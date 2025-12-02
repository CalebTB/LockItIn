# Shareless: Complete User Flows

## Document Overview

This document consolidates all step-by-step user journeys for the Shareless iOS calendar app. Each flow represents a critical user interaction path from initial app launch through advanced features.

**Purpose:** Serve as the definitive reference during development for screen transitions, user inputs, system responses, and state management across all major user journeys.

**How to Use During Development:**
- Use as pseudo-code for building ViewControllers and navigation flows
- Reference for testing critical user paths
- Source of truth for onboarding and feature tutorials
- Guide for error state handling and edge case scenarios
- Input for analytics tracking point definition

**Organization:**
- 10 core user flows numbered sequentially
- Each flow includes step-by-step journey, screen transitions, and success criteria
- Common patterns and decision points documented separately
- Color coding and visual indicators referenced for UI implementation

---

## FLOW 1: ONBOARDING (First-Time User)

**Objective:** New user launches app, completes sign-up, grants permissions, and reaches first usable calendar state.

### Journey Map

```
Launch App
  ↓
Welcome Screen (tagline: "Your calendar, supercharged for friend groups")
  ↓
Sign Up / Log In
  ├─ Email/password signup OR
  └─ Social login (Apple/Google)
  ↓
Request Calendar Access
  ├─ Modal: "We'll sync with Apple Calendar"
  ├─ Explanation: "See your existing events and keep them in sync"
  └─ [Allow] [Skip for now] buttons
  ↓
Request Notifications
  ├─ Modal: "Get notified about group events"
  ├─ Explanation: "Stay updated on proposals and confirmations"
  └─ [Allow] [Skip for now] buttons
  ↓
Calendar View (empty state or synced from Apple Calendar)
  ├─ If empty: "No events yet"
  │   └─ "Tap + to create your first event"
  └─ If synced: Shows imported events
  ↓
Tutorial Tooltips (dismiss-able)
  ├─ "Tap + to create an event"
  ├─ "Swipe up for month view"
  └─ "Groups tab to invite friends"
  ↓
Success State: User can see calendar, tap + to create events
```

### Key Screens

**Welcome Screen:**
- App logo/branding
- Tagline and brief value proposition
- [Sign Up] and [Log In] buttons

**Sign Up Sheet:**
- Email input field
- Password input field
- Confirm password input field
- Terms of service checkbox
- [Sign Up] button
- "Already have an account?" → Link to login

**Calendar Access Permission:**
- Icon showing calendar sync
- Explanation text: "We'll sync with Apple Calendar to see your existing events and keep them in sync"
- [Allow] and [Skip for now] buttons

**Notifications Permission:**
- Icon showing bell/notification
- Explanation text: "Stay updated on group event proposals and voting deadlines"
- [Allow] and [Skip for now] buttons

**Calendar View (Empty State):**
- Empty calendar illustration
- "No events yet" message
- Floating action button (+) prominently displayed
- Tutorial tooltip pointing to (+) button

### Success Criteria

- User successfully creates account (email verification if required)
- Calendar access granted (or explicitly skipped)
- Notifications enabled (or explicitly skipped)
- User reaches calendar view ready to create events
- Permission state saved to UserDefaults for subsequent app launches
- No "required permission" blockers on subsequent sessions

### Error Handling

- **Sign Up Failure:** Display error message (email already exists, weak password, etc.)
  - Allow user to retry or switch to login
- **Calendar Access Failure:** Show retry button or allow continuation without sync
- **Notification Permission Failure:** Allow app to continue, prompt again later

### Analytics Tracking

- `onboarding_started`
- `calendar_permission_requested` (allow/skip)
- `notifications_permission_requested` (allow/skip)
- `onboarding_completed`
- `time_to_first_event_creation` (duration)

---

## FLOW 2: PERSONAL EVENT CREATION

**Objective:** User creates a personal calendar event with privacy settings, which syncs to Apple Calendar.

### Journey Map

```
Calendar View
  ↓
Tap "+" button (floating action button)
  ↓
New Event Sheet slides up from bottom
  ├─ Title field (required)
  │   └─ Keyboard: Text input, placeholder "Event title"
  ├─ Date picker (required)
  │   └─ Tap to open date selector
  ├─ Time picker (required for all-day confirmation)
  │   ├─ Start time
  │   ├─ End time
  │   └─ All-day toggle
  ├─ Location field (optional)
  │   └─ Tap to open map for search
  ├─ Notes field (optional)
  │   └─ Multi-line text input
  ├─ Repeat options (optional)
  │   └─ None / Daily / Weekly / Monthly / Custom
  └─ Privacy Settings ⭐ (key differentiator)
      ├─ Selection buttons:
      │   ├─ "Private" (default, locked icon)
      │   │   └─ "Only you can see this event"
      │   ├─ "Shared with name" (person icon)
      │   │   └─ "Friends see the event title and time"
      │   └─ "Shared - busy only" (clock icon)
      │       └─ "Friends see you're busy, but not details"
      └─ If not Private: "Who can see it?" selector
          └─ Toggle switches for each group
              ├─ "College Friends" [toggle]
              ├─ "Roommates" [toggle]
              └─ "Basketball Crew" [toggle]
  ↓
Tap "Create" button
  ↓
Loading state (spinner) - 1-2 seconds
  ↓
Event appears on calendar with privacy badge
  ├─ 🔒 = Private
  ├─ 👥 = Shared with name
  └─ 👁️ = Busy only
  ↓
Syncs to Apple Calendar in background (bidirectional)
  ↓
Success: Event persisted locally and on backend
```

### Key Screens

**New Event Sheet:**
- Clear, minimal design matching Apple Calendar
- Dividers between sections (Title, Date/Time, Location, Privacy, etc.)
- All fields validated on-the-fly with inline error messages
- Privacy section highlighted or bordered to draw attention

**Date Picker (Modal):**
- Standard iOS date picker (wheels or calendar style)
- Allow quick date selection by tapping calendar grid

**Time Picker:**
- Standard iOS time picker (wheels)
- Start and end times side-by-side or sequential

**Group Selector (Privacy):**
- List of user's groups with toggle switches
- Animated state change when toggled

### Success Criteria

- Event saved to local database
- Event synced to Supabase backend
- Event synced to Apple Calendar (if permission granted)
- Privacy settings correctly applied
- Event visible on calendar with correct privacy badge
- Event is not visible to groups not selected in privacy settings

### Error Handling

- **Missing Title:** Red border around title field, error message "Event title required"
- **Invalid Time:** Error message "End time must be after start time"
- **Sync Failure:** Retry button appears, event stays in "Syncing..." state until resolved
- **Apple Calendar Sync Failure:** Show warning but allow event to remain in app, retry in background

### State Management

- Track unsaved changes to warn user on back/cancel
- Auto-save drafts to local storage while editing
- Handle cancellation (discard draft)

### Analytics Tracking

- `event_creation_started`
- `privacy_setting_changed` (which setting selected)
- `event_creation_completed`
- `apple_calendar_sync_requested`
- `apple_calendar_sync_completed` (success/failure)

---

## FLOW 3: EDITING EXISTING EVENT

**Objective:** User modifies an existing event's details or privacy settings, with changes synced across all platforms.

### Journey Map - Tap to Edit

```
Calendar View
  ↓
Tap on Event
  ↓
Event Detail Sheet slides up
  ├─ Title (read-only or tappable for inline edit)
  ├─ Date and time (read-only)
  ├─ Location (read-only)
  ├─ Privacy indicator
  │   └─ 🔒 Private / 👥 Shared / 👁️ Busy only
  ├─ Notes (if any)
  ├─ "Edit" button
  ├─ "Delete" button
  └─ "Share with..." button (quick access to privacy change)
  ↓
Tap "Edit" button
  ↓
Edit Event Sheet opens (same form as creation)
  ├─ All fields editable
  ├─ Privacy settings editable
  └─ "Who can see it?" selector if shared
  ↓
Make changes (title, time, location, notes, privacy, groups)
  ↓
Tap "Save" button
  ↓
Loading state - 1-2 seconds
  ↓
Sheet dismisses, calendar view updates
  ↓
Changes synced to Apple Calendar
  ↓
Success: Event updated everywhere
```

### Journey Map - Long Press Alternative

```
Long-press on Event → Quick Action Menu
  ├─ Edit
  │   └─ Opens full edit sheet
  ├─ Delete
  │   └─ Confirmation: "Delete this event?"
  ├─ Share with... (privacy quick-change)
  │   ├─ "Private"
  │   ├─ "Shared with name"
  │   └─ "Busy only"
  └─ Duplicate
      └─ Creates copy with default privacy
```

### Key Screens

**Event Detail Sheet:**
- Title, date, time, location displayed clearly
- Privacy badge prominently shown
- Action buttons at bottom or in header
- Swipe down to dismiss

**Edit Event Sheet:**
- Identical to creation sheet (reuse component)
- Pre-filled with current event data
- All fields validated during editing

**Conflict Handling (if synced from Apple Calendar):**
- Message: "This event was modified in Apple Calendar"
- Options: [Use App Version] [Use Apple Calendar Version] [Manual Resolve]
- Last write wins strategy with user notification

### Success Criteria

- Changes persisted to local database
- Changes synced to backend
- Changes synced to Apple Calendar (if applicable)
- Privacy changes take effect immediately
- All group members with visibility see updated event
- No duplicate events created

### Error Handling

- **Edit Conflict:** Show merge dialog if event modified externally
- **Sync Failure on Save:** Show retry button, keep edit form open
- **Delete Confirmation:** Require explicit confirmation with event title shown

### State Management

- Track which fields were modified
- Auto-save drafts while editing
- Handle cancellation without changes
- Detect external changes during edit (user modified in Apple Calendar)

### Analytics Tracking

- `event_edit_started`
- `event_field_modified` (which fields)
- `event_edit_completed`
- `event_delete_confirmed`
- `sync_conflict_detected` (which calendar)

---

## FLOW 4: CREATING A GROUP EVENT PROPOSAL

**Objective:** User initiates group event planning by proposing an event with multiple time options for voting.

### Journey Map

```
Calendar View OR Groups Tab
  ↓
Tap "+" button → "Propose Group Event" option
  ↓
Group Event Creation Sheet slides up
  ├─ Event title field (required)
  │   └─ "Secret Santa Planning" (example)
  ├─ Select Group dropdown (required)
  │   └─ Picker: "College Friends", "Roommates", "Basketball Crew"
  ├─ Description field (optional)
  │   └─ "Let's plan our annual Secret Santa"
  ├─ Location field (optional)
  │   └─ "TBD or specific location"
  └─ Propose Time Slots section (required, minimum 1)
      ├─ "+ Add Time Slot" button
      │   ├─ Opens date picker
      │   ├─ Opens start time picker
      │   ├─ Opens end time picker
      │   └─ Returns to proposal form
      │
      ├─ Time Slot 1: "Dec 15, 6-8pm"
      │   ├─ Shows availability heatmap
      │   │   └─ "5/8 people available"
      │   │       (pulls from Shadow Calendar data)
      │   └─ X button to remove slot
      │
      ├─ Time Slot 2: "Dec 16, 2-4pm"
      │   ├─ Shows: "7/8 people available"
      │   └─ X button to remove slot
      │
      └─ Time Slot 3: "Dec 17, 7-9pm"
          ├─ Shows: "3/8 people available"
          └─ X button to remove slot
  ↓
Tap "Send Proposal" button
  ↓
Loading state - backend creates proposal record
  ↓
Confirmation toast: "Proposal sent to College Friends"
  ↓
Sheet dismisses, returns to calendar/groups view
  ↓
Event Proposal appears in:
  ├─ Your Inbox (read-only "You proposed this" view)
  ├─ Recipients' Inbox (voting interface)
  └─ Groups tab under group details
  ↓
Push notifications sent to all group members
  ↓
Success: Proposal created, voting can begin
```

### Key Screens

**Group Event Creation Sheet:**
- Clean, minimal form layout
- Time slots section expanded by default or collapsed
- Each time slot shows availability count dynamically
- "Send Proposal" button disabled until all required fields filled

**Time Slot Picker (Modal):**
- Date picker for selecting date
- Two time pickers (start and end)
- Visual confirmation of selected time
- [Add] [Cancel] buttons

**Availability Heatmap Display:**
- Shows count of available people for each proposed slot
- Pulls from Shadow Calendar data (based on event visibility)
- Color coding: Green (good), Yellow (okay), Red (bad)
- Updates in real-time as user adjusts slots

### Success Criteria

- Proposal record created in database
- Minimum 1 time slot required
- Time slots cannot be in the past
- All group members receive push notification
- Proposal visible in all group members' inbox immediately (real-time)
- Availability counts are accurate per Shadow Calendar
- Proposal organizer can see all votes as they come in (real-time)

### Error Handling

- **Missing Required Field:** Red border and error message
- **Invalid Time (past time):** Error message "Select a future date and time"
- **Only 1 or 0 people available in all slots:** Warning (not error) "No one's available for any of these times. Continue anyway?"
- **Group Member Not Found:** Error when sending "One or more group members no longer exist"

### State Management

- Unsaved changes tracked, warn on back
- Auto-save time slots as user adds them
- Handle back/cancel properly (confirm discard)

### Real-Time Backend Operations

- Create `event_proposals` record
- Create `proposal_time_options` records (one per slot)
- Query Shadow Calendar data for each slot
- Send push notifications to group members via APNs
- Trigger `proposals.insert` Realtime event to group members

### Analytics Tracking

- `proposal_creation_started`
- `group_selected` (which group)
- `time_slot_added` (how many total)
- `proposal_sent`
- `proposal_notification_sent_count` (number of recipients)
- `availability_data_used` (yes/no - did user see availability?)

---

## FLOW 5: RESPONDING TO GROUP EVENT PROPOSAL

**Objective:** Group member receives proposal notification, views voting options, votes on preferred time, and sees real-time results.

### Journey Map

```
Push Notification received: "New event proposal: Secret Santa Planning"
  ↓
User taps notification (or opens app to Inbox tab)
  ↓
Inbox displays list with badge count
  ├─ Section: "Pending Votes" (highest priority)
  │   └─ Event Proposal Card: "Secret Santa Planning"
  ├─ Section: "Confirmed Events"
  └─ Section: "Activity"
  ↓
Tap Event Proposal Card
  ↓
Proposal Detail Sheet opens with voting interface
  ├─ Header
  │   ├─ Event title: "Secret Santa Planning"
  │   ├─ Proposed by: "[Friend name]"
  │   └─ Group: "[Group name]"
  │
  ├─ Time Slot Options (scrollable list)
  │   │
  │   ├─ Option 1: Sat Dec 15, 6-8pm
  │   │   ├─ Vote count: "5/8 available"
  │   │   ├─ Visual progress bar
  │   │   ├─ Avatar cluster showing who voted
  │   │   └─ Vote buttons:
  │   │       ├─ [✓ Available] (green)
  │   │       ├─ [~ Maybe] (yellow)
  │   │       └─ [✗ Can't make it] (gray)
  │   │
  │   ├─ Option 2: Sun Dec 16, 2-4pm ⭐ (highlighted)
  │   │   ├─ Vote count: "7/8 available" (best option)
  │   │   ├─ Visual progress bar (longer/greener)
  │   │   ├─ Avatar cluster
  │   │   └─ Vote buttons (same as above)
  │   │
  │   └─ Option 3: Mon Dec 17, 7-9pm
  │       ├─ Vote count: "3/8 available"
  │       ├─ Visual progress bar (shorter/redder)
  │       ├─ Avatar cluster
  │       └─ Vote buttons
  │
  ├─ Voting Deadline (if visible)
  │   └─ "Vote by: Dec 15 at 11:59pm"
  │
  └─ [Close] or Back button
  ↓
User taps "✓ Available" on Option 2
  ↓
Button highlights (shows selected state)
  ↓
Vote submitted to backend (optimistic UI update)
  ↓
In real-time, card updates:
  ├─ Vote count changes (e.g., 6/8 → 7/8)
  ├─ User's avatar appears in the group
  ├─ Progress bar animates to new width
  └─ User's vote marked with checkmark
  ↓
Real-time feed updates for other group members:
  ├─ They see vote count change immediately
  ├─ They see user's avatar added to voters
  └─ "Best option" badge may shift if this slot now leads
  ↓
If all group members voted OR deadline passed:
  ├─ Backend auto-confirms the winning time
  ├─ Event created and added to everyone's calendar
  ├─ Push notification sent: "Secret Santa confirmed for Dec 16, 2-4pm!"
  └─ Proposal moves from "Pending Votes" to "Confirmed Events"
  ↓
Sheet dismisses, user returns to Inbox
  ↓
Success: Vote recorded, event creation in progress
```

### Key Screens

**Inbox (Proposal List):**
- Categorized sections with collapsible headers
- "Pending Votes" section shows active proposals needing user action
- Badge count on "Pending Votes" section
- Proposal cards show:
  - Event title
  - Proposed by (friend's name)
  - Group name
  - Best time option (preview)
  - User's current vote status (if voted)

**Proposal Voting Sheet:**
- Header with event title and organizer
- Scrollable list of time options
- Each option shows clear voting buttons
- Real-time vote count updates
- Visual indication of best option (green background, star badge)
- Avatar cluster showing voters (tap to see names)

**Avatar Cluster Component:**
- Overlapping circular avatars
- Tap to expand and show full list of who voted for this slot
- Shows names of available/maybe/unavailable for transparency

### Success Criteria

- Vote recorded to `proposal_votes` table immediately
- User cannot vote twice (button disabled after first vote)
- Vote count updates in real-time for all group members via WebSocket
- "Best option" badge updates dynamically as vote counts change
- User sees their own vote reflected immediately
- Auto-event creation triggers when all voted or deadline passes
- Event created correctly in everyone's calendar
- Proposal moves to "Confirmed Events" section

### Error Handling

- **Vote Submission Failure:** Show retry button, keep voting interface open
- **WebSocket Disconnect:** Show "Connecting..." indicator, auto-reconnect
- **Proposal Closed:** Display message "Voting is closed. Event already confirmed."
- **User Not in Group:** Show error "You're no longer a member of this group"

### Real-Time Behavior (WebSocket)

- Subscribe to `proposal_votes.on('*')` for specific proposal
- Receive updates when other members vote
- Unsubscribe when sheet dismissed
- Show connection status indicator if network is poor

### State Management

- Track user's current vote on this proposal
- Highlight current vote button with visual indicator
- Disable changing vote after deadline (optional for MVP)
- Handle sheet dismissal (cleanup subscriptions)

### Analytics Tracking

- `proposal_viewed`
- `vote_recorded` (which option, which sentiment)
- `real_time_update_received_count` (track engagement)
- `proposal_auto_confirmed`
- `time_to_vote` (duration from notification to vote)

---

## FLOW 6: VIEWING GROUP CALENDARS (AVAILABILITY)

**Objective:** User switches to group view, examines friends' availability heatmap, and explores best times for group events.

### Journey Map

```
Bottom Tab Navigation → "Groups" tab
  ↓
Groups List View
  ├─ "College Friends" (8 members, avatar cluster)
  │   └─ 2 upcoming proposals, 3 confirmed events
  ├─ "Roommates" (4 members, avatar cluster)
  │   └─ 0 proposals, 1 upcoming event
  └─ "Basketball Crew" (6 members, avatar cluster)
      └─ 1 proposal pending
  ↓
Tap on "College Friends"
  ↓
Group Detail View
  ├─ Header
  │   ├─ Group name: "College Friends"
  │   ├─ Member list with avatars (horizontal scroll, click to see full list)
  │   └─ Actions menu: [Add member] [Remove group] [Settings]
  │
  ├─ Primary action button: "View Group Calendar" ⭐
  │   └─ Launches availability heatmap view
  │
  ├─ Section: "Upcoming Group Events" (confirmed)
  │   ├─ Secret Santa Planning - Sat Dec 16, 2-4pm
  │   ├─ Dinner - Sun Dec 17, 7pm
  │   └─ Tap to see details / edit
  │
  └─ Section: "Past Events" (collapsed)
      ├─ Thanksgiving Potluck - Nov 24
      └─ Tap to view details
  ↓
Tap "View Group Calendar"
  ↓
Group Calendar View (overlay mode on user's calendar)
  ├─ Header
  │   ├─ Group name
  │   └─ [Filter] [Settings] buttons
  │
  ├─ Calendar display (week or month view)
  │   ├─ Your events shown in full (solid colors)
  │   │   ├─ Blue = your personal events
  │   │   └─ Green = group events you're attending
  │   │
  │   └─ Friends' availability shown as colored heatmap blocks
  │       ├─ Green block = Everyone free (5/5 people)
  │       ├─ Yellow block = Most people free (3/5 people)
  │       ├─ Red block = Most people busy (1/5 people)
  │       └─ Gray block = No data / everyone private
  │
  ├─ Navigation
  │   └─ Swipe left/right to navigate weeks
  │
  ├─ Legend (at bottom)
  │   ├─ Green = Everyone free
  │   ├─ Yellow = Mixed availability
  │   ├─ Red = Most people busy
  │   └─ Gray = No visibility
  │
  └─ Tap a heatmap block to reveal details
      ↓
```

### Journey Map - Exploring Time Blocks

```
User taps on a Green heatmap block (e.g., Sat 2-4pm)
  ↓
Availability Detail Popup appears
  ├─ Time: "Sat Dec 16, 2-4pm"
  ├─ Availability breakdown:
  │   ├─ Available: Sarah, Mike, Jordan, Emma, Alex (5/5 people)
  │   ├─ Maybe: (none)
  │   └─ Busy: (none)
  │
  ├─ List of available friends with reason (if visible)
  │   ├─ "Sarah - Free"
  │   ├─ "Mike - Free"
  │   └─ "Jordan - Free"
  │
  ├─ Friends with privacy-restricted events
  │   └─ "Chris - Private event" (gray, shows they're busy but not why)
  │
  └─ Action button: "Propose event for this time"
      ↓
      (Starts Flow 4 with pre-filled date/time)
```

### Key Screens

**Groups List:**
- Grid or list view of all user's groups
- Each group card shows:
  - Group name
  - Member count
  - Avatar cluster (4-6 visible)
  - Upcoming event count
  - Pending proposal count

**Group Detail Sheet:**
- Full member list with ability to add/remove
- Primary CTA: "View Group Calendar"
- Upcoming and past events listed
- Settings and group management options

**Group Calendar View:**
- Calendar grid (week or month)
- Your events in solid colors overlaid
- Friends' availability as colored heatmap blocks
- Touch-friendly heatmap blocks (at least 1 hour x 30 min)
- Clear color legend

**Availability Detail Popup:**
- Time range displayed clearly
- Names of available people (color-coded by availability status)
- "Propose event here" button
- Dismiss by tapping outside or [X]

### Success Criteria

- Heatmap colors accurately reflect aggregated availability
- Privacy rules respected (don't show private event details)
- Available names shown only for events marked "shared with name" or "busy only"
- "Everyone free" blocks clearly identifiable
- User can tap any time block to see details
- "Propose event here" pre-fills date/time in Flow 4
- Navigation works smoothly (swipe/scroll)
- Accessible to all group members (not just organizer)

### Privacy Rules (Shadow Calendar)

- **Private events:** Shown as gray block (no details revealed)
- **Shared with name:** Name visible, event title visible
- **Busy only:** Name visible in aggregate count, but no event details
- At database level via RLS: Only return availability data user has permission to see

### Real-Time Behavior

- If someone votes on a proposal while viewing, heatmap updates
- If someone creates an event while viewing, heatmap updates
- Optimistic local updates for user's own actions

### State Management

- Track selected group
- Cache heatmap data to avoid repeated queries
- Handle group member changes (add/remove)
- Handle privacy setting changes

### Analytics Tracking

- `group_calendar_opened`
- `heatmap_block_tapped` (availability level)
- `propose_event_from_calendar` (started from heatmap)
- `group_members_viewed`
- `time_spent_viewing_calendar` (duration)

---

## FLOW 7: FRIEND MANAGEMENT

**Objective:** User adds friends individually and/or creates friend groups, manages group membership, and handles friend requests.

### Journey Map - Creating a Group

```
Bottom Tab Navigation → "Groups" tab
  ↓
Tab bar or header shows "Groups" with "+" button
  ↓
Tap "+" button → "New Group" option
  ↓
Create Group Sheet slides up
  ├─ Group name field (required)
  │   └─ Placeholder: "College Friends"
  │   └─ Validation: 1-50 characters
  │
  ├─ Add Members section
  │   ├─ Search bar: "Add friends..."
  │   │   └─ Real-time search across your friends list
  │   │
  │   ├─ "+ Import from Contacts"
  │   │   └─ Opens contact picker, multi-select allowed
  │   │
  │   ├─ "+ Generate Invite Link"
  │   │   └─ Creates shareable link (SMS/iMessage/email)
  │   │
  │   └─ Selected members shown below as chips with [X] to remove
  │       ├─ Sarah
  │       ├─ Mike
  │       └─ Jordan
  │
  └─ [Create Group] button (disabled until at least 1 member)
  ↓
Tap "Create Group"
  ↓
Group record created in database
  ↓
Push notifications sent to all members
  │   └─ "[Your name] added you to College Friends"
  │
  ├─ Invited members receive notification
  │   └─ Two buttons: [Accept] [Decline]
  │
  └─ Accepted members added to group
      ↓
```

### Journey Map - Adding Individual Friends

```
Bottom Tab Navigation → "Profile" tab
  ↓
Profile View shows:
  ├─ User avatar and name
  ├─ [Friends] button / section
  └─ [+ Add Friend] button
  ↓
Tap [+ Add Friend]
  ↓
Add Friend Sheet
  ├─ Search bar (search by username/email/phone)
  │   └─ Real-time search on Supabase `users` table
  │
  ├─ Search results show:
  │   ├─ User avatar
  │   ├─ Display name
  │   ├─ "@username" or email
  │   └─ [+ Add] button
  │
  ├─ OR: Share your Friend Code / QR Code section
  │   └─ Your unique 6-digit code (e.g., "A7X4K2")
  │   └─ QR code image (scannable)
  │   └─ [Copy Code] and [Share QR] buttons
  │
  └─ Friends can scan your QR or enter your code to add you
  ↓
Tap [+ Add] next to a friend
  ↓
Friend request sent
  ↓
Recipient gets notification: "[Your name] added you as a friend"
  ├─ [Accept] [Decline] buttons
  │
  └─ If accepted:
      ├─ Friend added to your friends list
      ├─ Both parties can now add each other to groups
      └─ Can view each other's group calendars
  ↓
```

### Key Screens

**Create Group Sheet:**
- Group name input with character count
- Search bar for adding friends
- Contact import button
- Invite link generation
- Selected members shown as removable chips
- Create button (disabled state when no members)

**Add Friend Sheet:**
- Search bar (focuses on open)
- Search results with add buttons
- Friend code section with copy/share actions
- QR code display and save/share buttons

**Friend Request Notification:**
- Tap notification → Opens modal
- Shows friend's profile: name, avatar, username
- [Accept] and [Decline] buttons
- Dismissible

**Friends List (Profile Tab):**
- List of all accepted friends
- Each friend card shows:
  - Avatar
  - Name
  - Shared groups count
  - Remove/block options

### Success Criteria

- Group created with at least 1 member
- Group visible in Groups tab immediately
- All invited members receive notifications
- Member can accept/decline invitation (if flow supports it, otherwise auto-join)
- Friends can be added via search, contact import, or QR/code
- Friend requests work bidirectionally
- Both users see each other in friends list after acceptance
- Users cannot add themselves as friend
- Cannot add same friend twice

### Error Handling

- **Group name too long:** Error message "Group name must be 50 characters or less"
- **No members selected:** Create button disabled with tooltip "Add at least one member"
- **Friend not found:** Search returns "No friends found"
- **Already friends:** Show "Already friends" instead of add button
- **Already sent request:** Show "Request sent" instead of add button

### State Management

- Track invited vs accepted group members (if applicable)
- Update friends list in real-time when acceptance received
- Handle block/unblock logic
- Manage group member list state during creation

### Real-Time Backend Operations

- Create `groups` record
- Create `group_members` records for each invited member
- Send push notifications via APNs
- Trigger `groups.insert` Realtime event to invitees

### Analytics Tracking

- `group_creation_started`
- `group_members_added_count` (how many invited)
- `group_created` (success)
- `friend_request_sent`
- `friend_request_accepted`
- `contact_import_used`
- `invite_link_shared`

---

## FLOW 8: CALENDAR VIEWS & NAVIGATION

**Objective:** User switches between day/week/month views, navigates dates, filters events, and manages calendar display.

### Journey Map

```
Calendar Tab (default: Week View)
  ↓
Header
  ├─ Date range display (e.g., "Dec 10-16, 2025")
  │
  ├─ View selector buttons [Day] [Week] [Month]
  │   └─ Tappable, shows which is active
  │
  └─ Filter button [☰]
      └─ Dropdown or side sheet with options:
          ├─ Show all events
          ├─ Only my events (personal)
          ├─ Only group events
          └─ By specific group:
              ├─ "College Friends"
              ├─ "Roommates"
              └─ "Basketball Crew"
  ↓
Calendar Grid (Week View, default)
  ├─ Week header with days of week (Mon, Tue, Wed, etc.)
  ├─ Time axis on left (12am, 1am, ..., 11pm)
  ├─ Grid cells showing events
  │   ├─ Color-coded by event type (see legend below)
  │   ├─ Event title visible if space permits
  │   └─ Privacy badges (🔒, 👥, 👁️) visible on hover
  │
  └─ Color Coding
      ├─ Blue = Your personal events
      ├─ Green = Group events (you're attending)
      ├─ Purple = Pending proposals (needing your vote)
      ├─ Gray = Your events marked "busy only" (visible to friends)
      └─ Light gray = Friends' events (you can see their busy blocks)
  ↓
Navigation Gestures
  ├─ Swipe left → Next week/day/month
  ├─ Swipe right → Previous week/day/month
  ├─ Swipe up → Expand to Month View (zoom in)
  └─ Swipe down → Collapse to Day View (zoom out)
  ↓
Tap on Event
  ├─ Event Detail Sheet opens (see Flow 2/3)
  └─ Shows full event details and edit/delete options
  ↓
Tap empty time slot
  ├─ Opens New Event creation (Flow 2)
  └─ Pre-fills date and time selected
  ↓
```

### Journey Map - View Changes

```
[Week] view (default)
  ├─ Shows 7 days in grid
  ├─ Scroll horizontally to see more weeks
  └─ Tap [Month] button to switch
      ↓
[Month] view
  ├─ Shows full month in calendar grid
  ├─ Events shown as small dots or abbreviated text
  ├─ Tap [Week] button to switch
  └─ Tap a day to jump to that day in week view
      ↓
[Day] view
  ├─ Shows single day with hour-by-hour timeline
  ├─ Scroll vertically to see more hours
  └─ Tap [Week] button to switch
```

### Key Screens

**Week View:**
- 7-column grid with days of week
- Time axis on left side (hourly)
- Events as colored blocks, resizable/draggable (future feature)
- Clear visual separation between days and hours

**Month View:**
- Full calendar grid with 6 weeks visible
- Day numbers in top-left of each cell
- Events shown as small dots or 1-line preview
- Tap day to zoom into that day's view
- Holiday indicators

**Day View:**
- Single day with hour-by-hour timeline
- Scroll vertically to see full day
- Current time indicated with red line
- Events shown as full-width blocks with details visible

**Filter Dropdown/Sheet:**
- Radio button group for view type (all/personal/group/by group)
- Clear selection button
- Auto-closes after selection
- Shows current filter state

### Success Criteria

- All three views (day/week/month) functional and smooth
- Swipe gestures work correctly in both directions
- Date navigation doesn't lose filter state
- Events display with correct colors based on type
- Tapping events opens detail sheet consistently
- Tapping empty slots opens creation form pre-filled
- Filter persists across view changes
- No event data lost during view transitions

### Gesture Handling

- **Swipe left/right:** Navigate to next/previous period
- **Swipe up:** Zoom into more detail (week→day not usual, but month→week)
- **Long press:** Show event quick actions (edit, delete, share)
- **Double tap:** Create event in tapped time slot (optional)

### State Management

- Track current view (day/week/month)
- Track current date range being displayed
- Track active filter
- Preserve state when returning from detail sheets
- Cache visible events to avoid refetch on view change

### Real-Time Updates

- If someone in your group creates an event, calendar updates
- If someone votes on a proposal, pending event badge updates
- If event confirmed from proposal, moves to solid colored block

### Analytics Tracking

- `calendar_view_changed` (to which view)
- `date_navigated` (forward/backward)
- `filter_applied` (which filter)
- `event_tapped`
- `empty_slot_tapped` (create from slot)
- `time_spent_in_view` (duration in each view)

---

## FLOW 9: NOTIFICATIONS & INBOX

**Objective:** User receives push notifications, views organized inbox by notification type, and manages notification preferences.

### Journey Map

```
Push Notification received
  ├─ Lock screen shows notification
  │   ├─ Title: "New event proposal: Secret Santa Planning"
  │   ├─ Body: "College Friends - vote by Dec 15"
  │   └─ Actions: [View] [Mute] (if available)
  │
  └─ User taps notification → Opens app to Inbox tab
      ↓
Inbox Tab (badge shows unread count)
  ├─ Badge: "3" (unread notifications)
  │
  ├─ Section: "Pending Votes" (highest priority)
  │   ├─ Needs your action - event proposals
  │   ├─ Event Proposal Card: "Secret Santa Planning"
  │   │   ├─ Group: "College Friends"
  │   │   ├─ Proposed by: "Sarah"
  │   │   ├─ Best option: "Dec 16, 2-4pm (7/8 available)"
  │   │   ├─ Your vote status: "You voted: Available"
  │   │   └─ Time to vote: "Vote by Dec 15, 11:59pm"
  │   │
  │   └─ Tap card → Opens voting sheet (Flow 5)
  │
  ├─ Section: "Confirmed Events" (next priority)
  │   ├─ Group events that are now confirmed
  │   ├─ Event Card: "Secret Santa Planning - Sat Dec 16, 2-4pm"
  │   │   ├─ Status badge: "Confirmed"
  │   │   ├─ Location: "TBD"
  │   │   └─ Added to calendar: "Dec 16"
  │   │
  │   └─ Tap card → Opens event detail
  │
  ├─ Section: "Friend Requests"
  │   ├─ Person cards with avatars
  │   ├─ Friend Card: "Mike"
  │   │   ├─ "@mikesmith"
  │   │   ├─ Mutual friends count
  │   │   └─ [Accept] [Decline] buttons
  │   │
  │   └─ Tap card or buttons → Accept/decline
  │
  └─ Section: "Activity Feed" (lowest priority)
      ├─ General updates and social activity
      ├─ "[Sarah] joined College Friends"
      ├─ "[Mike] voted on Secret Santa Planning"
      ├─ "[Jordan] added a new event"
      └─ Swipe to dismiss individual activity items
  ↓
Pull to refresh
  ├─ Refetches notifications from backend
  └─ Shows last updated time
  ↓
Swipe left on notification
  ├─ Shows action buttons: [Archive] [Delete] / [Mute]
  └─ Swiped item moves to Archived section (or deleted)
```

### Key Screens

**Inbox Tab:**
- Multiple sections with collapsible headers
- "Pending Votes" section at top (collapses if empty)
- Color-coded badges for unread/priority
- Pull-to-refresh functionality
- Empty state message if no notifications

**Proposal Card (in Pending Votes):**
- Event title prominent
- Organizer name
- Group name
- Best time option with vote count
- User's current vote status
- Deadline/voting deadline

**Friend Request Card:**
- Avatar and name
- Username or identifier
- Mutual friends count (if applicable)
- [Accept] and [Decline] buttons
- Color-coded (orange or blue)

**Activity Feed Item:**
- Small avatar of actor
- Action description (lightweight)
- Related event or item name
- Timestamp
- Swipe to dismiss

### Success Criteria

- Unread count badge accurate
- "Pending Votes" section shows active proposals only
- "Confirmed Events" section shows newly created events
- Friend requests show all pending requests
- Activity feed displays updates in chronological order
- Swipe actions work (archive/delete)
- Pull-to-refresh fetches latest notifications
- Deep link from notification opens correct sheet
- Archive/delete actually removes items from inbox

### Push Notification Types

1. **New Proposal** - "New event proposal: [Title]"
2. **Vote Reminder** - "[Friend] voted on [Event]" or "Voting closes in 1 hour"
3. **Event Confirmed** - "[Event] confirmed for [Time]"
4. **Friend Request** - "[Friend] added you as a friend"
5. **Friend Accepted** - "[Friend] accepted your friend request"
6. **Group Invitation** - "[Friend] added you to [Group]"
7. **Vote Deadline** - "Voting closes soon: [Event]"

### Real-Time Updates

- New notifications appear at top of inbox instantly
- Vote count updates in proposal cards (WebSocket)
- Proposal moves to "Confirmed Events" when deadline passed
- Archive actions sync across devices

### Notification Preferences (Flow 10)

- User controls which notification types are enabled
- Can mute specific events or groups
- Mute for 1 hour, 8 hours, or until tomorrow
- Do Not Disturb schedule

### State Management

- Track read/unread status for each notification
- Preserve section open/collapse state
- Handle archive/deletion with undo option
- Cache notification list for fast load

### Analytics Tracking

- `notification_received` (type)
- `notification_tapped` (which type, leading to which action)
- `inbox_opened`
- `proposal_voted_from_notification`
- `time_to_action` (notification received to user action)
- `notification_archived` / `notification_deleted`

---

## FLOW 10: SETTINGS & PRIVACY

**Objective:** User accesses account settings, manages privacy preferences, controls notification behavior, and manages subscriptions.

### Journey Map

```
Bottom Tab Navigation → "Profile" tab
  ↓
Profile View
  ├─ User avatar (tappable to change)
  ├─ Display name (tappable to edit)
  ├─ Username (read-only, show your friend code option)
  │
  ├─ [Friends] button → Friends list (Flow 7)
  │
  └─ [Settings] button
      ↓
Settings Screen
  ├─ Section: "Account"
  │   ├─ Display Name (editable inline)
  │   ├─ Email (editable, requires verification)
  │   ├─ Phone Number (optional, for faster friend finding)
  │   ├─ Profile Photo (tap to upload from camera/library)
  │   └─ Change Password
  │
  ├─ Section: "Privacy Settings" ⭐ (key feature)
  │   ├─ Default Event Visibility (radio buttons)
  │   │   ├─ (O) "Private" - Only you can see
  │   │   ├─ (O) "Shared with name" - Friends see title & time
  │   │   └─ (O) "Busy only" - Friends see you're busy
  │   │
  │   ├─ "Who can see my calendar by default?" (advanced)
  │   │   ├─ (O) "Nobody"
  │   │   ├─ (O) "My friends"
  │   │   └─ (O) "Specific groups" → selector
  │   │
  │   ├─ Per-Group Privacy Overrides (collapsible section)
  │   │   ├─ "College Friends"
  │   │   │   └─ Visibility: [Private ▼] [Shared ▼] [Busy ▼]
  │   │   │
  │   │   ├─ "Roommates"
  │   │   │   └─ Visibility: [Private ▼]
  │   │   │
  │   │   └─ [+ Add group-specific setting]
  │   │
  │   └─ Blocked Users
  │       ├─ List of blocked users
  │       ├─ Each entry: [Avatar] [Name] [Unblock ×]
  │       └─ [+ Block User] button
  │
  ├─ Section: "Notifications"
  │   ├─ Toggle: "Push Notifications" (master switch)
  │   ├─ Toggle: "Event proposals"
  │   ├─ Toggle: "Voting reminders"
  │   ├─ Toggle: "Friend requests"
  │   ├─ Toggle: "Event confirmations"
  │   ├─ Do Not Disturb Schedule
  │   │   └─ [10pm - 8am] (editable)
  │   └─ Notification sound selector
  │
  ├─ Section: "Calendar Sync"
  │   ├─ Toggle: "Sync with Apple Calendar" (on/off)
  │   ├─ Status: "Last synced: 2 minutes ago"
  │   ├─ [Sync Now] button (force immediate sync)
  │   └─ Sync frequency selector: [Every 15 min] [Every 30 min] [Hourly]
  │
  ├─ Section: "Data & Storage"
  │   ├─ Cache size indicator
  │   ├─ [Clear Cache] button
  │   └─ Export Calendar Data (CSV/ICS download)
  │
  ├─ Section: "Subscription"
  │   ├─ Current plan: "Free"
  │   ├─ [Upgrade to Premium] button → Payment flow
  │   ├─ Restore Purchase (if lapsed)
  │   └─ Manage Subscription (if active)
  │
  ├─ Section: "About"
  │   ├─ App version: "1.0.0"
  │   ├─ Terms of Service (link)
  │   ├─ Privacy Policy (link)
  │   ├─ Contact Support (opens email)
  │   └─ Report a Bug (opens feedback form)
  │
  └─ [Log Out] button (red, destructive style)
      ↓
```

### Key Screens

**Profile Tab (Main):**
- User avatar, name, username at top
- Quick access buttons: [Friends] [Settings]
- Friend code and QR code shareable section
- Brief stats (groups, confirmed events, etc.)

**Account Settings:**
- Editable fields: name, email, phone, photo
- Password change button
- Settings applied immediately or on Save (UX decision)

**Privacy Settings (Detailed):**
- Default visibility picker (3 options)
- Per-group overrides (expandable list)
- Blocked users list with unblock action
- Clear, visual explanation of each privacy level

**Notification Preferences:**
- Master toggle for push notifications
- Individual toggles for each notification type
- Do Not Disturb schedule with time picker
- Notification sound/haptic selector

**Calendar Sync Settings:**
- Apple Calendar toggle
- Last sync time displayed
- Manual sync button
- Sync frequency selection (dropdown)

**Subscription/Payment:**
- Current plan displayed
- Upgrade button (leads to payment flow)
- Manage subscription (if premium)
- Restore purchase button (for users on other devices)

### Success Criteria

- All settings persist across app sessions
- Privacy changes take effect immediately (database RLS updated)
- Push notification settings respected
- Calendar sync respects user preferences
- Do Not Disturb schedule prevents notifications during quiet hours
- Per-group privacy overrides work correctly
- Blocked users cannot see calendar or send friend requests
- Password change requires current password
- Email change requires verification
- Logout clears all local data and returns to login

### Privacy Setting Behavior

**Default Event Visibility:**
- Applies to all new events created
- Can be overridden per-event (Flow 2)
- Saved to `users.default_event_visibility` in Supabase

**Per-Group Privacy:**
- Overrides default visibility for events shared with specific group
- Example: Default is "Shared with name", but "College Friends" sees "Busy only"
- Stored in `calendar_sharing` table (user_id, group_id, visibility)

**Blocked Users:**
- Blocked users cannot:
  - See user's calendar (any visibility level ignored)
  - Send friend requests
  - Add user to groups
  - Vote on proposals from user
- RLS policies enforce blocking at database level

### State Management

- Track unsaved changes, warn on back
- Auto-save individual toggle changes (no explicit Save button needed)
- Handle settings that require backend confirmation
- Manage modal/sheet navigation within settings

### Analytics Tracking

- `settings_opened`
- `privacy_setting_changed` (which setting, from what to what)
- `notification_setting_changed`
- `blocked_user_added`
- `sync_frequency_changed`
- `apple_calendar_sync_toggled`
- `premium_upgrade_initiated`
- `logout`

### Subscription Flow (Premium)

- Tap [Upgrade to Premium]
- Opens sheet showing benefits:
  - Smart time suggestions
  - Event location details
  - Special templates (Surprise party, Potluck)
  - No ads (if applicable)
- Show pricing: $4.99/month or $49.99/year
- Tap [Subscribe]
- Uses Stripe/RevenueCat for payment
- On success, app updates and premium features unlock
- Manage subscription via App Store

---

## COMMON PATTERNS

### Navigation Patterns

**Sheet Navigation (Bottom Sheet)**
- Event creation, editing, group creation
- Settings and filters
- Animation: Slide up from bottom, dismiss by swiping down
- Gesture: Swipe down dismisses without saving if appropriate
- Z-index: Sheets above calendar, overlay semi-transparent background

**Tab Navigation (Bottom Tabs)**
- Calendar | Groups | Inbox | Profile
- 4 main tabs, persistent across navigation
- Badge counts on Groups and Inbox
- Tapping active tab scrolls to top

**Modal Navigation (Full Screen)**
- Details sheets that need full focus
- Proposal voting, event details
- Dismiss: Swipe down or [Close] button

**Stack Navigation (Push/Pop)**
- Within settings or detail views
- Bread crumb or back button for navigation
- Swipe left edge to pop

### Error Handling Patterns

**Validation Errors (Form Level):**
- Red border around field
- Error message below field in red text
- Clear indication of what's wrong
- Disable submit until corrected

**Network Errors (Server Level):**
- Toast notification at bottom: "Network error. Retrying..."
- Manual [Retry] button if auto-retry fails
- Show last known good data while retrying
- Offline queue for local changes

**Permission Errors:**
- Modal explaining what permission is needed and why
- [Allow] opens system settings
- [Not Now] allows app to continue (show reminder later)

**Conflict Errors (Sync Conflicts):**
- Modal showing conflicting versions (app vs Apple Calendar)
- [Use App Version] [Use Calendar Version] [Review Both]
- Clear explanation of what happened

### Loading States

**Spinner (Network Request):**
- Centered spinner in modal/sheet
- Message: "Loading..." or specific action (e.g., "Creating event...")
- Prevents user interaction until complete

**Skeleton Screens (Content Load):**
- Gray placeholder blocks matching final layout
- Animated shimmer effect
- Shows expected structure while data loads

**Optimistic Updates:**
- Show change immediately (voting, creating event)
- Roll back if server responds with error
- No spinner needed for fast operations

### Empty States

**No Events:**
- Illustration or icon
- "No events yet" message
- CTA: "Tap + to create your first event"

**No Groups:**
- Illustration showing friend groups
- "No friend groups yet" message
- CTA: "Tap + to create a group"

**No Proposals:**
- "No pending proposals" message
- Optional: "Create one by tapping +"

### Success Feedback

**Toast Notifications:**
- Bottom of screen, non-intrusive
- Dismiss automatically after 3 seconds
- "Event created", "Proposal sent", "Vote recorded"

**Haptic Feedback:**
- Light feedback on button tap
- Medium feedback on vote submission
- Success/confirmation haptic

**Animations:**
- Confetti on event confirmation (optional delight)
- Bounce animation on vote submission
- Scale animation on button tap (feedback)

### Back / Cancel Behavior

**Navigation Back:**
- Back button returns to previous screen
- Swiping left edge also triggers back
- State preserved if navigating away and back

**Cancel (Discard Changes):**
- [Cancel] button on form sheets
- Warning: "Discard changes?" if user edited anything
- [Keep Editing] or [Discard] options

**Dismissing Sheets:**
- Swipe down to dismiss (if no unsaved changes)
- Swiping with unsaved changes shows confirmation
- [X] button in header also dismisses

---

## FLOW DECISION POINTS

### Key Branching Paths

**Event Creation Flow (Flow 2)**
- User chooses privacy level → different visibility to groups
  - Private: Not visible to anyone
  - Shared: Visible to selected groups
  - Busy only: Visible as busy block only
- Each choice leads to different group selector display

**Event Proposal Flow (Flow 4)**
- User can add 1-5 time slots
- Availability shown for each slot (influences choice)
- Sending proposal initiates voting in group members' views (Flow 5)

**Group Event Proposal Response (Flow 5)**
- User votes "Available", "Maybe", or "Can't Make It"
- Vote affects "best option" badge for other group members
- System auto-creates event if all voted or deadline passed

**Group Calendar View (Flow 6)**
- User can explore any visible time block
- Tapping "Propose event here" starts Flow 4 with pre-filled time
- Availability display respects privacy rules

**Friend Management (Flow 7)**
- Adding friend via search vs QR code vs contact import
- Creating group vs adding to existing group
- Accepting group invitation (if applicable)

### User Choice Impacts

**Privacy Choice:**
- Determines visibility to groups across all their events
- Can be overridden per-event
- Can be set per-group

**Vote Choice:**
- Affects group's ability to find common time
- Influences which time slot is marked "best option"
- May trigger auto-event creation

**Calendar Sync Choice:**
- Enables bidirectional sync with Apple Calendar
- Changes stored in `events.apple_calendar_id`
- Disabling stops new sync but doesn't delete existing synced events

### System Decision Logic

**Best Option Badge (Flow 5):**
- Algorithm: Highest count of "Available" votes
- Tie-breaking: Earlier time slot wins
- Re-evaluates in real-time as votes come in

**Auto-Event Creation Trigger (Flow 5):**
- When all group members voted, OR
- When voting deadline passed
- Confirms winning time option
- Creates event in all group members' calendars
- Status changes from "Pending Votes" to "Confirmed Events"

**Heatmap Color (Flow 6):**
- Green: >75% available
- Yellow: 50-75% available
- Red: <50% available
- Gray: No visibility or all private

### Recovery Paths

**Failed Event Creation:**
- User taps retry, form pre-filled with previous input
- No data lost, user can re-attempt
- Error message shows reason and solution

**Failed Vote Submission (Flow 5):**
- Show retry button
- Keep voting interface open
- Preserve user's vote choice visually

**Lost Connection:**
- Show "Offline" indicator
- Queue local changes for sync
- Sync when connection restored
- Show badge "X pending changes"

---

## SUCCESS CRITERIA BY FLOW

### Flow 1: Onboarding

**Successful Completion:**
- User account created with email verified
- Calendar access permission granted (or explicitly skipped)
- Notifications permission granted (or explicitly skipped)
- User reaches calendar view ready to create events
- All permission states saved (don't re-prompt unnecessarily)

**Drop-off Points to Monitor:**
- Sign-up form (high drop-off expected)
- Permission request modals (users skip permissions)
- Onboarding tooltips (users dismiss without reading)

**Analytics Tracking:**
- `onboarding_completed` (percentage)
- `permission_denial_rate` (calendar access)
- `permission_denial_rate` (notifications)
- `time_to_first_event` (useful engagement metric)

### Flow 2: Personal Event Creation

**Successful Completion:**
- Event saved to database
- Event visible on calendar immediately
- Event synced to Apple Calendar (if enabled)
- Privacy settings applied correctly
- Event not visible to groups not selected

**Drop-off Points:**
- Complex privacy settings confuse users (simplify UI)
- Users delete event immediately (UI issue or intent)
- Sync failures cause user frustration

**Analytics Tracking:**
- `event_created_count` (daily/monthly)
- `privacy_setting_distribution` (which setting most used)
- `sync_success_rate` (Apple Calendar)
- `event_edit_frequency` (suggest better defaults)

### Flow 3: Editing Existing Event

**Successful Completion:**
- Event changes saved
- Privacy changes take effect
- Changes visible to affected groups immediately
- No duplicate events created

**Drop-off Points:**
- Sync conflicts confuse users
- Users unable to find edit option
- Time pickers confusing on certain devices

**Analytics Tracking:**
- `event_edited_count`
- `privacy_change_frequency`
- `sync_conflict_rate`
- `edit_abandonment_rate`

### Flow 4: Creating Group Event Proposal

**Successful Completion:**
- Proposal saved with at least 1 time slot
- All group members receive notification
- Proposal visible in their inbox with voting interface
- Availability heatmap shows correctly for each slot

**Drop-off Points:**
- Users don't know how to propose events
- Time slot selection is confusing
- Low visibility of "Propose Group Event" option

**Analytics Tracking:**
- `proposal_created_count`
- `time_slot_count_distribution` (1-5)
- `proposal_notification_delivery_rate`
- `average_availability_per_slot` (guidance for users)

### Flow 5: Responding to Group Event Proposal

**Successful Completion:**
- User votes on at least one time option
- Vote recorded immediately
- Vote count updates in real-time for others
- Event auto-created when deadline passed or all voted
- Event added to user's calendar

**Drop-off Points:**
- Users miss notification (notification delivery issue)
- Users unsure how to vote (unclear UI)
- Voting deadline passed before user acts
- WebSocket connection issues prevent real-time updates

**Analytics Tracking:**
- `notification_tap_through_rate` (Flow 5 engagement)
- `vote_submission_rate` (% of users voting)
- `avg_time_to_vote` (metric of urgency)
- `auto_confirm_trigger_rate` (deadline vs all voted)
- `event_added_to_calendar_success_rate`

### Flow 6: Viewing Group Calendars

**Successful Completion:**
- Heatmap loads quickly and accurately
- User can tap time blocks to see details
- "Propose event here" pre-fills date/time in Flow 4
- Privacy rules respected (no private event details shown)

**Drop-off Points:**
- Heatmap doesn't load (performance issue)
- Colors confusing (legend help needed)
- Users don't understand how to use availability data

**Analytics Tracking:**
- `group_calendar_opened_rate`
- `avg_time_on_calendar` (engagement)
- `heatmap_load_time` (performance)
- `color_confusion_feedback` (if tracked)
- `propose_from_calendar_rate` (Flow 4 conversion)

### Flow 7: Friend Management

**Successful Completion:**
- Friend or group created successfully
- Invitations sent and delivered
- Invited users notified
- Users can accept/join and see each other in groups

**Drop-off Points:**
- Users unable to find friend management
- Search doesn't find friends
- QR code fails to scan
- Contact import permissions denied

**Analytics Tracking:**
- `friend_added_count`
- `group_created_count`
- `invitation_acceptance_rate`
- `contact_import_permission_denial_rate`
- `qr_scan_success_rate`

### Flow 8: Calendar Views & Navigation

**Successful Completion:**
- All three views (day/week/month) functional
- Swiping gestures work smoothly
- Filter applied and persists
- Events display with correct colors
- No data loss during navigation

**Drop-off Points:**
- Users confused about swipe vs tap
- Month view too compressed to read events
- Filter state lost (frustrating UX)

**Analytics Tracking:**
- `view_switch_frequency` (day vs week vs month preference)
- `filter_usage_rate`
- `swipe_gesture_success_rate` (vs taps)
- `view_load_time` (performance metric)

### Flow 9: Notifications & Inbox

**Successful Completion:**
- All notification types delivered correctly
- Inbox shows unread count accurately
- Categories organized correctly
- Tapping notification deep-links to correct flow
- Actions (accept, vote, dismiss) work

**Drop-off Points:**
- Users miss notifications (delivery, volume)
- Inbox too cluttered (organization issue)
- Notifications are noisy (preference issue)

**Analytics Tracking:**
- `notification_delivery_rate` (by type)
- `notification_open_rate` (tap through)
- `inbox_mute_rate` (users disabling)
- `notification_action_rate` (% taking action vs dismissing)

### Flow 10: Settings & Privacy

**Successful Completion:**
- All settings changes persisted
- Privacy changes take effect immediately
- Notification preferences respected
- Calendar sync works per user selection
- Blocked users cannot interact

**Drop-off Points:**
- Users confused about privacy options
- Settings don't persist (data loss)
- Notifications still delivered despite Do Not Disturb
- Sync settings broken

**Analytics Tracking:**
- `settings_opened_rate`
- `privacy_setting_change_frequency`
- `notification_setting_changes` (which settings changed)
- `premium_upgrade_rate` (conversion metric)
- `settings_confidence_survey` (user survey, optional)

---

## Implementation Notes for Developers

### Recommended Development Order

**Priority 1 (Core):**
1. Flow 1: Onboarding (enable app launch)
2. Flow 2: Personal Event Creation (core feature)
3. Flow 8: Calendar Views (primary interface)

**Priority 2 (Group MVP):**
4. Flow 7: Friend Management (enable groups)
5. Flow 4: Group Event Proposals (core group feature)
6. Flow 5: Voting (complete proposal flow)

**Priority 3 (Polish & Completion):**
7. Flow 3: Event Editing (completeness)
8. Flow 6: Group Calendars (exploration)
9. Flow 9: Notifications & Inbox (engagement)
10. Flow 10: Settings (user control)

### State Management Across Flows

- **User Context:** Store in AppDelegate or Combine Publisher
  - Current user info, groups, friends
  - Notification permissions status
  - Calendar sync status

- **Navigation State:** Track in a NavigationController or SwiftUI @State
  - Current flow/sheet
  - Parameters passed to flows
  - Back stack

- **Cache:** Use Core Data or SQLite for offline support
  - Recent calendar events
  - Group list and members
  - Proposal history

### Error Recovery Checklist

For each flow, implement:
- [ ] Network error retry button
- [ ] Validation error messages with clear guidance
- [ ] Sync conflict detection and resolution
- [ ] Offline queue for changes made while disconnected
- [ ] Automatic retry for transient failures
- [ ] User notification for persistent failures
- [ ] Fallback to cached data when available

### Real-Time Features Checklist

For WebSocket integration:
- [ ] Subscribe to relevant tables on flow entry
- [ ] Unsubscribe on flow exit (prevent memory leaks)
- [ ] Show connection status indicator if poor network
- [ ] Optimistic UI updates for local changes
- [ ] Rollback UI on server error
- [ ] Handle reconnection gracefully
- [ ] Cache subscription state across navigation

---

**Document Version:** 1.0
**Last Updated:** December 1, 2025
**Status:** Final - Ready for Development
