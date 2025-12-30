-- Migration: 007_get_user_groups_with_counts
-- Description: Create RPC function to get user groups with member counts in a single query
-- Fixes: Issue #96 - N+1 query in getUserGroups()
--
-- Previously, getUserGroups() made 2 database queries:
-- 1. Get groups via join on group_members
-- 2. Get member counts for all groups separately
--
-- This RPC function combines both into a single efficient query using
-- PostgreSQL aggregate functions.

-- Drop function if exists (for idempotent migrations)
DROP FUNCTION IF EXISTS get_user_groups_with_counts(UUID);

-- Create optimized function to get user groups with member counts
CREATE OR REPLACE FUNCTION get_user_groups_with_counts(user_uuid UUID)
RETURNS TABLE (
  id UUID,
  name TEXT,
  emoji TEXT,
  created_by UUID,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  members_can_invite BOOLEAN,
  member_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    g.id,
    g.name::TEXT,
    g.emoji::TEXT,
    g.created_by,
    g.created_at,
    g.updated_at,
    g.members_can_invite,
    COUNT(gm2.user_id)::BIGINT as member_count
  FROM group_members gm
  INNER JOIN groups g ON g.id = gm.group_id
  LEFT JOIN group_members gm2 ON gm2.group_id = g.id
  WHERE gm.user_id = user_uuid
  GROUP BY g.id, g.name, g.emoji, g.created_by, g.created_at, g.updated_at, g.members_can_invite
  ORDER BY g.created_at DESC;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_user_groups_with_counts(UUID) TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION get_user_groups_with_counts IS
'Fetches all groups a user belongs to with member counts in a single query.
Used by GroupService.getUserGroups() to avoid N+1 query pattern.
Returns groups ordered by creation date descending.';
