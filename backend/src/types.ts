export interface Env {
  DB: D1Database;
  CACHE_KV: KVNamespace;
  BUCKET: R2Bucket;
  ENVIRONMENT?: string;
  JWT_SECRET?: string;
  AFRICAS_TALKING_API_KEY?: string;
  AFRICAS_TALKING_USERNAME?: string;
  TWILIO_ACCOUNT_SID?: string;
  TWILIO_AUTH_TOKEN?: string;
  TWILIO_FROM_NUMBER?: string;
}

export interface User {
  id: string;
  phone_number: string;
  full_name: string;
  id_number?: string;
  id_type?: string;
  verified: number;
  selfie_url?: string;
  id_doc_url?: string;
  language: string;
  needs_extra_time: number;
  guardian_angel_primary: number;
  created_at: string;
  updated_at: string;
}

export interface GuardianAngel {
  id: string;
  user_id: string;
  name: string;
  phone_number: string;
  relationship?: string;
  gender?: string;
  night_only: number;
  verified: number;
  created_at: string;
}

export interface Destination {
  id: string;
  name: string;
  category: string;
  latitude: number;
  longitude: number;
  address?: string;
  active: number;
}

export interface Group {
  id: string;
  destination_id: string;
  status: 'forming' | 'active' | 'completed' | 'cancelled';
  departure_time?: string;
  created_at: string;
  updated_at: string;
}

export interface GroupMember {
  id: string;
  group_id: string;
  user_id: string;
  role: string;
  pickup_lat?: number;
  pickup_lng?: number;
  pickup_order?: number;
  picked_up_at?: string;
  safe_checked_in: number;
  safe_checked_in_at?: string;
  created_at: string;
}

export interface GroupMessage {
  id: string;
  group_id: string;
  user_id: string;
  user_name: string;
  message: string;
  quick_action?: string;
  is_flagged: number;
  created_at: string;
}

export interface EhailingTrip {
  id: string;
  user_id: string;
  driver_name?: string;
  vehicle_registration?: string;
  service_provider?: string;
  status: 'active' | 'safe_completed' | 'emergency';
  start_lat?: number;
  start_lng?: number;
  current_lat?: number;
  current_lng?: number;
  blacklyst_flagged: number;
  blacklyst_details?: string;
  started_at: string;
  ended_at?: string;
}

export interface SOSEvent {
  id: string;
  user_id: string;
  group_id?: string;
  ehailing_trip_id?: string;
  latitude: number;
  longitude: number;
  status: 'triggered' | 'acknowledged' | 'resolved' | 'false_alarm' | 'police_escalated';
  trigger_type: string;
  distress_message?: string;
  acknowledged_by?: string;
  acknowledged_at?: string;
  created_at: string;
}

export interface SafetyFlag {
  id: string;
  reported_by_user_id?: string;
  latitude: number;
  longitude: number;
  reason: string;
  source: string;
  severity: string;
  description?: string;
  created_at: string;
  expires_at?: string;
}
