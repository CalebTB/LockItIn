-- ============================================================================
-- Migration: 006_fix_group_members_insert_policy.sql
-- Description: Fix RLS policy for group_members INSERT (allow self-add on group creation)
-- Issue: New users cannot create groups - RLS denies INSERT to group_members
-- ============================================================================

-- Drop existing INSERT policy if it exists
DROP POLICY IF EXISTS "Owners and co-owners can add members" ON group_members;

-- Recreate the INSERT policy with correct conditions
-- This policy allows:
-- 1. Users to add themselves (needed when creating a group - user becomes owner)
-- 2. Owners/co-owners to add other members to their groups
CREATE POLICY "Owners and co-owners can add members"
ON group_members
FOR INSERT
TO authenticated
WITH CHECK (
  -- Allow adding self (when creating a group)
  (user_id = auth.uid())
  OR
  -- Allow owners/co-owners to add others
  auth_has_group_role(group_id, auth.uid(), ARRAY['owner', 'co_owner']::group_member_role[])
);

-- Add comment for documentation
COMMENT ON POLICY "Owners and co-owners can add members" ON group_members IS
'Allows users to add themselves when creating a group, and allows owners/co-owners to invite others.';
