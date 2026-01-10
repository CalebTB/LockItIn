---
module: Calendar System
date: 2026-01-09
problem_type: logic_error
component: flutter_screen
symptoms:
  - "Events created but lost after hot restart"
  - "EventService.createEvent() never called from card_calendar_screen.dart"
  - "Events only added to memory, not saved to Supabase"
root_cause: incomplete_implementation
severity: critical
stage: Phase 2 Testing
tags: [event-persistence, supabase, dual-write-pattern, calendar-sync]
related_issues:
  - "PR #234 - Phase 2: Timezone Support & Bug Fixes"
  - "Issue #211 - Timezone Support for Cross-Timezone Users (Epic)"
  - "docs/solutions/database-issues/visibility-enum-mismatch-20260109.md"
---

# Events Not Persisting After Hot Restart

## Problem

**Severity:** 🔴 CRITICAL - Data Loss

**Observable Symptoms:**
- User creates event from agenda view FAB button
- Event appears in calendar immediately
- After hot restart, event disappears completely
- No error messages shown to user

**User Report:**
> "I click the FAB button on the agenda view, then click Party template. Event shows up but when I hot restart, those events aren't on the personal calendar."

## Investigation

### Failed Attempts

1. **Initially suspected CalendarManager platform channel exception**
   - Added MissingPluginException handling (needed for simulator but not root cause)

2. **Added extensive logging to track event flow**
   - EventService logs were completely missing
   - This revealed the actual issue

3. **Traced FAB navigation flow**
   - User clicks FAB → card_calendar_screen.dart → EventCreationScreen
   - Party template was IN EventCreationScreen, not NewEventBottomSheet
   - Found FAB → card_calendar_screen.dart → **missing EventService call**

### Root Cause

**File:** `lib/presentation/screens/card_calendar_screen.dart`

The `_showNewEventSheet()` method only added events to the in-memory Provider state but **NEVER** called `EventService.createEvent()` to save to Supabase.

**Broken code:**
```dart
void _showNewEventSheet() async {
  final result = await Navigator.of(context).push<EventModel>(
    MaterialPageRoute(builder: (context) => EventCreationScreen()),
  );

  if (result != null && mounted) {
    final provider = context.read<CalendarProvider>();
    provider.addEvent(result);  // ❌ ONLY adds to memory!
  }
}
```

**Why this breaks:**
1. Event exists in Provider (in-memory state)
2. Hot restart clears all in-memory state
3. Provider calls `_loadEvents()` from Supabase
4. Event doesn't exist in database → not restored
5. User sees event disappear

**Comparison with working code:**

The calendar_screen.dart FAB worked correctly because it called EventService:

```dart
// calendar_screen.dart (WORKING)
final savedEvent = await EventService.instance.createEvent(result);
provider.addEvent(savedEvent);
```

## Solution

**Complete rewrite of `_showNewEventSheet()` in card_calendar_screen.dart:**

```dart
void _showNewEventSheet() async {
  final result = await Navigator.of(context).push<EventModel>(
    MaterialPageRoute(
      builder: (context) => EventCreationScreen(
        selectedDate: _selectedDate,
      ),
    ),
  );

  if (result != null && mounted) {
    // Show loading dialog while saving
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // ✅ NOW saves to Supabase!
      final savedEvent = await EventService.instance.createEvent(result);

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      // Add to provider (in-memory state)
      final provider = context.read<CalendarProvider>();
      provider.addEvent(savedEvent);

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event created successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      // Show error and rollback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create event: $e'),
          backgroundColor: Colors.red,
        ),
      );

      Logger.error('CardCalendarScreen', 'Failed to create event: $e');
    }
  }
}
```

**Key changes:**
1. ✅ Calls `EventService.instance.createEvent(result)` to save to Supabase
2. ✅ Shows loading dialog during save operation
3. ✅ Uses saved event from database (with generated ID and timestamps)
4. ✅ Shows success/error feedback to user
5. ✅ Handles errors with rollback (doesn't add to provider if save fails)

**Files Modified:**
- `lib/presentation/screens/card_calendar_screen.dart` - Complete rewrite of `_showNewEventSheet()`
- `lib/core/services/event_service.dart` - Added logging, fixed to return database response
- `lib/core/services/calendar_manager.dart` - Added MissingPluginException handling

## Prevention

### Pattern to Follow: Dual-Write for Event Creation

**ALWAYS use this pattern when creating events:**

```dart
// 1. Create event in Supabase (source of truth)
final savedEvent = await EventService.instance.createEvent(event);

// 2. Add to in-memory provider state (for immediate UI update)
provider.addEvent(savedEvent);

// 3. Optionally sync to native calendar (iOS/Android)
// (EventService handles this automatically)
```

**Why this order matters:**
- Supabase is source of truth (survives app restarts)
- Use database response (has generated ID, timestamps)
- Provider state is ephemeral (cleared on restart)
- Native calendar sync is optional (requires permissions)

### Testing Checklist

To verify event persistence:

```bash
# 1. Create event from agenda view FAB
# 2. Verify event appears in calendar
# 3. Hot restart app (flutter run -d <device>)
# 4. ✅ Event should still exist
# 5. Check Supabase dashboard → events table → verify row exists
```

### Code Review Checklist

When reviewing event creation code:

- [ ] Does it call `EventService.createEvent()`?
- [ ] Does it use the database response (not the input event)?
- [ ] Does it handle errors and show user feedback?
- [ ] Does it show loading state during save?
- [ ] Does it rollback UI changes if save fails?

## Related Issues

**Similar patterns in codebase:**

1. `lib/presentation/screens/calendar_screen.dart` - ✅ CORRECT implementation
   - Shows loading dialog
   - Calls EventService.createEvent()
   - Uses database response
   - Shows success/error feedback

2. `lib/presentation/screens/card_calendar_screen.dart` - ❌ WAS BROKEN (now fixed)
   - Missing EventService call
   - Only updated in-memory state

**Lesson:** When adding new event creation flows, always reference `calendar_screen.dart` as the canonical example.

## Technical Details

**Architecture:**

```
User Action (FAB click)
    ↓
EventCreationScreen (returns EventModel)
    ↓
_showNewEventSheet() in parent screen
    ↓
EventService.createEvent()  ← CRITICAL: Must call this
    ├── Save to Supabase (source of truth)
    ├── Sync to native calendar (iOS/Android)
    └── Return saved event with DB-generated fields
    ↓
CalendarProvider.addEvent()  ← Update in-memory state
    ↓
UI reflects new event
```

**Why hot restart exposed this:**
- Hot restart clears all Dart in-memory state
- Provider calls `_loadEvents()` to restore from Supabase
- Events not in Supabase → not restored → appear to "disappear"

**Database schema:**
```sql
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  title TEXT NOT NULL,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  -- ... other fields
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

## Resolution Timeline

1. **User reported issue:** "Events disappear after hot restart"
2. **Initial investigation:** Suspected platform channel issues (red herring)
3. **Added logging:** Discovered EventService logs missing
4. **User interview:** Confirmed exact UI flow (FAB → Party template)
5. **Code path tracing:** Found missing EventService call in card_calendar_screen.dart
6. **Root cause identified:** Only updating in-memory state, not database
7. **Solution implemented:** Complete rewrite of `_showNewEventSheet()`
8. **Verification:** Events now persist after hot restart ✅

**Time to resolution:** ~1 hour of debugging

## Critical Pattern

⭐ **This solution has been promoted to Required Reading:**
[Pattern 1: Dual-Write Pattern](../../patterns/critical-patterns.md#pattern-1-dual-write-pattern-for-event-creation)

All developers must follow the dual-write pattern when creating or modifying events to prevent data loss.

## Tags

#event-persistence #supabase #dual-write-pattern #calendar-sync #data-loss #critical-bug
