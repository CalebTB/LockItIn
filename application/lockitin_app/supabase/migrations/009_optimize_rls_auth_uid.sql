-- ============================================================================
-- Migration 009: Optimize RLS Policies - auth.uid() Performance Fix
-- ============================================================================
-- Fixes performance warning: "RLS policy re-evaluates auth.uid() for each row"
-- Solution: Replace auth.uid() with (select auth.uid()) to cache the value
--
-- This prevents auth.uid() from being called for every row in large tables,
-- significantly improving query performance at scale.
--
-- Created: December 30, 2025
-- Issue: Supabase Database Advisor - Performance
-- Docs: https://supabase.com/docs/guides/database/postgres/row-level-security#call-functions-with-select
-- ============================================================================

-- ============================================================================
-- USERS TABLE POLICIES
-- ============================================================================

-- Drop and recreate update policy
DROP POLICY IF EXISTS "Enable update for users based on id" ON users;
CREATE POLICY "Enable update for users based on id"
ON users
FOR UPDATE
TO authenticated
USING ((select auth.uid()) = id)
WITH CHECK ((select auth.uid()) = id);

-- ============================================================================
-- EVENTS TABLE POLICIES
-- ============================================================================

-- Drop and recreate insert policy
DROP POLICY IF EXISTS "Users can insert own events" ON events;
CREATE POLICY "Users can insert own events"
ON events
FOR INSERT
TO authenticated
WITH CHECK ((select auth.uid()) = user_id);

-- Drop and recreate update policy
DROP POLICY IF EXISTS "Users can update own events" ON events;
CREATE POLICY "Users can update own events"
ON events
FOR UPDATE
TO authenticated
USING ((select auth.uid()) = user_id)
WITH CHECK ((select auth.uid()) = user_id);

-- Drop and recreate delete policy
DROP POLICY IF EXISTS "Users can delete own events" ON events;
CREATE POLICY "Users can delete own events"
ON events
FOR DELETE
TO authenticated
USING ((select auth.uid()) = user_id);

-- Drop and recreate select policy (complex one with group member check)
DROP POLICY IF EXISTS "Users can view own and group members events" ON events;
CREATE POLICY "Users can view own and group members events"
ON events
FOR SELECT
TO authenticated
USING (
  (user_id = (select auth.uid()))
  OR (
    visibility <> 'private'::text
    AND user_id <> (select auth.uid())
    AND EXISTS (
      SELECT 1
      FROM group_members gm1
      JOIN group_members gm2 ON gm1.group_id = gm2.group_id AND gm1.user_id <> gm2.user_id
      WHERE gm1.user_id = (select auth.uid())
      AND gm2.user_id = events.user_id
    )
  )
);

-- ============================================================================
-- FRIENDSHIPS TABLE POLICIES
-- ============================================================================

-- Drop and recreate select policy
DROP POLICY IF EXISTS "Users can view own friendships" ON friendships;
CREATE POLICY "Users can view own friendships"
ON friendships
FOR SELECT
TO authenticated
USING ((select auth.uid()) = user_id OR (select auth.uid()) = friend_id);

-- Drop and recreate insert policy
DROP POLICY IF EXISTS "Users can send friend requests" ON friendships;
CREATE POLICY "Users can send friend requests"
ON friendships
FOR INSERT
TO authenticated
WITH CHECK ((select auth.uid()) = user_id);

-- Drop and recreate update policy
DROP POLICY IF EXISTS "Users can update own friendships" ON friendships;
CREATE POLICY "Users can update own friendships"
ON friendships
FOR UPDATE
TO authenticated
USING ((select auth.uid()) = user_id OR (select auth.uid()) = friend_id)
WITH CHECK ((select auth.uid()) = user_id OR (select auth.uid()) = friend_id);

-- Drop and recreate delete policy
DROP POLICY IF EXISTS "Users can delete own friendships" ON friendships;
CREATE POLICY "Users can delete own friendships"
ON friendships
FOR DELETE
TO authenticated
USING ((select auth.uid()) = user_id OR (select auth.uid()) = friend_id);

-- ============================================================================
-- GROUPS TABLE POLICIES
-- ============================================================================

-- Drop and recreate select policy
DROP POLICY IF EXISTS "Users can view groups they belong to" ON groups;
CREATE POLICY "Users can view groups they belong to"
ON groups
FOR SELECT
TO authenticated
USING (
  auth_is_group_member(id, (select auth.uid()))
  OR created_by = (select auth.uid())
);

-- Drop and recreate insert policy
DROP POLICY IF EXISTS "Authenticated users can create groups" ON groups;
CREATE POLICY "Authenticated users can create groups"
ON groups
FOR INSERT
TO authenticated
WITH CHECK ((select auth.uid()) = created_by);

-- Drop and recreate update policy
DROP POLICY IF EXISTS "Owners and co-owners can update groups" ON groups;
CREATE POLICY "Owners and co-owners can update groups"
ON groups
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM group_members
    WHERE group_members.group_id = groups.id
    AND group_members.user_id = (select auth.uid())
    AND group_members.role = ANY (ARRAY['owner'::group_member_role, 'co_owner'::group_member_role])
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM group_members
    WHERE group_members.group_id = groups.id
    AND group_members.user_id = (select auth.uid())
    AND group_members.role = ANY (ARRAY['owner'::group_member_role, 'co_owner'::group_member_role])
  )
);

-- Drop and recreate delete policy
DROP POLICY IF EXISTS "Only owners can delete groups" ON groups;
CREATE POLICY "Only owners can delete groups"
ON groups
FOR DELETE
TO authenticated
USING (auth_has_group_role(id, (select auth.uid()), ARRAY['owner'::group_member_role]));

-- ============================================================================
-- GROUP_MEMBERS TABLE POLICIES
-- ============================================================================

-- Drop and recreate select policy
DROP POLICY IF EXISTS "Users can view group members" ON group_members;
CREATE POLICY "Users can view group members"
ON group_members
FOR SELECT
TO authenticated
USING (auth_is_group_member(group_id, (select auth.uid())));

-- Drop and recreate insert policy
DROP POLICY IF EXISTS "Owners and co-owners can add members" ON group_members;
CREATE POLICY "Owners and co-owners can add members"
ON group_members
FOR INSERT
TO authenticated
WITH CHECK (
  user_id = (select auth.uid())
  OR auth_has_group_role(group_id, (select auth.uid()), ARRAY['owner'::group_member_role, 'co_owner'::group_member_role])
);

-- Drop and recreate update policy
DROP POLICY IF EXISTS "Owners can update roles" ON group_members;
CREATE POLICY "Owners can update roles"
ON group_members
FOR UPDATE
TO authenticated
USING (auth_has_group_role(group_id, (select auth.uid()), ARRAY['owner'::group_member_role]))
WITH CHECK (auth_has_group_role(group_id, (select auth.uid()), ARRAY['owner'::group_member_role]));

-- Drop and recreate delete policy
DROP POLICY IF EXISTS "Members can leave or be removed" ON group_members;
CREATE POLICY "Members can leave or be removed"
ON group_members
FOR DELETE
TO authenticated
USING (
  user_id = (select auth.uid())
  OR auth_has_group_role(group_id, (select auth.uid()), ARRAY['owner'::group_member_role, 'co_owner'::group_member_role])
);

-- ============================================================================
-- GROUP_INVITES TABLE POLICIES
-- ============================================================================

-- Drop and recreate select policy
DROP POLICY IF EXISTS "Users can view relevant invites" ON group_invites;
CREATE POLICY "Users can view relevant invites"
ON group_invites
FOR SELECT
TO authenticated
USING (
  invited_user_id = (select auth.uid())
  OR auth_is_group_member(group_id, (select auth.uid()))
);

-- Drop and recreate insert policy
DROP POLICY IF EXISTS "Owners and co-owners can invite" ON group_invites;
CREATE POLICY "Owners and co-owners can invite"
ON group_invites
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM group_members
    WHERE group_members.group_id = group_invites.group_id
    AND group_members.user_id = (select auth.uid())
    AND group_members.role = ANY (ARRAY['owner'::group_member_role, 'co_owner'::group_member_role])
  )
  OR EXISTS (
    SELECT 1 FROM group_members gm
    JOIN groups g ON g.id = gm.group_id
    WHERE gm.group_id = group_invites.group_id
    AND gm.user_id = (select auth.uid())
    AND g.members_can_invite = true
  )
);

-- Drop and recreate delete policy
DROP POLICY IF EXISTS "Users can decline or cancel invites" ON group_invites;
CREATE POLICY "Users can decline or cancel invites"
ON group_invites
FOR DELETE
TO authenticated
USING (
  invited_user_id = (select auth.uid())
  OR auth_has_group_role(group_id, (select auth.uid()), ARRAY['owner'::group_member_role, 'co_owner'::group_member_role])
);

-- ============================================================================
-- SHADOW_CALENDAR TABLE POLICIES
-- ============================================================================

-- Drop and recreate own view policy
DROP POLICY IF EXISTS "Users can view own shadow calendar" ON shadow_calendar;
CREATE POLICY "Users can view own shadow calendar"
ON shadow_calendar
FOR SELECT
TO authenticated
USING ((select auth.uid()) = user_id);

-- Drop and recreate group member view policy
DROP POLICY IF EXISTS "Group members can view each other's shadow calendar" ON shadow_calendar;
CREATE POLICY "Group members can view each other's shadow calendar"
ON shadow_calendar
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM group_members gm1
    JOIN group_members gm2 ON gm1.group_id = gm2.group_id
    WHERE gm1.user_id = (select auth.uid())
    AND gm2.user_id = shadow_calendar.user_id
    AND gm1.user_id <> gm2.user_id
  )
);

-- ============================================================================
-- VERIFICATION
-- ============================================================================
-- After running this migration, verify the policies are updated:
-- SELECT tablename, policyname, qual, with_check
-- FROM pg_policies
-- WHERE tablename IN ('users', 'events', 'groups', 'group_members', 'group_invites', 'friendships', 'shadow_calendar')
-- ORDER BY tablename, policyname;
