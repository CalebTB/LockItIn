-- Migration: Allow group members to view each other's non-private events
--
-- This enables the group availability heatmap to work correctly.
-- Group members can see events with visibility 'sharedWithName' or 'busyOnly'
-- from other members of groups they belong to.

-- Drop existing select policy if it only allows own events
DROP POLICY IF EXISTS "Users can view own events" ON events;
DROP POLICY IF EXISTS "Group members can view shared events" ON events;

-- Create comprehensive select policy for events
CREATE POLICY "Users can view own and group members events" ON events
FOR SELECT TO authenticated
USING (
  -- Can always see own events
  user_id = auth.uid()
  OR
  -- Can see non-private events from group members
  (
    visibility != 'private'
    AND EXISTS (
      SELECT 1 FROM group_members gm1
      JOIN group_members gm2 ON gm1.group_id = gm2.group_id
      WHERE gm1.user_id = auth.uid()
      AND gm2.user_id = events.user_id
    )
  )
);

-- Add comment
COMMENT ON POLICY "Users can view own and group members events" ON events IS
'Allows users to see their own events, plus non-private events from members of shared groups';
