import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { Env } from '../types';

export const guardianRoutes = new Hono<{ Bindings: Env }>();

async function getUserId(c: any): Promise<string | null> {
  const authHeader = c.req.header('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) return null;
  const token = authHeader.replace('Bearer ', '');
  return await c.env.CACHE_KV.get(`session:${token}`);
}

// List user's Guardian Angels (up to 4)
guardianRoutes.get('/', async (c) => {
  const userId = await getUserId(c);
  if (!userId) return c.json({ error: 'Unauthorized' }, 401);

  const { results } = await c.env.DB.prepare(
    'SELECT * FROM guardian_angels WHERE user_id = ? ORDER BY created_at ASC'
  )
    .bind(userId)
    .all();

  return c.json({ success: true, guardians: results });
});

// Add Guardian Angel
guardianRoutes.post(
  '/',
  zValidator(
    'json',
    z.object({
      name: z.string().min(2),
      phone_number: z.string().min(10),
      relationship: z.string().optional(),
      gender: z.enum(['female', 'male', 'other']).optional(),
      night_only: z.boolean().optional(),
    })
  ),
  async (c) => {
    const userId = await getUserId(c);
    if (!userId) return c.json({ error: 'Unauthorized' }, 401);

    // Enforce max 4 guardians rule per spec
    const countResult = await c.env.DB.prepare(
      'SELECT COUNT(*) as count FROM guardian_angels WHERE user_id = ?'
    )
      .bind(userId)
      .first<{ count: number }>();

    if (countResult && countResult.count >= 4) {
      return c.json({ error: 'Maximum of 4 Guardian Angels allowed per user' }, 400);
    }

    const body = c.req.valid('json');
    const guardianId = `ga_${crypto.randomUUID()}`;

    await c.env.DB.prepare(
      `INSERT INTO guardian_angels (id, user_id, name, phone_number, relationship, gender, night_only, verified)
       VALUES (?, ?, ?, ?, ?, ?, ?, 1)`
    )
      .bind(
        guardianId,
        userId,
        body.name,
        body.phone_number,
        body.relationship || null,
        body.gender || null,
        body.night_only ? 1 : 0
      )
      .run();

    const created = await c.env.DB.prepare('SELECT * FROM guardian_angels WHERE id = ?')
      .bind(guardianId)
      .first();

    return c.json({ success: true, guardian: created }, 201);
  }
);

// Delete Guardian Angel
guardianRoutes.delete('/:id', async (c) => {
  const userId = await getUserId(c);
  if (!userId) return c.json({ error: 'Unauthorized' }, 401);
  const guardianId = c.req.param('id');

  await c.env.DB.prepare('DELETE FROM guardian_angels WHERE id = ? AND user_id = ?')
    .bind(guardianId, userId)
    .run();

  return c.json({ success: true, message: 'Guardian Angel removed' });
});
