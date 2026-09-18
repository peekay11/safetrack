# SafeTrack — Cloudflare Backend

High-performance, edge-first backend for **SafeWalk / SafeTrack** running entirely on the **Cloudflare Workers** serverless ecosystem.

## Architecture

- **Runtime & Framework:** Cloudflare Workers + [Hono](https://hono.dev/)
- **Database (Relational):** [Cloudflare D1](https://developers.cloudflare.com/d1/) (SQLite at edge)
- **Fast Cache & Real-Time Presence:** [Cloudflare KV](https://developers.cloudflare.com/kv/) (OTP codes, active walk live coordinates)
- **Object Storage:** [Cloudflare R2](https://developers.cloudflare.com/r2/) (Selfie verification & ID document uploads)
- **Cron / Escalation Worker:** Cloudflare Scheduled Events (3-minute unacknowledged SOS auto-escalation, checkpoint timeouts)
- **USSD Gateway:** Africa's Talking compatible webhook handler for basic phone / lost-phone incident reporting

---

## API Endpoints Overview

| Module | Method | Endpoint | Description |
|---|---|---|---|
| **Health** | `GET` | `/` | API status & available endpoints |
| **Auth** | `POST` | `/api/auth/send-otp` | Request phone OTP |
| | `POST` | `/api/auth/verify-otp` | Verify OTP & sign in/up (JWT session token) |
| | `GET` | `/api/auth/me` | Current user profile & guardian angels |
| | `PATCH` | `/api/auth/profile` | Update profile, language & accessibility settings |
| **Verification** | `POST` | `/api/verification/selfie` | In-app selfie capture upload (R2) |
| | `POST` | `/api/verification/id-document` | SA ID / Passport / Driver's license document upload (R2) |
| **Guardians** | `GET` | `/api/guardians` | List user's Guardian Angels (up to 4) |
| | `POST` | `/api/guardians` | Add a Guardian Angel contact (with night-only rules) |
| | `DELETE` | `/api/guardians/:id` | Remove a Guardian Angel |
| **Groups** | `GET` | `/api/groups/destinations` | List preset destinations (ranks, malls, stations) |
| | `POST` | `/api/groups/match` | Destination matching with Haversine proximity (100–500m) |
| | `GET` | `/api/groups/:id` | Group status, destination & member roster |
| | `POST` | `/api/groups/:id/location` | Broadcast member's live location (KV) |
| | `GET` | `/api/groups/:id/locations` | Get live locations of all group members |
| | `POST` | `/api/groups/:id/checkpoint-arrival` | Mark pickup checkpoint reached |
| | `POST` | `/api/groups/:id/checkin-safe` | "I am safe" arrival button & auto-completion |
| **Active Walk Chat** | `GET` | `/api/chat/:groupId` | Get group chat messages (closes when safe) |
| | `POST` | `/api/chat/:groupId` | Send message or quick-action (Running late / Arrived / Need help) |
| | `POST` | `/api/chat/:groupId/messages/:msgId/flag` | Flag inappropriate or concerning message |
| **E-Hailing Mode** | `POST` | `/api/ehailing/start` | Start trip with live guardian tracking link & BlackLyst check |
| | `POST` | `/api/ehailing/:id/location` | Stream vehicle/ride coordinates |
| | `POST` | `/api/ehailing/:id/checkin-safe` | End ride with "I am safe" |
| | `GET` | `/api/ehailing/track/:id` | Public live tracking page for Guardian Angels |
| **SOS** | `POST` | `/api/sos/trigger` | Trigger SOS emergency (multilingual distress alert) |
| | `POST` | `/api/sos/:id/acknowledge` | Guardian Angel: "Received — I'm on it" |
| | `POST` | `/api/sos/:id/resolve` | Mark as resolved or false alarm |
| **Safety Map** | `GET` | `/api/safety-map/flags` | Query unsafe spot pins within radius |
| | `POST` | `/api/safety-map/flags` | Drop manual safety pin (with automatic decay) |
| **USSD** | `POST` | `/api/ussd` | Africa's Talking phone-lost reporting flow (ID-based) |

---

## Local Development & Testing

```bash
cd backend

# Run comprehensive automated test suite
npm test

# Run local development worker
npm run dev

# Re-initialize local D1 database schema
npm run db:init
```
