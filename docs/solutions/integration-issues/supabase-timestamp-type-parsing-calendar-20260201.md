---
module: LockItIn Calendar System
date: 2026-02-01
problem_type: integration_issue
component: frontend_stimulus
symptoms:
  - "Events created for Feb 5 appeared as Feb 6 in calendar"
  - "Off-by-one date error in event display"
root_cause: logic_error
resolution_type: code_fix
severity: high
tags: [supabase, timezone, datetime, parsing, flutter, dart]
---

# Troubleshooting: Supabase Timestamp Type Inconsistency Causing Off-by-One Date Error

## Problem
Events created for one date (e.g., February 5) were appearing on the calendar one day later (February 6). The root cause was that EventModel.fromJson() assumed Supabase always returned timestamps as strings, but Supabase can return either DateTime objects OR strings depending on the query and serialization path. This caused incorrect parsing and timezone conversion.

## Environment
- Module: LockItIn Calendar System
- Framework: Flutter 3.16+ with Dart 3.0+
- Backend: Supabase (PostgreSQL with TIMESTAMPTZ columns)
- Affected Components: EventModel, ShadowCalendarEntry
- Date: 2026-02-01

## Symptoms
- User creates event for February 5, 2026
- Event appears in calendar on February 6, 2026
- Database verification shows correct UTC storage: `2026-02-06 01:00:00+00` (Feb 5 17:00 PST)
- Personal calendar view shows Feb 6 (wrong)
- Group calendar view shows Feb 6 (wrong)
- Consistent off-by-one error across all calendar views

## What Didn't Work

**Investigation Step 1: Verify Database Storage**
- **What was tried:** Queried database to check if timestamps were stored incorrectly
- **Result:** Database storage was CORRECT - events stored in UTC as expected
- **Why investigation continued:** The problem was in parsing/display, not storage

## Solution

**Add parseTimestamp() Helper to Handle Both String and DateTime Types**

Modified both EventModel and ShadowCalendarEntry to handle Supabase's inconsistent timestamp serialization:

```dart
// File: application/lockitin_app/lib/data/models/event_model.dart

factory EventModel.fromJson(Map<String, dynamic> json) {
  // Helper to parse timestamps from Supabase (handles both String and DateTime)
  DateTime parseTimestamp(dynamic value, bool ensureUtc) {
    if (value is DateTime) {
      // Supabase returned a DateTime object - ensure it's UTC if needed
      return ensureUtc ? value.toUtc() : value;
    } else if (value is String) {
      // Supabase returned a string - parse it
      return ensureUtc ? TimezoneUtils.parseUtc(value) : DateTime.parse(value);
    } else {
      throw ArgumentError('Invalid timestamp type: ${value.runtimeType}');
    }
  }

  final allDay = json['all_day'] as bool? ?? false;

  return EventModel(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    // Use helper for all timestamp fields
    startTime: parseTimestamp(json['start_time'], !allDay),
    endTime: parseTimestamp(json['end_time'], !allDay),
    createdAt: parseTimestamp(json['created_at'], true),
    updatedAt: json['updated_at'] != null
      ? parseTimestamp(json['updated_at'], true)
      : null,
    // ... rest of fields
  );
}
```

```dart
// File: application/lockitin_app/lib/data/models/shadow_calendar_entry.dart

factory ShadowCalendarEntry.fromJson(Map<String, dynamic> json) {
  // Helper to parse timestamps from Supabase (handles both String and DateTime)
  DateTime parseTimestamp(dynamic value) {
    if (value is DateTime) {
      return value.toUtc();
    } else if (value is String) {
      return TimezoneUtils.parseUtc(value);
    } else {
      throw ArgumentError('Invalid timestamp type: ${value.runtimeType}');
    }
  }

  return ShadowCalendarEntry(
    userId: json['user_id'] as String,
    startTime: parseTimestamp(json['start_time']),
    endTime: parseTimestamp(json['end_time']),
    visibility: _visibilityFromString(json['visibility'] as String),
    eventTitle: json['event_title'] as String?,
    isGroupEvent: json['is_group_event'] as bool? ?? false,
    eventId: json['event_id'] as String?,
    templateData: templateData,
  );
}
```

**Key Changes:**
1. **Type checking**: Check if value is `DateTime` or `String` before parsing
2. **Conditional UTC conversion**:
   - DateTime objects: Use `.toUtc()` if needed
   - Strings: Parse with `TimezoneUtils.parseUtc()` or `DateTime.parse()`
3. **All-day event handling**: Skip UTC conversion for all-day events in EventModel
4. **Error handling**: Throw clear error if unexpected type received

## Why This Works

**Root Cause:**
Supabase's Dart client serializes PostgreSQL TIMESTAMPTZ columns inconsistently:
- **Sometimes**: Returns pre-parsed `DateTime` objects (when using `.select().single()`)
- **Sometimes**: Returns ISO 8601 strings (when using `.select()` without `.single()`)
- **Depends on**: Query type, response format, client version

The original code assumed timestamps were always strings:
```dart
// BEFORE (broken):
startTime: TimezoneUtils.parseUtc(json['start_time'] as String)
```

When Supabase returned a `DateTime` object, the `as String` cast failed silently or produced incorrect results, causing the timestamp to be interpreted incorrectly and leading to the off-by-one date error.

**Why the solution addresses this:**
1. **Type-safe parsing**: Explicitly checks runtime type before parsing
2. **Handles both paths**: Works whether Supabase returns DateTime or String
3. **Preserves UTC storage**: Ensures all timestamps are converted to UTC consistently
4. **Maintains existing logic**: For String values, uses same `TimezoneUtils.parseUtc()` that was working
5. **Clear error messages**: If Supabase returns an unexpected type, we get a clear error instead of silent failure

**Underlying Issue:**
This is a Supabase client library quirk where the serialization behavior isn't guaranteed. The client may optimize certain query types by pre-parsing timestamps to DateTime objects, but other queries return raw JSON strings. Defensive programming requires handling both cases.

## Prevention

**To avoid Supabase timestamp parsing issues in future Flutter/Dart development:**

1. **Never assume Supabase timestamp types:**
   ```dart
   ✅ CORRECT: Type-safe parsing
   DateTime parseTimestamp(dynamic value) {
     if (value is DateTime) return value.toUtc();
     if (value is String) return TimezoneUtils.parseUtc(value);
     throw ArgumentError('Invalid type: ${value.runtimeType}');
   }

   ❌ WRONG: Assuming string type
   startTime: TimezoneUtils.parseUtc(json['start_time'] as String)
   ```

2. **Create reusable parsing helpers:**
   - Define parseTimestamp() helper in model classes
   - Reuse across all timestamp fields
   - Centralize type-checking logic

3. **Test with different Supabase query patterns:**
   - `.select().single()` (may return DateTime objects)
   - `.select()` (may return strings)
   - RPC function results (may vary)
   - Real-time subscription updates (may differ from queries)

4. **Validate UTC conversion:**
   - All timestamps from database should be UTC
   - Use `.toUtc()` for DateTime objects
   - Use `TimezoneUtils.parseUtc()` for strings
   - Display in local timezone: `.toLocal()`

5. **Document timestamp handling in model classes:**
   ```dart
   /// Parses timestamps from Supabase.
   ///
   /// Supabase may return TIMESTAMPTZ as DateTime objects OR ISO 8601 strings
   /// depending on the query type. This helper handles both cases.
   ```

6. **Add debug logging for type mismatches:**
   ```dart
   if (value is! DateTime && value is! String) {
     print('WARNING: Unexpected timestamp type: ${value.runtimeType}');
   }
   ```

7. **Verify database storage is correct:**
   - Use Supabase SQL Editor to check raw TIMESTAMPTZ values
   - Compare UTC timestamps with expected values
   - Confirm `AT TIME ZONE 'UTC'` queries show correct times

## Related Issues

- See also: [timezone-date-handling-standardization-calendar-20260201.md](../best-practices/timezone-date-handling-standardization-calendar-20260201.md) - Related work on standardizing timezone helpers across the app

## Additional Context

**Database Verification:**
The database was storing timestamps correctly in UTC:
```sql
SELECT id, title, start_time,
       start_time AT TIME ZONE 'America/Los_Angeles' as pst_time
FROM events
WHERE title = 'Party';

-- Result:
-- start_time: 2026-02-06 01:00:00+00 (UTC)
-- pst_time: 2026-02-05 17:00:00 (PST)
```

This confirmed the issue was in parsing/display, not storage.

**Supabase Client Behavior:**
The inconsistency in return types is a known characteristic of the Supabase Dart client. The library tries to optimize performance by pre-parsing certain response types, but this creates unpredictability in client code. Defensive type checking is the recommended approach.

**All-Day Event Special Case:**
The EventModel parseTimestamp() helper has a `ensureUtc` parameter to handle all-day events differently. All-day events are stored without time components and shouldn't be forced to UTC (which could shift the date). This is handled by passing `!allDay` to the helper.
