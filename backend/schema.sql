-- SafeTrack Cloudflare D1 Database Schema

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    phone_number TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    id_number TEXT UNIQUE, -- SA ID, driver's license, or passport
    id_type TEXT DEFAULT 'sa_id', -- sa_id, passport, drivers_license
    verified INTEGER DEFAULT 0, -- 0 or 1
    selfie_url TEXT,
    id_doc_url TEXT,
    language TEXT DEFAULT 'en', -- en, zu, af, st
    needs_extra_time INTEGER DEFAULT 0, -- accessibility mobility flag
    guardian_angel_primary INTEGER DEFAULT 0, -- accompany first vs group first
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Guardian Angels table (up to 4 saved per user)
CREATE TABLE IF NOT EXISTS guardian_angels (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    phone_number TEXT NOT NULL,
    relationship TEXT,
    gender TEXT, -- female, male, other
    night_only INTEGER DEFAULT 0, -- user-configurable rule e.g. male family after dark
    verified INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Destinations (preset meeting/drop points e.g. Taxi Rank, Mall, Station)
CREATE TABLE IF NOT EXISTS destinations (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    category TEXT NOT NULL, -- taxi_rank, mall, station, campus
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    address TEXT,
    active INTEGER DEFAULT 1
);

-- Active & Scheduled Walking / Taxi Groups
CREATE TABLE IF NOT EXISTS groups (
    id TEXT PRIMARY KEY,
    destination_id TEXT NOT NULL,
    group_type TEXT NOT NULL DEFAULT 'walk', -- walk, taxi
    taxi_plate TEXT, -- normalized vehicle registration, set when group_type = 'taxi'
    capacity INTEGER NOT NULL DEFAULT 6, -- 6 for a walking pack, 15 riders (+1 driver = 16) for a taxi
    status TEXT NOT NULL DEFAULT 'forming', -- forming, active, completed, cancelled
    departure_time DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (destination_id) REFERENCES destinations(id)
);

-- Group Members
CREATE TABLE IF NOT EXISTS group_members (
    id TEXT PRIMARY KEY,
    group_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    role TEXT DEFAULT 'member', -- leader, member
    pickup_lat REAL,
    pickup_lng REAL,
    pickup_order INTEGER,
    picked_up_at DATETIME,
    safe_checked_in INTEGER DEFAULT 0,
    safe_checked_in_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Active Walk Group Real-time Chat
CREATE TABLE IF NOT EXISTS group_messages (
    id TEXT PRIMARY KEY,
    group_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    user_name TEXT NOT NULL,
    message TEXT NOT NULL,
    quick_action TEXT, -- running_late, arrived, need_help, etc.
    is_flagged INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- E-Hailing Mode Rides
CREATE TABLE IF NOT EXISTS ehailing_trips (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    driver_name TEXT,
    vehicle_registration TEXT,
    service_provider TEXT, -- Uber, Bolt, etc.
    status TEXT DEFAULT 'active', -- active, safe_completed, emergency
    start_lat REAL,
    start_lng REAL,
    current_lat REAL,
    current_lng REAL,
    blacklyst_flagged INTEGER DEFAULT 0,
    blacklyst_details TEXT,
    started_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    ended_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- SOS & Emergency Escalations
CREATE TABLE IF NOT EXISTS sos_events (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    group_id TEXT,
    ehailing_trip_id TEXT,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    status TEXT DEFAULT 'triggered', -- triggered, acknowledged, resolved, false_alarm, police_escalated
    trigger_type TEXT DEFAULT 'app_sos', -- app_sos, hardware_volume, checkpoint_timeout, ussd_report
    distress_message TEXT,
    acknowledged_by TEXT, -- guardian angel name / id
    acknowledged_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Safety Map & Unsafe Spot Flags
CREATE TABLE IF NOT EXISTS safety_flags (
    id TEXT PRIMARY KEY,
    reported_by_user_id TEXT,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    reason TEXT NOT NULL, -- poor_lighting, harassment, isolated, suspicious_activity, sos_triggered
    source TEXT DEFAULT 'user', -- user, sos, ussd
    severity TEXT DEFAULT 'medium', -- low, medium, high, severe
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME
);

-- USSD Reports (Phone lost / bystander fallback)
CREATE TABLE IF NOT EXISTS ussd_reports (
    id TEXT PRIMARY KEY,
    reported_id_number TEXT NOT NULL,
    session_id TEXT,
    phone_dialed_from TEXT,
    report_type TEXT NOT NULL, -- member, stranger, emergency_contact
    target_member_id TEXT,
    pickup_point_ref TEXT,
    stranger_description TEXT,
    status TEXT DEFAULT 'pending_acknowledgment', -- pending_acknowledgment, acknowledged, police_escalated
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Walk Reviews / Feedback
CREATE TABLE IF NOT EXISTS walk_reviews (
    id TEXT PRIMARY KEY,
    group_id TEXT NOT NULL,
    reviewer_user_id TEXT NOT NULL,
    target_user_id TEXT NOT NULL,
    rating INTEGER NOT NULL,
    comment TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES groups(id),
    FOREIGN KEY (reviewer_user_id) REFERENCES users(id),
    FOREIGN KEY (target_user_id) REFERENCES users(id)
);
