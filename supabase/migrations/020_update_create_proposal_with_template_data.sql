-- Update create_proposal_with_options RPC function to support template_data
-- This enables Surprise Party and other templates for proposals

DROP FUNCTION IF EXISTS create_proposal_with_options(UUID, TEXT, TEXT, TEXT, TIMESTAMPTZ, JSONB);

CREATE OR REPLACE FUNCTION create_proposal_with_options(
  p_group_id UUID,
  p_title TEXT,
  p_description TEXT,
  p_location TEXT,
  p_voting_deadline TIMESTAMPTZ,
  p_time_options JSONB,
  p_template_data JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_proposal_id UUID;
  v_time_option JSONB;
BEGIN
  -- Verify caller is a member of the group
  IF NOT EXISTS (
    SELECT 1 FROM group_members
    WHERE group_id = p_group_id
    AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Access denied: You must be a member of this group';
  END IF;

  -- Create the proposal
  INSERT INTO event_proposals (
    group_id,
    title,
    description,
    location,
    voting_deadline,
    created_by,
    template_data
  ) VALUES (
    p_group_id,
    p_title,
    p_description,
    p_location,
    p_voting_deadline,
    auth.uid(),
    p_template_data
  )
  RETURNING id INTO v_proposal_id;

  -- Insert time options
  FOR v_time_option IN SELECT * FROM jsonb_array_elements(p_time_options)
  LOOP
    INSERT INTO proposal_time_options (
      proposal_id,
      start_time,
      end_time
    ) VALUES (
      v_proposal_id,
      (v_time_option->>'start_time')::timestamptz,
      (v_time_option->>'end_time')::timestamptz
    );
  END LOOP;

  RETURN v_proposal_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION create_proposal_with_options(UUID, TEXT, TEXT, TEXT, TIMESTAMPTZ, JSONB, JSONB) TO authenticated;

COMMENT ON FUNCTION create_proposal_with_options IS
'Create a proposal with time options and optional template data in a single transaction.
Template data is transferred to the final event after voting completes.';
