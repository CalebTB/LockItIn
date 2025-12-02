# LockItIn Onboarding Documentation

Complete first-time user experience, permission strategy, interactive tutorials, and empty state guidance.

---

## 1. Onboarding Philosophy & Goals

### Core Mission
Transform a new user from app installer to active group organizer in minimal steps, clearly demonstrating the app's core value proposition: solving the "30 messages to plan one event" problem.

### Key Principles
- **Value-First**: Each step explains WHY we need permission or information before asking
- **Minimal Steps**: Get users to see the magic (group planning) as quickly as possible
- **Privacy Transparency**: Clarify data usage and privacy controls early
- **Progressive Disclosure**: Show complexity only when needed
- **Empowerment**: Users feel in control of their data and sharing choices

### Success Criteria
- User completes onboarding in <5 minutes
- User understands core feature (group availability + voting) by tutorial end
- User creates first group or joins one within first session
- User grants required permissions (calendar + notifications)

---

## 2. Step-by-Step Onboarding Flow

### Flow Diagram
```
Launch App
↓
Welcome Screen (Value prop + CTA)
↓
Sign Up / Log In (Apple Sign In or Email)
↓
Profile Setup (Name, optional photo/phone)
↓
Calendar Sync (EventKit permission request)
↓
Notifications (Push permission request)
↓
Location (Optional permission request)
↓
Interactive Tutorial (Guided simulation)
↓
Empty State (Personal calendar + Group nudge)
```

### Detailed Steps

#### Step 1: Welcome Screen
**User sees:**
```
┌─────────────────────────────────────┐
│  LockItIn                           │
│                                     │
│  Lock in plans, not details.        │
│                                     │
│  See when everyone's free at a      │
│  glance. Vote on times. Plans made. │
│                                     │
│  [Get Started]                      │
└─────────────────────────────────────┘
```

**What happens:** Simple value prop + action button. Skip button optional.

---

#### Step 2: Sign Up / Log In
**Options:**
- Apple Sign In (recommended, one tap)
- Email + Password
- Link to existing account

**Why Apple Sign In first:** Fastest path, uses existing device identity, aligns with privacy-first values.

---

#### Step 3: Profile Setup
**Collects:**
- Display name (required)
- Optional phone number (for SMS invites later)
- Optional profile photo

**Why now:** Users identify themselves so friends can find them by name/photo in groups.

**UI:**
```
┌─────────────────────────────────────┐
│  Welcome to LockItIn!               │
│                                     │
│  Display Name:                      │
│  [Your Name____________]            │
│                                     │
│  Phone (optional):                  │
│  [(  ) ___-____]                    │
│                                     │
│  Profile Photo (optional):          │
│  [+] Add Photo                      │
│                                     │
│  [Continue]                         │
└─────────────────────────────────────┘
```

---

## 3. Permission Request Strategy

### Permission Hierarchy & Timing

| Permission | Timing | Why Then | Required? |
| ----- | ----- | ----- | ----- |
| Calendar Access | Step 4 (during onboarding) | Core feature—app depends on it | YES |
| Notifications | Step 5 (during onboarding) | Value is clear: "know when friends propose" | YES |
| Location | Step 6 (during onboarding, skippable) | Nice-to-have: "show travel time to events" | NO |
| Contacts | Later (when inviting friends) | Context makes sense, not intrusive on launch | NO |

### Calendar Access (Step 4)

**Request Screen:**
```
┌─────────────────────────────────────┐
│  Sync Your Calendar                 │
│                                     │
│  📅 We'll import your existing      │
│  events from Apple Calendar.        │
│                                     │
│  Why: LockItIn works best when      │
│  you share your real availability   │
│  with friends.                      │
│                                     │
│  We never share event details       │
│  unless YOU choose to.              │
│                                     │
│  [Allow Calendar Access]            │
│  [Not Now]                          │
└─────────────────────────────────────┘
```

**If Denied:**
- App enters "Limited Mode"
- Show clear warning: Friends won't see accurate availability
- Offer Settings shortcut to re-enable
- Users CAN still create events in-app and participate in group voting
- Revisit this screen occasionally with softer prompts

**Limited Mode Warning:**
```
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

---

### Notifications (Step 5)

**Request Screen:**
```
┌─────────────────────────────────────┐
│  Stay in the Loop                   │
│                                     │
│  🔔 Get notified when:              │
│                                     │
│  • Friends propose group events     │
│  • Votes close on proposals         │
│  • Events are confirmed             │
│  • Someone votes your way           │
│                                     │
│  [Allow Notifications]              │
│  [Not Now]                          │
└─────────────────────────────────────┘
```

**If Denied:**
- App works fine
- Show occasional reminder: "You missed a proposal" card
- Don't nag—respects user choice
- Offer Settings link in cards for users to re-enable later

---

### Location (Step 6 - Optional)

**Request Screen:**
```
┌─────────────────────────────────────┐
│  Travel Time (Optional)             │
│                                     │
│  📍 Show estimated travel time      │
│  to events with locations.          │
│                                     │
│  Example: "Event at Riverside       │
│  Coffee · 12 min away"              │
│                                     │
│  [Allow Location Access]            │
│  [Skip]                             │
└─────────────────────────────────────┘
```

**If Denied:**
- Features that show travel time are grayed out
- No nag screens—this is truly optional

---

### Contacts (Later - When Inviting)

**Timing:** Requested only when user tries to invite friends by phone number or contacts search.

**Why:** Context is clear—user is actively trying to invite someone.

**Request Screen:**
```
┌─────────────────────────────────────┐
│  Find Friends                       │
│                                     │
│  We'll search your contacts to      │
│  find friends already using         │
│  LockItIn.                          │
│                                     │
│  [Allow Contacts Access]            │
│  [Enter phone manually]             │
└─────────────────────────────────────┘
```

---

## 4. Interactive Tutorial Design

### Tutorial Philosophy
**Don't explain—show.** Instead of tooltips or text instructions, drop users into a guided simulation of the magic: group planning with real-time voting.

### Tutorial Sequence

#### Intro Screen
```
┌─────────────────────────────────────┐
│  👋 Let's see how LockItIn works    │
│                                     │
│  Imagine your friend group          │
│  "College Crew" is planning a       │
│  hangout...                         │
│                                     │
│  [Show me →]                        │
└─────────────────────────────────────┘
```

---

#### Scene 1: The Heatmap
**Duration:** 15 seconds

Shows a fake group with 5 "friends" and their availability heatmap.

```
┌─────────────────────────────────────┐
│  College Crew Availability          │
├─────────────────────────────────────┤
│                                     │
│  Friday              Saturday       │
│  [Heatmap showing green (free) and  │
│   red (busy) zones for each time]   │
│                                     │
│  5/5 people free       4/5 people   │
│  Friday 7-9 PM         free Sat 7PM │
│                                     │
│  💡 See when everyone's free at     │
│  a glance. Green = everyone's free. │
│                                     │
│  [Next →]                           │
└─────────────────────────────────────┘
```

---

#### Scene 2: Creating a Proposal
**Duration:** 20 seconds

```
┌─────────────────────────────────────┐
│  Sarah starts organizing hangout    │
│                                     │
│  Sarah's Proposal:                  │
│  "Game Night 🎲"                    │
│                                     │
│  Which time works best?             │
│                                     │
│  ⊡ Friday 7-9 PM                    │
│  ⊡ Saturday 7-9 PM                  │
│  ⊡ Sunday 2-4 PM                    │
│                                     │
│  💡 Sarah picks multiple options.   │
│  Everyone votes on their favorite.  │
│                                     │
│  [Next →]                           │
└─────────────────────────────────────┘
```

---

#### Scene 3: Real-Time Voting
**Duration:** 25 seconds (animated votes coming in)

```
┌─────────────────────────────────────┐
│  Everyone votes in real-time        │
│                                     │
│  Friday 7-9 PM                      │
│  ████████ 4 votes                   │
│  (Vote count animates up)           │
│                                     │
│  Saturday 7-9 PM                    │
│  ██ 2 votes → ████ 4 votes          │
│  (animate dynamically)              │
│                                     │
│  Sunday 2-4 PM                      │
│  ░░░░░░░░ 0 votes                   │
│                                     │
│  💡 See who's voting. Votes update  │
│  as friends respond.                │
│                                     │
│  [Next →]                           │
└─────────────────────────────────────┘
```

---

#### Scene 4: Event Locked In
**Duration:** 15 seconds

```
┌─────────────────────────────────────┐
│  🎉 Locked In!                      │
│                                     │
│  Game Night                         │
│  Friday, Dec 20 · 7-9 PM            │
│  at Mike's Place                    │
│                                     │
│  5 people confirmed                 │
│                                     │
│  ✓ Automatically added to           │
│    everyone's calendar              │
│                                     │
│  💡 No more "Wait, what time?"      │
│                                     │
│  [Next →]                           │
└─────────────────────────────────────┘
```

---

#### Scene 5: Surprise Party Teaser (Optional)
**Duration:** 10 seconds

Quick preview of surprise birthday feature:

```
┌─────────────────────────────────────┐
│  🎂 The Surprise (Secret!)          │
│                                     │
│  Planning a surprise party?         │
│  The birthday person won't see      │
│  a thing until it's revealed.       │
│                                     │
│  [Learn more →]                     │
└─────────────────────────────────────┘
```

---

#### Scene 6: Tutorial End
```
┌─────────────────────────────────────┐
│  ✨ Ready to plan with YOUR         │
│     friends?                        │
│                                     │
│  [Create a Group] [Invite Friends]  │
│  [Skip to Calendar]                 │
└─────────────────────────────────────┘
```

### Tutorial Parameters
- **Total duration:** 60-90 seconds (keep it snappy)
- **Animations:** Smooth transitions, light haptics on key moments (vote tallies, confirmation)
- **Restart option:** Users can re-watch from settings
- **Accessibility:** Full narration support, captions for animations

---

## 5. Empty State Experience (0 Friends, 0 Groups)

### After Tutorial, User Lands Here

When user completes onboarding and has no groups yet:

```
┌─────────────────────────────────────┐
│  < December 2025 >          [≡]     │
├─────────────────────────────────────┤
│                                     │
│  [Calendar view - empty]            │
│                                     │
│  ┌─────────────────────────────────┐
│  │ 👥 LockItIn is better together  │
│  │                                 │
│  │ Create a group to start         │
│  │ planning with friends.          │
│  │                                 │
│  │ [Create Group]  [Invite Friends]│
│  └─────────────────────────────────┘
│                                     │
└─────────────────────────────────────┘
```

### Empty State Behavior

- **Persistence:** Card displays until user creates a group or joins one
- **Dismissal:** Users can swipe away the card temporarily
- **Smart re-appearance:** After dismissal
  - 1st dismiss: Reappears after 5 minutes
  - 2nd dismiss: Reappears after 1 hour
  - 3rd+ dismiss: Minimizes to small banner at bottom
  - Fully hidden only after first group is created/joined

### Small Banner (After 3 Dismissals)
```
┌─────────────────────────────────────┐
│  ...calendar...              👥 ×   │
│                              [→]    │
│                        "Create Group"│
└─────────────────────────────────────┘
```

---

## 6. First Group Creation Flow

### Triggered By
User taps [Create Group] from empty state or from Groups tab.

### Step 1: Group Name & Description
```
┌─────────────────────────────────────┐
│  Create a Group                     │
│                                     │
│  Group Name *                       │
│  [College Crew____________]         │
│                                     │
│  Description (optional)             │
│  [What's this group for?___]        │
│                                     │
│  Examples: College Friends,         │
│  Work Squad, Gaming Buddies         │
│                                     │
│  [Next]                             │
└─────────────────────────────────────┘
```

### Step 2: Add Members
```
┌─────────────────────────────────────┐
│  Add Friends                        │
│                                     │
│  Search by name or phone:           │
│  [Search_________________]          │
│                                     │
│  ☐ Sarah (sarah@email.com)          │
│  ☐ Mike (mike@email.com)            │
│  ☐ Jordan (jordan@email.com)        │
│                                     │
│  [Create Group]  [Add Later]        │
└─────────────────────────────────────┘
```

**Options:**
- Add members now (search by name, email, or phone)
- Create empty, add members later
- Copy invite link to share

### Step 3: Confirmation
```
┌─────────────────────────────────────┐
│  ✓ Group Created!                  │
│                                     │
│  College Crew                       │
│  You + 3 members                    │
│                                     │
│  Ready to start planning?           │
│                                     │
│  [Create Event Proposal]            │
│  [View Group Calendar]              │
│  [Done]                             │
└─────────────────────────────────────┘
```

---

## 7. First Event Creation Guidance

### Personal Event (Single User)
```
┌─────────────────────────────────────┐
│  New Event                          │
│                                     │
│  Title *                            │
│  [Team Standup____________]         │
│                                     │
│  Date & Time                        │
│  Mon, Dec 9 · 10:00 AM - 11:00 AM  │
│                                     │
│  Privacy                            │
│  ⊙ Private (only you see)           │
│  ⊙ Share with Groups...             │
│                                     │
│  [Create Event]                     │
└─────────────────────────────────────┘
```

### Group Event Proposal (Voting)
```
┌─────────────────────────────────────┐
│  Create a Proposal                  │
│                                     │
│  Group: College Crew                │
│  Title *                            │
│  [Game Night 🎲____________]         │
│                                     │
│  What times work?                   │
│  (Pick 2-4 options)                 │
│                                     │
│  ☑ Friday 7-9 PM                    │
│  ☑ Saturday 7-9 PM                  │
│  ☐ Sunday 2-4 PM                    │
│                                     │
│  [Create Proposal]                  │
└─────────────────────────────────────┘
```

**First-time note:** After first proposal, show a tooltip:
"Friends will vote on these times. You'll see who's free for each option."

---

## 8. Onboarding Success Metrics

Track these to measure onboarding effectiveness:

### Completion Metrics
- % of users completing all 8 onboarding steps
- % of users granting calendar permission
- % of users granting notification permission
- Average time to complete onboarding
- Drop-off rates at each step

### Engagement Metrics
- % of users creating first group within 24 hours of signup
- % of users inviting friends within first week
- % of users creating first group event within first group creation
- Return rate 7 days after signup (users who create first group are stickier)

### Permission Metrics
- % of users who see calendar permission screen
- % who grant it (vs. deny/not-now)
- % who grant notifications
- % who grant location

### Tutorial Metrics
- % of users watching full tutorial
- Average watch time
- Where users drop off (if they skip early)

---

## 9. Edge Cases & Denied Permissions

### Calendar Permission Denied

**Scenario:** User skips calendar sync during onboarding.

**Experience:**
1. Show "Limited Mode" warning (see Section 3)
2. App functions with user-created events only
3. No automatic sync from Apple Calendar
4. Availability shown to groups is incomplete
5. Periodic soft reminders in UI (not aggressive)

**Recovery Path:**
- Settings > Calendar
- Re-request with explanation of impact
- One-tap link to system Settings

---

### Notifications Permission Denied

**Scenario:** User denies notification permission.

**Experience:**
1. App works normally
2. Users must actively check app for updates
3. Occasional in-app notification card appears
4. Example: "You missed a proposal from Sarah"

**Recovery Path:**
- Card includes: "Enable notifications" link to Settings

---

### Location Permission Denied

**Scenario:** User denies location access.

**Experience:**
1. App works normally
2. Travel time features not available
3. Event detail screens show location but no ETA
4. No nagging

---

### Contacts Permission Denied When Inviting

**Scenario:** User tries to invite friends but denies contacts access.

**Experience:**
1. User can still manually enter phone numbers/emails
2. Show search interface: "Enter email or phone"
3. No nag screens

---

### User Skips Profile Photo

**Scenario:** User proceeds without adding profile photo.

**Experience:**
1. Default avatar generated (initials or color-based)
2. User can add photo anytime from Settings
3. No blocking

---

### Network Error During Signup

**Scenario:** Network drops during account creation.

**Experience:**
1. Show clear error message
2. Offer "Retry" button
3. Store locally if needed, sync when restored

---

## 10. Onboarding Variations & A/B Tests

### Potential Experiments

1. **Tutorial Length:** 60s vs. 90s vs. full interactive walkthrough
2. **Permission Sequencing:** Calendar first vs. Calendar + Notifications together
3. **Empty State CTA:** "Create Group" vs. "Invite Friends" as primary button
4. **Messaging Tone:** Technical vs. Casual vs. Friendly
5. **Profile Photo Requirement:** Optional vs. Required for better UX

---

## 11. Related Documentation

**For deeper context, see:**
- `lockitin-designs.md` - Full screen layouts and interactions
- `lockitin-invites.md` - Invite flow, deep linking, web previews
- `lockitin-events.md` - Event creation, proposals, voting
- `NotionMD/Complete UI Flows/FLOW 1 ONBOARDING` - Flow diagrams
- `NotionMD/Edge Cases/CALENDAR SYNC - EDGE CASES.md` - Permission denial scenarios

---

*Last updated: December 1, 2025*
