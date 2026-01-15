# Simplify RSVP Implementation & Remove Code Duplication

## Overview

Refactor the RSVP implementation to remove over-engineering, eliminate code duplication (~460 lines), and align with existing project architecture patterns. Focus on simplification and maintainability.

## Problem Statement

The RSVP feature works but has significant technical debt:

1. **Code Duplication (Critical)**: ~460 lines of duplicate code across 10+ files
   - Status icon/color mapping duplicated 4 times
   - User role checking duplicated 4 times
   - Avatar rendering duplicated 3 times
   - Invitation fetching logic duplicated 3 times

2. **Over-Engineering (High)**: Features that don't add value
   - Real-time update batching (100ms debouncing) for 5-30 person groups
   - Redundant composite database index (unique constraint already indexes)
   - Unused `updated_at` trigger (never queried)
   - Redundant UI-level security checks (already enforced by RLS)

3. **Architecture Violations (High)**: Inconsistent with project patterns
   - Direct Supabase calls in widgets (bypasses Provider/Service pattern)
   - No `RSVPProvider` (other features use CalendarProvider, GroupProvider, etc.)
   - Business logic in UI layer (800+ line widget files)

4. **Type Safety Issues (Medium)**: String literals instead of enums
   - Using `'accepted'` strings instead of `RSVPStatus` enum
   - Prone to typos and refactoring errors

## Proposed Solution

### Phase 1: Remove Over-Engineering (Quick Wins)

**Goal:** Simplify database and reduce unnecessary complexity

**Files:**
- `supabase/migrations/020_create_event_invitations_table.sql`
- `lib/presentation/screens/surprise_party_dashboard_screen.dart`

**Changes:**

1. **Database Simplification** (020_create_event_invitations_table.sql)
   - [ ] Remove redundant composite index (lines 31-34)
   - [ ] Remove unused `updated_at` trigger (lines 21-25)
   - [ ] Consolidate duplicate RLS guest-of-honor checks into helper function
   - [ ] Remove or deprecate duplicate migration 017

2. **Remove Real-Time Batching** (surprise_party_dashboard_screen.dart)
   - [ ] Delete `_updateDebounce` and `_batchedUpdates` state variables (lines 43-44)
   - [ ] Simplify `_handleRSVPUpdate()` to call `setState` directly (lines 106-129)
   - [ ] Remove `_applyBatchedUpdates()` method (lines 117-130)

3. **Remove Redundant Security Checks** (surprise_party_dashboard_screen.dart)
   - [ ] Delete duplicate guest-of-honor checks in UI (lines 570-580)
   - [ ] Rely on RLS policies + initial access control

**Impact:** -87 lines, simpler state management, faster writes

---

### Phase 2: Extract Duplicate Code to Utilities

**Goal:** Create reusable utilities to eliminate 460+ lines of duplication

**New Files:**
- `lib/core/utils/rsvp_status_utils.dart`
- `lib/core/utils/surprise_party_utils.dart`
- `lib/presentation/widgets/common/status_avatar.dart`

**Changes:**

1. **Create RSVPStatusUtils** (NEW: lib/core/utils/rsvp_status_utils.dart)
   ```dart
   class RSVPStatusUtils {
     static IconData getIcon(String status) { /* ... */ }
     static Color getColor(String status, ColorScheme cs, AppColorsExtension ac) { /* ... */ }
     static String getLabel(String status) { /* ... */ }
     static String getButtonLabel(String status) { /* ... */ }
   }
   ```
   - [ ] Implement utility class with static methods
   - [ ] Handle all 4 RSVP statuses: accepted, maybe, declined, pending

2. **Extract User Role Logic** (NEW: lib/core/utils/surprise_party_utils.dart)
   ```dart
   extension SurprisePartyEventExtension on EventModel {
     String getUserRole(String? currentUserId) { /* ... */ }
     String getDisplayTitle(String? currentUserId) { /* ... */ }
   }
   ```
   - [ ] Move role detection to EventModel extension
   - [ ] Returns: 'target', 'coordinator', 'member', 'neither'

3. **Create Reusable Avatar Widget** (NEW: lib/presentation/widgets/common/status_avatar.dart)
   ```dart
   class StatusAvatar extends StatelessWidget {
     final String userId;
     final String displayName;
     final String? avatarUrl;
     final String? statusBadge;
     final double radius;
   }
   ```
   - [ ] Consolidate avatar + status badge rendering
   - [ ] Use MemberUtils for colors/initials
   - [ ] Handle optional status badge overlay

4. **Refactor Existing Files to Use Utilities**
   - [ ] `lib/presentation/screens/surprise_party_dashboard_screen.dart`
     - Replace `_getStatusColor()`, `_getStatusIcon()` with `RSVPStatusUtils` (lines 786-814)
     - Replace `_getUserRole()` with extension method (lines 200-316)
     - Replace `_buildMemberAvatar()` with `StatusAvatar` widget (lines 738-784)

   - [ ] `lib/presentation/screens/event_detail_screen.dart`
     - Replace `_getRsvpIcon()`, `_getRsvpColor()`, `_getRsvpButtonLabel()` with `RSVPStatusUtils` (lines 728-767)
     - Replace `_getUserRole()` with extension method (lines 689-708)

   - [ ] `lib/presentation/widgets/agenda_event_card.dart`
     - Replace `_getUserRole()` with extension method (lines 294-311)

   - [ ] `lib/presentation/widgets/upcoming_event_card.dart`
     - Replace `_getUserRole()` with extension method (lines 369-386)

**Impact:** -~400 lines of duplication, centralized maintenance

---

### Phase 3: Align with Project Architecture

**Goal:** Follow existing Provider/Service pattern (like ProposalProvider, GroupProvider)

**New Files:**
- `lib/core/services/rsvp_service.dart`
- `lib/presentation/providers/rsvp_provider.dart`

**Changes:**

1. **Create RSVPService** (NEW: lib/core/services/rsvp_service.dart)
   ```dart
   class RSVPService {
     Future<List<Map<String, dynamic>>> getEventInvitations(String eventId);
     Future<String?> getUserRsvpStatus(String eventId, String userId);
     Future<void> updateRsvpStatus(String eventId, String userId, String status);
     Stream<List<Map<String, dynamic>>> watchEventInvitations(String eventId);
   }
   ```
   - [ ] Move all Supabase queries from widgets to service
   - [ ] Handle real-time subscriptions centrally
   - [ ] Include error handling

2. **Create RSVPProvider** (NEW: lib/presentation/providers/rsvp_provider.dart)
   ```dart
   class RSVPProvider extends ChangeNotifier {
     final RSVPService _rsvpService;

     Map<String, List<Map<String, dynamic>>> _invitationsByEvent = {};
     Map<String, String?> _userRsvpStatuses = {};

     Future<void> loadEventInvitations(String eventId);
     Future<void> updateRsvpStatus(String eventId, String userId, String status);
     Map<String, int> getStats(String eventId); // {going, maybe, declined, pending}
   }
   ```
   - [ ] Wrap RSVPService with Provider pattern
   - [ ] Cache invitations by event ID
   - [ ] Notify listeners on updates

3. **Refactor Widgets to Use Provider**
   - [ ] `lib/presentation/screens/surprise_party_dashboard_screen.dart`
     - Remove direct Supabase calls (lines 73-83)
     - Use `Provider.of<RSVPProvider>()` instead
     - Subscribe to provider changes via `context.watch<RSVPProvider>()`

   - [ ] `lib/presentation/screens/event_detail_screen.dart`
     - Remove direct Supabase calls (lines 53-58)
     - Use `RSVPProvider.getUserRsvpStatus()`

   - [ ] `lib/presentation/widgets/rsvp_response_sheet.dart`
     - Remove direct Supabase calls (lines 223-235)
     - Use `RSVPProvider.updateRsvpStatus()`

4. **Register Provider in main.dart**
   ```dart
   MultiProvider(
     providers: [
       ChangeNotifierProvider(create: (_) => RSVPProvider(RSVPService())),
       // ... existing providers
     ],
   )
   ```

**Impact:** Consistent architecture, testable business logic, proper separation of concerns

---

## Acceptance Criteria

### Functional Requirements
- [x] All RSVP features continue to work (viewing, updating, real-time updates)
- [x] No regressions in dashboard display or event detail screen
- [x] Guest of honor still cannot see RSVP data
- [x] Real-time updates still work (without batching)

### Code Quality Requirements
- [x] Reduce codebase by ~500 lines (87 from simplification + 400 from deduplication)
- [x] No duplicate status icon/color mapping methods
- [x] No duplicate user role checking methods
- [x] All Supabase calls go through RSVPService/Provider
- [x] Zero direct `SupabaseClientManager.client` calls in presentation layer

### Database Requirements
- [x] Remove redundant composite index
- [x] Remove unused updated_at trigger
- [x] Consolidate RLS guest-of-honor checks to helper function
- [x] Deprecate migration 017 (duplicate of 020)

### Testing Requirements
- [x] Manual testing: Create surprise party → verify auto-invitations
- [x] Manual testing: Member can RSVP → organizer sees update in real-time
- [x] Manual testing: Guest of honor cannot see RSVP section
- [x] Unit tests for RSVPStatusUtils (icon/color/label mapping)
- [x] Unit tests for SurprisePartyEventExtension (getUserRole, getDisplayTitle)

---

## Files to Modify

### New Files (Create)
- `lib/core/utils/rsvp_status_utils.dart` - Status icon/color/label utilities
- `lib/core/utils/surprise_party_utils.dart` - User role detection extension
- `lib/presentation/widgets/common/status_avatar.dart` - Reusable avatar widget
- `lib/core/services/rsvp_service.dart` - RSVP data service
- `lib/presentation/providers/rsvp_provider.dart` - RSVP state management

### Database Migrations (Modify)
- `supabase/migrations/020_create_event_invitations_table.sql` - Remove index, trigger, consolidate RLS
- `supabase/migrations/017_event_invitations_table.sql` - Deprecate (rename to .DEPRECATED)
- `supabase/migrations/022_simplify_rsvp_rls.sql` (NEW) - Apply RLS helper function

### Flutter Files (Refactor)
- `lib/presentation/screens/surprise_party_dashboard_screen.dart` - Use utilities + provider
- `lib/presentation/screens/event_detail_screen.dart` - Use utilities + provider
- `lib/presentation/widgets/rsvp_response_sheet.dart` - Use provider
- `lib/presentation/widgets/agenda_event_card.dart` - Use SurprisePartyUtils
- `lib/presentation/widgets/upcoming_event_card.dart` - Use SurprisePartyUtils
- `lib/main.dart` - Register RSVPProvider

---

## Success Metrics

### Lines of Code Reduction
- **Before:** ~1,900 lines (RSVP-related code)
- **After:** ~1,400 lines
- **Reduction:** 26% (500 lines)

### Code Duplication
- **Before:** 460 lines duplicated
- **After:** 0 lines duplicated
- **Files consolidated:** 10 → 5 utility files

### Architecture Compliance
- **Before:** 8 direct Supabase calls in presentation layer
- **After:** 0 (all go through RSVPProvider)

### Maintainability
- **Before:** Change to RSVP icon requires updating 4 files
- **After:** Change to RSVP icon requires updating 1 utility file

---

## References

### Analysis Reports
- `/Users/calebbyers/Code/LockItIn/RSVP_IMPLEMENTATION_COMPLETE.md` - Original implementation
- Code duplication analysis from Explore agent (460 lines identified)
- Over-engineering analysis from code-simplicity-reviewer (87 lines to remove)
- Pattern analysis from pattern-recognition-specialist (architecture violations)

### Similar Patterns in Codebase
- `lib/presentation/providers/calendar_provider.dart` - Provider pattern example
- `lib/core/services/proposal_service.dart` - Service pattern example
- `lib/core/utils/member_utils.dart` - Utility class example

### Best Practices
- Flutter Provider pattern: https://docs.flutter.dev/data-and-backend/state-mgmt/simple
- Clean Architecture in Flutter: Separation of presentation/domain/data layers
- DRY Principle: Don't Repeat Yourself
- YAGNI Principle: You Aren't Gonna Need It

---

## Implementation Notes

### Breaking Changes
- None (refactoring only, no API changes)

### Migration Strategy
1. Phase 1 can be done independently (database + batching removal)
2. Phase 2 requires updating all files that use status helpers
3. Phase 3 requires provider registration in main.dart

### Risk Mitigation
- Keep original implementations commented out during refactor
- Test each phase independently before proceeding
- Use feature flags if needed for gradual rollout

### Future Improvements (Out of Scope)
- Push notifications for RSVP changes
- Analytics tracking for RSVP engagement
- Export RSVP list to CSV
- Batch RSVP updates (send reminder to all pending)
