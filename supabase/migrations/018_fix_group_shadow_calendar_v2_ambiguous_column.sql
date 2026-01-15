-- Fix ambiguous column reference in get_group_shadow_calendar_v2
-- Issue: When joining shadow_calendar with events table, "user_id" exists in both
-- Solution: Fully qualify all column references with table aliases

DROP FUNCTION IF EXISTS get_group_shadow_calendar_v2(UUID[], UUID, TIMESTAMPTZ, TIMESTAMPTZ);

CREATE OR REPLACE FUNCTION get_group_shadow_calendar_v2(
  p_user_ids UUID[],
  p_requesting_group_id UUID,
  p_start_date TIMESTAMP WITH TIME ZONE,
  p_end_date TIMESTAMP WITH TIME ZONE
)
RETURNS TABLE (
  user_id UUID,
  start_time TIMESTAMPTZ,
  end_time TIMESTAMPTZ,
  visibility TEXT,
  event_title TEXT,
  is_group_event BOOLEAN
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Verify caller is member of requesting group
  IF NOT EXISTS (
    SELECT 1 FROM group_members
    WHERE group_members.group_id = p_requesting_group_id
    AND group_members.user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Access denied: You must be a member of this group';
  END IF;

  -- Return shadow calendar entries with group-aware visibility
  RETURN QUERY
  SELECT
    sc.user_id,
    sc.start_time,
    sc.end_time,
    -- Override visibility for same-group events
    CASE
      WHEN sc.group_id = p_requesting_group_id THEN 'sharedWithName'::TEXT
      WHEN sc.group_id IS NOT NULL AND sc.group_id != p_requesting_group_id THEN 'busyOnly'::TEXT
      ELSE sc.visibility::TEXT
    END AS visibility,
    -- Override title for same-group events
    CASE
      WHEN sc.group_id = p_requesting_group_id THEN (
        SELECT e.title FROM events e WHERE e.id = sc.event_id
      )
      WHEN sc.group_id IS NOT NULL AND sc.group_id != p_requesting_group_id THEN NULL
      ELSE sc.event_title
    END AS event_title,
    -- Mark if this is a group event belonging to the requesting group
    (sc.group_id = p_requesting_group_id) AS is_group_event
  FROM shadow_calendar sc
  WHERE sc.user_id = ANY(p_user_ids)
    AND sc.start_time < p_end_date
    AND sc.end_time > p_start_date
  ORDER BY sc.user_id, sc.start_time;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_group_shadow_calendar_v2(UUID[], UUID, TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated;

COMMENT ON FUNCTION get_group_shadow_calendar_v2 IS
'Fetch shadow calendar entries for group members with group-aware visibility.
Events from the requesting group show full details (sharedWithName + actual title).
Events from other groups show as busy blocks (busyOnly + NULL title).
Personal events respect their original visibility settings.';
