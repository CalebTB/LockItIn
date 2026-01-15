-- Exclude guest of honor from proposal votes and viewing
-- For Surprise Party template, the guest of honor should NOT be able to vote or see the proposal

-- Add RLS policy to hide surprise party proposals from guest of honor
-- First, drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view proposals they can vote on or created" ON event_proposals;
DROP POLICY IF EXISTS "Users can view time options for proposals they can see" ON proposal_time_options;
DROP POLICY IF EXISTS "Users can view proposals in their groups" ON event_proposals;
DROP POLICY IF EXISTS "Users can view proposal time options" ON proposal_time_options;

-- Create RLS policy that excludes guest of honor from seeing surprise party proposals
CREATE POLICY "Users can view proposals in their groups (except guests of honor)"
ON event_proposals FOR SELECT TO authenticated
USING (
  -- User created the proposal
  created_by = auth.uid()
  OR
  -- User is a member of the group AND (no template OR not the guest of honor)
  (
    EXISTS (
      SELECT 1 FROM group_members gm
      WHERE gm.group_id = event_proposals.group_id
      AND gm.user_id = auth.uid()
    )
    AND (
      -- No template data (regular proposal)
      (template_data = '{}'::jsonb OR template_data IS NULL)
      OR
      -- Has template but user is not the guest of honor
      (template_data->>'guestOfHonorId' IS NULL)
      OR
      ((template_data->>'guestOfHonorId')::UUID != auth.uid())
    )
  )
);

-- Create RLS policy for time options based on proposal visibility
CREATE POLICY "Users can view time options for visible proposals"
ON proposal_time_options FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM event_proposals ep
    JOIN group_members gm ON gm.group_id = ep.group_id
    WHERE ep.id = proposal_time_options.proposal_id
    AND (
      ep.created_by = auth.uid()
      OR
      (
        gm.user_id = auth.uid()
        AND (
          (ep.template_data = '{}'::jsonb OR ep.template_data IS NULL)
          OR (ep.template_data->>'guestOfHonorId' IS NULL)
          OR ((ep.template_data->>'guestOfHonorId')::UUID != auth.uid())
        )
      )
    )
  )
);

-- Create RLS policy for votes to prevent guest of honor from voting
DROP POLICY IF EXISTS "Users can vote on proposals" ON proposal_votes;
DROP POLICY IF EXISTS "Users can manage their votes" ON proposal_votes;

CREATE POLICY "Users can create votes (except guests of honor)"
ON proposal_votes FOR INSERT TO authenticated
WITH CHECK (
  -- User is creating their own vote
  user_id = auth.uid()
  AND
  -- User is not the guest of honor for surprise parties
  EXISTS (
    SELECT 1
    FROM proposal_time_options pto
    JOIN event_proposals ep ON ep.id = pto.proposal_id
    WHERE pto.id = option_id
    AND (
      (ep.template_data = '{}'::jsonb OR ep.template_data IS NULL)
      OR (ep.template_data->>'guestOfHonorId' IS NULL)
      OR ((ep.template_data->>'guestOfHonorId')::UUID != auth.uid())
    )
  )
);

CREATE POLICY "Users can view and update their own votes"
ON proposal_votes FOR ALL TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

COMMENT ON POLICY "Users can view proposals in their groups (except guests of honor)" ON event_proposals IS
'Allows group members to view proposals, except guests of honor in surprise parties.';

COMMENT ON POLICY "Users can create votes (except guests of honor)" ON proposal_votes IS
'Prevents guests of honor from voting on surprise party proposals.';
