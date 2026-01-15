-- Create event_invitations table for Quick Event RSVP tracking
-- This table stores invitations and RSVP status for group quick events

-- Create RSVP status enum
CREATE TYPE rsvp_status AS ENUM ('pending', 'accepted', 'declined', 'maybe');

-- Create event_invitations table
CREATE TABLE event_invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rsvp_status rsvp_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ,

  -- Ensure unique invitation per user per event
  CONSTRAINT unique_event_user UNIQUE (event_id, user_id)
);

-- Add indexes for performance
CREATE INDEX idx_event_invitations_event_id ON event_invitations(event_id);
CREATE INDEX idx_event_invitations_user_id ON event_invitations(user_id);
CREATE INDEX idx_event_invitations_rsvp_status ON event_invitations(rsvp_status);

-- Enable RLS
ALTER TABLE event_invitations ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can view invitations for events they're invited to OR events they created
CREATE POLICY "Users can view their own invitations"
ON event_invitations FOR SELECT
TO authenticated
USING (
  user_id = auth.uid()
  OR
  EXISTS (
    SELECT 1 FROM events
    WHERE events.id = event_invitations.event_id
    AND events.user_id = auth.uid()
  )
);

-- RLS Policy: Event creators can insert invitations for their events
CREATE POLICY "Event creators can create invitations"
ON event_invitations FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM events
    WHERE events.id = event_id
    AND events.user_id = auth.uid()
  )
);

-- RLS Policy: Users can update their own RSVP status
CREATE POLICY "Users can update their own RSVP"
ON event_invitations FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- RLS Policy: Event creators can delete invitations for their events
CREATE POLICY "Event creators can delete invitations"
ON event_invitations FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM events
    WHERE events.id = event_id
    AND events.user_id = auth.uid()
  )
);

-- Create function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_event_invitations_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- Create trigger for updated_at
CREATE TRIGGER set_event_invitations_updated_at
BEFORE UPDATE ON event_invitations
FOR EACH ROW
EXECUTE FUNCTION update_event_invitations_updated_at();

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON event_invitations TO authenticated;
GRANT USAGE ON TYPE rsvp_status TO authenticated;
