-- Migration: Convert visibility column to use event_visibility enum type
-- Purpose: Enforce type safety and ensure visibility values are valid
-- Date: 2026-01-09

-- Change the visibility column from TEXT to event_visibility enum
ALTER TABLE events
ALTER COLUMN visibility TYPE event_visibility
USING visibility::event_visibility;

-- Update the default to use the enum type
ALTER TABLE events
ALTER COLUMN visibility SET DEFAULT 'private'::event_visibility;

-- Do the same for shadow_calendar table
ALTER TABLE shadow_calendar
ALTER COLUMN visibility TYPE event_visibility
USING visibility::event_visibility;

-- shadow_calendar doesn't need a default (it's always set from events)
