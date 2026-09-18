import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { prettyJSON } from 'hono/pretty-json';
import { swaggerUI } from '@hono/swagger-ui';
import { Env } from './types';
import { openApiSpec } from './openapi';

// Import Route Handlers
import { authRoutes } from './routes/auth';
import { verificationRoutes } from './routes/verification';
import { guardianRoutes } from './routes/guardians';
import { groupRoutes } from './routes/groups';
import { chatRoutes } from './routes/chat';
import { ehailingRoutes } from './routes/ehailing';
import { sosRoutes } from './routes/sos';
import { safetyMapRoutes } from './routes/safetyMap';
import { ussdRoutes } from './routes/ussd';
import { insightsRoutes } from './routes/insights';

const app = new Hono<{ Bindings: Env }>();

// Middlewares
app.use('*', logger());
app.use('*', prettyJSON());
app.use(
  '*',
  cors({
    origin: '*',
    allowMethods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowHeaders: ['Content-Type', 'Authorization'],
  })
);

// Health check / API root
app.get('/', (c) => {
  return c.json({
    name: 'SafeTrack Cloudflare Backend API',
    version: '1.0.0',
    status: 'online',
    documentation: '/ui',
    openapi_spec: '/doc',
    timestamp: new Date().toISOString(),
    endpoints: {
      auth: '/api/auth',
      verification: '/api/verification',
      guardians: '/api/guardians',
      groups: '/api/groups',
      chat: '/api/chat',
      ehailing: '/api/ehailing',
      sos: '/api/sos',
      safety_map: '/api/safety-map',
      ussd: '/api/ussd',
      insights: '/api/insights',
    },
  });
});

// Swagger OpenAPI documentation
app.get('/doc', (c) => c.json(openApiSpec));
app.get('/ui', swaggerUI({ url: '/doc' }));

// Serve R2 uploaded media (selfies, ID docs)
app.get('/uploads/:prefix/:key', async (c) => {
  const prefix = c.req.param('prefix');
  const key = c.req.param('key');
  const fullKey = `${prefix}/${key}`;

  const object = await c.env.BUCKET.get(fullKey);
  if (!object) {
    return c.text('File Not Found', 404);
  }

  const headers = new Headers();
  object.writeHttpMetadata(headers);
  headers.set('etag', object.httpEtag);

  return new Response(object.body, { headers });
});

// Mount modular sub-routers
app.route('/api/auth', authRoutes);
app.route('/api/verification', verificationRoutes);
app.route('/api/guardians', guardianRoutes);
app.route('/api/groups', groupRoutes);
app.route('/api/chat', chatRoutes);
app.route('/api/ehailing', ehailingRoutes);
app.route('/api/sos', sosRoutes);
app.route('/api/safety-map', safetyMapRoutes);
app.route('/api/ussd', ussdRoutes);
app.route('/api/insights', insightsRoutes);

export { app };

export default {
  fetch: app.fetch,

  // Cloudflare Scheduled (Cron) Worker Trigger
  // Handles checkpoint timeouts, group matching window reminders & escalation timers
  async scheduled(event: ScheduledEvent, env: Env, ctx: ExecutionContext) {
    console.log(`[SafeTrack Cron] Triggered at ${new Date(event.scheduledTime).toISOString()}`);

    // 1. Escalate unacknowledged SOS events older than 3 minutes (180s)
    try {
      const { results: staleSos } = await env.DB.prepare(
        `SELECT id, user_id FROM sos_events
         WHERE status = 'triggered'
         AND datetime(created_at, '+3 minutes') < datetime('now')`
      ).all();

      for (const sos of staleSos) {
        console.log(`[SafeTrack Cron Escalation] Escalating unacknowledged SOS ${sos.id}`);
        await env.DB.prepare(
          `UPDATE sos_events SET status = 'police_escalated' WHERE id = ?`
        )
          .bind(sos.id)
          .run();
      }
    } catch (err) {
      console.error('[SafeTrack Cron Error]', err);
    }
  },
};
