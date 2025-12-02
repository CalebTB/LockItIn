# LockItIn - Complete Feature Roadmap

**Tagline:** "Lock in plans, not details."

**Last Updated:** December 1, 2025

---

## 📋 Table of Contents

1. [Current Features (Implemented)](#current-features-implemented)
2. [In Progress (Active Development)](#in-progress-active-development)
3. [Future Features](#future-features)
   - [Tier 1: Absolute Must-Haves (MVP)](#tier-1-absolute-must-haves-mvp)
   - [Tier 2: Strong Differentiators](#tier-2-strong-differentiators)
   - [Tier 3: Post-Launch Features (V1.1+)](#tier-3-post-launch-features-v11)
   - [Tier 4: Retention & Engagement](#tier-4-retention--engagement)
   - [Seasonal Event Templates](#seasonal-event-templates)

---

## 🟢 Current Features (Implemented)

**Status:** No features implemented yet. Development starts December 25, 2025.

---

## 🟡 In Progress (Active Development)

**Current Sprint:** Sprint 3 - Event Proposals & Voting
**Development Phase:** Pre-development (planning only until Dec 25, 2025)

### Sprint 1 Issues (Queued - Days 1-14)
- Day 1: Set up MVVM architecture and Supabase connection
- Day 2: Create LoginView and SignUpView with validation
- Day 3: Implement Supabase authentication flows
- Day 4: Implement session persistence with Keychain
- Day 5: Create ProfileView and enable profile editing
- Day 6: Build basic calendar grid view
- Day 7: Sprint 1 Week 1 Review & Refactor
- Day 8: Integrate EventKit and fetch Apple Calendar events
- Day 9: Show event indicators on calendar dates
- Day 10: Create EventDetailView to display full event information
- Day 11: Build EventCreationView with all input fields
- Day 12: Implement event creation and sync to both calendars
- Day 13: Implement edit and delete operations with sync
- Day 14: Sprint 1 Final Review & Testing

### Sprint 2 Issues (Queued - Days 15-28)
- Day 15: Friend System Database & API
- Day 16: Friend System UI
- Day 17: Groups Backend Database
- Day 18: Groups List UI
- Day 19: Group Detail View
- Day 20: Group Permissions & Roles
- Day 21: Sprint 2 Week 3 Review
- Day 22: Shadow Calendar Backend
- Day 23: Group Availability Algorithm
- Day 24: Availability Heatmap UI
- Day 25: Smart Time Suggestions Algorithm
- Day 26: Smart Time Suggestions UI
- Day 27: Sprint 2 Testing & Bug Fixes
- Day 28: Sprint 2 Final Review & Demo

### Sprint 3 Issues (Queued - Days 29-43)
- Day 29: Event Proposals Database Schema
- Day 30: Proposal API Endpoints
- Day 31: Proposal Creation UI
- Day 32: Proposal List View
- Day 33: Voting API Backend
- Day 34: Proposal Detail & Voting UI
- Day 35: Sprint 3 Week 5 Review
- Day 36: Real-time Vote Updates
- Day 37: Push Notifications Setup
- Day 38: Proposal Notifications
- Day 39: Auto Event Creation from Votes
- Day 40: Sprint 3 Testing & Bug Fixes
- Day 41: Sprint 3 Polish & Optimization
- Day 42: Sprint 3 Final Review & Demo

---

## 🔵 Future Features

### TIER 1: Absolute Must-Haves (MVP)

*Cannot launch without these features. Target: April 1, 2026*

#### 1. Personal Calendar Foundation
- Sync with Apple Calendar (read-only via EventKit)
- Display events in the app
- Create/edit/delete events locally
- Basic calendar views (day, week, month)

**Why it's core:** Without a working calendar, nothing else matters.

---

#### 2. Shadow Calendar System
- Mark events as Private / Busy-Only / Full Details
- Groups see "busy blocks" without event titles
- Per-event privacy controls

**Why it's core:** This IS the differentiation. Without this, it's just another shared calendar.

---

#### 3. Friend System
- Add friends by phone/email
- Accept/decline friend requests
- Create friend groups (College Friends, Roommates, etc.)
- Choose which groups see your availability

**Why it's core:** Can't coordinate without knowing who to coordinate with.

---

#### 4. Group Availability Heatmap
- Visual display of when group members are free/busy
- Privacy-preserving (shows counts, not names until tapped)
- Filter by time range (this weekend, next week, etc.)
- Color-coded: green = everyone free, red = most busy

**Why it's core:** Visual killer feature. The "wow" moment that makes people get it instantly.

---

#### 5. Event Proposals with Voting
- Create proposal with 2-5 time options
- Send to a group
- Members vote: Can make it / Maybe / Can't
- Real-time vote tallies
- Organizer confirms winning option
- Event auto-adds to everyone's calendar when confirmed

**Why it's core:** Solves the "30 messages to plan one thing" problem. Main use case.

---

#### 6. Basic Notifications
- New proposal notification
- Voting deadline reminder
- Event confirmed notification
- Event starting soon reminder

**Why it's core:** Without notifications, proposals die in the void.

**Key principle:** Only notify when action is needed. No spam from friends adding personal events.

---

#### 7. 🎂 Surprise Birthday Party Template
- Create event in "Surprise Mode"
- Birthday person auto-excluded from seeing event
- Decoy event shown to birthday person ("Dinner with Mike")
- Task assignments (decorations, cake, get them there)
- Cover story management
- Timeline coordination (arrive before them)
- Auto-reveal after surprise happens
- Planning history shown as keepsake

**Why it's core:** Year-round relevance, emotionally significant, demonstrates privacy controls, word-of-mouth generator.

**Complexity:** Medium-High (requires complex privacy logic)

---

### TIER 2: Strong Differentiators

*Include if time permits — these make the app noticeably better than competitors.*

#### 8. Smart Time Suggestions
- "Find best times" button analyzes group availability
- Suggests top 3 slots based on who's free
- Shows availability count per option ("7/8 people free")

**Why include:** Reduces cognitive load. Shows the app is smart, not just a container.

**Complexity:** Medium (requires availability analysis algorithm)

---

#### 9. Travel Time + Departure Alerts
- Add location to events (MapKit integration)
- Calculate travel time from home location
- Show "Leave by" time on event details
- "Time to leave" notification with real-time traffic
- Multiple transport modes (car, transit, walking)
- Group travel coordination ("Chris needs to leave soon!")

**Why include:** Highly practical, daily utility, differentiates from Howbout/TimeTree. Howbout tells you WHEN something is happening. LockItIn tells you WHEN TO LEAVE.

**Complexity:** Low-Medium (MapKit handles most of it)

---

#### 10. 🍗 Potluck/Friendsgiving Template
- Host assignment
- Dish signup categories (mains, sides, desserts, drinks)
- Serving size tracking
- Dietary restrictions display
- Duplicate prevention warnings ("Someone already signed up for pasta!")
- "What's still needed" view

**Why include:** Highly practical, solves real coordination problem, useful year-round.

**Complexity:** Low-Medium (structured task list)

---

### TIER 3: Post-Launch Features (V1.1+)

*Save for updates after validating core concept.*

- Live arrival status ("I'm on my way")
- Conflict detection when calendar changes
- Group insights/analytics
- Recurring events
- Energy/effort meter
- Smart rescheduling suggestions
- Cross-group conflict warnings
- Flexible attendance (drop-in events)
- Participation tracking
- Fair location picking (minimize total group travel)
- Real-time traffic updates

---

### TIER 4: Retention & Engagement

*Features that build long-term loyalty and keep users coming back.*

**Core principle:** The planning features get people to download. The retention features keep them engaged.

#### 1. BeReal-Style Event Capture
- Prompt for photos after event ends
- Low friction, high emotional value
- No pressure to perform, just candid "we were here" moments
- Come back to see what others posted

**Retention loop:** Memory capture → curiosity about friends' photos → re-engagement

---

#### 2. Year-End Wrapped
- "You attended 47 events with your crew"
- "Your favorite group: College Friends (23 hangouts)"
- Photo memories compilation
- Shareable cards for social media

**Retention loop:** Anticipation of year-end recap → reason to keep logging events → viral sharing

---

#### 3. "Haven't Seen This Group" Nudges
- "It's been 3 weeks since you hung out with College Friends"
- Gentle, not annoying
- Quick action: "Start a plan?"

**Retention loop:** Awareness of social gaps → motivation to reconnect → new event created

---

#### 4. Real-Time Departure Alerts
- "Leave in 15 minutes to make it to Sarah's birthday on time"
- Updates based on live traffic
- Actually useful day-of notification

**Retention loop:** Daily utility → app becomes essential → habitual checking

---

#### 5. Spontaneous "Who's Free" Check
- Quick glance at heatmap for tonight
- See 3 friends are free → drop a quick plan
- Frictionless casual check-in

**Retention loop:** Casual curiosity → low-effort check → spontaneous plans happen

---

## 🎄 Seasonal Event Templates

### Summer Update (June - v1.1)

**Focus: Outdoor & Social Events**

#### New Event Templates:
- 🏖️ **Beach Day / Pool Party**
  - Weather monitoring
  - Outdoor gear checklist
  - Backup indoor location
  - Sunscreen/supplies assignments

- 🎆 **4th of July BBQ**
  - Grill master assignment
  - Food signups (burgers, hot dogs, sides)
  - Fireworks pooling
  - Outdoor games equipment tracking

- ✈️ **Group Trip / Weekend Getaway**
  - Multi-day itinerary
  - Accommodation room assignments
  - Expense splitting
  - Activity voting
  - Packing list

#### Feature Additions:
- Weather integration for outdoor events
- Photo sharing for trip events
- Expense splitting calculator

**Timeline:** Ship mid-June
**Dev time:** 2-3 weeks

---

### Fall Update (October - v1.2)

**Focus: Halloween & Autumn Events**

#### New Event Templates:
- 🎃 **Halloween Party**
  - Costume theme voting
  - Costume reveals (what are you wearing?)
  - Decoration assignments
  - Candy/supplies list
  - Spooky playlist collaboration

- 🏈 **Game Watch Party**
  - Team allegiance display
  - Snack assignments
  - Viewing location
  - Group predictions/bracket

- 🍂 **Oktoberfest / Fall Festival**
  - Activity voting (pumpkin patch, corn maze, etc.)
  - Transportation coordination
  - Group photo spots

#### Feature Additions:
- Costume voting/themes
- Photo spot suggestions
- Team/bracket management

**Timeline:** Ship late September
**Dev time:** 2 weeks

---

### Holiday Update (November - v1.3)

**Focus: Thanksgiving & Year-End Celebrations**

#### New Event Templates:
- 🦃 **Friendsgiving** (enhanced potluck)
  - Traditional Thanksgiving dishes
  - Seating arrangements
  - Gratitude sharing prompts
  - Leftovers distribution

- 🎅 **Secret Santa**
  - Auto-assign gift recipients (private)
  - Budget setting
  - Wishlist submission
  - Exclusion rules (couples, roommates)
  - Name draw with re-draw capability
  - Anonymous gift hints

- 🕎 **Hanukkah Party**
  - 8-night celebration tracking
  - Gift exchange coordination
  - Traditional food signups

- 🎄 **Holiday Party**
  - Ugly sweater contest voting
  - White elephant gift exchange
  - Playlist collaboration
  - Holiday cookie exchange

#### Feature Additions:
- Gift matching algorithm (Secret Santa)
- Anonymous messaging for gift hints
- Gift budget tracking
- Multi-day event series (Hanukkah)

**Timeline:** Ship early November
**Dev time:** 3-4 weeks (Secret Santa is complex)

---

### New Year Update (December - v1.4)

**Focus: Year-End & Winter Events**

#### New Event Templates:
- 🎊 **New Year's Eve Party**
  - Countdown timer
  - Resolution sharing (private/public toggle)
  - Champagne/drinks pooling
  - Transportation/designated driver coordination
  - Morning-after brunch planning

- ❄️ **Ski Trip / Winter Getaway**
  - Multi-day coordination
  - Ski level tracking
  - Equipment rental tracking
  - Slope/activity voting
  - Après-ski planning

- 💝 **Valentine's Day Group Dinner**
  - Singles vs couples coordination
  - Restaurant voting
  - Cost splitting
  - Secret admirer mode (optional)

#### Feature Additions:
- Countdown timers for events
- Resolution tracking year-round
- Skill level matching (for sports)

**Timeline:** Ship mid-December
**Dev time:** 2 weeks

---

### Spring Update (March - v1.5)

**Focus: Spring Events & Celebrations**

#### New Event Templates:
- 🌸 **Spring Break Trip**
  - Week-long itinerary
  - Flight coordination
  - Beach/resort activities
  - Budget tracking

- 🥚 **Easter Brunch / Egg Hunt**
  - Egg hunt organization
  - Brunch potluck
  - Kid-friendly activity planning

- 🎓 **Graduation Party**
  - Guest list management
  - Photo slideshow coordination
  - Gift pooling
  - Speech/toast signup

- 🌮 **Cinco de Mayo Party**
  - Mexican food signups
  - Margarita ingredients pooling
  - Piñata coordination

#### Feature Additions:
- Multi-location coordination (spring break)
- Kid-friendly event modes
- Photo collection/slideshow

**Timeline:** Ship early March
**Dev time:** 2-3 weeks

---

## 🚫 Explicitly NOT in Roadmap

### Year 1 (Post-MVP):
- Android app
- Google Calendar / Outlook integration
- Recurring availability patterns
- Calendar widgets

### Year 2+ (Growth Phase - Public/Business Events):
- Public event discovery (concerts, shows, restaurants)
- Business-posted events (venues can post events)
- Event sharing to friend groups (vote on which public event to attend)
- Ticketing integration
- Advanced event discovery features

**Why Friend Groups First:**
- Simpler use case, faster validation
- Network effects work better with private groups
- Privacy controls are core differentiator
- Less competition than public events space
- Easier to build trust and community

**Future Vision:** Validate product-market fit with friend coordination, then expand to let businesses post events that friends can discover and coordinate attendance on together.

---

## 📊 Feature Ideas from Market Research

### Considered but Deferred

#### ⭐ Smart Contextual Scheduling
- AI meeting time suggester that considers:
  - Travel time between events
  - Group preferences (e.g., "prefer evenings," "avoid Mondays")
  - Commute constraints
  - Time zone fatigue rules
- Energy-based scheduling (e.g., "low-energy mornings" vs "creative hours")
- Schedule health score (flags overloaded days)

**Status:** Consider for Year 2 premium feature

---

#### ⭐ Automated Task ↔ Calendar Integration
- Drag a task onto a calendar slot to auto-schedule
- Tasks auto-reschedule when conflicts happen
- Shared task → shared time block (e.g., "clean clubhouse 2 hrs this weekend")

**Status:** Out of scope - different product category

---

#### ⭐ Event-Based Social Layer
- Event comments & polls (in one place)
- Group photo sharing tied to events
- Event "memory" pages (photos + summaries + attendance logs)
- Micro-communities: recurring groups with chats, profiles, histories

**Status:** Partially implemented via BeReal-style capture, but NO social feed

---

#### ⭐ Anonymous or Soft RSVP Feedback
- Anonymous "likely / maybe / low chance" participation votes
- Crowd interest tracking (let people express interest without joining)

**Status:** Already implemented via "Can make it / Maybe / Can't" voting

---

#### ⭐ Fine-Grained Privacy Controls
- Share busy/free ONLY ✅ (Shadow Calendar)
- Share title only but hide details ✅ (Shadow Calendar)
- Share specific windows ✅ (Shadow Calendar)
- Share different levels with different groups ✅ (Shadow Calendar)

**Status:** CORE FEATURE - Already in MVP

---

#### ⭐ Household & Relationship Support
- Couples syncing calendars with "visibility rules"
- Household scheduling (chores, groceries, shared tasks)
- Parenting mode → shared school schedules, custody schedule, reminders, health notes

**Status:** Consider for Year 2 expansion

---

#### ⭐ Real-Time Presence & Micro-Location
- "Who's already at the event?"
- "How far is everyone?"
- Location-based auto-check-in
- Geofenced reminders

**Status:** REJECTED - Conflicts with privacy-first positioning

---

#### ⭐ Local Event Discovery + Business Integration
- Let businesses post events to nearby users
- Allow users to follow businesses/venues
- Provide "recommended events" based on past behavior
- Integrate ticketing or small payments

**Status:** Year 2+ Growth Phase

---

#### ⭐ Conflict Resolution Tools
- Suggest alternate times
- Suggest splitting large groups into smaller ones
- Ask participants for quick inputs to resolve conflicts
- Suggest virtual/in-person hybrid depending on availability

**Status:** Consider for v1.2+

---

#### ⭐ Habit + Calendar Fusion
- Habit streaks that appear on the calendar
- Shared habit tracking between friends
- Streak-based group challenges

**Status:** Out of scope - different product category

---

#### ⭐ Calendar Gamification
- Group XP for attending events
- Badges for consistency
- "Event streaks"
- Team challenges

**Status:** REJECTED - Conflicts with "calm, not chaotic" philosophy

---

#### ⭐ Accessibility & Neurodiversity-Friendly Features
- Color-coded mode for sensory clarity
- "One-tap plan for the day"
- Simplified view mode
- Automatic breakdown of large events into smaller steps
- Voice planning

**Status:** Consider for accessibility update (v1.6+)

---

## 🗓️ Seasonal Release Calendar

```
2026 Release Timeline:

📅 April 1 (v1.0) - MVP LAUNCH
├─ Core calendar features
├─ Shadow calendar
├─ Group coordination
├─ Surprise Birthday
└─ Potluck template

☀️ June 15 (v1.1) - SUMMER UPDATE
├─ Beach/Pool Party
├─ 4th of July BBQ
└─ Group Trip template

🍂 September 25 (v1.2) - FALL UPDATE
├─ Halloween Party
├─ Game Watch Party
└─ Fall Festival template

🦃 November 1 (v1.3) - HOLIDAY UPDATE
├─ Enhanced Friendsgiving
├─ Secret Santa ⭐
├─ Hanukkah Party
└─ Holiday Party

🎊 December 15 (v1.4) - NEW YEAR UPDATE
├─ New Year's Eve
├─ Ski Trip
└─ Valentine's Group Dinner

🌸 March 1 (v1.5) - SPRING UPDATE
├─ Spring Break Trip
├─ Easter Brunch
└─ Graduation Party
```

---

## 🎯 What This MVP Proves

If we ship this, we'll have proven:

1. ✅ **Privacy-first coordination works** (shadow calendar)
2. ✅ **Visual availability is useful** (heatmap)
3. ✅ **Voting is faster than group chat** (proposals)
4. ✅ **Smart suggestions save time** (find best times)
5. ✅ **Special event types add real value** (surprise parties, potlucks)

That's enough to validate product-market fit.

---

## 📈 Final MVP Feature Count

```
MVP v1.0 - Launch Features (April 1, 2026)
┌─────────────────────────────────────┐
│ CORE CALENDAR                       │
│ ✅ Apple Calendar sync (read)       │
│ ✅ View events (day/week/month)     │
│ ✅ Create/edit/delete events        │
│                                     │
│ PRIVACY & SHARING                   │
│ ✅ Shadow calendar system           │
│ ✅ Per-event privacy controls       │
│ ✅ Add friends                      │
│ ✅ Create groups                    │
│ ✅ Share availability with groups   │
│                                     │
│ GROUP COORDINATION                  │
│ ✅ Availability heatmap             │
│ ✅ Create event proposals           │
│ ✅ Multi-option voting              │
│ ✅ Real-time vote updates           │
│ ✅ Confirm & create event           │
│ ✅ "Find best times" suggestions 🌟 │
│                                     │
│ SPECIAL EVENT TEMPLATES             │
│ ✅ 🎂 Surprise Birthday Party       │
│ ✅ 🍗 Potluck/Friendsgiving         │
│                                     │
│ LOCATION & TRAVEL                   │
│ ✅ Event locations                  │
│ ✅ Travel time calculation          │
│ ✅ "Leave by" notifications         │
│                                     │
│ NOTIFICATIONS                       │
│ ✅ New proposal alert               │
│ ✅ Vote reminder                    │
│ ✅ Event confirmed                  │
│ ✅ Event starting soon              │
│ ✅ Time to leave reminder           │
└─────────────────────────────────────┘

Total core features: 25
Estimated dev time: 7-8 weeks
```

---

## 🔔 Notification Philosophy

**Key differentiator from Howbout: Calm, not chaotic.**

### What DOES Trigger Notifications
- Group event proposal (action needed: vote)
- Event confirmed (informational)
- Time to leave (action needed: go)
- Post-event photo prompt (optional action)

### What Does NOT Trigger Notifications
- Friend adding a personal event
- Someone updating their availability
- Activity feed updates
- Events you weren't invited to

---

## 📱 Event Flow States

1. **Personal →** Completely private, just blocks availability
2. **Proposed →** Group gets pinged, voting opens
3. **Voting →** Members vote on time options
4. **Locked In →** Time confirmed, on everyone's calendar
5. **Completed →** Event happened, photo prompt sent
6. **Memory →** Stored for year-end wrapped

---

## 🎯 The Pitch

*"LockItIn makes group plans actually happen — then helps you remember them."*

The planning is the promise. The memories are the surprise that makes people stay and tell friends.

---

*This is the single source of truth for all LockItIn features, past, present, and future.*
