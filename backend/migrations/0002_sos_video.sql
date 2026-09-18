-- Adds optional SOS video-evidence support to an already-deployed table.
ALTER TABLE sos_events ADD COLUMN video_url TEXT;
