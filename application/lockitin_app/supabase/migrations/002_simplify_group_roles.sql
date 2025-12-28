-- Migration: Simplify Group Roles with Co-Owner Support
--
-- Changes:
-- 1. Add members_can_invite column to groups table
-- 2. Recreate enum with only: owner, co_owner, member (remove admin)
-- 3. Update RPC functions
--
-- Role system:
-- - owner: Original creator, full control, can promote to co-owner
-- - co_owner: Promoted by owner, same permissions as owner (except transfer ownership)
-- - member: Regular participant

-- Step 1: Add members_can_invite column to groups
ALTER TABLE groups
ADD COLUMN IF NOT EXISTS members_can_invite BOOLEAN DEFAULT true;

COMMENT ON COLUMN groups.members_can_invite IS 'Whether non-owner members can invite others to the group';

-- Step 2: Convert any existing admin roles to member before changing enum
UPDATE group_members
SET role = 'member'
WHERE role = 'admin';

-- Step 3: Recreate the enum type without 'admin'
-- First, change column to TEXT temporarily
ALTER TABLE group_members
ALTER COLUMN role TYPE TEXT;

-- Drop the old enum
DROP TYPE IF EXISTS group_member_role;

-- Create new enum with only the 3 valid roles
CREATE TYPE group_member_role AS ENUM ('owner', 'co_owner', 'member');

-- Convert column back to enum
ALTER TABLE group_members
ALTER COLUMN role TYPE group_member_role USING role::group_member_role;

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
