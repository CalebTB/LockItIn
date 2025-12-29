-- Shadow Calendar Schema for LockItIn
-- This table stores denormalized availability data for efficient group availability queries
-- Privacy is enforced at the database level - only non-private events are synced
--
-- HOW TO APPLY THIS SCHEMA:
-- 1. Go to https://app.supabase.com/
-- 2. Select your project
-- 3. Go to SQL Editor
-- 4. Copy and paste this entire file
-- 5. Click "Run" to execute
--
-- IMPORTANT: Run this AFTER applying schema.sql and groups_schema.sql
--
-- Last updated: December 29, 2025

-- ============================================================================
-- SHADOW CALENDAR TABLE
-- ============================================================================
-- Stores availability blocks for users, synced from their events
-- Only non-private events are synced (busyOnly and sharedWithName)
-- Group members can query this table to see aggregated availability

CREATE TABLE IF NOT EXISTS shadow_calendar (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Reference to the source event
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,

  -- Denormalized user reference (for efficient queries without joins)
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Time block (copied from event for efficient range queries)
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE NOT NULL,

  -- Visibility level determines what group members can see:
  -- 'busyOnly' = Show as "Busy" (no title)
  -- 'sharedWithName' = Show event title
  visibility event_visibility NOT NULL,

  -- Event title (only populated for 'sharedWithName' visibility)
  -- NULL for 'busyOnly' to enforce privacy at DB level
  event_title TEXT,

  -- Timestamps for sync tracking
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE,

  -- Constraints
  CONSTRAINT valid_shadow_time_range CHECK (end_time > start_time),
  CONSTRAINT valid_title_for_visibility CHECK (
    (visibility = 'busyOnly'::event_visibility AND event_title IS NULL) OR
    (visibility = 'sharedWithName'::event_visibility AND event_title IS NOT NULL) OR
    (visibility = 'private'::event_visibility) -- Should never happen due to trigger, but defensive
  )
);

-- Add updated_at trigger
CREATE TRIGGER update_shadow_calendar_updated_at
BEFORE UPDATE ON shadow_calendar
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- INDEXES for Performance
-- ============================================================================

-- Index for querying by user (most common pattern)
CREATE INDEX IF NOT EXISTS idx_shadow_calendar_user_id
ON shadow_calendar(user_id);

-- Index for date range queries (critical for availability heatmaps)
CREATE INDEX IF NOT EXISTS idx_shadow_calendar_time_range
ON shadow_calendar(start_time, end_time);

-- Composite index for user + time range (most common query pattern)
CREATE INDEX IF NOT EXISTS idx_shadow_calendar_user_time
ON shadow_calendar(user_id, start_time, end_time);

-- Index for finding shadow entries by source event (for updates/deletes)
CREATE INDEX IF NOT EXISTS idx_shadow_calendar_event_id
ON shadow_calendar(event_id);

-- ============================================================================
-- SYNC TRIGGER: Events -> Shadow Calendar
-- ============================================================================
-- Automatically syncs events to shadow_calendar when:
-- - Event is created with non-private visibility
-- - Event visibility changes from private to non-private
-- - Event times are updated
-- - Event is deleted (cascade handles this)

CREATE OR REPLACE FUNCTION sync_event_to_shadow_calendar()
RETURNS TRIGGER AS $$
BEGIN
  -- Handle INSERT
  IF TG_OP = 'INSERT' THEN
    -- Only sync non-private events
    IF NEW.visibility != 'private'::event_visibility THEN
      INSERT INTO shadow_calendar (
        event_id,
        user_id,
        start_time,
        end_time,
        visibility,
        event_title
      ) VALUES (
        NEW.id,
        NEW.user_id,
        NEW.start_time,
        NEW.end_time,
        NEW.visibility,
        CASE WHEN NEW.visibility = 'sharedWithName'::event_visibility THEN NEW.title ELSE NULL END
      );
    END IF;
    RETURN NEW;
  END IF;

  -- Handle UPDATE
  IF TG_OP = 'UPDATE' THEN
    -- Case 1: Event changed TO private - remove from shadow calendar
    IF NEW.visibility = 'private'::event_visibility AND OLD.visibility != 'private'::event_visibility THEN
      DELETE FROM shadow_calendar WHERE event_id = NEW.id;
      RETURN NEW;
    END IF;

    -- Case 2: Event changed FROM private - add to shadow calendar
    IF NEW.visibility != 'private'::event_visibility AND OLD.visibility = 'private'::event_visibility THEN
      INSERT INTO shadow_calendar (
        event_id,
        user_id,
        start_time,
        end_time,
        visibility,
        event_title
      ) VALUES (
        NEW.id,
        NEW.user_id,
        NEW.start_time,
        NEW.end_time,
        NEW.visibility,
        CASE WHEN NEW.visibility = 'sharedWithName'::event_visibility THEN NEW.title ELSE NULL END
      );
      RETURN NEW;
    END IF;

    -- Case 3: Event is non-private and something changed - update shadow calendar
    IF NEW.visibility != 'private'::event_visibility THEN
      UPDATE shadow_calendar
      SET
        start_time = NEW.start_time,
        end_time = NEW.end_time,
        visibility = NEW.visibility,
        event_title = CASE WHEN NEW.visibility = 'sharedWithName'::event_visibility THEN NEW.title ELSE NULL END,
        updated_at = now()
      WHERE event_id = NEW.id;
    END IF;

    RETURN NEW;
  END IF;

  -- Handle DELETE (CASCADE handles this, but explicit for clarity)
  IF TG_OP = 'DELETE' THEN
    DELETE FROM shadow_calendar WHERE event_id = OLD.id;
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on events table
DROP TRIGGER IF EXISTS sync_events_to_shadow ON events;
CREATE TRIGGER sync_events_to_shadow
AFTER INSERT OR UPDATE OR DELETE ON events
FOR EACH ROW
EXECUTE FUNCTION sync_event_to_shadow_calendar();

-- ============================================================================
-- RLS POLICIES: Shadow Calendar Access Control
-- ============================================================================

-- Enable RLS
ALTER TABLE shadow_calendar ENABLE ROW LEVEL SECURITY;

-- Policy 1: Users can always see their own shadow calendar entries
CREATE POLICY "Users can view own shadow calendar"
ON shadow_calendar
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Policy 2: Group members can see shadow calendar of other group members
-- Uses the existing auth_is_group_member function from groups_schema.sql
CREATE POLICY "Group members can view each other's shadow calendar"
ON shadow_calendar
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM group_members gm1
    JOIN group_members gm2 ON gm1.group_id = gm2.group_id
    WHERE gm1.user_id = auth.uid()
    AND gm2.user_id = shadow_calendar.user_id
    AND gm1.user_id != gm2.user_id
  )
);

-- Note: INSERT/UPDATE/DELETE are handled by the sync trigger (SECURITY DEFINER)
-- No explicit policies needed for writes since the trigger bypasses RLS
-- Users cannot directly modify shadow_calendar - only triggers can

-- ============================================================================
-- RPC FUNCTION: Get Shadow Calendar for Multiple Users
-- ============================================================================
-- Efficient function for fetching availability of multiple group members
-- Returns availability blocks within a date range

CREATE OR REPLACE FUNCTION get_group_shadow_calendar(
  p_user_ids UUID[],
  p_start_date TIMESTAMP WITH TIME ZONE,
  p_end_date TIMESTAMP WITH TIME ZONE
)
RETURNS TABLE (
  user_id UUID,
  start_time TIMESTAMP WITH TIME ZONE,
  end_time TIMESTAMP WITH TIME ZONE,
  visibility TEXT,
  event_title TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Verify caller is a group member with at least one of the requested users
  IF NOT EXISTS (
    SELECT 1 FROM group_members gm1
    JOIN group_members gm2 ON gm1.group_id = gm2.group_id
    WHERE gm1.user_id = auth.uid()
    AND gm2.user_id = ANY(p_user_ids)
  ) AND NOT (auth.uid() = ANY(p_user_ids)) THEN
    RAISE EXCEPTION 'Access denied: You must be in a group with the requested users';
  END IF;

  RETURN QUERY
  SELECT
    sc.user_id,
    sc.start_time,
    sc.end_time,
    sc.visibility::TEXT,
    sc.event_title
  FROM shadow_calendar sc
  WHERE sc.user_id = ANY(p_user_ids)
    AND sc.start_time < p_end_date
    AND sc.end_time > p_start_date
  ORDER BY sc.user_id, sc.start_time;
END;
$$;

-- ============================================================================
-- MIGRATION: Sync Existing Events to Shadow Calendar
-- ============================================================================
-- Run this once to populate shadow_calendar with existing non-private events
--
-- TODO (Pre-Launch - Issue #120): The events.visibility column should be migrated
-- from TEXT to event_visibility enum type for better type safety. Run this migration:
--
--   ALTER TABLE events
--   ALTER COLUMN visibility TYPE event_visibility
--   USING visibility::event_visibility;
--
-- After that migration, the ::text casts below can be removed and replaced with
-- direct enum comparisons (e.g., visibility = 'private'::event_visibility)
-- ============================================================================

INSERT INTO shadow_calendar (event_id, user_id, start_time, end_time, visibility, event_title)
SELECT
  id,
  user_id,
  start_time,
  end_time,
  visibility::event_visibility,
  CASE WHEN visibility::text = 'sharedWithName' THEN title ELSE NULL END
FROM events
WHERE visibility::text != 'private'
ON CONFLICT DO NOTHING;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check shadow_calendar table exists
-- SELECT table_name, column_name, data_type
-- FROM information_schema.columns
-- WHERE table_name = 'shadow_calendar';

-- Check trigger exists
-- SELECT trigger_name, event_object_table
-- FROM information_schema.triggers
-- WHERE trigger_name = 'sync_events_to_shadow';

-- Test shadow calendar sync
-- INSERT INTO events (user_id, title, start_time, end_time, visibility)
-- VALUES (auth.uid(), 'Test Event', now(), now() + interval '1 hour', 'busyOnly');
-- SELECT * FROM shadow_calendar WHERE event_title IS NULL;

-- ============================================================================
-- NEXT STEPS
-- ============================================================================
--
-- After running this schema:
-- 1. Verify shadow_calendar table was created
-- 2. Verify trigger is active by creating a test event
-- 3. Update Flutter EventService to use get_group_shadow_calendar RPC
-- 4. Test group availability queries
--
-- ============================================================================
