-- Seed initial destinations in pilot areas (e.g. Johannesburg / Soweto / Pretoria taxi ranks and stations)
INSERT OR IGNORE INTO destinations (id, name, category, latitude, longitude, address) VALUES
('dest-bree-taxi', 'Bree Taxi Rank', 'taxi_rank', -26.2003, 28.0385, 'Lilian Ngoyi St, Johannesburg'),
('dest-noord-mtn', 'Noord Street (MTN) Taxi Rank', 'taxi_rank', -26.1979, 28.0468, 'Noord St, Johannesburg CBD'),
('dest-park-station', 'Johannesburg Park Station', 'station', -26.1966, 28.0416, 'Rissik St, Braamfontein'),
('dest-baragwanath', 'Chris Hani Baragwanath Taxi Rank', 'taxi_rank', -26.2608, 27.9405, 'Old Potchefstroom Rd, Soweto'),
('dest-maponya-mall', 'Maponya Mall Rank', 'mall', -26.2625, 27.9015, 'Chris Hani Rd, Klipspruit, Soweto'),
('dest-pretoria-station', 'Pretoria Bosman Station Rank', 'taxi_rank', -25.7578, 28.1887, 'Bosman St, Pretoria Central');

-- Seed sample safety flags
INSERT OR IGNORE INTO safety_flags (id, reported_by_user_id, latitude, longitude, reason, source, severity, description, created_at, expires_at) VALUES
('flag-1', 'system', -26.2010, 28.0400, 'poor_lighting', 'user', 'high', 'Streetlights not working under bridge', datetime('now', '-2 hours'), datetime('now', '+5 days')),
('flag-2', 'system', -26.1985, 28.0440, 'harassment', 'user', 'medium', 'Aggressive loitering reported near alleyway', datetime('now', '-5 hours'), datetime('now', '+3 days'));
