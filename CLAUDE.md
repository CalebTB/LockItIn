# CLAUDE.md/usafe
This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Specialized Agents Available

This project uses **specialized Claude subagents** for different aspects of development. Each agent has deep expertise in their domain (9 agents total):

- **📱 Flutter Architect** (`.claude/agents/flutter-architect.md`) - Flutter/Dart, cross-platform mobile (iOS & Android), state management, native platform integration
- **🎨 Mobile UX Designer** (`.claude/agents/mobile-ux-designer.md`) - iOS & Android UI/UX design, HIG + Material Design, interaction patterns, adaptive design
- **🔗 Supabase Mobile Integration** (`.claude/agents/supabase-mobile-integration.md`) - Supabase Flutter SDK, auth, RLS, real-time for iOS & Android
- **🔄 Dev Sync Coordinator** (`.claude/agents/dev-sync-coordinator.md`) - Frontend-Backend alignment verification
- **💎 Feature Values Advisor** (`.claude/agents/feature-values-advisor.md`) - Privacy-first principles, value alignment
- **📊 Feature Analyzer** (`.claude/agents/feature-analyzer.md`) - Feature analysis and market research
- **🎯 Feature Orchestrator** (`.claude/agents/feature-orchestrator.md`) - Feature lifecycle, roadmap, market research
- **🤖 GitHub Workflow Manager** (`.claude/agents/github-workflow-manager.md`) - Issues, PRs, sprint planning

**See `.claude/agents/README.md` for detailed usage instructions.**

## Project Overview

**Shareless: Everything Calendar** (LockItIn) is a cross-platform mobile app for group event planning with privacy-first availability sharing. The core innovation is a "Shadow Calendar" system that lets users share their availability (when they're busy/free) without revealing private event details, combined with real-time group voting on event proposals.

**Target Launch:** April 30, 2026
**Development Status:** Pre-development (planning phase until Dec 25, 2025)
**Platform:** Cross-platform (Flutter for iOS & Android), targeting iOS 13+ and Android 8.0+

### Core Value Proposition
Solve the "30 messages to plan one event" problem by showing real availability from calendars, enabling one-tap voting on time options, and auto-creating events when consensus is reached.

## Documentation Structure
This repository contains **planning documentation only** - no code yet. The actual Flutter app will be developed in a separate repository starting December 25, 2025.

### Master Documentation Index

**START HERE:** Read `lockitin-documentation-index.md` for a complete navigation guide to all 13 lockitin files, 2 remaining NotionMD design resources, and how to find information by role or topic.

### Core Documentation Files (13 Files)

**Product & Strategy (3 files):**
- `lockitin-product-vision.md` - Complete product vision, target personas, competitive analysis, market positioning, long-term strategy
- `lockitin-features.md` - Complete feature roadmap with Tier 1/2/3 prioritization and implementation details
- `lockitin-business.md` - Freemium monetization model, B2B expansion, virality mechanics, growth metrics

**Technical Architecture (3 files):**
- `lockitin-technical-architecture.md` - Backend & systems architecture, database schema (13 tables), API endpoints, EventKit integration, code examples
- `lockitin-privacy-security.md` - Shadow Calendar system, RLS policies with SQL, authentication, user controls, compliance (GDPR/CCPA/COPPA)
- `lockitin-notifications.md` - APNs integration, 12+ notification types, delivery strategy, inbox architecture, user preferences

**Design & UX (5 files):**
- `lockitin-designs.md` - Design system, principles, color palette, typography, spacing, animations, accessibility
- `lockitin-ui-design.md` - Complete UI specifications, component library, dark mode, icons, animations
- `lockitin-complete-user-flows.md` - 10 complete user journeys (onboarding → settings, voting, etc.) with step-by-step flows
- `lockitin-onboarding.md` - Onboarding strategy, permission flows, tutorial, empty states, progressive disclosure
- `lockitin-edge-cases.md` - 12 edge case categories, error scenarios, resolution strategies

**Development Process (2 files):**
- `lockitin-roadmap-development.md` - 6-month timeline with sprint breakdowns across all phases
- `lockitin-beta-testing.md` - Testing phases, recruitment strategy, feedback collection, metrics, launch readiness

### Technology Stack

**Frontend (Cross-Platform Mobile):**
- Flutter 3.16+ with Dart 3.0+ (clean architecture pattern)
- Provider or Riverpod for state management
- Platform channels for native calendar access:
  - iOS: EventKit for Apple Calendar bidirectional sync
  - Android: CalendarContract for Google Calendar / device calendar sync
- Supabase Flutter SDK for backend communication
- Material Design (Android) and Cupertino widgets (iOS) for platform-native feel

**Backend (Supabase):**
- PostgreSQL 15 database (13 tables)
- Supabase Auth (JWT-based authentication)
- Supabase Realtime (WebSocket for live vote updates)
- Row Level Security (RLS) for privacy enforcement
- Supabase Edge Functions for serverless logic

**Third-Party Services:**
- Push Notifications (Firebase Cloud Messaging for Android, APNs for iOS)
- Stripe (payment processing for premium subscriptions)
- PostHog or Mixpanel (analytics)

### Core Data Models

**Privacy-First Event Model:**
```dart
enum EventVisibility {
  private,           // Hidden from all groups
  sharedWithName,    // Groups see event title & time
  busyOnly,          // Groups see "busy" block without details
}
```

**Key Tables (PostgreSQL):**
- `users` - Profiles, settings, subscription status
- `events` - Calendar events with privacy settings (source of truth)
- `shadow_calendar` - Synced availability blocks for group queries (non-private events only)
- `groups` + `group_members` - Friend groups with role-based access
- `event_proposals` + `proposal_time_options` + `proposal_votes` - Voting system
- `calendar_sharing` - Per-group visibility controls
- `notifications` - In-app notification queue

### Critical Design Patterns

**1. Shadow Calendar System (Dual-Table Architecture)**

Users set visibility per event: Private / Shared-With-Name / Busy-Only. Privacy is enforced at the database level through a dual-table architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                      EVENTS TABLE                            │
│  Stores ALL events (private, busyOnly, sharedWithName)      │
│                                                              │
│  RLS Policy: Users can ONLY see their own events            │
│  Used by: Personal calendar view                            │
└─────────────────────────────────────────────────────────────┘
                           │
                           │ Trigger syncs non-private only
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                  SHADOW_CALENDAR TABLE                       │
│  Stores ONLY busyOnly + sharedWithName events               │
│  (Private events NEVER exist here)                          │
│                                                              │
│  RLS Policy: Group members can see each other's entries     │
│  Used by: Group availability heatmap, day detail views      │
└─────────────────────────────────────────────────────────────┘
```

**How events flow:**
- **Private event** → `events` table only (your eyes only)
- **BusyOnly event** → `events` + `shadow_calendar` (title stored as NULL)
- **SharedWithName event** → `events` + `shadow_calendar` (title visible)

**Privacy guarantees:**
- Private events physically don't exist in `shadow_calendar` - impossible to leak
- BusyOnly events show as time blocks without titles in group views
- SharedWithName events show titles to group members
- Groups see aggregated availability heatmaps (e.g., "5/8 people free")
- Tapping a time slot reveals who's free (respecting individual privacy settings)

**Database objects:**
- `shadow_calendar` table with RLS policies
- `sync_event_to_shadow_calendar()` trigger function
- `get_group_shadow_calendar()` RPC function for efficient queries

**2. Real-Time Voting**
- WebSocket subscriptions on proposal screens for live vote updates
- Optimistic UI updates (show vote immediately, rollback on error)
- Vote counts update in real-time for all group members
- Auto-event creation when voting deadline passes or organizer confirms

**3. Native Calendar Bidirectional Sync**
- Background sync every 15 minutes
- Platform-specific integration:
  - iOS: EventKit for Apple Calendar
  - Android: CalendarContract for Google Calendar / device calendars
- Store `native_calendar_id` in events table for two-way sync
- Conflict resolution: Last write wins (with user notification)
- Offline queue for changes made while disconnected

## MVP Feature Scope

### TIER 1 (Must-Have):
1. Personal calendar with native calendar sync (Apple Calendar on iOS, Google Calendar on Android)
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

### Explicitly NOT in MVP (Planned for Later Phases):

**Year 1 (Post-MVP):**
- Outlook / Office 365 calendar integration
- Recurring availability patterns
- Additional event templates
- Home screen widgets (iOS and Android)

**Year 2+ (Growth Phase - Public/Business Events):**
- Public event discovery (concerts, shows, restaurants)
- Business-posted events (venues can post events)
- Event sharing to friend groups (vote on which public event to attend)
- Ticketing integration
- Advanced event discovery features

**Why Cross-Platform is Essential:**
- Friend groups are mixed (iPhone + Android users)
- Network effects require ALL members can participate
- iOS-only = broken coordination when one person can't access the app
- Cross-platform maximizes addressable market and virality

**Why Friend Groups First:**
- Simpler use case, faster validation
- Network effects work better with private groups
- Privacy controls are core differentiator
- Less competition than public events space
- Easier to build trust and community

**Future Vision:** Validate product-market fit with friend coordination, then expand to let businesses post events that friends can discover and coordinate attendance on together.

## Development Timeline

**Phase 0: Pre-Mac Preparation (Dec 1-25, 2025)**
- Learning Flutter/Dart (Flutter & Dart - The Complete Guide, official Flutter docs)
- Finalizing designs in Figma (both iOS and Android adaptive designs)
- Setting up development environment (Flutter SDK, Android Studio, Xcode)
- No coding until Mac Mini arrives Dec 25 (needed for iOS builds)

**Phase 1: MVP Development (Dec 26 - Feb 26, 2026) - 9 weeks**
- Sprint 1: Authentication, project setup, calendar view skeleton
- Sprint 2: Groups, friends, privacy settings
- Sprint 3: Event proposals and voting core functionality
- Sprint 4: Special templates (Surprise Party, Potluck) + travel features
- Sprint 5: Polish, notifications, offline support

**Phase 2: Beta Testing (Feb 27 - Apr 8, 2026) - 6 weeks**
- TestFlight (iOS) and Google Play Internal Testing (Android) with 100+ beta testers
- Iteration based on feedback
- Bug fixes and UX polish
- Test on wide variety of devices (iOS and Android)

**Phase 3: Launch (Apr 9-30, 2026) - 4 weeks**
- App Store (iOS) and Google Play Store (Android) submission
- Soft launch with marketing push
- Target: 500+ downloads, 200+ active users in Month 1 across both platforms

## Key Design Principles

1. **Platform-Native Feel** - Follows Apple HIG on iOS (Cupertino widgets, SF Pro) and Material Design on Android (Material widgets, Roboto), uses system colors, feels native to each platform
2. **Minimal & Focused** - One primary action per screen, progressive disclosure
3. **Delightful Details** - Platform-appropriate animations (spring physics on iOS, Material motion on Android), haptic feedback, confetti on event confirmations
4. **Privacy-First** - Granular controls, opt-in sharing, RLS enforcement at DB level
5. **Fast & Responsive** - Optimistic UI, aggressive caching, offline queue, <100ms interactions

## App Theme System (Minimal Theme)

The app uses a **centralized theme-based color system** based on the Minimal theme specification (`LOCKIT_MINIMAL_THEME.md`). All colors are managed through Flutter's `ColorScheme` and custom `ThemeExtension`.

### Theme Files
- `lib/core/theme/app_colors.dart` - Color definitions, ColorScheme, and ThemeExtension
- `lib/core/theme/app_theme.dart` - ThemeData configuration for light/dark modes

### Color Palette

**Primary Accent:** Rose (`#F43F5E`) to Orange (`#F97316`) gradient
**Foundation:** Neutral grays (dark mode) / Gray scale (light mode)

| Role | Dark Mode | Light Mode |
|------|-----------|------------|
| Background | Black / Neutral-950 | White / Gray-100 |
| Surface | Neutral-900 | White |
| Card | Neutral-900 | White |
| Border | Neutral-800 | Gray-200 |
| Primary Text | White | Gray-900 |
| Secondary Text | Neutral-300 | Gray-700 |
| Muted Text | Neutral-500 | Gray-500 |

### Using Theme Colors in Widgets

**ALWAYS use theme-based colors. NEVER use hardcoded hex values.**

```dart
@override
Widget build(BuildContext context) {
  // Standard ColorScheme colors
  final colorScheme = Theme.of(context).colorScheme;

  // Custom app colors (text hierarchy, semantic colors, card styling)
  final appColors = context.appColors;

  return Container(
    color: colorScheme.surface,           // Use for backgrounds
    child: Text(
      'Hello',
      style: TextStyle(
        color: colorScheme.onSurface,     // Primary text
      ),
    ),
  );
}
```

### ColorScheme Properties (Standard Material 3)

| Property | Usage |
|----------|-------|
| `colorScheme.primary` | Primary accent (rose-500) |
| `colorScheme.secondary` | Secondary accent (orange-500) |
| `colorScheme.surface` | Page/card backgrounds |
| `colorScheme.onSurface` | Primary text on surface |
| `colorScheme.surfaceContainer` | Elevated surfaces |
| `colorScheme.surfaceContainerHigh` | Higher elevation surfaces |
| `colorScheme.outline` | Borders |
| `colorScheme.error` | Error states |

### AppColorsExtension Properties (Custom)

Access via `context.appColors`:

| Property | Usage |
|----------|-------|
| `appColors.textSecondary` | Secondary text (slightly muted) |
| `appColors.textTertiary` | Tertiary text |
| `appColors.textMuted` | Muted/placeholder text |
| `appColors.textDisabled` | Disabled state text |
| `appColors.success` | Success color (emerald) |
| `appColors.successBackground` | Success background |
| `appColors.warning` | Warning color (amber) |
| `appColors.warningBackground` | Warning background |
| `appColors.cardBackground` | Card backgrounds |
| `appColors.cardBorder` | Card borders |
| `appColors.divider` | Divider lines |

### Category Colors

For event categories and member colors, use `AppColors` static constants:

```dart
import '../../core/theme/app_colors.dart';

// Event categories
AppColors.categoryWork     // Teal
AppColors.categoryHoliday  // Orange (secondary)
AppColors.categoryFriend   // Violet
AppColors.categoryOther    // Rose (primary)

// Member colors (for avatars, group members)
AppColors.memberPink
AppColors.memberAmber
AppColors.memberViolet
AppColors.memberCyan
AppColors.memberEmerald
AppColors.memberTeal
```

### Common Patterns

**Card with border:**
```dart
Container(
  decoration: BoxDecoration(
    color: appColors.cardBackground,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: appColors.cardBorder),
  ),
)
```

**Primary button:**
```dart
Container(
  decoration: BoxDecoration(
    color: colorScheme.primary,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Text('Button', style: TextStyle(color: colorScheme.onPrimary)),
)
```

**Empty state:**
```dart
Icon(Icons.event_busy, color: appColors.textDisabled)
Text('No events', style: TextStyle(color: appColors.textMuted))
```

### Pitfalls to Avoid

- **Don't** use hardcoded colors like `Color(0xFFF43F5E)` - use `colorScheme.primary`
- **Don't** use gradients for backgrounds (Minimal theme uses solid colors)
- **Don't** create new color constants in widgets - add them to `AppColors` or `AppColorsExtension`
- **Do** use `colorScheme.onSurface` for text on `colorScheme.surface` backgrounds
- **Do** use `withValues(alpha: 0.x)` instead of `withOpacity()` for color transparency

## Common Pitfalls to Avoid

### Native Calendar Integration
- **Don't**: Request calendar access immediately on launch
- **Don't**: Sync all calendars (can be thousands of events)
- **Do**: Request during onboarding with clear explanation of value
- **Do**: Sync last 30 days + next 60 days, with pagination
- **Do**: Handle platform-specific permissions (iOS EventKit, Android Calendar permissions)

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

### Supabase RLS Policies

**Common Issue: INSERT with .select() fails due to SELECT policy**

When using `.insert(...).select().single()` in Supabase (which returns the created row), you need BOTH:
1. An INSERT policy that allows the insert
2. A SELECT policy that allows reading the newly created row

**Problem scenario (Groups table):**
```dart
// This requires INSERT + SELECT permissions
await supabase.from('groups').insert({...}).select().single();
```

If your SELECT policy is:
```sql
-- User must be a member to see the group
USING (auth_is_group_member(id, auth.uid()))
```

This FAILS because the user isn't a member yet - the member record is created AFTER the group!

**Solution:** Add creator exception to SELECT policy:
```sql
CREATE POLICY "Users can view groups they belong to"
ON groups FOR SELECT TO authenticated
USING (
  auth_is_group_member(id, auth.uid())
  OR created_by = auth.uid()  -- Allow creator to see their group
);
```

**Other RLS Tips:**
- Always add `TO authenticated` to policies targeting logged-in users
- Use `SECURITY DEFINER` functions to bypass RLS when checking membership (prevents infinite recursion)
- Test with `SELECT auth.uid()` via RPC to verify JWT is working
- If RLS fails mysteriously, try `ALTER TABLE x DISABLE ROW LEVEL SECURITY` to confirm RLS is the issue
- Migration scripts: `supabase/fix_groups_rls.sql` contains the corrected policies

## Testing Strategy

**Unit Tests (70% coverage target):**
- Providers/Business logic layer
- Utilities and extensions
- Data models and transformations

**Integration Tests:**
- Supabase API calls
- Native calendar sync (EventKit on iOS, CalendarContract on Android)
- Offline queue processing
- Platform channel communication

**Widget Tests:**
- Critical user flows: Event creation → Proposal → Voting → Confirmation
- Onboarding flow
- Privacy settings enforcement
- Both Material (Android) and Cupertino (iOS) widget variants

## Pre-Launch Checklist

Manual steps required before going live (not automated in migrations):

### Supabase Dashboard Settings
- [ ] **Enable Leaked Password Protection** - Auth → Settings → Password Security
  - Checks passwords against HaveIBeenPwned.org database
  - Prevents users from using compromised passwords
  - Issue identified: December 30, 2025 via Database Advisor

### Database Migrations Applied (Sprint 2)
- [x] `008_fix_function_search_path.sql` - Security: Fixed 19 functions with `SET search_path = public`
- [x] `009_optimize_rls_auth_uid.sql` - Performance: Optimized 24 RLS policies with `(select auth.uid())`
- [x] `010_cleanup_duplicate_indexes.sql` - Performance: Removed duplicate indexes on events table
- [x] `011_add_missing_fk_index.sql` - Performance: Added index for `group_invites.invited_by` FK

### App Store / Play Store
- [ ] Privacy Policy URL
- [ ] Terms of Service URL
- [ ] App Store screenshots (6.5" and 5.5" for iOS)
- [ ] Play Store screenshots and feature graphic
- [ ] Age rating questionnaire completed

## Future Context

When the actual codebase is created (starting Dec 25, 2025):

**Expected Project Structure (Clean Architecture):**
```
lockitin_app/
├── lib/
│   ├── main.dart
│   ├── core/ (Network, Storage, Platform Channels, Constants)
│   ├── data/ (Models, Repositories, Data Sources)
│   ├── domain/ (Use Cases, Entities, Repository Interfaces)
│   ├── presentation/
│   │   ├── providers/ (State Management)
│   │   ├── screens/ (Auth, Calendar, Groups, Inbox, Profile)
│   │   └── widgets/ (Reusable Components)
│   └── utils/ (Extensions, Helpers, Logger)
├── ios/ (iOS-specific native code, platform channels)
├── android/ (Android-specific native code, platform channels)
├── assets/ (Images, Fonts, Localizations)
└── test/ (Unit, Widget, Integration tests)
```

**Development Commands (when code exists):**
- Run: `flutter run` (iOS/Android)
- Build iOS: `flutter build ios` or `flutter build ipa`
- Build Android: `flutter build apk` or `flutter build appbundle`
- Tests: `flutter test`
- Lint: `flutter analyze` (analysis_options.yaml config)
- iOS TestFlight: `flutter build ipa && Fastlane`
- Android Internal Testing: `flutter build appbundle` + Google Play Console

## Git Workflow & Version Control

### ⚠️ CRITICAL: Branch-First Workflow

**BEFORE making ANY code changes, ALWAYS create a branch first:**
```bash
git checkout -b [type]/[issue-number]-[short-description]
```

**Rules:**
1. **NEVER commit directly to main** - Always work on a feature/fix/refactor branch
2. **NEVER push to main** - All changes go through Pull Requests
3. **Create branch BEFORE editing files** - Not after you've already made changes

If you accidentally made changes on main:
```bash
# Stash changes, create branch, apply changes
git stash
git checkout -b fix/123-description
git stash pop
```

**Reference:** See `lockitin_docs/versioning-and-issue-categories.md` for complete details.

### Versioning (SemVer)
Use **MAJOR.MINOR.PATCH** format: `v1.2.3`

| Version | Content |
|---------|---------|
| v0.1.0 | Sprint 1 complete (Auth + Calendar) |
| v0.2.0 | Sprint 2 complete (Groups + Shadow Calendar) |
| v0.3.0 | Sprint 3 complete (Proposals + Voting) |
| v0.4.0 | Sprint 4 complete (Templates + Travel) |
| v0.5.0-beta.1 | MVP complete, first beta |
| v1.0.0 | Public Launch |

### Branch Naming Convention
**Format:** `[type]/[issue-number]-[short-description]`

| Type | Use For |
|------|---------|
| `feature/` | New features |
| `fix/` | Bug fixes |
| `refactor/` | Code improvements |
| `docs/` | Documentation |
| `chore/` | Maintenance |

**Examples:**
```bash
feature/20-group-detail-view
fix/99-calendar-sync-crash
refactor/100-group-service-cleanup
```

### Issue Naming Convention
**Format:** `[version] - [Category]: [Title]`

**Categories:** Auth, Calendar, Groups, Proposals, Notifications, Templates, Location, Premium, UI, Backend, Settings, Testing, Launch

**Examples:**
```
v0.2.0 - Groups: Detail View
v0.3.0 - Proposals: Voting API Backend
v1.0.1 - Bug: Calendar sync fails on iOS 17
```

### Commit Message Convention
**Format:** `type(scope): description`

| Type | Use For |
|------|---------|
| `feat:` | New feature |
| `fix:` | Bug fix |
| `docs:` | Documentation |
| `style:` | Formatting (no code change) |
| `refactor:` | Code refactoring |
| `test:` | Adding tests |
| `chore:` | Maintenance |

**Examples:**
```
feat(groups): add pull-to-refresh for groups list
fix(calendar): resolve sync crash on iOS 17
refactor(auth): simplify session management logic
```

### Quick Reference Commands
```bash
# Create branch for issue
git checkout -b feature/20-group-detail-view

# Create issue with labels
gh issue create \
  --title "v0.2.0 - Groups: Detail View" \
  --label "type: feature" \
  --label "area: groups" \
  --label "priority: high" \
  --label "sprint: 2"

# Create PR
gh pr create \
  --title "v0.2.0 - Groups: Detail View" \
  --body "Closes #20"
```

## Important Notes

- **Solo Developer**: Built by one person with learning curve factored in (3-4 hours/day pace)
- **Documentation First**: All major decisions documented before coding begins
- **Agile with Buffer**: 2-week sprints with built-in timeline buffer for unknowns
- **User Validation Required**: Beta testing with 100+ users before public launch to validate assumptions

---

*Last updated: December 30, 2025 - Added App Theme System documentation (Minimal theme), branch-first workflow, pre-launch checklist, Sprint 2 migrations*
