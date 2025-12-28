-- Migration: Add Co-Owner Role Support
--
-- Role system:
-- - owner: Original creator, full control, can promote to co-owner
-- - co_owner: Promoted by owner, same permissions as owner (except transfer ownership)
-- - member: Regular participant
-- - admin: DEPRECATED (treated as 'member' by app, kept for backwards compatibility)

-- Step 1: Add members_can_invite column to groups
ALTER TABLE groups
ADD COLUMN IF NOT EXISTS members_can_invite BOOLEAN DEFAULT true;

COMMENT ON COLUMN groups.members_can_invite IS 'Whether non-owner members can invite others to the group';

-- Step 2: Add 'co_owner' to the enum type (run separately if needed)
ALTER TYPE group_member_role ADD VALUE IF NOT EXISTS 'co_owner' AFTER 'owner';

-- Step 3: Convert any existing admin roles to member
UPDATE group_members
SET role = 'member'
WHERE role = 'admin';

-- Step 4: Update the get_user_groups function to include members_can_invite
DROP FUNCTION IF EXISTS get_user_groups(UUID);

CREATE OR REPLACE FUNCTION get_user_groups(user_uuid UUID)
RETURNS TABLE (
  group_id UUID,
  name TEXT,
  emoji TEXT,
  created_by UUID,
  created_at TIMESTAMPTZ,
  member_count BIGINT,
  members_can_invite BOOLEAN
)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT
    g.id AS group_id,
    g.name,
    g.emoji,
    g.created_by,
    g.created_at,
    COUNT(gm2.id) AS member_count,
    g.members_can_invite
  FROM groups g
  INNER JOIN group_members gm ON g.id = gm.group_id AND gm.user_id = user_uuid
  LEFT JOIN group_members gm2 ON g.id = gm2.group_id
  GROUP BY g.id, g.name, g.emoji, g.created_by, g.created_at, g.members_can_invite
  ORDER BY g.created_at DESC;
$$;

-- Step 5: Update RLS policies to include co_owner where appropriate
-- Update policy for group updates (owner or co_owner can update)
DROP POLICY IF EXISTS "Owners and admins can update groups" ON groups;
CREATE POLICY "Owners and co-owners can update groups" ON groups
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_id = groups.id
      AND user_id = auth.uid()
      AND role IN ('owner', 'co_owner')
    )
  );

-- Update policy for adding members (owner or co_owner can add)
DROP POLICY IF EXISTS "Owners and admins can add members" ON group_members;
CREATE POLICY "Owners and co-owners can add members" ON group_members
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM group_members gm
      WHERE gm.group_id = group_members.group_id
      AND gm.user_id = auth.uid()
      AND gm.role IN ('owner', 'co_owner')
    )
    OR
    -- Allow users to add themselves when accepting an invite
    (user_id = auth.uid() AND role = 'member')
  );

-- Update policy for invites (owner or co_owner can invite)
DROP POLICY IF EXISTS "Owners and admins can invite" ON group_invites;
CREATE POLICY "Owners and co-owners can invite" ON group_invites
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_id = group_invites.group_id
      AND user_id = auth.uid()
      AND role IN ('owner', 'co_owner')
    )
    OR
    -- Members can invite if group allows it
    EXISTS (
      SELECT 1 FROM group_members gm
      JOIN groups g ON g.id = gm.group_id
      WHERE gm.group_id = group_invites.group_id
      AND gm.user_id = auth.uid()
      AND g.members_can_invite = true
    )
  );

-- Add comment explaining the role system
COMMENT ON COLUMN group_members.role IS 'Member role: owner, co_owner, or member. Admin is deprecated.';
