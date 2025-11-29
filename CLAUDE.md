# CLAUDE.md/usafe
This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Specialized Agents Available

This project uses **specialized Claude subagents** for different aspects of development. Each agent has deep expertise in their domain:

- **🍎 iOS Developer** (`.claude/agents/ios-developer.md`) - Swift, SwiftUI, EventKit, MVVM
- **🗄️ Supabase Database** (`.claude/agents/supabase-database.md`) - PostgreSQL, RLS, real-time
- **⚙️ Systems Engineer** (`.claude/agents/systems-engineer.md`) - CI/CD, deployment, monitoring
- **🎯 Product Vision** (`.claude/agents/product-vision.md`) - Strategy, UX, feature prioritization
- **🤖 GitHub Automation** (`.claude/agents/github-automation.md`) - Sprint management, PR automation

**See `.claude/agents/README.md` for detailed usage instructions.**

## Project Overview

**Shareless: Everything Calendar** is an iOS calendar app for group event planning with privacy-first availability sharing. The core innovation is a "Shadow Calendar" system that lets users share their availability (when they're busy/free) without revealing private event details, combined with real-time group voting on event proposals.

**Target Launch:** April 30, 2025
**Development Status:** Pre-development (planning phase until Dec 25, 2024)
**Platform:** iOS-first (Swift/SwiftUI), targeting iOS 17+

### Core Value Proposition
Solve the "30 messages to plan one event" problem by showing real availability from calendars, enabling one-tap voting on time options, and auto-creating events when consensus is reached.

## Documentation Structure
This repository contains **planning documentation only** - no code yet. The actual iOS app will be developed in a separate repository starting December 25, 2025.

### Key Documentation Files

**Product & Vision:**
- `NotionMD/Project Overview.md` - Complete product vision, competitive analysis, business model
- `NotionMD/SharelessFeatures/Core Features.md` - MVP feature prioritization (Tier 1/2/3)
- `NotionMD/Monetization Strategy.md` - Freemium model ($4.99/mo premium)

**Technical Architecture:**
- `NotionMD/Technical Documentation/Architecture Overview.md` - High-level system design
- `NotionMD/Technical Documentation/Database Schema.md` - Complete PostgreSQL schema for Supabase
- `NotionMD/Technical Documentation/API Endpoints.md` - Supabase REST API design
- `NotionMD/Technical Documentation/EventKit Integration.md` - Apple Calendar sync approach

**Development Roadmap:**
- `NotionMD/DETAILED DEVELOPMENT TIMELINE & ROADMAP.md` - 6-month timeline overview
- `NotionMD/DETAILED DEVELOPMENT TIMELINE & ROADMAP/PHASE 1 MVP DEVELOPMENT.md` - Sprint-by-sprint breakdown
- `NotionMD/DETAILED DEVELOPMENT TIMELINE & ROADMAP/PHASE 2 BETA TESTING.md` - Sprint-by-sprint breakdown
- `NotionMD/DETAILED DEVELOPMENT TIMELINE & ROADMAP/PHASE 3 GROWTH & ITERATION.md` - Sprint-by-sprint breakdown

**UX Documentation:**
- `NotionMD/Complete UI Flows/` - 10 complete user flows (onboarding → settings)
- `NotionMD/Detailed Layouts/` - 10 screen-by-screen designs with interactions
- `NotionMD/Edge Cases/` - 12 comprehensive edge case scenarios
- `NotionMD/Design System.md` - Color palette, typography, component library

## Architecture Overview

### Technology Stack

**Frontend (iOS):**
- Swift 5.9+ with SwiftUI (MVVM pattern)
- Combine for reactive programming
- EventKit for Apple Calendar bidirectional sync
- Supabase Swift SDK for backend communication

**Backend (Supabase):**
- PostgreSQL 15 database (13 tables)
- Supabase Auth (JWT-based authentication)
- Supabase Realtime (WebSocket for live vote updates)
- Row Level Security (RLS) for privacy enforcement
- Supabase Edge Functions for serverless logic

**Third-Party Services:**
- APNs (Apple Push Notification Service)
- Stripe (payment processing for premium subscriptions)
- PostHog or Mixpanel (analytics)

### Core Data Models

**Privacy-First Event Model:**
```swift
enum EventVisibility {
    case private              // Hidden from all groups
    case sharedWithName       // Groups see event title & time
    case busyOnly             // Groups see "busy" block without details
}
```

**Key Tables (PostgreSQL):**
- `users` - Profiles, settings, subscription status
- `events` - Calendar events with privacy settings
- `groups` + `group_members` - Friend groups with role-based access
- `event_proposals` + `proposal_time_options` + `proposal_votes` - Voting system
- `calendar_sharing` - Per-group visibility controls
- `notifications` - In-app notification queue

### Critical Design Patterns

**1. Shadow Calendar System**
- Users set visibility per event: Private / Shared-With-Name / Busy-Only
- Groups only see aggregated availability heatmaps (e.g., "5/8 people free")
- Tapping a time slot reveals who's free (respecting individual privacy settings)
- Privacy enforced at database level via RLS policies

**2. Real-Time Voting**
- WebSocket subscriptions on proposal screens for live vote updates
- Optimistic UI updates (show vote immediately, rollback on error)
- Vote counts update in real-time for all group members
- Auto-event creation when voting deadline passes or organizer confirms

**3. EventKit Bidirectional Sync**
- Background sync every 15 minutes
- Store `apple_calendar_id` in events table for two-way sync
- Conflict resolution: Last write wins (with user notification)
- Offline queue for changes made while disconnected

## MVP Feature Scope

### TIER 1 (Must-Have):
1. Personal calendar with Apple Calendar sync
2. Shadow Calendar privacy system (Private/Shared/Busy-Only)
3. Friend system + group creation
4. Group availability heatmap
5. Event proposals with real-time voting
6. Push notifications (new proposals, votes, confirmations)

### TIER 2 (Strong Differentiators - Include if time permits):
7. Smart time suggestions ("Find best times" algorithm)
8. Event locations with travel time calculation
9. Surprise Birthday Party template (hidden event with decoy)
10. Potluck/Friendsgiving template (dish signup coordination)

### Explicitly NOT in MVP:
- Android app
- Google Calendar / Outlook integration
- Recurring availability patterns
- Event templates beyond surprise party/potluck
- Team/work features
- Calendar widgets

## Development Timeline

**Phase 0: Pre-Mac Preparation (Dec 1-25, 2024)**
- Learning Swift/SwiftUI (100 Days of SwiftUI course)
- Finalizing designs in Figma
- No coding until Mac Mini arrives Dec 25

**Phase 1: MVP Development (Dec 26 - Feb 26, 2025) - 9 weeks**
- Sprint 1: Authentication, project setup, calendar view skeleton
- Sprint 2: Groups, friends, privacy settings
- Sprint 3: Event proposals and voting core functionality
- Sprint 4: Special templates (Surprise Party, Potluck) + travel features
- Sprint 5: Polish, notifications, offline support

**Phase 2: Beta Testing (Feb 27 - Apr 8, 2025) - 6 weeks**
- TestFlight with 100+ beta testers
- Iteration based on feedback
- Bug fixes and UX polish

**Phase 3: Launch (Apr 9-30, 2025) - 4 weeks**
- App Store submission
- Soft launch with marketing push
- Target: 500+ downloads, 200+ active users in Month 1

## Key Design Principles

1. **Native Feel** - Follows Apple HIG, uses SF Pro font, system colors, feels like built by Apple
2. **Minimal & Focused** - One primary action per screen, progressive disclosure
3. **Delightful Details** - Spring physics animations, haptic feedback, confetti on event confirmations
4. **Privacy-First** - Granular controls, opt-in sharing, RLS enforcement at DB level
5. **Fast & Responsive** - Optimistic UI, aggressive caching, offline queue, <100ms interactions

## Common Pitfalls to Avoid

### EventKit Integration
- **Don't**: Request calendar access immediately on launch
- **Don't**: Sync all calendars (can be thousands of events)
- **Do**: Request during onboarding with clear explanation of value
- **Do**: Sync last 30 days + next 60 days, with pagination

### Privacy System
- **Don't**: Show "who's busy" by default in group availability view
- **Don't**: Let group members see event titles for "Busy-Only" events
- **Do**: Show aggregated counts (e.g., "6/8 free"), reveal names only on tap
- **Do**: Enforce visibility rules at database RLS level, not just app UI

### Real-Time Updates
- **Don't**: Poll for vote updates every few seconds
- **Don't**: Keep all WebSocket channels open simultaneously
- **Do**: Use Supabase Realtime WebSocket subscriptions
- **Do**: Subscribe only to active proposal screens, unsubscribe on navigation away

### Performance
- **Don't**: Load all 50 groups and their calendars at app launch
- **Don't**: Block UI on calendar sync
- **Do**: Lazy load groups, cache aggressively, background sync on app foreground
- **Do**: Show cached data immediately, sync in background with pull-to-refresh

## Testing Strategy

**Unit Tests (70% coverage target):**
- ViewModels (business logic)
- Utilities and extensions
- Data models and transformations

**Integration Tests:**
- Supabase API calls
- EventKit calendar sync
- Offline queue processing

**UI Tests:**
- Critical user flows: Event creation → Proposal → Voting → Confirmation
- Onboarding flow
- Privacy settings enforcement

## Future Context

When the actual codebase is created (starting Dec 25, 2024):

**Expected Project Structure (MVVM):**
```
CalendarApp/
├── App/ (entry point, AppDelegate)
├── Core/ (Network, Storage, EventKit, Notifications)
├── Models/ (User, Group, Event, EventProposal, Vote)
├── ViewModels/ (Auth, Calendar, Groups, Inbox)
├── Views/ (Auth, Calendar, Groups, Inbox, Profile, Components)
├── Utilities/ (Extensions, Constants, Logger)
└── Resources/ (Assets, Localizable.strings)
```

**Development Commands (when code exists):**
- Build: Xcode GUI or `xcodebuild -scheme CalendarApp build`
- Tests: Xcode Test Navigator or `xcodebuild test -scheme CalendarApp`
- Lint: SwiftLint (`.swiftlint.yml` config to be added)
- TestFlight: Fastlane automation (`fastlane beta`)

## Important Notes

- **No Code Yet**: This repository contains only planning/design docs. Code development starts Dec 25, 2024.
- **Solo Developer**: Built by one person with learning curve factored in (3-4 hours/day pace)
- **Documentation First**: All major decisions documented before coding begins
- **Agile with Buffer**: 2-week sprints with built-in timeline buffer for unknowns
- **User Validation Required**: Beta testing with 100+ users before public launch to validate assumptions

---

*Last updated: November 29, 2024*
