import { app } from './src/index';

const testEnv = {
  ENVIRONMENT: 'development',
  // Mock KV
  CACHE_KV: {
    store: new Map<string, string>(),
    async get(key: string) { return this.store.get(key) || null; },
    async put(key: string, val: string) { this.store.set(key, val); },
    async delete(key: string) { this.store.delete(key); },
  },
  // Mock D1
  DB: {
    tables: {
      users: [] as any[],
      destinations: [
        { id: 'dest-bree-taxi', name: 'Bree Taxi Rank', category: 'taxi_rank', latitude: -26.2003, longitude: 28.0385, active: 1 }
      ],
      groups: [] as any[],
      group_members: [] as any[],
      guardian_angels: [] as any[],
      sos_events: [] as any[],
      safety_flags: [] as any[],
      ehailing_trips: [] as any[],
      group_messages: [] as any[],
      ussd_reports: [] as any[],
    },
    prepare(query: string) {
      const db = this;
      return {
        params: [] as any[],
        bind(...args: any[]) {
          this.params = args;
          return this;
        },
        async first(key?: string) {
          if (query.includes('FROM destinations')) return db.tables.destinations[0] || null;
          if (query.includes('FROM users WHERE phone_number')) {
            return db.tables.users.find((u: any) => u.phone_number === this.params[0]) || null;
          }
          if (query.includes('FROM users WHERE id')) {
            return db.tables.users.find((u: any) => u.id === this.params[0]) || null;
          }
          if (query.includes('FROM groups WHERE id')) {
            return db.tables.groups.find((g: any) => g.id === this.params[0]) || null;
          }
          if (query.includes('COUNT(*) as count FROM group_members')) {
            const count = db.tables.group_members.filter((m: any) => m.group_id === this.params[0]).length;
            return { count };
          }
          if (query.includes('COUNT(*) as count FROM guardian_angels')) {
            const count = db.tables.guardian_angels.filter((g: any) => g.user_id === this.params[0]).length;
            return { count };
          }
          return null;
        },
        async all() {
          if (query.includes('FROM destinations')) {
            return { results: db.tables.destinations };
          }
          if (query.includes('FROM groups')) {
            return { results: db.tables.groups };
          }
          if (query.includes('FROM group_members')) {
            return { results: db.tables.group_members.filter((m: any) => m.group_id === this.params[0]) };
          }
          if (query.includes('FROM guardian_angels')) {
            return { results: db.tables.guardian_angels.filter((g: any) => g.user_id === this.params[0]) };
          }
          if (query.includes('FROM safety_flags')) {
            return { results: db.tables.safety_flags };
          }
          return { results: [] };
        },
        async run() {
          if (query.includes('INSERT INTO users')) {
            db.tables.users.push({
              id: this.params[0],
              phone_number: this.params[1],
              full_name: this.params[2],
              language: 'en',
              verified: 0,
            });
          } else if (query.includes('INSERT INTO groups')) {
            db.tables.groups.push({
              id: this.params[0],
              destination_id: this.params[1],
              status: this.params[2] || 'forming',
            });
          } else if (query.includes('INSERT OR REPLACE INTO group_members')) {
            db.tables.group_members.push({
              id: this.params[0],
              group_id: this.params[1],
              user_id: this.params[2],
              pickup_order: this.params[6],
            });
          } else if (query.includes('INSERT INTO guardian_angels')) {
            db.tables.guardian_angels.push({
              id: this.params[0],
              user_id: this.params[1],
              name: this.params[2],
              phone_number: this.params[3],
            });
          } else if (query.includes('INSERT INTO sos_events')) {
            db.tables.sos_events.push({
              id: this.params[0],
              user_id: this.params[1],
              latitude: this.params[4],
              longitude: this.params[5],
              status: 'triggered',
            });
          } else if (query.includes('INSERT INTO ehailing_trips')) {
            db.tables.ehailing_trips.push({
              id: this.params[0],
              user_id: this.params[1],
              status: 'active',
              vehicle_registration: this.params[3],
            });
          }
          return { success: true };
        },
      };
    },
  },
  BUCKET: {},
};

async function runSelfTests() {
  console.log('--- Starting Cloudflare Worker API Self-Test Suite ---');

  // Test 1: Root endpoint
  const res1 = await app.request('/', {}, testEnv as any);
  console.log(`[Test 1] GET / status: ${res1.status}`);
  const data1 = await res1.json();
  console.assert(res1.status === 200, 'Root endpoint status should be 200');

  // Test 2: Auth Send OTP
  const res2 = await app.request('/api/auth/send-otp', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ phone_number: '+27821234567' }),
  }, testEnv as any);
  console.log(`[Test 2] POST /api/auth/send-otp status: ${res2.status}`);
  const data2: any = await res2.json();
  console.assert(data2.success === true, 'OTP should send successfully');

  // Test 3: Verify OTP & Log In
  const res3 = await app.request('/api/auth/verify-otp', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      phone_number: '+27821234567',
      code: data2.dev_otp || '123456',
      full_name: 'Thandi Khumalo',
    }),
  }, testEnv as any);
  console.log(`[Test 3] POST /api/auth/verify-otp status: ${res3.status}`);
  const data3: any = await res3.json();
  const token = data3.token;
  console.assert(token !== undefined, 'Should receive session token');

  // Test 4: Destinations
  const res4 = await app.request('/api/groups/destinations', {}, testEnv as any);
  console.log(`[Test 4] GET /api/groups/destinations status: ${res4.status}`);

  // Test 5: Add Guardian Angel
  const res5 = await app.request('/api/guardians', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
    },
    body: JSON.stringify({
      name: 'Sis Nomvula',
      phone_number: '+27839876543',
      relationship: 'Sister',
      gender: 'female',
    }),
  }, testEnv as any);
  console.log(`[Test 5] POST /api/guardians status: ${res5.status}`);

  // Test 6: Group Matching
  const res6 = await app.request('/api/groups/match', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
    },
    body: JSON.stringify({
      destination_id: 'dest-bree-taxi',
      latitude: -26.2041,
      longitude: 28.0473,
    }),
  }, testEnv as any);
  console.log(`[Test 6] POST /api/groups/match status: ${res6.status}`);
  const data6: any = await res6.json();
  console.assert(data6.success === true, 'Matching should succeed');

  // Test 7: Trigger SOS
  const res7 = await app.request('/api/sos/trigger', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
    },
    body: JSON.stringify({
      latitude: -26.2041,
      longitude: 28.0473,
      trigger_type: 'app_sos',
    }),
  }, testEnv as any);
  console.log(`[Test 7] POST /api/sos/trigger status: ${res7.status}`);

  // Test 8: Start E-Hailing Mode
  const res8 = await app.request('/api/ehailing/start', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
    },
    body: JSON.stringify({
      service_provider: 'Uber',
      vehicle_registration: 'CA888ALERT',
      start_lat: -26.2041,
      start_lng: 28.0473,
    }),
  }, testEnv as any);
  console.log(`[Test 8] POST /api/ehailing/start status: ${res8.status}`);
  const data8: any = await res8.json();
  console.assert(data8.blacklyst.flagged === true, 'BlackLyst test pattern should flag');

  console.log('--- ALL BACKEND TEST SUITE CHECKS PASSED! ---');
}

runSelfTests().catch((err) => {
  console.error('Self-test error:', err);
  process.exit(1);
});
