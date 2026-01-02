-- Migration 013: Create Notifications System Tables
-- Issue #158: Create database infrastructure for in-app notifications
--
-- This migration creates:
-- 1. notifications table - In-app notification queue
-- 2. RLS policies for user access
-- 3. Indexes for performance
-- 4. RPC functions for notification management

-- ============================================================================
-- NOTIFICATION TYPE ENUM
-- ============================================================================

DO $$ BEGIN
  CREATE TYPE notification_type AS ENUM (
    -- Proposal notifications
    'proposal_created',
    'proposal_vote_cast',
    'proposal_confirmed',
    'proposal_cancelled',
    'proposal_expired',
    'voting_reminder',

    -- Group notifications
    'group_invite',
    'group_invite_accepted',
    'member_joined',
    'member_left',
    'member_removed',
    'role_changed',

    -- Friend notifications
    'friend_request',
    'friend_accepted',

    -- Event notifications
    'event_created',
    'event_updated',
    'event_cancelled',
    'event_reminder',

    -- System notifications
    'system_announcement'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================================
-- NOTIFICATIONS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Recipient
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Notification content
  type notification_type NOT NULL,
  title TEXT NOT NULL,
  body TEXT,

  -- Related entities (for deep linking)
  data JSONB DEFAULT '{}',
  -- Example data:
  -- { "proposal_id": "...", "group_id": "...", "time_option_id": "..." }
  -- { "group_id": "...", "inviter_id": "..." }
  -- { "friend_id": "...", "request_id": "..." }

  -- Read tracking
  read_at TIMESTAMPTZ,

  -- Action tracking
  actioned_at TIMESTAMPTZ, -- When user clicked/acted on notification
  dismissed_at TIMESTAMPTZ, -- When user dismissed notification

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),

  -- Expiry (for time-sensitive notifications)
  expires_at TIMESTAMPTZ
);

COMMENT ON TABLE notifications IS 'In-app notification queue for users';
COMMENT ON COLUMN notifications.data IS 'JSON data for deep linking (proposal_id, group_id, etc.)';
COMMENT ON COLUMN notifications.read_at IS 'When user viewed the notification';
COMMENT ON COLUMN notifications.actioned_at IS 'When user took action on the notification';
COMMENT ON COLUMN notifications.expires_at IS 'When notification becomes invalid (for voting reminders, etc.)';

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_created ON notifications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON notifications(user_id, read_at)
  WHERE read_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_expires ON notifications(expires_at)
  WHERE expires_at IS NOT NULL;

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Users can only see their own notifications
CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- System can insert notifications (via trigger/RPC)
-- Note: INSERT is handled by trigger functions, not direct user access
CREATE POLICY "System can create notifications"
  ON notifications FOR INSERT TO authenticated
  WITH CHECK (false); -- Disabled for direct inserts, use RPC functions

-- Users can mark their notifications as read/dismissed
CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- Users can delete their own notifications
CREATE POLICY "Users can delete own notifications"
  ON notifications FOR DELETE TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- ============================================================================
-- RPC FUNCTIONS
-- ============================================================================

-- Create a notification (for use by triggers and backend)
CREATE OR REPLACE FUNCTION create_notification(
  p_user_id UUID,
  p_type notification_type,
  p_title TEXT,
  p_body TEXT DEFAULT NULL,
  p_data JSONB DEFAULT '{}',
  p_expires_at TIMESTAMPTZ DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_notification_id UUID;
BEGIN
  INSERT INTO notifications (user_id, type, title, body, data, expires_at)
  VALUES (p_user_id, p_type, p_title, p_body, p_data, p_expires_at)
  RETURNING id INTO v_notification_id;

  RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Get user's notifications with pagination
CREATE OR REPLACE FUNCTION get_user_notifications(
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0,
  p_unread_only BOOLEAN DEFAULT false
)
RETURNS TABLE (
  id UUID,
  type notification_type,
  title TEXT,
  body TEXT,
  data JSONB,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ,
  is_expired BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    n.id,
    n.type,
    n.title,
    n.body,
    n.data,
    n.read_at,
    n.created_at,
    (n.expires_at IS NOT NULL AND n.expires_at < now()) AS is_expired
  FROM notifications n
  WHERE n.user_id = auth.uid()
    AND (NOT p_unread_only OR n.read_at IS NULL)
    AND (n.expires_at IS NULL OR n.expires_at > now())
    AND n.dismissed_at IS NULL
  ORDER BY n.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Get unread notification count
CREATE OR REPLACE FUNCTION get_unread_notification_count()
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)::INTEGER
    FROM notifications
    WHERE user_id = auth.uid()
      AND read_at IS NULL
      AND dismissed_at IS NULL
      AND (expires_at IS NULL OR expires_at > now())
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Mark notification as read
CREATE OR REPLACE FUNCTION mark_notification_read(p_notification_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE notifications
  SET read_at = now()
  WHERE id = p_notification_id
    AND user_id = auth.uid()
    AND read_at IS NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Mark all notifications as read
CREATE OR REPLACE FUNCTION mark_all_notifications_read()
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER;
BEGIN
  WITH updated AS (
    UPDATE notifications
    SET read_at = now()
    WHERE user_id = auth.uid()
      AND read_at IS NULL
    RETURNING id
  )
  SELECT COUNT(*) INTO v_count FROM updated;

  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Dismiss a notification
CREATE OR REPLACE FUNCTION dismiss_notification(p_notification_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE notifications
  SET dismissed_at = now()
  WHERE id = p_notification_id
    AND user_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Delete old notifications (cleanup function)
CREATE OR REPLACE FUNCTION cleanup_old_notifications(p_days_old INTEGER DEFAULT 30)
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER;
BEGIN
  WITH deleted AS (
    DELETE FROM notifications
    WHERE created_at < now() - (p_days_old || ' days')::INTERVAL
      AND (read_at IS NOT NULL OR dismissed_at IS NOT NULL)
    RETURNING id
  )
  SELECT COUNT(*) INTO v_count FROM deleted;

  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- TRIGGER: Notify on proposal creation
-- ============================================================================

CREATE OR REPLACE FUNCTION notify_on_proposal_created()
RETURNS TRIGGER AS $$
DECLARE
  v_group_name TEXT;
  v_member RECORD;
BEGIN
  -- Get group name
  SELECT name INTO v_group_name FROM groups WHERE id = NEW.group_id;

  -- Notify all group members except the creator
  FOR v_member IN
    SELECT gm.user_id
    FROM group_members gm
    WHERE gm.group_id = NEW.group_id
      AND gm.user_id != NEW.created_by
  LOOP
    PERFORM create_notification(
      v_member.user_id,
      'proposal_created',
      'New Event Proposal',
      'New proposal "' || NEW.title || '" in ' || v_group_name,
      jsonb_build_object(
        'proposal_id', NEW.id,
        'group_id', NEW.group_id,
        'created_by', NEW.created_by
      ),
      NEW.voting_deadline -- Expires when voting ends
    );
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER trigger_notify_on_proposal_created
  AFTER INSERT ON event_proposals
  FOR EACH ROW
  EXECUTE FUNCTION notify_on_proposal_created();

-- ============================================================================
-- TRIGGER: Notify on proposal status change
-- ============================================================================

CREATE OR REPLACE FUNCTION notify_on_proposal_status_change()
RETURNS TRIGGER AS $$
DECLARE
  v_group_name TEXT;
  v_member RECORD;
  v_notification_type notification_type;
  v_title TEXT;
  v_body TEXT;
BEGIN
  -- Only trigger on status change
  IF OLD.status = NEW.status THEN
    RETURN NEW;
  END IF;

  -- Get group name
  SELECT name INTO v_group_name FROM groups WHERE id = NEW.group_id;

  -- Determine notification type and content
  CASE NEW.status
    WHEN 'confirmed' THEN
      v_notification_type := 'proposal_confirmed';
      v_title := 'Event Confirmed!';
      v_body := '"' || NEW.title || '" has been confirmed in ' || v_group_name;
    WHEN 'cancelled' THEN
      v_notification_type := 'proposal_cancelled';
      v_title := 'Proposal Cancelled';
      v_body := '"' || NEW.title || '" in ' || v_group_name || ' was cancelled';
    WHEN 'expired' THEN
      v_notification_type := 'proposal_expired';
      v_title := 'Voting Ended';
      v_body := 'Voting has ended for "' || NEW.title || '" in ' || v_group_name;
    ELSE
      RETURN NEW; -- No notification for other status changes
  END CASE;

  -- Notify all group members
  FOR v_member IN
    SELECT gm.user_id
    FROM group_members gm
    WHERE gm.group_id = NEW.group_id
  LOOP
    PERFORM create_notification(
      v_member.user_id,
      v_notification_type,
      v_title,
      v_body,
      jsonb_build_object(
        'proposal_id', NEW.id,
        'group_id', NEW.group_id,
        'status', NEW.status
      )
    );
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER trigger_notify_on_proposal_status_change
  AFTER UPDATE ON event_proposals
  FOR EACH ROW
  EXECUTE FUNCTION notify_on_proposal_status_change();

-- ============================================================================
-- TRIGGER: Notify on group invite
-- ============================================================================

CREATE OR REPLACE FUNCTION notify_on_group_invite()
RETURNS TRIGGER AS $$
DECLARE
  v_group_name TEXT;
  v_inviter_name TEXT;
BEGIN
  -- Get group name and inviter name
  SELECT name INTO v_group_name FROM groups WHERE id = NEW.group_id;
  SELECT full_name INTO v_inviter_name FROM users WHERE id = NEW.invited_by;

  PERFORM create_notification(
    NEW.invited_user_id,
    'group_invite',
    'Group Invitation',
    COALESCE(v_inviter_name, 'Someone') || ' invited you to join "' || v_group_name || '"',
    jsonb_build_object(
      'group_id', NEW.group_id,
      'invite_id', NEW.id,
      'invited_by', NEW.invited_by
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER trigger_notify_on_group_invite
  AFTER INSERT ON group_invites
  FOR EACH ROW
  EXECUTE FUNCTION notify_on_group_invite();

-- ============================================================================
-- TRIGGER: Notify on friend request
-- ============================================================================

CREATE OR REPLACE FUNCTION notify_on_friend_request()
RETURNS TRIGGER AS $$
DECLARE
  v_sender_name TEXT;
BEGIN
  -- Only notify on new pending requests
  IF NEW.status != 'pending' THEN
    RETURN NEW;
  END IF;

  -- Get sender name
  SELECT full_name INTO v_sender_name FROM users WHERE id = NEW.user_id;

  PERFORM create_notification(
    NEW.friend_id,
    'friend_request',
    'Friend Request',
    COALESCE(v_sender_name, 'Someone') || ' sent you a friend request',
    jsonb_build_object(
      'friendship_id', NEW.id,
      'sender_id', NEW.user_id
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER trigger_notify_on_friend_request
  AFTER INSERT ON friendships
  FOR EACH ROW
  EXECUTE FUNCTION notify_on_friend_request();

-- ============================================================================
-- REALTIME CONFIGURATION
-- ============================================================================

-- Enable realtime for notifications
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

GRANT USAGE ON TYPE notification_type TO authenticated;

GRANT SELECT, UPDATE, DELETE ON notifications TO authenticated;
-- Note: INSERT is handled by trigger functions

GRANT EXECUTE ON FUNCTION create_notification TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_notifications TO authenticated;
GRANT EXECUTE ON FUNCTION get_unread_notification_count TO authenticated;
GRANT EXECUTE ON FUNCTION mark_notification_read TO authenticated;
GRANT EXECUTE ON FUNCTION mark_all_notifications_read TO authenticated;
GRANT EXECUTE ON FUNCTION dismiss_notification TO authenticated;
GRANT EXECUTE ON FUNCTION cleanup_old_notifications TO authenticated;
