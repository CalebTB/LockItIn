# Critical Patterns - Required Reading

**Purpose:** Patterns that MUST be followed every time. These patterns prevent critical bugs that were discovered during development.

**When to read:** Before implementing any feature that involves:
- Event creation/modification
- Screen navigation with data return
- Database schema changes
- Timezone handling

---

## Pattern 1: Dual-Write Pattern for Event Creation

**Discovered:** Phase 2 Testing (January 9, 2026)
**Severity:** 🔴 CRITICAL - Data Loss
**Context:** Events created but lost after hot restart
**Issue:** `card_calendar_screen.dart` only updated in-memory Provider, never saved to Supabase

### The Problem

When creating events, there are TWO state locations:
1. **Supabase database** - Persistent storage (survives app restarts)
2. **Provider state** - In-memory cache (cleared on restart)

**If you only update Provider state**, events disappear on hot restart because:
- Provider loads events from Supabase on startup
- Event doesn't exist in database → not restored
- User loses their data

### ❌ WRONG: Only Update In-Memory State

```dart
void _showNewEventSheet() async {
  final result = await Navigator.of(context).push<EventModel>(
    MaterialPageRoute(builder: (context) => EventCreationScreen()),
  );

  if (result != null && mounted) {
    final provider = context.read<CalendarProvider>();
    provider.addEvent(result);  // ❌ ONLY updates memory - DATA LOSS!
  }
}
```

**Why this is wrong:**
- Event only exists in Provider (in-memory)
- Hot restart clears all Dart memory
- Provider reloads from Supabase → event not found
- Event disappears completely

### ✅ CORRECT: Dual-Write Pattern

```dart
void _showNewEventSheet() async {
  final result = await Navigator.of(context).push<EventModel>(
    MaterialPageRoute(builder: (context) => EventCreationScreen()),
  );

  if (result != null && mounted) {
    // Show loading state
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. ✅ FIRST: Save to Supabase (source of truth)
      final savedEvent = await EventService.instance.createEvent(result);

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      // 2. ✅ SECOND: Add to Provider (use database response)
      final provider = context.read<CalendarProvider>();
      provider.addEvent(savedEvent);  // Use savedEvent, not result!

      // 3. ✅ Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event created successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      // 4. ✅ Handle errors - DON'T add to Provider if save fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create event: $e')),
      );
    }
  }
}
```

**Why this is correct:**
1. **Supabase first** - Database is source of truth
2. **Use database response** - Contains generated ID, timestamps, etc.
3. **Provider second** - Updates in-memory cache for immediate UI
4. **Error handling** - Rollback if save fails
5. **User feedback** - Loading state + success/error messages

### The Rule

**ALWAYS follow this order for event creation:**

```dart
// 1. Save to Supabase (persistent storage)
final savedEvent = await EventService.instance.createEvent(event);

// 2. Add to Provider (in-memory cache) - use savedEvent!
provider.addEvent(savedEvent);

// 3. Native calendar sync happens automatically in EventService
```

**Never skip step 1. Never use the input event instead of savedEvent.**

### References
- [Solution Doc: events-not-persisting-calendar-20260109.md](../logic-errors/events-not-persisting-calendar-20260109.md)
- [PR #234](https://github.com/CalebTB/LockItIn/pull/234)
- Files affected: `lib/presentation/screens/card_calendar_screen.dart`, `lib/core/services/event_service.dart`

---

## Pattern 2: PopScope Type Safety

**Discovered:** Phase 2 Testing (January 9, 2026)
**Severity:** 🔴 CRITICAL - App Crash
**Context:** App crashed when saving events from EventCreationScreen
**Issue:** `PopScope<bool?>` but `Navigator.pop(event)` returned `EventModel`

### The Problem

Flutter's `PopScope` widget uses a generic type parameter to specify what type of data the screen returns. If this type doesn't match what `Navigator.pop()` actually returns, you get a runtime type error and the app crashes.

### ❌ WRONG: Type Mismatch

```dart
@override
Widget build(BuildContext context) {
  return PopScope<bool?>(  // ❌ Expects bool?
    canPop: !hasUnsavedChanges,
    onPopInvokedWithResult: (bool didPop, bool? result) {  // ❌ result is bool?
      if (!didPop && hasUnsavedChanges) {
        _showUnsavedChangesDialog();
      }
    },
    child: Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () {
              final event = EventModel(...);
              Navigator.pop(context, event);  // ❌ Returns EventModel - TYPE MISMATCH!
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}
```

**Error:**
```
type 'EventModel' is not a subtype of type 'bool?' of 'result'
```

**Why this crashes:**
- `PopScope<bool?>` means `onPopInvokedWithResult` expects `bool? result`
- But `Navigator.pop(context, event)` returns `EventModel`
- Flutter's type system catches this at runtime → crash

### ✅ CORRECT: Matching Types

```dart
@override
Widget build(BuildContext context) {
  return PopScope<EventModel?>(  // ✅ Generic type matches return type
    canPop: !hasUnsavedChanges,
    onPopInvokedWithResult: (bool didPop, EventModel? result) {  // ✅ result is EventModel?
      if (!didPop && hasUnsavedChanges) {
        _showUnsavedChangesDialog();
      }
    },
    child: Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () {
              final event = EventModel(...);
              Navigator.pop(context, event);  // ✅ Returns EventModel - types match!
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}
```

**Why this works:**
- `PopScope<EventModel?>` declares the return type
- `onPopInvokedWithResult` receives `EventModel? result`
- `Navigator.pop(context, event)` returns `EventModel`
- Types align perfectly → no crash

### The Rule

**PopScope generic type MUST match Navigator.pop() return type:**

```dart
// Pattern 1: Return data model
PopScope<MyModel?>(
  onPopInvokedWithResult: (bool didPop, MyModel? result) { },
  child: // ... Navigator.pop(context, myModel)
)

// Pattern 2: Return bool for confirmation
PopScope<bool?>(
  onPopInvokedWithResult: (bool didPop, bool? result) { },
  child: // ... Navigator.pop(context, true/false)
)

// Pattern 3: No return value
PopScope<void>(
  onPopInvokedWithResult: (bool didPop, void result) { },
  child: // ... Navigator.pop(context)
)
```

**Also type Navigator.push for safety:**

```dart
// ✅ CORRECT: Explicit type parameter
final result = await Navigator.push<EventModel>(
  context,
  MaterialPageRoute(builder: (context) => EventCreationScreen()),
);
// result is EventModel?, not dynamic

// ❌ WRONG: No type parameter
final result = await Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => EventCreationScreen()),
);
// result is dynamic - no type safety
```

### References
- [Solution Doc: popscope-type-mismatch-20260109.md](../runtime-errors/popscope-type-mismatch-20260109.md)
- [PR #234](https://github.com/CalebTB/LockItIn/pull/234)
- File affected: `lib/presentation/screens/event_creation_screen.dart`

---

## Pattern 3: Database Schema Alignment

**Discovered:** Phase 2 Testing (January 9, 2026)
**Severity:** 🔴 CRITICAL - Data Integrity
**Context:** Three database schema issues discovered
**Issues:** Missing `all_day` column, enum value mismatch (camelCase vs snake_case), wrong column type (TEXT instead of enum)

### The Problem

When Dart models include fields that don't exist in the database, or when database types don't match model expectations, you get runtime errors or silent data corruption.

### ❌ WRONG: Code Before Migration

```dart
// EventModel.toJson() includes all_day field
Map<String, dynamic> toJson() {
  return {
    'title': title,
    'all_day': allDay,  // ❌ Column doesn't exist in database!
    'visibility': visibility.name,  // ❌ Sends 'shared_with_name', DB has 'sharedWithName'
  };
}
```

```sql
-- Database schema is out of sync
CREATE TABLE events (
  id UUID PRIMARY KEY,
  title TEXT NOT NULL,
  -- all_day column missing! ❌
  visibility TEXT DEFAULT 'private',  -- ❌ Should be enum type, not TEXT
  -- ...
);

-- Enum values don't match Dart
CREATE TYPE event_visibility AS ENUM (
  'private',
  'sharedWithName',  -- ❌ camelCase, Dart sends snake_case
  'busyOnly'         -- ❌ camelCase, Dart sends snake_case
);
```

**Errors:**
```
PostgrestException: Could not find the 'all_day' column of 'events' in the schema cache
invalid input value for enum event_visibility: "shared_with_name"
```

### ✅ CORRECT: Migration Before Code

**Step 1: Create migrations FIRST**

```sql
-- Migration 015: Add missing column
ALTER TABLE events
ADD COLUMN IF NOT EXISTS all_day BOOLEAN NOT NULL DEFAULT false;

-- Migration 016: Add snake_case enum values (can't remove old ones without recreating type)
ALTER TYPE event_visibility ADD VALUE IF NOT EXISTS 'shared_with_name';
ALTER TYPE event_visibility ADD VALUE IF NOT EXISTS 'busy_only';

-- Migrate existing data
UPDATE events SET visibility = 'shared_with_name' WHERE visibility = 'sharedWithName';
UPDATE events SET visibility = 'busy_only' WHERE visibility = 'busyOnly';

-- Migration 017: Convert column type to enum
ALTER TABLE events ALTER COLUMN visibility TYPE event_visibility
USING visibility::event_visibility;
```

**Step 2: THEN use in Dart code**

```dart
// ✅ Now safe to use these fields
Map<String, dynamic> toJson() {
  return {
    'title': title,
    'all_day': allDay,  // ✅ Column exists
    'visibility': visibility.name,  // ✅ Enum values match
  };
}
```

### The Rule

**ALWAYS follow this order:**

```
1. Create migration script (supabase/migrations/XXX_description.sql)
2. Apply migration to database (supabase db push)
3. Verify schema with information_schema queries
4. Update Dart models to use new fields
5. Test end-to-end
```

**Never skip steps. Never write code before migration exists.**

### Enum Value Naming Convention

**ALWAYS use snake_case for enum values:**

```dart
// ✅ CORRECT
enum EventVisibility {
  private,           // 'private'
  shared_with_name,  // 'shared_with_name' ← snake_case
  busy_only,         // 'busy_only' ← snake_case
}
```

```sql
-- ✅ CORRECT
CREATE TYPE event_visibility AS ENUM (
  'private',
  'shared_with_name',  -- ← snake_case
  'busy_only'          -- ← snake_case
);
```

**Why snake_case:**
- JSON convention (most APIs use snake_case)
- PostgreSQL convention (lowercase with underscores)
- Dart `.toJson()` naturally produces snake_case
- Supabase client expects snake_case

### Type Alignment Checklist

Before adding a field to a Dart model:

- [ ] Does the column exist in the database?
- [ ] Is the column type correct? (BOOLEAN, TIMESTAMPTZ, enum, etc.)
- [ ] Do enum values match exactly? (use snake_case)
- [ ] Has the migration been applied?
- [ ] Have you verified with `information_schema` queries?

### References
- [Solution Doc: visibility-enum-mismatch-20260109.md](../database-issues/visibility-enum-mismatch-20260109.md)
- [PR #234](https://github.com/CalebTB/LockItIn/pull/234)
- Migrations: `015_add_all_day_to_events.sql`, `016_fix_event_visibility_enum.sql`, `017_convert_visibility_to_enum.sql`

---

## Pattern 4: Timezone Change Detection

**Discovered:** Phase 2 Testing (January 9, 2026)
**Severity:** 🟡 IMPORTANT - Stale Data
**Context:** Events not refreshing when device timezone changes
**Issue:** No lifecycle observation to detect app resume after timezone change

### The Problem

Events are stored in UTC but displayed in local timezone. When users travel and change their device timezone, the app needs to refresh to show times in the new timezone. Without lifecycle detection, events show stale times.

### ❌ WRONG: No Lifecycle Detection

```dart
class CalendarProvider extends ChangeNotifier {
  // ❌ No lifecycle observation
  // ❌ Events loaded once, never refreshed

  CalendarProvider() {
    _loadEvents();  // Loads once on creation
  }
}
```

**Result:**
- User opens app in PST → events loaded with PST times
- User travels to EST, changes device timezone
- User resumes app → still shows PST times (stale data)

### ✅ CORRECT: Lifecycle Observation

```dart
class CalendarProvider extends ChangeNotifier with WidgetsBindingObserver {
  int? _lastTimezoneOffsetHours;

  CalendarProvider() {
    _loadEvents();

    // ✅ Register as lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    _lastTimezoneOffsetHours = DateTime.now().timeZoneOffset.inHours;
  }

  // ✅ Detect when app resumes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndRefreshOnTimezoneChange();
    }
  }

  // ✅ Check if timezone changed and refresh
  void _checkAndRefreshOnTimezoneChange() {
    final currentOffsetHours = DateTime.now().timeZoneOffset.inHours;

    if (_lastTimezoneOffsetHours != null &&
        _lastTimezoneOffsetHours != currentOffsetHours) {
      Logger.info(
        'CalendarProvider',
        'Timezone changed from $_lastTimezoneOffsetHours to $currentOffsetHours hours - refreshing',
      );

      _lastTimezoneOffsetHours = currentOffsetHours;
      _loadEvents();  // Reload with new timezone
      notifyListeners();
    }
  }

  // ✅ Clean up observer
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
```

### The Rule

**For Providers that display datetime values:**

```dart
class MyProvider extends ChangeNotifier with WidgetsBindingObserver {
  int? _lastTimezoneOffsetHours;

  MyProvider() {
    // Register observer + store initial offset
    WidgetsBinding.instance.addObserver(this);
    _lastTimezoneOffsetHours = DateTime.now().timeZoneOffset.inHours;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final current = DateTime.now().timeZoneOffset.inHours;
      if (_lastTimezoneOffsetHours != current) {
        _lastTimezoneOffsetHours = current;
        _refreshData();  // Your refresh logic
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
```

**When to use:**
- Provider displays datetime values
- Data comes from UTC database storage
- User might change device timezone

### References
- [Solution Doc: timezone-datetime-parsing-20260109.md](../runtime-errors/timezone-datetime-parsing-20260109.md)
- [PR #234](https://github.com/CalebTB/LockItIn/pull/234)
- File affected: `lib/presentation/providers/calendar_provider.dart`

---

## Summary

**Critical Patterns (MUST follow every time):**

1. **Dual-Write Pattern** - Save to Supabase BEFORE updating Provider (prevents data loss)
2. **PopScope Type Safety** - Generic type MUST match Navigator.pop() return type (prevents crashes)
3. **Database Schema Alignment** - Create migration BEFORE using field in code (prevents data integrity issues)

**Important Patterns (Should follow):**

4. **Timezone Change Detection** - Use WidgetsBindingObserver for lifecycle detection (prevents stale data)

**When violated, these patterns cause:**
- 🔴 Data loss (Pattern 1)
- 🔴 App crashes (Pattern 2)
- 🔴 Data corruption (Pattern 3)
- 🟡 Stale UI data (Pattern 4)

**Read before:**
- Creating or modifying events
- Building screens that return data via navigation
- Changing database schema
- Working with timezone-sensitive data

---

*Last updated: January 9, 2026*
*Patterns discovered: Phase 2 Testing*
*Total critical patterns: 4*
