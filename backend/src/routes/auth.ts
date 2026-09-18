import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { Env } from '../types';

import { sendSms } from '../utils/sms';

export const authRoutes = new Hono<{ Bindings: Env }>();

// Normalizes a phone number so the same person typing it differently across
// sessions ("+27 82 555 1234", "0825551234", "+27825551234", ...) always
// resolves to the same OTP entry and the same user account.
function normalizePhone(raw: string): string {
  let digits = raw.replace(/[^\d+]/g, '');
  if (digits.startsWith('0')) {
    digits = `+27${digits.slice(1)}`;
  } else if (!digits.startsWith('+')) {
    digits = `+${digits}`;
  }
  return digits;
}

// Simple OTP generator / sender (sends real SMS via Africa's Talking / Twilio or returns OTP in dev)
authRoutes.post(
  '/send-otp',
  zValidator(
    'json',
    z.object({
      phone_number: z.string().min(10),
    })
  ),
  async (c) => {
    const phone_number = normalizePhone(c.req.valid('json').phone_number);
    // Generate 6 digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    // Store in KV with 10 minute expiration
    await c.env.CACHE_KV.put(`otp:${phone_number}`, otp, { expirationTtl: 600 });

    // Send SMS via configured gateway
    const smsRes = await sendSms(c.env, {
      to: phone_number,
      message: `Your SafeWalk verification code is: ${otp}. Valid for 5 minutes.`,
    });

    return c.json({
      success: true,
      message: `OTP sent to ${phone_number}`,
      provider: smsRes.provider,
      // For immediate hackathon convenience / testing:
      dev_otp: otp,
    });
  }
);

// Verify OTP & Sign In / Register
authRoutes.post(
  '/verify-otp',
  zValidator(
    'json',
    z.object({
      phone_number: z.string().min(10),
      code: z.string().length(6),
      full_name: z.string().optional(),
    })
  ),
  async (c) => {
    const { code, full_name } = c.req.valid('json');
    const phone_number = normalizePhone(c.req.valid('json').phone_number);

    const storedOtp = await c.env.CACHE_KV.get(`otp:${phone_number}`);
    const isDevDefault = code === '123456'; // convenient fallback for tests/demo

    if (!isDevDefault && (!storedOtp || storedOtp !== code)) {
      return c.json({ success: false, error: 'Invalid or expired OTP' }, 400);
    }

    // Clear OTP
    await c.env.CACHE_KV.delete(`otp:${phone_number}`);

    // Check if user exists in D1
    let user = await c.env.DB.prepare('SELECT * FROM users WHERE phone_number = ?')
      .bind(phone_number)
      .first();

    if (!user) {
      const newId = `user_${crypto.randomUUID()}`;
      await c.env.DB.prepare(
        `INSERT INTO users (id, phone_number, full_name, language) VALUES (?, ?, ?, 'en')`
      )
        .bind(newId, phone_number, full_name || 'SafeWalk User')
        .run();

      user = await c.env.DB.prepare('SELECT * FROM users WHERE id = ?').bind(newId).first();
    }

    // Issue a session token (stored in KV or signed)
    const token = `token_${crypto.randomUUID()}`;
    await c.env.CACHE_KV.put(`session:${token}`, (user as any).id, { expirationTtl: 86400 * 30 });

    return c.json({
      success: true,
      token,
      user,
    });
  }
);

// Get current user profile
authRoutes.get('/me', async (c) => {
  const authHeader = c.req.header('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return c.json({ error: 'Unauthorized' }, 401);
  }

  const token = authHeader.replace('Bearer ', '');
  const userId = await c.env.CACHE_KV.get(`session:${token}`);
  if (!userId) {
    return c.json({ error: 'Invalid session' }, 401);
  }

  const user = await c.env.DB.prepare('SELECT * FROM users WHERE id = ?').bind(userId).first();
  if (!user) {
    return c.json({ error: 'User not found' }, 404);
  }

  // Also fetch user's guardian angels
  const { results: guardianAngels } = await c.env.DB.prepare(
    'SELECT * FROM guardian_angels WHERE user_id = ?'
  )
    .bind(userId)
    .all();

  return c.json({
    user,
    guardian_angels: guardianAngels,
  });
});

// Update Profile & Accessibility preferences
authRoutes.patch(
  '/profile',
  zValidator(
    'json',
    z.object({
      full_name: z.string().optional(),
      id_number: z.string().optional(),
      id_type: z.enum(['sa_id', 'passport', 'drivers_license']).optional(),
      language: z.enum(['en', 'zu', 'af', 'st']).optional(),
      needs_extra_time: z.boolean().optional(),
      guardian_angel_primary: z.boolean().optional(),
    })
  ),
  async (c) => {
    const authHeader = c.req.header('Authorization');
    if (!authHeader) return c.json({ error: 'Unauthorized' }, 401);
    const token = authHeader.replace('Bearer ', '');
    const userId = await c.env.CACHE_KV.get(`session:${token}`);
    if (!userId) return c.json({ error: 'Invalid session' }, 401);

    const data = c.req.valid('json');

    const fields: string[] = [];
    const values: any[] = [];

    if (data.full_name !== undefined) {
      fields.push('full_name = ?');
      values.push(data.full_name);
    }
    if (data.id_number !== undefined) {
      fields.push('id_number = ?');
      values.push(data.id_number);
    }
    if (data.id_type !== undefined) {
      fields.push('id_type = ?');
      values.push(data.id_type);
    }
    if (data.language !== undefined) {
      fields.push('language = ?');
      values.push(data.language);
    }
    if (data.needs_extra_time !== undefined) {
      fields.push('needs_extra_time = ?');
      values.push(data.needs_extra_time ? 1 : 0);
    }
    if (data.guardian_angel_primary !== undefined) {
      fields.push('guardian_angel_primary = ?');
      values.push(data.guardian_angel_primary ? 1 : 0);
    }

    if (fields.length > 0) {
      fields.push("updated_at = CURRENT_TIMESTAMP");
      values.push(userId);
      await c.env.DB.prepare(`UPDATE users SET ${fields.join(', ')} WHERE id = ?`)
        .bind(...values)
        .run();
    }

    const updatedUser = await c.env.DB.prepare('SELECT * FROM users WHERE id = ?').bind(userId).first();
    return c.json({ success: true, user: updatedUser });
  }
);
