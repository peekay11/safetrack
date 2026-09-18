import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { Env } from '../types';

export const verificationRoutes = new Hono<{ Bindings: Env }>();

// Helper to authenticate session
async function getUserIdFromSession(c: any): Promise<string | null> {
  const authHeader = c.req.header('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) return null;
  const token = authHeader.replace('Bearer ', '');
  return await c.env.CACHE_KV.get(`session:${token}`);
}

// Upload selfie verification (stores in R2 and links to user)
verificationRoutes.post('/selfie', async (c) => {
  const userId = await getUserIdFromSession(c);
  if (!userId) return c.json({ error: 'Unauthorized' }, 401);

  const body = await c.req.parseBody();
  const file = body['file'];

  if (!file || !(file instanceof File)) {
    return c.json({ error: 'Valid image file is required' }, 400);
  }

  const fileKey = `selfies/${userId}-${Date.now()}.jpg`;
  const arrayBuffer = await file.arrayBuffer();

  // Store in Cloudflare R2 bucket
  await c.env.BUCKET.put(fileKey, arrayBuffer, {
    httpMetadata: { contentType: file.type || 'image/jpeg' },
  });

  const selfieUrl = `/uploads/${fileKey}`;

  // Update user in D1
  await c.env.DB.prepare('UPDATE users SET selfie_url = ?, verified = 1, updated_at = CURRENT_TIMESTAMP WHERE id = ?')
    .bind(selfieUrl, userId)
    .run();

  return c.json({
    success: true,
    message: 'Selfie verification recorded successfully',
    selfie_url: selfieUrl,
    verified: true,
  });
});

// Upload ID document (SA ID / Passport / Driver's License)
verificationRoutes.post('/id-document', async (c) => {
  const userId = await getUserIdFromSession(c);
  if (!userId) return c.json({ error: 'Unauthorized' }, 401);

  const body = await c.req.parseBody();
  const file = body['file'];
  const idNumber = body['id_number'] as string;
  const idType = (body['id_type'] as string) || 'sa_id';

  if (!file || !(file instanceof File)) {
    return c.json({ error: 'Valid document file is required' }, 400);
  }

  const fileKey = `documents/${userId}-${Date.now()}.jpg`;
  const arrayBuffer = await file.arrayBuffer();

  await c.env.BUCKET.put(fileKey, arrayBuffer, {
    httpMetadata: { contentType: file.type || 'image/jpeg' },
  });

  const docUrl = `/uploads/${fileKey}`;

  await c.env.DB.prepare(
    `UPDATE users SET id_doc_url = ?, id_number = COALESCE(?, id_number), id_type = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?`
  )
    .bind(docUrl, idNumber || null, idType, userId)
    .run();

  return c.json({
    success: true,
    message: 'ID Document uploaded successfully',
    doc_url: docUrl,
  });
});
