---
module: Event Creation Screen
date: 2026-01-09
problem_type: runtime_error
component: flutter_navigation
symptoms:
  - "type 'EventModel' is not a subtype of type 'bool?' of 'result'"
  - "App crashes when navigating back from event creation screen"
  - "PopScope widget type mismatch"
root_cause: incorrect_generic_type
severity: critical
stage: Phase 2 Testing
tags: [popscope, navigation, type-safety, flutter-widgets]
related_issues:
  - "PR #234 - Phase 2: Timezone Support & Bug Fixes"
  - "Issue #211 - Timezone Support for Cross-Timezone Users (Epic)"
---

# PopScope Generic Type Mismatch

## Problem

**Severity:** 🔴 CRITICAL - App Crash on Navigation

**Observable Symptoms:**

```
type 'EventModel' is not a subtype of type 'bool?' of 'result'
```

**When it occurs:**
- User creates/edits event in EventCreationScreen
- User saves event
- Screen calls `Navigator.pop(event)` with EventModel
- App crashes with type error

**File:** `lib/presentation/screens/event_creation_screen.dart:291`

## Investigation

### Root Cause

**PopScope widget was typed as `PopScope<bool?>` but `Navigator.pop()` returned `EventModel`.**

**Broken code:**

```dart
@override
Widget build(BuildContext context) {
  return PopScope<bool?>(  // ❌ Generic type is bool?
    canPop: !hasUnsavedChanges || widget.isEditMode,
    onPopInvokedWithResult: (bool didPop, bool? result) {  // ❌ result typed as bool?
      if (!didPop && hasUnsavedChanges) {
        _showUnsavedChangesDialog();
      }
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'Edit Event' : 'New Event'),
        actions: [
          TextButton(
            onPressed: () {
              if (_validateForm()) {
                final event = EventModel(...);
                Navigator.pop(context, event);  // ❌ Returns EventModel, not bool!
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
      // ... rest of widget tree
    ),
  );
}
```

**Why this breaks:**

1. PopScope generic type is `PopScope<bool?>`
2. This means `onPopInvokedWithResult` expects `bool? result`
3. But `Navigator.pop(context, event)` returns `EventModel`
4. Flutter's type system catches this mismatch → runtime error
5. App crashes when trying to pass EventModel as bool?

**The type flow:**

```dart
// PopScope declares:
PopScope<bool?>  // Expects bool? as result type

// onPopInvokedWithResult signature becomes:
void Function(bool didPop, bool? result)  // result MUST be bool?

// But Navigator.pop() does:
Navigator.pop<EventModel>(context, event)  // Returns EventModel

// TYPE MISMATCH: EventModel cannot be assigned to bool?
// Runtime error: type 'EventModel' is not a subtype of type 'bool?'
```

## Solution

**Change PopScope generic type to match the return type:**

```dart
@override
Widget build(BuildContext context) {
  return PopScope<EventModel?>(  // ✅ Generic type matches return type
    canPop: !hasUnsavedChanges || widget.isEditMode,
    onPopInvokedWithResult: (bool didPop, EventModel? result) {  // ✅ result is EventModel?
      if (!didPop && hasUnsavedChanges) {
        _showUnsavedChangesDialog();
      }
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'Edit Event' : 'New Event'),
        actions: [
          TextButton(
            onPressed: () {
              if (_validateForm()) {
                final event = EventModel(
                  id: widget.eventToEdit?.id ?? '',
                  userId: widget.eventToEdit?.userId ?? '',
                  title: _titleController.text,
                  startTime: _startTime,
                  endTime: _endTime,
                  allDay: _isAllDay,
                  description: _descriptionController.text.isEmpty
                      ? null
                      : _descriptionController.text,
                  location: _locationController.text.isEmpty
                      ? null
                      : _locationController.text,
                  category: _selectedCategory,
                  visibility: _selectedVisibility,
                  nativeCalendarId: widget.eventToEdit?.nativeCalendarId,
                );
                Navigator.pop(context, event);  // ✅ Returns EventModel
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
      body: _buildForm(),
    ),
  );
}
```

**Files Modified:**
- `lib/presentation/screens/event_creation_screen.dart` - Changed PopScope<bool?> to PopScope<EventModel?>

## Prevention

### PopScope Type Safety Pattern

**RULE: PopScope generic type MUST match Navigator.pop() return type**

```dart
// ✅ CORRECT - Types match
return PopScope<MyModel?>( // Screen returns MyModel?
  onPopInvokedWithResult: (bool didPop, MyModel? result) {
    // Handle result
  },
  child: Scaffold(
    // ...
    onPressed: () => Navigator.pop(context, myModel), // Returns MyModel
  ),
);

// ❌ WRONG - Type mismatch
return PopScope<bool?>( // Expects bool?
  onPopInvokedWithResult: (bool didPop, bool? result) {
    // result is bool?, but...
  },
  child: Scaffold(
    // ...
    onPressed: () => Navigator.pop(context, myModel), // Returns MyModel ❌
  ),
);
```

### Common PopScope Patterns

**Pattern 1: Return data model on save**

```dart
// Screen that creates/edits data and returns it
return PopScope<EventModel?>(
  canPop: !hasUnsavedChanges,
  onPopInvokedWithResult: (bool didPop, EventModel? result) {
    // result is the saved EventModel (or null if cancelled)
  },
  child: Scaffold(
    // Save button
    onPressed: () => Navigator.pop(context, savedEvent),
  ),
);
```

**Pattern 2: Return bool for confirmation**

```dart
// Screen that just confirms an action
return PopScope<bool?>(
  canPop: true,
  onPopInvokedWithResult: (bool didPop, bool? result) {
    // result is true/false for confirmed/cancelled
  },
  child: Scaffold(
    // Confirm button
    onPressed: () => Navigator.pop(context, true),
    // Cancel button
    onPressed: () => Navigator.pop(context, false),
  ),
);
```

**Pattern 3: No return value (void navigation)**

```dart
// Screen that doesn't return anything
return PopScope<void>(
  canPop: true,
  onPopInvokedWithResult: (bool didPop, void result) {
    // result is always null
  },
  child: Scaffold(
    // Back button
    onPressed: () => Navigator.pop(context),
  ),
);
```

### Type-Checking Navigator.push/pop

**When calling a screen that returns data:**

```dart
// ✅ CORRECT - Explicit type parameter
final result = await Navigator.of(context).push<EventModel>(
  MaterialPageRoute(
    builder: (context) => EventCreationScreen(),
  ),
);

if (result != null) {
  // result is EventModel (type-safe)
  print(result.title);
}

// ❌ WRONG - No type parameter, result is dynamic
final result = await Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => EventCreationScreen(),
  ),
);
// result is dynamic, no type safety
```

### Code Review Checklist

When reviewing navigation code:

- [ ] Does PopScope generic type match Navigator.pop() return type?
- [ ] Does Navigator.push have explicit type parameter?
- [ ] Are null checks in place for optional results?
- [ ] Does onPopInvokedWithResult use the result correctly?

## Testing

### Verify Type Safety

**Test event creation flow:**

1. Open EventCreationScreen
2. Fill in event details
3. Click "Save"
4. ✅ Screen should pop with EventModel (no crash)
5. Parent screen receives EventModel (type-safe)

**Test cancel flow:**

1. Open EventCreationScreen
2. Make changes
3. Click back button
4. ✅ Unsaved changes dialog shows
5. Click "Discard"
6. ✅ Screen pops with null (no crash)

**Test edit flow:**

1. Open EventCreationScreen with existing event
2. Modify event details
3. Click "Save"
4. ✅ Screen pops with updated EventModel (no crash)

## Technical Details

### PopScope Widget (Flutter 3.16+)

**Purpose:** Replace deprecated `WillPopScope` for handling back navigation

**Generic type parameter:**
```dart
class PopScope<T> extends StatefulWidget {
  const PopScope({
    required this.child,
    this.canPop = true,
    this.onPopInvokedWithResult,
  });

  final Widget child;
  final bool canPop;
  final void Function(bool didPop, T result)? onPopInvokedWithResult;
}
```

**Type parameter `T` specifies:**
- The type of result passed to `onPopInvokedWithResult`
- Must match the type returned by `Navigator.pop()`
- Can be nullable (e.g., `EventModel?`, `bool?`)

### Why Flutter Uses Generics for Navigation

**Type safety across navigation boundaries:**

```dart
// Type-safe navigation
final event = await Navigator.push<EventModel>(
  context,
  MaterialPageRoute(builder: (context) => EventCreationScreen()),
);
// event is EventModel?, not dynamic

// If screen tries to return wrong type:
Navigator.pop(context, "wrong type");  // Compile-time error if type mismatch

// Type propagates through navigation stack
PopScope<EventModel?>  // Must match Navigator.push<EventModel>
```

**Benefits:**
- Compile-time type checking (catch bugs early)
- IDE autocomplete for result properties
- Refactoring safety (change type once, errors show everywhere)
- Self-documenting code (clear what screen returns)

### Migration from WillPopScope

**Old API (deprecated in Flutter 3.12):**

```dart
// ❌ Deprecated
return WillPopScope(
  onWillPop: () async {
    if (hasUnsavedChanges) {
      return await _showUnsavedChangesDialog();
    }
    return true;
  },
  child: Scaffold(...),
);
```

**New API (Flutter 3.16+):**

```dart
// ✅ Current
return PopScope<EventModel?>(
  canPop: !hasUnsavedChanges,
  onPopInvokedWithResult: (bool didPop, EventModel? result) {
    if (!didPop && hasUnsavedChanges) {
      _showUnsavedChangesDialog();
    }
  },
  child: Scaffold(...),
);
```

**Key differences:**
- `PopScope` uses generic type for result (type-safe)
- `onPopInvokedWithResult` receives both `didPop` flag and `result`
- `canPop` controls whether pop is allowed (vs onWillPop returning bool)
- Better integration with predictive back gesture (Android)

## Resolution Timeline

1. **Error discovered:** App crashed when saving events
2. **Stack trace analysis:** Identified type mismatch at event_creation_screen.dart:291
3. **Root cause:** PopScope<bool?> but Navigator.pop(event) returns EventModel
4. **Fix applied:** Changed PopScope<bool?> to PopScope<EventModel?>
5. **Verification:** Event creation flow works without crashes ✅

**Time to resolution:** ~10 minutes

## Critical Pattern

⭐ **This solution has been promoted to Required Reading:**
[Pattern 2: PopScope Type Safety](../../patterns/critical-patterns.md#pattern-2-popscope-type-safety)

All developers must ensure PopScope generic types match Navigator.pop() return types to prevent app crashes.

## Tags

#popscope #navigation #type-safety #flutter-widgets #generics #type-mismatch
