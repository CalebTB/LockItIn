-- ============================================================================
-- Migration: 004_transfer_ownership_rpc.sql
-- Description: Add RPC function for atomic group ownership transfer
-- Issue: #98 - transferOwnership lacks transaction safety
-- ============================================================================

-- Function to atomically transfer group ownership
-- Uses transaction to ensure both updates succeed or both fail
-- Prevents data corruption (two owners or orphaned groups)
CREATE OR REPLACE FUNCTION transfer_group_ownership(
  p_group_id UUID,
  p_new_owner_id UUID,
  p_current_owner_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
  v_current_role group_member_role;
  v_new_owner_exists BOOLEAN;
BEGIN
  -- Verify current user is the owner
  SELECT role INTO v_current_role
  FROM group_members
  WHERE group_id = p_group_id AND user_id = p_current_owner_id;

  IF v_current_role IS NULL OR v_current_role != 'owner' THEN
    RAISE EXCEPTION 'Only the owner can transfer ownership';
  END IF;

  -- Verify new owner is a member of the group
  SELECT EXISTS (
    SELECT 1 FROM group_members
    WHERE group_id = p_group_id AND user_id = p_new_owner_id
  ) INTO v_new_owner_exists;

  IF NOT v_new_owner_exists THEN
    RAISE EXCEPTION 'New owner must be a member of the group';
  END IF;

  -- Atomic update: promote new owner
  UPDATE group_members
  SET role = 'owner'
  WHERE group_id = p_group_id AND user_id = p_new_owner_id;

  -- Atomic update: demote current owner
  UPDATE group_members
  SET role = 'member'
  WHERE group_id = p_group_id AND user_id = p_current_owner_id;

  RETURN TRUE;

EXCEPTION WHEN OTHERS THEN
  -- Transaction automatically rolls back on exception
  RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION transfer_group_ownership(UUID, UUID, UUID) TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION transfer_group_ownership IS
'Atomically transfers group ownership from current owner to new owner.
Both role updates happen in a single transaction to prevent data corruption.';
