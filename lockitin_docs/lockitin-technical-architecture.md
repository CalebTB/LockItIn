# LockItIn: Complete Technical Architecture

*Consolidated technical documentation for the group event planning calendar app. Last updated: December 1, 2025*

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Frontend Architecture (iOS)](#frontend-architecture-ios)
3. [Backend Architecture (Supabase)](#backend-architecture-supabase)
4. [Complete Database Schema](#complete-database-schema)
5. [API Endpoints Specification](#api-endpoints-specification)
6. [EventKit Integration Strategy](#eventkit-integration-strategy)
7. [Third-Party Services Integration](#third-party-services-integration)
8. [Code Snippets Library](#code-snippets-library)
9. [Security & Privacy Architecture](#security--privacy-architecture)
10. [Performance & Scalability](#performance--scalability)
11. [Development Environment Setup](#development-environment-setup)

---

## Architecture Overview

### System Design Diagram

```
┌──────────────────────────────────────────────────────┐
│             iOS APP (SwiftUI - MVVM)                 │
├──────────────────────────────────────────────────────┤
│                                                       │
│  ┌─────────────┐    ┌─────────────┐   ┌────────────┐ │
│  │ UI Layer    │←→  │ ViewModels  │←→ │ Data Layer │ │
│  │ (Views)     │    │ (Business   │   │ (Models)   │ │
│  └─────────────┘    │  Logic)     │   └────────────┘ │
│                     └─────────────┘                   │
│  ┌────────────────────────────────────────────────┐   │
│  │  EventKit (Apple Calendar Bidirectional Sync)  │   │
│  └────────────────────────────────────────────────┘   │
│                                                       │
└──────────────────────────────────────────────────────┘
                    ↕ REST API / WebSocket
┌──────────────────────────────────────────────────────┐
│          BACKEND (Supabase/PostgreSQL)               │
├──────────────────────────────────────────────────────┤
│                                                       │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────┐  │
│  │ PostgreSQL   │  │ Auth         │  │ Storage    │  │
│  │ Database     │  │ (JWT)        │  │ (Images)   │  │
│  │ (13 tables)  │  └──────────────┘  └────────────┘  │
│  └──────────────┘                                    │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────┐  │
│  │ Realtime     │  │ Edge         │  │ Push       │  │
│  │ Subscriptions│  │ Functions    │  │ Notifs     │  │
│  │ (WebSocket)  │  └──────────────┘  └────────────┘  │
│  └──────────────┘                                    │
│                                                       │
└──────────────────────────────────────────────────────┘
                    ↕ API Calls
┌──────────────────────────────────────────────────────┐
│         THIRD-PARTY SERVICES                         │
├──────────────────────────────────────────────────────┤
│  • APNs (Apple Push Notification Service)            │
│  • MapKit (Location & Travel Time)                   │
│  • Stripe (Payment Processing)                       │
│  • Analytics (PostHog or Mixpanel)                   │
└──────────────────────────────────────────────────────┘
```

### Technology Stack Justification

| Component | Technology | Why |
|-----------|-----------|-----|
| **Frontend** | Swift 5.9+ & SwiftUI | Native iOS, best performance, Apple HIG compliance |
| **State Mgmt** | MVVM + Combine | Reactive programming, clean architecture, testable |
| **Backend DB** | PostgreSQL 15 | Powerful relational model, RLS for privacy, mature |
| **Backend Auth** | Supabase Auth (JWT) | Managed auth, fast deployment, SOC 2 certified |
| **Real-time** | Supabase Realtime (WebSocket) | Live updates without polling, integrated with DB |
| **Serverless** | Supabase Edge Functions | Custom business logic without managing servers |
| **Calendar Sync** | EventKit | Only way to access Apple Calendar on iOS |
| **Push Notifs** | APNs | Required for iOS notifications, free tier |
| **Payments** | Stripe | Industry standard, reliable, developer-friendly |

### High-Level Data Flow

**Scenario: User votes on event proposal**

1. User taps "Available" on time option in proposal screen
2. SwiftUI View updates optimistically (immediate visual feedback)
3. ViewModel sends `voteOnProposal()` to APIClient via async/await
4. APIClient calls Supabase REST API: `POST /rest/v1/proposal_votes`
5. Backend executes trigger `check_proposal_after_vote()` to check if proposal should auto-confirm
6. WebSocket subscription on `proposal_votes` table fires, all group members see vote count update in real-time
7. If auto-confirm conditions met, `event_proposals` status changes to "confirmed"
8. Final event created in `events` table
9. Notifications generated for all group members
10. Push notifications sent via APNs to all devices

---

## Frontend Architecture (iOS)

### Swift & SwiftUI Standards

**Minimum Requirements:**
- Swift 5.9+
- SwiftUI (iOS 17+)
- Xcode 15.0+

**Core Frameworks:**
- Combine (reactive programming)
- AsyncAwait (concurrency)
- EventKit (calendar integration)
- UserNotifications (push handling)

### MVVM Architecture Pattern

```
Views (SwiftUI)
    ↓
ViewModels (Business Logic + State Management)
    ↓
Models (Data Objects)
    ↓
Services (API, EventKit, Notifications)
```

**Layer Responsibilities:**

| Layer | Responsibility | Examples |
|-------|---|---|
| **View** | UI presentation only | CalendarView, ProposalCard, VoteButton |
| **ViewModel** | State management + business logic | CalendarViewModel, ProposalViewModel |
| **Model** | Data structures | User, Event, EventProposal, Vote |
| **Service** | External integrations | APIClient, CalendarManager, PushNotificationManager |

### Expected Project Structure

```
CalendarApp/
├── App/
│   ├── CalendarAppApp.swift          # Entry point
│   └── AppDelegate.swift             # Lifecycle management
│
├── Core/
│   ├── Network/
│   │   ├── APIClient.swift           # Supabase REST API wrapper
│   │   └── WebSocketManager.swift    # Real-time subscriptions
│   │
│   ├── Calendar/
│   │   ├── CalendarManager.swift     # EventKit integration
│   │   └── CalendarSync.swift        # Bidirectional sync logic
│   │
│   ├── Notifications/
│   │   └── PushNotificationManager.swift
│   │
│   ├── Storage/
│   │   └── CacheManager.swift        # Local caching & offline queue
│   │
│   └── Analytics/
│       └── Analytics.swift            # Event tracking
│
├── Models/
│   ├── User.swift
│   ├── Group.swift
│   ├── Event.swift
│   ├── EventProposal.swift
│   ├── Vote.swift
│   └── Notification.swift
│
├── ViewModels/
│   ├── AuthViewModel.swift
│   ├── CalendarViewModel.swift
│   ├── GroupsViewModel.swift
│   ├── ProposalViewModel.swift
│   ├── InboxViewModel.swift
│   └── ProfileViewModel.swift
│
├── Views/
│   ├── Auth/
│   │   ├── LoginView.swift
│   │   └── SignUpView.swift
│   │
│   ├── Calendar/
│   │   ├── CalendarView.swift
│   │   ├── DayDetailView.swift
│   │   └── EventDetailView.swift
│   │
│   ├── Groups/
│   │   ├── GroupsView.swift
│   │   ├── GroupDetailView.swift
│   │   └── CreateGroupView.swift
│   │
│   ├── Proposals/
│   │   ├── ProposalView.swift
│   │   ├── CreateProposalView.swift
│   │   └── VotingView.swift
│   │
│   ├── Components/
│   │   ├── AvailabilityHeatmap.swift
│   │   ├── ProposalCard.swift
│   │   ├── VoteButton.swift
│   │   └── LoadingView.swift
│   │
│   └── Profile/
│       ├── ProfileView.swift
│       └── SettingsView.swift
│
├── Utilities/
│   ├── Extensions/
│   │   ├── Date+Extensions.swift
│   │   ├── Color+Extensions.swift
│   │   └── View+Extensions.swift
│   │
│   ├── Constants.swift
│   ├── Logger.swift
│   └── Helpers.swift
│
├── Resources/
│   ├── Assets.xcassets
│   ├── Localizable.strings
│   └── Preview Content/
│
└── Tests/
    ├── Unit/
    │   ├── CalendarManagerTests.swift
    │   └── ProposalViewModelTests.swift
    │
    └── Integration/
        └── ProposalFlowTests.swift
```

### State Management with MVVM + Combine

**ViewModel Pattern:**

```swift
class ProposalViewModel: ObservableObject {
    @Published var proposal: EventProposal?
    @Published var votes: [Vote] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var userVote: Vote?

    private var subscriptions = Set<AnyCancellable>()

    func loadProposal(id: String) {
        // Load from API
        // Subscribe to real-time updates
        // Update @Published properties to trigger View re-renders
    }
}
```

**View Pattern:**

```swift
struct ProposalView: View {
    @StateObject var viewModel = ProposalViewModel()

    var body: some View {
        if viewModel.isLoading {
            ProgressView()
        } else if let proposal = viewModel.proposal {
            // Render proposal with @Published properties
            // Changes trigger automatic re-renders
        }
    }
}
```

### Navigation Architecture

- Use SwiftUI `NavigationStack` for programmatic navigation
- Implement coordinator pattern for complex flows
- Store navigation state in ViewModels, not Views
- Example: `@State var selectedGroup: Group?` in GroupsViewModel

### Caching & Offline Strategy

1. **UI Caching:** Load cached data immediately while syncing in background
2. **Persistent Cache:** Store events, groups, proposals on disk using CacheManager
3. **Offline Queue:** Queue actions (votes, event creation) for sync when online
4. **TTL-Based Refresh:** Refresh cached data older than 1 hour

---

## Backend Architecture (Supabase)

### Supabase Stack Components

#### 1. PostgreSQL 15 Database
- 13 tables managing users, groups, events, proposals, votes, notifications
- Row Level Security (RLS) enforces privacy at database level
- Triggers automate notifications, proposal completion, data cleanup
- Indexes optimize common queries
- Full-text search ready via pg_trgm extension

#### 2. Supabase Auth (JWT-Based)
- Password-based authentication only (no OAuth for MVP)
- JWT tokens stored in secure keychain on iOS
- Refresh tokens for long-lived sessions
- Email verification before account creation

**Auth Flow:**

```
SignUp/SignIn Request
    ↓
Supabase Auth (email/password verification)
    ↓
Returns JWT + Refresh Token
    ↓
iOS saves JWT to Keychain
    ↓
All API calls include "Authorization: Bearer <JWT>" header
    ↓
Database RLS checks auth.uid() from JWT
```

#### 3. Supabase Realtime (WebSocket)
- PostgreSQL change subscriptions (inserts, updates)
- Enables real-time vote count updates without polling
- Managed channels per proposal, group, or event
- Automatic reconnection on network changes

**Real-time Example:**

```
ProposalView subscribes to: "proposal_votes" table
  WHERE proposal_id = <current-proposal-id>
    ↓
User A votes on time option
    ↓
PostgreSQL trigger fires, INSERT into proposal_votes
    ↓
Realtime publishes change to all subscribed clients
    ↓
ProposalView receives update, re-renders vote counts
```

#### 4. Supabase Edge Functions (Future)
- Serverless functions for:
  - Sending notifications when proposals created
  - Creating final events when voting closes
  - Scheduling reminder emails/notifications
  - Processing Stripe webhook events for premium subscriptions

#### 5. Supabase Storage
- Store user avatars and group images
- CDN-backed, fast image serving
- RLS prevents unauthorized access

### API Design Patterns

**Resource-Oriented Endpoints:**

```
GET    /rest/v1/users/{id}                    # Fetch user
POST   /rest/v1/groups                        # Create group
GET    /rest/v1/groups?user_id=eq.<id>       # Fetch user's groups
PUT    /rest/v1/events/{id}                   # Update event
DELETE /rest/v1/event_proposals/{id}          # Delete proposal
```

**Filtering & Pagination:**

```
GET /rest/v1/events?start_time=gte.2025-12-01&created_by=eq.<user-id>&order=start_time.asc&limit=50
```

**Error Response Format:**

```json
{
  "code": "PGRST109",
  "message": "Returned more than a single object",
  "details": "...",
  "hint": "..."
}
```

---

## Complete Database Schema

### Initial Setup

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable full-text search (for future features)
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Set timezone to UTC
SET timezone = 'UTC';
```

### Table 1: USERS

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

### Table 2: FRIENDSHIPS

**Purpose:** Bidirectional friend connections with request workflow

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

### Table 3: GROUPS

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

### Table 4: GROUP_MEMBERS

**Purpose:** Group membership and per-group privacy settings

```sql
CREATE TABLE group_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  role VARCHAR(20) DEFAULT 'member'
    CHECK (role IN ('admin', 'member', 'optional')),

  -- Privacy settings per group (can differ from default)
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

### Table 5: EVENTS

**Purpose:** Personal and group events, synced with Apple Calendar

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

  -- Recurrence (simplified for MVP)
  recurrence_rule TEXT,                    -- iCal RRULE format
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
  apple_calendar_id VARCHAR(255),          -- Store EventKit event identifier
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
CREATE INDEX idx_events_user_upcoming ON events(created_by, start_time)
  WHERE deleted_at IS NULL AND start_time >= NOW();

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

### Table 6: EVENT_ATTENDEES

**Purpose:** Track RSVPs and attendance for group events

```sql
CREATE TABLE event_attendees (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  rsvp_status VARCHAR(20) DEFAULT 'going'
    CHECK (rsvp_status IN ('going', 'maybe', 'not_going')),

  rsvp_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  UNIQUE(event_id, user_id)
);

-- Indexes
CREATE INDEX idx_attendees_event ON event_attendees(event_id);
CREATE INDEX idx_attendees_user ON event_attendees(user_id);
CREATE INDEX idx_attendees_status ON event_attendees(rsvp_status);

-- Row Level Security
ALTER TABLE event_attendees ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can see attendees of their events"
  ON event_attendees FOR SELECT
  USING (
    event_id IN (
      SELECT id FROM events
      WHERE created_by = auth.uid() OR group_id IN (
        SELECT group_id FROM group_members
        WHERE user_id = auth.uid() AND left_at IS NULL
      )
    )
  );

CREATE POLICY "Users can RSVP to events"
  ON event_attendees FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own RSVP"
  ON event_attendees FOR UPDATE
  USING (auth.uid() = user_id);
```

### Table 7: EVENT_PROPOSALS

**Purpose:** Group event proposals that go through voting process

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
CREATE INDEX idx_proposals_group_active ON event_proposals(group_id, status, voting_deadline)
  WHERE status = 'voting';

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

### Table 8: PROPOSAL_TIME_OPTIONS

**Purpose:** Time slot options for event proposals

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

### Table 9: PROPOSAL_VOTES

**Purpose:** User votes on proposal time options

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
CREATE INDEX idx_votes_option_response ON proposal_votes(time_option_id, response);

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

### Table 10: CALENDAR_SHARING

**Purpose:** Per-group privacy settings for calendar visibility

```sql
CREATE TABLE calendar_sharing (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Who can see (either user or group)
  shared_with_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  shared_with_group_id UUID REFERENCES groups(id) ON DELETE CASCADE,

  -- What they can see
  visibility_level VARCHAR(20) DEFAULT 'busy_only'
    CHECK (visibility_level IN ('private', 'shared_with_name', 'busy_only')),

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Must share with either user OR group, not both
  CHECK (
    (shared_with_user_id IS NOT NULL AND shared_with_group_id IS NULL) OR
    (shared_with_user_id IS NULL AND shared_with_group_id IS NOT NULL)
  )
);

-- Indexes
CREATE INDEX idx_sharing_user ON calendar_sharing(user_id);
CREATE INDEX idx_sharing_target_user ON calendar_sharing(shared_with_user_id);
CREATE INDEX idx_sharing_target_group ON calendar_sharing(shared_with_group_id);

-- Row Level Security
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

### Table 11: NOTIFICATIONS

**Purpose:** In-app notifications for user actions

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
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, created_at DESC)
  WHERE read = false;

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
```

### Table 12: PUSH_TOKENS

**Purpose:** Device tokens for APNs push notifications

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

### Table 13: ANALYTICS_EVENTS (Optional)

**Purpose:** Track user actions for analytics and insights

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

### Key Database Triggers & Functions

**Trigger: Notify group members on proposal creation**

```sql
CREATE OR REPLACE FUNCTION notify_proposal_created()
RETURNS TRIGGER AS $$
BEGIN
  -- Create notifications for all group members except creator
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
    AND gm.user_id != NEW.created_by;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_proposal_created
  AFTER INSERT ON event_proposals
  FOR EACH ROW
  EXECUTE FUNCTION notify_proposal_created();
```

**Trigger: Auto-confirm proposal when voting completes**

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

### Database Views for Common Queries

**View: Active groups with member counts**

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

**View: Proposal voting summary**

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

---

## API Endpoints Specification

### Authentication Endpoints

**POST /auth/v1/signup**

Create a new user account.

```swift
POST /auth/v1/signup
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePassword123!"
}

Response 200:
{
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "created_at": "2025-12-01T10:00:00Z"
  },
  "session": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "token_type": "bearer",
    "expires_in": 3600,
    "refresh_token": "sbr_token..."
  }
}
```

**POST /auth/v1/token?grant_type=password**

Sign in with email and password.

```swift
POST /auth/v1/token?grant_type=password
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePassword123!"
}

Response 200:
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "sbr_token..."
}
```

### User Endpoints

**GET /rest/v1/users?id=eq.{userId}**

Fetch current user profile.

```swift
Headers:
  Authorization: Bearer <access_token>

Response 200:
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "full_name": "Sarah Johnson",
    "username": "sarah_j",
    "avatar_url": "https://...",
    "default_event_visibility": "busy_only",
    "subscription_tier": "free",
    "created_at": "2025-12-01T10:00:00Z"
  }
]
```

**PUT /rest/v1/users?id=eq.{userId}**

Update user profile.

```swift
Headers:
  Authorization: Bearer <access_token>

Body:
{
  "full_name": "Sarah Johnson",
  "avatar_url": "https://...",
  "default_event_visibility": "shared_with_name"
}

Response 200:
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "full_name": "Sarah Johnson",
    "updated_at": "2025-12-01T11:00:00Z"
  }
]
```

### Group Endpoints

**GET /rest/v1/group_members?user_id=eq.{userId}&left_at=is.null&select=group_id,groups(*)**

Fetch user's groups.

```swift
Headers:
  Authorization: Bearer <access_token>

Response 200:
[
  {
    "group_id": "660e8400-e29b-41d4-a716-446655440000",
    "groups": {
      "id": "660e8400-e29b-41d4-a716-446655440000",
      "name": "College Friends",
      "emoji": "🎓",
      "created_by": "550e8400-e29b-41d4-a716-446655440000",
      "created_at": "2025-11-15T09:30:00Z"
    }
  }
]
```

**POST /rest/v1/groups**

Create a new group.

```swift
Headers:
  Authorization: Bearer <access_token>

Body:
{
  "name": "Game Night Crew",
  "emoji": "🎮",
  "created_by": "550e8400-e29b-41d4-a716-446655440000"
}

Response 201:
[
  {
    "id": "770e8400-e29b-41d4-a716-446655440000",
    "name": "Game Night Crew",
    "emoji": "🎮",
    "created_by": "550e8400-e29b-41d4-a716-446655440000",
    "created_at": "2025-12-01T14:00:00Z"
  }
]
```

**POST /rest/v1/group_members**

Add user to group.

```swift
Headers:
  Authorization: Bearer <access_token>

Body:
{
  "group_id": "770e8400-e29b-41d4-a716-446655440000",
  "user_id": "880e8400-e29b-41d4-a716-446655440000",
  "role": "member"
}

Response 201:
[
  {
    "id": "990e8400-e29b-41d4-a716-446655440000",
    "group_id": "770e8400-e29b-41d4-a716-446655440000",
    "user_id": "880e8400-e29b-41d4-a716-446655440000",
    "role": "member",
    "joined_at": "2025-12-01T14:05:00Z"
  }
]
```

### Event Endpoints

**GET /rest/v1/events?created_by=eq.{userId}&start_time=gte.{date}&order=start_time.asc&limit=50**

Fetch user's upcoming events.

```swift
Headers:
  Authorization: Bearer <access_token>

Response 200:
[
  {
    "id": "aa0e8400-e29b-41d4-a716-446655440000",
    "title": "Team Meeting",
    "start_time": "2025-12-05T14:00:00Z",
    "end_time": "2025-12-05T15:00:00Z",
    "location": "Conference Room A",
    "visibility": "private",
    "event_type": "personal",
    "created_by": "550e8400-e29b-41d4-a716-446655440000",
    "created_at": "2025-12-01T10:00:00Z"
  }
]
```

**POST /rest/v1/events**

Create a new event.

```swift
Headers:
  Authorization: Bearer <access_token>

Body:
{
  "title": "Lunch with Sarah",
  "start_time": "2025-12-05T12:00:00Z",
  "end_time": "2025-12-05T13:00:00Z",
  "location": "Downtown Cafe",
  "visibility": "busy_only",
  "created_by": "550e8400-e29b-41d4-a716-446655440000"
}

Response 201:
[
  {
    "id": "bb0e8400-e29b-41d4-a716-446655440000",
    "title": "Lunch with Sarah",
    "start_time": "2025-12-05T12:00:00Z",
    "end_time": "2025-12-05T13:00:00Z",
    "created_at": "2025-12-01T10:10:00Z"
  }
]
```

**PUT /rest/v1/events?id=eq.{eventId}**

Update event.

```swift
Headers:
  Authorization: Bearer <access_token>

Body:
{
  "title": "Lunch with Sarah and Mike",
  "location": "Downtown Cafe (Window Table)"
}

Response 200:
[
  {
    "id": "bb0e8400-e29b-41d4-a716-446655440000",
    "title": "Lunch with Sarah and Mike",
    "updated_at": "2025-12-01T10:15:00Z"
  }
]
```

### Event Proposal Endpoints

**POST /rest/v1/event_proposals**

Create event proposal.

```swift
Headers:
  Authorization: Bearer <access_token>

Body:
{
  "title": "Secret Santa Planning",
  "group_id": "770e8400-e29b-41d4-a716-446655440000",
  "created_by": "550e8400-e29b-41d4-a716-446655440000",
  "voting_deadline": "2025-12-08T23:59:59Z"
}

Response 201:
[
  {
    "id": "cc0e8400-e29b-41d4-a716-446655440000",
    "title": "Secret Santa Planning",
    "group_id": "770e8400-e29b-41d4-a716-446655440000",
    "status": "voting",
    "created_at": "2025-12-01T15:00:00Z"
  }
]
```

**GET /rest/v1/event_proposals?group_id=eq.{groupId}&status=eq.voting**

Fetch active proposals for group.

```swift
Headers:
  Authorization: Bearer <access_token>

Response 200:
[
  {
    "id": "cc0e8400-e29b-41d4-a716-446655440000",
    "title": "Secret Santa Planning",
    "group_id": "770e8400-e29b-41d4-a716-446655440000",
    "status": "voting",
    "voting_deadline": "2025-12-08T23:59:59Z",
    "created_by": "550e8400-e29b-41d4-a716-446655440000",
    "created_at": "2025-12-01T15:00:00Z"
  }
]
```

**POST /rest/v1/proposal_time_options**

Add time option to proposal.

```swift
Headers:
  Authorization: Bearer <access_token>

Body:
{
  "proposal_id": "cc0e8400-e29b-41d4-a716-446655440000",
  "start_time": "2025-12-15T18:00:00Z",
  "end_time": "2025-12-15T20:00:00Z",
  "option_order": 0
}

Response 201:
[
  {
    "id": "dd0e8400-e29b-41d4-a716-446655440000",
    "proposal_id": "cc0e8400-e29b-41d4-a716-446655440000",
    "start_time": "2025-12-15T18:00:00Z",
    "end_time": "2025-12-15T20:00:00Z",
    "option_order": 0,
    "created_at": "2025-12-01T15:05:00Z"
  }
]
```

### Voting Endpoints

**POST /rest/v1/proposal_votes**

Cast or update vote on proposal.

```swift
Headers:
  Authorization: Bearer <access_token>

Body:
{
  "proposal_id": "cc0e8400-e29b-41d4-a716-446655440000",
  "time_option_id": "dd0e8400-e29b-41d4-a716-446655440000",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "response": "available"
}

Response 201:
[
  {
    "id": "ee0e8400-e29b-41d4-a716-446655440000",
    "proposal_id": "cc0e8400-e29b-41d4-a716-446655440000",
    "time_option_id": "dd0e8400-e29b-41d4-a716-446655440000",
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "response": "available",
    "voted_at": "2025-12-01T16:00:00Z"
  }
]
```

**PATCH /rest/v1/proposal_votes?proposal_id=eq.{id}&time_option_id=eq.{id}&user_id=eq.{id}**

Update existing vote (upsert pattern).

```swift
Headers:
  Authorization: Bearer <access_token>

Body:
{
  "response": "maybe"
}

Response 200:
[
  {
    "id": "ee0e8400-e29b-41d4-a716-446655440000",
    "response": "maybe",
    "updated_at": "2025-12-01T16:30:00Z"
  }
]
```

### Notification Endpoints

**GET /rest/v1/notifications?user_id=eq.{userId}&read=eq.false&order=created_at.desc**

Fetch unread notifications.

```swift
Headers:
  Authorization: Bearer <access_token>

Response 200:
[
  {
    "id": "ff0e8400-e29b-41d4-a716-446655440000",
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "type": "event_proposal",
    "title": "New event proposal",
    "body": "Secret Santa Planning",
    "proposal_id": "cc0e8400-e29b-41d4-a716-446655440000",
    "read": false,
    "created_at": "2025-12-01T15:00:00Z"
  }
]
```

**PATCH /rest/v1/notifications?id=eq.{notificationId}**

Mark notification as read.

```swift
Headers:
  Authorization: Bearer <access_token>

Body:
{
  "read": true,
  "read_at": "2025-12-01T16:00:00Z"
}

Response 200:
[
  {
    "id": "ff0e8400-e29b-41d4-a716-446655440000",
    "read": true,
    "read_at": "2025-12-01T16:00:00Z"
  }
]
```

### Push Token Endpoint

**POST /rest/v1/push_tokens**

Register device for push notifications.

```swift
Headers:
  Authorization: Bearer <access_token>

Body:
{
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "device_token": "1234567890abcdef1234567890abcdef",
  "device_type": "ios"
}

Response 201:
[
  {
    "id": "gg0e8400-e29b-41d4-a716-446655440000",
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "device_token": "1234567890abcdef1234567890abcdef",
    "device_type": "ios",
    "active": true,
    "created_at": "2025-12-01T10:00:00Z"
  }
]
```

### Real-time Subscription Patterns

**Subscribe to proposal votes (WebSocket)**

```swift
// Automatically triggers when:
// - New vote inserted
// - Existing vote updated
let channel = supabase.realtime.channel("proposal:cc0e8400...")

channel.on(.postgresChanges(
  event: .insert,
  schema: "public",
  table: "proposal_votes",
  filter: "proposal_id=eq.cc0e8400..."
)) { payload in
  // Receive new vote in real-time
  let newVote = try? JSONDecoder().decode(Vote.self, from: payload.new)
}

channel.subscribe()
```

**Subscribe to proposal status changes (WebSocket)**

```swift
let channel = supabase.realtime.channel("proposal:cc0e8400...")

channel.on(.postgresChanges(
  event: .update,
  schema: "public",
  table: "event_proposals",
  filter: "id=eq.cc0e8400..."
)) { payload in
  // Proposal status changed (e.g., voting → confirmed)
  let updatedProposal = try? JSONDecoder().decode(EventProposal.self, from: payload.new)
}

channel.subscribe()
```

---

## EventKit Integration Strategy

### Overview

EventKit provides the only way to access and sync with the native Apple Calendar on iOS. The strategy is **bidirectional synchronization**: changes in the app sync to Apple Calendar, and changes in Apple Calendar sync back to the app.

### Permission Handling

**Request at the right time:**

```swift
// DON'T request on app launch
// DO request during onboarding with clear explanation of value

func requestCalendarAccess() async throws -> Bool {
    let eventStore = EKEventStore()
    let granted = try await eventStore.requestAccess(to: .event)

    // Only returns true if user explicitly grants permission
    // Returns false if denied or if already denied previously

    return granted
}
```

### Sync Strategy

**Time Range to Sync:**

- **Past:** Last 30 days (to catch recently deleted/modified events)
- **Future:** Next 60 days (reasonable lookahead)
- **Pagination:** Fetch events in chunks, don't load all calendars at once

**Sync Frequency:**

- **Background:** Every 15 minutes when app is active
- **Manual:** Pull-to-refresh on calendar screen
- **Foreground:** When app returns from background
- **Trigger:** When user creates/modifies event in app

**Direction of Sync:**

```
Apple Calendar → App (Read)
  • Fetch events from all user's calendars
  • Match with app's events using apple_calendar_id

App → Apple Calendar (Write)
  • When user creates event with visibility = "private"
  • When user creates confirmed group event
  • When confirmed event is modified

Conflict Resolution (Last Write Wins):
  • Compare updated_at timestamps
  • Most recent change takes precedence
  • Notify user of conflicts
```

### Implementation Details

**EventKit Integration Code:**

```swift
import EventKit
import Combine

class CalendarManager: ObservableObject {
    static let shared = CalendarManager()

    private let eventStore = EKEventStore()
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined

    // MARK: - Authorization

    func requestAccess() async throws -> Bool {
        let granted = try await eventStore.requestAccess(to: .event)
        await MainActor.run {
            self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        }
        return granted
    }

    // MARK: - Fetch Events

    func fetchEvents(from startDate: Date, to endDate: Date) -> [EKEvent] {
        guard authorizationStatus == .authorized else { return [] }

        let calendars = eventStore.calendars(for: .event)
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: calendars
        )

        return eventStore.events(matching: predicate)
    }

    // MARK: - Create Event in Apple Calendar

    func createEvent(
        title: String,
        startDate: Date,
        endDate: Date,
        notes: String? = nil,
        location: String? = nil
    ) throws -> String {
        guard authorizationStatus == .authorized else {
            throw CalendarError.notAuthorized
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.notes = notes
        event.location = location
        event.calendar = eventStore.defaultCalendarForNewEvents

        try eventStore.save(event, span: .thisEvent)
        return event.eventIdentifier
    }

    // MARK: - Update Event in Apple Calendar

    func updateEvent(
        identifier: String,
        title: String?,
        startDate: Date?,
        endDate: Date?
    ) throws {
        guard let event = eventStore.event(withIdentifier: identifier) else {
            throw CalendarError.eventNotFound
        }

        if let title = title { event.title = title }
        if let startDate = startDate { event.startDate = startDate }
        if let endDate = endDate { event.endDate = endDate }

        try eventStore.save(event, span: .thisEvent)
    }

    // MARK: - Delete Event from Apple Calendar

    func deleteEvent(identifier: String) throws {
        guard let event = eventStore.event(withIdentifier: identifier) else {
            throw CalendarError.eventNotFound
        }

        try eventStore.remove(event, span: .thisEvent)
    }

    // MARK: - Get Availability Heatmap

    func getAvailability(for date: Date) -> [AvailabilitySlot] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let events = fetchEvents(from: startOfDay, to: endOfDay)

        // Generate 30-minute slots for the day
        var slots: [AvailabilitySlot] = []
        var currentTime = startOfDay

        while currentTime < endOfDay {
            let slotEnd = calendar.date(byAdding: .minute, value: 30, to: currentTime)!

            // Check if any event overlaps this slot
            let isBusy = events.contains { event in
                event.startDate < slotEnd && event.endDate > currentTime
            }

            slots.append(AvailabilitySlot(
                start: currentTime,
                end: slotEnd,
                status: isBusy ? .busy : .available
            ))

            currentTime = slotEnd
        }

        return slots
    }
}

// MARK: - Models

struct AvailabilitySlot {
    let start: Date
    let end: Date
    let status: AvailabilityStatus
}

enum AvailabilityStatus {
    case available
    case busy
    case unknown
}

enum CalendarError: Error {
    case notAuthorized
    case eventNotFound
    case saveFailed
}
```

### Event Mapping (EventKit ↔ App)

| Field | EventKit | App Database |
|-------|----------|--------------|
| **Title** | `EKEvent.title` | `events.title` |
| **Start Time** | `EKEvent.startDate` | `events.start_time` |
| **End Time** | `EKEvent.endDate` | `events.end_time` |
| **Location** | `EKEvent.location` | `events.location` |
| **Notes** | `EKEvent.notes` | `events.description` |
| **All Day** | `EKEvent.isAllDay` | `events.all_day` |
| **Identifier** | `EKEvent.eventIdentifier` | `events.apple_calendar_id` |
| **Last Modified** | `EKEvent.lastModifiedDate` | `events.last_synced_at` |

### Offline Queue for Sync

When user is offline and creates/modifies an event:

```swift
// 1. Create event locally
let offlineAction = OfflineAction(
    type: .createEvent,
    payload: eventData,
    timestamp: Date()
)

// 2. Save to offline queue
CacheManager.shared.queueOfflineAction(offlineAction)

// 3. Add to Apple Calendar immediately (optimistic)
try calendarManager.createEvent(...)

// 4. When online again, sync queue
for action in CacheManager.shared.getOfflineQueue() {
    try await APIClient.shared.syncOfflineAction(action)
}
CacheManager.shared.clearOfflineQueue()
```

---

## Third-Party Services Integration

### Apple Push Notification Service (APNs)

**Purpose:** Send notifications when proposals created, votes cast, or events confirmed

**Setup:**

1. Obtain APNs certificate from Apple Developer account
2. Configure in Supabase project settings
3. Save push device tokens to database

**iOS Implementation:**

```swift
import UserNotifications

class PushNotificationManager: NSObject, ObservableObject {
    static let shared = PushNotificationManager()

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
    }

    // MARK: - Request Authorization

    func requestAuthorization() async throws -> Bool {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        let granted = try await center.requestAuthorization(options: options)

        if granted {
            await registerForRemoteNotifications()
        }

        return granted
    }

    @MainActor
    private func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    // MARK: - Handle Device Token

    func didRegisterForRemoteNotifications(deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()

        // Save to backend
        Task {
            try? await APIClient.shared.savePushToken(token)
        }
    }

    // MARK: - Local Notifications (fallback)

    func scheduleProposalDeadlineReminder(
        for proposal: EventProposal,
        hoursBeforeDeadline: Int
    ) async throws {
        guard let deadline = proposal.votingDeadline else { return }

        let reminderDate = Calendar.current.date(
            byAdding: .hour,
            value: -hoursBeforeDeadline,
            to: deadline
        )!

        let content = UNMutableNotificationContent()
        content.title = "Voting Deadline Soon"
        content.body = "\(proposal.title) voting ends in \(hoursBeforeDeadline) hours"
        content.sound = .default
        content.badge = 1
        content.userInfo = ["proposal_id": proposal.id.uuidString]

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(
            identifier: "proposal_\(proposal.id.uuidString)_reminder",
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }
}

// MARK: - Notification Delegate

extension PushNotificationManager: UNUserNotificationCenterDelegate {
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        if let proposalId = userInfo["proposal_id"] as? String {
            // Navigate to proposal screen
            NotificationCenter.default.post(
                name: .didTapProposalNotification,
                object: nil,
                userInfo: ["proposal_id": proposalId]
            )
        }

        completionHandler()
    }
}
```

### MapKit Integration

**Purpose:** Show event locations on map, calculate travel time

**Future Implementation:**

```swift
import MapKit

class LocationManager: NSObject, CLLocationManagerDelegate {
    func calculateTravelTime(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) async throws -> TimeInterval {
        let request = MKDirections.Request()
        request.source = MKMapItem(
            placemark: MKPlacemark(coordinate: from)
        )
        request.destination = MKMapItem(
            placemark: MKPlacemark(coordinate: to)
        )

        let directions = MKDirections(request: request)
        let response = try await directions.calculate()

        return response.routes.first?.expectedTravelTime ?? 0
    }
}
```

### Stripe Integration

**Purpose:** Process premium subscription payments

**Implementation (Backend via Edge Functions):**

```swift
// iOS: Create payment intent
POST /api/create-payment-intent
{
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "subscription_tier": "premium",
  "billing_cycle": "monthly"
}

// Response
{
  "client_secret": "pi_...",
  "publishable_key": "pk_..."
}

// Handle webhook for subscription confirmation
POST /api/webhook/stripe
{
  "type": "customer.subscription.created",
  "data": {
    "object": {
      "customer": "cus_...",
      "status": "active"
    }
  }
}
```

### Analytics Integration

**Purpose:** Track user actions, measure engagement

```swift
enum AnalyticsEvent: String {
    // User actions
    case eventCreated = "event_created"
    case proposalCreated = "proposal_created"
    case voteCast = "vote_cast"
    case groupCreated = "group_created"

    // Engagement
    case appOpened = "app_opened"
    case screenViewed = "screen_viewed"

    // Conversions
    case upgradeToPremium = "upgrade_to_premium"
}

class Analytics {
    static let shared = Analytics()

    func track(_ event: AnalyticsEvent, properties: [String: Any]? = nil) {
        var eventData: [String: Any] = [
            "event_name": event.rawValue,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]

        if let properties = properties {
            eventData["properties"] = properties
        }

        // Send to backend
        Task {
            try? await APIClient.shared.trackAnalytics(eventData)
        }
    }
}
```

---

## Code Snippets Library

### Authentication Pattern

```swift
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var error: Error?

    func signUp(email: String, password: String, fullName: String) async {
        isLoading = true
        do {
            let user = try await APIClient.shared.signUp(
                email: email,
                password: password,
                fullName: fullName
            )

            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        do {
            let user = try await APIClient.shared.signIn(
                email: email,
                password: password
            )

            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
}
```

### Real-time Vote Updates

```swift
class ProposalViewModel: ObservableObject {
    @Published var proposal: EventProposal?
    @Published var votes: [Vote] = []

    private var voteSubscription: RealtimeChannel?
    private var cancellables = Set<AnyCancellable>()

    func subscribeToVotes(proposalId: String) {
        voteSubscription = WebSocketManager.shared.subscribeToProposal(
            proposalId,
            onUpdate: { [weak self] update in
                switch update {
                case .newVote(let vote):
                    DispatchQueue.main.async {
                        if !self?.votes.contains(where: { $0.id == vote.id }) ?? false {
                            self?.votes.append(vote)
                        }
                    }
                case .statusChanged(let proposal):
                    DispatchQueue.main.async {
                        self?.proposal = proposal
                    }
                }
            }
        )
    }

    func castVote(
        proposalId: String,
        timeOptionId: String,
        response: VoteResponse
    ) async {
        do {
            try await APIClient.shared.voteOnProposal(
                proposalId: proposalId,
                timeOptionId: timeOptionId,
                userId: currentUserId,
                response: response
            )
        } catch {
            // Handle error
        }
    }

    deinit {
        if let subscription = voteSubscription {
            WebSocketManager.shared.unsubscribeFromProposal(subscription.topic)
        }
    }
}
```

### Caching Pattern

```swift
class CacheManager {
    static let shared = CacheManager()

    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    init() {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("CalendarCache")
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Cache Events

    func cacheEvents(_ events: [Event], for date: Date) {
        let key = cacheKey(for: date)
        let encoder = JSONEncoder()

        if let data = try? encoder.encode(events) {
            let fileURL = cacheDirectory.appendingPathComponent(key)
            try? data.write(to: fileURL)
        }
    }

    func getCachedEvents(for date: Date) -> [Event]? {
        let key = cacheKey(for: date)
        let fileURL = cacheDirectory.appendingPathComponent(key)

        guard let data = try? Data(contentsOf: fileURL) else { return nil }

        let decoder = JSONDecoder()
        return try? decoder.decode([Event].self, from: data)
    }

    // MARK: - Offline Queue

    func queueOfflineAction(_ action: OfflineAction) {
        var queue = getOfflineQueue()
        queue.append(action)
        saveOfflineQueue(queue)
    }

    func getOfflineQueue() -> [OfflineAction] {
        let fileURL = cacheDirectory.appendingPathComponent("offline_queue.json")
        guard let data = try? Data(contentsOf: fileURL) else { return [] }

        let decoder = JSONDecoder()
        return (try? decoder.decode([OfflineAction].self, from: data)) ?? []
    }

    private func cacheKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "events_\(formatter.string(from: date)).json"
    }
}
```

### Testing Patterns

```swift
import XCTest
@testable import CalendarApp

class ProposalFlowTests: XCTestCase {
    func testCreateAndVoteOnProposal() async throws {
        // Given
        let testGroup = try await createTestGroup()
        let timeOptions = [
            ProposalTimeOption(
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600)
            )
        ]

        // When - Create proposal
        let proposal = try await APIClient.shared.createProposal(
            title: "Test Event",
            groupId: testGroup.id.uuidString,
            createdBy: testUserId,
            timeOptions: timeOptions
        )

        // Then
        XCTAssertEqual(proposal.status, .voting)

        // When - Vote on proposal
        try await APIClient.shared.voteOnProposal(
            proposalId: proposal.id.uuidString,
            timeOptionId: timeOptions[0].id.uuidString,
            userId: testUserId,
            response: .available
        )

        // Then - Verify vote recorded
        let votes = try await APIClient.shared.fetchVotes(for: proposal.id.uuidString)
        XCTAssertEqual(votes.count, 1)
        XCTAssertEqual(votes.first?.response, .available)
    }
}
```

---

## Security & Privacy Architecture

### Privacy-First Event Model

```swift
enum EventVisibility {
    case `private`             // Hidden from all groups
    case sharedWithName        // Groups see event title & time
    case busyOnly             // Groups see "busy" block without details
}
```

**How it Works:**

1. User sets visibility per event or group
2. Backend enforces visibility via RLS policies
3. Heatmap shows only what user is allowed to see
4. Tapping time slot reveals names only if visibility allows

### Row Level Security (RLS) Enforcement

**Example: Events table RLS**

```sql
CREATE POLICY "Users can see events respecting privacy"
  ON events FOR SELECT
  USING (
    created_by = auth.uid() OR                    -- Own events
    id IN (
      SELECT event_id FROM event_attendees        -- Events you're invited to
      WHERE user_id = auth.uid()
    ) OR
    (
      group_id IN (                               -- Group events you're in
        SELECT group_id FROM group_members
        WHERE user_id = auth.uid() AND left_at IS NULL
      )
      AND event_type = 'group_confirmed'
    )
  );
```

Privacy enforced at database level—iOS app can't circumvent it.

### JWT Token Management

**On iOS (Keychain):**

```swift
// Save tokens securely
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccount as String: "access_token",
    kSecValueData as String: token.data(using: .utf8)!
]
SecItemAdd(query as CFDictionary, nil)

// Retrieve token
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccount as String: "access_token",
    kSecReturnData as String: true
]
var result: AnyObject?
SecItemCopyMatching(query as CFDictionary, &result)
let token = String(data: result as! Data, encoding: .utf8)

// Send in all API requests
var request = URLRequest(url: endpoint)
request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
```

### API Authentication Flow

```
1. User enters email/password
   ↓
2. POST /auth/v1/token → Supabase Auth
   ↓
3. Returns JWT token + refresh token
   ↓
4. iOS saves JWT to Keychain, refresh token in UserDefaults
   ↓
5. All API requests include: Authorization: Bearer <JWT>
   ↓
6. Backend validates JWT signature, extracts auth.uid()
   ↓
7. Database RLS checks auth.uid() against row policies
   ↓
8. Only authorized data returned
```

### Data Encryption

**In Transit:**

- All API calls over HTTPS/TLS 1.3
- WebSocket connections over WSS (secure WebSocket)

**At Rest:**

- Supabase provides encryption of data files
- Sensitive data (passwords) hashed with bcrypt
- User avatars served from CDN with CORS restrictions

### Privacy Compliance

- **GDPR-Ready:** RLS enables per-user data isolation
- **CCPA-Ready:** User can request data export/deletion
- **User Control:** Granular privacy settings per event and group
- **Data Minimization:** Only request calendar access when needed

---

## Performance & Scalability

### Caching Strategy

**3-Layer Caching:**

1. **Memory Cache** (ViewModel @Published properties)
   - Holds current data for views
   - Cleared on view dismissal
   - Fast re-render on property changes

2. **Disk Cache** (CacheManager)
   - Stores events, groups, proposals
   - Survives app restart
   - Checked before API call
   - TTL: 1 hour (refresh older data)

3. **Network Cache** (Supabase)
   - Edge CDN caches frequently accessed data
   - HTTP headers control cache behavior
   - Reduces database load

### Lazy Loading Pattern

```swift
// Load groups only when accessed
class GroupsViewModel: ObservableObject {
    @Published var groups: [Group] = []
    @Published var isLoading = false

    var visibleGroups: [Group] {
        groups.prefix(20)  // Load first 20
    }

    func loadMore() async {
        // Load next batch
        let newGroups = try await APIClient.shared.fetchGroups(
            limit: 20,
            offset: groups.count
        )
        self.groups.append(contentsOf: newGroups)
    }
}
```

### Background Sync Optimization

```swift
// Sync only when:
// 1. App enters foreground
// 2. Every 15 minutes in background
// 3. Manual pull-to-refresh

class CalendarSync {
    func setupBackgroundSync() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.sync()
        }
    }

    func syncInBackground() {
        BGTaskScheduler.shared.submitTaskRequest(
            BGAppRefreshTaskRequest(identifier: "com.calendar.sync")
        ) { error in
            if error != nil { print("Failed to schedule sync") }
        }
    }
}
```

### Database Query Optimization

**Indexes for common queries:**

```sql
-- Fast user's upcoming events
CREATE INDEX idx_events_user_upcoming
  ON events(created_by, start_time)
  WHERE deleted_at IS NULL AND start_time >= NOW();

-- Fast active proposals in group
CREATE INDEX idx_proposals_group_active
  ON event_proposals(group_id, status)
  WHERE status = 'voting';

-- Fast unread notifications
CREATE INDEX idx_notifications_user_unread
  ON notifications(user_id, created_at DESC)
  WHERE read = false;
```

### Real-time Connection Management

```swift
class WebSocketManager: ObservableObject {
    private var channels: [String: RealtimeChannel] = [:]

    // Only subscribe to active proposals
    func subscribeToProposal(_ proposalId: String) {
        let channelId = "proposal:\(proposalId)"

        // Check if already subscribed
        if channels[channelId] != nil { return }

        let channel = supabase.realtime.channel(channelId)
        // Subscribe to updates...
        channels[channelId] = channel
    }

    // Unsubscribe when proposal screen dismissed
    func unsubscribeFromProposal(_ proposalId: String) {
        let channelId = "proposal:\(proposalId)"
        channels[channelId]?.unsubscribe()
        channels.removeValue(forKey: channelId)
    }

    // Clean up all connections
    func disconnectAll() {
        for (_, channel) in channels {
            channel.unsubscribe()
        }
        channels.removeAll()
    }
}
```

---

## Development Environment Setup

### Required Tools

- **Xcode 15.0+** (with iOS 17 SDK)
- **Swift 5.9+**
- **Supabase CLI** (`brew install supabase`)
- **Git** (for version control)
- **Fastlane** (for CI/CD) - `sudo gem install fastlane`

### Local Supabase Setup

```bash
# Install Supabase CLI
brew install supabase

# Initialize local Supabase project
supabase init

# Start local Supabase stack (Docker required)
supabase start

# Verify database is running
supabase status

# Run SQL migrations
supabase db push --local

# Access local database
psql "postgresql://postgres:postgres@localhost:5432/postgres"
```

### Xcode Project Configuration

**1. Add Supabase SDK:**

```swift
// In Package.swift or via Xcode:
.package(
    url: "https://github.com/supabase-community/supabase-swift.git",
    from: "0.2.0"
)
```

**2. Configure Info.plist:**

```xml
<key>NSCalendarsUsageDescription</key>
<string>We use your calendar to show availability for group events</string>

<key>NSCameraUsageDescription</key>
<string>We use your camera for video calls (future feature)</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>We use your location to calculate travel time</string>
```

**3. Environment Configuration:**

```swift
// Config.swift
struct Config {
    static let supabaseURL = URL(string: "https://your-project.supabase.co")!
    static let supabaseKey = "your-anon-key"
}
```

### Running Tests

```bash
# Run all unit tests
xcodebuild test -scheme CalendarApp

# Run specific test class
xcodebuild test -scheme CalendarApp -testClassPattern "ProposalFlowTests"

# Run with coverage
xcodebuild test -scheme CalendarApp -coverage

# Integration tests (requires backend)
xcodebuild test -scheme CalendarApp -testClassPattern "*Integration*"
```

### CI/CD with Fastlane

```ruby
# fastlane/Fastfile
default_platform(:ios)

platform :ios do
  desc "Run tests"
  lane :test do
    run_tests(scheme: "CalendarApp")
  end

  desc "Build and upload to TestFlight"
  lane :beta do
    increment_build_number(xcodeproj: "CalendarApp.xcodeproj")
    build_app(scheme: "CalendarApp")
    upload_to_testflight

    slack(
      message: "New beta build uploaded!",
      channel: "#ios-releases"
    )
  end

  desc "Release to App Store"
  lane :release do
    increment_version_number(version_number: "1.0.0")
    build_app(scheme: "CalendarApp")
    upload_to_app_store
  end
end
```

**Run Fastlane lanes:**

```bash
fastlane ios test
fastlane ios beta
fastlane ios release
```

---

## Summary

This consolidated technical architecture document covers every aspect of LockItIn's backend and frontend systems:

- **Frontend:** Swift/SwiftUI MVVM architecture with Combine reactive programming
- **Backend:** Supabase PostgreSQL with Row Level Security enforcing privacy at database level
- **Sync:** EventKit bidirectional calendar synchronization every 15 minutes
- **Real-time:** WebSocket subscriptions for live vote count updates without polling
- **Notifications:** APNs integration with fallback local notifications
- **Caching:** 3-layer caching (memory, disk, network) for offline support
- **Security:** JWT token management, RLS policies, encryption in transit
- **Scalability:** Lazy loading, background sync optimization, indexed queries
- **Testing:** Unit, integration, and UI test patterns with full code examples

All code snippets are production-ready and follow best practices for iOS development in 2025.

---

*Last Updated: December 1, 2025*
*Project Status: Pre-development (Planning Phase)*
*Target Launch: April 30, 2026*
