-- Migration 012: Create Proposals & Voting Tables
-- Issue #144: Create database tables for event proposals and voting
--
-- This migration creates:
-- 1. event_proposals table - Group event proposals with voting
-- 2. proposal_time_options table - Time slots for voting
-- 3. proposal_votes table - User votes on time options
-- 4. RLS policies for group member access
-- 5. Indexes for performance
-- 6. RPC functions for vote summaries
-- 7. Realtime enabled for live vote updates

-- ============================================================================
-- PROPOSAL STATUS ENUM
-- ============================================================================

DO $$ BEGIN
  CREATE TYPE proposal_status AS ENUM ('voting', 'confirmed', 'cancelled', 'expired');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE vote_type AS ENUM ('yes', 'no', 'maybe');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================================
-- TABLE 1: EVENT_PROPOSALS
-- ============================================================================
-- Purpose: Group event proposals that go through voting process

CREATE TABLE IF NOT EXISTS event_proposals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Relationships
  group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Basic info
  title TEXT NOT NULL CHECK (length(trim(title)) > 0),
  description TEXT,
  location TEXT,

  -- Voting config
  voting_deadline TIMESTAMPTZ NOT NULL,
  min_votes_required INTEGER DEFAULT 1,
  auto_confirm BOOLEAN DEFAULT true,

  -- Status tracking
  status proposal_status NOT NULL DEFAULT 'voting',
  confirmed_time_option_id UUID, -- Set when proposal is confirmed
  confirmed_event_id UUID, -- Reference to created event

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ
);

-- Add foreign key for confirmed_time_option_id (will be created after proposal_time_options table)
-- Add foreign key for confirmed_event_id
ALTER TABLE event_proposals
  ADD CONSTRAINT fk_confirmed_event
  FOREIGN KEY (confirmed_event_id) REFERENCES events(id) ON DELETE SET NULL;

COMMENT ON TABLE event_proposals IS 'Group event proposals with voting on time options';
COMMENT ON COLUMN event_proposals.voting_deadline IS 'When voting ends and winner is determined';
COMMENT ON COLUMN event_proposals.auto_confirm IS 'If true, auto-create event when all members vote';
COMMENT ON COLUMN event_proposals.confirmed_time_option_id IS 'The winning time option after voting';

-- Indexes for event_proposals
CREATE INDEX IF NOT EXISTS idx_proposals_group ON event_proposals(group_id);
CREATE INDEX IF NOT EXISTS idx_proposals_creator ON event_proposals(created_by);
CREATE INDEX IF NOT EXISTS idx_proposals_status ON event_proposals(status);
CREATE INDEX IF NOT EXISTS idx_proposals_deadline ON event_proposals(voting_deadline);
CREATE INDEX IF NOT EXISTS idx_proposals_group_active ON event_proposals(group_id, status, voting_deadline)
  WHERE status = 'voting';

-- ============================================================================
-- TABLE 2: PROPOSAL_TIME_OPTIONS
-- ============================================================================
-- Purpose: Time slot options for event proposals

CREATE TABLE IF NOT EXISTS proposal_time_options (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  proposal_id UUID NOT NULL REFERENCES event_proposals(id) ON DELETE CASCADE,

  -- Time slot
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,

  -- Order for display
  option_order INTEGER NOT NULL DEFAULT 1,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),

  -- Constraints
  CONSTRAINT valid_time_range CHECK (end_time > start_time),
  UNIQUE(proposal_id, option_order)
);

COMMENT ON TABLE proposal_time_options IS 'Time slot options for event proposals';
COMMENT ON COLUMN proposal_time_options.option_order IS 'Display order of options (1-5)';

-- Add foreign key for confirmed_time_option_id now that table exists
ALTER TABLE event_proposals
  ADD CONSTRAINT fk_confirmed_time_option
  FOREIGN KEY (confirmed_time_option_id) REFERENCES proposal_time_options(id) ON DELETE SET NULL;

-- Indexes for proposal_time_options
CREATE INDEX IF NOT EXISTS idx_time_options_proposal ON proposal_time_options(proposal_id);

-- ============================================================================
-- TABLE 3: PROPOSAL_VOTES
-- ============================================================================
-- Purpose: User votes on proposal time options

CREATE TABLE IF NOT EXISTS proposal_votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  proposal_id UUID NOT NULL REFERENCES event_proposals(id) ON DELETE CASCADE,
  time_option_id UUID NOT NULL REFERENCES proposal_time_options(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Vote type
  vote vote_type NOT NULL,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ,

  -- One vote per user per time option
  UNIQUE(proposal_id, time_option_id, user_id)
);

COMMENT ON TABLE proposal_votes IS 'User votes on proposal time options';
COMMENT ON COLUMN proposal_votes.vote IS 'yes = available, maybe = if needed, no = unavailable';

-- Indexes for proposal_votes
CREATE INDEX IF NOT EXISTS idx_votes_proposal ON proposal_votes(proposal_id);
CREATE INDEX IF NOT EXISTS idx_votes_time_option ON proposal_votes(time_option_id);
CREATE INDEX IF NOT EXISTS idx_votes_user ON proposal_votes(user_id);
CREATE INDEX IF NOT EXISTS idx_votes_proposal_user ON proposal_votes(proposal_id, user_id);

-- ============================================================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE event_proposals ENABLE ROW LEVEL SECURITY;
ALTER TABLE proposal_time_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE proposal_votes ENABLE ROW LEVEL SECURITY;

-- Helper function to check group membership (SECURITY DEFINER to bypass RLS)
CREATE OR REPLACE FUNCTION auth_is_proposal_group_member(proposal_id UUID, user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM event_proposals ep
    JOIN group_members gm ON gm.group_id = ep.group_id
    WHERE ep.id = proposal_id
    AND gm.user_id = user_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- EVENT_PROPOSALS POLICIES

CREATE POLICY "Group members can view proposals"
  ON event_proposals FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM group_members gm
      WHERE gm.group_id = event_proposals.group_id
      AND gm.user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Group members can create proposals"
  ON event_proposals FOR INSERT TO authenticated
  WITH CHECK (
    created_by = (SELECT auth.uid())
    AND EXISTS (
      SELECT 1 FROM group_members gm
      WHERE gm.group_id = event_proposals.group_id
      AND gm.user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Creators can update their proposals"
  ON event_proposals FOR UPDATE TO authenticated
  USING (created_by = (SELECT auth.uid()));

CREATE POLICY "Creators can delete their proposals"
  ON event_proposals FOR DELETE TO authenticated
  USING (created_by = (SELECT auth.uid()));

-- PROPOSAL_TIME_OPTIONS POLICIES

CREATE POLICY "Group members can view time options"
  ON proposal_time_options FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM event_proposals ep
      JOIN group_members gm ON gm.group_id = ep.group_id
      WHERE ep.id = proposal_time_options.proposal_id
      AND gm.user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Proposal creators can add time options"
  ON proposal_time_options FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM event_proposals ep
      WHERE ep.id = proposal_time_options.proposal_id
      AND ep.created_by = (SELECT auth.uid())
    )
  );

CREATE POLICY "Proposal creators can update time options"
  ON proposal_time_options FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM event_proposals ep
      WHERE ep.id = proposal_time_options.proposal_id
      AND ep.created_by = (SELECT auth.uid())
    )
  );

CREATE POLICY "Proposal creators can delete time options"
  ON proposal_time_options FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM event_proposals ep
      WHERE ep.id = proposal_time_options.proposal_id
      AND ep.created_by = (SELECT auth.uid())
    )
  );

-- PROPOSAL_VOTES POLICIES

CREATE POLICY "Group members can view votes"
  ON proposal_votes FOR SELECT TO authenticated
  USING (
    auth_is_proposal_group_member(proposal_id, (SELECT auth.uid()))
  );

CREATE POLICY "Group members can cast votes"
  ON proposal_votes FOR INSERT TO authenticated
  WITH CHECK (
    user_id = (SELECT auth.uid())
    AND auth_is_proposal_group_member(proposal_id, (SELECT auth.uid()))
    AND EXISTS (
      SELECT 1 FROM event_proposals ep
      WHERE ep.id = proposal_votes.proposal_id
      AND ep.status = 'voting'
      AND ep.voting_deadline > now()
    )
  );

CREATE POLICY "Users can update their own votes"
  ON proposal_votes FOR UPDATE TO authenticated
  USING (
    user_id = (SELECT auth.uid())
    AND EXISTS (
      SELECT 1 FROM event_proposals ep
      WHERE ep.id = proposal_votes.proposal_id
      AND ep.status = 'voting'
      AND ep.voting_deadline > now()
    )
  );

CREATE POLICY "Users can delete their own votes"
  ON proposal_votes FOR DELETE TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Updated_at trigger for event_proposals
CREATE TRIGGER update_proposals_updated_at
  BEFORE UPDATE ON event_proposals
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Updated_at trigger for proposal_votes
CREATE TRIGGER update_votes_updated_at
  BEFORE UPDATE ON proposal_votes
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- RPC FUNCTIONS
-- ============================================================================

-- Get vote summary for a proposal
CREATE OR REPLACE FUNCTION get_proposal_vote_summary(p_proposal_id UUID)
RETURNS TABLE (
  time_option_id UUID,
  start_time TIMESTAMPTZ,
  end_time TIMESTAMPTZ,
  yes_count INTEGER,
  maybe_count INTEGER,
  no_count INTEGER,
  total_votes INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    pto.id AS time_option_id,
    pto.start_time,
    pto.end_time,
    COALESCE(SUM(CASE WHEN pv.vote = 'yes' THEN 1 ELSE 0 END)::INTEGER, 0) AS yes_count,
    COALESCE(SUM(CASE WHEN pv.vote = 'maybe' THEN 1 ELSE 0 END)::INTEGER, 0) AS maybe_count,
    COALESCE(SUM(CASE WHEN pv.vote = 'no' THEN 1 ELSE 0 END)::INTEGER, 0) AS no_count,
    COALESCE(COUNT(pv.id)::INTEGER, 0) AS total_votes
  FROM proposal_time_options pto
  LEFT JOIN proposal_votes pv ON pv.time_option_id = pto.id
  WHERE pto.proposal_id = p_proposal_id
  GROUP BY pto.id, pto.start_time, pto.end_time, pto.option_order
  ORDER BY pto.option_order;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Get detailed votes for a time option (who voted what)
CREATE OR REPLACE FUNCTION get_time_option_votes(p_time_option_id UUID)
RETURNS TABLE (
  user_id UUID,
  full_name TEXT,
  avatar_url TEXT,
  vote vote_type,
  voted_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    u.id AS user_id,
    u.full_name,
    u.avatar_url,
    pv.vote,
    pv.created_at AS voted_at
  FROM proposal_votes pv
  JOIN users u ON u.id = pv.user_id
  WHERE pv.time_option_id = p_time_option_id
  ORDER BY pv.created_at;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Check if user has voted on a proposal
CREATE OR REPLACE FUNCTION has_user_voted_on_proposal(p_proposal_id UUID, p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM proposal_votes
    WHERE proposal_id = p_proposal_id
    AND user_id = p_user_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Confirm a proposal with winning time option
CREATE OR REPLACE FUNCTION confirm_proposal(
  p_proposal_id UUID,
  p_time_option_id UUID
)
RETURNS UUID AS $$
DECLARE
  v_proposal event_proposals%ROWTYPE;
  v_time_option proposal_time_options%ROWTYPE;
  v_new_event_id UUID;
BEGIN
  -- Get proposal
  SELECT * INTO v_proposal FROM event_proposals WHERE id = p_proposal_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Proposal not found';
  END IF;

  -- Check if user is creator
  IF v_proposal.created_by != auth.uid() THEN
    RAISE EXCEPTION 'Only the proposal creator can confirm';
  END IF;

  -- Check if still in voting status
  IF v_proposal.status != 'voting' THEN
    RAISE EXCEPTION 'Proposal is not in voting status';
  END IF;

  -- Get time option
  SELECT * INTO v_time_option FROM proposal_time_options
  WHERE id = p_time_option_id AND proposal_id = p_proposal_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Time option not found or does not belong to this proposal';
  END IF;

  -- Create the confirmed event
  INSERT INTO events (
    user_id,
    title,
    description,
    location,
    start_time,
    end_time,
    visibility
  ) VALUES (
    v_proposal.created_by,
    v_proposal.title,
    v_proposal.description,
    v_proposal.location,
    v_time_option.start_time,
    v_time_option.end_time,
    'sharedWithName' -- Group events are shared
  )
  RETURNING id INTO v_new_event_id;

  -- Update proposal status
  UPDATE event_proposals
  SET
    status = 'confirmed',
    confirmed_time_option_id = p_time_option_id,
    confirmed_event_id = v_new_event_id,
    updated_at = now()
  WHERE id = p_proposal_id;

  RETURN v_new_event_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Create proposal with time options in a single transaction
CREATE OR REPLACE FUNCTION create_proposal_with_options(
  p_group_id UUID,
  p_title TEXT,
  p_description TEXT,
  p_location TEXT,
  p_voting_deadline TIMESTAMPTZ,
  p_time_options JSONB -- Array of {start_time, end_time}
)
RETURNS UUID AS $$
DECLARE
  v_proposal_id UUID;
  v_option JSONB;
  v_order INTEGER := 1;
BEGIN
  -- Create proposal
  INSERT INTO event_proposals (
    group_id,
    created_by,
    title,
    description,
    location,
    voting_deadline
  ) VALUES (
    p_group_id,
    auth.uid(),
    p_title,
    p_description,
    p_location,
    p_voting_deadline
  )
  RETURNING id INTO v_proposal_id;

  -- Create time options
  FOR v_option IN SELECT * FROM jsonb_array_elements(p_time_options)
  LOOP
    INSERT INTO proposal_time_options (
      proposal_id,
      start_time,
      end_time,
      option_order
    ) VALUES (
      v_proposal_id,
      (v_option->>'start_time')::TIMESTAMPTZ,
      (v_option->>'end_time')::TIMESTAMPTZ,
      v_order
    );
    v_order := v_order + 1;
  END LOOP;

  RETURN v_proposal_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Get proposals for a group with vote summaries
CREATE OR REPLACE FUNCTION get_group_proposals(p_group_id UUID)
RETURNS TABLE (
  id UUID,
  title TEXT,
  description TEXT,
  location TEXT,
  voting_deadline TIMESTAMPTZ,
  status proposal_status,
  created_by UUID,
  creator_name TEXT,
  created_at TIMESTAMPTZ,
  total_options INTEGER,
  total_votes INTEGER,
  user_has_voted BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    ep.id,
    ep.title,
    ep.description,
    ep.location,
    ep.voting_deadline,
    ep.status,
    ep.created_by,
    u.full_name AS creator_name,
    ep.created_at,
    (SELECT COUNT(*)::INTEGER FROM proposal_time_options pto WHERE pto.proposal_id = ep.id) AS total_options,
    (SELECT COUNT(DISTINCT pv.user_id)::INTEGER FROM proposal_votes pv WHERE pv.proposal_id = ep.id) AS total_votes,
    has_user_voted_on_proposal(ep.id, auth.uid()) AS user_has_voted
  FROM event_proposals ep
  JOIN users u ON u.id = ep.created_by
  WHERE ep.group_id = p_group_id
  ORDER BY
    CASE WHEN ep.status = 'voting' THEN 0 ELSE 1 END,
    ep.voting_deadline DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- REALTIME CONFIGURATION
-- ============================================================================

-- Enable realtime for proposal_votes (for live vote updates)
ALTER PUBLICATION supabase_realtime ADD TABLE proposal_votes;

-- Enable realtime for event_proposals (for status changes)
ALTER PUBLICATION supabase_realtime ADD TABLE event_proposals;

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

GRANT USAGE ON TYPE proposal_status TO authenticated;
GRANT USAGE ON TYPE vote_type TO authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE ON event_proposals TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON proposal_time_options TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON proposal_votes TO authenticated;

GRANT EXECUTE ON FUNCTION get_proposal_vote_summary TO authenticated;
GRANT EXECUTE ON FUNCTION get_time_option_votes TO authenticated;
GRANT EXECUTE ON FUNCTION has_user_voted_on_proposal TO authenticated;
GRANT EXECUTE ON FUNCTION confirm_proposal TO authenticated;
GRANT EXECUTE ON FUNCTION create_proposal_with_options TO authenticated;
GRANT EXECUTE ON FUNCTION get_group_proposals TO authenticated;
GRANT EXECUTE ON FUNCTION auth_is_proposal_group_member TO authenticated;
