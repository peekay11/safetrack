-- Adds taxi-group support to an already-deployed `groups` table.
-- Safe to run once; re-running fails harmlessly on "duplicate column".
ALTER TABLE groups ADD COLUMN group_type TEXT NOT NULL DEFAULT 'walk';
ALTER TABLE groups ADD COLUMN taxi_plate TEXT;
ALTER TABLE groups ADD COLUMN capacity INTEGER NOT NULL DEFAULT 6;
