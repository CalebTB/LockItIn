-- Migration: Simplify Group Roles with Co-Owner Support
--
-- Changes:
-- 1. Add members_can_invite column to groups table
-- 2. Convert existing 'admin' roles to 'member'
-- 3. Update role constraint to allow 'owner', 'co_owner', and 'member'
-- 4. Update RPC functions if needed
--
-- Role system:
-- - owner: Original creator, full control, can promote to co-owner
-- - co_owner: Promoted by owner, same permissions as owner (except transfer ownership)
-- - member: Regular participant

-- Step 1: Add members_can_invite column to groups
ALTER TABLE groups
ADD COLUMN IF NOT EXISTS members_can_invite BOOLEAN DEFAULT true;

COMMENT ON COLUMN groups.members_can_invite IS 'Whether non-owner members can invite others to the group';

-- Step 2: Convert existing admin roles to member
-- (Admins become regular members in 2-tier system)
UPDATE group_members
SET role = 'member'
WHERE role = 'admin';

-- Step 3: Update the role constraint
-- First drop the old constraint if it exists
ALTER TABLE group_members
DROP CONSTRAINT IF EXISTS group_members_role_check;

-- Add new constraint with owner, co_owner, and member
ALTER TABLE group_members
ADD CONSTRAINT group_members_role_check
CHECK (role IN ('owner', 'co_owner', 'member'));

-- Step 4: Update the get_user_groups function to include members_can_invite
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

-- Add comment explaining the role system
COMMENT ON COLUMN group_members.role IS 'Member role: owner (full control), co_owner (promoted by owner, same permissions), or member (participant).';
