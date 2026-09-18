import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { Env } from '../types';
import { haversineDistanceKm } from '../utils/geo';

export const safetyMapRoutes = new Hono<{ Bindings: Env }>();

async function getUserId(c: any): Promise<string | null> {
  const authHeader = c.req.header('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) return null;
  const token = authHeader.replace('Bearer ', '');
  return await c.env.CACHE_KV.get(`session:${token}`);
}

// Get safety flags within radius of coordinate or bounding box
safetyMapRoutes.get('/flags', async (c) => {
  const lat = parseFloat(c.req.query('lat') || '-26.2041');
  const lng = parseFloat(c.req.query('lng') || '28.0473');
  const radiusKm = parseFloat(c.req.query('radius') || '10');

  // Fetch active flags that haven't expired
  const { results } = await c.env.DB.prepare(
    `SELECT * FROM safety_flags WHERE (expires_at IS NULL OR expires_at > CURRENT_TIMESTAMP) ORDER BY created_at DESC`
  ).all();

  // Filter within radius using Haversine
  const nearbyFlags = (results as any[]).filter((flag) => {
    const dist = haversineDistanceKm(lat, lng, flag.latitude, flag.longitude);
    return dist <= radiusKm;
  });

  return c.json({
    success: true,
    count: nearbyFlags.length,
    flags: nearbyFlags,
  });
});

// Drop manual safety pin flag
safetyMapRoutes.post(
  '/flags',
  zValidator(
    'json',
    z.object({
      latitude: z.number(),
      longitude: z.number(),
      reason: z.enum([
        'poor_lighting',
        'harassment',
        'isolated',
        'suspicious_activity',
        'other',
      ]),
      severity: z.enum(['low', 'medium', 'high', 'severe']).default('medium'),
      description: z.string().optional(),
    })
  ),
  async (c) => {
    const userId = await getUserId(c);
    const data = c.req.valid('json');

    const flagId = `flag_${crypto.randomUUID()}`;
    // Flags decay over time (e.g. 7 days default)
    await c.env.DB.prepare(
      `INSERT INTO safety_flags (id, reported_by_user_id, latitude, longitude, reason, source, severity, description, expires_at)
       VALUES (?, ?, ?, ?, ?, 'user', ?, ?, datetime('now', '+7 days'))`
    )
      .bind(
        flagId,
        userId || 'anonymous',
        data.latitude,
        data.longitude,
        data.reason,
        data.severity,
        data.description || null
      )
      .run();

    const created = await c.env.DB.prepare('SELECT * FROM safety_flags WHERE id = ?')
      .bind(flagId)
      .first();

    return c.json({ success: true, flag: created }, 201);
  }
);
