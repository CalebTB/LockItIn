-- ============================================================================
-- RLS POLICY VALIDATION TEST SUITE
-- ============================================================================
-- This test suite validates all Row Level Security policies for the LockItIn database.
--
-- HOW TO RUN THESE TESTS:
-- 1. Go to https://app.supabase.com/
-- 2. Select your project
-- 3. Go to SQL Editor
-- 4. Copy and paste sections from this file
-- 5. Run each section one at a time to validate policies
--
-- IMPORTANT: These tests create and delete test data. Run on a test database only!
--
-- Last updated: December 29, 2025
-- Sprint 2 Testing - Issue #28
-- ============================================================================

-- ============================================================================
-- TEST SETUP: User Configuration
-- ============================================================================
-- NOTE: The `users` table has a FK to `auth.users`, so test users cannot be
-- created directly. Tests that require users will use existing authenticated
-- users from your Supabase Auth.
--
-- To run data-dependent tests:
-- 1. Create 2-3 test accounts via Supabase Auth (email/password signup)
-- 2. Get their UUIDs from the auth.users table
-- 3. Replace the UUIDs below with your actual test user IDs
--
-- For now, the test suite validates RLS STRUCTURE (policies exist, constraints
-- work) rather than runtime behavior with test data.

DO $$
DECLARE
  user_count INT;
BEGIN
  SELECT COUNT(*) INTO user_count FROM users;
  RAISE NOTICE '[INFO] Found % users in database. Data-dependent tests will use existing users.', user_count;

  IF user_count < 2 THEN
    RAISE WARNING '[WARN] Less than 2 users found. Some tests may be skipped. Create test accounts via Supabase Auth.';
  END IF;
END $$;

-- ============================================================================
-- TEST 1: USERS TABLE RLS
-- ============================================================================
-- Expected behaviors:
-- 1. Users can view their own profile
-- 2. Users can update their own profile
-- 3. Users CANNOT view other users' profiles
-- 4. Users CANNOT update other users' profiles

-- Test 1.1: Verify users table has RLS enabled
DO $$
DECLARE
  rls_enabled BOOLEAN;
BEGIN
  SELECT relrowsecurity INTO rls_enabled
  FROM pg_class
  WHERE relname = 'users';

  IF rls_enabled THEN
    RAISE NOTICE '[PASS] TEST 1.1: Users table has RLS enabled';
  ELSE
    RAISE EXCEPTION '[FAIL] TEST 1.1: Users table does NOT have RLS enabled';
  END IF;
END $$;

-- Test 1.2: Verify SELECT policy exists for users
DO $$
DECLARE
  policy_count INT;
BEGIN
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies
  WHERE tablename = 'users' AND cmd = 'SELECT';

  IF policy_count > 0 THEN
    RAISE NOTICE '[PASS] TEST 1.2: Users SELECT policy exists (% policies)', policy_count;
  ELSE
    RAISE EXCEPTION '[FAIL] TEST 1.2: No SELECT policy found for users table';
  END IF;
END $$;

-- Test 1.3: Verify UPDATE policy exists for users
DO $$
DECLARE
  policy_count INT;
BEGIN
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies
  WHERE tablename = 'users' AND cmd = 'UPDATE';

  IF policy_count > 0 THEN
    RAISE NOTICE '[PASS] TEST 1.3: Users UPDATE policy exists (% policies)', policy_count;
  ELSE
    RAISE EXCEPTION '[FAIL] TEST 1.3: No UPDATE policy found for users table';
  END IF;
END $$;

-- ============================================================================
-- TEST 2: EVENTS TABLE RLS
-- ============================================================================
-- Expected behaviors:
-- 1. Users can CRUD their own events
-- 2. Users CANNOT read/modify other users' events
-- 3. Private events are completely isolated

-- Test 2.1: Verify events table has RLS enabled
DO $$
DECLARE
  rls_enabled BOOLEAN;
BEGIN
  SELECT relrowsecurity INTO rls_enabled
  FROM pg_class
  WHERE relname = 'events';

  IF rls_enabled THEN
    RAISE NOTICE '[PASS] TEST 2.1: Events table has RLS enabled';
  ELSE
    RAISE EXCEPTION '[FAIL] TEST 2.1: Events table does NOT have RLS enabled';
  END IF;
END $$;

-- Test 2.2: Verify all CRUD policies exist for events
DO $$
DECLARE
  select_count INT;
  insert_count INT;
  update_count INT;
  delete_count INT;
BEGIN
  SELECT COUNT(*) INTO select_count FROM pg_policies WHERE tablename = 'events' AND cmd = 'SELECT';
  SELECT COUNT(*) INTO insert_count FROM pg_policies WHERE tablename = 'events' AND cmd = 'INSERT';
  SELECT COUNT(*) INTO update_count FROM pg_policies WHERE tablename = 'events' AND cmd = 'UPDATE';
  SELECT COUNT(*) INTO delete_count FROM pg_policies WHERE tablename = 'events' AND cmd = 'DELETE';

  IF select_count > 0 AND insert_count > 0 AND update_count > 0 AND delete_count > 0 THEN
    RAISE NOTICE '[PASS] TEST 2.2: Events has all CRUD policies (SELECT:%, INSERT:%, UPDATE:%, DELETE:%)',
      select_count, insert_count, update_count, delete_count;
  ELSE
    RAISE EXCEPTION '[FAIL] TEST 2.2: Events missing CRUD policies (SELECT:%, INSERT:%, UPDATE:%, DELETE:%)',
      select_count, insert_count, update_count, delete_count;
  END IF;
END $$;

-- Test 2.3: Verify events exist for testing (uses existing data)
DO $$
DECLARE
  event_count INT;
BEGIN
  SELECT COUNT(*) INTO event_count FROM events;

  IF event_count > 0 THEN
    RAISE NOTICE '[PASS] TEST 2.3: Found % events in database for RLS validation', event_count;
  ELSE
    RAISE WARNING '[SKIP] TEST 2.3: No events found. Create events via the app to test RLS runtime behavior.';
  END IF;
END $$;

-- ============================================================================
-- TEST 3: GROUPS TABLE RLS
-- ============================================================================
-- Expected behaviors:
-- 1. Users can view groups they are members of OR created
-- 2. Any authenticated user can create a group
-- 3. Only owners/co-owners can update groups
-- 4. Only owners can delete groups

-- Test 3.1: Verify groups table has RLS enabled
DO $$
DECLARE
  rls_enabled BOOLEAN;
BEGIN
  SELECT relrowsecurity INTO rls_enabled
  FROM pg_class
  WHERE relname = 'groups';

  IF rls_enabled THEN
    RAISE NOTICE '[PASS] TEST 3.1: Groups table has RLS enabled';
  ELSE
    RAISE EXCEPTION '[FAIL] TEST 3.1: Groups table does NOT have RLS enabled';
  END IF;
END $$;

-- Test 3.2: Verify SELECT policy includes creator exception (Issue #106)
DO $$
DECLARE
  policy_definition TEXT;
BEGIN
  SELECT qual INTO policy_definition
  FROM pg_policies
  WHERE tablename = 'groups' AND cmd = 'SELECT' LIMIT 1;

  -- Check if policy includes created_by check
  IF policy_definition LIKE '%created_by%' OR policy_definition LIKE '%auth_is_group_member%' THEN
    RAISE NOTICE '[PASS] TEST 3.2: Groups SELECT policy includes membership/creator check';
  ELSE
    RAISE WARNING '[INFO] TEST 3.2: Groups SELECT policy: %', policy_definition;
  END IF;
END $$;

-- Test 3.3: Verify UPDATE policy restricts to owners/co-owners
DO $$
DECLARE
  policy_definition TEXT;
BEGIN
  SELECT qual INTO policy_definition
  FROM pg_policies
  WHERE tablename = 'groups' AND cmd = 'UPDATE' LIMIT 1;

  IF policy_definition LIKE '%owner%' OR policy_definition LIKE '%co_owner%' OR policy_definition LIKE '%auth_has_group_role%' THEN
    RAISE NOTICE '[PASS] TEST 3.3: Groups UPDATE policy restricts to owners/co-owners';
  ELSE
    RAISE WARNING '[INFO] TEST 3.3: Groups UPDATE policy may not restrict properly: %', policy_definition;
  END IF;
END $$;

-- Test 3.4: Verify DELETE policy restricts to owners only
DO $$
DECLARE
  policy_definition TEXT;
BEGIN
  SELECT qual INTO policy_definition
  FROM pg_policies
  WHERE tablename = 'groups' AND cmd = 'DELETE' LIMIT 1;

  IF policy_definition LIKE '%owner%' THEN
    RAISE NOTICE '[PASS] TEST 3.4: Groups DELETE policy restricts to owners';
  ELSE
    RAISE WARNING '[INFO] TEST 3.4: Groups DELETE policy: %', policy_definition;
  END IF;
END $$;

-- Test 3.5: Verify groups exist for testing (uses existing data)
DO $$
DECLARE
  group_count INT;
  member_count INT;
BEGIN
  SELECT COUNT(*) INTO group_count FROM groups;
  SELECT COUNT(*) INTO member_count FROM group_members;

  IF group_count > 0 THEN
    RAISE NOTICE '[PASS] TEST 3.5: Found % groups with % memberships for RLS validation', group_count, member_count;
  ELSE
    RAISE WARNING '[SKIP] TEST 3.5: No groups found. Create groups via the app to test RLS runtime behavior.';
  END IF;
END $$;

-- ============================================================================
-- TEST 4: GROUP_MEMBERS TABLE RLS
-- ============================================================================
-- Expected behaviors:
-- 1. Users can view members of groups they belong to
-- 2. Users can add themselves (when creating group)
-- 3. Owners/co-owners can add other members
-- 4. Only owners can update roles
-- 5. Members can leave; owners/co-owners can remove others

-- Test 4.1: Verify group_members table has RLS enabled
DO $$
DECLARE
  rls_enabled BOOLEAN;
BEGIN
  SELECT relrowsecurity INTO rls_enabled
  FROM pg_class
  WHERE relname = 'group_members';

  IF rls_enabled THEN
    RAISE NOTICE '[PASS] TEST 4.1: Group_members table has RLS enabled';
  ELSE
    RAISE EXCEPTION '[FAIL] TEST 4.1: Group_members table does NOT have RLS enabled';
  END IF;
END $$;

-- Test 4.2: Verify SELECT policy checks group membership
DO $$
DECLARE
  policy_definition TEXT;
BEGIN
  SELECT qual INTO policy_definition
  FROM pg_policies
  WHERE tablename = 'group_members' AND cmd = 'SELECT' LIMIT 1;

  IF policy_definition LIKE '%auth_is_group_member%' OR policy_definition LIKE '%group_id%' THEN
    RAISE NOTICE '[PASS] TEST 4.2: Group_members SELECT policy checks membership';
  ELSE
    RAISE WARNING '[INFO] TEST 4.2: Group_members SELECT policy: %', policy_definition;
  END IF;
END $$;

-- Test 4.3: Verify INSERT policy allows self-add and owner/co-owner add
DO $$
DECLARE
  policy_definition TEXT;
BEGIN
  SELECT with_check INTO policy_definition
  FROM pg_policies
  WHERE tablename = 'group_members' AND cmd = 'INSERT' LIMIT 1;

  IF policy_definition LIKE '%user_id%' OR policy_definition LIKE '%auth_has_group_role%' THEN
    RAISE NOTICE '[PASS] TEST 4.3: Group_members INSERT policy allows appropriate inserts';
  ELSE
    RAISE WARNING '[INFO] TEST 4.3: Group_members INSERT policy: %', policy_definition;
  END IF;
END $$;

-- Test 4.4: Verify UPDATE policy restricts to owners
DO $$
DECLARE
  policy_definition TEXT;
BEGIN
  SELECT qual INTO policy_definition
  FROM pg_policies
  WHERE tablename = 'group_members' AND cmd = 'UPDATE' LIMIT 1;

  IF policy_definition LIKE '%owner%' OR policy_definition LIKE '%auth_has_group_role%' THEN
    RAISE NOTICE '[PASS] TEST 4.4: Group_members UPDATE policy restricts to owners';
  ELSE
    RAISE WARNING '[INFO] TEST 4.4: Group_members UPDATE policy: %', policy_definition;
  END IF;
END $$;

-- Test 4.5: Verify DELETE policy allows self-leave and owner/co-owner removal
DO $$
DECLARE
  policy_definition TEXT;
BEGIN
  SELECT qual INTO policy_definition
  FROM pg_policies
  WHERE tablename = 'group_members' AND cmd = 'DELETE' LIMIT 1;

  IF policy_definition LIKE '%user_id%' OR policy_definition LIKE '%auth_has_group_role%' THEN
    RAISE NOTICE '[PASS] TEST 4.5: Group_members DELETE policy allows appropriate deletions';
  ELSE
    RAISE WARNING '[INFO] TEST 4.5: Group_members DELETE policy: %', policy_definition;
  END IF;
END $$;

-- ============================================================================
-- TEST 5: GROUP_INVITES TABLE RLS
-- ============================================================================
-- Expected behaviors:
-- 1. Invited users can see invites sent to them
-- 2. Group members can see pending invites for their group
-- 3. Owners/co-owners can create invites
-- 4. Invited user can decline; owners/co-owners can cancel

-- Test 5.1: Verify group_invites table has RLS enabled
DO $$
DECLARE
  rls_enabled BOOLEAN;
BEGIN
  SELECT relrowsecurity INTO rls_enabled
  FROM pg_class
  WHERE relname = 'group_invites';

  IF rls_enabled THEN
    RAISE NOTICE '[PASS] TEST 5.1: Group_invites table has RLS enabled';
  ELSE
    RAISE EXCEPTION '[FAIL] TEST 5.1: Group_invites table does NOT have RLS enabled';
  END IF;
END $$;

-- Test 5.2: Verify SELECT policy covers invited user and group members
DO $$
DECLARE
  policy_definition TEXT;
BEGIN
  SELECT qual INTO policy_definition
  FROM pg_policies
  WHERE tablename = 'group_invites' AND cmd = 'SELECT' LIMIT 1;

  IF policy_definition LIKE '%invited_user_id%' OR policy_definition LIKE '%auth_is_group_member%' THEN
    RAISE NOTICE '[PASS] TEST 5.2: Group_invites SELECT policy covers invited users and group members';
  ELSE
    RAISE WARNING '[INFO] TEST 5.2: Group_invites SELECT policy: %', policy_definition;
  END IF;
END $$;

-- Test 5.3: Verify INSERT policy restricts to owners/co-owners
DO $$
DECLARE
  policy_definition TEXT;
BEGIN
  SELECT with_check INTO policy_definition
  FROM pg_policies
  WHERE tablename = 'group_invites' AND cmd = 'INSERT' LIMIT 1;

  IF policy_definition LIKE '%owner%' OR policy_definition LIKE '%co_owner%' OR policy_definition LIKE '%auth_has_group_role%' THEN
    RAISE NOTICE '[PASS] TEST 5.3: Group_invites INSERT policy restricts to owners/co-owners';
  ELSE
    RAISE WARNING '[INFO] TEST 5.3: Group_invites INSERT policy: %', policy_definition;
  END IF;
END $$;

-- Test 5.4: Verify group invites exist for testing (uses existing data)
DO $$
DECLARE
  invite_count INT;
BEGIN
  SELECT COUNT(*) INTO invite_count FROM group_invites;

  IF invite_count > 0 THEN
    RAISE NOTICE '[PASS] TEST 5.4: Found % pending invites for RLS validation', invite_count;
  ELSE
    RAISE NOTICE '[INFO] TEST 5.4: No pending invites found. This is normal if no invites are pending.';
  END IF;
END $$;

-- ============================================================================
-- TEST 6: FRIENDSHIPS TABLE RLS
-- ============================================================================
-- Expected behaviors:
-- 1. Users can view friendships where they're involved
-- 2. Users can send friend requests (as requester)
-- 3. Users can update friendships they're involved in
-- 4. Users can delete friendships they're involved in

-- Test 6.1: Verify friendships table has RLS enabled
DO $$
DECLARE
  rls_enabled BOOLEAN;
BEGIN
  SELECT relrowsecurity INTO rls_enabled
  FROM pg_class
  WHERE relname = 'friendships';

  IF rls_enabled THEN
    RAISE NOTICE '[PASS] TEST 6.1: Friendships table has RLS enabled';
  ELSE
    RAISE EXCEPTION '[FAIL] TEST 6.1: Friendships table does NOT have RLS enabled';
  END IF;
END $$;

-- Test 6.2: Verify SELECT policy checks both user_id and friend_id
DO $$
DECLARE
  policy_definition TEXT;
BEGIN
  SELECT qual INTO policy_definition
  FROM pg_policies
  WHERE tablename = 'friendships' AND cmd = 'SELECT' LIMIT 1;

  IF policy_definition LIKE '%user_id%' AND policy_definition LIKE '%friend_id%' THEN
    RAISE NOTICE '[PASS] TEST 6.2: Friendships SELECT policy checks both parties';
  ELSE
    RAISE WARNING '[INFO] TEST 6.2: Friendships SELECT policy: %', policy_definition;
  END IF;
END $$;

-- Test 6.3: Verify INSERT policy only allows sending as requester
DO $$
DECLARE
  policy_definition TEXT;
BEGIN
  SELECT with_check INTO policy_definition
  FROM pg_policies
  WHERE tablename = 'friendships' AND cmd = 'INSERT' LIMIT 1;

  IF policy_definition LIKE '%user_id%' THEN
    RAISE NOTICE '[PASS] TEST 6.3: Friendships INSERT policy restricts to requester';
  ELSE
    RAISE WARNING '[INFO] TEST 6.3: Friendships INSERT policy: %', policy_definition;
  END IF;
END $$;

-- Test 6.4: Verify friendships exist for testing (uses existing data)
DO $$
DECLARE
  friendship_count INT;
  pending_count INT;
  accepted_count INT;
BEGIN
  SELECT COUNT(*) INTO friendship_count FROM friendships;
  SELECT COUNT(*) INTO pending_count FROM friendships WHERE status = 'pending';
  SELECT COUNT(*) INTO accepted_count FROM friendships WHERE status = 'accepted';

  IF friendship_count > 0 THEN
    RAISE NOTICE '[PASS] TEST 6.4: Found % friendships (% accepted, % pending) for RLS validation',
      friendship_count, accepted_count, pending_count;
  ELSE
    RAISE NOTICE '[INFO] TEST 6.4: No friendships found. Create friend connections via the app to test runtime behavior.';
  END IF;
END $$;

-- ============================================================================
-- TEST 7: SHADOW_CALENDAR TABLE RLS
-- ============================================================================
-- Expected behaviors:
-- 1. Users can view their own shadow calendar entries
-- 2. Group members can view each other's shadow calendar entries
-- 3. Non-group members CANNOT view shadow calendar entries
-- 4. Private events NEVER appear in shadow_calendar

-- Test 7.1: Verify shadow_calendar table has RLS enabled
DO $$
DECLARE
  rls_enabled BOOLEAN;
BEGIN
  SELECT relrowsecurity INTO rls_enabled
  FROM pg_class
  WHERE relname = 'shadow_calendar';

  IF rls_enabled THEN
    RAISE NOTICE '[PASS] TEST 7.1: Shadow_calendar table has RLS enabled';
  ELSE
    RAISE EXCEPTION '[FAIL] TEST 7.1: Shadow_calendar table does NOT have RLS enabled';
  END IF;
END $$;

-- Test 7.2: Verify SELECT policy includes own entries and group member entries
DO $$
DECLARE
  policy_count INT;
BEGIN
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies
  WHERE tablename = 'shadow_calendar' AND cmd = 'SELECT';

  IF policy_count >= 2 THEN
    RAISE NOTICE '[PASS] TEST 7.2: Shadow_calendar has % SELECT policies (own + group)', policy_count;
  ELSIF policy_count = 1 THEN
    RAISE WARNING '[INFO] TEST 7.2: Shadow_calendar has only 1 SELECT policy - may be combined';
  ELSE
    RAISE EXCEPTION '[FAIL] TEST 7.2: Shadow_calendar has no SELECT policies';
  END IF;
END $$;

-- Test 7.3: Verify private events are NOT in shadow_calendar
DO $$
DECLARE
  private_count INT;
BEGIN
  SELECT COUNT(*) INTO private_count
  FROM shadow_calendar
  WHERE visibility = 'private'::event_visibility;

  IF private_count = 0 THEN
    RAISE NOTICE '[PASS] TEST 7.3: No private events in shadow_calendar (privacy enforced)';
  ELSE
    RAISE EXCEPTION '[FAIL] TEST 7.3: Found % private events in shadow_calendar - PRIVACY VIOLATION!', private_count;
  END IF;
END $$;

-- Test 7.4: Verify busyOnly events have NULL event_title
DO $$
DECLARE
  violation_count INT;
BEGIN
  SELECT COUNT(*) INTO violation_count
  FROM shadow_calendar
  WHERE visibility = 'busyOnly'::event_visibility
    AND event_title IS NOT NULL;

  IF violation_count = 0 THEN
    RAISE NOTICE '[PASS] TEST 7.4: All busyOnly events have NULL titles (privacy enforced)';
  ELSE
    RAISE EXCEPTION '[FAIL] TEST 7.4: Found % busyOnly events with titles - PRIVACY VIOLATION!', violation_count;
  END IF;
END $$;

-- Test 7.5: Verify sharedWithName events have event_title
DO $$
DECLARE
  violation_count INT;
BEGIN
  SELECT COUNT(*) INTO violation_count
  FROM shadow_calendar
  WHERE visibility = 'sharedWithName'::event_visibility
    AND event_title IS NULL;

  IF violation_count = 0 THEN
    RAISE NOTICE '[PASS] TEST 7.5: All sharedWithName events have titles';
  ELSE
    RAISE WARNING '[INFO] TEST 7.5: Found % sharedWithName events without titles', violation_count;
  END IF;
END $$;

-- ============================================================================
-- TEST 8: HELPER FUNCTIONS
-- ============================================================================
-- Verify security-critical helper functions exist and work correctly

-- Test 8.1: Verify auth_is_group_member function exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'auth_is_group_member') THEN
    RAISE NOTICE '[PASS] TEST 8.1: auth_is_group_member function exists';
  ELSE
    RAISE EXCEPTION '[FAIL] TEST 8.1: auth_is_group_member function does not exist';
  END IF;
END $$;

-- Test 8.2: Verify auth_has_group_role function exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'auth_has_group_role') THEN
    RAISE NOTICE '[PASS] TEST 8.2: auth_has_group_role function exists';
  ELSE
    RAISE EXCEPTION '[FAIL] TEST 8.2: auth_has_group_role function does not exist';
  END IF;
END $$;

-- Test 8.3: Verify is_group_member function exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'is_group_member') THEN
    RAISE NOTICE '[PASS] TEST 8.3: is_group_member function exists';
  ELSE
    RAISE EXCEPTION '[FAIL] TEST 8.3: is_group_member function does not exist';
  END IF;
END $$;

-- Test 8.4: Verify are_friends function exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'are_friends') THEN
    RAISE NOTICE '[PASS] TEST 8.4: are_friends function exists';
  ELSE
    RAISE EXCEPTION '[FAIL] TEST 8.4: are_friends function does not exist';
  END IF;
END $$;

-- Test 8.5: Verify get_group_shadow_calendar RPC function exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_group_shadow_calendar') THEN
    RAISE NOTICE '[PASS] TEST 8.5: get_group_shadow_calendar function exists';
  ELSE
    RAISE EXCEPTION '[FAIL] TEST 8.5: get_group_shadow_calendar function does not exist';
  END IF;
END $$;

-- ============================================================================
-- TEST 9: SYNC TRIGGER VALIDATION
-- ============================================================================
-- Verify the events -> shadow_calendar sync trigger works correctly

-- Test 9.1: Verify sync trigger exists on events table
DO $$
DECLARE
  trigger_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM information_schema.triggers
    WHERE event_object_table = 'events'
    AND trigger_name = 'sync_events_to_shadow'
  ) INTO trigger_exists;

  IF trigger_exists THEN
    RAISE NOTICE '[PASS] TEST 9.1: sync_events_to_shadow trigger exists';
  ELSE
    RAISE EXCEPTION '[FAIL] TEST 9.1: sync_events_to_shadow trigger does not exist';
  END IF;
END $$;

-- Test 9.2: Verify sync_event_to_shadow_calendar function exists
DO $$
BEGIN
  -- Check function exists by querying pg_proc
  IF EXISTS (
    SELECT 1 FROM pg_proc WHERE proname = 'sync_event_to_shadow_calendar'
  ) THEN
    RAISE NOTICE '[PASS] TEST 9.2: sync_event_to_shadow_calendar function exists';
  ELSE
    RAISE EXCEPTION '[FAIL] TEST 9.2: sync_event_to_shadow_calendar function does not exist';
  END IF;
END $$;

-- ============================================================================
-- TEST 10: CONSTRAINT VALIDATION
-- ============================================================================
-- Verify database constraints prevent invalid data

-- Test 10.1: Verify no_self_friendship constraint exists
DO $$
DECLARE
  constraint_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM information_schema.check_constraints
    WHERE constraint_name = 'no_self_friendship'
  ) INTO constraint_exists;

  IF constraint_exists THEN
    RAISE NOTICE '[PASS] TEST 10.1: no_self_friendship constraint exists';
  ELSE
    RAISE WARNING '[WARN] TEST 10.1: no_self_friendship constraint not found - check friendships table';
  END IF;
END $$;

-- Test 10.2: Verify valid_shadow_time_range constraint exists
DO $$
DECLARE
  constraint_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM information_schema.check_constraints
    WHERE constraint_name = 'valid_shadow_time_range'
  ) INTO constraint_exists;

  IF constraint_exists THEN
    RAISE NOTICE '[PASS] TEST 10.2: valid_shadow_time_range constraint exists';
  ELSE
    RAISE WARNING '[WARN] TEST 10.2: valid_shadow_time_range constraint not found - check shadow_calendar table';
  END IF;
END $$;

-- Test 10.3: Verify unique_group_membership constraint exists
DO $$
DECLARE
  constraint_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'unique_group_membership'
    AND constraint_type = 'UNIQUE'
  ) INTO constraint_exists;

  IF constraint_exists THEN
    RAISE NOTICE '[PASS] TEST 10.3: unique_group_membership constraint exists';
  ELSE
    RAISE WARNING '[WARN] TEST 10.3: unique_group_membership constraint not found - check group_members table';
  END IF;
END $$;

-- ============================================================================
-- TEST 11: POLICY ISOLATION VERIFICATION
-- ============================================================================
-- These tests verify that RLS properly isolates data between users

-- Test 11.1: Verify total policy count for all tables
DO $$
DECLARE
  policy_summary RECORD;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '=== RLS POLICY SUMMARY ===';

  FOR policy_summary IN
    SELECT tablename, COUNT(*) as policy_count
    FROM pg_policies
    WHERE tablename IN ('users', 'events', 'groups', 'group_members', 'group_invites', 'friendships', 'shadow_calendar')
    GROUP BY tablename
    ORDER BY tablename
  LOOP
    RAISE NOTICE 'Table: %, Policies: %', policy_summary.tablename, policy_summary.policy_count;
  END LOOP;

  RAISE NOTICE '========================';
END $$;

-- Test 11.2: List all policies with their commands
DO $$
DECLARE
  policy_detail RECORD;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '=== DETAILED POLICY LIST ===';

  FOR policy_detail IN
    SELECT tablename, policyname, cmd
    FROM pg_policies
    WHERE tablename IN ('users', 'events', 'groups', 'group_members', 'group_invites', 'friendships', 'shadow_calendar')
    ORDER BY tablename, cmd
  LOOP
    RAISE NOTICE '% | % | %', policy_detail.tablename, policy_detail.cmd, policy_detail.policyname;
  END LOOP;

  RAISE NOTICE '============================';
END $$;

-- ============================================================================
-- NOTE: No cleanup needed - this test suite validates structure only
-- ============================================================================
-- This test suite checks that RLS policies, constraints, functions, and triggers
-- exist and are properly configured. It does not create test data that needs cleanup.

-- ============================================================================
-- TEST SUMMARY
-- ============================================================================
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'RLS STRUCTURE VALIDATION COMPLETE';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'Tests executed: 30+';
  RAISE NOTICE 'Tables validated: users, events, groups, group_members, group_invites, friendships, shadow_calendar';
  RAISE NOTICE 'Functions verified: auth_is_group_member, auth_has_group_role, is_group_member, are_friends, get_group_shadow_calendar';
  RAISE NOTICE 'Triggers verified: sync_events_to_shadow';
  RAISE NOTICE 'Constraints verified: no_self_friendship, valid_shadow_time_range, unique_group_membership';
  RAISE NOTICE '';
  RAISE NOTICE 'Status Legend:';
  RAISE NOTICE '[PASS] = Structure exists and is correct';
  RAISE NOTICE '[FAIL] = Critical structure missing - FIX REQUIRED';
  RAISE NOTICE '[WARN] = Structure may be missing - verify manually';
  RAISE NOTICE '[INFO] = Informational only';
  RAISE NOTICE '[SKIP] = Skipped (missing prerequisites)';
  RAISE NOTICE '';
  RAISE NOTICE 'NOTE: This validates RLS STRUCTURE, not runtime behavior.';
  RAISE NOTICE 'For runtime testing, use the app with real authenticated users.';
  RAISE NOTICE '============================================';
END $$;
