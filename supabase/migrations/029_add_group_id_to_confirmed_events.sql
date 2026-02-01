-- Migration: Add Group ID to Confirmed Events
-- Date: 2026-02-01
-- Purpose: Populate group_id when confirming proposals to enable group badge display

-- ============================================================================
-- PART 1: Add Foreign Key Constraint (if not exists)
-- ============================================================================

-- Add FK constraint to events.group_id
-- This ensures referential integrity and enables JOIN queries
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'fk_events_group_id'
  ) THEN
    ALTER TABLE events
    ADD CONSTRAINT fk_events_group_id
    FOREIGN KEY (group_id)
    REFERENCES groups(id)
    ON DELETE SET NULL;
  END IF;
END $$;

COMMENT ON CONSTRAINT fk_events_group_id ON events IS
'Foreign key to groups table. ON DELETE SET NULL preserves event history when group is deleted.';

-- ============================================================================
-- PART 2: Update confirm_proposal to Populate group_id
-- ============================================================================

-- Drop existing function
DROP FUNCTION IF EXISTS confirm_proposal(UUID, UUID);

-- Recreate with group_id population
CREATE OR REPLACE FUNCTION confirm_proposal(
  p_proposal_id UUID,
  p_option_id UUID
)
RETURNS UUID AS $$
DECLARE
  v_proposal event_proposals%ROWTYPE;
  v_time_option proposal_time_options%ROWTYPE;
  v_creator_event_id UUID;
  v_event_count INTEGER;
BEGIN
  -- Fetch proposal
  SELECT * INTO v_proposal FROM event_proposals WHERE id = p_proposal_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Proposal not found: %', p_proposal_id;
  END IF;

  -- Validate user is creator
  IF v_proposal.created_by != auth.uid() THEN
    RAISE EXCEPTION 'Only proposal creator can confirm';
  END IF;

  -- Validate status
  IF v_proposal.status != 'voting' THEN
    RAISE EXCEPTION 'Proposal status must be "voting", current: %', v_proposal.status;
  END IF;

  -- Fetch time option
  SELECT * INTO v_time_option
  FROM proposal_time_options
  WHERE id = p_option_id AND proposal_id = p_proposal_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Time option not found or does not belong to proposal';
  END IF;

  -- Create events for all group members who voted YES
  -- NEW: Now includes group_id from proposal
  INSERT INTO events (
    user_id,
    title,
    description,
    location,
    start_time,
    end_time,
    visibility,
    group_id,
    created_at
  )
  SELECT
    pv.user_id,
    v_proposal.title,
    v_proposal.description,
    v_proposal.location,
    v_time_option.start_time,
    v_time_option.end_time,
    'sharedWithName',
    v_proposal.group_id,
    now()
  FROM proposal_votes pv
  WHERE pv.option_id = p_option_id
    AND pv.vote = 'yes'; -- Only YES voters get event

  GET DIAGNOSTICS v_event_count = ROW_COUNT;

  -- Get the creator's event ID (for confirmation record)
  -- If creator didn't vote YES, use NULL
  SELECT id INTO v_creator_event_id
  FROM events
  WHERE user_id = v_proposal.created_by
    AND title = v_proposal.title
    AND start_time = v_time_option.start_time
  ORDER BY created_at DESC
  LIMIT 1;

  -- Update proposal status
  UPDATE event_proposals
  SET
    status = 'confirmed',
    confirmed_option_id = p_option_id,
    created_event_id = v_creator_event_id,
    updated_at = now()
  WHERE id = p_proposal_id;

  -- Notify all group members
  INSERT INTO notifications (
    user_id,
    type,
    title,
    body,
    data,
    created_at
  )
  SELECT
    gm.user_id,
    'proposal_confirmed',
    'Event Confirmed: ' || v_proposal.title,
    'The event "' || v_proposal.title || '" has been scheduled for ' ||
      to_char(v_time_option.start_time AT TIME ZONE 'UTC', 'Mon DD at HH12:MI AM'),
    jsonb_build_object('proposal_id', v_proposal.id),
    now()
  FROM group_members gm
  WHERE gm.group_id = v_proposal.group_id;

  -- Return creator's event ID (or NULL if creator didn't vote YES)
  RETURN v_creator_event_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION confirm_proposal(UUID, UUID) TO authenticated;

COMMENT ON FUNCTION confirm_proposal IS
'Confirms an event proposal by creating events for all YES voters.

Changes in this version:
- Populates group_id from proposal.group_id for group badge display
- Maintains FK constraint with ON DELETE SET NULL for group deletion

Parameters:
- p_proposal_id: Proposal to confirm
- p_option_id: Winning time option

Returns: Creator event ID (or NULL if creator did not vote YES)';
