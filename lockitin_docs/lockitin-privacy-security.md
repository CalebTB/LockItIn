# LockItIn: Privacy & Security Design Guide

*Complete consolidated reference for privacy-first architecture, security implementation, and user controls*

**Last Updated:** December 2, 2025
**Status:** Pre-development (Planning Phase)
**Target Launch:** April 30, 2026

---

## Table of Contents

1. [Privacy & Security Philosophy](#privacy--security-philosophy)
2. [Shadow Calendar System Overview](#shadow-calendar-system-overview)
3. [Shadow Calendar Technical Implementation](#shadow-calendar-technical-implementation)
4. [Row Level Security (RLS) Policies](#row-level-security-rls-policies)
5. [Group Privacy Controls](#group-privacy-controls)
6. [Authentication & Authorization](#authentication--authorization)
7. [Data Privacy & Compliance](#data-privacy--compliance)
8. [API Security](#api-security)
9. [Data Encryption](#data-encryption)
10. [Privacy-Aware Features](#privacy-aware-features)
11. [Privacy Edge Cases](#privacy-edge-cases)
12. [Security Best Practices](#security-best-practices)
13. [Penetration Testing & Audits](#penetration-testing--audits)
14. [User Privacy Controls UI](#user-privacy-controls-ui)
15. [Quick Reference](#quick-reference)

---

## Privacy & Security Philosophy

### Core Principle: Privacy First

**LockItIn is built on the belief that users should control their calendar data completely.** Every privacy decision prioritizes user control, transparency, and minimal data exposure.

### Why Privacy Matters for LockItIn

**Problem Solved:**
- Users want to share availability with friend groups WITHOUT revealing private event details
- Current calendar-sharing apps (Google Calendar, Outlook) are all-or-nothing
- Sharing your calendar means everyone sees your doctor's appointment, therapy session, and personal time

**LockItIn Solution:**
The Shadow Calendar system shows friends *when you're free/busy* without showing *what you're doing*.

### Privacy as Competitive Differentiator

**Market Positioning:**
- Competitors (Howbout, TimeTree, When2Meet) focus on finding meeting times
- LockItIn focuses on *privacy while finding meeting times*
- Users explicitly choose LockItIn because they trust the privacy model

### Trust and Transparency Principles

**What we collect:**
- Calendar events (when you're busy/free)
- Group memberships (who you coordinate with)
- Votes (your preferences for event times)
- Minimal profile data (name, email, avatar)

**What we don't collect:**
- Event details you mark as "Private" or "Busy-Only"
- Location data (only for voluntary travel time calculations)
- Browsing history, contacts (beyond friends you invite)
- Behavioral analytics beyond engagement metrics

**User Control:**
- All data can be exported (GDPR right to access)
- All data can be deleted (GDPR right to be forgotten)
- All sharing can be revoked immediately
- Privacy settings can be changed anytime

---

## Shadow Calendar System Overview

### Three-Tier Visibility Model

The core innovation: **Show availability without revealing details.**

#### Level 1: Private (🔒)

**What the user sees:**
- Event in their personal calendar with full details
- Title, time, location, description all visible

**What groups see:**
- Nothing (gap in calendar is completely invisible)
- No "busy" block, no indication of anything

**Use cases:**
- Medical appointments (therapy, doctor)
- Personal time / mental health breaks
- Confidential meetings
- Family matters
- Anything the user doesn't want discussed

**RLS Rule:**
Groups have ZERO access to private events. Database-level enforcement.

---

#### Level 2: Shared With Name (👥)

**What the user sees:**
- Event visible in group calendar with full details
- Title, time, location all shared

**What groups see:**
- Full event details (title, time, location, description)
- Who else is attending
- Can be discussed in group chat

**Use cases:**
- Confirmed group events ("Game Night", "Dinner with Sarah")
- Events you want to discuss with the group
- Planning events where details matter

**RLS Rule:**
Group members can see events where `visibility = 'shared_with_name'` AND they're in the group.

---

#### Level 3: Busy Only (👁️)

**What the user sees:**
- Event in their personal calendar with full details
- Title, time, location, description all visible

**What groups see:**
- A "busy" block during that time
- No event title, location, or description
- Calendar heatmap counts them as "busy"
- Can see name in availability heatmap only with more intrusive tapping

**Use cases:**
- Work meetings (colleagues don't need to know your schedule details)
- Appointments you're committed to but don't want to discuss
- Professional obligations
- Anything personal but requiring privacy from this group

**RLS Rule:**
Groups see availability (busy/free status) but not event details. Privacy enforced at database.

---

### How Shadow Calendar Works (Technical Overview)

```
User's Personal Calendar
├─ Doctor's appointment (2-3pm) [PRIVATE]
├─ Team meeting (4-5pm) [BUSY-ONLY]
└─ Dinner with Sarah (7-8pm) [SHARED-WITH-NAME]

Group View (College Friends):
├─ 2-3pm: UNKNOWN (gap in their view)
├─ 4-5pm: YOU'RE BUSY (gray block, no details)
└─ 7-8pm: Dinner with Sarah (7-8pm, Sarah attending)
```

**When proposing a group event (e.g., Game Night 2pm-4pm):**
- System checks user's availability
- User shows as busy 2-3pm (doctor's appointment, privacy preserved)
- System marks user as unavailable for 2-3pm time slot
- Other users see aggregate: "6/8 people free 2-3pm, 7/8 people free 3-4pm"
- User's privacy is protected while contributing to group planning

---

## Shadow Calendar Technical Implementation

### Database-Level Privacy Enforcement

**Why enforce at database level?**
- Cannot be circumvented by app logic
- Impossible for hackers to bypass UI controls
- Most secure approach

### Event Visibility Enum

```swift
enum EventVisibility {
    case `private`          // Hidden from all groups
    case sharedWithName     // Groups see title & time
    case busyOnly          // Groups see "busy" block without details
}
```

**Stored in database as VARCHAR(20) with CHECK constraint:**
```sql
visibility VARCHAR(20) CHECK (visibility IN ('private', 'shared_with_name', 'busy_only'))
```

---

### RLS Policy: Group Members Can See Visibility-Appropriate Events

```sql
CREATE POLICY "Users see events respecting privacy settings"
  ON events FOR SELECT
  USING (
    -- Case 1: User owns the event
    created_by = auth.uid()
    OR
    -- Case 2: User is an attendee
    id IN (
      SELECT event_id FROM event_attendees
      WHERE user_id = auth.uid()
    )
    OR
    -- Case 3: Group event that respects visibility
    (
      group_id IN (
        SELECT group_id FROM group_members
        WHERE user_id = auth.uid() AND left_at IS NULL
      )
      AND event_type = 'group_confirmed'
      AND visibility IN ('shared_with_name', 'busy_only')
    )
  );
```

This policy ensures:
- Users can see their own events (regardless of visibility)
- Users can see events they're invited to
- Groups only see events marked "shared_with_name" or "busy_only"
- Private events are completely invisible to groups

---

### API-Level Privacy Enforcement

**Never trust the client.** Always validate on the backend.

When API receives request for events:
```javascript
// Backend validation (Supabase Edge Function)
async function getGroupAvailability(groupId, startDate, endDate) {
  // Verify user is in group
  const isGroupMember = await checkGroupMembership(userId, groupId);
  if (!isGroupMember) {
    return 403 Forbidden;
  }

  // Query respects RLS automatically
  const events = await db
    .from('events')
    .select('*')
    .eq('group_id', groupId)
    .gte('start_time', startDate)
    .lte('end_time', endDate);
  // RLS automatically filters based on visibility

  // Aggregate results for availability heatmap
  return aggregateAvailability(events, groupMembers);
}
```

---

### UI-Level Privacy Hints

Show privacy icons on calendar:
- 🔒 Private - Grayed out, no details shown
- 👥 Shared - Full event visible
- 👁️ Busy only - "Busy" block shown without details

**User can tap to see:**
- Full privacy settings
- Who else can see this event
- Option to change privacy level

---

### Group Availability Heatmap (Privacy-Preserving)

**What the heatmap shows:**

```
Wednesday 2:00-3:00 PM
✓ AVAILABLE (5/8 people)
⚠ BUSY (2/8 people - busy only events)
❓ UNKNOWN (1/8 people - calendar private)

[Tap to see who's available]
```

**When tapped (shows names):**
```
AVAILABLE:
• Sarah M. (Shared calendar)
• Mike J. (Shared calendar)
• Jordan T. (Shared calendar)
• Alex K. (Shared calendar)
• You (Your calendar)

BUSY:
• Emma W. (Busy on something)
• Chris P. (Busy on something)

UNKNOWN:
• Taylor S. (Private calendar)
```

**Progressive disclosure:**
1. Initially see counts only
2. Tap to see names with status
3. Respects all visibility settings
4. Cannot see event titles for busy-only events

---

## Row Level Security (RLS) Policies

### RLS Overview

**What is RLS?**
PostgreSQL feature that restricts database access based on user role. Applied automatically to all queries.

**Why use it?**
- Cannot be bypassed by app logic
- Protects against accidental data exposure
- Protects against malicious API calls
- Server-side enforcement

**How it works:**
1. All queries include `auth.uid()` from JWT token
2. Database checks if user has access to each row
3. Rows not matching policy are filtered out automatically
4. No API workaround exists

---

### RLS Policies for All 13 Tables

#### Table 1: USERS

```sql
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Users can read own profile
CREATE POLICY "Users can read own profile"
  ON users FOR SELECT
  USING (auth.uid() = id);

-- Users can update own profile
CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  USING (auth.uid() = id);

-- Users can be searched by friends (minimal info)
CREATE POLICY "Friends can see minimal user info"
  ON users FOR SELECT
  USING (
    id IN (
      SELECT user_id FROM friendships
      WHERE friend_id = auth.uid() AND status = 'accepted'
    )
    OR
    id IN (
      SELECT friend_id FROM friendships
      WHERE user_id = auth.uid() AND status = 'accepted'
    )
  );
```

---

#### Table 2: FRIENDSHIPS

```sql
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;

-- Users can see own friendship requests (sent and received)
CREATE POLICY "Users can see own friendships"
  ON friendships FOR SELECT
  USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- Users can create friendship requests
CREATE POLICY "Users can create friendship requests"
  ON friendships FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can accept their own requests
CREATE POLICY "Users can accept friendship requests"
  ON friendships FOR UPDATE
  USING (auth.uid() = friend_id);
```

---

#### Table 3: GROUPS

```sql
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;

-- Users can see groups they're in
CREATE POLICY "Users can see groups they are in"
  ON groups FOR SELECT
  USING (
    id IN (
      SELECT group_id FROM group_members
      WHERE user_id = auth.uid() AND left_at IS NULL
    )
  );

-- Users can create groups
CREATE POLICY "Users can create groups"
  ON groups FOR INSERT
  WITH CHECK (auth.uid() = created_by);

-- Group admins can update groups
CREATE POLICY "Group admins can update groups"
  ON groups FOR UPDATE
  USING (
    id IN (
      SELECT group_id FROM group_members
      WHERE user_id = auth.uid() AND role = 'admin' AND left_at IS NULL
    )
  );
```

---

#### Table 4: GROUP_MEMBERS

```sql
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;

-- Users can see members of their groups
CREATE POLICY "Users can see group members"
  ON group_members FOR SELECT
  USING (
    group_id IN (
      SELECT group_id FROM group_members
      WHERE user_id = auth.uid() AND left_at IS NULL
    )
  );

-- Group admins can manage members
CREATE POLICY "Group admins can manage members"
  ON group_members FOR ALL
  USING (
    group_id IN (
      SELECT group_id FROM group_members
      WHERE user_id = auth.uid() AND role = 'admin' AND left_at IS NULL
    )
  );
```

---

#### Table 5: EVENTS

**Most critical table - visibility-aware policies**

```sql
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

-- Users can see own events (regardless of visibility)
CREATE POLICY "Users can see own events"
  ON events FOR SELECT
  USING (created_by = auth.uid());

-- Users can see group events respecting visibility
CREATE POLICY "Users can see group events with visibility"
  ON events FOR SELECT
  USING (
    -- Own events (always see)
    created_by = auth.uid()
    OR
    -- Attendee of event (always see)
    id IN (
      SELECT event_id FROM event_attendees
      WHERE user_id = auth.uid()
    )
    OR
    -- Group event respecting visibility
    (
      group_id IN (
        SELECT group_id FROM group_members
        WHERE user_id = auth.uid() AND left_at IS NULL
      )
      AND event_type = 'group_confirmed'
      AND visibility IN ('shared_with_name', 'busy_only')
    )
  );

-- Users can create events
CREATE POLICY "Users can create events"
  ON events FOR INSERT
  WITH CHECK (auth.uid() = created_by);

-- Users can update own events
CREATE POLICY "Users can update own events"
  ON events FOR UPDATE
  USING (auth.uid() = created_by);

-- Users can delete own events
CREATE POLICY "Users can delete own events"
  ON events FOR DELETE
  USING (auth.uid() = created_by);
```

---

#### Table 6: EVENT_ATTENDEES

```sql
ALTER TABLE event_attendees ENABLE ROW LEVEL SECURITY;

-- Users can see attendees of events they have access to
CREATE POLICY "Users can see attendees of accessible events"
  ON event_attendees FOR SELECT
  USING (
    event_id IN (
      SELECT id FROM events
      WHERE created_by = auth.uid()
      OR id IN (
        SELECT event_id FROM event_attendees
        WHERE user_id = auth.uid()
      )
    )
  );

-- Users can RSVP to events
CREATE POLICY "Users can RSVP to events"
  ON event_attendees FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update own RSVP
CREATE POLICY "Users can update own RSVP"
  ON event_attendees FOR UPDATE
  USING (auth.uid() = user_id);
```

---

#### Table 7: EVENT_PROPOSALS

```sql
ALTER TABLE event_proposals ENABLE ROW LEVEL SECURITY;

-- Group members can see proposals
CREATE POLICY "Group members can see proposals"
  ON event_proposals FOR SELECT
  USING (
    group_id IN (
      SELECT group_id FROM group_members
      WHERE user_id = auth.uid() AND left_at IS NULL
    )
  );

-- Group members can create proposals
CREATE POLICY "Group members can create proposals"
  ON event_proposals FOR INSERT
  WITH CHECK (
    group_id IN (
      SELECT group_id FROM group_members
      WHERE user_id = auth.uid() AND left_at IS NULL
    )
    AND auth.uid() = created_by
  );

-- Creators can update proposals
CREATE POLICY "Creators can update proposals"
  ON event_proposals FOR UPDATE
  USING (auth.uid() = created_by);
```

---

#### Table 8: PROPOSAL_TIME_OPTIONS

```sql
ALTER TABLE proposal_time_options ENABLE ROW LEVEL SECURITY;

-- Group members can see time options
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

#### Table 9: PROPOSAL_VOTES

```sql
ALTER TABLE proposal_votes ENABLE ROW LEVEL SECURITY;

-- Group members can see votes (aggregate availability)
CREATE POLICY "Group members can see votes"
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

-- Group members can vote
CREATE POLICY "Group members can vote"
  ON proposal_votes FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND proposal_id IN (
      SELECT id FROM event_proposals
      WHERE group_id IN (
        SELECT group_id FROM group_members
        WHERE user_id = auth.uid() AND left_at IS NULL
      )
    )
  );

-- Users can update own votes
CREATE POLICY "Users can update own votes"
  ON proposal_votes FOR UPDATE
  USING (auth.uid() = user_id);
```

---

#### Table 10: CALENDAR_SHARING

```sql
ALTER TABLE calendar_sharing ENABLE ROW LEVEL SECURITY;

-- Users can manage own sharing settings
CREATE POLICY "Users can manage own sharing"
  ON calendar_sharing FOR ALL
  USING (auth.uid() = user_id);

-- Users can see who shared with them
CREATE POLICY "Users can see sharing settings"
  ON calendar_sharing FOR SELECT
  USING (
    auth.uid() = shared_with_user_id
    OR
    shared_with_group_id IN (
      SELECT group_id FROM group_members
      WHERE user_id = auth.uid() AND left_at IS NULL
    )
  );
```

---

#### Table 11: NOTIFICATIONS

```sql
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Users can see own notifications
CREATE POLICY "Users can see own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

-- Users can mark own notifications as read
CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id);
```

---

#### Table 12: PUSH_TOKENS

```sql
ALTER TABLE push_tokens ENABLE ROW LEVEL SECURITY;

-- Users can manage own push tokens
CREATE POLICY "Users can manage own push tokens"
  ON push_tokens FOR ALL
  USING (auth.uid() = user_id);
```

---

#### Table 13: ANALYTICS_EVENTS

```sql
ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

-- Users can log analytics events
CREATE POLICY "Users can create analytics events"
  ON analytics_events FOR INSERT
  WITH CHECK (true);  -- Anyone can log (no sensitive data)

-- Only admins can read analytics
CREATE POLICY "Admins can read analytics"
  ON analytics_events FOR SELECT
  USING (auth.role = 'admin');
```

---

### RLS Policy Testing & Validation

**Every RLS policy must be tested before deployment.**

```sql
-- Test: User A cannot see User B's private events
SELECT * FROM events
WHERE created_by = 'user_b_id'
AND visibility = 'private'
AND auth.uid() = 'user_a_id';
-- Should return 0 rows ✓

-- Test: Group member can see group's shared events
SELECT * FROM events
WHERE group_id = 'group_id'
AND visibility = 'shared_with_name'
AND auth.uid() = 'group_member_id';
-- Should return events ✓

-- Test: Non-group member cannot see group events
SELECT * FROM events
WHERE group_id = 'group_id'
AND auth.uid() = 'non_member_id';
-- Should return 0 rows ✓
```

---

## Group Privacy Controls

### Per-Group Visibility Settings

Users can configure different privacy levels for each group:

```swift
// Example: Sarah's privacy settings
default_event_visibility = "private"  // Most restrictive default

// But per-group:
group_id: "college_friends" → visibility: "shared_with_name"
group_id: "work_colleagues" → visibility: "busy_only"
group_id: "casual_friends" → visibility: "private"
```

**Implementation:**
```sql
-- group_members table has calendar_visibility column
CREATE TABLE group_members (
  ...
  calendar_visibility VARCHAR(20) DEFAULT 'busy_only'
    CHECK (calendar_visibility IN ('private', 'shared_with_name', 'busy_only')),
  ...
);
```

When creating an event while viewing a group's context:
1. System checks default_event_visibility (user's global default)
2. Checks group-specific override
3. Shows suggestion: "Share with [Group Name] as [Visibility Level]?"
4. User can override on per-event basis

---

### Group Member Roles & Access Control

**Three member roles:**

| Role | Permissions |
|------|------------|
| **Admin** | Create proposals, manage members, edit group settings, remove members, delete group |
| **Member** | Create proposals, vote, view group calendar and availability |
| **Optional** | Invited but not required to participate, can decline proposals |

**RLS enforcement:**
```sql
-- Only admins can manage group
WHERE role = 'admin' AND left_at IS NULL
```

---

### Group Privacy Defaults

When user creates a group, they set:
1. **Group visibility:** Who can see this group exists
2. **Member visibility:** Can members see other members?
3. **Calendar visibility:** What privacy level for events?
4. **Who can create proposals:** Admin only or all members?

---

### Changing Privacy Settings for Existing Events

When user changes an event's privacy level:
1. System notifies affected groups (if sharing changes)
2. Past visibility is logged for transparency
3. Future queries use new privacy level
4. No retroactive visibility change (what's seen is seen)

---

## Authentication & Authorization

### JWT-Based Authentication (Supabase Auth)

**Flow:**

```
1. User enters email/password
   ↓
2. POST /auth/v1/signup or /auth/v1/token
   ↓
3. Supabase Auth validates credentials
   ↓
4. Returns JWT access token + refresh token
   ↓
5. iOS app saves JWT to Keychain (secure storage)
   ↓
6. All API requests include: Authorization: Bearer <JWT>
   ↓
7. Backend validates JWT signature
   ↓
8. Extracts auth.uid() from JWT
   ↓
9. Database RLS checks auth.uid() against row policies
   ↓
10. Only authorized data returned
```

**JWT Structure:**
```
Header: { "alg": "HS256", "typ": "JWT" }
Payload: {
  "sub": "550e8400-e29b-41d4-a716-446655440000",  // User ID
  "email": "user@example.com",
  "email_verified": true,
  "aud": "authenticated",
  "iss": "https://your-project.supabase.co/auth/v1",
  "exp": 1701446400,  // Expiration: 1 hour
  "iat": 1701442800
}
Signature: HMAC-SHA256(header.payload, secret)
```

---

### Token Management on iOS

**Store securely in Keychain:**

```swift
// Save JWT to Keychain
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccount as String: "access_token",
    kSecValueData as String: token.data(using: .utf8)!,
    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
]
SecItemAdd(query as CFDictionary, nil)

// Retrieve token from Keychain
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccount as String: "access_token",
    kSecReturnData as String: true
]
var result: AnyObject?
SecItemCopyMatching(query as CFDictionary, &result)
let token = String(data: result as! Data, encoding: .utf8)
```

**Never store in UserDefaults** (not encrypted)

---

### Refresh Token Flow

When access token expires:

```swift
// 1. API returns 401 Unauthorized
// 2. Automatically call refresh endpoint
POST /auth/v1/token?grant_type=refresh_token
{
  "refresh_token": "sbr_token..."
}

// 3. Returns new access token
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 3600
}

// 4. Retry original request with new token
// 5. Save new token to Keychain
```

---

### Session Security

**Best practices:**

1. **Token expiration:** Access tokens expire after 1 hour
2. **Refresh token rotation:** New refresh token on each refresh
3. **Secure storage:** Keychain encryption (device-level)
4. **Multi-device:** Refresh tokens are device-specific
5. **Account recovery:** Refresh tokens invalidated on password change

---

### Password Requirements

**For MVP (simple):**
- Minimum 8 characters
- At least 1 uppercase letter
- At least 1 number

**Consider for later:**
- Special characters requirement
- Breach database checking
- Compromised password detection

---

### Multi-Device Session Handling

**Sessions are per-device:**
1. User logs in on iPhone
2. Receives refresh token tied to that device
3. Can also log in on iPad (separate token)
4. Logout on iPhone doesn't affect iPad session
5. Password change invalidates all refresh tokens

---

### Account Recovery Security

**If user forgets password:**

```
1. User taps "Forgot Password"
2. Enters email address
3. Email sent with recovery link
4. Link contains time-limited token (1 hour)
5. User clicks link → password reset screen
6. Sets new password
7. All existing refresh tokens invalidated
8. User must log in again on all devices
```

---

## Data Privacy & Compliance

### What Data We Collect and Why

| Data | Reason | Retention |
|------|--------|-----------|
| Email | Authentication, communication | Until account deleted |
| Password (hashed) | Authentication | Until account deleted |
| Full name | Profile display | Until account deleted |
| Calendar events | Core feature | Until event deleted |
| Event visibility settings | Privacy control | Until event deleted |
| Group memberships | Social graph | Until user leaves |
| Votes on proposals | Voting system | Until proposal deleted |
| Push device tokens | Notifications | Until device logs out |
| Last active timestamp | Inactive detection | 90 days after deletion |
| Analytics events | Product insights | 180 days |

---

### Data Minimization Principles

**Only collect what's necessary:**

- Don't collect: Browsing history
- Don't collect: Contacts (except friends explicitly invited)
- Don't collect: Location data (optional for travel time)
- Don't collect: Biometric data
- Don't collect: Device identifiers (except for APNs token)

**Minimal retention:**
- Delete read notifications after 90 days
- Delete unread notifications after 1 year
- Soft-delete events (keep in case of undo, hard-delete after 30 days)
- Delete analytics data after 180 days

---

### User Data Export (GDPR Right to Access)

```
Profile → Settings → Privacy & Data
→ [Export All My Data]

Downloads ZIP with:
├── user_profile.json
├── events.json
├── groups.json
├── votes.json
├── notifications.json
└── analytics.json
```

**Format:** Standard JSON, human-readable

---

### User Data Deletion (Right to Be Forgotten)

```
Profile → Settings → Privacy & Data
→ [Delete My Account]

Confirmation required: "Are you sure?"

On deletion:
1. Soft-delete user row (marked with deleted_at)
2. Remove from all groups (notify group members)
3. Cancel pending votes
4. Anonymize contributions (keep event data but remove user reference)
5. Hard-delete after 30-day grace period
```

**Grace period:** Allows undo if user changes mind

---

### Privacy Policy Requirements

**Must include:**
- What data we collect
- How we use it
- How long we keep it
- User rights (access, deletion, portability)
- Third-party services (Supabase, Stripe, APNs)
- Security measures
- Contact for privacy questions
- Regulatory compliance (GDPR, CCPA, COPPA)

---

### COPPA / Age Restrictions (13+)

**LockItIn is for users 13+**

- Require age verification at signup
- No data collection without parental consent for users under 13
- Cannot market to children
- Parental controls for teen accounts

**Implementation:**
```swift
if user.age < 13 {
    showParentalConsentRequirement()
}
```

---

## API Security

### API Authentication (JWT in Headers)

Every API request must include JWT:

```
GET /rest/v1/events HTTP/1.1
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Without JWT:** 401 Unauthorized

---

### Rate Limiting to Prevent Abuse

**Per-user limits:**
- 100 requests/minute (most endpoints)
- 10 requests/minute (auth endpoints)
- 1000 requests/day (total)

**Implementation:**
```sql
-- Track requests per user per minute
CREATE TABLE rate_limits (
  user_id UUID,
  endpoint VARCHAR(255),
  request_count INT,
  window_start TIMESTAMP,
  UNIQUE(user_id, endpoint, window_start)
);

-- On each request:
INSERT INTO rate_limits (user_id, endpoint, request_count, window_start)
VALUES (auth.uid(), 'GET /events', 1, NOW())
ON CONFLICT (user_id, endpoint, window_start)
DO UPDATE SET request_count = request_count + 1;

-- Check limit
SELECT request_count FROM rate_limits
WHERE user_id = auth.uid()
AND endpoint = 'GET /events'
AND window_start > NOW() - INTERVAL '1 minute'
LIMIT 1;

IF request_count >= 100 THEN
  RETURN 429 Too Many Requests;
END IF;
```

---

### Input Validation and Sanitization

**Never trust user input.**

```swift
// Example: Validate event title
func validateEventTitle(_ title: String) -> Result<String, ValidationError> {
    guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
        return .failure(.emptyTitle)
    }

    guard title.count <= 200 else {
        return .failure(.titleTooLong)
    }

    // Remove potentially malicious characters
    let sanitized = title.trimmingCharacters(in: .whitespaces)

    // No SQL injection possible (using parameterized queries)
    // No XSS possible (mobile app, not web)

    return .success(sanitized)
}
```

---

### SQL Injection Prevention (Parameterized Queries)

**Supabase uses parameterized queries by default.**

```swift
// SAFE - Parameterized
let events = try await supabase
    .from("events")
    .select("*")
    .eq("created_by", userID)  // Parameter binding
    .execute()

// UNSAFE - String interpolation (DON'T DO THIS)
let query = "SELECT * FROM events WHERE created_by = '\(userID)'"
// Vulnerable if userID contains SQL injection
```

---

### XSS Prevention

**Not applicable to iOS app** (no HTML rendering).

**If web version added:**
- Sanitize all user input before rendering
- Use Content Security Policy headers
- Escape special characters

---

### CSRF Protection

**For iOS:**
- Not applicable (token stored securely, same-origin not relevant)

**For web version:**
- Use SameSite cookie attribute
- Include CSRF token in POST requests
- Verify Origin header

---

## Data Encryption

### Encryption at Rest

**Supabase default encryption:**
- PostgreSQL data encrypted with AES-256
- Encryption keys managed by Supabase
- Backups encrypted separately

**Supabase documentation:** https://supabase.com/docs/guides/database/data-encryption

---

### Encryption in Transit

**HTTPS/TLS 1.3:**
- All API calls over HTTPS
- Minimum TLS version: 1.2
- Strong cipher suites only

**WebSocket connections:**
- Secure WebSocket (WSS), not WS
- Same TLS encryption as HTTPS

**Certificate pinning (optional):**
```swift
// Pin API certificate for extra security
// Useful if concerned about MITM attacks
let config = URLSessionConfiguration.default
// Add certificate pinning if needed
```

---

### Sensitive Data Handling

**Passwords:**
- Never stored in plaintext
- Hashed with bcrypt by Supabase Auth
- Impossible for us to recover (good!)

**Tokens:**
- Stored in iOS Keychain (device-encrypted)
- Never logged
- Cleared on logout

**API Keys:**
- Stored in app's Info.plist (not hardcoded)
- Supabase anon key (read-only, safe)
- Real secret key never exposed to client

---

### Local Storage Encryption (Keychain)

```swift
// Keychain uses device-level encryption
// Automatic protection based on screen lock state

// Best practice: Use kSecAttrAccessibleWhenUnlockedThisDeviceOnly
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    // Encrypted only when device is unlocked
]
```

---

## Privacy-Aware Features

### Conflict Notifications (Privacy-Respecting)

When a group event conflicts with a user's calendar:

**Who gets notified:**
- User with the conflict ✓
- Event organizer ✓
- Other group members ✗ (reduces noise, prevents embarrassment)

**Notification text (to user):**
"You have a conflict: 'Team Meeting' (2-3pm) conflicts with the group event 'Game Night' (2-4pm)"

**Notification text (to organizer):**
"Sarah has a conflict with Game Night. She may not be able to attend."

**Why this pattern:**
- Prevents embarrassment ("Sarah has a doctor's appointment at 2pm")
- Reduces group notification fatigue
- Only relevant people are informed

---

### Event Memories (Attendee-Only Access)

Memory uploads are only visible to people who attended:

| Scenario | Access | Reasoning |
|----------|--------|-----------|
| Attended event | ✓ Full access | You were there, you earned the memories |
| Declined invite | ✗ No notification | Your choice not to attend |
| Wanted to go but couldn't | ✗ No auto-notification | Prevents FOMO, but can manually check if curious |
| Not invited at all | ✗ No access | Event is private to attendees |

**No FOMO weaponization:**
- App doesn't push event memories to non-attendees
- User chooses to check if they want to

---

### Availability Heatmap (Aggregate View)

Shows counts, requires tap to see names:

```
Wednesday 2-3pm: "5/8 people free"
[Tap to see who]

Reveals:
AVAILABLE: Sarah, Mike, Jordan, Alex, You
BUSY: Emma, Chris
UNKNOWN: Taylor (private calendar)
```

**Why this pattern:**
- Initial view preserves privacy (just counts)
- User chooses to drill down
- Names shown respectfully with status

---

### Year-End Wrapped (Celebration, Not Guilt)

Only shows stats for events *you attended*:

```
Your 2025:
✓ Attended 47 events
✓ Most active group: College Friends (23 events)
✓ Spent most time with: Mike (34 events together)
✓ Busiest month: July (12 events)
✓ Photo highlights from events you attended
```

**NOT included:**
- "Your friends had 62 events, you missed 15" ← NO
- Photos from events you didn't attend ← NO
- Guilt-inducing comparisons ← NO

**Vibe:** Celebration, not shame

---

### Notification Content (Privacy-Aware)

Different notification content based on privacy:

| Event Type | Notification Content | Shows Event Title? |
|------------|----------------------|-------------------|
| Shared-with-name event | "Game Night confirmed for Sat 7pm" | ✓ Yes |
| Busy-only event | "Your scheduled event confirmed for Sat 7pm" | ✗ No |
| Private event | Nothing shown | N/A |

**Reasoning:**
- Respects event privacy settings
- Other people shouldn't learn private event details from notifications
- Lock screen shows same respect (generic "LockItIn" notification)

---

## Privacy Edge Cases

### What Happens When Privacy Settings Change

**Scenario:** User changes event from "Shared-with-name" to "Private"

1. Change takes effect immediately
2. Groups' views updated (event becomes invisible)
3. Previous visibility is logged (for transparency)
4. User receives confirmation: "Event now private. College Friends can no longer see details."
5. No notification sent to group (reduces noise)

---

### Group Member Removal and Data Access

**When admin removes user from group:**

1. User is marked left_at = NOW()
2. User immediately loses access to:
   - Group calendar
   - All group events
   - All proposals in the group
   - All votes in the group
3. Database RLS prevents access (cannot query removed member's data)
4. User receives notification: "You were removed from [Group]"

**Removed user's data:**
- Their votes are kept (historical record)
- Events they created are kept but move to personal calendar
- Name stays on past events (for memory)

---

### Deleted Events and Historical Data

**When user deletes an event:**

1. Event soft-deleted (marked deleted_at = NOW())
2. Becomes invisible to user immediately
3. Groups cannot see deleted event
4. Hard-delete after 30-day grace period
5. User can undo within 5 seconds

**Historical data:**
- Event appears in analytics as "deleted"
- Memory photos remain (they're separate records)
- Votes on deleted proposals are cleaned up

---

### Metadata Leakage Prevention

**Potential metadata leaks to prevent:**

| Leak Type | Risk | Mitigation |
|-----------|------|-----------|
| Timing attacks | User can guess event dates from response times | Use consistent response times (database-side) |
| File sizes | User can guess document length from network | Pad responses to standard sizes |
| Last-modified times | User can detect when events change | Timestamp precision limited (minute-level) |
| Deleted records | User can guess deleted event count | Soft-delete, hard-delete after delay |

---

### Screenshot Prevention Considerations

**Technical limitation:** Cannot truly prevent screenshots on iOS

**Mitigation approach:**
- Educate users about privacy
- Terms of service prohibit sharing private events
- Legal recourse for violations
- Content is temporary (archived after time)

**Optional advanced features (future):**
- Screenshot detection (triggers warning)
- Screenshot notification to owner
- Watermarking with username

---

## Security Best Practices

### Secure Coding Guidelines

**1. Input Validation**
- Validate all user input on client AND server
- Use allowlist validation (allow known good, reject everything else)
- Validate file uploads (type, size, content)

**2. Error Handling**
- Never expose system errors to users
- Log detailed errors server-side
- Show generic errors to client
- Example: Not "Invalid password" but "Email or password incorrect"

**3. Dependency Management**
- Keep all dependencies updated
- Run `pod update` monthly
- Monitor for security vulnerabilities
- Use dependency auditing tools (npm audit equivalent)

**4. Secrets Management**
- Never commit secrets to git
- Use `.env` files (in `.gitignore`)
- Rotate API keys regularly
- Use least-privilege permissions

**5. Logging Security**
- Never log sensitive data (passwords, tokens, API keys)
- Sanitize logs for PII
- Rotate logs (keep 30 days)
- Restrict log access to admins

---

### Dependency Security (SPM)

Keep iOS dependencies updated:

```swift
// In Package.swift
.package(
    url: "https://github.com/supabase-community/supabase-swift.git",
    from: "0.2.0"  // Keep up-to-date
)
```

**Best practices:**
- Update monthly
- Run security audit tools
- Test before deploying
- Subscribe to security advisories

---

### Secret Management (API Keys)

**Store in Config.swift (not hardcoded):**

```swift
struct Config {
    static let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "https://..."
    static let supabaseAnonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? "..."
}
```

**For CI/CD:**
- Store secrets in GitHub Secrets
- Pass as environment variables at build time
- Never print secrets to build logs

---

### Error Messages (Non-Leaky)

**BAD:**
- "User with email 'sarah@example.com' not found" ← Leaks information
- "Invalid password" ← Confirms email exists
- "Database connection error: Connection refused at 192.168.1.1" ← Leaks infrastructure

**GOOD:**
- "Email or password incorrect" ← Generic, doesn't confirm email exists
- "An error occurred. Please try again." ← Doesn't leak information
- "Our service is temporarily unavailable. Please try again later." ← Non-specific

---

## Penetration Testing & Audits

### Security Testing Checklist

Before launch, test:

- [ ] Authentication bypass (try to access another user's data)
- [ ] Authorization bypass (try to modify group settings without permission)
- [ ] RLS policy bypass (try SQL injection to circumvent policies)
- [ ] Session hijacking (intercept and replay tokens)
- [ ] Man-in-the-middle (test HTTPS enforcement)
- [ ] Brute force (rate limiting works)
- [ ] CSRF (not applicable to iOS, but test if web version exists)
- [ ] XSS (not applicable to iOS, test if web version exists)
- [ ] Data exposure (verify sensitive data not logged)
- [ ] Privacy controls (verify visibility settings enforced)

---

### Third-Party Security Audit Plan

**Pre-launch (Q2 2025):**
1. Hire external security firm
2. Conduct comprehensive penetration test
3. Review code for vulnerabilities
4. Test RLS policies thoroughly
5. Verify encryption implementation
6. Assess third-party integrations

**Post-launch (Annual):**
- Annual security audit
- Dependency vulnerability scanning
- Incident response plan testing

---

### Vulnerability Disclosure Policy

**If security researcher finds vulnerability:**

```
Email: security@lockit.in

Please include:
1. Vulnerability description
2. Steps to reproduce
3. Impact assessment
4. Suggested fix (optional)

We commit to:
- Acknowledging receipt within 24 hours
- Providing timeline for fix
- Crediting you (if desired) in security advisory
- 90-day responsible disclosure window
```

---

### Incident Response Plan

**If data breach occurs:**

```
1. Immediate (< 1 hour):
   - Isolate affected systems
   - Preserve forensic evidence
   - Activate incident response team

2. Investigation (< 24 hours):
   - Determine scope of breach
   - Identify what data was exposed
   - Assess number of affected users
   - Document timeline

3. Notification (ASAP, legally required):
   - Notify affected users
   - Notify relevant regulators (GDPR, CCPA)
   - Post public statement
   - Provide identity theft protection (if applicable)

4. Remediation:
   - Fix root cause
   - Improve security controls
   - Deploy patches
   - Monitor for further compromise

5. Postmortem:
   - Document lessons learned
   - Update incident response plan
   - Report to stakeholders
```

---

## User Privacy Controls UI

### Privacy Settings Screen Layout

```
┌─────────────────────────────────┐
│  [<]  Privacy & Sharing         │
├─────────────────────────────────┤
│                                 │
│  DEFAULT EVENT VISIBILITY       │
│                                 │
│  When you create new events:    │
│  ⦿ Private (just me)            │
│  ○ Shared with name             │
│  ○ Shared - busy only           │
│                                 │
├─────────────────────────────────┤
│  CALENDAR VISIBILITY            │
│                                 │
│  Who can see your availability: │
│  ○ Nobody                       │
│  ⦿ Friends only                 │
│  ○ Custom per group       [>]   │
│                                 │
├─────────────────────────────────┤
│  GROUP PRIVACY SETTINGS         │
│                                 │
│  College Friends          [>]   │
│  Work Colleagues          [>]   │
│  Basketball Crew          [>]   │
│                                 │
├─────────────────────────────────┤
│  ADVANCED                       │
│                                 │
│  ☑ Share free/busy only for     │
│     work calendar               │
│  ☑ Allow friends to see when    │
│     you've read proposals       │
│  ☐ Show "last active" status    │
│                                 │
│  [Blocked users]          [>]   │
│  [Delete my account]      [>]   │
│                                 │
└─────────────────────────────────┘
```

---

### Per-Event Privacy Controls

When creating/editing an event:

```
┌─────────────────────────────────┐
│  Event Title: "Team Meeting"    │
├─────────────────────────────────┤
│                                 │
│  Privacy Setting:               │
│                                 │
│  ⦿ Private (🔒)                │
│  │  Only you can see this      │
│  │                              │
│  ○ Shared with name (👥)        │
│  │  College Friends see:        │
│  │  "Team Meeting" 2-3pm        │
│  │                              │
│  ○ Shared - busy only (👁️)     │
│  │  College Friends see:        │
│  │  "Busy" 2-3pm               │
│                                 │
│  💡 Tip: For work meetings,     │
│     "Busy only" is good!        │
│                                 │
│  [Cancel]  [Save]               │
│                                 │
└─────────────────────────────────┘
```

---

### Per-Group Privacy Controls

When editing group settings:

```
┌─────────────────────────────────┐
│  [<]  College Friends Privacy   │
├─────────────────────────────────┤
│                                 │
│  DEFAULT VISIBILITY FOR THIS    │
│  GROUP:                         │
│                                 │
│  ⦿ Shared with name             │
│  ○ Shared - busy only           │
│  ○ Private (don't share)        │
│                                 │
│  MEMBER PERMISSIONS:            │
│                                 │
│  Who can create proposals?      │
│  ⦿ All members                  │
│  ○ Admins only                  │
│                                 │
│  Can members see each other?    │
│  ☑ Yes                          │
│  ☐ No (anonymous)              │
│                                 │
│  Can you see their names when   │
│  they're busy?                  │
│  ☑ Yes (shared-with-name only) │
│  ☐ No (respect busy-only)      │
│                                 │
│  [Cancel]  [Save]               │
│                                 │
└─────────────────────────────────┘
```

---

### Global Privacy Defaults

```
┌─────────────────────────────────┐
│  [<]  Privacy Defaults          │
├─────────────────────────────────┤
│                                 │
│  NEW EVENTS:                    │
│  When you create a new event,   │
│  default privacy level:         │
│                                 │
│  ⦿ Private (most restrictive)   │
│  ○ Shared with name             │
│  ○ Shared - busy only           │
│                                 │
│  CALENDAR ACCESS:               │
│  By default, who can see        │
│  your availability?             │
│                                 │
│  ⦿ Only me                      │
│  ○ Friends only                 │
│  ○ Everyone in my groups        │
│                                 │
│  💡 You can always override     │
│     these defaults for each     │
│     event or group.             │
│                                 │
│  [Learn more about privacy]     │
│                                 │
└─────────────────────────────────┘
```

---

## Quick Reference

### Privacy Decision Matrix

When building a feature, ask:

| Question | If Yes | If No |
|----------|--------|-------|
| Does this feature access user data? | Implement RLS policy | Skip RLS |
| Is data sensitive? | Encrypt at rest + in transit | Standard HTTPS |
| Should all groups see it? | Check visibility settings | Show to all |
| Could it leak metadata? | Use consistent response times | Standard response |
| Should user be able to delete it? | Add soft-delete + hard-delete after 30 days | Normal delete |
| Is privacy setting critical? | Enforce at DB level | Can enforce at API |
| Involves notifications? | Check privacy level first | Send notification |

---

### RLS Policy Quick Lookup

| Table | Can User See? | Policy |
|-------|---------------|--------|
| users | Own only | `auth.uid() = id` |
| friendships | Own only | `user_id = auth.uid() OR friend_id = auth.uid()` |
| groups | Member groups only | `id IN group_members WHERE user_id = auth.uid()` |
| events | Own + group (respecting visibility) | Complex (see RLS section) |
| notifications | Own only | `user_id = auth.uid()` |

---

### Security Checklist for Developers

Before committing code:

- [ ] No secrets in code (use environment variables)
- [ ] All inputs validated
- [ ] No sensitive data in logs
- [ ] Error messages don't leak info
- [ ] RLS policy enforced for database table
- [ ] Authorization check for API endpoints
- [ ] Rate limiting on sensitive endpoints
- [ ] HTTPS used for all communication
- [ ] Tokens stored in Keychain (not UserDefaults)
- [ ] Tests cover security scenarios

---

### Common Privacy Mistakes to Avoid

| Mistake | Why Bad | Fix |
|---------|-------|----|
| Assuming app-level privacy is enough | Can be bypassed | Enforce in RLS |
| Storing secrets in code | Exposed in git history | Use env variables |
| Logging sensitive data | Leaks in logs | Sanitize logs |
| Not validating input | SQL injection possible | Validate all input |
| One-size-fits-all privacy | Some users need more control | Per-group settings |
| Notifying everyone about changes | Privacy violation | Notify only relevant parties |
| Keeping deleted data | GDPR violation | Hard-delete after grace period |
| Showing private events in search | Privacy leak | Search respects visibility |

---

## Email Privacy

**Decision (December 2025):** User email addresses are NOT displayed anywhere in the friend-related UI.

### Rationale
- Email addresses are considered sensitive personal information
- Displaying emails enables potential harassment or spam
- Users connect via name/avatar, not email
- Follows privacy-first design principle

### Implementation Details

| Component | Email Behavior |
|-----------|---------------|
| Friend search results | Email NOT shown (name only) |
| Friend request tiles | Email NOT shown |
| Friends list | Email NOT shown |
| Friend detail view | Email NOT shown |
| User's own profile | Email IS shown (user's own data) |
| Local search filter | Email CAN be searched (not displayed) |

### Technical Notes
- `FriendProfile.fromUserJson()` masks emails for search results: `j***@example.com`
- Email field exists in models for internal use (database queries, local filtering)
- Email is never rendered in UI widgets for other users
- User's OWN email shown on Profile screen (self-service)

### Files Affected
- `lib/presentation/widgets/friend_request_tile.dart`
- `lib/presentation/widgets/friend_search_delegate.dart`
- `lib/presentation/widgets/friends_bottom_sheet.dart`
- `lib/presentation/widgets/friend_list_tile.dart`
- `lib/presentation/screens/friends_screen.dart`
- `lib/data/models/friendship_model.dart` (maskEmail function)

### Future Considerations
- If email display is ever needed, require explicit user consent
- Consider adding "share email with friends" toggle in settings
- Email could be revealed only after mutual friendship acceptance

---

## Summary

LockItIn's privacy and security model is built on:

1. **Shadow Calendar System** - Users share availability without revealing private details
2. **Row Level Security** - Database enforces privacy, can't be bypassed by app
3. **Granular Controls** - Users choose privacy level per event and per group
4. **Encryption** - Data encrypted in transit (HTTPS) and at rest
5. **Compliance** - GDPR, CCPA, COPPA ready
6. **Transparency** - Users see what data we have, can export/delete anytime

**Core Philosophy:**
"Privacy first, not as an afterthought."

Every design decision returns to this: **Does this respect user privacy?** If not, we find another way.

---

*This document is the single source of truth for all privacy and security implementation. Update when adding new features or changing policies.*
