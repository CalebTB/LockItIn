# Lock-In: Edge Cases & Error Handling Guide

A comprehensive reference for all edge case scenarios, error handling strategies, and UX patterns for the Lock-In iOS calendar app.

**Last Updated:** December 1, 2025
**Version:** 1.0
**Status:** Ready for Development

---

## Overview

This document consolidates 12 categories of edge cases and complex scenarios encountered during event planning, group coordination, calendar synchronization, and real-time voting. It serves as:

- **Development Reference:** Specific error handling code patterns and recovery paths
- **QA Test Matrix:** Comprehensive scenarios to validate during testing
- **UX Guideline:** Required patterns for user feedback and error messaging
- **Performance Tuning:** Optimization targets and threshold values

### How to Use This Document

1. **During Planning:** Reference the priority framework to determine MVP scope
2. **During Development:** Use specific scenarios as acceptance criteria for user stories
3. **During Testing:** Follow the edge case scenarios as test cases
4. **During Code Review:** Verify that error handling matches documented patterns

### Priority Framework

**MUST-HAVE (Tier 1 - Core Experience):**
- Offline queue for all user actions
- Conflict resolution for sync conflicts
- Graceful degradation (partial data > no data)
- Undo/redo for destructive actions
- Real-time vote updates via WebSocket
- Optimistic UI for all interactions

**SHOULD-HAVE (Tier 2 - Polish):**
- Smart suggestions (privacy recommendations, time patterns)
- Micro-interactions (haptic feedback, confetti, animations)
- Beautiful empty states
- Progressive disclosure of advanced features
- Accessibility support (VoiceOver, Dynamic Type)

**NICE-TO-HAVE (Tier 3 - Delight):**
- Duplicate detection and merging
- Advanced pattern recognition
- Battery/performance optimization
- Analytics and insights

---

## Key Takeaways for Development

### Must-Have Error Handling Patterns

1. **Offline Queue**
   - Store all user actions in local database
   - Queue flag: `is_synced: boolean`
   - Sync on app foreground or when connection restored
   - Show "⏳ Sending..." indicator while queued
   - Retry failed items with exponential backoff

2. **Conflict Resolution**
   - Use "last-write-wins" strategy with timestamps
   - Always notify user of conflicts with clear options
   - Provide undo option (5-second toast)
   - Store conflict history for transparency

3. **Graceful Degradation**
   - Show partial data rather than empty state
   - Indicate which data is incomplete
   - Provide "Retry" or "Continue Anyway" option
   - Cache aggressively and serve stale data

4. **Undo Actions**
   - 5-second toast notification after deletions
   - "Undo" button in toast (tap to restore)
   - Visual feedback of restoration
   - Don't allow undo after 5 seconds expire

5. **Smart Defaults**
   - Pre-fill based on context (recent groups, last event time)
   - Suggest privacy settings based on event keywords
   - Auto-detect conflicts and offer solutions
   - Remember user preferences

### UX Polish Requirements

1. **Real-Time Updates**
   - Use Supabase Realtime WebSocket for vote counts
   - Subscribe only to active proposal screens
   - Unsubscribe on navigation away
   - Show live vote notifications with haptic feedback

2. **Optimistic UI**
   - Show user action immediately
   - Disable retry/undo during optimistic update
   - Rollback seamlessly on error
   - Queue for later if offline

3. **Micro-Interactions**
   - Haptic feedback for votes, deletions, confirmations
   - Spring physics animations for list items
   - Confetti animation on event confirmation
   - Smooth transitions between screens
   - Loading indicators that don't block UI

4. **Empty States**
   - Beautiful illustrations for empty states
   - Clear call-to-action buttons
   - Helpful tips for getting started
   - Progress indicators (e.g., "0/3 groups created")

5. **Loading States**
   - Show skeleton loaders for content
   - Indicate which data is loading
   - Timeout after 10 seconds with "Retry" option
   - Never show complete blank screen

### Performance Considerations

1. **Lazy Loading**
   - Load groups on-demand (20 at a time)
   - Paginate calendar events (last 30 days + next 60 days)
   - Load availability data per group
   - Don't fetch all data on app launch

2. **Caching Strategy**
   - Cache calendar data with TTL (15 minutes)
   - Cache group membership (24 hours)
   - Cache user preferences (until changed)
   - Serve stale cache while refreshing

3. **Background Sync**
   - Sync on app foreground
   - Sync every 15 minutes (if app in foreground)
   - Background sync on iOS (when allowed)
   - Batch multiple changes into single sync

4. **Debounce/Throttle**
   - Search: 300ms debounce
   - Text input: 500ms debounce
   - Scroll events: 100ms throttle
   - Vote updates: 100ms throttle (show latest)

5. **Pagination**
   - Calendar events: 20 per page
   - Group members: 50 per page
   - Proposals: 10 per page
   - Implement "load more" with spinner

---

## 1. Event Creation Edge Cases

### Scenario: User creates event during existing busy time

**UI Flow:**
```
User selects Dec 15, 2:00-4:00 PM
System detects "Team Meeting" 2:00-3:00 PM conflict

┌─────────────────────────────────────┐
│  ⚠️ SCHEDULING CONFLICT              │
├─────────────────────────────────────┤
│                                     │
│  You already have:                  │
│  "Team Meeting"                     │
│  2:00 - 3:00 PM                     │
│                                     │
│  New event:                         │
│  "Lunch with Sarah"                 │
│  2:00 - 4:00 PM                     │
│                                     │
│  Options:                           │
│  ┌───────────────────────────┐     │
│  │ [Create Anyway]           │     │
│  └───────────────────────────┘     │
│  ┌───────────────────────────┐     │
│  │ [Adjust Time]             │     │
│  │ (suggests 3:00-5:00 PM)   │     │
│  └───────────────────────────┘     │
│  ┌───────────────────────────┐     │
│  │ [Cancel]                  │     │
│  └───────────────────────────┘     │
│                                     │
└─────────────────────────────────────┘
```

**Error Handling:**
- Check all personal calendars (including Apple Calendar sync)
- Detect 15-minute buffer conflicts
- Allow double-booking (user's choice)
- Suggest next available time slot
- Log conflict event for analytics

### Scenario: User shares event with privacy conflict

**UI Flow:**
```
User creates "Therapy appointment"
Selects "Shared with name" + College Friends

System suggests:
┌─────────────────────────────────────┐
│  💡 PRIVACY SUGGESTION               │
├─────────────────────────────────────┤
│                                     │
│  This event might be personal.      │
│                                     │
│  Consider:                          │
│  ┌───────────────────────────┐     │
│  │ ⦿ Share as "Busy" instead │     │
│  │   (hides event name)      │     │
│  └───────────────────────────┘     │
│  ┌───────────────────────────┐     │
│  │ ○ Share with name anyway  │     │
│  └───────────────────────────┘     │
│  ┌───────────────────────────┐     │
│  │ ○ Keep private            │     │
│  └───────────────────────────┘     │
│                                     │
│  ☑ Remember for events with:       │
│     "therapy", "doctor", "counseling"│
│                                     │
└─────────────────────────────────────┘
```

**Error Handling:**
- Detect sensitive keywords (therapy, doctor, counselor, etc.)
- Suggest appropriate privacy level
- Remember user preference for keyword
- Don't prevent user choice (just inform)
- Track privacy overrides for support

### Scenario: All-day events

**UI Flow:**
```
User toggles "All-day" switch

┌─────────────────────────────────────┐
│  ☑ All-day event                    │
│                                     │
│  📅  Mon, Dec 16                    │
│  🕐  [Time disabled - grayed out]  │
│                                     │
│  Privacy note:                      │
│  All-day events show as "Busy"      │
│  for the entire day in group        │
│  availability views.                │
└─────────────────────────────────────┘
```

**Error Handling:**
- Disable time fields when all-day is selected
- Always set visibility to "Busy" for all-day events
- Show notification about visibility implications
- Don't allow granular time sharing for all-day events

### Validation Rules

- Event title: 1-200 characters (required)
- Event duration: 15 minutes to 24 hours
- Start time: cannot be before now (for today's events)
- End time: must be after start time
- Location: optional, 0-500 characters
- Description: optional, 0-5000 characters

---

## 2. Group Event Proposals - Complex Interactions

### Scenario: Proposer edits proposal after votes received

**UI Flow:**
```
Mike proposed, 5 people already voted

Mike taps: [...] → Edit Proposal

┌─────────────────────────────────────┐
│  ⚠️ EDIT ACTIVE PROPOSAL             │
├─────────────────────────────────────┤
│                                     │
│  5 people have already voted.       │
│                                     │
│  If you edit, all votes will be     │
│  reset and people will be notified. │
│                                     │
│  What would you like to edit?       │
│                                     │
│  ┌───────────────────────────┐     │
│  │ Title/Description/Location│     │
│  │ (keeps votes)             │     │
│  └───────────────────────────┘     │
│  ┌───────────────────────────┐     │
│  │ Time Options              │     │
│  │ (resets all votes)        │     │
│  └───────────────────────────┘     │
│  ┌───────────────────────────┐     │
│  │ Cancel Proposal           │     │
│  └───────────────────────────┘     │
│                                     │
└─────────────────────────────────────┘
```

**Error Handling:**
- Distinguish safe vs. vote-resetting edits
- Notify all voters when votes are reset
- Provide edit history
- Track edit timestamp for transparency

### Scenario: Tied votes at deadline

**UI Flow:**
```
Voting deadline reached:
Option 1: 4 votes
Option 2: 4 votes
Option 3: 2 votes

┌─────────────────────────────────────┐
│  🤝 IT'S A TIE!                     │
├─────────────────────────────────────┤
│                                     │
│  Secret Santa Planning              │
│                                     │
│  Two options tied with 4 votes each:│
│                                     │
│  ┌───────────────────────────┐     │
│  │ Sat, Dec 14 • 6:00 PM     │     │
│  │ ✓ 4 votes                 │     │
│  │ [Choose This]             │     │
│  └───────────────────────────┘     │
│                                     │
│  ┌───────────────────────────┐     │
│  │ Sun, Dec 15 • 2:00 PM     │     │
│  │ ✓ 4 votes                 │     │
│  │ [Choose This]             │     │
│  └───────────────────────────┘     │
│                                     │
│  Or:                                │
│  [Extend Voting (24 hrs)]           │
│  [Create New Poll]                  │
│                                     │
│  💡 As the organizer, you make      │
│     the final call!                 │
│                                     │
└─────────────────────────────────────┘
```

**Tie-Breaking Logic:**
- Organizer always decides on tie
- Options: choose one, extend voting, create new poll
- Default: do not auto-select (requires human decision)
- Notify all voters of tie and organizer's choice

### Scenario: Someone votes "No" to all options

**UI Flow:**
```
Sarah votes "Can't make it" on all 3 time slots

System flags to proposer:
┌─────────────────────────────────────┐
│  📬 Update on Secret Santa          │
├─────────────────────────────────────┤
│                                     │
│  Sarah can't make any of the        │
│  proposed times.                    │
│                                     │
│  ┌───────────────────────────┐     │
│  │ [Message Sarah]           │     │
│  └───────────────────────────┘     │
│  ┌───────────────────────────┐     │
│  │ [Add More Time Options]   │     │
│  └───────────────────────────┘     │
│  ┌───────────────────────────┐     │
│  │ [Proceed Without Sarah]   │     │
│  └───────────────────────────┘     │
│                                     │
└─────────────────────────────────────┘
```

**Error Handling:**
- Detect when one person votes "No" to all options
- Notify proposer immediately
- Flag person in voting results
- Suggest messaging or adding options
- Count final availability with/without that person

### Scenario: Last-minute vote changes the leader

**UI Flow:**
```
7/8 people voted, Option 2 winning with 5 votes
Jordan (last person) votes for Option 1

Real-time update for all:
┌─────────────────────────────────────┐
│  🔄 VOTES UPDATED                   │
├─────────────────────────────────────┤
│                                     │
│  Jordan just voted!                 │
│                                     │
│  New leader:                        │
│  ✓ Option 1: Sun, Dec 15 • 2:00 PM │
│    6 votes (was 5)                  │
│                                     │
│  Previous leader:                   │
│  • Option 2: Mon, Dec 16 • 7:00 PM │
│    5 votes                          │
│                                     │
│  [View full results]                │
│                                     │
└─────────────────────────────────────┘
```

**Error Handling:**
- Use WebSocket subscriptions for real-time updates
- Show vote change notifications with haptic feedback
- Throttle updates to 100ms to avoid spam
- Provide option to view full vote breakdown

### Voting Rules

- Each person votes once per proposal
- Vote options: "Available" / "Maybe" / "Can't Make It"
- Proposal voting deadline: 48 hours (configurable)
- Minimum votes needed: 50% of group members
- Can change vote until deadline
- Vote is anonymous (visible to organizer only in first phase)

---

## 3. Calendar Sync - Edge Cases

### Scenario: Apple Calendar permission denied

**UI Flow:**
```
User signs up, denies calendar access

┌─────────────────────────────────────┐
│  📅 LIMITED MODE                    │
├─────────────────────────────────────┤
│                                     │
│  You're using the app without       │
│  calendar access.                   │
│                                     │
│  You can still:                     │
│  ✓ Create events in this app        │
│  ✓ Join group events                │
│  ✓ Vote on proposals                │
│                                     │
│  But you can't:                     │
│  ✗ Sync with Apple Calendar         │
│  ✗ Auto-import existing events      │
│  ✗ Show accurate availability       │
│                                     │
│  ⚠️ Friends won't see your true     │
│     availability for group planning.│
│                                     │
│  ┌───────────────────────────┐     │
│  │ [Enable Calendar Access]  │     │
│  └───────────────────────────┘     │
│  ┌───────────────────────────┐     │
│  │ [Continue in Limited Mode]│     │
│  └───────────────────────────┘     │
│                                     │
└─────────────────────────────────────┘
```

**Error Handling:**
- Request calendar access during onboarding (not launch)
- Allow app to function without calendar access
- Store flag: `has_calendar_permission`
- Show banner when permission is denied
- Offer easy re-request in settings

### Scenario: Event modified in Apple Calendar

**UI Flow:**
```
User edits "Team Meeting" in Apple Calendar:
Changes time from 9:00 AM → 10:00 AM

On next sync:
┌─────────────────────────────────────┐
│  🔄 SYNC UPDATE                     │
├─────────────────────────────────────┤
│                                     │
│  "Team Meeting" changed in          │
│  Apple Calendar                     │
│                                     │
│  Old: Mon 9:00 - 10:00 AM           │
│  New: Mon 10:00 - 11:00 AM          │
│                                     │
│  This affects:                      │
│  • Your availability for            │
│    "Coffee with Sarah" proposal     │
│                                     │
│  ┌───────────────────────────┐     │
│  │ [Update & Notify Friends] │     │
│  └───────────────────────────┘     │
│  ┌───────────────────────────┐     │
│  │ [Update Silently]         │     │
│  └───────────────────────────┘     │
│                                     │
└─────────────────────────────────────┘
```

**Error Handling:**
- Detect modifications by comparing stored event data
- Determine if change affects group availability
- Notify group members if availability changed
- Provide option for silent update
- Store change history

### Scenario: Event deleted in Apple Calendar

**UI Flow:**
```
User deletes group event "Secret Santa" in Apple Calendar

On sync:
┌─────────────────────────────────────┐
│  ⚠️ DELETED IN APPLE CALENDAR        │
├─────────────────────────────────────┤
│                                     │
│  "Secret Santa Planning" was        │
│  deleted from your Apple Calendar.  │
│                                     │
│  This is a group event with 8 people│
│                                     │
│  What would you like to do?         │
│                                     │
│  ┌───────────────────────────┐     │
│  │ [Restore Event]           │     │
│  └───────────────────────────┘     │
│  ┌───────────────────────────┐     │
│  │ [Leave Group Event]       │     │
│  │ (notifies others)         │     │
│  └───────────────────────────┘     │
│  ┌───────────────────────────┐     │
│  │ [Keep Deleted]            │     │
│  │ (still in group)          │     │
│  └───────────────────────────┘     │
│                                     │
└─────────────────────────────────────┘
```

**Error Handling:**
- Detect deleted events on next sync
- Check if it's a group event or personal
- If group event: offer restore, leave, or ignore
- Notify other group members of deletion
- Don't automatically restore (user's choice)

### Scenario: Duplicate events created

**UI Flow:**
```
User creates "Dentist" in both apps simultaneously

System detects on sync:
┌─────────────────────────────────────┐
│  🔍 POSSIBLE DUPLICATE               │
├─────────────────────────────────────┤
│                                     │
│  Found similar events:              │
│                                     │
│  Event 1 (this app):                │
│  "Dentist Appointment"              │
│  Wed, Dec 18 • 3:00 PM              │
│                                     │
│  Event 2 (Apple Calendar):          │
│  "Dentist"                          │
│  Wed, Dec 18 • 3:00 PM              │
│                                     │
│  Are these the same event?          │
│                                     │
│  ┌───────────────────────────┐     │
│  │ [Merge Events]            │     │
│  └───────────────────────────┘     │
│  ┌───────────────────────────┐     │
│  │ [Keep Both]               │     │
│  └───────────────────────────┘     │
│                                     │
│  ☑ Remember: Auto-merge similar    │
│     events in future                │
│                                     │
└─────────────────────────────────────┘
```

**Error Handling:**
- Check for events with same time and similar names
- Use fuzzy string matching (Levenshtein distance)
- Suggest merge if confidence > 85%
- Allow user to remember preference
- Store link between merged events

### Sync Strategy

**Sync Frequency:**
- On app foreground: immediate
- While in foreground: every 15 minutes
- In background: per iOS background app refresh
- Manual: pull-to-refresh on calendar views

**Sync Scope:**
- Last 30 days + next 60 days only
- Don't sync all historical events
- Paginate large calendars (20 events per batch)
- Debounce sync requests (100ms minimum between syncs)

**Conflict Resolution:**
- Last-write-wins with timestamp comparison
- If tied: Apple Calendar source takes precedence (user trusts it more)
- Notify user of conflicts
- Provide merge/keep/delete options

---

## 4. Group Dynamics - Social Edge Cases

### Scenario: User removed from group mid-proposal

**UI Flow:**
```
You're voting on "Game Night" proposal
Admin removes you from "Gaming Squad" group

Immediate notification:
┌─────────────────────────────────────┐
│  👋 REMOVED FROM GROUP               │
├─────────────────────────────────────┤
│                                     │
│  You were removed from              │
│  "Gaming Squad" by [Admin name]     │
│                                     │
│  Your pending votes have been       │
│  canceled.                          │
│                                     │
│  Upcoming events affected:          │
│  • Game Night (voting)              │
│  • Tournament (Dec 20)              │
│                                     │
│  These events will be removed from  │
│  your calendar.                     │
│                                     │
│  ┌───────────────────────────┐     │
│  │ [OK]                      │     │
│  └───────────────────────────┘     │
│  ┌───────────────────────────┐     │
│  │ [Report Issue]            │     │
│  └───────────────────────────┘     │
│                                     │
└─────────────────────────────────────┘
```

**Error Handling:**
- Use Supabase RLS to prevent further access
- Remove member's votes from all active proposals
- Notify user immediately
- List affected events
- Remove group events from calendar
- Mark removed flag: `removed_at` timestamp

### Scenario: User blocks another user

**UI Flow:**
```
You block Mike

System handles:
┌─────────────────────────────────────┐
│  🚫 USER BLOCKED                    │
├─────────────────────────────────────┤
│                                     │
│  Mike has been blocked.             │
│                                     │
│  Effects:                           │
│  • Removed from all shared groups   │
│    - College Friends (8 → 7)        │
│    - Basketball Crew (6 → 5)        │
│                                     │
│  • Can't see your calendar          │
│  • Can't invite you to events       │
│  • You won't see their proposals    │
│                                     │
│  Affected upcoming events:          │
│  • Secret Santa (you'll remain)     │
│  • Game night (you'll remain)       │
│                                     │
│  ⚠️ Mike will be notified you left  │
│     these groups (not why)          │
│                                     │
│  [Confirm Block]  [Cancel]          │
│                                     │
└─────────────────────────────────────┘
```

**Error Handling:**
- Store block relationship in `blocked_users` table
- Remove from all mutual groups silently
- Prevent all interaction
- Notify blocked user (generic notification)
- Allow unblock from settings

### Scenario: Group admin leaves group

**UI Flow:**
```
Only admin (Mike) leaves "College Friends"

System prompts:
┌─────────────────────────────────────┐
│  👑 TRANSFER OWNERSHIP               │
├─────────────────────────────────────┤
│                                     │
│  You're the only admin of           │
│  "College Friends"                  │
│                                     │
│  Before leaving, assign a new admin:│
│                                     │
│  [👤] Sarah Martinez           [→]  │
│  [👤] Jordan Taylor            [→]  │
│  [👤] Alex Kim                 [→]  │
│  [👤] Chris Park               [→]  │
│  [👤] Emma Wilson              [→]  │
│                                     │
│  Or:                                │
│  ┌───────────────────────────┐     │
│  │ [Delete Entire Group]     │     │
│  │ (affects 7 people)        │     │
│  └───────────────────────────┘     │
│                                     │
│  [Cancel]                           │
│                                     │
└─────────────────────────────────────┘
```

**Error Handling:**
- Detect if user is only admin
- Prevent leaving without admin transfer
- Allow group deletion (nuclear option)
- Notify new admin of transfer
- Notify all members of admin change

### Scenario: Inactive group member

**UI Flow:**
```
Taylor hasn't voted on last 5 proposals
System suggests to admin:

┌─────────────────────────────────────┐
│  💤 INACTIVE MEMBER                 │
├─────────────────────────────────────┤
│                                     │
│  Taylor Smith hasn't participated   │
│  in the last 5 event proposals.     │
│                                     │
│  Last active: 3 weeks ago           │
│                                     │
│  Suggestions:                       │
│  ┌───────────────────────────┐     │
│  │ [Send Reminder]           │     │
│  └───────────────────────────┘     │
│  ┌───────────────────────────┐     │
│  │ [Mark as Optional]        │     │
│  │ (exclude from quorum)     │     │
│  └───────────────────────────┘     │
│  ┌───────────────────────────┐     │
│  │ [Remove from Group]       │     │
│  └───────────────────────────┘     │
│  ┌───────────────────────────┐     │
│  │ [Ignore]                  │     │
│  └───────────────────────────┘     │
│                                     │
└─────────────────────────────────────┘
```

**Error Handling:**
- Track last active timestamp per member
- Detect inactivity after 5+ proposals skipped
- Notify admin (not auto-remove)
- Provide soft options (remind, mark optional)
- Require admin confirmation for removal

---

## 5. Notification Interactions

### Scenario: User has notifications disabled but proposal urgent

**UI Flow:**
```
Voting closes in 1 hour
User has app notifications disabled

In-app banner when they open app:
┌─────────────────────────────────────┐
│  ⏰ URGENT: VOTING ENDS SOON         │
├─────────────────────────────────────┤
│                                     │
│  Secret Santa Planning              │
│  Voting closes in 47 minutes        │
│                                     │
│  You haven't voted yet!             │
│                                     │
│  [Vote Now]    [Dismiss]            │
│                                     │
│  ───────────────────────────────    │
│                                     │
│  💡 Enable notifications to never   │
│     miss deadlines                  │
│                                     │
│  [Turn On Notifications]            │
│                                     │
└─────────────────────────────────────┘
```

**Error Handling:**
- Show in-app banner for urgent deadlines (< 1 hour remaining)
- Don't rely on system notifications alone
- Offer easy enable for notifications
- Dismiss after vote or timeout

### Scenario: Notification clustering

**UI Flow:**
```
5 events updated in 10 minutes

Instead of 5 separate notifications:
┌─────────────────────────────────────┐
│  📬 5 Calendar Updates               │
├─────────────────────────────────────┤
│                                     │
│  • Secret Santa - time confirmed    │
│  • Game night - voting started      │
│  • Friendsgiving - 2 new votes      │
│  • Sarah voted on Coffee meetup     │
│  • Basketball practice - rescheduled│
│                                     │
│  [View All]                         │
│                                     │
└─────────────────────────────────────┘
```

**Error Handling:**
- Batch notifications within 10-minute window
- Group by type (votes, proposals, updates)
- Show summary notification with count
- Include most important item first
- Provide "View All" action

### Scenario: Notification action from lock screen

**UI Flow:**
```
Lock screen notification:
┌─────────────────────────────────────┐
│  📅 Calendar App                    │
│  Secret Santa Planning              │
│  Vote on time options               │
│                                     │
│  [✓ Available] [~ Maybe] [✗ No]    │
│                                     │
└─────────────────────────────────────┘

User taps "✓ Available" without unlocking

Haptic feedback + micro-notification:
┌─────────────────────────────────────┐
│  ✓ Vote recorded!                   │
└─────────────────────────────────────┘
```

**Error Handling:**
- Support interactive notification actions
- Process vote without requiring app open
- Show confirmation with haptic feedback
- Queue offline if needed
- Sync when app opens

### Notification Types

**Voting Alerts:**
- New proposal in group
- Voting deadline approaching (1 hour, 24 hours before)
- Member voted, shifting leader
- Voting ended, needs decision

**Event Updates:**
- Group event confirmed
- Event time changed (affects availability)
- Member availability changed
- Event cancelled

**Social Alerts:**
- New group invitation
- Member removed you
- Group event scheduled
- Member joined group

**Premium Alerts:**
- Trial expiring soon
- Subscription renewal
- Feature limit reached

### Notification Settings

- Per-notification-type toggles
- Do Not Disturb respect (use APNS quiet notifications)
- Notification sound preferences
- Badge count auto-management
- Summary notifications option (iOS 15+)

---

## 6. Offline Connectivity Edge Cases

### Scenario: User votes while offline

**UI Flow:**
```
User votes on 3 proposals with no internet

Visual feedback:
┌─────────────────────────────────────┐
│  Option 2: Sun, Dec 15 • 2:00 PM   │
│                                     │
│  Your response: ✓ Available         │
│  ⏳ Sending...                      │
│                                     │
└─────────────────────────────────────┘

When connection restored:
┌─────────────────────────────────────┐
│  ☁️ SYNCING                         │
├─────────────────────────────────────┤
│                                     │
│  Uploading your votes...            │
│  ✓ Secret Santa                     │
│  ✓ Game night                       │
│  ⏳ Friendsgiving                   │
│                                     │
└─────────────────────────────────────┘
```

**Error Handling:**
- Show "⏳ Sending..." indicator on pending actions
- Store all votes locally immediately
- Auto-sync when connection restored
- Show sync progress
- Notify on sync completion
- Retry failed syncs with exponential backoff

### Scenario: Conflict during offline sync

**UI Flow:**
```
You voted "Available" offline
Meanwhile, event time changed online

When syncing:
┌─────────────────────────────────────┐
│  ⚠️ EVENT CHANGED                    │
├─────────────────────────────────────┤
│                                     │
│  While you were offline, the time   │
│  options changed:                   │
│                                     │
│  You voted for:                     │
│  Sun, Dec 15 • 2:00 PM (removed)    │
│                                     │
│  New options are:                   │
│  • Sat, Dec 14 • 6:00 PM            │
│  • Mon, Dec 16 • 7:00 PM            │
│                                     │
│  Your vote was not counted.         │
│                                     │
│  ┌───────────────────────────┐     │
│  │ [Vote Again]              │     │
│  └───────────────────────────┘     │
│  ┌───────────────────────────┐     │
│  │ [Skip]                    │     │
│  └───────────────────────────┘     │
│                                     │
└─────────────────────────────────────┘
```

**Error Handling:**
- Detect conflicts when syncing offline changes
- Notify user that change happened
- Don't silently discard their vote
- Offer to re-vote on new options
- Log conflict for analytics

### Offline Queue Management

**Queue Table Schema:**
```
offline_queue:
  id: UUID
  user_id: UUID
  action_type: string ('vote', 'create_event', 'edit_event', etc.)
  resource_id: UUID
  payload: JSON
  created_at: timestamp
  synced_at: timestamp (nullable)
  sync_attempts: integer
  last_error: string (nullable)
```

**Sync Logic:**
- Process queue in order (FIFO)
- Retry on network error (max 3 attempts)
- Exponential backoff: 1s, 5s, 30s
- Skip items that fail permanently (404, 403)
- Remove from queue on success
- Show queue status to user

### Offline Capabilities

**Available Offline:**
- View cached calendar
- View cached groups and members
- Create local events
- Vote on cached proposals
- View event details
- Edit local settings

**Not Available Offline:**
- Sync with Apple Calendar
- Create/edit groups
- Send messages
- See live vote updates
- Search across all events

**Offline Indicator:**
- Show cloud icon with "offline" badge
- Display sync status in header
- Show "⏳" indicator on pending items
- Show "No internet" banner at bottom

---

## 7. Availability View Edge Cases

### Scenario: Privacy-mixed group (varied privacy levels)

**UI Flow:**
```
Group of 8 people viewing availability:
- 5 people share full calendar
- 2 people share "busy only"
- 1 person keeps calendar private

Availability view shows:
┌─────────────────────────────────────┐
│  Wednesday 2:00 - 3:00 PM           │
├─────────────────────────────────────┤
│                                     │
│  ✓ AVAILABLE (5/8)                  │
│  • Sarah M.    • Mike J.            │
│  • Jordan T.   • Alex K.            │
│  • You                              │
│                                     │
│  ⚠ BUSY (2/8)                       │
│  • Emma W. (Busy)                   │
│  • Chris P. (Busy)                  │
│                                     │
│  ❓ UNKNOWN (1/8)                    │
│  • Taylor S. (Private calendar)     │
│                                     │
│  💡 Availability: 62% (5/8 confirmed)│
│     Best to ask Taylor directly     │
│                                     │
│  [Propose Event Here]               │
│                                     │
└─────────────────────────────────────┘
```

**Error Handling:**
- Respect RLS policies (don't show hidden events)
- Aggregate availability by privacy level
- Show count by status (available/busy/unknown)
- Indicate why someone is unknown
- Suggest asking directly
- Show confidence percentage

### Scenario: Recurring availability patterns

**UI Flow:**
```
User opens availability view for "every Friday night"

Smart suggestion appears:
┌─────────────────────────────────────┐
│  💡 PATTERN DETECTED                │
├─────────────────────────────────────┤
│                                     │
│  Most of your group is consistently │
│  free on Friday nights 7-9 PM       │
│                                     │
│  Available 80% of the time:         │
│  • Sarah, Mike, Jordan, Alex, You   │
│                                     │
│  Often busy:                        │
│  • Emma (work shifts)               │
│  • Chris (family dinner)            │
│                                     │
│  ┌───────────────────────────┐     │
│  │ [Set Recurring Event]     │     │
│  │ Every Friday, 7-9 PM      │     │
│  └───────────────────────────┘     │
│  ┌───────────────────────────┐     │
│  │ [Propose Specific Date]   │     │
│  └───────────────────────────┘     │
│                                     │
└─────────────────────────────────────┘
```

**Error Handling:**
- Analyze last 10 proposals for patterns
- Detect consistent free slots
- Calculate availability percentage
- Suggest recurring events
- Don't force suggestion (let user accept)

### Availability View Rules

**Display Rules:**
- Show only future dates (next 90 days)
- Group by date and time
- Sort by availability (highest first)
- Show person count for each availability level
- Respect all privacy settings via RLS

**Performance:**
- Load availability for 14 days at a time
- Paginate when scrolling down
- Cache for 5 minutes
- Background refresh in real-time

---

## 8. Premium Monetization Edge Cases

### Scenario: Free user hits group limit

**UI Flow:**
```
Free tier: 3 groups max
User tries to create 4th group

┌─────────────────────────────────────┐
│  💎 UPGRADE TO PREMIUM               │
├─────────────────────────────────────┤
│                                     │
│  You've reached the free plan limit │
│  of 3 groups.                       │
│                                     │
│  Your current groups:               │
│  1. College Friends (8 members)     │
│  2. Roommates (4 members)           │
│  3. Basketball Crew (6 members)     │
│                                     │
│  To create "Gaming Squad":          │
│                                     │
│  ┌───────────────────────────┐     │
│  │ 💎 Upgrade to Premium     │     │
│  │ $4.99/month                │     │
│  │ • Unlimited groups         │     │
│  │ • Advanced scheduling      │     │
│  │ • Priority support         │     │
│  │                            │     │
│  │ [Start Free Trial - 14 days]│   │
│  └───────────────────────────┘     │
│                                     │
│  Or:                                │
│  ┌───────────────────────────┐     │
│  │ [Remove an Old Group]     │     │
│  └───────────────────────────┘     │
│                                     │
└─────────────────────────────────────┘
```

**Error Handling:**
- Check premium status before creating group
- Show clear limit messaging
- Offer trial conversion path
- Allow free workaround (remove group)
- Track upgrade prompt events

### Scenario: Premium trial expiring

**UI Flow:**
```
3 days before trial ends

Gentle notification:
┌─────────────────────────────────────┐
│  💎 Premium Trial Ending Soon        │
├─────────────────────────────────────┤
│                                     │
│  Your free trial ends in 3 days     │
│                                     │
│  You're currently using:            │
│  • 5 groups (free limit: 3)         │
│  • Custom event templates           │
│  • Advanced availability view       │
│                                     │
│  After trial ends:                  │
│  ⚠️ 2 groups will be archived       │
│  ⚠️ Premium features disabled       │
│                                     │
│  Keep your features:                │
│  ┌───────────────────────────┐     │
│  │ [Subscribe - $4.99/month] │     │
│  └───────────────────────────┘     │
│  ┌───────────────────────────┐     │
│  │ [Annual - $39.99 (save 33%)]│   │
│  └───────────────────────────┘     │
│                                     │
│  [Remind Me Tomorrow]               │
│  [Downgrade to Free]                │
│                                     │
└─────────────────────────────────────┘
```

**Error Handling:**
- Check trial expiration daily
- Remind at: 3 days, 1 day, on expiration
- Auto-archive groups when trial expires
- Disable premium features gracefully
- Don't prevent viewing archived groups
- Allow easy downgrade

### Premium Feature Gating

**Free Tier Limits:**
- Max 3 groups
- Basic event creation
- Voting on proposals
- 1 month history
- Basic notifications

**Premium Tier Unlocks:**
- Unlimited groups
- Advanced templates (Surprise Party, Potluck)
- Travel time calculation
- Smart time suggestions
- 1 year history
- Priority support
- Custom group colors

**Premium Features Check:**
```swift
// Check before allowing action
guard user.isPremium || featureAllowedInFreeTier else {
    showPremiumUpsell()
    return
}
```

---

## 9. Performance & Loading States

### Scenario: Slow network loading availability

**UI Flow:**
```
Opening group calendar with slow connection

Progressive loading:
┌─────────────────────────────────────┐
│  College Friends Calendar           │
├─────────────────────────────────────┤
│                                     │
│  Loading availability...            │
│                                     │
│  ✓ Your calendar loaded             │
│  ⏳ Loading Sarah's calendar...     │
│  ⏳ Loading Mike's calendar...      │
│  ⏳ Loading 5 more...               │
│                                     │
│  [█████░░░░░] 50%                   │
│                                     │
│  You can start browsing with        │
│  partial data or wait for all.      │
│                                     │
│  [Show Partial]  [Wait]             │
│                                     │
└─────────────────────────────────────┘

After timeout (10 seconds):
┌─────────────────────────────────────┐
│  ⚠️ PARTIAL AVAILABILITY             │
├─────────────────────────────────────┤
│                                     │
│  Showing data for 5/8 people        │
│                                     │
│  Could not load:                    │
│  • Jordan T.                        │
│  • Emma W.                          │
│  • Taylor S.                        │
│                                     │
│  Availability data may be incomplete│
│                                     │
│  [Retry]  [Continue Anyway]         │
│                                     │
└─────────────────────────────────────┘
```

**Error Handling:**
- Show progressive loading indicators
- Load own calendar first
- Load other calendars in parallel
- Timeout after 10 seconds
- Show partial data option
- Provide retry mechanism
- Cache partial results

### Loading Thresholds

- **Instant (< 100ms):** Cached data, local operations
- **Fast (< 500ms):** Small API calls, sync operations
- **Acceptable (< 2s):** Group calendar loading, availability calculation
- **Timeout (10s):** Fail and show partial data option

### Skeleton Loaders

Use skeleton loaders for:
- Calendar events
- Group member avatars
- Vote count numbers
- Event details
- Availability percentages

### Performance Targets

- App launch: < 2 seconds to show calendar
- Calendar view render: < 500ms
- Proposal voting: < 200ms (optimistic update)
- Group switching: < 500ms (with cached data)
- Availability calculation: < 3 seconds for 8 people

---

## 10. Accessibility Interactions

### Scenario: VoiceOver user navigating calendar

**VoiceOver Announcement Example:**
```
"Calendar view. Week of December 8th.
Monday, December 9th.
Two events.
Team Meeting, 9:00 AM to 10:00 AM, Private event.
Lunch with Sarah, 12:00 PM to 1:00 PM, Shared with group.
Actions available."

User double-taps on event:
"Event details sheet. Team Meeting.
Edit button. Delete button.
Share with groups button."
```

**Implementation Requirements:**
- All images have descriptive `accessibilityLabel`
- Interactive elements have `accessibilityHint`
- Custom views implement `UIAccessibilityElement`
- Announce important status changes
- Support VoiceOver rotor (navigate by event, by time, etc.)

### Scenario: Dynamic Type (large text) user

**Implementation:**
```swift
// Calendar view adapts to Dynamic Type
switch traitCollection.preferredContentSizeCategory {
case .extraSmall, .small, .medium:
    // Normal layout - week view
    showWeekView()
case .large, .extraLarge:
    // Single day view - events scroll vertically
    showDayView()
case .accessibilityMedium, .accessibilityLarge, .accessibilityExtraLarge:
    // Single event per card - large touch targets
    showAccessibilityView()
}

// Minimum touch targets: 60pt x 60pt
// Minimum button padding: 8pt
// Scalable fonts using preferredFont(forTextStyle:)
```

**Requirements:**
- Use system preferred fonts (not fixed sizes)
- Support Dynamic Type up to accessibility extra-large
- Minimum touch target: 60pt x 60pt
- No color-only information
- Sufficient color contrast (WCAG AA)

### Accessibility Requirements

**Vision:**
- Color contrast: 4.5:1 for normal text, 3:1 for large text
- No information conveyed by color alone
- Support for Dark Mode
- Large text support (Dynamic Type)
- Zoom support (max 200%)

**Hearing:**
- Haptic feedback for important actions
- No critical audio cues
- Captions for any video content

**Motor:**
- Minimum touch target: 60pt x 60pt
- Support for voice control
- No hover-only interactions
- Support for accessibility buttons and switches

**Cognitive:**
- Clear, simple language
- Consistent navigation patterns
- Error messages are clear and specific
- Minimal cognitive load for core tasks

---

## 11. Data Conflicts & Resolution

### Scenario: Two people propose same event simultaneously

**UI Flow:**
```
Mike proposes: "Game Night" for Dec 15
Sarah proposes: "Game Night" for Dec 15
(both sent within 30 seconds)

System detects similarity:
┌─────────────────────────────────────┐
│  🔀 DUPLICATE PROPOSAL DETECTED      │
├─────────────────────────────────────┤
│                                     │
│  Two similar proposals:             │
│                                     │
│  Proposal 1 (Mike):                 │
│  "Game Night"                       │
│  Dec 15 • 7:00 PM                   │
│  3 time options                     │
│                                     │
│  Proposal 2 (Sarah):                │
│  "Game Night"                       │
│  Dec 15 • 7:30 PM                   │
│  4 time options                     │
│                                     │
│  To avoid split voting:             │
│  ┌───────────────────────────┐     │
│  │ [Merge Proposals]         │     │
│  │ (Mike & Sarah co-hosts)   │     │
│  └───────────────────────────┘     │
│  ┌───────────────────────────┐     │
│  │ [Keep Separate]           │     │
│  └───────────────────────────┘     │
│                                     │
│  Sent to: Mike, Sarah for decision  │
│                                     │
└─────────────────────────────────────┘
```

**Error Handling:**
- Detect duplicate proposals (same title, same date within 2 hours)
- Use fuzzy string matching
- Notify both proposers
- Offer merge option
- Combine time slots if merged
- Combine votes if merged
- List co-hosts if merged

### Conflict Resolution Strategy

**Last-Write-Wins:**
- Compare timestamps: `updated_at`
- Server timestamp takes precedence
- If same timestamp: database primary key breaks tie
- Always notify user of conflict
- Don't silently discard changes

**Version Fields:**
```sql
events:
  id UUID
  title TEXT
  updated_at TIMESTAMP  -- Conflict detection
  version INTEGER       -- For optimistic locking
  updated_by UUID       -- For transparency

event_updates:  -- Changelog for conflicts
  id UUID
  event_id UUID
  changed_by UUID
  old_value JSONB
  new_value JSONB
  created_at TIMESTAMP
```

**Example Conflict Flow:**
```
User A edits event title offline: "Game" → "Game Night"
User B edits location: "" → "Mike's Place"

On sync:
1. Send A's update (title)
2. Receive 409 Conflict
3. Fetch latest version from server
4. Merge: title="Game Night" + location="Mike's Place"
5. Send merged version
6. Notify A: "Location was updated by B"
```

---

## 12. Extreme Scenarios

### Scenario: 100+ person group (school club)

**UI Flow:**
```
User in group with 150 members

Availability view changes:
┌─────────────────────────────────────┐
│  🎓 CS Club (150 members)           │
├─────────────────────────────────────┤
│                                     │
│  ⚠️ Large group mode                │
│                                     │
│  Showing aggregate availability:    │
│                                     │
│  Wednesday 2:00 - 3:00 PM           │
│  ████████████░░░░░░ 78% available   │
│  117 free • 23 busy • 10 unknown    │
│                                     │
│  [See individual breakdown]    ›    │
│                                     │
│  💡 For large groups, we recommend: │
│  • Setting RSVP deadline            │
│  • Limiting to 3-5 time options     │
│  • Using "Maybe" sparingly          │
│                                     │
└─────────────────────────────────────┘
```

**Error Handling:**
- Detect groups with > 50 members
- Switch to aggregate mode (percentages, counts)
- Show breakdown on tap
- Limit time option count
- Show recommendations for large groups
- Paginate member list

### Scenario: User in 50+ groups (data hoarder)

**UI Flow:**
```
User somehow has 50+ groups

App implements pagination:
┌─────────────────────────────────────┐
│  👥 Groups                   [+]    │
├─────────────────────────────────────┤
│                                     │
│  🔍 [Search groups...]              │
│                                     │
│  RECENT (10)                        │
│  [Shows last 10 active groups]      │
│                                     │
│  ALL GROUPS (50)                    │
│  [Load more...]                     │
│                                     │
│  💡 Tip: Archive inactive groups    │
│     to improve performance          │
│                                     │
│  [Manage Groups]                ›   │
│                                     │
└─────────────────────────────────────┘
```

**Error Handling:**
- Require search for groups beyond first 10
- Show recent groups (by activity)
- Implement "load more" pagination
- Track active/inactive groups
- Suggest archiving inactive groups
- Set max groups limit (soft cap at 100)

### Boundary Conditions

**Event Boundaries:**
- Max 365 days in future
- Min 15 minutes duration
- Max 24 hours duration
- Max 500 characters title
- Max 5000 characters description

**Group Boundaries:**
- Max 500 members per group
- Max 100 groups per user (soft limit, suggest archiving)
- Max 50 active proposals per group
- Max 20 time options per proposal

**Time Boundaries:**
- Max 90-day availability view window
- Min voting deadline: 1 hour
- Max voting deadline: 30 days
- Proposal expiration: 7 days after voting ends

---

## Quick Reference Matrix

| Edge Case | Category | Priority | Handling Strategy | Test Criteria |
|-----------|----------|----------|-------------------|---------------|
| Event time conflict | Event Creation | MUST | Show dialog, allow override | Dialog appears, user can override |
| Privacy mismatch | Event Creation | MUST | Suggest privacy level | Suggestion shown for keywords |
| Calendar permission denied | Calendar Sync | MUST | Limited mode | App works without calendar |
| Offline vote | Connectivity | MUST | Queue action | Vote syncs after reconnect |
| Conflict on sync | Data | MUST | Notify user, offer merge | Conflict notification shown |
| Duplicate proposals | Data | MUST | Detect & suggest merge | Merge option offered |
| Removed from group | Group Dynamics | MUST | Immediate notification | User notified, votes canceled |
| Admin leaving | Group Dynamics | SHOULD | Require admin transfer | Admin selection dialog shown |
| Inactive member | Group Dynamics | SHOULD | Notify admin | Admin receives suggestion |
| Slow network | Performance | MUST | Progressive loading | Partial data shows quickly |
| Large group (100+) | Extreme | MUST | Aggregate mode | Percentages shown, not names |
| VoiceOver | Accessibility | SHOULD | Full announcements | VoiceOver navigates correctly |
| Dynamic Type | Accessibility | SHOULD | Responsive layout | Large text displays correctly |
| Premium trial expiring | Monetization | SHOULD | Reminder notifications | Notification shown at 3, 1 days |
| Tied votes | Proposals | MUST | Organizer decides | Tie-breaking dialog shown |
| Event deleted in Apple | Calendar Sync | SHOULD | Offer restore | Restore/leave/ignore options |
| Notification spam | Notifications | SHOULD | Cluster notifications | 5+ notifications → 1 summary |
| Timezone handling | Availability | SHOULD | Display in local time | Times shown in user's timezone |

---

## Development Checklist

### Must-Have Features to Test

- [ ] Offline queue persists across app restart
- [ ] Conflicts on sync show clear UI
- [ ] Undo works for deletions (5-second window)
- [ ] Real-time vote updates via WebSocket
- [ ] Calendar sync handles all modification types
- [ ] Large groups show aggregate data
- [ ] Premium limits enforced (3 groups max)
- [ ] Removed user sees notification and loses access
- [ ] Accessibility: VoiceOver announces events
- [ ] Accessibility: Dynamic Type scales properly

### Performance Targets

- [ ] App launch: < 2 seconds
- [ ] Calendar view: < 500ms render
- [ ] Group switch: < 500ms with cache
- [ ] Proposal voting: < 200ms (optimistic)
- [ ] Availability load: < 3 seconds for 8 people
- [ ] No janky scrolling (60 FPS maintained)
- [ ] Memory usage < 150MB typical

### Quality Metrics

- [ ] Zero unhandled errors (all crashes logged)
- [ ] Offline queue success rate > 98%
- [ ] Sync completion time < 5 seconds typical
- [ ] Notification delivery rate > 95%
- [ ] User satisfaction on error handling > 4/5

---

## Document Information

**Related Documents:**
- `NotionMD/Technical Documentation/Architecture Overview.md` - System design
- `NotionMD/Complete UI Flows/` - User flow documentation
- `CLAUDE.md` - Development guidelines

**Future Updates:**
- Add platform-specific edge cases as iOS 18+ features emerge
- Update performance targets based on device telemetry
- Expand monetization edge cases based on beta feedback
- Add localization edge cases

**Document Maintenance:**
- Review quarterly during development sprints
- Update after major beta testing milestones
- Add new edge cases discovered during QA
- Remove resolved edge cases after implementation
