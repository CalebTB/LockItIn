# PHASE 1: MVP DEVELOPMENT

### **Dec 26 - Feb 26 (9 weeks)**

**UPDATED:** Now includes Special Event Templates & Travel Time features

This is where the app comes to life. Work in 2-week sprints.

---

### **SPRINT 1: Foundation & Authentication (Dec 26 - Jan 8)**

**Goals:**

- Authentication working
- Basic project structure
- Calendar view skeleton

**Week 1 (Dec 26 - Jan 1):**

```markdown
Day 1 (Dec 26): Project Setup
□ Set up MVVM architecture (folders, base files)
□ Create Models (User, Group, Event)
□ Set up Supabase connection
□ Test API connection
  Target: API call working by end of day

Day 2 (Dec 27): Authentication UI
□ Create LoginView
□ Create SignUpView
□ Add form validation
□ Basic styling (don't perfect it yet)
  Target: UI screens exist, looking decent

Day 3 (Dec 28): Authentication Logic
□ Connect Supabase auth
□ Implement sign up flow
□ Implement login flow
□ Add error handling
  Target: Can create account & log in

Day 4 (Dec 29): Session Management
□ Store auth token in Keychain
□ Auto-login on app launch
□ Logout functionality
□ Handle token expiration
  Target: Auth persists between app launches

Day 5 (Dec 30): User Profile
□ Fetch user data from Supabase
□ Create basic ProfileView
□ Allow editing name, avatar
□ Save changes to database
  Target: User can update their profile

Day 6 (Dec 31): Calendar View Skeleton
□ Create CalendarView with tab structure
□ Add week header (S M T W T F S)
□ Display current month/year
□ Navigation between months
  Target: Can browse calendar (no events yet)

Day 7 (Jan 1): Rest & Review
□ Review code quality
□ Fix bugs from week
□ Refactor messy code
□ Plan next week
  Target: Clean, working foundation
```

**Week 2 (Jan 2 - Jan 8):**

```markdown
Day 8 (Jan 2): EventKit Integration
□ Request calendar permissions
□ Implement CalendarManager
□ Fetch events from Apple Calendar
□ Display events in list (simple)
  Target: See Apple Calendar events in app

Day 9 (Jan 3): Display Events on Calendar
□ Parse events by date
□ Show event dots on calendar
□ Tap date → show events
□ Add time slots to day view
  Target: Events visible on calendar grid

Day 10 (Jan 4): Event Detail View
□ Create EventDetailView
□ Show title, time, location, notes
□ Add Edit/Delete buttons (UI only)
□ Smooth navigation animations
  Target: Can tap event → see details

Day 11 (Jan 5): Create Event - UI
□ Create EventCreationView
□ Title, date/time pickers
□ Location, notes fields
□ Privacy settings UI (Private/Shared-Busy/Shared-Details)
  Target: All input fields working

Day 12 (Jan 6): Create Event - Logic
□ Connect to CalendarManager
□ Save to Apple Calendar
□ Sync to Supabase database
□ Refresh calendar after creation
  Target: Can create events end-to-end

Day 13 (Jan 7): Edit/Delete Events
□ Implement edit functionality
□ Implement delete with confirmation
□ Handle EventKit sync
□ Update Supabase
  Target: Full event CRUD working

Day 14 (Jan 8): Sprint Review
□ Test all features built
□ Fix critical bugs
□ Demo to a friend
□ Document what works/doesn't
  Target: Usable personal calendar
```

**Sprint 1 Deliverables:**

- ✅ Working authentication
- ✅ Personal calendar syncing with Apple Calendar
- ✅ Create, view, edit, delete events
- ✅ Basic privacy settings (3 levels)
- ✅ Basic UI (not polished, but functional)

---

### **SPRINT 2: Groups & Shadow Calendar (Jan 9 - Jan 22)**

**Goals:**

- Friend connections working
- Group creation & management
- Shadow calendar privacy system
- Group availability heatmap

**Week 3 (Jan 9 - Jan 15):**

```markdown
Day 15 (Jan 9): Friend System - Database
□ Create friendships table
□ API endpoints: send request, accept, decline
□ Test with Postman/Supabase console
  Target: Friend system working in backend

Day 16 (Jan 10): Friend System - UI
□ Create FriendsListView
□ Add friend search
□ Send/accept/decline requests
□ Show friend list
  Target: Can add friends in app

Day 17 (Jan 11): Groups - Backend
□ Create groups table
□ Create group_members table
□ API: create group, add members
  Target: Group database structure working

Day 18 (Jan 12): Groups - UI (List)
□ Create GroupsListView
□ Show user's groups
□ Create group form
□ Add group emoji picker
  Target: Can view and create groups

Day 19 (Jan 13): Groups - UI (Detail)
□ Create GroupDetailView
□ Show members list
□ Add "invite member" flow
□ Show upcoming events placeholder
  Target: Can manage group members

Day 20 (Jan 14): Group Permissions
□ Admin vs member roles
□ Only admin can invite/remove
□ Transfer admin on leave
□ Remove member functionality
  Target: Group permissions working

Day 21 (Jan 15): Sprint Checkpoint
□ Test friend + group flows
□ Fix bugs
□ Optimize performance
□ Code review & refactor
  Target: Stable friend/group system
```

**Week 4 (Jan 16 - Jan 22):**

```markdown
Day 22 (Jan 16): Shadow Calendar - Backend
□ Create calendar_sharing table (user → groups)
□ Create visibility rules per group
□ API to query availability (privacy-respecting)
  Target: Shadow calendar data model

Day 23 (Jan 17): Shadow Calendar - Logic
□ Build AvailabilityManager
□ Calculate busy/free blocks per privacy settings
□ Filter out private event details
□ Generate shadow view per group
  Target: Privacy-respecting availability data

Day 24 (Jan 18): Group Calendar View - Setup
□ Create GroupCalendarView
□ Fetch group members' shadow calendars
□ Handle privacy settings correctly
  Target: Basic group calendar structure

Day 25 (Jan 19): Group Calendar View - Heatmap ⭐
□ Calculate availability overlaps
□ Create heatmap visualization component
□ Color-code by availability % (gradient)
□ Show free/busy counts on tap
  Target: Visual availability heatmap working

Day 26 (Jan 20): Availability Details
□ Tap time slot → show who's available
□ List available vs busy members
□ Respect privacy (show names only, not events)
□ "Propose event here" button
  Target: Detailed availability breakdown

Day 27 (Jan 21): Smart Time Suggestions
□ Build availability analysis algorithm
□ "Find best times" button on group view
□ Suggest top 3 time slots with availability counts
□ Sort by most people available
  Target: Smart suggestions working

Day 28 (Jan 22): Sprint Review
□ Full shadow calendar flow test
□ Verify privacy protection
□ Test heatmap with 8+ member group
□ Get feedback from test users
  Target: Shadow calendar + heatmap rock-solid
```

**Sprint 2 Deliverables:**

- ✅ Friend connections
- ✅ Group creation & management
- ✅ Shadow calendar system (privacy-first)
- ✅ Group availability heatmap
- ✅ Smart time suggestions

---

### **SPRINT 3: Event Proposals & Voting (Jan 23 - Feb 5)**

**Goals:**

- Create group event proposals
- Voting system working
- Real-time vote updates
- Event confirmation & auto-creation

**Week 5 (Jan 23 - Jan 29):**

```markdown
Day 29 (Jan 23): Proposal Backend
□ Create event_proposals table
□ Create proposal_time_options table
□ Create proposal_votes table
□ API endpoints for CRUD
  Target: Proposal database ready

Day 30 (Jan 24): Create Proposal - UI
□ CreateProposalView
□ Title, group selection, location
□ Add time options (2-5 slots)
□ Show live availability for each slot
□ "Find best times" integration
  Target: Proposal creation form working

Day 31 (Jan 25): Create Proposal - Logic
□ Save proposal to database
□ Create time options
□ Send notifications to group
□ Refresh group view
  Target: End-to-end proposal creation

Day 32 (Jan 26): Voting UI
□ Create ProposalVotingView
□ Show all time options
□ Available/Maybe/No buttons
□ Vote counts & progress bars
  Target: Can view proposals & vote

Day 33 (Jan 27): Voting Logic
□ Save votes to database
□ Update vote counts in real-time
□ Handle vote changes (update not insert)
□ Calculate winning option (scoring algorithm)
  Target: Voting fully functional

Day 34 (Jan 28): Real-time Updates
□ Set up Supabase Realtime subscription
□ Subscribe to proposal vote changes
□ Update UI when votes come in
□ Show "X just voted" toasts
  Target: Live vote updates working

Day 35 (Jan 29): Proposal Status Flow
□ Voting deadline logic
□ Auto-confirm when deadline passes or threshold met
□ Create event from winning option
□ Add to everyone's calendar
□ Send confirmations
  Target: Proposals → confirmed events
```

**Week 6 (Jan 30 - Feb 5):**

```markdown
Day 36 (Jan 30): Inbox - Setup
□ Create InboxView
□ Fetch pending proposals
□ Fetch confirmed events
□ Fetch friend requests
  Target: Inbox displaying items

Day 37 (Jan 31): Inbox - Interactions
□ Quick vote from inbox
□ Mark notifications as read
□ Swipe to dismiss
□ Pull to refresh
  Target: Fully interactive inbox

Day 38 (Feb 1): Notifications - Local
□ Schedule deadline reminders
□ "You haven't voted" reminders
□ Event confirmed notifications
□ Test notification timing
  Target: Local notifications working

Day 39 (Feb 2): Notifications - Push Setup
□ Configure APNs certificates
□ Implement PushNotificationManager
□ Save device tokens
□ Test push on physical device
  Target: Push notifications configured

Day 40 (Feb 3): Notifications - Backend
□ Supabase edge function for push
□ Trigger on proposal creation
□ Trigger on vote cast
□ Trigger on event confirmation
  Target: Automated push notifications

Day 41 (Feb 4): Edge Cases - Voting
□ Handle tied votes
□ Handle no one voting
□ Handle proposal cancellation
□ Handle member leaving mid-vote
  Target: All voting edge cases covered

Day 42 (Feb 5): Sprint Review
□ Full proposal flow test (5+ people)
□ Test real-time updates
□ Test notifications
□ Fix critical bugs
  Target: Proposals rock-solid
```

**Sprint 3 Deliverables:**

- ✅ Event proposal creation
- ✅ Multi-option voting system
- ✅ Real-time vote updates
- ✅ Push notifications
- ✅ Auto-event creation from votes

---

### **SPRINT 4: Special Event Templates & Travel (Feb 6 - Feb 19)**

**Goals:**

- Surprise Birthday Party template
- Potluck template
- Location & travel time features
- Template framework for future events

**Week 7 (Feb 6 - Feb 12):**

```markdown
Day 43 (Feb 6): Event Templates - Framework
□ Create EventTemplate base model
□ Template selector UI
□ Custom fields system (tasks, assignments)
□ Template rendering logic
  Target: Template framework in place

Day 44 (Feb 7): Surprise Birthday - Backend
□ Create surprise_events table
□ Create decoy_events table (what target sees)
□ Privacy rules (target can't see real event)
□ Task assignments table
  Target: Surprise party data model

Day 45 (Feb 8): Surprise Birthday - UI (Creation)
□ Surprise party creation flow
□ Select target person (auto-excluded)
□ Cover story input
□ Task assignments (decorations, cake, etc.)
□ Timeline builder
  Target: Can create surprise party

Day 46 (Feb 9): Surprise Birthday - Privacy Logic
□ Target sees only decoy event
□ Coordinators see real event + tasks
□ Auto-reveal after surprise time
□ Planning history preserved
  Target: Surprise mode fully functional

Day 47 (Feb 10): Potluck Template - Backend
□ Create potluck_items table
□ Dish categories (mains, sides, desserts, drinks)
□ Dietary restrictions tracking
□ Host assignment
  Target: Potluck data model

Day 48 (Feb 11): Potluck Template - UI
□ Potluck creation with categories
□ Dish signup interface
□ "What's needed" counter
□ Duplicate warnings
□ Dietary notes display
  Target: Full potluck coordination

Day 49 (Feb 12): Location & Travel - MapKit Setup
□ Import MapKit framework
□ Location search & autocomplete
□ Add location to events
□ Store coordinates in database
  Target: Location selection working
```

**Week 8 (Feb 13 - Feb 19):**

```markdown
Day 50 (Feb 13): Travel Time - Calculation
□ Request location permissions
□ Get user's "home" location (from settings)
□ Calculate travel time via MapKit
□ Support multiple transport modes (car, transit, walk)
  Target: Travel time calculations working

Day 51 (Feb 14): Travel Time - UI
□ Show "Leave by" time on event details
□ Distance & duration display
□ Transport mode selector
□ Real-time traffic updates (basic)
  Target: Travel info visible on events

Day 52 (Feb 15): Travel Time - Notifications
□ "Time to leave" notification
□ Calculate notification time dynamically
□ Traffic delay warnings
□ "I'm on my way" quick action (optional)
  Target: Travel notifications working

Day 53 (Feb 16): Group Travel Coordination
□ Show group members' travel times
□ Aggregate "who needs to leave first"
□ Location fairness suggestions (optional)
  Target: Basic group travel awareness

Day 54 (Feb 17): Template Polish
□ Beautiful template cards
□ Template icons & branding
□ Task completion animations
□ Template previews
  Target: Templates look professional

Day 55 (Feb 18): Integration Testing
□ Test surprise party full flow
□ Test potluck with 8+ people
□ Test travel notifications
□ Fix template bugs
  Target: Templates fully functional

Day 56 (Feb 19): Sprint Review
□ Demo all templates to testers
□ Test edge cases (target accidentally sees, etc.)
□ Performance check
□ Prepare for polish sprint
  Target: Special features ready
```

**Sprint 4 Deliverables:**

- ✅ Surprise Birthday Party template (full privacy)
- ✅ Potluck/Friendsgiving template
- ✅ Event locations with search
- ✅ Travel time calculations
- ✅ "Leave by" notifications
- ✅ Template framework for future events

---

### **SPRINT 5: Polish & Completion (Feb 20 - Feb 26)**

**Goals:**

- UI polish & animations throughout
- Settings & preferences complete
- Premium features foundation
- MVP feature-complete & polished

**Week 9 (Feb 20 - Feb 26):**

```markdown
Day 57 (Feb 20): UI Polish - Calendar
□ Smooth animations (spring physics)
□ Better color scheme consistency
□ Improved typography
□ Loading states everywhere
  Target: Calendar looks professional

Day 58 (Feb 21): UI Polish - Groups & Heatmap
□ Beautiful group cards
□ Avatar images throughout
□ Heatmap gradient refinement
□ Empty states with illustrations
□ Smooth transitions
  Target: Groups UI polished

Day 59 (Feb 22): UI Polish - Proposals & Templates
□ Voting animations (progress bars)
□ Confetti on event confirmed 🎉
□ Template card designs
□ Task completion checkmarks
  Target: Proposals & templates delightful

Day 60 (Feb 23): Settings & Preferences
□ Create SettingsView
□ Privacy settings (default visibility)
□ Notification preferences (granular)
□ Home location setting
□ Travel mode preference
□ Account management
  Target: Complete settings panel

Day 61 (Feb 24): Premium Features - UI
□ Premium badge on profile
□ Upgrade prompts (when hit 3 group limit)
□ Pricing page
□ Features comparison
  Target: Premium UI in place

Day 62 (Feb 25): Premium Features - Logic
□ Free tier limits (3 groups max)
□ Check limits before creating groups
□ Stripe integration setup
□ Subscription status checking
  Target: Premium gating working

Day 63 (Feb 26): Final Polish & MVP Complete! 🎉
□ Onboarding flow (3-4 welcome screens)
□ Request permissions gracefully
□ Bug bash - test everything
□ Record demo video
□ Take App Store screenshots
□ Code documentation
  Target: MVP COMPLETE & READY FOR BETA
```

**Sprint 5 Deliverables:**

- ✅ Polished UI throughout app
- ✅ Complete settings & preferences
- ✅ Premium features foundation
- ✅ Onboarding flow
- ✅ **MVP COMPLETE**

---

# 📊 Updated MVP Feature Count

**Total Features Shipping in MVP:**

**Core Calendar:** 4 features

- Apple Calendar sync
- Event CRUD
- Calendar views (day/week/month)
- Privacy controls (3 levels)

**Social & Groups:** 5 features

- Friend connections
- Group creation & management
- Shadow calendar system
- Group availability heatmap
- Smart time suggestions

**Coordination:** 5 features

- Event proposals (multi-option)
- Voting system
- Real-time vote updates
- Auto-event creation
- Push notifications

**Special Events:** 4 features

- Template framework
- Surprise Birthday template
- Potluck template
- Task assignment system

**Location & Travel:** 4 features

- Location search & selection
- Travel time calculation
- "Leave by" notifications
- Multiple transport modes

**Premium & Polish:** 3 features

- Premium tier (3 group limit free)
- Settings & preferences
- Onboarding flow

**Total: 25 core features**

**Timeline: 9 weeks (Dec 26 - Feb 26)**

**Estimated hours: 240-270 hours**

---

# ⚠️ Updated Checkpoints

**Checkpoint 1 (Jan 8 - End of Sprint 1):**

- ✅ Can users create accounts and log in?
- ✅ Does Apple Calendar sync work?
- ✅ Can users create/edit/delete events with privacy settings?
- ❌ **If no → Extend Sprint 1 by 1 week**

**Checkpoint 2 (Jan 22 - End of Sprint 2):**

- ✅ Can users add friends and create groups?
- ✅ Does shadow calendar privacy work correctly?
- ✅ Does group availability heatmap display?
- ✅ Do smart time suggestions work?
- ❌ **If no → Cut travel features from MVP, ship post-launch**

**Checkpoint 3 (Feb 5 - End of Sprint 3):**

- ✅ Can users create and vote on proposals?
- ✅ Do real-time updates work?
- ✅ Does auto-event creation work?
- ❌ **If no → Cut one template, focus on core voting**

**Checkpoint 4 (Feb 19 - End of Sprint 4):**

- ✅ Does surprise party template work (privacy intact)?
- ✅ Does potluck template work?
- ✅ Do travel time notifications work?
- ❌ **If no → Ship with 1 template instead of 2**

**Checkpoint 5 (Feb 26 - MVP Complete):**

- ✅ Would YOU use this app daily?
- ✅ Would your friends pay $5/month for it?
- ✅ Is it stable (no crashes in normal use)?
- ❌ **If no → Delay beta by 1 week, iterate on UX**

---

**Updated Completion Date: February 26, 2025**

**Beta Testing Starts: February 27, 2025**

**Launch Target: April 8, 2025** (adjusted for extra week)