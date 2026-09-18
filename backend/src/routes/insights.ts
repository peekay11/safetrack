import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { Env } from '../types';
import { haversineDistanceKm } from '../utils/geo';

export const insightsRoutes = new Hono<{ Bindings: Env }>();

const AI_MODEL = '@cf/meta/llama-3.1-8b-instruct-fp8';
const CONTEXT_RADIUS_KM = 2;

async function getUserId(c: any): Promise<string | null> {
  const authHeader = c.req.header('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) return null;
  const token = authHeader.replace('Bearer ', '');
  return await c.env.CACHE_KV.get(`session:${token}`);
}

/** Pulls real, local SafeWalk data near a destination to ground the model — never lets it invent specifics. */
async function buildDestinationContext(
  c: any,
  destination: { name: string; category?: string; address?: string; latitude: number; longitude: number }
): Promise<string> {
  const { results: flags } = await c.env.DB.prepare(
    `SELECT reason, severity FROM safety_flags WHERE (expires_at IS NULL OR expires_at > CURRENT_TIMESTAMP)`
  ).all();
  const nearbyFlags = (flags as any[]).filter(
    (f: any) => haversineDistanceKm(destination.latitude, destination.longitude, f.latitude ?? destination.latitude, f.longitude ?? destination.longitude) <= CONTEXT_RADIUS_KM
  );

  const { results: hotspotRows } = await c.env.DB.prepare(
    `SELECT ROUND(pickup_lat, 3) as latitude, ROUND(pickup_lng, 3) as longitude, COUNT(*) as walker_count
     FROM group_members WHERE pickup_lat IS NOT NULL AND pickup_lng IS NOT NULL
     GROUP BY latitude, longitude HAVING walker_count >= 2`
  ).all();
  const nearbyWalkers = (hotspotRows as any[])
    .filter((h) => haversineDistanceKm(destination.latitude, destination.longitude, h.latitude, h.longitude) <= CONTEXT_RADIUS_KM)
    .reduce((sum, h) => sum + h.walker_count, 0);

  const severityCounts: Record<string, number> = {};
  for (const f of nearbyFlags) {
    severityCounts[f.severity] = (severityCounts[f.severity] || 0) + 1;
  }

  const lines = [
    `Destination: ${destination.name}${destination.category ? ` (${destination.category})` : ''}`,
    destination.address ? `Address: ${destination.address}` : null,
    `Coordinates: ${destination.latitude}, ${destination.longitude}`,
    nearbyFlags.length > 0
      ? `Community safety reports within ${CONTEXT_RADIUS_KM}km: ${nearbyFlags.length} total (${Object.entries(severityCounts)
          .map(([sev, n]) => `${n} ${sev}`)
          .join(', ')}).`
      : `No community safety reports within ${CONTEXT_RADIUS_KM}km in the last 7 days.`,
    nearbyWalkers > 0
      ? `${nearbyWalkers} SafeWalk users have started a walk/taxi group within ${CONTEXT_RADIUS_KM}km recently — this is an active pickup area.`
      : `No recent SafeWalk group activity recorded within ${CONTEXT_RADIUS_KM}km yet.`,
  ].filter(Boolean);

  return lines.join('\n');
}

// Conversational AI insights about a specific destination — grounded in
// SafeTrack's own real data (community safety flags, pickup-activity
// hotspots), using Cloudflare Workers AI. Stateless: the client resends the
// short conversation history with each turn.
insightsRoutes.post(
  '/chat',
  zValidator(
    'json',
    z.object({
      destination: z.object({
        name: z.string(),
        category: z.string().optional(),
        address: z.string().optional(),
        latitude: z.number(),
        longitude: z.number(),
      }),
      message: z.string().min(1),
      history: z
        .array(
          z.object({
            role: z.enum(['user', 'assistant']),
            content: z.string(),
          })
        )
        .max(12)
        .optional(),
    })
  ),
  async (c) => {
    const userId = await getUserId(c);
    if (!userId) return c.json({ error: 'Unauthorized' }, 401);

    const { destination, message, history } = c.req.valid('json');
    const context = await buildDestinationContext(c, destination);

    const systemPrompt = `You are SafeWalk's local safety assistant, helping a user in South Africa understand a place they're about to travel to. You are given real, current data pulled from SafeWalk's own database below — use it as your primary source, and be explicit when you're speculating instead of stating a specific incident as fact. Do not invent specific crimes, incidents, or news stories that aren't in the provided data. Give short, practical, actionable safety guidance (lighting, time of day, group travel, what to watch for at this type of location). Keep replies to 2-4 sentences unless the user asks for more detail. Be warm but direct — this app is used by women walking alone.

Live data for this destination:
${context}`;

    try {
      const response = await c.env.AI.run(AI_MODEL, {
        messages: [
          { role: 'system', content: systemPrompt },
          ...(history || []),
          { role: 'user', content: message },
        ],
        max_tokens: 350,
      });

      const reply = (response as any)?.response || "I couldn't generate an insight right now — please try again.";
      return c.json({ success: true, reply, context_used: context });
    } catch (err) {
      console.error('[Insights AI Error]', err);
      return c.json(
        {
          success: true,
          reply:
            "I couldn't reach the AI service right now, but here's what SafeWalk knows: \n" +
            context +
            '\nStick to well-lit, busy routes and travel with your group where possible.',
          context_used: context,
          ai_unavailable: true,
        },
        200
      );
    }
  }
);
