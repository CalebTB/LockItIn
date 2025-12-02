# LockItIn Design Decisions & UX Documentation

*Consolidated design philosophy, UX logic, feature flows, and design system reference*

*Last Updated: December 1, 2025*

---

## Table of Contents

1. Design Philosophy & Guiding Principles
2. Core Navigation & Information Architecture
3. Calendar Views & Display Logic
4. Event Management (Creation, Editing, Proposals, Voting)
5. Privacy & Shadow Calendar Design
6. Notifications Design
7. Group & Friend System Design
8. Event Memories & Photo Sharing
9. Special Event Templates & Retention Features
10. Design System Reference
11. Quick Reference Decision Matrix

---

## 1. Design Philosophy & Guiding Principles

### Core Design Ethos: "Calm, Not Chaotic"

Every design decision should reduce anxiety, not create it. LockItIn helps you coordinate with friends without the noise, FOMO, and social pressure of other apps.

### Five Design Principles

**1. Native Feel**
- Follows Apple's Human Interface Guidelines
- Uses system fonts (SF Pro), colors, components
- Feels like it was built by Apple
- Native iOS affordances and interactions

**2. Minimal & Focused**
- Every screen has one primary action
- No clutter, no overwhelming options
- Progressive disclosure of complexity
- Clear visual hierarchy

**3. Delightful Details**
- Smooth animations (spring physics)
- Haptic feedback on important actions
- Confetti when events get confirmed
- Thoughtful empty states
- Micro-interactions that delight without distraction

**4. Accessible to All**
- Full VoiceOver support
- Dynamic Type (text scaling)
- High contrast mode
- Colorblind-friendly palettes
- Minimum 44pt touch targets

**5. Fast & Responsive**
- Optimistic UI updates (show action immediately)
- Aggressive caching
- Works offline with queue system
- <100ms response times
- Real-time updates via WebSockets

### Design Constraints

All design decisions balance:
- **User control** - Users make the decisions that matter to them
- **Reduced friction** - Every tap should feel intentional
- **Privacy-first** - Granular controls, opt-in sharing, default to private
- **Celebration over shame** - No guilt-inducing FOMO messages

---

## 2. Core Navigation & Information Architecture

### Tab-Based Architecture (Primary Navigation)

```
Bottom Tab Bar (4 tabs):
├─ Calendar (default tab)
├─ Groups
├─ Inbox (with badge counter)
└─ Profile
```

### Navigation Patterns

**Calendar Tab Navigation:**
- Swipe left/right: Next/previous week
- Swipe up: Expand to Month View
- Swipe down: Collapse to Day View
- Pinch: Zoom in/out
- Tap event: Open event details

**Groups Tab Navigation:**
- List of all friend groups
- Tap group: Opens group detail view
- Group detail shows: Members, upcoming events, past events, calendar overlay
- Long-press group: Quick actions (edit, remove, etc.)

**Inbox Tab Navigation:**
- Notifications with badges
- Event proposals that need action
- Real-time vote updates
- Filter options: "All", "Needs response", "Completed"

**Profile Tab Navigation:**
- User settings and preferences
- Privacy settings
- Calendar management
- Subscription status

### Default View Behavior

When opening the app, users land on the **Personal Calendar** in Week View. This keeps the experience simple on first open while allowing deep coordination when entering Groups.

---

## 3. Calendar Views & Display Logic

### Three Calendar View Modes

**Week View (Default)**
- Shows 7-day week with hourly time slots
- Current time indicator scrolls
- Events span time blocks
- Most common interaction context
- Touch-friendly timeline

**Month View**
- Shows 30-31 day calendar grid
- Day dots indicate events
- Tap day to see details
- Good for planning ahead
- Swipe to navigate months

**Day View**
- Single day expanded view
- Hourly slots
- Maximum detail
- Good for busy days
- Easy event creation

### Color Coding System

| Color | Event Type | Meaning |
|-------|-----------|---------|
| Blue | Personal events | Your private/personal calendar |
| Green | Group events (confirmed) | Events you're attending with groups |
| Purple | Pending proposals | Events awaiting your vote |
| Gray | Busy-only events | Your busy blocks (no details shared) |
| Red | Conflicts/Declined | Declined invites or scheduling conflicts |

### Event Icons & Badges

- **🔒 Private** - Only visible to you
- **👥 Shared with name** - Group can see title and time
- **👁️ Busy only** - Group sees "busy" block without details
- **⏰ Action needed** - Requires your vote/response
- **🏆 Best option** - Leading choice in voting
- **✓ Confirmed** - Event locked in, everyone attending

### Privacy Icon Display Logic

Events show privacy badges on the calendar:
- Tap event to see full privacy details
- Icons remain visible on list views
- No sensitive data shown in calendar grid view

### Filter Options

From Calendar view, users can filter by:
- Show all events
- Only my personal events
- Only group events
- By specific group (quick access)
- Upcoming vs. past

---

## 4. Event Management (Creation, Editing, Proposals, Voting)

### Personal Event Creation Flow

**Step 1: Trigger**
- Tap floating "+" button (bottom right, above tab bar)
- Or tap and hold on specific time slot
- Or tap [+] in Groups tab to add to a specific group

**Step 2: Create Event Sheet**
Capture: Title, Time, Location (optional), Description (optional), Recurrence

**Step 3: Set Privacy Level**
Three options:
1. **Private (just me)** - Hidden from all groups
2. **Shared with name** - Groups see event title and time
3. **Shared - busy only** - Groups only see "busy" block

**Step 4: Confirmation**
- Review all details
- Confirm and return to calendar
- Event syncs to Apple Calendar if enabled

### Personal Event Editing Flow

**Edit Actions:**
- Tap event → Edit button
- Safe edits: Title, time, location, description (no notification required)
- Privacy change: Notification sent to groups
- Delete: Confirm deletion, undo available for 5 seconds

**Special Case: Editing After Proposal**
- If event is from a confirmed proposal, editing is limited
- Can change time if all attendees agree
- Shows warning: "This will notify X people"

### Group Event Proposal Creation

**Step 1: Trigger**
- Tap "+" → "Propose Group Event"
- Or from Groups tab, select group then [+ Propose Event]

**Step 2: Event Details**
- Event title (required)
- Group selection (required)
- Description (optional)
- Location (optional)

**Step 3: Time Slot Proposal (The Core Innovation)**
- User adds 2-5 time options
- For each time option, system shows:
  - Who's available (green)
  - Who's busy (gray)
  - Who's maybe (yellow)
  - Vote count and percentages

**Step 4: Send Proposal**
- Review proposal
- Tap "Send Proposal"
- Notification sent to all group members

**Step 5: Voting Interface (Recipient)**

Each time option shows:
```
Option 1: Sat Dec 15, 6-8pm
├─ Available: 5/8 people (62%)
├─ Your response: [✓ Available] [~ Maybe] [✗ Can't make it]
└─ Shows avatars of who voted
```

Voting is one-tap with instant feedback.

### Group Event Proposal - Complex Interactions

**Scenario: Proposer Changes Mind After Sending**

Alert presents options:
- Edit title/description/location (keeps votes)
- Edit time options (resets all votes)
- Cancel proposal (notifies everyone)

**Scenario: Tied Votes**

When voting deadline reached with a tie:
- System alerts proposer
- Shows both tied options
- Proposer chooses winner
- Or can extend voting by 24 hours
- Or create new poll with different times

**Scenario: Someone Votes "No" to All Options**

System flags this to proposer with options:
- Message that person directly
- Add more time options
- Proceed without them

**Scenario: Last-Minute Vote Changes Winner**

Real-time notification to all:
- New leader highlighted
- Old leader shown for comparison
- View full results button

### Auto-Confirmation Logic

Event auto-confirms when:
1. **Voting deadline reached** (24 hours default) AND
   - Clear winner exists (>50% of group)
   - OR proposer has confirmed time
2. **All members have voted** (earlier confirmation)
3. **Proposer manually confirms** (can override anytime)

Once confirmed:
- Event automatically added to everyone's calendar
- Attendees get confirmation notification
- Event appears on personal calendar
- Can be edited only with group consensus

---

## 5. Privacy & Shadow Calendar Design

### Privacy Levels (Three-Tier System)

**Level 1: Private (🔒)**
- Event invisible to all groups
- Used for: Medical appointments, personal time, confidential events
- Others see: Nothing (gap in calendar is normal)
- Visible in: Only personal calendar

**Level 2: Shared with Name (👥)**
- Group sees full event details (title, time, location)
- Used for: Confirmed friend group events
- Others see: Event title, time, and who else is going
- Visible in: Group calendar view

**Level 3: Busy Only (👁️)**
- Group sees only a "busy" block (no details)
- Used for: Work meetings, appointments you don't want to discuss
- Others see: You're busy, can't see event title
- Visible in: Availability heatmap but no details

### Shadow Calendar System

The core innovation: Show availability without revealing private details.

**How It Works:**
1. User's events have privacy settings (private/shared/busy-only)
2. Groups see aggregated availability heatmap
3. For each time slot, groups see: "5/8 people free"
4. Tapping heatmap shows who specifically is free
5. Privacy settings are enforced at database level (RLS)

**Example:**
- Sarah has a doctor's appointment (private) from 2-3pm
- Her friends see her as "busy" during that time
- They can't see the doctor's appointment exists
- Sarah still appears in the availability heatmap

### Default Privacy Settings

Users configure default privacy for:
- All new personal events
- All new group events
- Per-group sharing levels

Can be overridden on a per-event basis.

### Group-Specific Privacy Controls

Users can set different sharing levels for different groups:
- College Friends group: "Shared with name"
- Work colleagues: "Busy only"
- Close friends: "Shared with name"
- Casual acquaintances: "Busy only"

---

## 6. Notifications Design

### Notification Philosophy

**Less is more.** Only notify when:
1. User action is required
2. Something they explicitly opted into
3. Information they can act on

Avoid notification fatigue by:
- Not notifying entire group about one person's changes
- Batching updates when possible
- Respecting user notification settings
- Never using notifications for FOMO

### Notification Types & Recipients

**New Proposal Notification**
- Who gets it: All group members
- Message: "Sarah proposed Game Night • Vote needed"
- Action: Open Inbox to vote
- Badge count: Increases until voted

**Vote Cast Notification**
- Who gets it: Proposer only
- Message: "Mike voted Available on Game Night"
- When: Real-time as votes come in
- Action: View proposal to see updated counts
- Can be disabled in settings

**Conflict Alert Notification**
- Who gets it: Organizer + conflicted person only (not entire group)
- Message (to conflicted person): "Heads up: You now have a conflict with Game Night on Saturday"
- Message (to organizer): "Sarah now has a conflict with Game Night on Saturday"
- Action: Organizer can message Sarah or propose new time

**Event Confirmed Notification**
- Who gets it: All attendees
- Message: "Game Night confirmed for Saturday 7pm"
- Action: Added to calendar
- Celebration: Confetti animation on receipt

**Deadline Reminder Notification**
- Who gets it: Members who haven't voted
- Message: "Game Night voting closes in 2 hours"
- Timing: 2 hours before deadline
- Frequency: Only if not already voted

**Proposal Update Notification**
- Who gets it: Group members who voted
- Message: "Sarah updated Game Night times"
- Reason: Time options changed (votes reset)
- Action: Re-vote with new options

### Notification Settings

Users can control:
- Toggle notifications per notification type
- Quiet hours (do not disturb)
- Sound vs silent
- Badge count display
- In-app notification banner style

### In-App Notification Toast Design

- Non-intrusive banner (top or bottom)
- Auto-dismisses after 3 seconds
- Allows undo for 5 seconds (e.g., "Deleted event" → [Undo])
- Shows during active app use
- Can be dismissed manually

### Push Notification Design

- Rich media allowed (group avatar, event color)
- Action buttons on lock screen (iOS 15+)
  - Direct vote response from notification
  - Open Inbox from notification
- No sounds by default (respect user settings)
- Supports critical notifications for urgent changes

---

## 7. Group & Friend System Design

### Friend Management Flow

**Adding Friends:**
1. Profile tab → [+ Add Friend]
2. Search by name, username, or phone number
3. Send friend request
4. Recipient gets notification
5. Approve/decline friend request
6. Once approved, can add to groups

**Creating Friend Groups:**
1. Groups tab → [+ Create Group]
2. Enter group name (e.g., "College Friends", "Board Game Club")
3. Select friends to add
4. Set group description (optional)
5. Confirm group creation
6. Group appears in Groups tab

**Managing Group Members:**
- View all members in group detail
- Remove members (group admin only)
- Change member roles (organizer, member)
- Invite new members

### Group Context

Each group can have:
- Custom name and description
- Member list with roles
- Calendar showing all group events
- Availability heatmap for members
- Past events with memories
- Shared event proposals

### Group Privacy Settings

Per-group controls for:
- Who can see your availability
- Default privacy level for events with this group
- Who can create proposals in this group
- Group member visibility (can see who else is in group)

---

## 8. Event Memories & Photo Sharing

### Memory Collection Trigger

**When:** Event ends (based on event end time + 10 minutes buffer)

**Who gets notified:** All confirmed attendees

**Notification style:** Gentle prompt, not pushy
- Message: "How was [Event Name]? Add a photo!"
- Shows in Inbox as a memory collection card
- Notification disappears after 3 days if no upload

### Memory Upload Rules

**Allowed uploads:**
- 1-2 photos per person per event (high-quality)
- OR 1 short video (5-10 seconds) per person
- Not both for one person

**Why this limit:** Keeps memories curated, not a dump. Lightweight storage.

**File requirements:**
- Photos: JPG/PNG up to 5MB
- Videos: MP4/MOV up to 15MB, max 10 seconds
- Compression on upload

### Shared Album Model (Not Single Uploader)

Why shared, not single photographer:
- Multiple perspectives capture different moments
- No single point of failure (if designated photographer forgets)
- Low pressure (optional, but encouraged)
- Higher engagement (people check back to see uploads)
- More fun (each upload is a small celebration)

### Memory Access Rules

| Scenario | Memory Access |
|----------|----------------|
| Attended the event | ✅ Full access - can upload and view all memories |
| Declined the invite | ❌ No automatic notification. Can manually view in group calendar if curious. |
| Wanted to go but couldn't | ❌ No automatic notification. Optional offer: "Your friends posted photos from [Event]. Want to see them?" - user chooses. |
| Not invited to event | ❌ No access at all. Event not visible. |

### Key FOMO Prevention Principle

**User stays in control.** We don't force-feed FOMO. If someone wants to peek at what they missed, they can. But we don't push it on them.

### Memory Gallery UI

**In Group Calendar View:**
- Small thumbnail carousel at bottom of event
- Shows first 3 photos
- Tap to expand full gallery
- Swipe through photos/videos
- See who uploaded each piece
- Like/react to individual uploads (future feature)

**In Event Detail:**
- Full-screen gallery view
- Timestamps of uploads (when added)
- Who uploaded each piece
- Share individual photos to social media

---

## 9. Special Event Templates & Retention Features

### Event Memory & Year-End Wrapped Strategy

The goal: Celebrate participation, not create FOMO.

### Year-End Wrapped Rules

**What's Included:**
- "You went to 47 events with your crew"
- "Your most active group: College Friends (23 hangouts)"
- "You spent the most time with: Mike (34 events together)"
- "Your biggest month: July (12 events)"
- Photo highlights from events YOU attended
- Shareable cards for social media

**What's NOT Included:**
- "Your friends had 62 events (you missed 15)" ← NO FOMO messaging
- Photos from events you didn't attend
- Any "you missed out" messaging
- Guilt-inducing stats

**The Vibe:**
Celebratory, not guilt-inducing. "Look at all the memories you made!" not "Look at what you could have done."

### Retention Mechanisms

**1. Event Memories & Photos**
- Users contribute to shared albums
- Reason to return: View new uploads, memories are living
- Social proof: See friends' contributions

**2. Real-Time Voting Energy**
- Live vote counts create urgency
- See votes come in real-time
- Last vote might change winner (exciting!)

**3. Group Locking**
- Groups create social pressure (in a good way)
- Can't delete account without leaving groups
- Friends rely on you

**4. BeReal-Style Moments**
- Event memory prompts are daily rituals
- Unexpected, delightful capture moments
- User engagement spikes after events

---

## 10. Design System Reference

### Colors

**Primary Colors**
- Primary Blue: #007AFF (iOS default)
- Success Green: #34C759
- Warning Yellow: #FFCC00
- Error Red: #FF3B30

**Neutral Colors**
- Background Light: #FFFFFF
- Background Dark: #000000
- Secondary Background Light: #F2F2F7
- Secondary Background Dark: #1C1C1E
- Tertiary Background Light: #E5E5EA
- Tertiary Background Dark: #2C2C2E
- Text Primary Light: #000000
- Text Primary Dark: #FFFFFF
- Text Secondary Light: #3C3C43
- Text Secondary Dark: #AEAEB2

### Typography

**System Font:** SF Pro (iOS default)

| Style | Size | Weight |
|-------|------|--------|
| Title 1 | 34pt | Bold |
| Title 2 | 28pt | Bold |
| Title 3 | 22pt | Semi-bold |
| Headline | 17pt | Semi-bold |
| Body | 17pt | Regular |
| Callout | 16pt | Regular |
| Footnote | 13pt | Regular |
| Caption | 12pt | Regular |

### Spacing

8pt grid system:
- 4pt (0.5x) - Tight spacing
- 8pt (1x) - Standard padding
- 16pt (2x) - Medium spacing
- 24pt (3x) - Large spacing
- 32pt (4x) - Extra large
- 48pt (6x) - Section spacing

### Icons

Using SF Symbols (built into iOS):
- **Calendar:** calendar
- **Groups:** person.3.fill
- **Proposals:** checkmark.circle.fill
- **Profile:** person.circle.fill
- **Settings:** gear
- **Privacy:** lock.circle.fill
- **Share:** square.and.arrow.up
- **Plus:** plus.circle.fill
- **Menu:** ellipsis

### Components

**Buttons**
- Primary action: Solid color, full width, 44pt height
- Secondary action: Outline or text style
- Danger action: Red background
- Disabled: Reduced opacity (50%)

**Cards**
- Rounded corners: 12pt
- Shadow: Light (1pt elevation)
- Padding: 16pt
- Background: Secondary background color

**Toggle/Switches**
- Size: 51 × 31pt (system standard)
- Thumb size: 27 × 27pt
- On color: Primary blue
- Off color: Gray

**Text Fields**
- Height: 44pt minimum
- Border: 1pt, gray on light, lighter gray on dark
- Corner radius: 8pt
- Padding: 12pt horizontal, 10pt vertical

**Progress Indicators**
- Vote progress bars: 6pt height, rounded
- Loading spinner: Indeterminate progress view
- Skeleton screens: During data loading

---

## 11. Quick Reference Decision Matrix

### Key Design Decisions at a Glance

| Topic | Decision | Reasoning |
|-------|----------|-----------|
| **Conflict Notifications** | Organizer + conflicted person only (not whole group) | Reduces noise, clear ownership, prevents panic |
| **Calendar Views** | Two views: Personal (your events) + Group (all group events) | Keeps personal cal clean, enables planning mode |
| **Declined Events on Personal Cal** | No - only visible in group calendar view | Prevents clutter, maintains focus |
| **Event Memories** | Shared album model (anyone who attended) | Multiple perspectives, no single point of failure |
| **Memory Upload Limit** | 1-2 photos per person OR 1 short video per person | Keeps memories curated, not spam |
| **Non-Attendees See Memories** | No auto-notification; optional peek if they choose | Prevents FOMO weaponization |
| **Year-End Wrapped** | Only counts events you attended | Celebratory, not guilt-inducing |
| **Default View** | Personal Calendar (Week View) | Keeps app simple on first open |
| **Tab Navigation** | 4-tab bar: Calendar, Groups, Inbox, Profile | Clear mental model, standard iOS pattern |
| **Event Privacy** | Three tiers: Private / Shared / Busy-Only | Granular control for privacy-first design |
| **Group Permissions** | Per-group visibility settings | Different groups need different privacy |
| **Vote Notifications** | Proposer only (not whole group) | Reduces noise while keeping them informed |
| **Proposal Deadline** | 24 hours (default, can extend) | Balances urgency with thoughtful response |
| **Tied Votes** | Proposer decides tiebreaker | Organizer has final call, community vote breaks stalemate |
| **Event Proposal** | 2-5 time options shown with availability | Sweet spot: enough choice without paralysis |
| **Availability Heatmap** | Shows aggregate count (5/8 free) | Privacy-first: respects visibility settings |
| **Filter Options** | By group, personal/group/all events | Progressive disclosure, stay focused |
| **Icon Display** | Privacy badges on calendar (🔒👥👁️) | Visual affordance, clear privacy status |
| **Offline Queue** | Store actions, sync when reconnected | Works offline, resilient network failures |
| **Undo Actions** | 5-second toast with Undo button | Reduces anxiety about destructive actions |
| **Optimistic UI** | Show action immediately, rollback if fails | Feels responsive, <100ms perceived latency |
| **Real-Time Updates** | WebSocket subscriptions on active screens | Live vote counts, collaborative feel |

---

## Summary: Core Design Principles in Action

Every design decision returns to this theme:

**"Calm, not chaotic. Helpful, not guilt-inducing. Your schedule, your control."**

The app succeeds when:
- Planning feels effortless, not stressful
- Privacy is respected, not compromised
- You feel in control of your calendar
- Coordination with friends feels fun, not like work
- You see what happened (memories) without FOMO about what you missed

Design decisions favor:
- User control over automation
- Privacy by default over convenience
- Simplicity over features
- Celebration over shame
- Responsiveness over perfection

---

*This is a living document. Update as design decisions evolve and new patterns emerge.*
