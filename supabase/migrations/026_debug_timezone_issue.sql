-- Migration: Debug Timezone Issue
-- Date: 2026-02-01
-- Purpose: Add a helper function to debug timezone handling

-- ============================================================================
-- DEBUG FUNCTION: Check how timestamps are stored and should be displayed
-- ============================================================================

CREATE OR REPLACE FUNCTION debug_event_timezone(p_event_id UUID)
RETURNS TABLE (
  event_title TEXT,
  start_time_utc TIMESTAMPTZ,
  start_time_string TEXT,
  start_time_epoch BIGINT,
  start_date_utc DATE,
  start_date_pst DATE,
  timezone_offset TEXT
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    e.title,
    e.start_time,
    e.start_time::TEXT,
    EXTRACT(EPOCH FROM e.start_time)::BIGINT,
    e.start_time::DATE AS start_date_utc,
    (e.start_time AT TIME ZONE 'America/Los_Angeles')::DATE AS start_date_pst,
    (e.start_time AT TIME ZONE 'America/Los_Angeles')::TEXT AS tz_offset
  FROM events e
  WHERE e.id = p_event_id;
END;
$$;

GRANT EXECUTE ON FUNCTION debug_event_timezone TO authenticated;

COMMENT ON FUNCTION debug_event_timezone IS
'Debug function to check timezone handling for events.
Shows how timestamps are stored in UTC and how they should be displayed in PST.';
