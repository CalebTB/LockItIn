-- Migration: Fix event_visibility enum to use snake_case
-- Purpose: Match app constants which use snake_case (shared_with_name, busy_only)
-- Date: 2026-01-09

-- Add new snake_case enum values
ALTER TYPE event_visibility ADD VALUE IF NOT EXISTS 'shared_with_name';
ALTER TYPE event_visibility ADD VALUE IF NOT EXISTS 'busy_only';

-- Update existing events to use snake_case values
UPDATE events
SET visibility = 'shared_with_name'
WHERE visibility = 'sharedWithName';

UPDATE events
SET visibility = 'busy_only'
WHERE visibility = 'busyOnly';

-- Note: We cannot remove old enum values in PostgreSQL without recreating the type
-- The old values (sharedWithName, busyOnly) will remain but won't be used
-- This is safe because the app only sends/expects snake_case values
