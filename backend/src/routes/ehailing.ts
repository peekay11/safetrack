import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { Env } from '../types';
import { sendSms } from '../utils/sms';

export const ehailingRoutes = new Hono<{ Bindings: Env }>();

async function getUserId(c: any): Promise<string | null> {
  const authHeader = c.req.header('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) return null;
  const token = authHeader.replace('Bearer ', '');
  return await c.env.CACHE_KV.get(`session:${token}`);
}

// Start E-Hailing Mode (with simulated BlackLyst verification & Guardian Angel SMS dispatch)
ehailingRoutes.post(
  '/start',
  zValidator(
    'json',
    z.object({
      driver_name: z.string().optional(),
      vehicle_registration: z.string().optional(),
      service_provider: z.enum(['Uber', 'Bolt', 'InDrive', 'Other']).default('Uber'),
      start_lat: z.number(),
      start_lng: z.number(),
    })
  ),
  async (c) => {
    const userId = await getUserId(c);
    if (!userId) return c.json({ error: 'Unauthorized' }, 401);

    const data = c.req.valid('json');
    const tripId = `trip_${crypto.randomUUID()}`;

    // Spec: Simulated BlackLyst check
    let blacklystFlagged = 0;
    let blacklystDetails = null;

    if (data.vehicle_registration) {
      const regUpper = data.vehicle_registration.toUpperCase().replace(/\s+/g, '');
      // Sample simulated flagged patterns
      if (regUpper.includes('CA888') || regUpper.includes('GP666') || regUpper.includes('ALERT')) {
        blacklystFlagged = 1;
        blacklystDetails = 'Warning: Vehicle registration has an active community flag on BlackLyst.';
      }
    }

    await c.env.DB.prepare(
      `INSERT INTO ehailing_trips (id, user_id, driver_name, vehicle_registration, service_provider, status, start_lat, start_lng, current_lat, current_lng, blacklyst_flagged, blacklyst_details)
       VALUES (?, ?, ?, ?, ?, 'active', ?, ?, ?, ?, ?, ?)`
    )
      .bind(
        tripId,
        userId,
        data.driver_name || null,
        data.vehicle_registration || null,
        data.service_provider,
        data.start_lat,
        data.start_lng,
        data.start_lat,
        data.start_lng,
        blacklystFlagged,
        blacklystDetails
      )
      .run();

    // Fetch user and Guardian Angels to prepare SMS notifications
    const user = await c.env.DB.prepare('SELECT full_name FROM users WHERE id = ?').bind(userId).first<{ full_name: string }>();
    const { results: guardians } = await c.env.DB.prepare(
      'SELECT name, phone_number FROM guardian_angels WHERE user_id = ?'
    )
      .bind(userId)
      .all();

    // Map link generated for guardians
    const liveTrackingUrl = `https://safetrack-backend.pasekamabitsela22.workers.dev/track/ehailing/${tripId}`;
    const smsMessage = `[SafeWalk Alert] ${user?.full_name || 'Your contact'} has started an ${data.service_provider} trip. Live tracking: ${liveTrackingUrl}. Reg: ${data.vehicle_registration || 'N/A'}`;

    // Send SMS alerts to each guardian angel
    for (const g of guardians as any[]) {
      if (g.phone_number) {
        await sendSms(c.env, { to: g.phone_number, message: smsMessage });
      }
    }

    return c.json({
      success: true,
      trip_id: tripId,
      live_tracking_url: liveTrackingUrl,
      blacklyst: {
        flagged: blacklystFlagged === 1,
        details: blacklystDetails,
      },
      notified_guardians_count: guardians.length,
      sms_preview: smsMessage,
      message: 'E-Hailing Mode activated. Guardian Angels notified.',
    });
  }
);

// Update live location during e-hailing trip
ehailingRoutes.post(
  '/:id/location',
  zValidator(
    'json',
    z.object({
      latitude: z.number(),
      longitude: z.number(),
    })
  ),
  async (c) => {
    const tripId = c.req.param('id');
    const { latitude, longitude } = c.req.valid('json');

    await c.env.DB.prepare(
      `UPDATE ehailing_trips SET current_lat = ?, current_lng = ? WHERE id = ?`
    )
      .bind(latitude, longitude, tripId)
      .run();

    // Store in KV for instant public tracking page
    await c.env.CACHE_KV.put(
      `ehailing:${tripId}:loc`,
      JSON.stringify({ latitude, longitude, timestamp: Date.now() }),
      { expirationTtl: 3600 }
    );

    return c.json({ success: true });
  }
);

// End E-Hailing trip: "I am safe" check-in
ehailingRoutes.post('/:id/checkin-safe', async (c) => {
  const tripId = c.req.param('id');

  await c.env.DB.prepare(
    `UPDATE ehailing_trips SET status = 'safe_completed', ended_at = CURRENT_TIMESTAMP WHERE id = ?`
  )
    .bind(tripId)
    .run();

  return c.json({ success: true, message: 'E-hailing trip marked safe and completed' });
});

// Public live-tracking endpoint for Guardian Angels
ehailingRoutes.get('/track/:id', async (c) => {
  const tripId = c.req.param('id');

  const trip = await c.env.DB.prepare(
    `SELECT t.*, u.full_name FROM ehailing_trips t JOIN users u ON t.user_id = u.id WHERE t.id = ?`
  )
    .bind(tripId)
    .first();

  if (!trip) return c.json({ error: 'Trip not found' }, 404);

  const locStr = await c.env.CACHE_KV.get(`ehailing:${tripId}:loc`);
  const liveLocation = locStr ? JSON.parse(locStr) : null;

  return c.json({
    success: true,
    trip,
    live_location: liveLocation || {
      latitude: (trip as any).current_lat,
      longitude: (trip as any).current_lng,
    },
  });
});
