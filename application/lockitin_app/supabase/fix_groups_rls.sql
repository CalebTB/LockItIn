-- Fix Groups RLS Policies
-- Run this script in Supabase SQL Editor to fix RLS issues
--
-- The main fix: SELECT policy now allows creators to see their group
-- before they're added as a member (needed for INSERT...RETURNING)
--
-- Last updated: December 27, 2025

-- ============================================================================
-- STEP 1: Drop existing policies
-- ============================================================================

DROP POLICY IF EXISTS "Users can view groups they belong to" ON groups;
DROP POLICY IF EXISTS "Authenticated users can create groups" ON groups;
DROP POLICY IF EXISTS "Owners and admins can update groups" ON groups;
DROP POLICY IF EXISTS "Owners and co-owners can update groups" ON groups;
DROP POLICY IF EXISTS "Only owners can delete groups" ON groups;

DROP POLICY IF EXISTS "Users can view group members" ON group_members;
DROP POLICY IF EXISTS "Owners and admins can add members" ON group_members;
DROP POLICY IF EXISTS "Owners and co-owners can add members" ON group_members;
DROP POLICY IF EXISTS "Owners can update roles" ON group_members;
DROP POLICY IF EXISTS "Members can leave or be removed" ON group_members;

DROP POLICY IF EXISTS "Users can view relevant invites" ON group_invites;
DROP POLICY IF EXISTS "Owners and admins can invite" ON group_invites;
DROP POLICY IF EXISTS "Owners and co-owners can invite" ON group_invites;
DROP POLICY IF EXISTS "Users can decline or cancel invites" ON group_invites;

-- ============================================================================
-- STEP 2: Create helper functions (SECURITY DEFINER bypasses RLS)
-- ============================================================================

-- Function to check if a user is a member of a group (bypasses RLS)
CREATE OR REPLACE FUNCTION auth_is_group_member(group_uuid UUID, user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM group_members
    WHERE group_id = group_uuid AND user_id = user_uuid
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if a user has a specific role in a group (bypasses RLS)
CREATE OR REPLACE FUNCTION auth_has_group_role(group_uuid UUID, user_uuid UUID, required_roles group_member_role[])
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM group_members
    WHERE group_id = group_uuid
    AND user_id = user_uuid
    AND role = ANY(required_roles)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- STEP 3: Create GROUPS table policies
-- ============================================================================

-- Policy: Users can view groups they are a member of OR created
-- The "OR created_by = auth.uid()" allows SELECT after INSERT before member record exists
CREATE POLICY "Users can view groups they belong to"
ON groups
FOR SELECT
TO authenticated
USING (
  auth_is_group_member(id, auth.uid())
  OR created_by = auth.uid()
);

-- Policy: Any authenticated user can create a group
CREATE POLICY "Authenticated users can create groups"
ON groups
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = created_by);

-- Policy: Owners and co-owners can update groups
CREATE POLICY "Owners and co-owners can update groups"
ON groups
FOR UPDATE
TO authenticated
USING (
  auth_has_group_role(id, auth.uid(), ARRAY['owner', 'co_owner']::group_member_role[])
)
WITH CHECK (
  auth_has_group_role(id, auth.uid(), ARRAY['owner', 'co_owner']::group_member_role[])
);

-- Policy: Only owners can delete groups
CREATE POLICY "Only owners can delete groups"
ON groups
FOR DELETE
TO authenticated
USING (
  auth_has_group_role(id, auth.uid(), ARRAY['owner']::group_member_role[])
);

-- ============================================================================
-- STEP 4: Create GROUP_MEMBERS table policies
-- ============================================================================

-- Policy: Users can view members of groups they belong to
CREATE POLICY "Users can view group members"
ON group_members
FOR SELECT
TO authenticated
USING (
  auth_is_group_member(group_id, auth.uid())
);

-- Policy: Owners and co-owners can add members, OR user can add themselves
CREATE POLICY "Owners and co-owners can add members"
ON group_members
FOR INSERT
TO authenticated
WITH CHECK (
  -- Allow adding self (when creating a group or accepting invite)
  (user_id = auth.uid())
  OR
  -- Allow owners/co-owners to add others
  auth_has_group_role(group_id, auth.uid(), ARRAY['owner', 'co_owner']::group_member_role[])
);

-- Policy: Owners can update member roles
CREATE POLICY "Owners can update roles"
ON group_members
FOR UPDATE
TO authenticated
USING (
  auth_has_group_role(group_id, auth.uid(), ARRAY['owner']::group_member_role[])
)
WITH CHECK (
  auth_has_group_role(group_id, auth.uid(), ARRAY['owner']::group_member_role[])
);

-- Policy: Members can remove themselves; Owners/co-owners can remove others
CREATE POLICY "Members can leave or be removed"
ON group_members
FOR DELETE
TO authenticated
USING (
  -- User can remove themselves (leave)
  user_id = auth.uid()
  OR
  -- Owners and co-owners can remove others
  auth_has_group_role(group_id, auth.uid(), ARRAY['owner', 'co_owner']::group_member_role[])
);

-- ============================================================================
-- STEP 5: Create GROUP_INVITES table policies
-- ============================================================================

-- Policy: Invited users can see their invites; group members can see group's invites
CREATE POLICY "Users can view relevant invites"
ON group_invites
FOR SELECT
TO authenticated
USING (
  -- User can see invites sent to them
  invited_user_id = auth.uid()
  OR
  -- Group members can see pending invites for their group
  auth_is_group_member(group_id, auth.uid())
);

-- Policy: Owners and co-owners can create invites
CREATE POLICY "Owners and co-owners can invite"
ON group_invites
FOR INSERT
TO authenticated
WITH CHECK (
  auth_has_group_role(group_id, auth.uid(), ARRAY['owner', 'co_owner']::group_member_role[])
);

-- Policy: Invited user can delete (decline); inviters can cancel
CREATE POLICY "Users can decline or cancel invites"
ON group_invites
FOR DELETE
TO authenticated
USING (
  -- Invited user can decline
  invited_user_id = auth.uid()
  OR
  -- Owners/co-owners can cancel invites
  auth_has_group_role(group_id, auth.uid(), ARRAY['owner', 'co_owner']::group_member_role[])
);

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Check policies were created
SELECT tablename, policyname, cmd, roles
FROM pg_policies
WHERE tablename IN ('groups', 'group_members', 'group_invites')
ORDER BY tablename, policyname;
