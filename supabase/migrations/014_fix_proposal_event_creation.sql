-- Migration 014: Fix Proposal Event Creation
--
-- CRITICAL FIX: When a proposal is confirmed, create events for ALL group members
-- who voted YES, not just the proposal creator.
--
-- Also adds notification delivery to all group members and a helper function
-- to automatically determine the winning time option.

-- Drop existing confirm_proposal function to recreate with fixes
DROP FUNCTION IF EXISTS confirm_proposal(UUID, UUID);

-- Recreated confirm_proposal with multi-user event creation
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

  -- CRITICAL FIX: Create events for all group members who voted YES
  -- (Previously only created event for proposal creator)
  INSERT INTO events (
    user_id,
    title,
    description,
    location,
    start_time,
    end_time,
    visibility,
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
    now()
  FROM proposal_votes pv
  WHERE pv.time_option_id = p_option_id
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
    confirmed_time_option_id = p_option_id,
    confirmed_event_id = v_creator_event_id,
    updated_at = now()
  WHERE id = p_proposal_id;

  -- Notify all group members
  INSERT INTO notifications (
    user_id,
    type,
    title,
    message,
    related_proposal_id,
    created_at
  )
  SELECT
    gm.user_id,
    'proposal_confirmed',
    'Event Confirmed: ' || v_proposal.title,
    'The event "' || v_proposal.title || '" has been scheduled for ' ||
      to_char(v_time_option.start_time AT TIME ZONE 'UTC', 'Mon DD at HH12:MI AM'),
    v_proposal.id,
    now()
  FROM group_members gm
  WHERE gm.group_id = v_proposal.group_id;

  -- Return creator's event ID (or NULL if creator didn't vote YES)
  RETURN v_creator_event_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Helper function to get winning time option
-- Uses scoring system: yes=2, maybe=1, no=0
-- Tiebreaker: most yes votes
CREATE OR REPLACE FUNCTION get_winning_time_option(p_proposal_id UUID)
RETURNS UUID AS $$
DECLARE
  v_winner_id UUID;
BEGIN
  -- Get option with highest score
  -- Score = (yes_count * 2) + (maybe_count * 1)
  -- Tiebreaker 1: most yes votes
  -- Tiebreaker 2: earliest created option
  SELECT id INTO v_winner_id
  FROM proposal_time_options pto
  LEFT JOIN (
    SELECT
      pv.time_option_id,
      COUNT(*) FILTER (WHERE pv.vote = 'yes') as yes_count,
      COUNT(*) FILTER (WHERE pv.vote = 'maybe') as maybe_count,
      COUNT(*) FILTER (WHERE pv.vote = 'no') as no_count
    FROM proposal_votes pv
    WHERE pv.proposal_id = p_proposal_id
    GROUP BY pv.time_option_id
  ) vote_summary ON pto.id = vote_summary.time_option_id
  WHERE pto.proposal_id = p_proposal_id
  ORDER BY
    COALESCE(vote_summary.yes_count, 0) * 2 + COALESCE(vote_summary.maybe_count, 0) DESC,  -- Score
    COALESCE(vote_summary.yes_count, 0) DESC,                                                -- Tiebreaker 1
    pto.created_at ASC                                                                       -- Tiebreaker 2
  LIMIT 1;

  RETURN v_winner_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION confirm_proposal(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_winning_time_option(UUID) TO authenticated;
