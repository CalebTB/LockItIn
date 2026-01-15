-- Create ENUM type (idempotent)
DO $$ BEGIN
  CREATE TYPE rsvp_status AS ENUM ('pending', 'accepted', 'declined', 'maybe');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Create table
CREATE TABLE IF NOT EXISTS event_invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  rsvp_status rsvp_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ,

  -- Prevent duplicate invitations
  CONSTRAINT unique_event_user UNIQUE (event_id, user_id)
);

-- Performance indexes
CREATE INDEX idx_event_invitations_event_id ON event_invitations(event_id);
CREATE INDEX idx_event_invitations_user_id ON event_invitations(user_id);

-- RLS Policies (see Critical Issue #2 for guest of honor exclusion)
ALTER TABLE event_invitations ENABLE ROW LEVEL SECURITY;

-- User can view their own invitations (except if guest of honor)
CREATE POLICY "Users can view their own invitations"
ON event_invitations FOR SELECT TO authenticated
USING (
  user_id = auth.uid()
  AND NOT EXISTS (
    SELECT 1 FROM events e
    WHERE e.id = event_invitations.event_id
    AND e.template_data->>'type' = 'surprise_party'
    AND (e.template_data->>'guestOfHonorId')::UUID = auth.uid()
  )
);

-- Event creator can view all invitations (except guest of honor cannot see their own event)
CREATE POLICY "Event creators can view invitations"
ON event_invitations FOR SELECT TO authenticated
USING (
  auth_is_event_creator(event_id)
  AND NOT EXISTS (
    SELECT 1 FROM events e
    WHERE e.id = event_invitations.event_id
    AND e.template_data->>'type' = 'surprise_party'
    AND (e.template_data->>'guestOfHonorId')::UUID = auth.uid()
  )
);

-- Event creators can create invitations
CREATE POLICY "Event creators can create invitations"
ON event_invitations FOR INSERT TO authenticated
WITH CHECK (auth_is_event_creator(event_id));

-- Users can update their own RSVP status (except guest of honor)
CREATE POLICY "Users can update their own RSVP"
ON event_invitations FOR UPDATE TO authenticated
USING (
  user_id = auth.uid()
  AND NOT EXISTS (
    SELECT 1 FROM events e
    WHERE e.id = event_invitations.event_id
    AND e.template_data->>'type' = 'surprise_party'
    AND (e.template_data->>'guestOfHonorId')::UUID = auth.uid()
  )
)
WITH CHECK (
  user_id = auth.uid()
  AND NOT EXISTS (
    SELECT 1 FROM events e
    WHERE e.id = event_invitations.event_id
    AND e.template_data->>'type' = 'surprise_party'
    AND (e.template_data->>'guestOfHonorId')::UUID = auth.uid()
  )
);

-- Event creators can delete invitations
CREATE POLICY "Event creators can delete invitations"
ON event_invitations FOR DELETE TO authenticated
USING (auth_is_event_creator(event_id));

-- Helper function for RLS (prevents N+1 query bottleneck)
CREATE OR REPLACE FUNCTION auth_is_event_creator(p_event_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM events
    WHERE id = p_event_id
    AND user_id = auth.uid()
  );
END;
$$;

COMMENT ON TABLE event_invitations IS
'Stores RSVP invitations for events. Each user can have one invitation per event.';
