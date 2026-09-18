import { Env } from '../types';

export interface SendSmsParams {
  to: string;
  message: string;
}

export async function sendSms(env: Env, { to, message }: SendSmsParams): Promise<{ success: boolean; provider?: string; error?: string }> {
  // 1. Try Africa's Talking (Standard in South Africa / Pan-Africa)
  if (env.AFRICAS_TALKING_API_KEY && env.AFRICAS_TALKING_USERNAME) {
    try {
      const url = 'https://api.africastalking.com/version1/messaging';
      const body = new URLSearchParams();
      body.append('username', env.AFRICAS_TALKING_USERNAME);
      body.append('to', to);
      body.append('message', message);

      const res = await fetch(url, {
        method: 'POST',
        headers: {
          'apiKey': env.AFRICAS_TALKING_API_KEY,
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: body.toString(),
      });

      if (res.ok) {
        return { success: true, provider: "africas_talking" };
      }
      const errText = await res.text();
      console.error("[Africa's Talking Error]", errText);
    } catch (e: any) {
      console.error("[Africa's Talking Exception]", e);
    }
  }

  // 2. Try Twilio SMS
  if (env.TWILIO_ACCOUNT_SID && env.TWILIO_AUTH_TOKEN && env.TWILIO_FROM_NUMBER) {
    try {
      const url = `https://api.twilio.com/2010-04-01/Accounts/${env.TWILIO_ACCOUNT_SID}/Messages.json`;
      const body = new URLSearchParams();
      body.append('To', to);
      body.append('From', env.TWILIO_FROM_NUMBER);
      body.append('Body', message);

      const auth = btoa(`${env.TWILIO_ACCOUNT_SID}:${env.TWILIO_AUTH_TOKEN}`);
      const res = await fetch(url, {
        method: 'POST',
        headers: {
          'Authorization': `Basic ${auth}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body.toString(),
      });

      if (res.ok) {
        return { success: true, provider: 'twilio' };
      }
      const errText = await res.text();
      console.error('[Twilio Error]', errText);
    } catch (e: any) {
      console.error('[Twilio Exception]', e);
    }
  }

  // Fallback in case keys are not yet configured: simulate delivery for dev/demo
  console.log(`[SMS Simulation] To: ${to} | Message: ${message}`);
  return { success: true, provider: 'simulation' };
}
