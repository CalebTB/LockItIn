---
module: LockItIn Shadow Calendar
date: 2026-02-01
problem_type: database_issue
component: database
symptoms:
  - "Greyed out heatmap showing 0 entries after migration 027"
  - "PostgreSQL error: column reference 'user_id' is ambiguous"
  - "Enum comparison failing without explicit casting"
  - "Snake_case vs camelCase enum mismatch between PostgreSQL and Dart"
root_cause: logic_error
resolution_type: migration
severity: critical
tags: [postgresql, rpc, enum, sql, snake-case, camelcase, supabase]
---

# Troubleshooting: PostgreSQL Enum Comparison & Ambiguous Column Reference in Shadow Calendar RPC

## Problem
After fixing personal event visibility logic in migration 027, the group calendar heatmap completely stopped working - showing all grey dots and fetching 0 shadow calendar entries. This required 4 sequential migrations (028-031) to fully resolve, uncovering multiple compounding issues with enum comparison, snake_case/camelCase mismatch, and ambiguous SQL column references.

## Environment
- Module: LockItIn Shadow Calendar
- Database: Supabase (PostgreSQL 15)
- Affected Component: `get_group_shadow_calendar_v3` RPC function
- Frontend: Flutter/Dart expecting camelCase enum values
- Date: 2026-02-01

## Symptoms
- Group calendar heatmap showing all grey dots (0 availability data)
- Console logs showing "Fetched 0 shadow entries" instead of expected 4+
- PostgreSQL error in migration 030: `column reference 'user_id' is ambiguous`
- Enum comparison not matching values despite correct logic
- Database stores `shared_with_name`, `busy_only` (snake_case)
- Dart expects `sharedWithName`, `busyOnly` (camelCase)

## What Didn't Work

**Attempted Solution 1: Migration 028 - Add Enum Casting**
- **What was tried:** Added `::TEXT` casting to enum comparison and `COALESCE` for NULL handling
```sql
CASE WHEN sc.visibility::TEXT = 'sharedWithName' THEN sc.event_title ELSE NULL END
```
- **Why it failed:** The database stores enum values as `shared_with_name` (snake_case), not `sharedWithName` (camelCase). The comparison never matched.

**Attempted Solution 2: Migration 029 - Use Snake_Case Comparison**
- **What was tried:** Changed comparison to use database's snake_case format
```sql
CASE WHEN sc.visibility::TEXT = 'shared_with_name' THEN sc.event_title ELSE NULL END
```
- **Why it failed:** While the comparison now worked, Dart code expected camelCase return values. Returning snake_case caused `_visibilityFromString()` to fail in ShadowCalendarEntry.fromJson().

**Attempted Solution 3: Migration 030 - Return CamelCase Values**
- **What was tried:** Compare with snake_case, but convert to camelCase for return:
```sql
CASE
  WHEN sc.visibility::TEXT = 'shared_with_name' THEN 'sharedWithName'
  WHEN sc.visibility::TEXT = 'busy_only' THEN 'busyOnly'
  ELSE 'busyOnly'
END AS visibility
```
- **Why it failed:** SQL error: `column reference 'user_id' is ambiguous`. The WHERE clause subquery didn't qualify column names with table aliases.

## Solution

**Migration 031: Add Table Aliases to Fix Ambiguous Column Reference**

The final working solution required adding table aliases to ALL column references in the WHERE clause subquery:

```sql
-- Migration: supabase/migrations/031_fix_ambiguous_user_id.sql

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
    -- Title visibility logic with enum conversion
    CASE
      WHEN sc.group_id IS NULL THEN
        -- Personal event: Use original visibility (compare snake_case)
        CASE WHEN sc.visibility::TEXT = 'shared_with_name' THEN sc.event_title ELSE NULL END
      WHEN sc.group_id = p_group_id THEN
        -- Same-group event: Show title
        sc.event_title
      WHEN COALESCE(e.show_busy_to_all_groups, true) = true THEN
        -- Cross-group event with privacy setting: Hide title
        NULL
      ELSE NULL
    END AS event_title,
    -- Visibility level (convert snake_case to camelCase for Dart)
    CASE
      WHEN sc.group_id IS NULL THEN
        -- Personal event: Convert to camelCase
        CASE
          WHEN sc.visibility::TEXT = 'shared_with_name' THEN 'sharedWithName'
          WHEN sc.visibility::TEXT = 'busy_only' THEN 'busyOnly'
          ELSE 'busyOnly'
        END
      WHEN sc.group_id = p_group_id THEN
        -- Same-group event: Full details
        'sharedWithName'
      WHEN COALESCE(e.show_busy_to_all_groups, true) = true THEN
        -- Cross-group event: Busy only
        'busyOnly'
      ELSE sc.visibility::TEXT
    END AS visibility,
    -- Flag for UI to distinguish group events from personal events
    COALESCE(sc.group_id IS NOT NULL, false) AS is_group_event
  FROM shadow_calendar sc
  JOIN events e ON e.id = sc.event_id
  WHERE sc.user_id IN (
    -- FIX: Fully qualified column names with table alias
    SELECT gm.user_id FROM group_members gm
    WHERE gm.group_id = p_group_id
  )
  AND sc.start_time < p_end_time
  AND sc.end_time > p_start_time
  ORDER BY sc.user_id, sc.start_time;
END;
$$;

GRANT EXECUTE ON FUNCTION get_group_shadow_calendar_v3 TO authenticated;
```

**Key Changes:**
1. **Table aliases in subquery**: `SELECT gm.user_id FROM group_members gm WHERE gm.group_id = p_group_id`
2. **Enum comparison**: Compare with snake_case (`'shared_with_name'`)
3. **Enum return**: Convert to camelCase (`'sharedWithName'`)
4. **NULL handling**: Use `COALESCE` for nullable fields

**Result:** Console logs confirmed success:
```
flutter: 🔵 LockItIn [GroupDetailScreen] DEBUG: Fetched 4 shadow entries
flutter: 🔵 LockItIn [GroupDetailScreen] DEBUG: Converted to 2 user event lists
```

## Why This Works

**Root Cause #1: Ambiguous Column Reference**
PostgreSQL couldn't determine which `user_id` column to use because both `shadow_calendar` and `group_members` have this column. Without table aliases, the query was ambiguous.

**Root Cause #2: Enum Storage Format Mismatch**
PostgreSQL stores enum values in snake_case (`event_visibility` type uses `shared_with_name`, `busy_only`), but Dart code expects camelCase (`sharedWithName`, `busyOnly`) because that's the Dart enum naming convention.

**Root Cause #3: Type Comparison**
PostgreSQL enum types require explicit casting to TEXT for string comparison. Without `::TEXT`, the comparison uses enum equality which has strict type checking.

**Why the solution addresses these:**
1. **Table aliases** disambiguate column references: `gm.user_id` and `gm.group_id` make it clear we're selecting from `group_members`
2. **Two-stage enum handling**:
   - **Comparison stage**: Use snake_case to match database storage (`'shared_with_name'`)
   - **Return stage**: Convert to camelCase for Dart compatibility (`'sharedWithName'`)
3. **Explicit casting**: `sc.visibility::TEXT` ensures string comparison works correctly

**Underlying Issue:**
This was a compounding problem where multiple small issues (enum format, column ambiguity, type casting) created a chain of failures. Each migration fixed one issue but revealed the next, requiring systematic debugging to reach the root cause.

## Prevention

**To avoid enum comparison and SQL ambiguity issues in future PostgreSQL/Supabase development:**

1. **Always use table aliases in subqueries with JOINs:**
   ```sql
   ✅ CORRECT:
   SELECT gm.user_id FROM group_members gm WHERE gm.group_id = p_group_id

   ❌ WRONG:
   SELECT user_id FROM group_members WHERE group_id = p_group_id
   ```

2. **Document enum storage format vs API format:**
   - Database: `snake_case` (PostgreSQL convention)
   - Dart/Flutter: `camelCase` (Dart enum convention)
   - RPC functions must convert between formats

3. **Always cast enums to TEXT for string comparison:**
   ```sql
   ✅ CORRECT:
   CASE WHEN sc.visibility::TEXT = 'shared_with_name' THEN ...

   ❌ WRONG:
   CASE WHEN sc.visibility = 'shared_with_name' THEN ...
   ```

4. **Test RPC functions immediately after changes:**
   - Don't wait for UI integration to discover data fetching issues
   - Use Supabase SQL Editor to test RPC calls directly:
   ```sql
   SELECT * FROM get_group_shadow_calendar_v3(
     '[group-uuid]'::UUID,
     '2026-02-01'::TIMESTAMPTZ,
     '2026-02-28'::TIMESTAMPTZ
   );
   ```

5. **When changing RPC logic, verify returned data structure:**
   - Check that enum values match what Dart code expects
   - Validate NULL handling with `COALESCE`
   - Confirm column names and types match Dart model

6. **Systematic debugging for cascading failures:**
   - If one fix breaks something else, you likely have compounding issues
   - Document each attempt and what it revealed
   - Work backward from error messages to find all root causes

## Related Issues

- See also: [personal-event-visibility-rpc-logic-shadow-calendar-20260201.md](personal-event-visibility-rpc-logic-shadow-calendar-20260201.md) - The privacy logic fix that initially broke the heatmap
- See also: [supabase-timestamp-type-parsing-calendar-20260201.md](../integration-issues/supabase-timestamp-type-parsing-calendar-20260201.md) - Related Supabase type handling issue

## Additional Context

**Migration History:**
- Migration 027: Fixed personal event visibility (introduced the bug)
- Migration 028: Added enum casting (didn't fix it)
- Migration 029: Used snake_case comparison (still broken)
- Migration 030: Return camelCase (revealed ambiguous column error)
- Migration 031: Added table aliases (FIXED)

**Key Learning:**
When a fix breaks something that was previously working, the new code likely exposed a latent bug. In this case, migration 027's privacy logic changes were correct, but they exposed that the enum comparison and column references were fragile and broke under the new CASE logic complexity.
