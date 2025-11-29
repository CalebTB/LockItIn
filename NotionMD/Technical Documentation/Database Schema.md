# Database Schema

```markdown
# 🗄️ Complete Database Schema

*PostgreSQL schema for Calendar App - copy this into Supabase SQL editor*

---

## 📋 Quick Reference

**Total Tables:** 13
**Database:** PostgreSQL 15
**Extensions Used:** uuid-ossp

**Tables by Category:**
```
Core User Data:
├── users (accounts & profiles)
├── friendships (friend connections)
└── push_tokens (notification devices)

Group Management:
├── groups (friend groups)
└── group_members (membership & roles)

Events & Calendar:
├── events (personal & group events)
└── event_attendees (RSVPs)

Proposals & Voting:
├── event_proposals (group proposals)
├── proposal_time_options (time slots)
└── proposal_votes (votes)

Privacy & Sharing:
└── calendar_sharing (visibility settings)

Communication:
└── notifications (in-app alerts)

Analytics (Optional):
└── analytics_events (usage tracking)
```

---

## 🚀 Initial Setup

**Run this first in Supabase SQL Editor:**
```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable full-text search (for future features)
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Set timezone to UTC
SET timezone = 'UTC';
```

---

## 👤 USERS TABLE

**Purpose:** User accounts and profile information
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Authentication (managed by Supabase Auth)
  email VARCHAR(255) UNIQUE NOT NULL,
  phone VARCHAR(20) UNIQUE,
  
  -- Profile
  full_name VARCHAR(255) NOT NULL,
  username VARCHAR(50) UNIQUE NOT NULL,
  avatar_url TEXT,
  
  -- Settings
  default_event_visibility VARCHAR(20) DEFAULT 'private'
    CHECK (default_event_visibility IN ('private', 'shared_with_name', 'busy_only')),
  calendar_sync_enabled BOOLEAN DEFAULT true,
  
  -- Premium
  subscription_tier VARCHAR(20) DEFAULT 'free'
    CHECK (subscription_tier IN ('free', 'premium')),
  subscription_expires_at TIMESTAMP WITH TIME ZONE,
  stripe_customer_id VARCHAR(255),
  
  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_active_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Soft delete
  deleted_at TIMESTAMP WITH TIME ZONE
);

-- Indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_deleted ON users(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_subscription ON users(subscription_tier);

-- Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own data"
  ON users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own data"
  ON users FOR UPDATE
  USING (auth.uid() = id);

-- Trigger to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

---

## 🤝 FRIENDSHIPS TABLE

**Purpose:** Bidirectional friend connections
```sql
CREATE TABLE friendships (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  friend_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  status VARCHAR(20) DEFAULT 'pending'
    CHECK (status IN ('pending', 'accepted', 'blocked')),
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  accepted_at TIMESTAMP WITH TIME ZONE,
  
  UNIQUE(user_id, friend_id),
  CHECK (user_id != friend_id)
);

-- Indexes
CREATE INDEX idx_friendships_user ON friendships(user_id);
CREATE INDEX idx_friendships_friend ON friendships(friend_id);
CREATE INDEX idx_friendships_status ON friendships(status);

-- Row Level Security
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can see own friendships"
  ON friendships FOR SELECT
  USING (auth.uid() = user_id OR auth.uid() = friend_id);

CREATE POLICY "Users can create friendships"
  ON friendships FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own friendship requests"
  ON friendships FOR UPDATE
  USING (auth.uid() = user_id OR auth.uid() = friend_id);
```

---

## 👥 GROUPS TABLE

**Purpose:** Friend groups for event coordination
```sql
CREATE TABLE groups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  name VARCHAR(255) NOT NULL,
  description TEXT,
  emoji VARCHAR(10) DEFAULT '👥',
  
  created_by UUID NOT NULL REFERENCES users(id),
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Soft delete
  deleted_at TIMESTAMP WITH TIME ZONE
);

-- Indexes
CREATE INDEX idx_groups_creator ON groups(created_by);
CREATE INDEX idx_groups_deleted ON groups(deleted_at) WHERE deleted_at IS NULL;

-- Row Level Security
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can see groups they're in"
  ON groups FOR SELECT
  USING (
    id IN (
      SELECT group_id FROM group_members
      WHERE user_id = auth.uid() AND left_at IS NULL
    )
  );

CREATE POLICY "Users can create groups"
  ON groups FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Group admins can update groups"
  ON groups FOR UPDATE
  USING (
    id IN (
      SELECT group_id FROM group_members
      WHERE user_id = auth.uid() AND role = 'admin' AND left_at IS NULL
    )
  );

-- Trigger
CREATE TRIGGER update_groups_updated_at
  BEFORE UPDATE ON groups
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

---

## 👤👥 GROUP MEMBERS TABLE

**Purpose:** Group membership and roles
```sql
CREATE TABLE group_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  role VARCHAR(20) DEFAULT 'member'
    CHECK (role IN ('admin', 'member', 'optional')),
  
  -- Privacy settings per group
  calendar_visibility VARCHAR(20) DEFAULT 'busy_only'
    CHECK (calendar_visibility IN ('private', 'shared_with_name', 'busy_only')),
  
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  left_at TIMESTAMP WITH TIME ZONE,
  
  UNIQUE(group_id, user_id)
);

-- Indexes
CREATE INDEX idx_group_members_group ON group_members(group_id);
CREATE INDEX idx_group_members_user ON group_members(user_id);
CREATE INDEX idx_group_members_active ON group_members(left_at) WHERE left_at IS NULL;

-- Row Level Security
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can see members of their groups"
  ON group_members FOR SELECT
  USING (
    group_id IN (
      SELECT group_id FROM group_members
      WHERE user_id = auth.uid() AND left_at IS NULL
    )
  );

CREATE POLICY "Group admins can manage members"
  ON group_members FOR ALL
  USING (
    group_id IN (
      SELECT group_id FROM group_members
      WHERE user_id = auth.uid() AND role = 'admin' AND left_at IS NULL
    )
  );

-- Trigger: Auto-add creator as admin
CREATE OR REPLACE FUNCTION add_creator_as_admin()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO group_members (group_id, user_id, role)
  VALUES (NEW.id, NEW.created_by, 'admin');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_group_created
  AFTER INSERT ON groups
  FOR EACH ROW
  EXECUTE FUNCTION add_creator_as_admin();
```

---

## 📅 EVENTS TABLE

**Purpose:** Personal and group events
```sql
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Event details
  title VARCHAR(255) NOT NULL,
  description TEXT,
  location TEXT,
  
  -- Timing
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE NOT NULL,
  all_day BOOLEAN DEFAULT false,
  timezone VARCHAR(50) DEFAULT 'UTC',
  
  -- Recurrence (simplified)
  recurrence_rule TEXT, -- iCal RRULE format
  recurrence_parent_id UUID REFERENCES events(id),
  
  -- Event type
  event_type VARCHAR(20) DEFAULT 'personal'
    CHECK (event_type IN ('personal', 'group_confirmed', 'group_proposal')),
  
  -- Creator & group
  created_by UUID NOT NULL REFERENCES users(id),
  group_id UUID REFERENCES groups(id),
  
  -- Privacy (for personal events)
  visibility VARCHAR(20) DEFAULT 'private'
    CHECK (visibility IN ('private', 'shared_with_name', 'busy_only')),
  
  -- Apple Calendar sync
  apple_calendar_id VARCHAR(255),
  last_synced_at TIMESTAMP WITH TIME ZONE,
  
  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE
);

-- Indexes
CREATE INDEX idx_events_creator ON events(created_by);
CREATE INDEX idx_events_group ON events(group_id);
CREATE INDEX idx_events_time ON events(start_time, end_time);
CREATE INDEX idx_events_type ON events(event_type);
CREATE INDEX idx_events_apple_id ON events(apple_calendar_id);
CREATE INDEX idx_events_deleted ON events(deleted_at) WHERE deleted_at IS NULL;

-- Row Level Security
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can see own events"
  ON events FOR SELECT
  USING (
    created_by = auth.uid() OR
    id IN (
      SELECT event_id FROM event_attendees
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create events"
  ON events FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own events"
  ON events FOR UPDATE
  USING (auth.uid() = created_by);

CREATE POLICY "Users can delete own events"
  ON events FOR DELETE
  USING (auth.uid() = created_by);

-- Trigger
CREATE TRIGGER update_events_updated_at
  BEFORE UPDATE ON events
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

---

## 🗳️ EVENT PROPOSALS TABLE

**Purpose:** Group event proposals for voting
```sql
CREATE TABLE event_proposals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Basic info
  title VARCHAR(255) NOT NULL,
  description TEXT,
  location TEXT,
  
  -- Group
  group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  created_by UUID NOT NULL REFERENCES users(id),
  
  -- Voting settings
  voting_deadline TIMESTAMP WITH TIME ZONE,
  allow_maybe BOOLEAN DEFAULT true,
  min_votes_required INT DEFAULT 1,
  
  -- Status
  status VARCHAR(20) DEFAULT 'voting'
    CHECK (status IN ('voting', 'confirmed', 'cancelled')),
  
  -- If confirmed, link to final event
  confirmed_event_id UUID REFERENCES events(id),
  confirmed_at TIMESTAMP WITH TIME ZONE,
  
  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_proposals_group ON event_proposals(group_id);
CREATE INDEX idx_proposals_creator ON event_proposals(created_by);
CREATE INDEX idx_proposals_status ON event_proposals(status);
CREATE INDEX idx_proposals_deadline ON event_proposals(voting_deadline);

-- Row Level Security
ALTER TABLE event_proposals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Group members can see proposals"
  ON event_proposals FOR SELECT
  USING (
    group_id IN (
      SELECT group_id FROM group_members
      WHERE user_id = auth.uid() AND left_at IS NULL
    )
  );

CREATE POLICY "Group members can create proposals"
  ON event_proposals FOR INSERT
  WITH CHECK (
    group_id IN (
      SELECT group_id FROM group_members
      WHERE user_id = auth.uid() AND left_at IS NULL
    )
  );

CREATE POLICY "Creators can update proposals"
  ON event_proposals FOR UPDATE
  USING (auth.uid() = created_by);

-- Trigger
CREATE TRIGGER update_proposals_updated_at
  BEFORE UPDATE ON event_proposals
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

---

## ⏰ PROPOSAL TIME OPTIONS TABLE

**Purpose:** Time slot options for proposals
```sql
CREATE TABLE proposal_time_options (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  proposal_id UUID NOT NULL REFERENCES event_proposals(id) ON DELETE CASCADE,
  
  -- Time slot
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE NOT NULL,
  
  -- Order for display
  option_order INT NOT NULL,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(proposal_id, option_order)
);

-- Indexes
CREATE INDEX idx_time_options_proposal ON proposal_time_options(proposal_id);

-- Row Level Security
ALTER TABLE proposal_time_options ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Group members can see time options"
  ON proposal_time_options FOR SELECT
  USING (
    proposal_id IN (
      SELECT id FROM event_proposals
      WHERE group_id IN (
        SELECT group_id FROM group_members
        WHERE user_id = auth.uid() AND left_at IS NULL
      )
    )
  );
```

---

## ✅ PROPOSAL VOTES TABLE

**Purpose:** User votes on time options
```sql
CREATE TABLE proposal_votes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  proposal_id UUID NOT NULL REFERENCES event_proposals(id) ON DELETE CASCADE,
  time_option_id UUID NOT NULL REFERENCES proposal_time_options(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Vote type
  response VARCHAR(20) NOT NULL
    CHECK (response IN ('available', 'maybe', 'unavailable')),
  
  -- Metadata
  voted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(proposal_id, time_option_id, user_id)
);

-- Indexes
CREATE INDEX idx_votes_proposal ON proposal_votes(proposal_id);
CREATE INDEX idx_votes_option ON proposal_votes(time_option_id);
CREATE INDEX idx_votes_user ON proposal_votes(user_id);

-- Row Level Security
ALTER TABLE proposal_votes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can see votes in their groups"
  ON proposal_votes FOR SELECT
  USING (
    proposal_id IN (
      SELECT id FROM event_proposals
      WHERE group_id IN (
        SELECT group_id FROM group_members
        WHERE user_id = auth.uid() AND left_at IS NULL
      )
    )
  );

CREATE POLICY "Users can vote in their groups"
  ON proposal_votes FOR INSERT
  WITH CHECK (
    auth.uid() = user_id AND
    proposal_id IN (
      SELECT id FROM event_proposals
      WHERE group_id IN (
        SELECT group_id FROM group_members
        WHERE user_id = auth.uid() AND left_at IS NULL
      )
    )
  );

CREATE POLICY "Users can update own votes"
  ON proposal_votes FOR UPDATE
  USING (auth.uid() = user_id);

-- Trigger
CREATE TRIGGER update_votes_updated_at
  BEFORE UPDATE ON proposal_votes
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

---
CREATE TABLE calendar_sharing (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  *-- Who can see (either user or group)*
  shared_with_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  shared_with_group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  
  *-- What they can see*
  visibility_level VARCHAR(20) DEFAULT 'busy_only'
    CHECK (visibility_level IN ('private', 'shared_with_name', 'busy_only')),
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  *-- Must share with either user OR group, not both*
  CHECK (
    (shared_with_user_id IS NOT NULL AND shared_with_group_id IS NULL) OR
    (shared_with_user_id IS NULL AND shared_with_group_id IS NOT NULL)
  )
);

*-- Indexes*
CREATE INDEX idx_sharing_user ON calendar_sharing(user_id);
CREATE INDEX idx_sharing_target_user ON calendar_sharing(shared_with_user_id);
CREATE INDEX idx_sharing_target_group ON calendar_sharing(shared_with_group_id);

*-- Row Level Security*
ALTER TABLE calendar_sharing ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own sharing settings"
  ON calendar_sharing FOR ALL
  USING (auth.uid() = user_id);

CREATE POLICY "Users can see sharing settings shared with them"
  ON calendar_sharing FOR SELECT
  USING (
    auth.uid() = shared_with_user_id OR
    shared_with_group_id IN (
      SELECT group_id FROM group_members
      WHERE user_id = auth.uid() AND left_at IS NULL
    )
  );
```

**🔔 NOTIFICATIONS TABLE**
**Purpose:** In-app notifications

```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Notification content
  type VARCHAR(50) NOT NULL,
  -- Types: 'event_proposal', 'vote_cast', 'event_confirmed', 
  --        'friend_request', 'group_invite', 'event_update'
  
  title VARCHAR(255) NOT NULL,
  body TEXT,
  
  -- Related entities (optional)
  event_id UUID REFERENCES events(id),
  proposal_id UUID REFERENCES event_proposals(id),
  group_id UUID REFERENCES groups(id),
  from_user_id UUID REFERENCES users(id),
  
  -- State
  read BOOLEAN DEFAULT false,
  read_at TIMESTAMP WITH TIME ZONE,
  
  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(read);
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);
CREATE INDEX idx_notifications_type ON notifications(type);

-- Row Level Security
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can see own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id);

-- Auto-delete old read notifications (90 days)
CREATE OR REPLACE FUNCTION delete_old_notifications()
RETURNS void AS $$
BEGIN
  DELETE FROM notifications
  WHERE read = true
  AND read_at < NOW() - INTERVAL '90 days';
END;
$$ LANGUAGE plpgsql;

-- Schedule this function to run daily (via pg_cron or external scheduler)
```

**📱 PUSH TOKENS TABLE**
**Purpose:** Device tokens for push notifications

```sql
CREATE TABLE push_tokens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  device_token VARCHAR(255) NOT NULL,
  device_type VARCHAR(20) DEFAULT 'ios'
    CHECK (device_type IN ('ios', 'android')),
  
  -- For invalidation
  active BOOLEAN DEFAULT true,
  last_used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(user_id, device_token)
);

-- Indexes
CREATE INDEX idx_push_tokens_user ON push_tokens(user_id);
CREATE INDEX idx_push_tokens_active ON push_tokens(active) WHERE active = true;

-- Row Level Security
ALTER TABLE push_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own push tokens"
  ON push_tokens FOR ALL
  USING (auth.uid() = user_id);

-- Auto-deactivate tokens not used in 90 days
CREATE OR REPLACE FUNCTION deactivate_old_tokens()
RETURNS void AS $$
BEGIN
  UPDATE push_tokens
  SET active = false
  WHERE last_used_at < NOW() - INTERVAL '90 days'
  AND active = true;
END;
$$ LANGUAGE plpgsql;
```

**📊 ANALYTICS EVENTS TABLE (Optional)**
**Purpose:** Track user actions for analytics

```sql
CREATE TABLE analytics_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  user_id UUID REFERENCES users(id),
  
  event_name VARCHAR(100) NOT NULL,
  properties JSONB,
  
  -- Session info
  session_id VARCHAR(255),
  
  -- Device info
  platform VARCHAR(50),
  app_version VARCHAR(20),
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_analytics_user ON analytics_events(user_id);
CREATE INDEX idx_analytics_name ON analytics_events(event_name);
CREATE INDEX idx_analytics_created ON analytics_events(created_at DESC);
CREATE INDEX idx_analytics_properties ON analytics_events USING gin(properties);

-- Partition by month for performance (optional, for later)
-- CREATE TABLE analytics_events_2024_12 PARTITION OF analytics_events
--   FOR VALUES FROM ('2024-12-01') TO ('2025-01-01');

-- Row Level Security (optional - might want admin-only access)
ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can create analytics events"
  ON analytics_events FOR INSERT
  WITH CHECK (true); -- Anyone can log events

-- Auto-delete old analytics (180 days)
CREATE OR REPLACE FUNCTION delete_old_analytics()
RETURNS void AS $$
BEGIN
  DELETE FROM analytics_events
  WHERE created_at < NOW() - INTERVAL '180 days';
END;
$$ LANGUAGE plpgsql;
```

**🔄 DATABASE TRIGGERS & FUNCTIONS**

**Trigger: Notify Group Members on Proposal Creation**

```sql
CREATE OR REPLACE FUNCTION notify_proposal_created()
RETURNS TRIGGER AS $$
BEGIN
  -- Create notifications for all group members
  INSERT INTO notifications (user_id, type, title, body, proposal_id, from_user_id)
  SELECT 
    gm.user_id,
    'event_proposal',
    'New event proposal',
    NEW.title,
    NEW.id,
    NEW.created_by
  FROM group_members gm
  WHERE gm.group_id = NEW.group_id
    AND gm.left_at IS NULL
    AND gm.user_id != NEW.created_by; -- Don't notify creator
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_proposal_created
  AFTER INSERT ON event_proposals
  FOR EACH ROW
  EXECUTE FUNCTION notify_proposal_created();
```

Trigger: Auto-Confirm Proposal When Voting Closes

```sql
CREATE OR REPLACE FUNCTION check_proposal_completion()
RETURNS TRIGGER AS $$
DECLARE
  total_members INT;
  total_votes INT;
  winning_option_id UUID;
  winning_vote_count INT;
BEGIN
  -- Only check if proposal is still in voting status
  IF NEW.status != 'voting' THEN
    RETURN NEW;
  END IF;
  
  -- Get total group members
  SELECT COUNT(*) INTO total_members
  FROM group_members
  WHERE group_id = NEW.group_id AND left_at IS NULL;
  
  -- Get total votes for this proposal
  SELECT COUNT(DISTINCT user_id) INTO total_votes
  FROM proposal_votes
  WHERE proposal_id = NEW.id;
  
  -- If everyone has voted OR deadline passed
  IF total_votes >= total_members OR NEW.voting_deadline < NOW() THEN
    -- Find winning option (most "available" votes)
    SELECT pto.id, COUNT(*) INTO winning_option_id, winning_vote_count
    FROM proposal_time_options pto
    JOIN proposal_votes pv ON pv.time_option_id = pto.id
    WHERE pto.proposal_id = NEW.id
      AND pv.response = 'available'
    GROUP BY pto.id
    ORDER BY COUNT(*) DESC, pto.option_order ASC
    LIMIT 1;
    
    -- If we have a winner with at least min required votes
    IF winning_vote_count >= NEW.min_votes_required THEN
      -- Create the event (handled by Edge Function in production)
      -- For now, just update status
      UPDATE event_proposals
      SET 
        status = 'confirmed',
        confirmed_at = NOW()
      WHERE id = NEW.id;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_proposal_after_vote
  AFTER INSERT OR UPDATE ON proposal_votes
  FOR EACH ROW
  EXECUTE FUNCTION check_proposal_completion();
```

Trigger: Update Last Active Timestamp

```sql
CREATE OR REPLACE FUNCTION update_last_active()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE users
  SET last_active_at = NOW()
  WHERE id = auth.uid();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to key activity tables
CREATE TRIGGER update_last_active_on_event
  AFTER INSERT ON events
  FOR EACH ROW
  EXECUTE FUNCTION update_last_active();

CREATE TRIGGER update_last_active_on_proposal
  AFTER INSERT ON event_proposals
  FOR EACH ROW
  EXECUTE FUNCTION update_last_active();

CREATE TRIGGER update_last_active_on_vote
  AFTER INSERT ON proposal_votes
  FOR EACH ROW
  EXECUTE FUNCTION update_last_active();
```

**📊 USEFUL VIEWS**

**View: Active Groups with Member Count**

```sql
CREATE VIEW active_groups_with_counts AS
SELECT 
  g.*,
  COUNT(gm.user_id) as member_count,
  COUNT(CASE WHEN gm.role = 'admin' THEN 1 END) as admin_count
FROM groups g
LEFT JOIN group_members gm ON g.id = gm.group_id AND gm.left_at IS NULL
WHERE g.deleted_at IS NULL
GROUP BY g.id;
```

View: Proposal Voting Summary

```sql
CREATE VIEW proposal_voting_summary AS
SELECT 
  p.id as proposal_id,
  p.title,
  p.status,
  pto.id as option_id,
  pto.start_time,
  pto.end_time,
  COUNT(CASE WHEN pv.response = 'available' THEN 1 END) as available_count,
  COUNT(CASE WHEN pv.response = 'maybe' THEN 1 END) as maybe_count,
  COUNT(CASE WHEN pv.response = 'unavailable' THEN 1 END) as unavailable_count,
  COUNT(DISTINCT pv.user_id) as total_votes
FROM event_proposals p
JOIN proposal_time_options pto ON pto.proposal_id = p.id
LEFT JOIN proposal_votes pv ON pv.time_option_id = pto.id
GROUP BY p.id, p.title, p.status, pto.id, pto.start_time, pto.end_time, pto.option_order
ORDER BY p.created_at DESC, pto.option_order ASC;
```

View: User's Upcoming Events

```sql
CREATE VIEW upcoming_events AS
SELECT 
  e.*,
  CASE 
    WHEN e.event_type = 'group_confirmed' THEN g.name
    ELSE NULL
  END as group_name,
  ea.rsvp_status
FROM events e
LEFT JOIN groups g ON e.group_id = g.id
LEFT JOIN event_attendees ea ON ea.event_id = e.id AND ea.user_id = auth.uid()
WHERE e.deleted_at IS NULL
  AND e.start_time >= NOW()
  AND (
    e.created_by = auth.uid() OR
    ea.user_id = auth.uid()
  )
ORDER BY e.start_time ASC;
```

🧪 SAMPLE DATA (For Development/Testing)

```sql
-- Create test users (only works if you're using Supabase Auth)
-- Run this after creating users via Supabase Auth UI

-- Insert sample groups
INSERT INTO groups (id, name, emoji, created_by) VALUES
  ('11111111-1111-1111-1111-111111111111', 'College Friends', '🎓', auth.uid()),
  ('22222222-2222-2222-2222-222222222222', 'Roommates', '🏠', auth.uid()),
  ('33333333-3333-3333-3333-333333333333', 'Basketball Crew', '🏀', auth.uid());

-- Insert sample events
INSERT INTO events (title, start_time, end_time, created_by) VALUES
  (
    'Team Meeting',
    NOW() + INTERVAL '2 days',
    NOW() + INTERVAL '2 days' + INTERVAL '1 hour',
    auth.uid()
  ),
  (
    'Lunch with Sarah',
    NOW() + INTERVAL '1 day' + INTERVAL '5 hours',
    NOW() + INTERVAL '1 day' + INTERVAL '6 hours',
    auth.uid()
  );

-- Insert sample proposal
INSERT INTO event_proposals (id, title, group_id, created_by, voting_deadline) VALUES
  (
    '44444444-4444-4444-4444-444444444444',
    'Secret Santa Planning',
    '11111111-1111-1111-1111-111111111111',
    auth.uid(),
    NOW() + INTERVAL '7 days'
  );

-- Insert time options for proposal
INSERT INTO proposal_time_options (proposal_id, start_time, end_time, option_order) VALUES
  (
    '44444444-4444-4444-4444-444444444444',
    NOW() + INTERVAL '14 days' + INTERVAL '18 hours',
    NOW() + INTERVAL '14 days' + INTERVAL '20 hours',
    0
  ),
  (
    '44444444-4444-4444-4444-444444444444',
    NOW() + INTERVAL '15 days' + INTERVAL '14 hours',
    NOW() + INTERVAL '15 days' + INTERVAL '16 hours',
    1
  ),
  (
    '44444444-4444-4444-4444-444444444444',
    NOW() + INTERVAL '16 days' + INTERVAL '19 hours',
    NOW() + INTERVAL '16 days' + INTERVAL '21 hours',
    2
  );
```

**🔍 USEFUL QUERIES FOR DEBUGGING**

**Check User's Groups**

```sql
SELECT 
  g.name,
  g.emoji,
  gm.role,
  gm.joined_at,
  (SELECT COUNT(*) FROM group_members WHERE group_id = g.id AND left_at IS NULL) as member_count
FROM groups g
JOIN group_members gm ON g.id = gm.group_id
WHERE gm.user_id = auth.uid()
  AND gm.left_at IS NULL
  AND g.deleted_at IS NULL
ORDER BY gm.joined_at DESC;
```

Check Pending Proposals

```sql
SELECT 
  p.title,
  g.name as group_name,
  p.voting_deadline,
  (SELECT COUNT(DISTINCT user_id) FROM proposal_votes WHERE proposal_id = p.id) as votes_received,
  (SELECT COUNT(*) FROM group_members WHERE group_id = p.group_id AND left_at IS NULL) as total_members
FROM event_proposals p
JOIN groups g ON p.group_id = g.id
WHERE p.status = 'voting'
  AND p.group_id IN (
    SELECT group_id FROM group_members
    WHERE user_id = auth.uid() AND left_at IS NULL
  )
ORDER BY p.voting_deadline ASC;
```

Check Database Size

```sql
SELECT 
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

## 🚀 PERFORMANCE OPTIMIZATION

### **Add Composite Indexes for Common Queries**

```sql
-- Fast lookup of user's upcoming events
CREATE INDEX idx_events_user_upcoming 
  ON events(created_by, start_time) 
  WHERE deleted_at IS NULL AND start_time >= NOW();

-- Fast lookup of active proposals in a group
CREATE INDEX idx_proposals_group_active
  ON event_proposals(group_id, status, voting_deadline)
  WHERE status = 'voting';

-- Fast lookup of unread notifications
CREATE INDEX idx_notifications_user_unread
  ON notifications(user_id, created_at DESC)
  WHERE read = false;

-- Fast vote counting
CREATE INDEX idx_votes_option_response
  ON proposal_votes(time_option_id, response);
```

Enable Query Plan Caching

```sql
-- Analyze tables for better query planning
ANALYZE users;
ANALYZE events;
ANALYZE event_proposals;
ANALYZE proposal_votes;
ANALYZE groups;
ANALYZE group_members;
```

## 📝 MIGRATION STRATEGY

**For future schema changes:**

```sql
-- Example migration: Add new column
-- migrations/001_add_user_bio.sql

BEGIN;

ALTER TABLE users 
  ADD COLUMN bio TEXT;

COMMENT ON COLUMN users.bio IS 'User biography (added 2024-12-01)';

COMMIT;
```

Track migrations:

```sql
CREATE TABLE schema_migrations (
  version INTEGER PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

INSERT INTO schema_migrations (version, name) VALUES
  (1, 'initial_schema'),
  (2, 'add_user_bio');
```

---

## ✅ POST-SETUP CHECKLIST

After running all the SQL above:
```
□ All tables created (13 total)
□ All indexes created
□ All triggers created
□ All Row Level Security policies enabled
□ Views created
□ Sample data inserted (for testing)
□ Analyzed all tables
□ No errors in Supabase SQL editor
```

Test the setup:

```sql
-- Should return your user
SELECT * FROM users WHERE id = auth.uid();

-- Should return empty (you have no groups yet)
SELECT * FROM active_groups_with_counts;

-- Should work without errors
INSERT INTO events (title, start_time, end_time, created_by)
VALUES ('Test Event', NOW() + INTERVAL '1 day', NOW() + INTERVAL '1 day' + INTERVAL '1 hour', auth.uid());
```

---

*Last updated: November 28, 2024*
```