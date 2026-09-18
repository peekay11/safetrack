import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { Env } from '../types';

export const chatRoutes = new Hono<{ Bindings: Env }>();

async function getUserId(c: any): Promise<string | null> {
  const authHeader = c.req.header('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) return null;
  const token = authHeader.replace('Bearer ', '');
  return await c.env.CACHE_KV.get(`session:${token}`);
}

// Get messages for an active walk
chatRoutes.get('/:groupId', async (c) => {
  const userId = await getUserId(c);
  if (!userId) return c.json({ error: 'Unauthorized' }, 401);
  const groupId = c.req.param('groupId');

  // Verify group is still active or recently completed
  const group = await c.env.DB.prepare('SELECT * FROM groups WHERE id = ?').bind(groupId).first();
  if (!group) return c.json({ error: 'Group not found' }, 404);

  const { results: messages } = await c.env.DB.prepare(
    'SELECT * FROM group_messages WHERE group_id = ? ORDER BY created_at ASC'
  )
    .bind(groupId)
    .all();

  return c.json({
    success: true,
    is_closed: (group as any).status === 'completed',
    messages,
  });
});

// Post a message or quick action ("Running late", "I've arrived", "Need help")
chatRoutes.post(
  '/:groupId',
  zValidator(
    'json',
    z.object({
      message: z.string().min(1),
      quick_action: z.enum(['running_late', 'arrived', 'need_help', 'custom']).optional(),
    })
  ),
  async (c) => {
    const userId = await getUserId(c);
    if (!userId) return c.json({ error: 'Unauthorized' }, 401);
    const groupId = c.req.param('groupId');

    const group = await c.env.DB.prepare('SELECT status FROM groups WHERE id = ?')
      .bind(groupId)
      .first<{ status: string }>();

    if (!group) return c.json({ error: 'Group not found' }, 404);
    if (group.status === 'completed' || group.status === 'cancelled') {
      return c.json({ error: 'Chat is closed as the walk has completed' }, 400);
    }

    const user = await c.env.DB.prepare('SELECT full_name FROM users WHERE id = ?')
      .bind(userId)
      .first<{ full_name: string }>();

    const { message, quick_action } = c.req.valid('json');
    const msgId = `msg_${crypto.randomUUID()}`;

    await c.env.DB.prepare(
      `INSERT INTO group_messages (id, group_id, user_id, user_name, message, quick_action)
       VALUES (?, ?, ?, ?, ?, ?)`
    )
      .bind(
        msgId,
        groupId,
        userId,
        user?.full_name || 'Member',
        message,
        quick_action || 'custom'
      )
      .run();

    const created = await c.env.DB.prepare('SELECT * FROM group_messages WHERE id = ?')
      .bind(msgId)
      .first();

    return c.json({ success: true, message: created }, 201);
  }
);

// Flag an in-chat message (feeds into incident reporting)
chatRoutes.post('/:groupId/messages/:messageId/flag', async (c) => {
  const userId = await getUserId(c);
  if (!userId) return c.json({ error: 'Unauthorized' }, 401);
  const messageId = c.req.param('messageId');

  await c.env.DB.prepare('UPDATE group_messages SET is_flagged = 1 WHERE id = ?')
    .bind(messageId)
    .run();

  return c.json({ success: true, message: 'Message flagged for review' });
});
