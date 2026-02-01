-- Migration: Fix Personal Event Visibility in Group Calendar
-- Date: 2026-02-01
-- Purpose: Personal events with "Shared with Details" should show titles, not "Busy"

-- ============================================================================
-- PRIVACY FIX: Respect Personal Event Visibility Settings
-- ============================================================================

-- Drop existing function
DROP FUNCTION IF EXISTS get_group_shadow_calendar_v3(UUID, TIMESTAMPTZ, TIMESTAMPTZ);

-- Recreate with fixed visibility logic
CREATE OR REPLACE FUNCTION get_group_shadow_calendar_v3(
  p_group_id UUID,
  p_start_time TIMESTAMPTZ,
  p_end_time TIMESTAMPTZ
)
RETURNS TABLE (
  user_id UUID,
  event_id UUID,
  start_time TIMESTAMPTZ,
  end_time TIMESTAMPTZ,
  event_title TEXT,
  visibility TEXT,
  is_group_event BOOLEAN
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Security check: Caller must be a member of the requesting group
  IF NOT EXISTS (
    SELECT 1 FROM group_members
    WHERE group_members.group_id = p_group_id
    AND group_members.user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Access denied: Not a member of this group';
  END IF;

  -- Return shadow calendar entries for ALL group members (including self)
  RETURN QUERY
  SELECT
    sc.user_id,
    sc.event_id,
    sc.start_time,
    sc.end_time,
    -- Title visibility logic:
    -- 1. Personal events (group_id IS NULL): Respect original visibility
    -- 2. Same-group events: Always show title
    -- 3. Cross-group events: NULL if show_busy_to_all_groups is true
    CASE
      WHEN sc.group_id IS NULL THEN
        -- Personal event: Use original visibility
        CASE WHEN sc.visibility = 'sharedWithName' THEN sc.event_title ELSE NULL END
      WHEN sc.group_id = p_group_id THEN
        -- Same-group event: Show title
        sc.event_title
      WHEN e.show_busy_to_all_groups = true THEN
        -- Cross-group event with privacy setting: Hide title
        NULL
      ELSE NULL
    END AS event_title,
    -- Visibility level:
    -- 1. Personal events: Use original visibility from shadow_calendar
    -- 2. Same-group events: Always sharedWithName
    -- 3. Cross-group events: busyOnly if show_busy_to_all_groups is true
    CASE
      WHEN sc.group_id IS NULL THEN
        -- Personal event: Original visibility
        sc.visibility::TEXT
      WHEN sc.group_id = p_group_id THEN
        -- Same-group event: Full details
        'sharedWithName'::TEXT
      WHEN e.show_busy_to_all_groups = true THEN
        -- Cross-group event: Busy only
        'busyOnly'::TEXT
      ELSE sc.visibility::TEXT
    END AS visibility,
    -- Flag for UI to distinguish group events from personal events
    COALESCE(sc.group_id IS NOT NULL, false) AS is_group_event
  FROM shadow_calendar sc
  JOIN events e ON e.id = sc.event_id
  WHERE sc.user_id IN (
    -- All group members (including requesting user)
    SELECT user_id FROM group_members
    WHERE group_id = p_group_id
  )
  AND sc.start_time < p_end_time
  AND sc.end_time > p_start_time
  ORDER BY sc.user_id, sc.start_time;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_group_shadow_calendar_v3 TO authenticated;

COMMENT ON FUNCTION get_group_shadow_calendar_v3 IS
'Fetch shadow calendar entries for group members with privacy-aware visibility.

Privacy rules:
1. Personal events (group_id IS NULL):
   - Respect original visibility from shadow_calendar
   - sharedWithName → Show title
   - busyOnly → Show as busy block
2. Same-group events (group_id = p_group_id):
   - Always show full details (title visible, sharedWithName)
3. Cross-group events (different group_id):
   - Show as busy blocks if show_busy_to_all_groups = true (no title, busyOnly)
   - Otherwise respect original visibility

Security:
- SECURITY DEFINER: Runs with function owner permissions
- RLS check: Caller must be a group member
- Includes requesting user to show complete availability

Parameters:
- p_group_id: Group to fetch availability for
- p_start_time: Start of date range (UTC)
- p_end_time: End of date range (UTC)

Returns: Shadow calendar entries ordered by user_id, start_time';
