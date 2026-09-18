import { Context, Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { Env } from '../types';
import { haversineDistanceMeters } from '../utils/geo';
import { sendSms } from '../utils/sms';

export const groupRoutes = new Hono<{ Bindings: Env }>();

// South African minibus taxis seat 16 total including the driver.
const TAXI_CAPACITY = 15;
const WALK_CAPACITY = 6;
const WALK_MIN_GROUP_SIZE = 3;
const TAXI_MIN_GROUP_SIZE = 2;

function normalizePlate(plate: string): string {
  return plate.toUpperCase().replace(/\s+/g, '');
}

/**
 * Alerts the user's Guardian Angels with the trip's drop-off point when no
 * group could be found — the "escort fallback" safety net. SMS is mocked
 * (see utils/sms.ts) when no real gateway credentials are configured, which
 * is always true for this demo deployment.
 */
async function notifyGuardiansOfFallback(
  c: Context<{ Bindings: Env }>,
  userId: string,
  destinationName: string,
  destinationAddress: string | null,
  modeLabel: string
): Promise<{ notified_guardians: { name: string; phone_number: string }[]; message_preview: string }> {
  const user = await c.env.DB.prepare('SELECT full_name FROM users WHERE id = ?')
    .bind(userId)
    .first<{ full_name: string }>();

  const { results: guardians } = await c.env.DB.prepare(
    'SELECT name, phone_number FROM guardian_angels WHERE user_id = ?'
  )
    .bind(userId)
    .all();

  const dropOff = destinationAddress ? `${destinationName} (${destinationAddress})` : destinationName;
  const message = `[SafeWalk Escort Alert] ${user?.full_name || 'Your contact'} could not find a ${modeLabel} group and is walking solo. Drop-off point: ${dropOff}. Please check in with them.`;

  for (const g of guardians as any[]) {
    if (g.phone_number) {
      // Mocked: simultaneously "sent" as SMS and WhatsApp in this demo environment.
      await sendSms(c.env, { to: g.phone_number, message });
    }
  }

  return {
    notified_guardians: guardians as any[],
    message_preview: message,
  };
}

async function getUserId(c: any): Promise<string | null> {
  const authHeader = c.req.header('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) return null;
  const token = authHeader.replace('Bearer ', '');
  return await c.env.CACHE_KV.get(`session:${token}`);
}

// Get list of preset destinations (taxi ranks, stations, malls)
groupRoutes.get('/destinations', async (c) => {
  const { results } = await c.env.DB.prepare(
    'SELECT * FROM destinations WHERE active = 1 ORDER BY category, name'
  ).all();

  return c.json({ success: true, destinations: results });
});

// Find or Match into a Group
// walk mode: destination match + proximity (100-500m) + opaque candidate matching
// taxi mode: destination match + same number plate (everyone is literally in the vehicle already)
groupRoutes.post(
  '/match',
  zValidator(
    'json',
    z.object({
      destination_id: z.string().optional(),
      custom_destination: z
        .object({
          name: z.string().min(2),
          latitude: z.number(),
          longitude: z.number(),
          address: z.string().optional(),
        })
        .optional(),
      latitude: z.number(),
      longitude: z.number(),
      group_type: z.enum(['walk', 'taxi']).default('walk'),
      taxi_plate: z.string().min(3).optional(),
      planned_departure_time: z.string().optional(),
    })
  ),
  async (c) => {
    const userId = await getUserId(c);
    if (!userId) return c.json({ error: 'Unauthorized' }, 401);

    const data = c.req.valid('json');

    if (!data.destination_id && !data.custom_destination) {
      return c.json({ error: 'destination_id or custom_destination is required' }, 400);
    }
    if (data.group_type === 'taxi' && !data.taxi_plate) {
      return c.json({ error: 'taxi_plate is required for group_type = taxi' }, 400);
    }

    // 0. Resolve destination — create one on the fly for a user-entered spot
    let destinationId = data.destination_id;
    if (!destinationId && data.custom_destination) {
      destinationId = `dest_custom_${crypto.randomUUID()}`;
      await c.env.DB.prepare(
        `INSERT INTO destinations (id, name, category, latitude, longitude, address, active)
         VALUES (?, ?, 'custom', ?, ?, ?, 1)`
      )
        .bind(
          destinationId,
          data.custom_destination.name,
          data.custom_destination.latitude,
          data.custom_destination.longitude,
          data.custom_destination.address || null
        )
        .run();
    }

    const destination = await c.env.DB.prepare('SELECT * FROM destinations WHERE id = ?')
      .bind(destinationId)
      .first<{ name: string; address: string | null }>();

    const isTaxi = data.group_type === 'taxi';
    const capacity = isTaxi ? TAXI_CAPACITY : WALK_CAPACITY;
    const minGroupSize = isTaxi ? TAXI_MIN_GROUP_SIZE : WALK_MIN_GROUP_SIZE;
    const taxiPlate = isTaxi && data.taxi_plate ? normalizePlate(data.taxi_plate) : null;

    // 1. Find forming/active groups for this destination (+ same taxi, if taxi mode)
    const candidateQuery = isTaxi
      ? `SELECT g.* FROM groups g WHERE g.destination_id = ? AND g.group_type = 'taxi' AND g.taxi_plate = ? AND g.status IN ('forming', 'active') ORDER BY g.created_at ASC`
      : `SELECT g.* FROM groups g WHERE g.destination_id = ? AND g.group_type = 'walk' AND g.status = 'forming' ORDER BY g.created_at ASC`;
    const candidateBindings = isTaxi ? [destinationId, taxiPlate] : [destinationId];

    const { results: candidateGroups } = await c.env.DB.prepare(candidateQuery)
      .bind(...candidateBindings)
      .all();

    let matchedGroupId: string | null = null;
    let pickupOrder = 1;

    for (const group of candidateGroups) {
      const { results: members } = await c.env.DB.prepare(
        'SELECT * FROM group_members WHERE group_id = ?'
      )
        .bind(group.id)
        .all();

      // Already in this group (e.g. re-matching)
      if (members.some((m: any) => m.user_id === userId)) {
        matchedGroupId = group.id as string;
        break;
      }

      if (isTaxi) {
        // Same plate + same destination already means "same vehicle" — no
        // proximity check needed, just seat availability.
        if (members.length < capacity) {
          matchedGroupId = group.id as string;
          pickupOrder = members.length + 1;
          break;
        }
        continue;
      }

      // Walk mode: proximity threshold 100–800m to existing pickup points
      let fitsInGroup = true;
      if (members.length > 0) {
        const minDistance = Math.min(
          ...members.map((m: any) =>
            m.pickup_lat && m.pickup_lng
              ? haversineDistanceMeters(latitude, longitude, m.pickup_lat, m.pickup_lng)
              : 0
          )
        );
        if (minDistance > 800) fitsInGroup = false;
      }

      if (fitsInGroup && members.length < capacity) {
        matchedGroupId = group.id as string;
        pickupOrder = members.length + 1;
        break;
      }
    }

    // 2. If no matching group found, create a new forming group
    if (!matchedGroupId) {
      matchedGroupId = `grp_${crypto.randomUUID()}`;
      await c.env.DB.prepare(
        `INSERT INTO groups (id, destination_id, group_type, taxi_plate, capacity, status, departure_time)
         VALUES (?, ?, ?, ?, ?, 'forming', ?)`
      )
        .bind(
          matchedGroupId,
          destinationId,
          data.group_type,
          taxiPlate,
          capacity,
          data.planned_departure_time || new Date().toISOString()
        )
        .run();
    }

    const { latitude, longitude } = data;

    // 3. Add or update user in group_members
    const memberId = `gm_${crypto.randomUUID()}`;
    await c.env.DB.prepare(
      `INSERT OR REPLACE INTO group_members (id, group_id, user_id, role, pickup_lat, pickup_lng, pickup_order)
       VALUES (?, ?, ?, 'member', ?, ?, ?)`
    )
      .bind(memberId, matchedGroupId, userId, latitude, longitude, pickupOrder)
      .run();

    // Check count of members
    const countRes = await c.env.DB.prepare(
      'SELECT COUNT(*) as count FROM group_members WHERE group_id = ?'
    )
      .bind(matchedGroupId)
      .first<{ count: number }>();

    const memberCount = countRes?.count || 1;
    const meetsMinimumGroupSize = memberCount >= minGroupSize;

    if (meetsMinimumGroupSize) {
      await c.env.DB.prepare("UPDATE groups SET status = 'active' WHERE id = ? AND status = 'forming'")
        .bind(matchedGroupId)
        .run();
    }

    const groupDetails = await c.env.DB.prepare('SELECT * FROM groups WHERE id = ?')
      .bind(matchedGroupId)
      .first();

    // 4. No group found yet — alert the user's Guardian Angels with the
    // drop-off point as an escort-fallback safety net (mocked SMS/WhatsApp).
    let guardianNotification: Awaited<ReturnType<typeof notifyGuardiansOfFallback>> | null = null;
    if (!meetsMinimumGroupSize) {
      guardianNotification = await notifyGuardiansOfFallback(
        c,
        userId,
        destination?.name || 'your destination',
        destination?.address || null,
        isTaxi ? 'taxi' : 'walking'
      );
    }

    return c.json({
      success: true,
      group_id: matchedGroupId,
      group: groupDetails,
      destination_id: destinationId,
      member_count: memberCount,
      capacity,
      meets_minimum_group_size: meetsMinimumGroupSize,
      fallback_to_guardian: !meetsMinimumGroupSize,
      guardian_notification: guardianNotification,
      message: meetsMinimumGroupSize
        ? `Group confirmed with ${memberCount} member${memberCount === 1 ? '' : 's'}`
        : isTaxi
          ? 'No one else in this taxi yet — your Guardian Angel has been alerted.'
          : 'Finding group members... Guardian Angel escort fallback ready.',
    });
  }
);

// Get current active group details (roster, pickup points, status)
groupRoutes.get('/:id', async (c) => {
  const userId = await getUserId(c);
  if (!userId) return c.json({ error: 'Unauthorized' }, 401);
  const groupId = c.req.param('id');

  const group = await c.env.DB.prepare('SELECT * FROM groups WHERE id = ?').bind(groupId).first();
  if (!group) return c.json({ error: 'Group not found' }, 404);

  const destination = await c.env.DB.prepare('SELECT * FROM destinations WHERE id = ?')
    .bind(group.destination_id)
    .first();

  // Get members with user profiles (names, selfie, verification, extra time setting)
  const { results: members } = await c.env.DB.prepare(
    `SELECT gm.*, u.full_name, u.selfie_url, u.verified, u.needs_extra_time
     FROM group_members gm
     JOIN users u ON gm.user_id = u.id
     WHERE gm.group_id = ?
     ORDER BY gm.pickup_order ASC`
  )
    .bind(groupId)
    .all();

  return c.json({
    success: true,
    group,
    destination,
    members,
  });
});

// Update live location of member in group (stored in KV for low-latency real-time)
groupRoutes.post(
  '/:id/location',
  zValidator(
    'json',
    z.object({
      latitude: z.number(),
      longitude: z.number(),
    })
  ),
  async (c) => {
    const userId = await getUserId(c);
    if (!userId) return c.json({ error: 'Unauthorized' }, 401);
    const groupId = c.req.param('id');
    const { latitude, longitude } = c.req.valid('json');

    const locationData = {
      user_id: userId,
      latitude,
      longitude,
      timestamp: Date.now(),
    };

    // Store in KV with 10 minute expiry
    await c.env.CACHE_KV.put(`loc:${groupId}:${userId}`, JSON.stringify(locationData), {
      expirationTtl: 600,
    });

    return c.json({ success: true });
  }
);

// Get all members' live locations for active group
groupRoutes.get('/:id/locations', async (c) => {
  const userId = await getUserId(c);
  if (!userId) return c.json({ error: 'Unauthorized' }, 401);
  const groupId = c.req.param('id');

  const { results: members } = await c.env.DB.prepare(
    'SELECT user_id FROM group_members WHERE group_id = ?'
  )
    .bind(groupId)
    .all();

  const locations: Record<string, any> = {};
  for (const m of members) {
    const locStr = await c.env.CACHE_KV.get(`loc:${groupId}:${m.user_id}`);
    if (locStr) {
      locations[m.user_id as string] = JSON.parse(locStr);
    }
  }

  return c.json({ success: true, locations });
});

// Mark Checkpoint Arrival / Checkpoint Pass
groupRoutes.post(
  '/:id/checkpoint-arrival',
  zValidator(
    'json',
    z.object({
      target_member_id: z.string(),
    })
  ),
  async (c) => {
    const userId = await getUserId(c);
    if (!userId) return c.json({ error: 'Unauthorized' }, 401);
    const groupId = c.req.param('id');
    const { target_member_id } = c.req.valid('json');

    // Record picked_up_at
    await c.env.DB.prepare(
      `UPDATE group_members SET picked_up_at = CURRENT_TIMESTAMP WHERE group_id = ? AND user_id = ?`
    )
      .bind(groupId, target_member_id)
      .run();

    return c.json({ success: true, message: 'Checkpoint arrival recorded' });
  }
);

// Member Check-in: "I am safe"
groupRoutes.post('/:id/checkin-safe', async (c) => {
  const userId = await getUserId(c);
  if (!userId) return c.json({ error: 'Unauthorized' }, 401);
  const groupId = c.req.param('id');

  await c.env.DB.prepare(
    `UPDATE group_members SET safe_checked_in = 1, safe_checked_in_at = CURRENT_TIMESTAMP WHERE group_id = ? AND user_id = ?`
  )
    .bind(groupId, userId)
    .run();

  // Check if ALL members are checked in safe
  const remaining = await c.env.DB.prepare(
    `SELECT COUNT(*) as unconfirmed FROM group_members WHERE group_id = ? AND safe_checked_in = 0`
  )
    .bind(groupId)
    .first<{ unconfirmed: number }>();

  let allSafe = false;
  if (remaining && remaining.unconfirmed === 0) {
    allSafe = true;
    await c.env.DB.prepare("UPDATE groups SET status = 'completed', updated_at = CURRENT_TIMESTAMP WHERE id = ?")
      .bind(groupId)
      .run();
  }

  return c.json({
    success: true,
    message: 'Safe check-in confirmed',
    group_completed: allSafe,
  });
});
