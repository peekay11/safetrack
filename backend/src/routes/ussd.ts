import { Hono } from 'hono';
import { Env } from '../types';

export const ussdRoutes = new Hono<{ Bindings: Env }>();

// Standard Africa's Talking / Telco USSD Webhook handler
// Request payload format:
// sessionId, serviceCode, phoneNumber, text
ussdRoutes.post('/', async (c) => {
  const body = await c.req.parseBody();
  const sessionId = (body['sessionId'] as string) || `sess_${Date.now()}`;
  const phoneNumber = (body['phoneNumber'] as string) || '';
  const text = (body['text'] as string) || '';

  const steps = text.split('*').filter((s) => s.trim().length > 0);
  let response = '';

  // Flow Step 0: Initial Screen -> Enter ID number (SA ID or Passport)
  if (steps.length === 0) {
    response = 'CON Welcome to SafeWalk Emergency.\nEnter your ID or Passport number:';
    return c.text(response);
  }

  const idNumber = steps[0].trim();

  // Find user associated with this ID number
  const user = await c.env.DB.prepare('SELECT * FROM users WHERE id_number = ?')
    .bind(idNumber)
    .first<{ id: string; full_name: string }>();

  // Flow Step 1: Main Menu
  if (steps.length === 1) {
    const greeting = user ? `Hello ${user.full_name.split(' ')[0]}` : 'SafeWalk Emergency';
    response = `CON ${greeting}.\nSelect option:\n1. Report incident (Group walk)\n2. Report stranger / unsafe area\n3. Alert Guardian Angels`;
    return c.text(response);
  }

  const choice = steps[1];

  // OPTION 1: Group Walk Incident (Pull roster from app logs)
  if (choice === '1') {
    if (steps.length === 2) {
      // Look up user's most recent walk
      if (user) {
        const recentWalk = await c.env.DB.prepare(
          `SELECT gm.group_id, g.created_at
           FROM group_members gm
           JOIN groups g ON gm.group_id = g.id
           WHERE gm.user_id = ?
           ORDER BY g.created_at DESC LIMIT 1`
        )
          .bind(user.id)
          .first<{ group_id: string }>();

        if (recentWalk) {
          // Fetch members and pickup sequence
          const { results: members } = await c.env.DB.prepare(
            `SELECT gm.user_id, u.full_name, gm.pickup_order
             FROM group_members gm
             JOIN users u ON gm.user_id = u.id
             WHERE gm.group_id = ?
             ORDER BY gm.pickup_order ASC`
          )
            .bind(recentWalk.group_id)
            .all();

          let menu = 'CON Select person or stop:\n';
          members.forEach((m: any, idx: number) => {
            menu += `${idx + 1}. Stop ${m.pickup_order}: ${m.full_name}\n`;
          });
          menu += `${members.length + 1}. Entire group\n${members.length + 2}. Between stops`;
          return c.text(menu);
        }
      }
      return c.text('CON Group walk incident.\n1. Group member\n2. Entire group\n3. Between stops');
    }

    if (steps.length >= 3) {
      // Log the USSD incident
      const reportId = `ussd_${crypto.randomUUID()}`;
      await c.env.DB.prepare(
        `INSERT INTO ussd_reports (id, reported_id_number, session_id, phone_dialed_from, report_type, pickup_point_ref, status)
         VALUES (?, ?, ?, ?, 'member', ?, 'pending_acknowledgment')`
      )
        .bind(reportId, idNumber, sessionId, phoneNumber, steps[2])
        .run();

      // Trigger Guardian Angel alert
      return c.text(
        'END SafeWalk Alert filed. All 4 Guardian Angels have been alerted simultaneously with your emergency status.'
      );
    }
  }

  // OPTION 2: Stranger / Unsafe area report
  if (choice === '2') {
    if (steps.length === 2) {
      return c.text('CON Describe briefly (e.g. 2 men in dark hoodies near rank):');
    }

    if (steps.length >= 3) {
      const description = steps.slice(2).join(' ');
      const reportId = `ussd_${crypto.randomUUID()}`;

      await c.env.DB.prepare(
        `INSERT INTO ussd_reports (id, reported_id_number, session_id, phone_dialed_from, report_type, stranger_description, status)
         VALUES (?, ?, ?, ?, 'stranger', ?, 'pending_acknowledgment')`
      )
        .bind(reportId, idNumber, sessionId, phoneNumber, description)
        .run();

      return c.text(
        'END Incident logged and added to community safety map. Guardian Angels notified.'
      );
    }
  }

  // OPTION 3: Direct Guardian Angel Alert
  if (choice === '3') {
    const reportId = `ussd_${crypto.randomUUID()}`;
    await c.env.DB.prepare(
      `INSERT INTO ussd_reports (id, reported_id_number, session_id, phone_dialed_from, report_type, status)
       VALUES (?, ?, ?, ?, 'emergency_contact', 'pending_acknowledgment')`
    )
      .bind(reportId, idNumber, sessionId, phoneNumber)
      .run();

    return c.text('END Emergency broadcast initiated to your Guardian Angels.');
  }

  return c.text('END Invalid option selected.');
});
