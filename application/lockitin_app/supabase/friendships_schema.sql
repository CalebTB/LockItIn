-- LockItIn Friendships Schema
-- Database schema for friend connections
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
DROP FUNCTION IF EXISTS get_friends(UUID);
DROP FUNCTION IF EXISTS get_pending_requests(UUID);
DROP FUNCTION IF EXISTS are_friends(UUID, UUID);
DROP TABLE IF EXISTS friendships;
DROP TYPE IF EXISTS friendship_status;

-- ============================================================================
-- FRIENDSHIPS TABLE
-- ============================================================================

-- Create friendship status enum
DO $$ BEGIN
  CREATE TYPE friendship_status AS ENUM ('pending', 'accepted', 'blocked');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Create friendships table
CREATE TABLE IF NOT EXISTS friendships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  friend_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status friendship_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  accepted_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE,

  -- Constraints
  CONSTRAINT unique_friendship UNIQUE(user_id, friend_id),
  CONSTRAINT no_self_friendship CHECK (user_id != friend_id)
);

-- Add updated_at trigger for friendships
CREATE TRIGGER update_friendships_updated_at
BEFORE UPDATE ON friendships
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- INDEXES for Performance
-- ============================================================================

-- Index for finding all friendships for a user (outgoing requests)
CREATE INDEX IF NOT EXISTS idx_friendships_user_id ON friendships(user_id);

-- Index for finding all friendship requests received (incoming requests)
CREATE INDEX IF NOT EXISTS idx_friendships_friend_id ON friendships(friend_id);

-- Index for filtering by status (pending, accepted, blocked)
CREATE INDEX IF NOT EXISTS idx_friendships_status ON friendships(status);

-- Composite index for finding accepted friends quickly
CREATE INDEX IF NOT EXISTS idx_friendships_user_accepted
ON friendships(user_id, status) WHERE status = 'accepted';

-- Composite index for finding pending requests quickly
CREATE INDEX IF NOT EXISTS idx_friendships_pending
ON friendships(friend_id, status) WHERE status = 'pending';

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

-- Enable RLS on friendships table
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view friendships where they are involved
CREATE POLICY "Users can view own friendships"
ON friendships
FOR SELECT
USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- Policy: Users can create friendship requests (as the requester)
CREATE POLICY "Users can send friend requests"
ON friendships
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update friendships they're involved in
-- (user_id can cancel, friend_id can accept/decline)
CREATE POLICY "Users can update own friendships"
ON friendships
FOR UPDATE
USING (auth.uid() = user_id OR auth.uid() = friend_id)
WITH CHECK (auth.uid() = user_id OR auth.uid() = friend_id);

-- Policy: Users can delete friendships they're involved in
-- Either party can delete (cancel pending request or remove friend)
CREATE POLICY "Users can delete own friendships"
ON friendships
FOR DELETE
USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to get all accepted friends for a user
CREATE OR REPLACE FUNCTION get_friends(user_uuid UUID)
RETURNS TABLE (friendship_id UUID, friend_id UUID, full_name TEXT, email TEXT, avatar_url TEXT, friendship_since TIMESTAMP WITH TIME ZONE) AS $$
BEGIN
  RETURN QUERY
  SELECT
    f.id as friendship_id,
    CASE
      WHEN f.user_id = user_uuid THEN f.friend_id
      ELSE f.user_id
    END as friend_id,
    u.full_name,
    u.email,
    u.avatar_url,
    f.accepted_at as friendship_since
  FROM friendships f
  JOIN users u ON u.id = CASE
    WHEN f.user_id = user_uuid THEN f.friend_id
    ELSE f.user_id
  END
  WHERE (f.user_id = user_uuid OR f.friend_id = user_uuid)
    AND f.status = 'accepted';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get pending friend requests received
CREATE OR REPLACE FUNCTION get_pending_requests(user_uuid UUID)
RETURNS TABLE (request_id UUID, requester_id UUID, full_name TEXT, email TEXT, avatar_url TEXT, requested_at TIMESTAMP WITH TIME ZONE) AS $$
BEGIN
  RETURN QUERY
  SELECT
    f.id as request_id,
    f.user_id as requester_id,
    u.full_name,
    u.email,
    u.avatar_url,
    f.created_at as requested_at
  FROM friendships f
  JOIN users u ON u.id = f.user_id
  WHERE f.friend_id = user_uuid
    AND f.status = 'pending';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if two users are friends
CREATE OR REPLACE FUNCTION are_friends(user1_uuid UUID, user2_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM friendships
    WHERE ((user_id = user1_uuid AND friend_id = user2_uuid)
        OR (user_id = user2_uuid AND friend_id = user1_uuid))
      AND status = 'accepted'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Run these queries to verify the schema was created correctly:

-- Check friendships table exists
-- SELECT table_name, column_name, data_type
-- FROM information_schema.columns
-- WHERE table_name = 'friendships';

-- Check indexes exist
-- SELECT indexname, indexdef
-- FROM pg_indexes
-- WHERE tablename = 'friendships';

-- Check RLS policies exist
-- SELECT policyname, cmd, qual
-- FROM pg_policies
-- WHERE tablename = 'friendships';

-- ============================================================================
-- NEXT STEPS
-- ============================================================================
--
-- After running this schema:
-- 1. Test friend request: INSERT INTO friendships (user_id, friend_id) VALUES (uuid1, uuid2)
-- 2. Accept request: UPDATE friendships SET status = 'accepted', accepted_at = now() WHERE id = request_id
-- 3. Test get_friends function: SELECT * FROM get_friends(your_user_id)
-- 4. Test get_pending_requests: SELECT * FROM get_pending_requests(your_user_id)
--
-- ============================================================================
