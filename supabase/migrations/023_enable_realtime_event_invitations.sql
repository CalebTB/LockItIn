-- Enable realtime for event_invitations table
-- This allows WebSocket subscriptions to receive RSVP updates in real-time

ALTER PUBLICATION supabase_realtime ADD TABLE event_invitations;

COMMENT ON TABLE event_invitations IS
'Event invitations with RSVP status. Realtime enabled for live RSVP updates in Party Coordinator Hub.';
