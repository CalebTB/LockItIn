---
module: Timezone Utils
date: 2026-01-09
problem_type: runtime_error
component: datetime_parsing
symptoms:
  - "Invalid argument(s): Invalid ISO 8601 format: 2026-01-10T01:00:00+00:00"
  - "Datetime parsing fails on Supabase responses"
  - "Events not refreshing when device timezone changes"
root_cause: regex_too_strict
severity: moderate
stage: Phase 2 Testing
tags: [timezone, datetime-parsing, iso8601, lifecycle-detection]
related_issues:
  - "PR #234 - Phase 2: Timezone Support & Bug Fixes"
  - "Issue #204 - Create Core Timezone Utilities"
  - "Issue #205 - Update Data Models with UTC Conversion"
  - "Issue #206 - Update Service Layer and DateTime.now() Usage"
  - "Issue #207 - Fix UI Display Layer DateFormat Usage"
  - "Issue #208 - Update Date Pickers to Convert to UTC"
  - "Issue #209 - Review and Fix Native Calendar Sync"
  - "Issue #210 - Integration Testing and Manual Validation"
  - "Issue #211 - Timezone Support for Cross-Timezone Users (Epic)"
---

# Timezone Datetime Parsing & Change Detection Issues

## Problem

**Severity:** 🟡 MODERATE - Runtime Errors & Stale Data

### Bug #6: Datetime Parsing Failures

**Observable Symptoms:**
```
Invalid argument(s): Invalid ISO 8601 format: 2026-01-10T01:00:00+00:00
```

**When it occurs:**
- Fetching events from Supabase
- Database returns timestamps in `+00:00` timezone offset format
- App crashes trying to parse the datetime string

### Bug #7: Timezone Changes Not Refreshing UI

**Observable Symptoms:**
- User changes device timezone in Settings
- Resumes app
- Event times still show in old timezone
- No automatic refresh triggered

**User Report:**
> "When I change timezones and open the app again it doesn't refresh the time changes to show the time change"

## Investigation

### Bug #6: Datetime Parsing

**Root Cause:** Regex pattern in `TimezoneUtils.parseUtc()` only accepted `Z` format, rejected `+00:00` offset format.

**File:** `lib/core/utils/timezone_utils.dart`

```dart
static DateTime parseUtc(String isoString) {
  // ❌ OLD REGEX: Only accepts Z format
  final iso8601Regex = RegExp(
    r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z?$'
  );

  // This REJECTS valid ISO 8601 formats:
  // ❌ 2026-01-10T01:00:00+00:00  (timezone offset format)
  // ❌ 2026-01-10T01:00:00.123456Z (microseconds)
}
```

**Why Supabase returns +00:00 format:**
- PostgreSQL TIMESTAMPTZ columns default to ISO 8601 with timezone offset
- Supabase client serializes as `2026-01-10T01:00:00+00:00`
- Both `Z` and `+00:00` are valid representations of UTC
- Our regex only accepted `Z` → parsing failed

**Example failure:**
```dart
// Supabase returns this JSON:
{
  "start_time": "2026-01-10T01:00:00+00:00",
  "end_time": "2026-01-10T02:00:00+00:00"
}

// TimezoneUtils.parseUtc() throws:
// Invalid argument(s): Invalid ISO 8601 format: 2026-01-10T01:00:00+00:00
```

### Bug #7: Timezone Change Detection

**Root Cause:** No lifecycle observation to detect when app resumes after timezone change.

**File:** `lib/presentation/providers/calendar_provider.dart`

**Original implementation:**
```dart
class CalendarProvider extends ChangeNotifier {
  // ❌ No lifecycle observation
  // ❌ No timezone change detection
  // ❌ Events loaded once, never refreshed
}
```

**Why this breaks:**
1. User opens app in PST (UTC-8) → events loaded with PST local times
2. User travels to EST (UTC-5) → changes device timezone
3. User resumes app → CalendarProvider state still has PST times
4. No detection of timezone change → no refresh triggered
5. Events display with wrong local times

**Expected behavior:**
- Detect timezone change on app resume
- Reload events from Supabase (stored in UTC)
- Convert UTC times to new local timezone
- Refresh UI with updated times

## Solution

### Fix #1: Update Datetime Parsing Regex

**File:** `lib/core/utils/timezone_utils.dart`

```dart
static DateTime parseUtc(String isoString) {
  // ✅ NEW REGEX: Accepts Z and +00:00 formats
  final iso8601Regex = RegExp(
    r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3,6})?(Z|[+-]\d{2}:\d{2})?$'
  );

  if (!iso8601Regex.hasMatch(isoString)) {
    throw ArgumentError('Invalid ISO 8601 format: $isoString');
  }

  try {
    final parsed = DateTime.parse(isoString);
    return parsed.isUtc ? parsed : parsed.toUtc();
  } catch (e) {
    throw ArgumentError('Failed to parse datetime: $isoString (error: $e)');
  }
}
```

**What changed:**
- `(\.\d{3})?` → `(\.\d{3,6})?` - Accept milliseconds or microseconds
- `Z?` → `(Z|[+-]\d{2}:\d{2})?` - Accept Z or timezone offset format

**Now accepts all these formats:**
```dart
✅ 2026-01-10T01:00:00Z
✅ 2026-01-10T01:00:00+00:00
✅ 2026-01-10T01:00:00-05:00
✅ 2026-01-10T01:00:00.123Z
✅ 2026-01-10T01:00:00.123456Z
✅ 2026-01-10T01:00:00.123+00:00
```

### Fix #2: Add Timezone Change Detection

**File:** `lib/presentation/providers/calendar_provider.dart`

```dart
class CalendarProvider extends ChangeNotifier with WidgetsBindingObserver {
  /// Timezone offset (in hours) when events were last loaded
  /// Used to detect timezone changes and refresh events
  int? _lastTimezoneOffsetHours;

  CalendarProvider({DateTime? initialDate})
      : _focusedDate = initialDate ?? TimezoneUtils.nowUtc() {
    _initializeMonths();
    _loadEvents();

    // ✅ Register as lifecycle observer to detect timezone changes
    WidgetsBinding.instance.addObserver(this);

    // ✅ Store initial timezone offset
    _lastTimezoneOffsetHours = DateTime.now().timeZoneOffset.inHours;
    Logger.info(
      'CalendarProvider',
      'Initial timezone offset: $_lastTimezoneOffsetHours hours',
    );
  }

  /// ✅ Lifecycle observer: Detect when app resumes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndRefreshOnTimezoneChange();
    }
  }

  /// ✅ Check if timezone changed and refresh events if needed
  void _checkAndRefreshOnTimezoneChange() {
    final currentOffsetHours = DateTime.now().timeZoneOffset.inHours;

    if (_lastTimezoneOffsetHours != null &&
        _lastTimezoneOffsetHours != currentOffsetHours) {
      Logger.info(
        'CalendarProvider',
        'Timezone changed from $_lastTimezoneOffsetHours to $currentOffsetHours hours - refreshing events',
      );

      // Update stored offset
      _lastTimezoneOffsetHours = currentOffsetHours;

      // Reload events to refresh with new timezone
      _loadEvents();

      // Force UI update
      notifyListeners();
    }
  }

  /// ✅ Clean up observer when provider is disposed
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
```

**What this does:**
1. **On app launch:** Store initial timezone offset (e.g., -8 for PST)
2. **On app resume:** Check if timezone offset changed
3. **If changed:** Reload events from Supabase (UTC timestamps)
4. **Convert to local:** EventModel.fromJson() converts UTC → new local time
5. **Refresh UI:** notifyListeners() triggers rebuild with updated times

**Example flow:**

```dart
// 1. User in PST (UTC-8) opens app
_lastTimezoneOffsetHours = -8
Event: 2026-01-10T09:00:00Z → displays as "1:00 AM PST"

// 2. User travels to EST (UTC-5), changes device timezone
// 3. User resumes app → didChangeAppLifecycleState(AppLifecycleState.resumed)

currentOffsetHours = -5  // Device now in EST
_lastTimezoneOffsetHours = -8  // Still PST

// Timezone changed! (-8 → -5)
_loadEvents()  // Re-fetch from Supabase
Event: 2026-01-10T09:00:00Z → displays as "4:00 AM EST" ✅

_lastTimezoneOffsetHours = -5  // Update stored offset
notifyListeners()  // Refresh UI
```

## Prevention

### Datetime Parsing Best Practices

**ALWAYS use TimezoneUtils for datetime parsing:**

```dart
// ✅ CORRECT - Handles all ISO 8601 formats
final utcTime = TimezoneUtils.parseUtc(jsonResponse['start_time']);

// ❌ WRONG - May fail on valid ISO 8601 strings
final utcTime = DateTime.parse(jsonResponse['start_time']).toUtc();
```

**Why TimezoneUtils is better:**
- Validates format before parsing (prevents crashes)
- Accepts multiple ISO 8601 formats (Z, +00:00, etc.)
- Always returns UTC (consistent with storage policy)
- Provides clear error messages

### Timezone Storage & Display Policy

**STORAGE: Always UTC**
```dart
// Store in database as UTC
final utcString = TimezoneUtils.toUtcString(dateTime);
await supabase.from('events').insert({
  'start_time': utcString,  // 2026-01-10T09:00:00.000Z
});
```

**DISPLAY: Always Local**
```dart
// Display to user in local timezone
final localTime = utcTime.toLocal();
final formatted = TimezoneUtils.formatLocal(utcTime, 'h:mm a');
// "1:00 AM" (in user's current timezone)
```

**TESTING: Use Clock package**
```dart
// Mock time for tests
import 'package:clock/clock.dart';

test('handles timezone changes', () {
  withClock(Clock.fixed(DateTime.utc(2026, 1, 10, 9, 0)), () {
    final now = TimezoneUtils.nowUtc();
    expect(now, DateTime.utc(2026, 1, 10, 9, 0));
  });
});
```

### Lifecycle Observation for Timezone Changes

**Pattern to follow for any Provider that displays times:**

```dart
class MyProvider extends ChangeNotifier with WidgetsBindingObserver {
  int? _lastTimezoneOffsetHours;

  MyProvider() {
    // Register observer
    WidgetsBinding.instance.addObserver(this);
    _lastTimezoneOffsetHours = DateTime.now().timeZoneOffset.inHours;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final current = DateTime.now().timeZoneOffset.inHours;
      if (_lastTimezoneOffsetHours != current) {
        _lastTimezoneOffsetHours = current;
        _refreshData();  // Reload data with new timezone
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

**When to use this pattern:**
- Provider displays datetime values to user
- Data comes from UTC database storage
- User might change device timezone

## Testing

### Test Datetime Parsing

```dart
// Test all ISO 8601 formats
test('parseUtc handles all valid ISO 8601 formats', () {
  // Z format
  expect(
    TimezoneUtils.parseUtc('2026-01-10T01:00:00Z'),
    DateTime.utc(2026, 1, 10, 1, 0, 0),
  );

  // +00:00 format (what Supabase returns)
  expect(
    TimezoneUtils.parseUtc('2026-01-10T01:00:00+00:00'),
    DateTime.utc(2026, 1, 10, 1, 0, 0),
  );

  // With milliseconds
  expect(
    TimezoneUtils.parseUtc('2026-01-10T01:00:00.123Z'),
    DateTime.utc(2026, 1, 10, 1, 0, 0, 123),
  );

  // With microseconds
  expect(
    TimezoneUtils.parseUtc('2026-01-10T01:00:00.123456Z'),
    DateTime.utc(2026, 1, 10, 1, 0, 0, 123, 456),
  );
});
```

### Manual Testing: Timezone Change

**Steps to verify timezone change detection:**

1. Open app, create event at specific time (e.g., "2:00 PM")
2. Note current timezone (e.g., "PST")
3. Go to device Settings → General → Date & Time
4. Change timezone (e.g., PST → EST, 3 hour difference)
5. Resume app (bring to foreground)
6. ✅ Event should now show "5:00 PM" (3 hours ahead)
7. Check logs for: "Timezone changed from -8 to -5 hours - refreshing events"

**Expected behavior:**
- No user action required
- Times automatically update on app resume
- All datetime displays refresh with new timezone

## Technical Details

### ISO 8601 Format Variations

**Valid representations of the same instant:**

```
2026-01-10T09:00:00Z           # Z = UTC
2026-01-10T09:00:00+00:00      # +00:00 = UTC
2026-01-10T01:00:00-08:00      # -08:00 = PST
2026-01-10T04:00:00-05:00      # -05:00 = EST

All represent the same UTC instant: 2026-01-10 09:00:00 UTC
```

**Why databases use +00:00:**
- PostgreSQL TIMESTAMPTZ default format
- Explicit timezone offset (more informative than Z)
- Unambiguous across different locales
- Standard JSON serialization format

### App Lifecycle States

**Flutter lifecycle states:**

```dart
enum AppLifecycleState {
  resumed,    // App visible and responding to user input
  inactive,   // App visible but not responding (e.g., phone call)
  paused,     // App not visible (backgrounded)
  detached,   // App about to terminate
  hidden,     // App hidden (iOS only)
}
```

**When timezone changes are detected:**

```
User backgrounds app (Settings)
  ↓
AppLifecycleState.paused

User changes timezone in Settings
  (App is paused, no code running)

User returns to app
  ↓
AppLifecycleState.resumed
  ↓
didChangeAppLifecycleState() called
  ↓
_checkAndRefreshOnTimezoneChange()
  ↓
Timezone offset changed? → Refresh events
```

### Why Compare Hours, Not Full Offset

```dart
// ✅ CORRECT - Compare hours
final currentOffsetHours = DateTime.now().timeZoneOffset.inHours;

// ❌ WRONG - Don't compare Duration objects
final currentOffset = DateTime.now().timeZoneOffset;
```

**Reasons:**
- Timezone offsets are always whole hours (except rare cases like Nepal UTC+5:45)
- Comparing hours is simpler and more readable
- Avoids issues with daylight saving time minute offsets
- More efficient than Duration comparison

## Resolution Timeline

**Bug #6 (Datetime Parsing):**
1. Error discovered during event loading from Supabase
2. Identified regex pattern only accepted Z format
3. Updated regex to accept multiple ISO 8601 formats ✅
4. Verified with test cases for all formats

**Bug #7 (Timezone Change Detection):**
1. User reported times not updating after timezone change
2. Identified missing lifecycle observation
3. Added WidgetsBindingObserver mixin to CalendarProvider
4. Implemented timezone change detection on app resume ✅
5. Verified with manual testing (PST → EST timezone change)

**Time to resolution:** ~30 minutes for both bugs

## Important Pattern

⭐ **This solution has been promoted to Required Reading:**
[Pattern 4: Timezone Change Detection](../../patterns/critical-patterns.md#pattern-4-timezone-change-detection)

Providers displaying datetime values should implement WidgetsBindingObserver for timezone change detection.

## Tags

#timezone #datetime-parsing #iso8601 #lifecycle-detection #app-resume #timezone-change
