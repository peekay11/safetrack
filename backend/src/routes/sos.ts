import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { Env } from '../types';

import { sendSms } from '../utils/sms';

export const sosRoutes = new Hono<{ Bindings: Env }>();

async function getUserId(c: any): Promise<string | null> {
  const authHeader = c.req.header('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) return null;
  const token = authHeader.replace('Bearer ', '');
  return await c.env.CACHE_KV.get(`session:${token}`);
}

// Trigger SOS (from in-app button, volume trigger, or missed checkpoint)
sosRoutes.post(
  '/trigger',
  zValidator(
    'json',
    z.object({
      latitude: z.number(),
      longitude: z.number(),
      group_id: z.string().optional(),
      ehailing_trip_id: z.string().optional(),
      trigger_type: z.enum(['app_sos', 'hardware_volume', 'checkpoint_timeout', 'ussd_report']).default('app_sos'),
      distress_message: z.string().optional(),
    })
  ),
  async (c) => {
    const userId = await getUserId(c);
    if (!userId) return c.json({ error: 'Unauthorized' }, 401);

    const data = c.req.valid('json');
    const sosId = `sos_${crypto.randomUUID()}`;

    // Get user details
    const user = await c.env.DB.prepare('SELECT full_name, language FROM users WHERE id = ?')
      .bind(userId)
      .first<{ full_name: string; language: string }>();

    // Multilingual SOS templates per section 4.9:
    const distressTemplates: Record<string, string> = {
      en: 'EMERGENCY: I need help immediately! Here is my live location:',
      zu: 'ISIPHUTHUMA: Ngidinga usizo ngokushesha! Nansi indawo yami ebukhoma:',
      af: 'NOODGEVAL: Ek benodig dringend hulp! Hier is my lewendige ligging:',
      st: 'TSHOHANYETSO: Ke hloka thuso kapele! Mona ke sebaka sa ka sa hona joale:',
    };

    const userLang = user?.language || 'en';
    const distressMessage = data.distress_message || distressTemplates[userLang] || distressTemplates['en'];

    // Insert SOS event
    await c.env.DB.prepare(
      `INSERT INTO sos_events (id, user_id, group_id, ehailing_trip_id, latitude, longitude, status, trigger_type, distress_message)
       VALUES (?, ?, ?, ?, ?, ?, 'triggered', ?, ?)`
    )
      .bind(
        sosId,
        userId,
        data.group_id || null,
        data.ehailing_trip_id || null,
        data.latitude,
        data.longitude,
        data.trigger_type,
        distressMessage
      )
      .run();

    // Auto-create a high severity safety flag on map for this SOS spot
    const flagId = `flag_sos_${crypto.randomUUID()}`;
    await c.env.DB.prepare(
      `INSERT INTO safety_flags (id, reported_by_user_id, latitude, longitude, reason, source, severity, description, expires_at)
       VALUES (?, ?, ?, ?, 'sos_triggered', 'sos', 'severe', 'Active SOS distress triggered here', datetime('now', '+7 days'))`
    )
      .bind(flagId, userId, data.latitude, data.longitude)
      .run();

    // Fetch all Guardian Angels to simulate simultaneous alert broadcast
    const { results: guardians } = await c.env.DB.prepare(
      'SELECT name, phone_number FROM guardian_angels WHERE user_id = ?'
    )
      .bind(userId)
      .all();

    const emergencySmsText = `[SafeWalk SOS ALERT] ${user?.full_name || 'Your contact'} has triggered an SOS! Location: https://maps.google.com/?q=${data.latitude},${data.longitude}. Message: ${distressMessage}`;
    for (const g of guardians as any[]) {
      if (g.phone_number) {
        await sendSms(c.env, { to: g.phone_number, message: emergencySmsText });
      }
    }

    return c.json({
      success: true,
      sos_id: sosId,
      status: 'triggered',
      distress_message: distressMessage,
      guardians_alerted: guardians,
      escalation_window_seconds: 180, // 3 minutes shared window before emergency fallback
      message: 'SOS active. All Guardian Angels alerted simultaneously.',
    });
  }
);

// Guardian Angel Acknowledgment: "Received - I'm on it"
sosRoutes.post(
  '/:id/acknowledge',
  zValidator(
    'json',
    z.object({
      guardian_name: z.string(),
    })
  ),
  async (c) => {
    const sosId = c.req.param('id');
    const { guardian_name } = c.req.valid('json');

    await c.env.DB.prepare(
      `UPDATE sos_events SET status = 'acknowledged', acknowledged_by = ?, acknowledged_at = CURRENT_TIMESTAMP WHERE id = ?`
    )
      .bind(guardian_name, sosId)
      .run();

    return c.json({
      success: true,
      message: `SOS acknowledged by ${guardian_name}. Escalation timer paused.`,
    });
  }
);

// Attach a recorded video evidence clip to an active SOS event (stored in R2)
sosRoutes.post('/:id/video', async (c) => {
  const userId = await getUserId(c);
  if (!userId) return c.json({ error: 'Unauthorized' }, 401);
  const sosId = c.req.param('id');

  const sos = await c.env.DB.prepare('SELECT id FROM sos_events WHERE id = ? AND user_id = ?')
    .bind(sosId, userId)
    .first();
  if (!sos) return c.json({ error: 'SOS event not found' }, 404);

  const body = await c.req.parseBody();
  const file = body['file'];
  if (!file || !(file instanceof File)) {
    return c.json({ error: 'Valid video file is required' }, 400);
  }

  const extension = (file.type && file.type.split('/')[1]) || 'mp4';
  const fileKey = `sos-videos/${sosId}-${Date.now()}.${extension}`;
  const arrayBuffer = await file.arrayBuffer();

  await c.env.BUCKET.put(fileKey, arrayBuffer, {
    httpMetadata: { contentType: file.type || 'video/mp4' },
  });

  const videoUrl = `/uploads/${fileKey}`;
  await c.env.DB.prepare('UPDATE sos_events SET video_url = ? WHERE id = ?')
    .bind(videoUrl, sosId)
    .run();

  return c.json({
    success: true,
    message: 'Video evidence attached to SOS event',
    video_url: videoUrl,
  });
});

// Resolve or Mark False Alarm
sosRoutes.post(
  '/:id/resolve',
  zValidator(
    'json',
    z.object({
      is_false_alarm: z.boolean().default(false),
    })
  ),
  async (c) => {
    const sosId = c.req.param('id');
    const { is_false_alarm } = c.req.valid('json');
    const newStatus = is_false_alarm ? 'false_alarm' : 'resolved';

    await c.env.DB.prepare(`UPDATE sos_events SET status = ? WHERE id = ?`)
      .bind(newStatus, sosId)
      .run();

    return c.json({
      success: true,
      status: newStatus,
      message: is_false_alarm ? 'Marked as false alarm' : 'SOS resolved safely',
    });
  }
);
