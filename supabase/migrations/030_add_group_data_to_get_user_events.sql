-- Migration: Add Group Data to get_user_events RPC
-- Date: 2026-02-01
-- Purpose: Include group name and emoji in get_user_events for badge display

-- Drop existing function
DROP FUNCTION IF EXISTS get_user_events(UUID, TIMESTAMPTZ, TIMESTAMPTZ);

-- Recreate with group data
CREATE OR REPLACE FUNCTION get_user_events(
  p_user_id UUID,
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ
)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  title TEXT,
  description TEXT,
  location TEXT,
  start_time TIMESTAMPTZ,
  end_time TIMESTAMPTZ,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  native_calendar_id TEXT,
  visibility TEXT,
  category TEXT,
  all_day BOOLEAN,
  group_id UUID,
  template_data JSONB,
  group_name TEXT,
  group_emoji TEXT
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT
    e.id,
    e.user_id,
    e.title,
    e.description,
    e.location,
    e.start_time,
    e.end_time,
    e.created_at,
    e.updated_at,
    e.native_calendar_id,
    e.visibility::TEXT,
    e.category,
    e.all_day,
    e.group_id,
    e.template_data,
    g.name::TEXT AS group_name,
    g.emoji::TEXT AS group_emoji
  FROM events e
  LEFT JOIN groups g ON g.id = e.group_id
  WHERE e.start_time >= p_start_date
    AND e.start_time <= p_end_date
    AND (
      -- Events created by the user
      e.user_id = p_user_id
      OR
      -- Events the user is invited to
      EXISTS (
        SELECT 1 FROM event_invitations ei
        WHERE ei.event_id = e.id
        AND ei.user_id = p_user_id
      )
    )
  ORDER BY e.start_time;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_user_events(UUID, TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated;

COMMENT ON FUNCTION get_user_events IS
'Fetch all events visible to a user (created by them OR invited to) within a date range.
Includes group name and emoji via LEFT JOIN for group badge display.
Used to show both personal and invited events in calendar view.';
