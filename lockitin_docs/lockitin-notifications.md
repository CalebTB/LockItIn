# LockItIn Notifications Architecture

*Consolidated notification system design, Apple Push Notification (APNs) integration, notification types, delivery strategies, inbox management, and user preferences. Last updated: December 1, 2025*

---

## Table of Contents

1. [Notification Philosophy](#notification-philosophy)
2. [Notification Types & Triggers](#notification-types--triggers)
3. [APNs Integration & Architecture](#apns-integration--architecture)
4. [Notification Delivery Strategy](#notification-delivery-strategy)
5. [In-App Notification Management](#in-app-notification-management)
6. [Notification Content & Copy](#notification-content--copy)
7. [Interactive Notifications & Actions](#interactive-notifications--actions)
8. [User Notification Preferences](#user-notification-preferences)
9. [Badge Management](#badge-management)
10. [Edge Cases & Error Handling](#edge-cases--error-handling)
11. [Code Implementation](#code-implementation)
12. [Testing Strategy](#testing-strategy)
13. [Analytics & Monitoring](#analytics--monitoring)

---

## Notification Philosophy

### Core Principle: "Calm, Not Chaotic"

**Guiding Rule:** Only notify when **user action is required**, **something is explicitly opted into**, or **information can be acted upon immediately**.

Avoid notification fatigue by:
- Not notifying entire group about one person's calendar changes
- Batching updates when possible
- Respecting user notification settings
- Never using notifications for FOMO messaging
- Only pushing notifications that drive engagement, not anxiety

### What DOES Trigger Notifications

1. **Action Required from User:**
   - New event proposal needing a vote
   - Voting deadline approaching (2 hours before)
   - Event confirmed and auto-added to calendar
   - Friend request awaiting response
   - Group invite requiring acceptance

2. **Time-Sensitive Information:**
   - Event starting soon (30 min before event)
   - Time to leave notification (with traffic updates)
   - Conflict alert (only to organizer + conflicted person)
   - Last-minute vote changes that affect outcome

3. **Explicitly Opted-In Events:**
   - Per-group notification preferences
   - Per-notification-type toggles
   - User-enabled vote updates (for proposal creators only)

### What Does NOT Trigger Notifications

- Someone adding a personal event to their calendar
- Someone editing the title of a personal event
- Someone joining a group (unless they requested notification)
- New photos uploaded to event memories
- Someone editing their profile
- Passive activity in groups (viewing calendar, etc.)
- Redundant notifications within 10 minutes

---

## Notification Types & Triggers

### 1. New Proposal Notification (ACTION REQUIRED)

**When:** Immediately after proposal is created and sent

**Who Gets It:** All group members except the proposer

**Payload:**
```
Title: "[Proposer] proposed [Event Name]"
Body: "Vote needed • Closes in 24 hours"
Data: {
  proposal_id,
  group_id,
  event_title,
  deadline_timestamp
}
```

**Example:**
- "Sarah proposed Game Night"
- "Vote needed • Closes in 24 hours"

**Action Buttons:**
- "Vote" → Opens Inbox to proposal
- "View Details" → Opens proposal full view

**Badge Count:** Increases by 1 until user votes or proposal expires

**Sound/Alert:** Default (respect user settings)

---

### 2. Vote Cast Notification (OPTIONAL - Proposer Only)

**When:** Real-time as group members vote

**Who Gets It:** Proposal creator (proposer)

**Enabled By Default:** No (user must opt-in in proposal settings)

**Payload:**
```
Title: "[Friend] voted [Yes/Maybe/No]"
Body: "on [Event Name]"
Data: {
  proposal_id,
  event_title,
  voter_name,
  vote_type
}
```

**Example:**
- "Mike voted Yes"
- "on Game Night"

**Why Optional:** Prevents notification spam. Proposer can still see live vote counts in app.

**Can Be Toggled:** Per-proposal or per-group default setting

---

### 3. Vote Count Update Notification (REAL-TIME, OPTIONAL)

**When:** Leading option changes due to new vote

**Who Gets It:** All group members who have already voted

**Enabled By Default:** Yes (but can be disabled globally)

**Payload:**
```
Title: "[Time Slot] now winning!"
Body: "[X/Y] people available"
Data: {
  proposal_id,
  time_option_id,
  available_count,
  total_count
}
```

**Example:**
- "Sun 7pm now winning!"
- "6/8 people available"

**Design Rationale:** Real-time energy creates engagement without being annoying. Only sent to people already engaged (voted).

---

### 4. Voting Deadline Reminder (ACTION REQUIRED)

**When:** 2 hours before voting deadline

**Who Gets It:** Group members who haven't voted yet

**Only Sent If:** User hasn't voted and proposal is still open

**Payload:**
```
Title: "[Event Name] voting closes in 2 hours"
Body: "[Group Name] needs your response"
Data: {
  proposal_id,
  time_remaining_minutes
}
```

**Example:**
- "Game Night voting closes in 2 hours"
- "College Friends needs your response"

**Action Buttons:**
- "Vote Now" → Opens Inbox to proposal
- "Dismiss" → Hides notification

---

### 5. Event Confirmed Notification (INFORMATIONAL)

**When:** Immediately when proposal auto-confirms or organizer confirms

**Who Gets It:** All group members (attendees of confirmed event)

**Payload:**
```
Title: "[Event Name] confirmed!"
Body: "[Day] at [Time]"
Data: {
  event_id,
  event_title,
  event_time,
  location
}
```

**Example:**
- "Game Night confirmed!"
- "Saturday at 7:00 PM"

**Special Handling:**
- Show celebratory confetti animation when notification received (if app open)
- Auto-add to calendar without user action
- No further action needed from user

**Sound/Alert:** Celebratory chime (if enabled)

---

### 6. Event Starting Soon Reminder (INFORMATIONAL)

**When:** 30 minutes before event start time

**Who Gets It:** All confirmed attendees

**Only If:** Event is confirmed and user is attending

**Payload:**
```
Title: "[Event Name] starts in 30 minutes"
Body: "[Location]"
Data: {
  event_id,
  event_title,
  location,
  time_until_event
}
```

**Example:**
- "Game Night starts in 30 minutes"
- "Mike's Apartment"

**Action Buttons:**
- "Open" → Shows event detail with directions

---

### 7. Time to Leave Notification (ACTIONABLE)

**When:** Based on travel time calculation (event time - travel duration - 15 min buffer)

**Who Gets It:** User attending event with location set

**Only If:** Travel time integration enabled AND location set for event

**Payload:**
```
Title: "Time to leave for [Event Name]!"
Body: "[Duration] away via [Mode] • Traffic: [Status]"
Data: {
  event_id,
  event_title,
  travel_time_minutes,
  traffic_level,
  location_lat_lng
}
```

**Example:**
- "Time to leave for Game Night!"
- "25 min away via car • Light traffic"

**Action Buttons:**
- "Get Directions" → Opens Maps with directions
- "Snooze 5 min" → Re-triggers in 5 minutes

**Special Handling:**
- Update travel time in real-time if traffic changes
- Only send if travel time > 5 minutes (no point for close events)

---

### 8. Conflict Alert Notification (ACTION REQUIRED)

**When:** Event proposal confirmed for time when user has conflict

**Who Gets It:**
- **Conflicted Person:** "You have a conflict"
- **Organizer Only:** "Sarah has a conflict"

**NOT sent to:** Other group members (reduces noise)

**Payload (To Conflicted Person):**
```
Title: "You have a scheduling conflict"
Body: "Game Night conflicts with [Existing Event]"
Data: {
  proposal_id,
  existing_event_id,
  conflict_level
}
```

**Payload (To Organizer):**
```
Title: "[Friend] has a scheduling conflict"
Body: "with [Event Name] on [Day]"
Data: {
  conflicted_user_id,
  conflicted_user_name,
  proposal_id
}
```

**Design Rationale:** Only notify those who can do something about it. Prevents panic in group.

**Action Buttons:**
- For conflicted person: "View Conflict" → Shows both events
- For organizer: "Message [Friend]" → Opens DM composer

---

### 9. Proposal Update Notification (ACTION REQUIRED)

**When:** Proposal creator edits time options (votes reset)

**Who Gets It:** All group members who already voted

**Only If:** Time options changed (not title/description)

**Payload:**
```
Title: "[Event Name] times changed"
Body: "Please vote again on new options"
Data: {
  proposal_id,
  event_title,
  new_time_count
}
```

**Example:**
- "Game Night times changed"
- "Please vote again on new options"

**Badge Behavior:** Adds 1 to pending votes count

---

### 10. Friend Request Notification (ACTION REQUIRED)

**When:** Immediately when friend request sent

**Who Gets It:** Recipient of friend request

**Payload:**
```
Title: "[Friend Name] sent you a friend request"
Body: "Tap to view"
Data: {
  friend_request_id,
  requester_id,
  requester_name
}
```

**Action Buttons:**
- "Accept" → Approves request, opens profile
- "View Profile" → Shows requester profile
- "Decline" → Rejects request

**Badge Count:** Increases by 1 until request accepted/declined

---

### 11. Group Invite Notification (ACTION REQUIRED)

**When:** Immediately when added to group

**Who Gets It:** New group member

**Payload:**
```
Title: "You were added to [Group Name]"
Body: "[Inviter Name] invited you"
Data: {
  group_id,
  group_name,
  inviter_id,
  inviter_name
}
```

**Action Buttons:**
- "View Group" → Opens group detail
- "Accept" → Joins group, opens group view

---

### 12. Event Memory Prompt (SOFT PROMPT)

**When:** 10 minutes after event end time

**Who Gets It:** All confirmed attendees (only if event is tracked)

**Payload:**
```
Title: "How was [Event Name]?"
Body: "Add a photo to memories"
Data: {
  event_id,
  event_title,
  group_id
}
```

**Design Rationale:** Gentle prompt, not pushy. Appears in Inbox as card.

**Expires:** Notification auto-dismisses after 3 days if not acted on

**Action Buttons:**
- "Add Photo" → Opens memory uploader
- "Maybe Later" → Dismisses for now

---

## APNs Integration & Architecture

### Apple Push Notification Service Overview

**What It Is:** Apple's infrastructure for sending push notifications to iOS devices

**Why It's Required:** Only way to notify users outside the app on iOS

**Cost:** Free tier included with Apple Developer account

### Device Token Registration

**Step 1: Request User Permission**
```swift
// iOS 10+
import UserNotifications

UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
    if granted {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}
```

**Step 2: Get Device Token**
```swift
func application(_ application: UIApplication,
                 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return true
}

func application(_ application: UIApplication,
                 didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    // Send token to Supabase
    Task {
        await APIClient.shared.registerDeviceToken(token)
    }
}

func application(_ application: UIApplication,
                 didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("Failed to register for remote notifications: \(error)")
}
```

**Step 3: Store Token in Database**

Database table to track device tokens:
```sql
CREATE TABLE device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_token VARCHAR(255) NOT NULL,
    device_model VARCHAR(50),
    os_version VARCHAR(20),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT now(),
    last_used_at TIMESTAMP DEFAULT now(),
    UNIQUE(user_id, device_token)
);

CREATE INDEX idx_device_tokens_user ON device_tokens(user_id);
CREATE INDEX idx_device_tokens_active ON device_tokens(user_id, is_active);
```

### APNs Notification Payload Structure

**General Payload Format:**
```json
{
  "aps": {
    "alert": {
      "title": "Notification Title",
      "body": "Notification body text",
      "sound": "default"
    },
    "badge": 1,
    "sound": "default",
    "mutable-content": 1,
    "category": "PROPOSAL_NOTIFICATION"
  },
  "custom_data": {
    "proposal_id": "uuid",
    "event_title": "Game Night",
    "deep_link": "lockit://proposals/uuid"
  }
}
```

**Key Fields:**

| Field | Purpose | Example |
|-------|---------|---------|
| `alert.title` | Primary notification text | "Sarah proposed Game Night" |
| `alert.body` | Secondary notification text | "Vote needed • 24 hours remaining" |
| `badge` | App icon badge number | 1 (increment by vote count) |
| `sound` | Notification sound | "default" (system sound) |
| `mutable-content` | Allow notification extension | 1 (enables rich media) |
| `category` | Notification type identifier | "PROPOSAL_NOTIFICATION" |
| `deep_link` | URL to deep link in app | "lockit://proposals/uuid" |
| `priority` | Delivery priority | 10 (high), 5 (background) |
| `expiration` | TTL (seconds until expire) | 3600 (1 hour) |

### Critical vs Regular Notifications

**Critical Notifications** (Bypass Do Not Disturb):
```json
{
  "aps": {
    "alert": { "title": "Urgent", "body": "Conflict detected" },
    "sound": "critical.caf",
    "critical-alert": true
  }
}
```

**Use Cases for Critical:**
- Scheduling conflict detected
- Event starting in <10 minutes (if requested)

**Regular Notifications**:
```json
{
  "aps": {
    "alert": { "title": "Sarah proposed Game Night", "body": "Vote needed" },
    "sound": "default"
  }
}
```

**Use Cases for Regular:**
- New proposals
- Vote deadline reminders
- Event confirmations
- All other notifications

### Silent Notifications (Background Updates)

**For Real-Time Vote Updates (WebSocket preferred, but fallback):**
```json
{
  "aps": {
    "content-available": 1,
    "mutable-content": 1
  },
  "data": {
    "proposal_id": "uuid",
    "vote_count": 5,
    "timestamp": "2025-12-01T14:30:00Z"
  }
}
```

**Behavior:** Wakes app in background to fetch data without showing notification

**Rate Limit:** Max 3 silent notifications per hour per app

---

## Notification Delivery Strategy

### Real-Time Delivery Flow

**High-Level Architecture:**

```
User Action (votes, creates proposal)
    ↓
Supabase REST API / Edge Function
    ↓
Database Trigger (checks notification recipients)
    ↓
Supabase Edge Function (formats notification)
    ↓
Device Token Lookup (fetch all devices for each recipient)
    ↓
APNs Request (send notification payload)
    ↓
Device Delivery
    ↓
User Notification
```

### Real-Time Implementation via Supabase

**Step 1: Database Trigger on Event Action**

Example: Create notification when proposal is created
```sql
CREATE OR REPLACE FUNCTION notify_proposal_created()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert notification for each group member
    INSERT INTO notifications (user_id, type, title, body, data, proposal_id, created_at)
    SELECT
        gm.user_id,
        'PROPOSAL_CREATED',
        (SELECT users.full_name FROM users WHERE users.id = NEW.created_by) || ' proposed ' || NEW.event_title,
        'Vote needed • Voting closes in 24 hours',
        jsonb_build_object(
            'proposal_id', NEW.id,
            'group_id', NEW.group_id,
            'event_title', NEW.event_title
        ),
        NEW.id,
        now()
    FROM group_members gm
    WHERE gm.group_id = NEW.group_id
    AND gm.user_id != NEW.created_by;  -- Don't notify proposer

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_proposal_created
AFTER INSERT ON event_proposals
FOR EACH ROW
EXECUTE FUNCTION notify_proposal_created();
```

**Step 2: Edge Function to Send APNs**

```typescript
// Supabase Edge Function: send_apns.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

serve(async (req: Request) => {
  const { notification_id } = await req.json();

  // Fetch notification from database
  const { data: notification } = await supabaseAdmin
    .from("notifications")
    .select("*, user:users(id, full_name)")
    .eq("id", notification_id)
    .single();

  if (!notification) return new Response("Not found", { status: 404 });

  // Fetch all device tokens for user
  const { data: deviceTokens } = await supabaseAdmin
    .from("device_tokens")
    .select("device_token")
    .eq("user_id", notification.user_id)
    .eq("is_active", true);

  // Send to each device
  for (const { device_token } of deviceTokens) {
    await sendAPNsNotification(device_token, {
      title: notification.title,
      body: notification.body,
      data: notification.data,
      badge: await calculateBadgeCount(notification.user_id),
    });
  }

  return new Response("Success", { status: 200 });
});

async function sendAPNsNotification(deviceToken: string, payload: any) {
  // Call Apple's APNs API (via Node.js library in production)
  // This is simplified; real implementation uses apn library
  const response = await fetch("https://api.push.apple.com/3/device/" + deviceToken, {
    method: "POST",
    headers: {
      "apns-priority": "10",
      "apns-topic": "com.lockit.app",
      authorization: `Bearer ${getAPNsToken()}`,
    },
    body: JSON.stringify({
      aps: {
        alert: {
          title: payload.title,
          body: payload.body,
        },
        badge: payload.badge,
        sound: "default",
        category: "PROPOSAL_NOTIFICATION",
      },
      data: payload.data,
    }),
  });

  return response.ok;
}
```

### Delivery Guarantees & Retries

**Delivery Guarantees:**
- APNs does NOT guarantee delivery
- Notification may not arrive if:
  - Device is offline (queued for 30 seconds max)
  - User has notifications disabled
  - Device token is invalid/expired
  - App is not installed

**Fallback Strategy:**
1. Send via APNs (primary)
2. If APNs fails, store in `notifications` table for in-app display
3. Sync `notifications` table when user opens app
4. Show unread notification badge

**Retry Logic:**
```swift
// APIClient - Retry failed APNs sends
func sendNotificationWithRetry(userId: String, notification: Notification, retryCount: Int = 0) async {
    do {
        try await apiClient.sendAPNsNotification(userId, notification)
    } catch {
        // Store locally for retry
        try await localNotificationStore.save(notification)

        // Exponential backoff retry
        if retryCount < 3 {
            let delay = pow(2.0, Double(retryCount)) * 1000 // 1s, 2s, 4s
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000))
            await sendNotificationWithRetry(userId, notification, retryCount: retryCount + 1)
        }
    }
}
```

### Batch vs Immediate Delivery

**Batch Rules:**

Multiple notifications within 10-minute window → Group into one notification

**Example:**
- Sarah votes
- Mike votes
- Jessica votes
→ Single notification: "3 people voted on Game Night"

**Implementation:**
```swift
// NotificationBatcher.swift
class NotificationBatcher {
    private let batchWindowSeconds: TimeInterval = 600 // 10 minutes

    func shouldBatch(notification: Notification, existingNotifications: [Notification]) -> Bool {
        // Same proposal + same day → batch
        let sameProposal = existingNotifications.filter {
            $0.data["proposal_id"] == notification.data["proposal_id"]
        }
        let recentNotifications = sameProposal.filter {
            now().timeIntervalSince($0.createdAt) < batchWindowSeconds
        }
        return !recentNotifications.isEmpty
    }
}
```

### Time-Zone Aware Delivery

**Don't Wake Users During Sleep:**

```swift
// NotificationScheduler.swift
func shouldDelayNotification(userId: String, notification: Notification) async -> Bool {
    let user = try await fetchUser(userId)
    let timezone = TimeZone(identifier: user.timezone) ?? TimeZone.current
    let now = Date().converting(to: timezone)

    let quietHoursStart = 22 // 10 PM
    let quietHoursEnd = 8    // 8 AM

    let hour = Calendar.current.component(.hour, from: now)

    // If in quiet hours, delay until morning
    if hour >= quietHoursStart || hour < quietHoursEnd {
        if notification.type != "CONFLICT_ALERT" {
            // Non-urgent: delay until 8 AM
            return true
        }
    }

    return false
}
```

---

## In-App Notification Management

### Notifications Database Table

**Primary Storage for In-App Notifications:**

```sql
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL, -- 'PROPOSAL_CREATED', 'CONFLICT_ALERT', etc.
    title VARCHAR(255) NOT NULL,
    body VARCHAR(500),
    data JSONB DEFAULT '{}', -- Custom data for deep linking
    proposal_id UUID REFERENCES event_proposals(id) ON DELETE CASCADE,
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    friend_request_id UUID REFERENCES friend_requests(id) ON DELETE CASCADE,
    is_read BOOLEAN DEFAULT false,
    is_archived BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT now(),
    expires_at TIMESTAMP DEFAULT now() + INTERVAL '30 days',
    updated_at TIMESTAMP DEFAULT now()
);

-- Indexes for performance
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(is_read);
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read, created_at DESC);

-- RLS Policy
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can see own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications (mark read)"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id);
```

### Inbox Architecture

**Three Categories in Inbox:**

1. **Pending Votes** (highest priority)
   - Event proposals awaiting user response
   - Shows countdown to deadline
   - Ordered by deadline, then newest first

2. **Upcoming Events** (informational)
   - Confirmed group events
   - Shows date, time, location
   - Ordered by event date

3. **Notifications & Activity** (mixed)
   - Friend requests
   - Group invites
   - Vote updates
   - Conflict alerts
   - Ordered by newest first

**Inbox View Implementation:**

```swift
@MainActor
class InboxViewModel: ObservableObject {
    @Published var pendingVotes: [EventProposal] = []
    @Published var upcomingEvents: [Event] = []
    @Published var notifications: [InboxNotification] = []
    @Published var unreadCount: Int = 0

    func loadInbox() async {
        // Fetch proposals pending user vote
        pendingVotes = try await supabase
            .from("event_proposals")
            .select()
            .eq("group_id", in: userGroups.map(\.id))
            .not("id", "in", userVotedProposals)
            .eq("status", "open")
            .order("deadline", ascending: true)
            .execute()
            .decoded(as: [EventProposal].self)

        // Fetch upcoming confirmed events
        upcomingEvents = try await supabase
            .from("events")
            .select()
            .eq("group_id", in: userGroups.map(\.id))
            .gte("event_date", today)
            .eq("is_confirmed", true)
            .order("event_date", ascending: true)
            .limit(10)
            .execute()
            .decoded(as: [Event].self)

        // Fetch all notifications
        notifications = try await supabase
            .from("notifications")
            .select()
            .eq("user_id", currentUser.id)
            .eq("is_archived", false)
            .order("created_at", ascending: false)
            .limit(50)
            .execute()
            .decoded(as: [InboxNotification].self)

        // Calculate unread count
        unreadCount = notifications.filter { !$0.isRead }.count +
                      pendingVotes.count
    }
}
```

### Notification Persistence & Cleanup

**Mark as Read:**
```swift
func markNotificationAsRead(notificationId: String) async throws {
    try await supabase
        .from("notifications")
        .update(["is_read": true, "updated_at": now()])
        .eq("id", notificationId)
        .execute()
}
```

**Archive Notification:**
```swift
func archiveNotification(notificationId: String) async throws {
    try await supabase
        .from("notifications")
        .update(["is_archived": true, "updated_at": now()])
        .eq("id", notificationId)
        .execute()
}
```

**Auto-Delete Old Notifications:**
```sql
-- Automatic cleanup: delete read notifications older than 90 days
CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS void AS $$
BEGIN
    DELETE FROM notifications
    WHERE is_read = true
    AND created_at < now() - INTERVAL '90 days';
END;
$$ LANGUAGE plpgsql;

-- Run daily via Supabase scheduled jobs (or cron trigger)
SELECT cron.schedule('cleanup-notifications', '0 2 * * *', 'SELECT cleanup_old_notifications()');
```

### Notification Grouping & Clustering

**Group Notifications by Proposal:**
```swift
extension Array where Element == InboxNotification {
    var groupedByProposal: [String: [InboxNotification]] {
        Dictionary(grouping: self) { notification in
            notification.data["proposal_id"] ?? "unknown"
        }
    }
}
```

**Display as Single Card:**
```swift
struct ProposalNotificationGroup: View {
    let proposalId: String
    let notifications: [InboxNotification]

    var body: some View {
        VStack {
            Text("3 people voted on Game Night")
                .font(.headline)
            Text("Voting closes in 2 hours")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
```

---

## Notification Content & Copy

### Notification Title Templates

**Proposal Notifications:**
```
"[Name] proposed [Event]"
"Sarah proposed Game Night"
```

**Vote Count Notifications:**
```
"[X] people voted on [Event]"
"3 people voted on Game Night"
```

**Confirmation Notifications:**
```
"[Event] confirmed!"
"Game Night confirmed!"
```

**Conflict Notifications (to affected person):**
```
"You have a scheduling conflict"
"You have a conflict with [Event]"
```

**Conflict Notifications (to organizer):**
```
"[Name] has a scheduling conflict"
"Sarah has a conflict with Game Night"
```

### Notification Body Templates

**Proposal Body:**
```
"Vote needed • Closes in [Time]"
"Vote needed • Closes in 24 hours"
```

**Deadline Reminder Body:**
```
"[Group] needs your response"
"College Friends needs your response"
```

**Confirmation Body:**
```
"[Day] at [Time]"
"Saturday at 7:00 PM"
```

**Event Starting Body:**
```
"[Location]"
"Mike's Apartment"
```

### Personalization & Names

**Always Include:**
- Proposer/actor name (creates personal connection)
- Event title (context)
- Group name (context)

**Example Progression:**
- Generic: "Proposal needs vote"
- Personalized: "Sarah proposed Game Night"
- Super personalized: "Sarah proposed Game Night with College Friends"

### Privacy-Aware Notification Text

**Rule: Never reveal private event details in notifications**

**Bad:**
- "Sarah added 'Doctor's Appointment' to [Group] calendar" ← Reveals private event

**Good:**
- "Sarah updated her availability" ← Privacy-preserving

**Implementation:**
```swift
func notificationText(for event: Event, with visibility: EventVisibility) -> String {
    switch visibility {
    case .private:
        return "Sarah updated her availability"
    case .sharedWithName:
        return "Sarah added '\(event.title)' to the calendar"
    case .busyOnly:
        return "Sarah is busy during this time"
    }
}
```

### Emoji Usage Guidelines

**Do Use:**
- Clock emoji for time-sensitive: "⏰ Vote closes in 2 hours"
- Checkmark for confirmations: "✓ Game Night confirmed!"
- People emoji for group notifications: "👥 College Friends"
- Celebration emoji for fun moments: "🎉 Event confirmed!"

**Don't Use:**
- Excessive emojis (max 2 per notification)
- Misleading emojis
- Emojis that don't add information

---

## Interactive Notifications & Actions

### Custom Notification Categories (iOS 15+)

**Define Notification Categories:**
```swift
// AppDelegate.swift
func setupNotificationCategories() {
    // Proposal voting category
    let yesAction = UNNotificationAction(identifier: "VOTE_YES", title: "Yes", options: .foreground)
    let maybeAction = UNNotificationAction(identifier: "VOTE_MAYBE", title: "Maybe", options: .foreground)
    let noAction = UNNotificationAction(identifier: "VOTE_NO", title: "No", options: .foreground)

    let proposalCategory = UNNotificationCategory(
        identifier: "PROPOSAL_NOTIFICATION",
        actions: [yesAction, maybeAction, noAction],
        intentIdentifiers: [],
        options: .customDismissAction
    )

    // Friend request category
    let acceptAction = UNNotificationAction(identifier: "FRIEND_ACCEPT", title: "Accept", options: .foreground)
    let declineAction = UNNotificationAction(identifier: "FRIEND_DECLINE", title: "Decline", options: .foreground)

    let friendRequestCategory = UNNotificationCategory(
        identifier: "FRIEND_REQUEST",
        actions: [acceptAction, declineAction],
        intentIdentifiers: [],
        options: .customDismissAction
    )

    UNUserNotificationCenter.current().setNotificationCategories([proposalCategory, friendRequestCategory])
}
```

### Handle Interactive Notification Actions

```swift
// AppDelegate.swift
func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
) {
    let userInfo = response.notification.request.content.userInfo

    switch response.actionIdentifier {
    case "VOTE_YES":
        if let proposalId = userInfo["proposal_id"] as? String {
            Task {
                await submitVote(proposalId: proposalId, vote: .yes)
            }
        }

    case "FRIEND_ACCEPT":
        if let requestId = userInfo["friend_request_id"] as? String {
            Task {
                await acceptFriendRequest(requestId: requestId)
            }
        }

    case UNNotificationDefaultActionIdentifier:
        // User tapped notification (open app and navigate)
        handleDeepLink(userInfo: userInfo)

    case UNNotificationDismissActionIdentifier:
        // User dismissed notification
        markNotificationAsRead(userInfo: userInfo)

    default:
        break
    }

    completionHandler()
}
```

### Deep Linking from Notifications

**Navigate to Correct Screen:**
```swift
func handleDeepLink(userInfo: [AnyHashable: Any]) {
    guard let deepLink = userInfo["deep_link"] as? String else { return }

    // Parse deep link: "lockit://proposals/uuid"
    guard let url = URL(string: deepLink),
          url.scheme == "lockit" else { return }

    let pathComponents = url.path.split(separator: "/")

    switch pathComponents.first {
    case "proposals":
        if let proposalId = pathComponents.last {
            appCoordinator.navigateToProposal(proposalId: String(proposalId))
        }
    case "events":
        if let eventId = pathComponents.last {
            appCoordinator.navigateToEvent(eventId: String(eventId))
        }
    case "friends":
        appCoordinator.navigateToFriendsTab()
    default:
        break
    }
}
```

---

## User Notification Preferences

### Global Notification Settings

**Screen: Settings → Notifications**

```
NOTIFICATIONS
├─ Allow Push Notifications (Toggle)
│  ├─ [OFF] → Shows "Enable Notifications" prompt
│  └─ [ON] → Show granular controls below
├─ Notification Preferences
│  ├─ Proposal Notifications (Toggle)
│  ├─ Vote Count Updates (Toggle)
│  ├─ Conflict Alerts (Toggle)
│  ├─ Friend Requests (Toggle)
│  ├─ Event Reminders (Toggle)
│  └─ Group Updates (Toggle)
├─ Sound & Haptics
│  ├─ Notification Sound (Dropdown)
│  ├─ Haptic Feedback (Toggle)
│  └─ Critical Alerts (Toggle)
├─ Quiet Hours
│  ├─ Enable Quiet Hours (Toggle)
│  ├─ From: [22:00]
│  └─ To: [08:00]
└─ Summary Notifications (iOS 15+)
   └─ Enable Summary (Toggle)
```

### Per-Group Notification Controls

**Screen: Groups → [Group] → Notification Settings**

```
[GROUP NAME] NOTIFICATIONS
├─ Notification Level
│  ├─ All Notifications (default)
│  ├─ Only Important
│  └─ Muted
├─ Specific Types
│  ├─ New Proposals (Toggle)
│  ├─ Voting Deadline (Toggle)
│  ├─ Vote Updates (Toggle)
│  └─ Event Confirmations (Toggle)
└─ Event Reminders
   ├─ 30 min before event (Toggle)
   └─ 24 hours before event (Toggle)
```

### Per-Event Type Controls

**Enable/Disable by Notification Type:**

| Type | Default | Toggleable |
|------|---------|-----------|
| New Proposals | ON | Yes |
| Vote Count Updates | ON | Yes |
| Voting Deadline | ON | Yes |
| Event Confirmations | ON | Yes |
| Event Reminders | ON | Yes |
| Friend Requests | ON | Yes |
| Conflict Alerts | ON | No (always on) |

### Database Storage

```sql
CREATE TABLE user_notification_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    notifications_enabled BOOLEAN DEFAULT true,
    proposal_notifications BOOLEAN DEFAULT true,
    vote_updates BOOLEAN DEFAULT true,
    conflict_alerts BOOLEAN DEFAULT true,
    friend_requests BOOLEAN DEFAULT true,
    event_reminders BOOLEAN DEFAULT true,
    group_updates BOOLEAN DEFAULT true,
    notification_sound VARCHAR(50) DEFAULT 'default',
    haptic_feedback BOOLEAN DEFAULT true,
    quiet_hours_enabled BOOLEAN DEFAULT false,
    quiet_hours_start TIME,
    quiet_hours_end TIME,
    timezone VARCHAR(100),
    summary_notifications_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

CREATE TABLE group_notification_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    group_id UUID NOT NULL,
    notification_level VARCHAR(20) DEFAULT 'all', -- 'all', 'important', 'muted'
    proposal_notifications BOOLEAN DEFAULT true,
    vote_updates BOOLEAN DEFAULT true,
    confirmations BOOLEAN DEFAULT true,
    event_reminders BOOLEAN DEFAULT true,
    UNIQUE(user_id, group_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE
);
```

---

## Badge Management

### Badge Count Logic

**Badge increments when:**
- New proposal notification sent to user (pending vote)
- Friend request received
- Group invite received

**Badge decrements when:**
- User votes on proposal
- User accepts/declines friend request
- User joins group

**Badge clears when:**
- All pending actions completed
- User marks Inbox as read

### Badge Calculation

```swift
func calculateAppBadge() async {
    let pendingVotes = try await supabase
        .from("event_proposals")
        .select("id")
        .eq("group_id", in: userGroups)
        .not("id", "in", userVotedProposals)
        .eq("status", "open")
        .execute()
        .count

    let pendingFriendRequests = try await supabase
        .from("friend_requests")
        .select("id")
        .eq("recipient_id", currentUser.id)
        .eq("status", "pending")
        .execute()
        .count

    let pendingGroupInvites = try await supabase
        .from("group_invites")
        .select("id")
        .eq("invitee_id", currentUser.id)
        .eq("status", "pending")
        .execute()
        .count

    let totalBadge = pendingVotes + pendingFriendRequests + pendingGroupInvites

    DispatchQueue.main.async {
        UIApplication.shared.applicationIconBadgeNumber = totalBadge
    }
}
```

### Update Badge on Action

```swift
func submitVote(proposalId: String, vote: Vote) async throws {
    try await supabase
        .from("proposal_votes")
        .insert(["proposal_id": proposalId, "vote": vote])
        .execute()

    // Update badge
    await calculateAppBadge()
}
```

---

## Edge Cases & Error Handling

### Permission Denied Scenarios

**Scenario 1: User denies notification permission on first prompt**

**Handling:**
```swift
// Show opt-in prompt in app
struct NotificationOptInView: View {
    var body: some View {
        VStack {
            Image(systemName: "bell.slash")
            Text("Stay Updated")
                .font(.title2)
            Text("Enable notifications to never miss an event proposal or voting deadline.")
                .font(.caption)

            Button("Enable Notifications") {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
        }
    }
}
```

**Fallback:**
- Use in-app notifications only
- Sync `notifications` table when app opens
- Show badge with unread count

### Device Token Expiration

**Scenario: Device token becomes invalid (device factory reset, app reinstall)**

**Detection:**
```swift
// APNs returns error when sending to invalid token
func sendAPNsNotification(deviceToken: String) async throws {
    do {
        try await apnsService.send(deviceToken: deviceToken, payload: payload)
    } catch APNsError.invalidToken {
        // Mark token as inactive
        await deactivateDeviceToken(deviceToken)
        return
    }
}

func deactivateDeviceToken(_ token: String) async {
    try await supabase
        .from("device_tokens")
        .update(["is_active": false])
        .eq("device_token", token)
        .execute()
}
```

### Failed Delivery Handling

**Scenario: APNs request fails (network error, service down)**

**Strategy:**
1. Catch APNs error
2. Store notification in database
3. Retry in background
4. Show in-app notification when user opens app

```swift
func sendNotificationWithFallback(_ notification: Notification) async {
    do {
        try await sendAPNs(notification)
    } catch {
        // Store for fallback display
        try await storeNotificationForInApp(notification)

        // Retry after delay
        try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
        await sendNotificationWithFallback(notification)
    }
}
```

### Notification Overload Prevention

**Scenario: System tries to send 50 notifications at once**

**Strategy:**
- Batch notifications within 10-minute window
- Rate limit: max 5 notifications per hour per user
- Queue excess for later delivery

```swift
class NotificationRateLimiter {
    private var recentNotifications: [String: [Date]] = [:]

    func shouldSendNotification(userId: String, type: String) -> Bool {
        let key = "\(userId)-\(type)"
        let recentDates = recentNotifications[key] ?? []

        // Remove dates older than 1 hour
        let withinHour = recentDates.filter { Date().timeIntervalSince($0) < 3600 }

        // Allow if fewer than 5 in last hour
        guard withinHour.count < 5 else { return false }

        recentNotifications[key] = withinHour + [Date()]
        return true
    }
}
```

### Expired Notifications

**Scenario: User votes, then proposal expires before confirmation**

**Handling:**
- Remove notification from Inbox
- Notification auto-expires after 30 days (via database cleanup)

```swift
// Remove notification when proposal expires
func expireProposal(proposalId: String) async {
    try await supabase
        .from("notifications")
        .delete()
        .eq("proposal_id", proposalId)
        .eq("is_read", false) // Keep read ones for history
        .execute()
}
```

### Cross-Device Notification Handling

**Scenario: User votes on iPhone, also gets notification on iPad**

**Prevention:**
- User votes on device A
- Backend marks proposal as "voted" immediately
- When device B gets notification, check if already voted before displaying

```swift
func handleProposalNotification(proposalId: String) async {
    // Check if user already voted
    let hasVoted = try await supabase
        .from("proposal_votes")
        .select("id")
        .eq("proposal_id", proposalId)
        .eq("user_id", currentUser.id)
        .execute()
        .count > 0

    if hasVoted {
        // Don't show notification, just update UI
        await markProposalAsVoted(proposalId)
    } else {
        // Show notification normally
        displayNotification()
    }
}
```

---

## Code Implementation

### PushNotificationManager Class

**Complete Implementation:**

```swift
// Core/Notifications/PushNotificationManager.swift

import UserNotifications
import Supabase

@MainActor
class PushNotificationManager: NSObject, ObservableObject {
    static let shared = PushNotificationManager()

    @Published var isNotificationsEnabled = false
    @Published var notifications: [InboxNotification] = []

    private let supabase = SupabaseClient(url: URL(string: "...")!, accessKey: "...")
    private let rateLimiter = NotificationRateLimiter()

    override init() {
        super.init()
        setupNotificationCategories()
        checkNotificationStatus()
    }

    // MARK: - Setup & Permissions

    func setupNotificationCategories() {
        // Proposal actions
        let yesAction = UNNotificationAction(identifier: "VOTE_YES", title: "Yes")
        let maybeAction = UNNotificationAction(identifier: "VOTE_MAYBE", title: "Maybe")
        let noAction = UNNotificationAction(identifier: "VOTE_NO", title: "No")

        let proposalCategory = UNNotificationCategory(
            identifier: "PROPOSAL_NOTIFICATION",
            actions: [yesAction, maybeAction, noAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        // Friend request actions
        let acceptAction = UNNotificationAction(identifier: "FRIEND_ACCEPT", title: "Accept")
        let declineAction = UNNotificationAction(identifier: "FRIEND_DECLINE", title: "Decline")

        let friendCategory = UNNotificationCategory(
            identifier: "FRIEND_REQUEST",
            actions: [acceptAction, declineAction]
        )

        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().setNotificationCategories([proposalCategory, friendCategory])
    }

    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])

            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }

            isNotificationsEnabled = granted
        } catch {
            print("Failed to request notification authorization: \(error)")
        }
    }

    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isNotificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Device Token Management

    func registerDeviceToken(_ token: String) async throws {
        try await supabase
            .from("device_tokens")
            .upsert(
                [
                    "user_id": CurrentUserManager.shared.user?.id ?? "",
                    "device_token": token,
                    "device_model": UIDevice.current.model,
                    "os_version": UIDevice.current.systemVersion,
                    "is_active": true,
                    "last_used_at": ISO8601DateFormatter().string(from: Date())
                ]
            )
            .eq("user_id", value: CurrentUserManager.shared.user?.id ?? "")
            .execute()
    }

    func deactivateDeviceToken(_ token: String) async throws {
        try await supabase
            .from("device_tokens")
            .update(["is_active": false])
            .eq("device_token", token)
            .execute()
    }

    // MARK: - Notification Handling

    func handleNotification(_ userInfo: [AnyHashable: Any]) {
        if let deepLink = userInfo["deep_link"] as? String {
            handleDeepLink(deepLink)
        }

        markNotificationAsRead(userInfo: userInfo)
        updateBadgeCount()
    }

    func handleDeepLink(_ deepLink: String) {
        guard let url = URL(string: deepLink), url.scheme == "lockit" else { return }

        let pathComponents = url.path.split(separator: "/").map(String.init)

        guard pathComponents.count >= 2 else { return }

        let target = pathComponents[0]
        let id = pathComponents[1]

        DispatchQueue.main.async {
            NavigationManager.shared.navigateTo(target: target, id: id)
        }
    }

    // MARK: - Fetch Notifications

    func fetchNotifications() async throws {
        guard let userId = CurrentUserManager.shared.user?.id else { return }

        let response = try await supabase
            .from("notifications")
            .select()
            .eq("user_id", value: userId)
            .eq("is_archived", value: false)
            .order("created_at", ascending: false)
            .limit(50)
            .execute()

        let notifications = try response.decoded(as: [InboxNotification].self)

        DispatchQueue.main.async {
            self.notifications = notifications
        }
    }

    func markNotificationAsRead(id: String) async throws {
        try await supabase
            .from("notifications")
            .update(["is_read": true])
            .eq("id", value: id)
            .execute()
    }

    func markNotificationAsRead(userInfo: [AnyHashable: Any]) {
        if let notificationId = userInfo["notification_id"] as? String {
            Task {
                try? await markNotificationAsRead(id: notificationId)
            }
        }
    }

    func archiveNotification(id: String) async throws {
        try await supabase
            .from("notifications")
            .update(["is_archived": true])
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Badge Management

    func updateBadgeCount() async throws {
        guard let userId = CurrentUserManager.shared.user?.id else { return }

        let pendingVotesCount = try await supabase
            .from("event_proposals")
            .select("id", count: .exact)
            .not("id", value: "in", []) // Filter out voted proposals
            .eq("status", value: "open")
            .execute()
            .count

        let pendingFriendsCount = try await supabase
            .from("friend_requests")
            .select("id", count: .exact)
            .eq("recipient_id", value: userId)
            .eq("status", value: "pending")
            .execute()
            .count

        let totalBadge = pendingVotesCount + pendingFriendsCount

        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = totalBadge
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Show notification banner while app is open
        return [.banner, .sound, .badge]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo

        switch response.actionIdentifier {
        case "VOTE_YES":
            await handleVoteAction(userInfo: userInfo, vote: .yes)
        case "VOTE_MAYBE":
            await handleVoteAction(userInfo: userInfo, vote: .maybe)
        case "VOTE_NO":
            await handleVoteAction(userInfo: userInfo, vote: .no)
        case "FRIEND_ACCEPT":
            await handleFriendAction(userInfo: userInfo, action: .accept)
        case "FRIEND_DECLINE":
            await handleFriendAction(userInfo: userInfo, action: .decline)
        case UNNotificationDefaultActionIdentifier:
            handleDeepLink(userInfo: userInfo)
        default:
            break
        }
    }

    private func handleVoteAction(userInfo: [AnyHashable: Any], vote: Vote) async {
        guard let proposalId = userInfo["proposal_id"] as? String else { return }

        do {
            try await submitVote(proposalId: proposalId, vote: vote)
            await updateBadgeCount()
        } catch {
            print("Failed to submit vote: \(error)")
        }
    }

    private func handleFriendAction(userInfo: [AnyHashable: Any], action: FriendAction) async {
        guard let requestId = userInfo["friend_request_id"] as? String else { return }

        do {
            try await respondToFriendRequest(requestId: requestId, action: action)
            await updateBadgeCount()
        } catch {
            print("Failed to respond to friend request: \(error)")
        }
    }

    private func handleDeepLink(userInfo: [AnyHashable: Any]) {
        if let deepLink = userInfo["deep_link"] as? String {
            handleDeepLink(deepLink)
        }
    }

    private func submitVote(proposalId: String, vote: Vote) async throws {
        // Implementation calls API
    }

    private func respondToFriendRequest(requestId: String, action: FriendAction) async throws {
        // Implementation calls API
    }
}

// MARK: - Helper Types

enum Vote: String {
    case yes = "yes"
    case maybe = "maybe"
    case no = "no"
}

enum FriendAction {
    case accept
    case decline
}

class NotificationRateLimiter {
    private var recentNotifications: [String: [Date]] = [:]

    func shouldSendNotification(userId: String, type: String) -> Bool {
        let key = "\(userId)-\(type)"
        let recentDates = recentNotifications[key] ?? []

        let withinHour = recentDates.filter { Date().timeIntervalSince($0) < 3600 }

        guard withinHour.count < 5 else { return false }

        recentNotifications[key] = withinHour + [Date()]
        return true
    }
}
```

### AppDelegate Setup

```swift
// App/AppDelegate.swift

import UIKit
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Setup notification manager
        let notificationManager = PushNotificationManager.shared

        // Request notification permissions (can also be done during onboarding)
        Task {
            await notificationManager.requestAuthorization()
        }

        // Setup notification handling
        UNUserNotificationCenter.current().delegate = notificationManager

        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()

        Task {
            try? await PushNotificationManager.shared.registerDeviceToken(token)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error)")
    }
}
```

---

## Testing Strategy

### Local Notification Testing

**Simulate APNs in Xcode:**

```swift
// Use Apple's Notification Composer tool in Xcode
// Or send test notification via Supabase CLI:

supabase functions invoke send_apns --no-verify \
  --header "Content-Type: application/json" \
  -d '{"user_id":"uuid","proposal_id":"uuid"}'
```

### TestFlight Notification Testing

**Best Practices:**
1. Deploy to TestFlight sandbox
2. Test with real APNs (not simulator)
3. Test all notification types
4. Test on multiple devices (iPhone, iPad)
5. Verify badges update correctly
6. Test deep links work

### Production Notification Monitoring

**Track Key Metrics:**
```sql
-- Notification delivery rate
SELECT
    type,
    COUNT(*) as total_sent,
    SUM(CASE WHEN delivered = true THEN 1 ELSE 0 END) as delivered,
    ROUND(SUM(CASE WHEN delivered = true THEN 1 ELSE 0 END)::numeric / COUNT(*), 2) as delivery_rate
FROM notifications
GROUP BY type;

-- Open rate by type
SELECT
    type,
    COUNT(*) as total,
    SUM(CASE WHEN is_read = true THEN 1 ELSE 0 END) as opened
FROM notifications
GROUP BY type;

-- Opt-out rate
SELECT
    notification_type,
    COUNT(DISTINCT user_id) as users_opted_out
FROM user_notification_preferences
WHERE (CASE
    WHEN notification_type = 'proposals' THEN NOT proposal_notifications
    WHEN notification_type = 'friend_requests' THEN NOT friend_requests
    ELSE false
END)
GROUP BY notification_type;
```

### A/B Testing Notification Content

**Test Variants:**

| Variant | Body | Hypothesis |
|---------|------|-----------|
| A (Control) | "Vote needed • Closes in 24 hours" | Baseline |
| B (Urgency) | "Vote needed • 24 hours left!" | Adds urgency |
| C (Names) | "[3 people] need your vote" | Social proof |
| D (Event) | "Vote on Game Night • 24 hours" | More context |

**Measure:** Open rate, click-through rate, conversion rate (vote submitted)

---

## Analytics & Monitoring

### Key Metrics to Track

| Metric | Formula | Target |
|--------|---------|--------|
| **Delivery Rate** | Delivered / Sent | >95% |
| **Open Rate** | Opened / Delivered | >30% |
| **Action Rate** | ActedUpon / Opened | >70% |
| **Opt-Out Rate** | OptedOut / Users | <5% |
| **Crash Rate** | Crashes / Launches | <0.1% |
| **Badge Accuracy** | AccurateBadge / Updates | 100% |

### Monitoring Implementation

```swift
// Services/AnalyticsService.swift

class AnalyticsService {
    static let shared = AnalyticsService()

    func trackNotificationSent(_ notification: Notification) {
        analytics.track(event: "notification_sent", properties: [
            "notification_type": notification.type,
            "user_id": CurrentUserManager.shared.user?.id ?? "",
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "has_action_buttons": !notification.actions.isEmpty
        ])
    }

    func trackNotificationOpened(_ notification: Notification) {
        analytics.track(event: "notification_opened", properties: [
            "notification_type": notification.type,
            "time_to_open_seconds": notification.timeToOpen ?? 0,
            "from_background": UIApplication.shared.applicationState == .background
        ])
    }

    func trackNotificationAction(_ notification: Notification, action: String) {
        analytics.track(event: "notification_action", properties: [
            "notification_type": notification.type,
            "action": action,
            "conversion": true
        ])
    }
}
```

### Error Tracking

```swift
// Track failed APNs sends
func trackAPNsFailure(error: Error, deviceToken: String) {
    errorTracker.captureException(error, context: [
        "error_type": "apns_failure",
        "device_token": deviceToken.prefix(10) + "...", // Partial token for privacy
        "timestamp": Date().iso8601String
    ])
}
```

---

## Related Documentation

See the following for integrated information:

- **Complete UI Flows:** `NotionMD/Complete UI Flows/FLOW 9 NOTIFICATIONS & INBOX.md`
- **Inbox Screen Design:** `NotionMD/Detailed Layouts/SCREEN 4 INBOX - EVENT PROPOSAL.md`
- **Design Philosophy:** `lockitin-designs.md` (Section 6 - Notifications Design)
- **Feature Requirements:** `lockitin-features.md` (Tier 1: Basic Notifications)
- **Technical Architecture:** `lockitin-technical-architecture.md` (APNs Integration)
- **Edge Cases:** `lockitin-edge-cases.md` (Notification Interactions Section)
- **Development Timeline:** `lockitin-roadmap-development.md` (Sprint 3: Push Notifications)

---

**Last Updated:** December 1, 2025
**Status:** Ready for Implementation
**Next Review:** When notification system is integrated

