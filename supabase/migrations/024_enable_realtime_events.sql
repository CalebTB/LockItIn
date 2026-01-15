-- Migration: Enable Realtime for Events Table
-- Purpose: Allow real-time updates for template_data changes in event templates
-- Required for: Potluck template dish claim/unclaim updates
-- Sprint: 4, Week 7
-- Date: 2026-01-14
--
-- CONTEXT: Pattern 6 from flutter-supabase-critical-patterns.md
-- "Check Database Config BEFORE Writing Client Code"
-- The Surprise Party implementation revealed that template_data updates
-- don't propagate in real-time unless the events table is in the realtime publication.
--
-- NOTE: Full app restart required after this migration (not just hot reload)
-- WebSocket subscriptions need to reconnect to see new publication config.

-- Enable realtime for events table
ALTER PUBLICATION supabase_realtime ADD TABLE events;

-- Add comment for documentation
COMMENT ON TABLE events IS
'Calendar events with privacy settings, group memberships, and template data. Realtime enabled for live template_data updates (Potluck dish claims, Surprise Party tasks, etc.).';
