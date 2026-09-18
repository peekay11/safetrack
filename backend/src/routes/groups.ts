import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { Env } from '../types';
import { haversineDistanceMeters } from '../utils/geo';

export const groupRoutes = new Hono<{ Bindings: Env }>();

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
// Rule: destination match + proximity (100-500m) + opaque candidate matching
groupRoutes.post(
  '/match',
  zValidator(
    'json',
    z.object({
      destination_id: z.string(),
      latitude: z.number(),
      longitude: z.number(),
      planned_departure_time: z.string().optional(),
    })
  ),
  async (c) => {
    const userId = await getUserId(c);
    if (!userId) return c.json({ error: 'Unauthorized' }, 401);

    const { destination_id, latitude, longitude, planned_departure_time } = c.req.valid('json');

    // 1. Find forming groups for this destination
    const { results: candidateGroups } = await c.env.DB.prepare(
      `SELECT g.* FROM groups g WHERE g.destination_id = ? AND g.status = 'forming' ORDER BY g.created_at ASC`
    )
      .bind(destination_id)
      .all();

    let matchedGroupId: string | null = null;
    let pickupOrder = 1;

    for (const group of candidateGroups) {
      // Get current members of this group
      const { results: members } = await c.env.DB.prepare(
        'SELECT * FROM group_members WHERE group_id = ?'
      )
        .bind(group.id)
        .all();

      // Check if user is already in this group
      if (members.some((m: any) => m.user_id === userId)) {
        matchedGroupId = group.id as string;
        break;
      }

      // If group has members, check proximity to existing members or route
      // Proximity threshold: 100m to 500m (or up to 1000m for forming pilot)
      let fitsInGroup = true;
      if (members.length > 0) {
        // Check distance to closest existing pickup
        const minDistance = Math.min(
          ...members.map((m: any) =>
            m.pickup_lat && m.pickup_lng
              ? haversineDistanceMeters(latitude, longitude, m.pickup_lat, m.pickup_lng)
              : 0
          )
        );

        if (minDistance > 800) {
          fitsInGroup = false;
        }
      }

      // Max group capacity e.g. 6 members for a safe walking pack
      if (fitsInGroup && members.length < 6) {
        matchedGroupId = group.id as string;
        pickupOrder = members.length + 1;
        break;
      }
    }

    // 2. If no matching group found, create a new forming group
    if (!matchedGroupId) {
      matchedGroupId = `grp_${crypto.randomUUID()}`;
      await c.env.DB.prepare(
        `INSERT INTO groups (id, destination_id, status, departure_time) VALUES (?, ?, 'forming', ?)`
      )
        .bind(matchedGroupId, destination_id, planned_departure_time || new Date().toISOString())
        .run();
    }

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
    // Minimum 3+ for a confirmed safe group
    const meetsMinimumGroupSize = memberCount >= 3;

    if (meetsMinimumGroupSize) {
      // Group reaches 3+ threshold, can become 'active' if departure is now
      await c.env.DB.prepare("UPDATE groups SET status = 'active' WHERE id = ? AND status = 'forming'")
        .bind(matchedGroupId)
        .run();
    }

    const groupDetails = await c.env.DB.prepare('SELECT * FROM groups WHERE id = ?')
      .bind(matchedGroupId)
      .first();

    return c.json({
      success: true,
      group_id: matchedGroupId,
      group: groupDetails,
      member_count: memberCount,
      meets_minimum_group_size: meetsMinimumGroupSize,
      fallback_to_guardian: !meetsMinimumGroupSize,
      message: meetsMinimumGroupSize
        ? 'Group confirmed with 3+ members'
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

  // Get members with user profiles (names, selfie, extra time setting)
  const { results: members } = await c.env.DB.prepare(
    `SELECT gm.*, u.full_name, u.selfie_url, u.needs_extra_time
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
