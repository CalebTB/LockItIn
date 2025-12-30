-- ============================================================================
-- RLS QUICK CHECK - Rapid Validation
-- ============================================================================
-- Fast validation of critical RLS policies - run before deployments
-- Expected runtime: < 5 seconds
--
-- Last updated: December 29, 2025
-- Sprint 2 Testing - Issue #28
-- ============================================================================

-- Check 1: All critical tables have RLS enabled
SELECT
  tablename,
  CASE WHEN relrowsecurity THEN 'ENABLED' ELSE 'DISABLED' END as rls_status
FROM pg_class pc
JOIN (
  VALUES ('users'), ('events'), ('groups'), ('group_members'), ('group_invites'), ('friendships'), ('shadow_calendar')
) AS t(tablename) ON pc.relname = t.tablename
ORDER BY tablename;

-- Check 2: Policy count per table (minimum expected)
-- users: 3, events: 4, groups: 4, group_members: 4, group_invites: 3, friendships: 4, shadow_calendar: 2
SELECT
  tablename,
  COUNT(*) as policy_count,
  CASE
    WHEN tablename = 'users' AND COUNT(*) >= 3 THEN 'OK'
    WHEN tablename = 'events' AND COUNT(*) >= 4 THEN 'OK'
    WHEN tablename = 'groups' AND COUNT(*) >= 4 THEN 'OK'
    WHEN tablename = 'group_members' AND COUNT(*) >= 4 THEN 'OK'
    WHEN tablename = 'group_invites' AND COUNT(*) >= 3 THEN 'OK'
    WHEN tablename = 'friendships' AND COUNT(*) >= 4 THEN 'OK'
    WHEN tablename = 'shadow_calendar' AND COUNT(*) >= 2 THEN 'OK'
    ELSE 'CHECK'
  END as status
FROM pg_policies
WHERE tablename IN ('users', 'events', 'groups', 'group_members', 'group_invites', 'friendships', 'shadow_calendar')
GROUP BY tablename
ORDER BY tablename;

-- Check 3: Shadow Calendar Privacy Validation
-- CRITICAL: No private events should exist in shadow_calendar
SELECT
  CASE
    WHEN COUNT(*) = 0 THEN 'PASS: No private events in shadow_calendar'
    ELSE 'FAIL: ' || COUNT(*) || ' private events found - PRIVACY VIOLATION!'
  END as privacy_check
FROM shadow_calendar
WHERE visibility = 'private'::event_visibility;

-- Check 4: BusyOnly events must have NULL titles
SELECT
  CASE
    WHEN COUNT(*) = 0 THEN 'PASS: All busyOnly events have NULL titles'
    ELSE 'FAIL: ' || COUNT(*) || ' busyOnly events have titles - PRIVACY VIOLATION!'
  END as busyonly_check
FROM shadow_calendar
WHERE visibility = 'busyOnly'::event_visibility
  AND event_title IS NOT NULL;

-- Check 5: Critical helper functions exist
SELECT
  proname as function_name,
  CASE WHEN proname IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END as status
FROM pg_proc
WHERE proname IN ('auth_is_group_member', 'auth_has_group_role', 'is_group_member', 'are_friends', 'get_group_shadow_calendar', 'sync_event_to_shadow_calendar')
ORDER BY proname;

-- Check 6: Sync trigger is active
SELECT
  trigger_name,
  event_object_table,
  CASE WHEN trigger_name IS NOT NULL THEN 'ACTIVE' ELSE 'MISSING' END as status
FROM information_schema.triggers
WHERE trigger_name = 'sync_events_to_shadow';

-- Summary
SELECT '=== RLS QUICK CHECK COMPLETE ===' as summary;
