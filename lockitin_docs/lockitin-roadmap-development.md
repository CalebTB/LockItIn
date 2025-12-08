# Shareless: Everything Calendar - Development Roadmap

**Complete 6-Month Development Timeline & Delivery Schedule**

- **Target Launch:** April 30, 2026
- **Total Development Time:** 6 months (Dec 1, 2025 - Apr 30, 2026)
- **Development Status:** Pre-development phase (planning until Dec 25, 2025)
- **Total Development Hours:** ~450-500 hours

---

## Overview: Development Phases

```
┌──────────────────────────────────────────────────────────────┐
│  PHASE 0        │  PHASE 1     │  PHASE 2    │  PHASE 3      │
│  PRE-MAC PREP   │  MVP BUILD   │  BETA       │  LAUNCH       │
│  (Dec 1-25)     │  (Dec 26-Feb) │ (Feb 27-Apr) │ (Apr 9-30)   │
│  4 weeks        │  9 weeks     │  6 weeks    │  4 weeks      │
└──────────────────────────────────────────────────────────────┘
   Learning       Core App       Testing &    App Store &
   & Planning     Development    Iteration    Growth
```

### Key Milestone Dates

| Date | Milestone | Status |
|------|-----------|--------|
| Dec 1 | Phase 0 starts (learning & research) | Pending |
| Dec 25 | Mac Mini arrives, coding begins | Pending |
| Jan 8 | Checkpoint 1: Foundation complete | Pending |
| Jan 22 | Checkpoint 2: Groups & privacy working | Pending |
| Feb 5 | Checkpoint 3: Voting system complete | Pending |
| Feb 19 | Checkpoint 4: Special templates done | Pending |
| Feb 26 | MVP feature-complete | Pending |
| Feb 27 | Phase 2 begins: Beta testing (50-100 testers) | Pending |
| Apr 8 | Beta testing complete | Pending |
| Apr 9 | Phase 3 begins: App Store submission & soft launch | Pending |
| Apr 30 | Public launch target | Pending |
| May 15 | Full public launch push | Pending |

---

## PHASE 0: PRE-MAC PREPARATION

**Duration:** December 1-25, 2025 (4 weeks)

This phase requires NO coding. Focus on learning, validation, and preparation to maximize productivity on Day 1 of development.

### Week 1 (Dec 1-7): Market Research & Validation

**Goals:** Validate the problem exists, understand competitive landscape, define MVP scope

**Tasks:**
- Interview 10 people from friend groups (30 min each)
  - How do they currently plan group events?
  - What's most frustrating about current methods?
  - Would they pay $5/month to solve it?
  - What features matter most?
- Download and analyze competitors: Doodle, When2Meet, Calendly, Fantastical
  - Document strengths and weaknesses
  - Identify gaps Shareless will fill
- Create 2-3 user personas (e.g., "Sarah, 24, organizes monthly game nights")
- Define success metrics:
  - Week 1 launch: 50 users
  - Month 1: 200 users, 10 active groups
  - Month 3: 1,000 users, 5% conversion to premium

**Deliverables:**
- Interview notes document
- Competitive analysis spreadsheet
- User persona slides
- Success metrics dashboard design

### Week 2 (Dec 8-14): Design & Architecture Planning

**Goals:** Finalize UI/UX flows, create detailed wireframes, plan database schema

**Tasks:**
- Sketch all screens on paper
  - Main calendar view
  - Event creation flow
  - Group proposal interface
  - Voting screens
  - Group calendar overlay
- Create digital wireframes in Figma (free tier)
  - Import sketches
  - Add navigation flows
  - Define color palette (3-4 colors max)
  - Choose typography (platform-appropriate for Flutter/Dart cross-platform development)
- Design key interactions
  - Navigation animations
  - Voting interactions
  - Loading/empty/error states
- Finalize database schema
  - Review PostgreSQL design
  - Identify missing fields
  - Plan indexes for performance

**Deliverables:**
- Complete Figma wireframes for all screens
- Interaction flow videos (using Figma prototypes)
- Database schema diagram (dbdiagram.io)
- Asset list (icons, images needed)

**Tools to Set Up:**
- Figma account (free)
- dbdiagram.io
- Notion or project management tool

### Week 3 (Dec 15-21): Flutter & Dart Learning

**Goals:** Build Flutter/Dart foundation, understand cross-platform development basics

**Daily Schedule:**
- Morning (1-2 hrs): Flutter & Dart tutorials
- Afternoon (1 hr): Backend/Supabase learning
- Evening (30 min): Review notes, plan next day

**Learning Path:**
- **Days 1-3:** Dart fundamentals
  - Variables, functions, null safety
  - Object-oriented programming in Dart
  - Async/await patterns
  - Resource: Dart language tour (dart.dev)

- **Days 4-7:** Flutter basics
  - Widgets, layouts, composition
  - Stateful vs Stateless widgets
  - State management fundamentals
  - Resource: Flutter & Dart - The Complete Guide (Udemy)
  - Resource: Official Flutter documentation (flutter.dev)

- **Days 8-12:** Navigation, forms, platform channels
  - Flutter navigation patterns
  - Form validation and input handling
  - Introduction to platform channels (iOS & Android native code)
  - Resource: Flutter codelabs and samples

- **Days 13-16:** Provider state management
  - Provider pattern for state management
  - Async patterns and futures
  - Error handling strategies
  - Resource: Official Provider documentation

- **Days 17-21:** Material Design + Cupertino widgets
  - Material Design widgets (Android-style)
  - Cupertino widgets (iOS-style)
  - Platform-adaptive UI patterns
  - Practice: Building platform-specific interfaces

- **Days 22-25:** Practice projects
  - Task: "Simple To-Do List App"
  - Features: Add items, delete items, mark complete, persist data
  - Practice: Provider, Lists, Forms, Platform-specific UI

**Framework Learning:**
- Platform channels for calendar access
  - EventKit (iOS) integration via platform channels
  - CalendarContract (Android) integration via platform channels
  - Understand permission flows on both platforms

- Supabase (backend)
  - Watch: "Supabase in 100 seconds" video
  - Read: Supabase Dart/Flutter SDK docs
  - Build: Simple CRUD app with Supabase

**Developer Accounts:**
- Create Apple Developer account ($99/year)
- Create Google Play Developer account ($25 one-time)
- Create Supabase account (free tier)
- Create Stripe account (for future monetization)

**Deliverables:**
- Completed to-do list app (demonstrates Flutter proficiency)
- Platform channel notes (EventKit + CalendarContract capabilities)
- Supabase test project with CRUD operations
- All developer accounts active

### Week 4 (Dec 22-25): Architecture & Launch Prep

**Goals:** Plan technical architecture, prepare for Day 1 coding, finalize designs

**Tasks:**
- Refine technical architecture
  - Create project structure diagram
  - List all dependencies needed
  - Plan API endpoints (data flow)
  - Review Provider patterns for Flutter state management

- Break down MVP into GitHub issues
  - Create 100+ specific tasks
  - Estimate hours per task
  - Prioritize: Must-have vs Nice-to-have
  - Group by feature area

- Set up project tracking
  - Create GitHub repository
  - Set up project board with sprints
  - Define milestones by sprint
  - Create daily development schedule

- Prepare Day 1 checklist
  - Flutter project setup (Android Studio + VS Code)
  - Project setup commands
  - Dependencies to install
  - First features to build
  - TestFlight + Google Play Internal Testing preparation

- Final design polish
  - Get feedback from 2-3 friends on Figma designs
  - Make final adjustments
  - Export assets (icons, colors as Dart code)

- Workspace preparation
  - Clear schedule for Dec 26-27 (dedicated coding)
  - Set up development workspace (desk, monitor)
  - Plan meals/minimize distractions

**Deliverables:**
- Complete task breakdown (100+ tasks)
- GitHub repository created and configured
- Project board with all sprints defined
- Day 1 setup checklist
- Design assets ready to import

### Christmas Day (Dec 25): Mac Mini Setup

**Timeline:**
```
8:00 AM - Unbox Mac Mini
         - Connect to monitor, keyboard, mouse
         - Complete macOS setup

8:30 AM - Software Installation
         - Android Studio download (install Flutter plugin)
         - VS Code download (install Flutter + Dart extensions)
         - Homebrew installation
         - Install git
         - Flutter SDK installation

10:00 AM - Developer Setup
          - Sign in to Apple Developer account
          - Sign in to Google Play Developer account
          - Configure Android Studio with Flutter SDK
          - Configure VS Code with Flutter extensions
          - Connect GitHub account

11:00 AM - Create First Project
          - flutter create calendar_app
          - Open in Android Studio or VS Code
          - Run on iOS Simulator: flutter run
          - Run on Android Emulator: flutter run
          - Verify both platforms work

12:00 PM - Dependency Setup
          - Add Supabase package dependency (pubspec.yaml)
          - Configure AndroidManifest.xml for calendar permissions
          - Configure Info.plist for calendar access (iOS)
          - Set up project structure (Provider pattern)

2:00 PM - First Commit
         - git init
         - git add .
         - git commit -m "Initial Flutter project setup"
         - git push to GitHub

3:00 PM - Build First Feature
         - Create simple calendar screen (just dates)
         - Test on both iOS and Android
         - See something on screen!

5:00 PM - Plan Tomorrow
         - Review Day 1 plan
         - Get good sleep
```

---

## PHASE 1: MVP DEVELOPMENT

**Duration:** December 26, 2025 - February 26, 2026 (9 weeks)

**Status:** Pending (starts after Mac Mini arrives)

**Goals:** Build complete MVP with 25 core features across 5 sprints

**Development Pace:** ~240-270 hours total (3-4 hours per day)

### Sprint 1: Foundation & Authentication

**Duration:** Dec 26 - Jan 8 (2 weeks)

**Goals:**
- Authentication working
- Personal calendar sync with Apple Calendar
- Create/read/edit/delete events
- Basic privacy settings

#### Week 1 (Dec 26 - Jan 1)

| Day | Date | Focus | Deliverables | Target |
|-----|------|-------|---------------|--------|
| 1 | Dec 26 | Project Setup | Provider architecture, Models, Supabase connection | API call working |
| 2 | Dec 27 | Auth UI | Login/SignUp screens (Material + Cupertino), validation | UI screens complete on both platforms |
| 3 | Dec 28 | Auth Logic | Sign up/login flows, error handling | Can create account & log in |
| 4 | Dec 29 | Session Mgmt | Secure storage, auto-login, token expiration | Auth persists between launches |
| 5 | Dec 30 | User Profile | Profile fetch/edit, avatar support | User can update profile |
| 6 | Dec 31 | Calendar Skeleton | Calendar widget (Material + Cupertino), month navigation | Can browse calendar on iOS & Android |
| 7 | Jan 1 | Review & Polish | Code review, bug fixes, refactoring | Clean, working foundation on both platforms |

#### Week 2 (Jan 2 - Jan 8)

| Day | Date | Focus | Deliverables | Target |
|-----|------|-------|---------------|--------|
| 8 | Jan 2 | Platform Channel Integration | Permissions, EventKit (iOS) + CalendarContract (Android), fetch events | See native calendar events on both platforms |
| 9 | Jan 3 | Display Events | Parse by date, event dots, day view | Events visible on calendar |
| 10 | Jan 4 | Event Details | Event detail screen, edit/delete buttons | Can tap event → see details |
| 11 | Jan 5 | Create Event UI | Title, date/time, location, privacy fields (adaptive UI) | All input fields working on both platforms |
| 12 | Jan 6 | Create Event Logic | Save to native calendar & Supabase (iOS & Android) | Can create events end-to-end |
| 13 | Jan 7 | Edit/Delete | Full CRUD operations, platform channel sync | Full event CRUD working on both platforms |
| 14 | Jan 8 | **CHECKPOINT 1** | Test all features on iOS & Android, demo to friend | Usable personal calendar on both platforms |

**Checkpoint 1 (Jan 8) - Must Pass:**
- ✅ Can users create accounts and log in on both platforms?
- ✅ Does native calendar sync work (iOS & Android)?
- ✅ Can users create/edit/delete events with privacy settings?
- ✅ Does the app work correctly on both iOS and Android?
- ❌ **If no → Extend Sprint 1 by 1 week**

**Sprint 1 Deliverables:**
- Working authentication system on both platforms
- Personal calendar syncing with native calendars (iOS & Android)
- Full event CRUD (create, view, edit, delete)
- 3-level privacy settings UI
- Basic functional UI (platform-adaptive, not polished)
- Testing on both iOS Simulator and Android Emulator

---

### Sprint 2: Groups & Shadow Calendar

**Duration:** Jan 9 - Jan 22 (2 weeks)

**Goals:**
- Friend system working
- Group creation & management
- Shadow calendar privacy system
- Group availability heatmap
- Smart time suggestions

#### Week 3 (Jan 9 - Jan 15)

| Day | Date | Focus | Deliverables | Target |
|-----|------|-------|---------------|--------|
| 15 | Jan 9 | Friend System - DB | Friendships table, API endpoints | Friend system backend ready |
| 16 | Jan 10 | Friend System - UI | FriendsListView, search, requests | Can add friends in app |
| 17 | Jan 11 | Groups - Backend | Groups table, group_members table | Group database structure |
| 18 | Jan 12 | Groups - UI (List) | GroupsListView, create form, emoji picker | Can view & create groups |
| 19 | Jan 13 | Groups - UI (Detail) | GroupDetailView, members list, invites | Can manage members |
| 20 | Jan 14 | Group Permissions | Admin vs member roles, transfers | Group permissions working |
| 21 | Jan 15 | Checkpoint Review | Test friend + group flows, bug fixes | Stable friend/group system |

#### Week 4 (Jan 16 - Jan 22)

| Day | Date | Focus | Deliverables | Target |
|-----|------|-------|---------------|--------|
| 22 | Jan 16 | Shadow Calendar - DB | calendar_sharing table, visibility rules | Shadow calendar data model |
| 23 | Jan 17 | Shadow Calendar - Logic | AvailabilityManager, privacy filtering | Privacy-respecting availability data |
| 24 | Jan 18 | Group Calendar - Setup | Group calendar screen, fetch shadow calendars | Basic group calendar structure |
| 25 | Jan 19 | Group Calendar - Heatmap | Availability overlaps, visualization | Visual heatmap working |
| 26 | Jan 20 | Availability Details | Tap time → show who's available | Detailed availability breakdown |
| 27 | Jan 21 | Smart Suggestions | "Find best times" algorithm | Smart suggestions working |
| 28 | Jan 22 | **CHECKPOINT 2** | Full shadow calendar test on both platforms, privacy verify | Shadow calendar rock-solid |

**Checkpoint 2 (Jan 22) - Must Pass:**
- ✅ Can users add friends and create groups?
- ✅ Does shadow calendar privacy work correctly?
- ✅ Does group availability heatmap display?
- ✅ Do smart time suggestions work?
- ❌ **If no → Cut travel features from MVP**

**Sprint 2 Deliverables:**
- Friend connection system
- Group creation & management
- Shadow calendar system (privacy-first)
- Group availability heatmap with color-coded visualization
- Smart time suggestion algorithm

---

### Sprint 3: Event Proposals & Voting

**Duration:** Jan 23 - Feb 5 (2 weeks)

**Goals:**
- Event proposal creation
- Multi-option voting system
- Real-time vote updates (WebSocket)
- Push notifications
- Auto-event creation from votes

#### Week 5 (Jan 23 - Jan 29)

| Day | Date | Focus | Deliverables | Target |
|-----|------|-------|---------------|--------|
| 29 | Jan 23 | Proposal Backend | event_proposals, proposal_time_options, votes tables | Proposal database ready |
| 30 | Jan 24 | Create Proposal UI | CreateProposalView, time options, availability | Proposal form working |
| 31 | Jan 25 | Create Proposal Logic | Save to DB, notifications, refresh | End-to-end proposal creation |
| 32 | Jan 26 | Voting UI | ProposalVotingView, buttons, progress bars | Can view & vote |
| 33 | Jan 27 | Voting Logic | Save votes, update counts, scoring algorithm | Voting fully functional |
| 34 | Jan 28 | Real-time Updates | Supabase Realtime subscriptions, UI updates | Live vote updates working |
| 35 | Jan 29 | Proposal Status | Deadline logic, auto-confirm, event creation | Proposals → confirmed events |

#### Week 6 (Jan 30 - Feb 5)

| Day | Date | Focus | Deliverables | Target |
|-----|------|-------|---------------|--------|
| 36 | Jan 30 | Inbox - Setup | InboxView, fetch proposals/events/requests | Inbox displaying items |
| 37 | Jan 31 | Inbox - Interactions | Quick vote, dismiss, pull-to-refresh | Fully interactive inbox |
| 38 | Feb 1 | Notifications - Local | Deadline reminders, vote reminders | Local notifications working |
| 39 | Feb 2 | Notifications - Push Setup | APNs certificates, PushNotificationManager | Push notifications configured |
| 40 | Feb 3 | Notifications - Backend | Edge function for push triggers | Automated push notifications |
| 41 | Feb 4 | Edge Cases | Tied votes, no voters, cancellation, member leaves | All voting edge cases covered |
| 42 | Feb 5 | **CHECKPOINT 3** | Full proposal flow test (5+ people), real-time verify | Proposals rock-solid |

**Checkpoint 3 (Feb 5) - Must Pass:**
- ✅ Can users create and vote on proposals?
- ✅ Do real-time updates work?
- ✅ Does auto-event creation work?
- ❌ **If no → Cut one template from Sprint 4**

**Sprint 3 Deliverables:**
- Event proposal creation with multi-option support
- Full voting system with real-time updates
- Push notification system (local and remote)
- Auto-event creation when voting concludes
- Complete proposal management flow

---

### Sprint 4: Special Event Templates & Travel Features

**Duration:** Feb 6 - Feb 19 (2 weeks)

**Goals:**
- Surprise Birthday Party template (complete privacy system)
- Potluck/Friendsgiving template
- Event location search with MapKit
- Travel time calculations
- "Leave by" notifications

#### Week 7 (Feb 6 - Feb 12)

| Day | Date | Focus | Deliverables | Target |
|-----|------|-------|---------------|--------|
| 43 | Feb 6 | Template Framework | EventTemplate base, selector UI, custom fields | Template framework in place |
| 44 | Feb 7 | Surprise Birthday - DB | surprise_events, decoy_events, task assignments | Surprise party data model |
| 45 | Feb 8 | Surprise Birthday - UI | Creation flow, target selection, task assignments | Can create surprise party |
| 46 | Feb 9 | Surprise Birthday - Privacy | Target sees decoy, coordinators see real event | Surprise mode fully functional |
| 47 | Feb 10 | Potluck - Backend | potluck_items table, categories, dietary tracking | Potluck data model |
| 48 | Feb 11 | Potluck - UI | Creation, dish signup, "what's needed" counter | Full potluck coordination |
| 49 | Feb 12 | Location & Travel - MapKit | Location search, autocomplete, coordinates | Location selection working |

#### Week 8 (Feb 13 - Feb 19)

| Day | Date | Focus | Deliverables | Target |
|-----|------|-------|---------------|--------|
| 50 | Feb 13 | Travel Time - Calc | Location permissions, home location, travel time | Travel time calculations |
| 51 | Feb 14 | Travel Time - UI | "Leave by" time, distance, transport modes | Travel info visible on events |
| 52 | Feb 15 | Travel Time - Notif | Time-to-leave notification, traffic warnings | Travel notifications working |
| 53 | Feb 16 | Group Travel | Show members' travel times, aggregate data | Basic group travel awareness |
| 54 | Feb 17 | Template Polish | Beautiful cards, icons, animations | Templates look professional |
| 55 | Feb 18 | Integration Testing | Full flows (surprise party, potluck, travel) | Templates fully functional |
| 56 | Feb 19 | **CHECKPOINT 4** | Demo templates, edge case testing, performance | Special features ready |

**Checkpoint 4 (Feb 19) - Must Pass:**
- ✅ Does surprise party template work (privacy intact)?
- ✅ Does potluck template work?
- ✅ Do travel time notifications work?
- ❌ **If no → Ship with 1 template instead of 2**

**Sprint 4 Deliverables:**
- Surprise Birthday Party template (full privacy system)
- Potluck/Friendsgiving template with task assignments
- Event location search (MapKit integration)
- Travel time calculations with multiple transport modes
- "Leave by" notifications with traffic integration
- Complete template framework for future expansion

---

### Sprint 5: Polish & Completion

**Duration:** Feb 20 - Feb 26 (1 week)

**Goals:**
- UI polish throughout app
- Complete settings & preferences
- Premium features foundation
- Onboarding flow
- MVP feature-complete & launch-ready

#### Week 9 (Feb 20 - Feb 26)

| Day | Date | Focus | Deliverables | Target |
|-----|------|-------|---------------|--------|
| 57 | Feb 20 | UI Polish - Calendar | Spring physics animations, colors, typography | Calendar looks professional |
| 58 | Feb 21 | UI Polish - Groups | Avatar images, heatmap refinement, empty states | Groups UI polished |
| 59 | Feb 22 | UI Polish - Proposals | Voting animations, confetti, template cards | Proposals & templates delightful |
| 60 | Feb 23 | Settings & Preferences | SettingsView, privacy settings, notifications | Complete settings panel |
| 61 | Feb 24 | Premium Features - UI | Premium badge, upgrade prompts, pricing | Premium UI in place |
| 62 | Feb 25 | Premium Features - Logic | Free tier limits (3 groups), Stripe setup | Premium gating working |
| 63 | Feb 26 | **MVP COMPLETE** | Onboarding, permissions, bug bash, screenshots | Ready for beta testing |

**Checkpoint 5 (Feb 26) - MVP Complete:**
- ✅ Would YOU use this app daily?
- ✅ Would your friends pay $5/month for it?
- ✅ Is it stable (no crashes in normal use)?
- ❌ **If no → Delay beta by 1 week, iterate**

**Sprint 5 Deliverables:**
- Polished UI throughout entire app
- Complete settings & preferences panel
- Premium features foundation (3-group free limit)
- Onboarding flow (3-4 welcome screens)
- App Store screenshots & demo video
- **MVP FEATURE-COMPLETE & READY FOR BETA**

---

### MVP Feature Summary

**Total Features Shipping:** 25 core features

**By Category:**

**Core Calendar (4):**
- Apple Calendar sync with bidirectional updates
- Event CRUD (create, read, update, delete)
- Calendar views (day/week/month)
- 3-level privacy controls (Private, Shared-With-Name, Busy-Only)

**Social & Groups (5):**
- Friend connections with request system
- Group creation & member management
- Shadow calendar system (privacy-respecting)
- Group availability heatmap with color coding
- Smart time suggestion algorithm

**Event Coordination (5):**
- Event proposal creation (multi-option)
- Voting system with real-time updates
- Real-time vote updates via WebSocket
- Auto-event creation from winning votes
- Push notifications (local & remote via APNs)

**Special Event Templates (4):**
- Template framework for extensibility
- Surprise Birthday Party template (with privacy)
- Potluck/Friendsgiving template
- Task assignment system for templates

**Location & Travel (4):**
- Event location search (MapKit)
- Travel time calculations (multiple transport modes)
- "Leave by" time notifications
- Group travel awareness & coordination

**Premium & Polish (3):**
- Premium tier (3-group free limit, unlimited premium)
- Complete settings & preferences
- Onboarding flow with permissions

**Development Timeline:** 9 weeks (Dec 26, 2025 - Feb 26, 2026)
**Estimated Hours:** 240-270 hours
**Beta Starts:** February 27, 2026

---

## PHASE 2: BETA TESTING & ITERATION

**Duration:** February 27 - April 8, 2026 (6 weeks)

**Status:** Pending

**Goals:** Validate product-market fit, gather user feedback, iterate on UX/features

### Testing Cohorts

**Alpha Testing (Week 1: Feb 27 - Mar 5)**
- 5-10 close friends
- Focus: Identify critical bugs, missing flows
- Daily communication, rapid iteration
- Run through all user scenarios
- Target: Zero critical bugs, feature-complete

**Closed Beta (Weeks 2-4: Mar 6 - Mar 26)**
- 50-100 beta testers
- Mix of friends, community (Reddit, Twitter, Discord)
- Focus: Usability, performance, retention
- Daily standups on key metrics
- Bi-weekly builds with improvements

**Public Beta (Weeks 5-6: Mar 27 - Apr 8)**
- TestFlight public link
- Target: 500+ total testers
- Focus: App Store readiness, edge cases
- Collect testimonials & reviews
- Final polish based on feedback

### Weekly Structure

| Week | Dates | Focus | Deliverables |
|------|-------|-------|--------------|
| 1 | Feb 27 - Mar 5 | Alpha Testing | Zero critical bugs, feature-complete |
| 2 | Mar 6 - Mar 12 | Bug Fixes v1 | App v1.01, DAU tracking |
| 3 | Mar 13 - Mar 19 | Feature Iteration | App v1.02, 50+ DAU, reviews |
| 4 | Mar 20 - Mar 26 | Performance Tuning | App v1.03, 40%+ Day-7 retention |
| 5 | Mar 27 - Apr 2 | Public Beta | TestFlight public, 500+ testers |
| 6 | Apr 3 - Apr 8 | Final Polish | App Store screenshots, demo video |

### Success Metrics (by Apr 8)

**User Metrics:**
- 100+ beta testers actively using app
- 50+ daily active users (DAU)
- 40%+ Day-7 retention (Day 1 = 100%, Day 7 = 40%+)
- 4.0+ star rating from testers

**Quality Metrics:**
- Zero critical bugs in production
- <2 crashes per 1,000 sessions
- <500ms average response times
- All features tested on iOS 17+ devices

**Feedback Metrics:**
- 5+ testimonials/quotes for marketing
- Top 3 feature requests documented
- Competitive differentiation validated
- Pricing validated ($4.99/mo premium)

### Decision Checkpoints

**Checkpoint (Mar 19 - Before App Store Submission):**
- ✅ Beta testers love it (4+ star average)?
- ✅ Retention >40% after Day 7?
- ✅ Zero critical bugs in last week?
- ❌ **If no → Delay launch by 1 week, polish more**

---

## PHASE 3: LAUNCH & GROWTH

**Duration:** April 9 - April 30, 2026 (4 weeks)

**Status:** Pending

**Goals:** App Store launch, soft launch marketing, establish user base

### Pre-Launch (Apr 1-8)

**Week Before Launch:**
```markdown
□ Final App Store submission
  - Review guidelines (privacy, permissions, etc.)
  - Submit v1.0 build
  - Prepare for potential rejections

□ Marketing prep
  - Create press kit (logo, screenshots, description)
  - Draft launch announcement
  - Identify launch day tactics (Twitter, Product Hunt, etc.)

□ Infrastructure setup
  - Configure analytics (PostHog/Mixpanel)
  - Set up monitoring (error tracking, performance)
  - Create dashboard for tracking metrics

□ Customer support prep
  - Create FAQ page
  - Set up support email
  - Create onboarding guides
```

### Week 1-2 (Apr 9-22): Soft Launch

**Focus:** Organic growth, monitor quality

```markdown
Week 1 (Apr 9-15): Monitor & Support
□ Daily metrics review (DAU, retention, conversion)
□ Respond to every review (thank positives, fix complaints)
□ Fix bugs reported by users
□ Track top 3 pain points
  Target: 500 total users

Week 2 (Apr 16-22): Growth Experiments
□ A/B test onboarding flow
□ Test different paywall positions
□ Experiment with referral incentives
□ Optimize App Store listing (keywords, description)
  Target: 15% conversion to premium
```

### Week 3-4 (Apr 23-30): Growth & Iteration

**Focus:** Feature iteration, retention improvement

```markdown
Week 3 (Apr 23-29): Feature Iteration
□ Build #1 most-requested feature
□ Improve #1 pain point identified
□ Performance optimization (if needed)
□ Update App Store with v1.1 build
  Target: 1,000 total users

Week 4 (Apr 24-30): Reflect & Plan
□ Analyze first month data
□ Plan Q2 roadmap based on user feedback
□ Decide: Double down on this idea or pivot?
□ Plan next major features for v1.2
```

### Success Metrics (by Apr 30)

**User Acquisition:**
- 1,000+ total downloads
- 200+ monthly active users (MAU)
- 100+ paying premium subscribers
- $250 monthly recurring revenue (MRR)

**Quality & Retention:**
- 4.5+ stars on App Store
- 30%+ Day-7 retention
- <1 crash per 1,000 sessions
- <100ms average load times

**Marketing & Visibility:**
- Featured in 1-2 publications/newsletters
- 5+ user testimonials collected
- 500+ Twitter impressions/day
- 10+ positive Reddit/HN mentions

### Growth Tactics

**Organic Growth:**
- App Store optimization (keywords, description, screenshots)
- Social media launch (Twitter, Product Hunt, Reddit)
- Friend referral program (free trial for referring)
- Community engagement (Discord, Twitter communities)

**Paid Growth (if budget available):**
- $200-500 Apple Search Ads budget
- Targeted to keywords: "calendar app", "group planning"
- Focus on high-intent keywords

**Partnerships:**
- Reach out to lifestyle/productivity bloggers
- Feature collaborations with similar apps
- Co-marketing with event planning communities

---

## RISK MITIGATION & TIMELINE BUFFER

### What Could Go Wrong

**Risk 1: Fall Behind Schedule**
- **Mitigation:** Build in 2-week buffer (launch Apr 30 vs Apr 15)
- **Plan B:** Cut nice-to-have features, ship core MVP
- **Fallback Features to Cut (in order):**
  1. Travel time notifications (move to v1.1)
  2. Potluck template (ship Surprise Birthday only)
  3. Smart time suggestions (move to v1.1)
  4. Premium features (launch as free, monetize later)

**Risk 2: Apple Rejects App**
- **Mitigation:** Study App Store guidelines carefully before submission
- **Plan B:** Fix issues quickly (typically resolved in 24-48 hours)
- **Common Issues:** Calendar permissions, privacy violations, unclear UX

**Risk 3: No One Uses It**
- **Mitigation:** Validate with 50+ beta testers before launch
- **Plan B:** Iterate based on feedback, pivot if needed
- **Pivot Options:**
  - Focus on workplace scheduling (vs friend groups)
  - Add calendar sync for other services (Google, Outlook)
  - Build B2B version for event planners

**Risk 4: Technical Blockers**
- **Mitigation:** Research thoroughly in Phase 0 (EventKit, Supabase, MapKit)
- **Plan B:** Ask for help (Stack Overflow, Reddit, Discord communities)
- **Critical Unknowns to Resolve in Phase 0:**
  - EventKit bidirectional sync reliability
  - Supabase Realtime WebSocket stability
  - APNs push notification delivery

**Risk 5: Burnout**
- **Mitigation:** Sustainable pace (3-4 hrs/day), take Sundays off if needed
- **Plan B:** Extend timeline if needed (better to finish than quit)
- **Signs to Watch:**
  - Missing more than 2 days/week
  - Code quality declining rapidly
  - Frustration with fundamental issues

### Checkpoint Decision Framework

If at ANY checkpoint you answer "no" to all items:

| Checkpoint | Date | Decision | Action |
|-----------|------|----------|--------|
| 1 | Jan 8 | Foundation working? | Extend Sprint 1 by 1 week |
| 2 | Jan 22 | Groups & privacy working? | Cut travel features from Sprint 4 |
| 3 | Feb 5 | Voting system working? | Cut one template (keep Surprise Birthday) |
| 4 | Feb 19 | Templates functional? | Ship with 1 template instead of 2 |
| 5 | Feb 26 | MVP usable & stable? | Delay beta by 1 week, iterate |

---

## SUCCESS METRICS BY PHASE

### Phase 0 (Dec 1-25) - Pre-Development
**Completion Criteria:**
- ✅ Market validation complete (10 interviews)
- ✅ Figma designs finalized
- ✅ Database schema approved
- ✅ GitHub repository set up with 100+ issues
- ✅ All developer accounts active
- ✅ Flutter/Dart fundamentals learned
- ✅ Day 1 checklist created and tested

### Phase 1 (Dec 26 - Feb 26) - MVP Development
**Sprint-by-Sprint Goals:**

**Sprint 1 (Jan 8):**
- ✅ MVP feature-complete (25 features)
- ✅ Zero critical bugs
- ✅ You use it daily for your own planning
- ✅ Usable personal calendar

**Sprint 2 (Jan 22):**
- ✅ Shadow calendar privacy working correctly
- ✅ Group availability heatmap functional
- ✅ Smart time suggestions algorithm tested

**Sprint 3 (Feb 5):**
- ✅ Real-time voting working
- ✅ Push notifications delivering
- ✅ Auto-event creation functional

**Sprint 4 (Feb 19):**
- ✅ Surprise Birthday template complete
- ✅ Potluck template complete
- ✅ Travel time notifications working

**Sprint 5 (Feb 26):**
- ✅ App polished and launch-ready
- ✅ Onboarding flow complete
- ✅ Demo video recorded
- ✅ App Store screenshots ready

### Phase 2 (Feb 27 - Apr 8) - Beta Testing
**Weekly Targets:**

| Week | Metric | Target |
|------|--------|--------|
| 1-2 | Beta testers | 50-100 |
| 2-3 | DAU | 30-50 |
| 3-4 | Day-7 retention | 35%+ |
| 4-5 | App rating | 4.0+ stars |
| 5-6 | Testimonials | 5+ |

**Final Checkpoint (Apr 8):**
- ✅ 100+ beta testers
- ✅ 50+ daily active users
- ✅ 40%+ Day-7 retention
- ✅ 4.0+ star rating
- ✅ Zero critical bugs

### Phase 3 (Apr 9-30) - Launch & Growth
**Week-by-Week Targets:**

| Metric | Week 1 | Week 2 | Week 3 | Week 4 | Final |
|--------|--------|--------|--------|--------|-------|
| Total downloads | 100 | 300 | 700 | 1,000 | 1,000+ |
| DAU | 30 | 60 | 100 | 150 | 200+ |
| Premium conversions | 2-3% | 5% | 10% | 15% | 100+ |
| MRR | $10 | $25 | $100 | $250 | $250+ |
| App rating | 4.2 | 4.3 | 4.4 | 4.5 | 4.5+ |

---

## DEVELOPMENT RESOURCES

### Solo Developer Pace

**Sustainable Schedule:**
- **Weekdays:** 3-4 hours/day focused development
- **Weekends:** 1-2 hours light work (code review, planning)
- **Off Days:** 1-2 days per week minimum
- **Total:** ~25-35 hours/week

**Why This Pace:**
- Allows for learning while building
- Minimizes burnout (6-month project)
- Leaves room for unexpected blockers
- Still achieves aggressive timeline

### Development Tools

**Local Development:**
- Android Studio (primary IDE for Flutter, free)
- VS Code with Flutter extension (alternative IDE, free)
- Xcode (for iOS builds on Mac, free)
- Flutter SDK and Dart pub (dependency management)
- Simulator (testing on Mac without device)
- Git & GitHub (version control)

**Backend Services:**
- Supabase (PostgreSQL + Auth + Realtime)
- Apple Push Notification service (APNs)
- Stripe (payment processing)
- MapKit (location & travel time)

**Productivity & Tracking:**
- GitHub Issues (task tracking)
- GitHub Project Board (sprint planning)
- Figma (design reference during development)
- Notion (personal notes & decisions)

**Testing & Monitoring:**
- TestFlight (beta distribution)
- Flutter test command (unit, widget & integration tests)
- PostHog or Mixpanel (analytics)
- Sentry or Bugsnag (crash reporting)

### Project Structure (MVVM)

```
CalendarApp/
├── App/
│   ├── CalendarApp.swift (entry point)
│   └── AppDelegate.swift
├── Core/
│   ├── Network/ (Supabase client)
│   ├── Storage/ (Local caching)
│   ├── EventKit/ (Calendar sync)
│   └── Notifications/ (Push handling)
├── Models/
│   ├── User.swift
│   ├── Group.swift
│   ├── Event.swift
│   ├── EventProposal.swift
│   └── Vote.swift
├── ViewModels/
│   ├── AuthViewModel.swift
│   ├── CalendarViewModel.swift
│   ├── GroupsViewModel.swift
│   └── ProposalViewModel.swift
├── Views/
│   ├── Auth/ (Login, Signup)
│   ├── Calendar/ (Month, week, day views)
│   ├── Groups/ (List, detail, manage)
│   ├── Proposals/ (Create, vote, inbox)
│   ├── Settings/ (Preferences, account)
│   └── Components/ (Reusable UI)
├── Utilities/
│   ├── Extensions/ (Dart utilities)
│   ├── Constants/ (Colors, fonts, etc.)
│   └── Logger/ (Debug logging)
└── Resources/
    ├── Assets.xcassets (images, colors)
    └── Localizable.strings (i18n)
```

### Development Commands

**Build & Run:**
```bash
# Build app
xcodebuild -scheme CalendarApp build

# Run tests
xcodebuild test -scheme CalendarApp

# Run on simulator
xcode-build -scheme CalendarApp -destination 'platform=iOS Simulator,name=iPhone 15'
```

**Code Quality:**
```bash
# Run Flutter analyzer
brew install swiftlint

# Run linting
swiftlint lint

# Auto-fix
swiftlint autocorrect
```

**Beta Distribution:**
```bash
# Build for TestFlight
xcodebuild -scheme CalendarApp -configuration Release archive

# Upload to TestFlight (iOS) and Google Play Internal Testing (Android)
fastlane beta
```

---

## COMMON PITFALLS TO AVOID

### EventKit Integration
- **DON'T:** Request calendar access immediately on launch
- **DON'T:** Sync all calendars (can be thousands of events)
- **DO:** Request during onboarding with clear explanation of value
- **DO:** Sync last 30 days + next 60 days, with pagination

### Privacy System
- **DON'T:** Show "who's busy" by default in group availability view
- **DON'T:** Let group members see event titles for "Busy-Only" events
- **DO:** Show aggregated counts (e.g., "6/8 free"), reveal names only on tap
- **DO:** Enforce visibility rules at database RLS level, not just app UI

### Real-Time Updates
- **DON'T:** Poll for vote updates every few seconds
- **DON'T:** Keep all WebSocket channels open simultaneously
- **DO:** Use Supabase Realtime WebSocket subscriptions
- **DO:** Subscribe only to active proposal screens, unsubscribe on navigation away

### Performance
- **DON'T:** Load all 50 groups and their calendars at app launch
- **DON'T:** Block UI on calendar sync
- **DO:** Lazy load groups, cache aggressively, background sync on app foreground
- **DO:** Show cached data immediately, sync in background with pull-to-refresh

### Testing & QA
- **DON'T:** Skip testing with real calendars (AppleCalendar is complex)
- **DON'T:** Test only on simulator (device testing essential)
- **DO:** Test on at least 2 physical iOS devices before beta
- **DO:** Set up automated tests for ViewModels early (save time later)

---

## TESTING STRATEGY

### Unit Tests (70% coverage target)
- ViewModels (business logic)
- Utilities and extensions
- Data models and transformations
- Availability calculation algorithm
- Voting scoring algorithm

### Integration Tests
- Supabase API calls (auth, CRUD, RLS)
- EventKit calendar sync (bidirectional)
- Offline queue processing
- Push notification handling

### UI Tests (Critical Flows)
- Event creation → Proposal → Voting → Confirmation
- Onboarding flow (sign up → create group → sync calendar)
- Privacy settings enforcement (shadow calendar accuracy)
- Real-time voting updates

### Device Testing
- iPhone 13 mini (minimum supported)
- iPhone 14 Pro (standard)
- iPhone 15 Pro Max (large screen)
- iPad (if time permits)

---

## FUTURE ROADMAP (Post-MVP)

### Phase 4: v1.1 - Smart Features (May-June 2026)
- Recurring availability patterns
- Additional event templates
- Calendar widgets (iOS 16+)
- Improved smart suggestions with ML

### Phase 5: Android & Expansion (Q3 2026)
- Android app launch
- Google Calendar integration
- Outlook integration
- Recurring event support

### Phase 6: Growth & Discovery (Q4 2026 - Q1 2026)
- Public event discovery
- Business-posted events
- Event sharing to friend groups
- Ticketing integration

### Long-Term Vision (2026+)
- Advanced event discovery
- Calendar AI assistant
- Business team coordination
- Calendar API for developers

---

## LAST UPDATED

**November 29, 2025** - Consolidated development roadmap including all phases, sprints, checkpoints, and success metrics.

---

## QUICK REFERENCE

### Key Dates at a Glance
- **Dec 25:** Mac Mini arrives → coding begins
- **Jan 8:** Foundation checkpoint
- **Jan 22:** Groups & privacy checkpoint
- **Feb 5:** Voting system checkpoint
- **Feb 19:** Special templates checkpoint
- **Feb 26:** MVP complete, beta starts
- **Apr 8:** Beta testing complete
- **Apr 30:** Launch target

### Decision Points
- **Checkpoint fails** → Follow fallback plan (cut features, extend timeline)
- **Behind on sprint** → Cut nice-to-have features from that sprint
- **Quality concerns** → Extend phase by 1 week, don't rush

### Success Criteria by Phase
- **Phase 0:** Learning complete, designs approved, ready to code
- **Phase 1:** MVP feature-complete, zero critical bugs, usable daily
- **Phase 2:** 100+ beta testers, 40%+ Day-7 retention, 4+ stars
- **Phase 3:** 1,000+ downloads, 200+ DAU, $250 MRR, 4.5+ stars

---

