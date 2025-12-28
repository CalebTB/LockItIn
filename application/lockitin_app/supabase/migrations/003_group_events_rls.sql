-- Migration: Allow group members to view each other's non-private events
--
-- This enables the group availability heatmap to work correctly.
-- Group members can see events with visibility 'sharedWithName' or 'busyOnly'
-- from other members of groups they belong to.

-- Drop existing select policy if it only allows own events
DROP POLICY IF EXISTS "Users can view own events" ON events;
DROP POLICY IF EXISTS "Group members can view shared events" ON events;

-- Create comprehensive select policy for events
-- Note: This correctly enforces DIRECT group membership only.
-- User A can only see User B's events if A and B share at least one group.
-- There is NO transitive visibility (sharing a group with someone who shares
-- a different group with the event owner does NOT grant access).
CREATE POLICY "Users can view own and group members events" ON events
FOR SELECT TO authenticated
USING (
  -- Can always see own events
  user_id = auth.uid()
  OR
  -- Can see non-private events from DIRECT group members only
  (
    visibility != 'private'
    AND user_id != auth.uid()  -- Explicitly exclude self (optimization)
    AND EXISTS (
      -- Find at least one group where BOTH users are members
      SELECT 1 FROM group_members gm1
      INNER JOIN group_members gm2
        ON gm1.group_id = gm2.group_id  -- Same group
        AND gm1.user_id != gm2.user_id  -- Different users
      WHERE gm1.user_id = auth.uid()    -- Current user is member
        AND gm2.user_id = events.user_id -- Event owner is member of SAME group
    )
  )
);

-- Add comment
COMMENT ON POLICY "Users can view own and group members events" ON events IS
'Allows users to see their own events, plus non-private events from members of shared groups';
