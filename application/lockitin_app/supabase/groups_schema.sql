-- LockItIn Groups Schema
-- Database schema for group management
--
-- HOW TO APPLY THIS SCHEMA:
-- 1. Go to https://app.supabase.com/
-- 2. Select your project
-- 3. Go to SQL Editor
-- 4. Copy and paste this entire file
-- 5. Click "Run" to execute
--
-- IMPORTANT: Run this AFTER applying schema.sql (users table must exist)
--
-- Last updated: December 27, 2025

-- ============================================================================
-- RESET (uncomment to drop and recreate everything)
-- ============================================================================

-- Drop existing objects to start fresh
-- DROP FUNCTION IF EXISTS get_user_groups(UUID);
-- DROP FUNCTION IF EXISTS get_group_members(UUID, UUID);
-- DROP TABLE IF EXISTS group_members;
-- DROP TABLE IF EXISTS groups;
-- DROP TYPE IF EXISTS group_member_role;

-- ============================================================================
-- GROUPS TABLE
-- ============================================================================

-- Create group member role enum
DO $$ BEGIN
  CREATE TYPE group_member_role AS ENUM ('owner', 'admin', 'member');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Create groups table
CREATE TABLE IF NOT EXISTS groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  emoji VARCHAR(10) NOT NULL DEFAULT '👥',
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE,

  -- Constraints
  CONSTRAINT name_not_empty CHECK (length(trim(name)) > 0)
);

-- Add updated_at trigger for groups
CREATE TRIGGER update_groups_updated_at
BEFORE UPDATE ON groups
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- GROUP_MEMBERS TABLE
-- ============================================================================

-- Create group_members table
CREATE TABLE IF NOT EXISTS group_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role group_member_role NOT NULL DEFAULT 'member',
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT now(),

  -- Constraints
  CONSTRAINT unique_group_membership UNIQUE(group_id, user_id)
);

-- ============================================================================
-- GROUP_INVITES TABLE
-- ============================================================================

-- Create group_invites table for pending invitations
CREATE TABLE IF NOT EXISTS group_invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  invited_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  invited_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),

  -- Constraints
  CONSTRAINT unique_group_invite UNIQUE(group_id, invited_user_id)
);

-- ============================================================================
-- INDEXES for Performance
-- ============================================================================

-- Index for finding all groups a user is a member of
CREATE INDEX IF NOT EXISTS idx_group_members_user_id ON group_members(user_id);

-- Index for finding all members of a group
CREATE INDEX IF NOT EXISTS idx_group_members_group_id ON group_members(group_id);

-- Index for finding groups by creator
CREATE INDEX IF NOT EXISTS idx_groups_created_by ON groups(created_by);

-- Composite index for role-based queries (e.g., find all admins)
CREATE INDEX IF NOT EXISTS idx_group_members_role ON group_members(group_id, role);

-- Index for finding all invites for a user
CREATE INDEX IF NOT EXISTS idx_group_invites_user_id ON group_invites(invited_user_id);

-- Index for finding all invites for a group
CREATE INDEX IF NOT EXISTS idx_group_invites_group_id ON group_invites(group_id);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

-- Enable RLS on groups table
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;

-- Enable RLS on group_members table
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- GROUPS RLS POLICIES
-- ============================================================================

-- Policy: Users can view groups they are a member of
CREATE POLICY "Users can view groups they belong to"
ON groups
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM group_members gm
    WHERE gm.group_id = groups.id
    AND gm.user_id = auth.uid()
  )
);

-- Policy: Any authenticated user can create a group
CREATE POLICY "Authenticated users can create groups"
ON groups
FOR INSERT
WITH CHECK (auth.uid() = created_by);

-- Policy: Owners and admins can update groups
CREATE POLICY "Owners and admins can update groups"
ON groups
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM group_members gm
    WHERE gm.group_id = groups.id
    AND gm.user_id = auth.uid()
    AND gm.role IN ('owner', 'admin')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM group_members gm
    WHERE gm.group_id = groups.id
    AND gm.user_id = auth.uid()
    AND gm.role IN ('owner', 'admin')
  )
);

-- Policy: Only owners can delete groups
CREATE POLICY "Only owners can delete groups"
ON groups
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM group_members gm
    WHERE gm.group_id = groups.id
    AND gm.user_id = auth.uid()
    AND gm.role = 'owner'
  )
);

-- ============================================================================
-- GROUP_MEMBERS RLS POLICIES
-- ============================================================================

-- Policy: Users can view members of groups they belong to
CREATE POLICY "Users can view group members"
ON group_members
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM group_members gm
    WHERE gm.group_id = group_members.group_id
    AND gm.user_id = auth.uid()
  )
);

-- Policy: Owners and admins can add members
CREATE POLICY "Owners and admins can add members"
ON group_members
FOR INSERT
WITH CHECK (
  -- Allow adding self (when creating a group)
  (user_id = auth.uid())
  OR
  -- Allow owners/admins to add others
  EXISTS (
    SELECT 1 FROM group_members gm
    WHERE gm.group_id = group_members.group_id
    AND gm.user_id = auth.uid()
    AND gm.role IN ('owner', 'admin')
  )
);

-- Policy: Owners can update member roles; members can update their own (leave)
CREATE POLICY "Owners can update roles"
ON group_members
FOR UPDATE
USING (
  -- Owner can update any member
  EXISTS (
    SELECT 1 FROM group_members gm
    WHERE gm.group_id = group_members.group_id
    AND gm.user_id = auth.uid()
    AND gm.role = 'owner'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM group_members gm
    WHERE gm.group_id = group_members.group_id
    AND gm.user_id = auth.uid()
    AND gm.role = 'owner'
  )
);

-- Policy: Members can remove themselves; Owners/admins can remove others
CREATE POLICY "Members can leave or be removed"
ON group_members
FOR DELETE
USING (
  -- User can remove themselves (leave)
  user_id = auth.uid()
  OR
  -- Owners and admins can remove others
  EXISTS (
    SELECT 1 FROM group_members gm
    WHERE gm.group_id = group_members.group_id
    AND gm.user_id = auth.uid()
    AND gm.role IN ('owner', 'admin')
  )
);

-- ============================================================================
-- GROUP_INVITES RLS POLICIES
-- ============================================================================

-- Enable RLS on group_invites table
ALTER TABLE group_invites ENABLE ROW LEVEL SECURITY;

-- Policy: Invited users can see their invites; group members can see group's invites
CREATE POLICY "Users can view relevant invites"
ON group_invites
FOR SELECT
USING (
  -- User can see invites sent to them
  invited_user_id = auth.uid()
  OR
  -- Group members can see pending invites for their group
  EXISTS (
    SELECT 1 FROM group_members gm
    WHERE gm.group_id = group_invites.group_id
    AND gm.user_id = auth.uid()
  )
);

-- Policy: Owners and admins can create invites
CREATE POLICY "Owners and admins can invite"
ON group_invites
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM group_members gm
    WHERE gm.group_id = group_invites.group_id
    AND gm.user_id = auth.uid()
    AND gm.role IN ('owner', 'admin')
  )
);

-- Policy: Invited user can delete (decline); inviters can cancel
CREATE POLICY "Users can decline or cancel invites"
ON group_invites
FOR DELETE
USING (
  -- Invited user can decline
  invited_user_id = auth.uid()
  OR
  -- Owners/admins can cancel invites
  EXISTS (
    SELECT 1 FROM group_members gm
    WHERE gm.group_id = group_invites.group_id
    AND gm.user_id = auth.uid()
    AND gm.role IN ('owner', 'admin')
  )
);

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to get all groups for a user with member count
CREATE OR REPLACE FUNCTION get_user_groups(user_uuid UUID)
RETURNS TABLE (
  group_id UUID,
  name VARCHAR(100),
  emoji VARCHAR(10),
  created_by UUID,
  created_at TIMESTAMP WITH TIME ZONE,
  member_count BIGINT,
  user_role group_member_role
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    g.id as group_id,
    g.name,
    g.emoji,
    g.created_by,
    g.created_at,
    (SELECT COUNT(*) FROM group_members gm2 WHERE gm2.group_id = g.id) as member_count,
    gm.role as user_role
  FROM groups g
  JOIN group_members gm ON gm.group_id = g.id AND gm.user_id = user_uuid
  ORDER BY g.name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get all members of a group with profile info
CREATE OR REPLACE FUNCTION get_group_members(group_uuid UUID, user_uuid UUID)
RETURNS TABLE (
  member_id UUID,
  user_id UUID,
  full_name TEXT,
  email TEXT,
  avatar_url TEXT,
  role group_member_role,
  joined_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  -- First verify the requesting user is a member of this group
  IF NOT EXISTS (
    SELECT 1 FROM group_members
    WHERE group_id = group_uuid AND group_members.user_id = user_uuid
  ) THEN
    RAISE EXCEPTION 'Access denied: User is not a member of this group';
  END IF;

  RETURN QUERY
  SELECT
    gm.id as member_id,
    gm.user_id,
    u.full_name,
    u.email,
    u.avatar_url,
    gm.role,
    gm.joined_at
  FROM group_members gm
  JOIN users u ON u.id = gm.user_id
  WHERE gm.group_id = group_uuid
  ORDER BY
    CASE gm.role
      WHEN 'owner' THEN 1
      WHEN 'admin' THEN 2
      ELSE 3
    END,
    gm.joined_at;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if a user is a member of a group
CREATE OR REPLACE FUNCTION is_group_member(group_uuid UUID, user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM group_members
    WHERE group_id = group_uuid AND user_id = user_uuid
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get a user's role in a group
CREATE OR REPLACE FUNCTION get_group_role(group_uuid UUID, user_uuid UUID)
RETURNS group_member_role AS $$
DECLARE
  user_role group_member_role;
BEGIN
  SELECT role INTO user_role
  FROM group_members
  WHERE group_id = group_uuid AND user_id = user_uuid;

  RETURN user_role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get all pending group invites for a user
CREATE OR REPLACE FUNCTION get_pending_group_invites(user_uuid UUID)
RETURNS TABLE (
  invite_id UUID,
  group_id UUID,
  group_name VARCHAR(100),
  group_emoji VARCHAR(10),
  invited_by UUID,
  inviter_name TEXT,
  invited_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    gi.id as invite_id,
    gi.group_id,
    g.name as group_name,
    g.emoji as group_emoji,
    gi.invited_by,
    u.full_name as inviter_name,
    gi.created_at as invited_at
  FROM group_invites gi
  JOIN groups g ON g.id = gi.group_id
  JOIN users u ON u.id = gi.invited_by
  WHERE gi.invited_user_id = user_uuid
  ORDER BY gi.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Run these queries to verify the schema was created correctly:

-- Check groups table exists
-- SELECT table_name, column_name, data_type
-- FROM information_schema.columns
-- WHERE table_name = 'groups';

-- Check group_members table exists
-- SELECT table_name, column_name, data_type
-- FROM information_schema.columns
-- WHERE table_name = 'group_members';

-- Check indexes exist
-- SELECT indexname, indexdef
-- FROM pg_indexes
-- WHERE tablename IN ('groups', 'group_members');

-- Check RLS policies exist
-- SELECT tablename, policyname, cmd
-- FROM pg_policies
-- WHERE tablename IN ('groups', 'group_members');

-- ============================================================================
-- TESTING THE SCHEMA
-- ============================================================================

-- To test the schema, run these queries in order:

-- 1. Create a group (replace YOUR_USER_ID with actual UUID)
-- INSERT INTO groups (name, emoji, created_by)
-- VALUES ('Test Group', '🎉', 'YOUR_USER_ID')
-- RETURNING id;

-- 2. Add yourself as owner (replace GROUP_ID and YOUR_USER_ID)
-- INSERT INTO group_members (group_id, user_id, role)
-- VALUES ('GROUP_ID', 'YOUR_USER_ID', 'owner');

-- 3. Test get_user_groups function
-- SELECT * FROM get_user_groups('YOUR_USER_ID');

-- 4. Test get_group_members function
-- SELECT * FROM get_group_members('GROUP_ID', 'YOUR_USER_ID');

-- ============================================================================
-- NEXT STEPS
-- ============================================================================
--
-- After running this schema:
-- 1. Apply the schema in Supabase SQL Editor
-- 2. Test creating a group through the Flutter app
-- 3. Verify RLS policies work correctly (members can only see their groups)
-- 4. Test adding/removing members
--
-- ============================================================================
