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

-- Step 2: Add 'co_owner' to the enum type
-- NOTE: Run this statement FIRST, separately in the SQL editor before running the rest:
--   ALTER TYPE group_member_role ADD VALUE IF NOT EXISTS 'co_owner' AFTER 'owner';
--
-- PostgreSQL 9.3+ supports IF NOT EXISTS for ADD VALUE
ALTER TYPE group_member_role ADD VALUE IF NOT EXISTS 'co_owner' AFTER 'owner';

-- Step 3: Convert existing admin roles to member (if any exist)
-- (Admins become regular members)
UPDATE group_members
SET role = 'member'
WHERE role = 'admin';

-- Step 4: Update the get_user_groups function to include members_can_invite
-- Must drop first because return type changed
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

-- Add comment explaining the role system
COMMENT ON COLUMN group_members.role IS 'Member role: owner (full control), co_owner (promoted by owner, same permissions), or member (participant).';
