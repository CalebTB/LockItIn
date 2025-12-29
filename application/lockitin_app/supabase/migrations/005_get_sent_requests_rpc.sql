-- ============================================================================
-- Migration: 005_get_sent_requests_rpc.sql
-- Description: Add RPC function for fetching sent friend requests
-- Issue: #99 - Add missing get_sent_requests RPC function
-- ============================================================================

-- Function to get sent (outgoing) friend requests for a user
-- Mirrors get_pending_requests but for requests the user has sent
CREATE OR REPLACE FUNCTION get_sent_requests(user_uuid UUID)
RETURNS TABLE (
  request_id UUID,
  recipient_id UUID,
  full_name TEXT,
  email TEXT,
  avatar_url TEXT,
  sent_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    f.id as request_id,
    f.friend_id as recipient_id,
    u.full_name,
    u.email,
    u.avatar_url,
    f.created_at as sent_at
  FROM friendships f
  JOIN users u ON u.id = f.friend_id
  WHERE f.user_id = user_uuid
    AND f.status = 'pending';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_sent_requests(UUID) TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION get_sent_requests IS
'Returns all pending friend requests sent by the specified user, with recipient profile info.';
