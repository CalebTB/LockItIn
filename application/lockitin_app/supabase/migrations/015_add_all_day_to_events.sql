-- Migration: Add all_day column to events table
-- Purpose: Support all-day events that don't have specific times
-- Date: 2026-01-09

-- Add all_day column to events table
-- Default to false for existing events (they are all timed events)
ALTER TABLE events
ADD COLUMN IF NOT EXISTS all_day BOOLEAN NOT NULL DEFAULT false;

-- Add comment explaining the column
COMMENT ON COLUMN events.all_day IS 'True if this is an all-day event (no specific time). All-day events are stored as local midnight (no UTC conversion).';

-- Create index for filtering all-day vs timed events
CREATE INDEX IF NOT EXISTS idx_events_all_day ON events(all_day);
