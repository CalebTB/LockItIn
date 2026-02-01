---
module: LockItIn Shadow Calendar
date: 2026-02-01
problem_type: logic_error
component: database
symptoms:
  - "Personal events with 'Shared with Details' showing as 'Busy'"
  - "RPC function applying wrong privacy logic to personal events"
root_cause: logic_error
resolution_type: migration
severity: high
tags: [rpc, privacy, shadow-calendar, visibility, postgresql]
---

# Troubleshooting: Personal Event Visibility Logic Error in Shadow Calendar RPC

## Problem
Personal events with "Shared with Details" visibility were incorrectly showing as "Busy" blocks in group calendars. The RPC function `get_group_shadow_calendar_v3` was applying cross-group privacy settings (`show_busy_to_all_groups`) to personal events (events with `group_id IS NULL`), hiding event titles that should have been visible based on the user's chosen visibility setting.

## Environment
- Module: LockItIn Shadow Calendar
- Database: Supabase (PostgreSQL 15)
- Affected Component: `get_group_shadow_calendar_v3` RPC function
- Privacy Model: Shadow Calendar dual-table architecture with per-event visibility
- Date: 2026-02-01

## Symptoms
- User selects "Shared with Details" when creating a personal event
- Event appears in personal calendar with title visible (correct)
- Same event appears in group calendar as "Busy" block without title (wrong)
- Expected: Group members should see the event title because visibility is `sharedWithName`
- Actual: Event title is NULL, showing as generic "Busy" block

## What Didn't Work

**Direct solution:** The problem was identified and fixed on the first attempt after the user reported the bug.

## Solution

**Migration 027: Add Three-Tier Privacy Logic**

Added logic to distinguish between three types of events:
1. **Personal events** (`group_id IS NULL`) - Respect original visibility setting
2. **Same-group events** (`group_id = p_group_id`) - Always show full details
3. **Cross-group events** (different `group_id`) - Apply `show_busy_to_all_groups` setting

```sql
-- Migration: supabase/migrations/027_fix_personal_event_visibility.sql

DROP FUNCTION IF EXISTS get_group_shadow_calendar_v3(UUID, TIMESTAMPTZ, TIMESTAMPTZ);

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
```

**Key Changes:**
1. **Added NULL check**: `WHEN sc.group_id IS NULL` distinguishes personal events
2. **Respect original visibility**: Personal events use `sc.visibility` from shadow_calendar
3. **Three-tier CASE logic**: Handles personal, same-group, and cross-group events separately
4. **Documentation**: Added comprehensive comment explaining privacy rules

## Why This Works

**Root Cause:**
The original RPC function only had logic for group events. It didn't distinguish between:
- Personal events created by the user (stored with `group_id = NULL`)
- Group events belonging to the requesting group
- Group events belonging to other groups (cross-group)

All non-same-group events were treated as "cross-group events" and subjected to the `show_busy_to_all_groups` privacy check, which incorrectly hid personal event titles.

**Why the solution addresses this:**
1. **Explicit personal event handling**: The `sc.group_id IS NULL` check creates a separate code path for personal events
2. **Respects user choice**: Personal events use the visibility setting from `shadow_calendar.visibility`, which reflects what the user selected during event creation
3. **Preserves group event privacy**: Same-group and cross-group events still follow their own privacy rules
4. **Clear decision tree**:
   - Is `group_id` NULL? → Personal event, use original visibility
   - Is `group_id` = requesting group? → Same-group event, show everything
   - Is `group_id` different? → Cross-group event, apply privacy setting

**Underlying Issue:**
This was a logic error in the privacy enforcement system. The Shadow Calendar architecture correctly synced personal events to `shadow_calendar` with their visibility settings, but the RPC function lacked the conditional logic to respect those settings for non-group events.

## Prevention

**To avoid privacy logic errors in future Shadow Calendar / RPC development:**

1. **Always distinguish event types in privacy logic:**
   ```sql
   ✅ CORRECT: Three-tier logic
   CASE
     WHEN group_id IS NULL THEN [personal event logic]
     WHEN group_id = p_group_id THEN [same-group logic]
     ELSE [cross-group logic]
   END

   ❌ WRONG: Only two cases (assumes non-same-group = cross-group)
   CASE
     WHEN group_id = p_group_id THEN [same-group logic]
     ELSE [treat all others the same]
   END
   ```

2. **Test all event types when changing privacy logic:**
   - Personal events with `sharedWithName`
   - Personal events with `busyOnly`
   - Same-group events
   - Cross-group events with `show_busy_to_all_groups = true`
   - Cross-group events with `show_busy_to_all_groups = false`

3. **Document privacy rules in RPC function comments:**
   - Clear explanation of how each event type is handled
   - Example scenarios for each privacy setting
   - Security guarantees provided by RLS + function logic

4. **Verify shadow_calendar sync preserves visibility:**
   - Confirm that `sync_event_to_shadow_calendar()` trigger copies visibility correctly
   - Check that personal events (`group_id IS NULL`) are synced to shadow_calendar
   - Validate that visibility enum values match between `events` and `shadow_calendar`

5. **Use descriptive variable/column names:**
   - `sc.group_id` makes it clear we're checking the event's group association
   - `p_group_id` makes it clear we're comparing to the requesting group
   - This clarity helps prevent logic errors

6. **Add comprehensive function comments:**
   - Document all privacy rules
   - Explain each CASE branch
   - Provide examples of what each visibility level means

## Related Issues

- See also: [enum-comparison-ambiguous-column-rpc-shadow-calendar-20260201.md](../database-issues/enum-comparison-ambiguous-column-rpc-shadow-calendar-20260201.md) - This fix initially broke the heatmap due to enum comparison issues

## Additional Context

**Shadow Calendar Architecture:**
The dual-table architecture stores:
- `events` table: ALL events (private, busyOnly, sharedWithName) with full details
- `shadow_calendar` table: ONLY non-private events (busyOnly + sharedWithName) for group queries

Personal events are synced to `shadow_calendar` with their original visibility setting, but the RPC function must respect that setting when querying for group availability.

**Privacy Levels:**
- **Private**: Never synced to shadow_calendar (physically impossible for groups to see)
- **Busy Only**: Synced with `event_title = NULL` (groups see time block only)
- **Shared with Details**: Synced with actual `event_title` (groups see title)

This fix ensures that the RPC function correctly interprets the visibility field for personal events instead of overriding it with cross-group privacy logic.
