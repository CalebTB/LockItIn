# Solutions Documentation Index

Comprehensive documentation of problems encountered during LockItIn development and their solutions.

## Phase 2: Timezone Support Testing (January 9, 2026)

### 🔴 Critical Issues

**Event Persistence**
- [`logic-errors/events-not-persisting-calendar-20260109.md`](logic-errors/events-not-persisting-calendar-20260109.md)
  - **Problem:** Events created but lost after hot restart
  - **Root Cause:** card_calendar_screen.dart never called EventService.createEvent()
  - **Impact:** Data loss - events only saved in memory, not database
  - **Tags:** #event-persistence #supabase #dual-write-pattern #data-loss

**PopScope Type Mismatch**
- [`runtime-errors/popscope-type-mismatch-20260109.md`](runtime-errors/popscope-type-mismatch-20260109.md)
  - **Problem:** App crashes when navigating back from event creation
  - **Root Cause:** PopScope<bool?> but Navigator.pop() returns EventModel
  - **Impact:** App crash on every event save
  - **Tags:** #popscope #navigation #type-safety #flutter-widgets

**Database Schema Issues**
- [`database-issues/visibility-enum-mismatch-20260109.md`](database-issues/visibility-enum-mismatch-20260109.md)
  - **Problem:** Visibility settings not preserved, enum value mismatch
  - **Root Cause:** Three issues: missing all_day column, camelCase vs snake_case enums, TEXT column instead of enum type
  - **Impact:** Privacy settings silently lost, data integrity compromised
  - **Tags:** #database-migration #enum-values #type-safety #privacy

### 🟡 Moderate Issues

**Timezone & Datetime**
- [`runtime-errors/timezone-datetime-parsing-20260109.md`](runtime-errors/timezone-datetime-parsing-20260109.md)
  - **Problem:** Datetime parsing fails on Supabase responses, timezone changes not refreshing UI
  - **Root Cause:** Regex too strict (only accepted Z format), no lifecycle observation
  - **Impact:** App crashes on event loading, stale data after timezone changes
  - **Tags:** #timezone #datetime-parsing #iso8601 #lifecycle-detection

## 📚 Required Reading - Critical Patterns

**[Critical Patterns File](patterns/critical-patterns.md)** - Patterns that MUST be followed every time.

The most critical bugs from Phase 2 have been promoted to Required Reading. **Read before implementing:**
- Event creation/modification → [Pattern 1: Dual-Write Pattern](patterns/critical-patterns.md#pattern-1-dual-write-pattern-for-event-creation)
- Screen navigation with data → [Pattern 2: PopScope Type Safety](patterns/critical-patterns.md#pattern-2-popscope-type-safety)
- Database schema changes → [Pattern 3: Database Schema Alignment](patterns/critical-patterns.md#pattern-3-database-schema-alignment)
- Timezone-sensitive data → [Pattern 4: Timezone Change Detection](patterns/critical-patterns.md#pattern-4-timezone-change-detection)

**Why these patterns matter:**
- Pattern 1 violated → 🔴 Data loss (events disappear)
- Pattern 2 violated → 🔴 App crashes (type mismatch)
- Pattern 3 violated → 🔴 Data corruption (schema mismatch)
- Pattern 4 violated → 🟡 Stale UI (wrong timezone)

## Summary Statistics

**Phase 2 Testing Results:**
- **Bugs Fixed:** 7 total
  - 🔴 Critical: 5 (event persistence, PopScope crash, 3 database issues)
  - 🟡 Moderate: 2 (datetime parsing, timezone refresh)
- **Critical Patterns Created:** 4 (promoted to Required Reading)
- **Migrations Created:** 3
  - `015_add_all_day_to_events.sql`
  - `016_fix_event_visibility_enum.sql`
  - `017_convert_visibility_to_enum.sql`
- **Testing Duration:** ~4 hours
- **Success Rate:** 100% (all bugs resolved)

## Categories

### Logic Errors
Issues with business logic or incomplete implementations
- [events-not-persisting-calendar-20260109.md](logic-errors/events-not-persisting-calendar-20260109.md)

### Runtime Errors
Crashes, exceptions, and runtime failures
- [popscope-type-mismatch-20260109.md](runtime-errors/popscope-type-mismatch-20260109.md)
- [timezone-datetime-parsing-20260109.md](runtime-errors/timezone-datetime-parsing-20260109.md)

### Database Issues
Schema mismatches, migration problems, data integrity
- [visibility-enum-mismatch-20260109.md](database-issues/visibility-enum-mismatch-20260109.md)

### UI Bugs
Visual issues, interaction problems, UX concerns
- *(None documented yet)*

## Key Lessons Learned

### 1. Dual-Write Pattern for Event Creation
**Always follow this pattern:**
```dart
// 1. Save to Supabase (source of truth)
final savedEvent = await EventService.instance.createEvent(event);

// 2. Add to in-memory provider
provider.addEvent(savedEvent);

// 3. Use database response (has generated ID/timestamps)
```

### 2. Database Schema Alignment
**Before adding fields to models:**
- Check if column exists in database
- Verify enum values match (use snake_case)
- Ensure column type matches Dart model
- Create migration BEFORE using field in code

### 3. PopScope Type Safety
**PopScope generic type MUST match Navigator.pop() return type:**
```dart
// ✅ CORRECT
PopScope<EventModel?>(
  onPopInvokedWithResult: (bool didPop, EventModel? result) { },
  child: ElevatedButton(
    onPressed: () => Navigator.pop(context, event),
  ),
)
```

### 4. Timezone Change Detection
**For Providers displaying times, implement lifecycle observation:**
```dart
class MyProvider extends ChangeNotifier with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndRefreshOnTimezoneChange();
    }
  }
}
```

## Search by Tag

- **#event-persistence** - Event storage and database sync issues
- **#supabase** - Supabase-specific problems
- **#database-migration** - Schema changes and migrations
- **#type-safety** - TypeScript/Dart type system issues
- **#flutter-widgets** - Flutter widget-specific problems
- **#timezone** - Timezone handling and conversion
- **#privacy** - Privacy and visibility settings
- **#navigation** - Screen navigation and routing
- **#data-loss** - Issues that can cause data loss
- **#critical-bug** - Bugs that block core functionality

## Documentation Format

Each solution document follows this structure:

```markdown
---
module: [Module Name]
date: YYYY-MM-DD
problem_type: [logic_error|runtime_error|database_issue|etc]
component: [Component Name]
symptoms: [List of observable symptoms]
root_cause: [Root cause category]
severity: [critical|moderate|minor]
stage: [Development Stage]
tags: [Relevant tags]
related_issues: [Related docs/PRs]
---

# Problem Title

## Problem
Observable symptoms and user impact

## Investigation
Failed attempts and debugging process

## Solution
Working fix with code examples

## Prevention
How to avoid in future

## Testing
Verification steps

## Technical Details
Deep dive into the issue

## Tags
Searchable keywords
```

## Contributing

When documenting new solutions:

1. Use the compound-docs skill: `/workflows:compound`
2. Include exact error messages (searchable)
3. Show failed attempts (helps others avoid wrong paths)
4. Provide code examples (before/after)
5. Add prevention guidance
6. Cross-reference related issues

## Related Work

### GitHub Issues (v0.4.0 Timezone Epic)

The bugs documented here were discovered during Phase 2 testing of the timezone support initiative. The following issues are part of the ongoing timezone work:

**Core Implementation:**
- [Issue #204](https://github.com/CalebTB/LockItIn/issues/204) - Create Core Timezone Utilities ✅ (Completed in Phase 2)
- [Issue #205](https://github.com/CalebTB/LockItIn/issues/205) - Update Data Models with UTC Conversion
- [Issue #206](https://github.com/CalebTB/LockItIn/issues/206) - Update Service Layer and DateTime.now() Usage

**UI & Display Layer:**
- [Issue #207](https://github.com/CalebTB/LockItIn/issues/207) - Fix UI Display Layer DateFormat Usage
- [Issue #208](https://github.com/CalebTB/LockItIn/issues/208) - Update Date Pickers to Convert to UTC

**Integration & Testing:**
- [Issue #209](https://github.com/CalebTB/LockItIn/issues/209) - Review and Fix Native Calendar Sync
- [Issue #210](https://github.com/CalebTB/LockItIn/issues/210) - Integration Testing and Manual Validation

**Epic:**
- [Issue #211](https://github.com/CalebTB/LockItIn/issues/211) - Timezone Support for Cross-Timezone Users (Epic)

### Pull Requests

**Phase 2 Testing Results:**
- [PR #234](https://github.com/CalebTB/LockItIn/pull/234) - Phase 2: Timezone Support & Bug Fixes (7 bugs fixed, 3 migrations)
  - Documents all issues found in this solutions directory
  - Includes PR_PHASE_2_TESTING_REPORT.md with comprehensive testing documentation

### Cross-References Between Solutions

**Event Persistence → Database Issues:**
- The event persistence bug required proper database schema alignment
- See [visibility-enum-mismatch-20260109.md](database-issues/visibility-enum-mismatch-20260109.md) for database migration details

**Timezone Parsing → Timezone Utils:**
- Timezone change detection relies on proper datetime parsing
- Both issues fixed in lib/core/utils/timezone_utils.dart
- See [timezone-datetime-parsing-20260109.md](runtime-errors/timezone-datetime-parsing-20260109.md)

**PopScope Type Safety → Navigation Patterns:**
- Type safety issues can occur throughout navigation flows
- Pattern applies to all screens that return data via Navigator.pop()
- See [popscope-type-mismatch-20260109.md](runtime-errors/popscope-type-mismatch-20260109.md)

## Next Steps

After documenting a solution:

1. **Continue workflow** - Return to development
2. **Add to Required Reading** - Promote to critical patterns
3. **Link related issues** ✅ - Connected to GitHub issues #204-211 and PR #234
4. **Add to existing skill** - Update learning resources
5. **Create new skill** - Extract into new documentation

## Future Phases

**Phase 3: Cross-Timezone Event Display Testing**
- Test with multiple users in different timezones
- Verify event times display correctly for all participants
- Test group availability heatmap with timezone differences
- Validate voting deadline behavior across timezones

**Issues to reference these solutions:**
- All timezone-related issues (#204-211) should reference this documentation
- Future timezone bugs should be documented here using same format
- Use these solutions as examples for prevention strategies

---

*Last updated: January 9, 2026*
*Total solutions documented: 4*
*Total bugs resolved: 7*
*Linked to: PR #234, Issues #204-#211*
