-- Allow surprise party coordinators to view all invitations for their event
-- This fixes the issue where coordinators could only see their own invitation

CREATE POLICY "Surprise party coordinators can view all invitations"
ON event_invitations FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM events e
    WHERE e.id = event_invitations.event_id
    AND e.template_data->>'type' = 'surprise_party'
    AND auth.uid()::text = ANY(
      -- Extract inOnItUserIds array from JSONB (handles both snake_case and camelCase)
      SELECT jsonb_array_elements_text(
        COALESCE(
          e.template_data->'in_on_it_user_ids',
          e.template_data->'inOnItUserIds'
        )
      )
    )
  )
);

COMMENT ON POLICY "Surprise party coordinators can view all invitations"
ON event_invitations IS
'Allows users in the in_on_it_user_ids array to view all invitations for a surprise party event. This enables the Party Coordinator Hub to display the full RSVP list.';
