# Plan: 24-Hour Timelines and Multi-Day Event Support

**Related to:** Issue #227 (to be created)
**Affects:** Group calendar day view, Week view, Personal day timeline
**Priority:** Medium (UX improvement)

---

## Problem Statement

### Issue 1: Inconsistent Timeline Hour Ranges

Different timeline views show different hour ranges:

| View | Current Range | Should Be |
|------|---------------|-----------|
| Personal Day Timeline (`day_timeline_view.dart`) | ✅ 12 AM - 11 PM (0-23) | Already correct |
| Group Day Timeline (`group_day_timeline_view.dart`) | ❌ 7 AM - 11 PM (7-23) | 12 AM - 11 PM (0-23) |
| Week Grid View (`week_grid_view.dart`) | ❌ 6 AM - 12 AM (6-24) | 12 AM - 11 PM (0-23) |

**User impact:**
- Events scheduled before 6-7 AM are hidden
- Inconsistent experience between views
- Late-night events (after 11 PM) may be cut off in group view

### Issue 2: Multi-Day Events Display Incorrectly

Events that **start one day and end the next** (e.g., 10 PM - 2 AM) are rendered incorrectly:

**Current behavior:**
```dart
// day_timeline_view.dart, line 348
final totalDurationMinutes = event.endTime.difference(event.startTime).inMinutes;
```

For an event starting **Jan 5 at 10 PM** and ending **Jan 6 at 2 AM**:
- Start: Jan 5, 22:00
- End: Jan 6, 02:00
- Duration: 4 hours (240 minutes) ✅ Correct calculation

**BUT when positioned on the timeline:**
```dart
// line 344-345
final startMinutes = event.startTime.hour * 60 + event.startTime.minute;
final topOffset = startMinutes.toDouble();
```

- `startMinutes = 22 * 60 + 0 = 1320` (10 PM)
- Event renders at position 1320px from top
- Event height = 240px (4 hours)
- **Event extends from 10 PM to 2 AM visually** ❌

**Problems:**
1. **Visual overflow:** Event extends beyond 11:59 PM boundary into empty space
2. **No continuation indicator:** Next day's timeline doesn't show the event continues
3. **All-day detection fails:** Events crossing midnight aren't treated as all-day
4. **Week view:** Event shows on Day 1 only, not on Day 2

**User impact:**
- Late-night events (party ending at 2 AM, overnight shift, etc.) look broken
- User can't see that event continues into next day
- May appear as 30-min event if only the portion after midnight is visible

---

## Current Code Analysis

### Personal Day Timeline (`day_timeline_view.dart`)
**Already shows 24 hours:**
```dart
// Line 211
height: 24 * _hourHeight, // Total height for 24 hours

// Line 216-222: Generates 0-23 hours
Column(
  children: List.generate(24, (hour) {
    return _buildHourRow(context, colorScheme, hour);
  }),
),
```

✅ No changes needed for hour range

### Group Day Timeline (`group_day_timeline_view.dart`)
**Currently limited to 7 AM - 11 PM:**
```dart
// Lines 50-51
static const int _startHour = 7;
static const int _endHour = 23;

// Line 270: Only renders 7-23
final hours = List.generate(_endHour - _startHour + 1, (i) => _startHour + i);
```

❌ Needs to change to 0-23

### Week Grid View (`week_grid_view.dart`)
**Currently 6 AM - 12 AM (midnight):**
```dart
// Lines 30-31
this.startHour = 6,
this.endHour = 24,
```

❌ Needs to change to 0-24 (or 0-23 with special midnight handling)

### Multi-Day Event Rendering

**Current logic (all timeline views):**
```dart
// Calculate position and height
final startMinutes = event.startTime.hour * 60 + event.startTime.minute;
final topOffset = startMinutes.toDouble();
final totalDurationMinutes = event.endTime.difference(event.startTime).inMinutes;
final totalHeight = totalDurationMinutes.toDouble();
```

❌ Doesn't handle events crossing midnight:
- Event starting 10 PM on Day 1, ending 2 AM on Day 2
- Renders entire 4-hour block on Day 1 timeline
- Extends beyond day boundary visually

---

## Implementation Plan

### Phase 1: Standardize Timeline to 24 Hours

#### 1A. Update Group Day Timeline (`group_day_timeline_view.dart`)

**Changes:**
```dart
// Lines 50-51: Change start/end hours
static const int _startHour = 0;  // Was: 7
static const int _endHour = 23;   // Was: 23 (keep same)

// Update all references to match 0-23 range
// Lines affected:
// - 270: Hour generation
// - 280: Total height calculation
// - 305: Hour row positioning
// - 342-343: Time slot positioning
// - 424: Current time indicator validation
// - 428: Current time position
// - 462-463: Event positioning
// - 746-755: Event clamping logic
// - 856: Gap calculation starting point
```

**Auto-scroll behavior:**
- Update default scroll position (line 856) to still start around 7-8 AM for better UX
- Don't force user to scroll from midnight if no early events

#### 1B. Update Week Grid View (`week_grid_view.dart`)

**Changes:**
```dart
// Lines 30-31: Standardize to 0-24
this.startHour = 0,   // Was: 6
this.endHour = 24,    // Already 24 (midnight of next day)

// Update event positioning logic (lines 267-268)
// Already uses startHour in calculation, should work once changed
```

**Auto-scroll behavior:**
- Keep current auto-scroll to first event or 8 AM

---

### Phase 2: Multi-Day Event Support

#### Strategy: Clamp + Continuation Indicators

Instead of trying to render events across multiple day timelines (complex), we:
1. **Clamp event to day boundary** (render until 11:59 PM on Day 1)
2. **Add visual continuation indicator** (show "→" or "Continues tomorrow")
3. **Render continuation on next day** (show from 12:00 AM on Day 2)

#### 2A. Update Event Positioning Logic

**File: `day_timeline_view.dart` (and similar for other views)**

**Current code (line 343-349):**
```dart
// Calculate vertical position from midnight (0:00)
final startMinutes = event.startTime.hour * 60 + event.startTime.minute;
final topOffset = startMinutes.toDouble();

// Calculate total height for the event
final totalDurationMinutes = event.endTime.difference(event.startTime).inMinutes;
final totalHeight = totalDurationMinutes.toDouble().clamp(_eventMinHeight, double.infinity);
```

**New code with multi-day handling:**
```dart
// Calculate vertical position from midnight (0:00)
final startMinutes = event.startTime.hour * 60 + event.startTime.minute;
final topOffset = startMinutes.toDouble();

// Check if event crosses midnight
final isSameDay = event.startTime.year == event.endTime.year &&
                  event.startTime.month == event.endTime.month &&
                  event.startTime.day == event.endTime.day;

final bool continuesNextDay;
final double totalHeight;

if (isSameDay) {
  // Normal single-day event
  final totalDurationMinutes = event.endTime.difference(event.startTime).inMinutes;
  totalHeight = totalDurationMinutes.toDouble().clamp(_eventMinHeight, double.infinity);
  continuesNextDay = false;
} else {
  // Multi-day event: Clamp to end of current day
  final endOfDay = DateTime(
    event.startTime.year,
    event.startTime.month,
    event.startTime.day,
    23,
    59,
  );

  final durationToMidnight = endOfDay.difference(event.startTime).inMinutes;
  totalHeight = (durationToMidnight + 1).toDouble().clamp(_eventMinHeight, double.infinity);
  continuesNextDay = true;
}
```

#### 2B. Add Continuation Indicator to Event Card

**File: `day_timeline_view.dart`, `_buildEventCard()` method (line 370)**

**Add visual indicator for events that continue:**
```dart
Widget _buildEventCard(
  BuildContext context,
  ColorScheme colorScheme,
  EventModel event,
) {
  final privacyColor = _getPrivacyColor(context, event.visibility);

  // Check if event crosses midnight
  final isSameDay = event.startTime.year == event.endTime.year &&
                    event.startTime.month == event.endTime.month &&
                    event.startTime.day == event.endTime.day;
  final continuesNextDay = !isSameDay && event.endTime.isAfter(event.startTime);

  // ... existing duration calculations ...

  return Material(
    color: privacyColor.withValues(alpha: 0.15),
    borderRadius: BorderRadius.circular(6),
    child: InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => _navigateToEventDetail(context, event),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: privacyColor, width: 3),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Time range
            Row(
              children: [
                Expanded(
                  child: Text(
                    timeRange,
                    style: TextStyle(...),
                  ),
                ),
                // NEW: Continuation indicator
                if (continuesNextDay)
                  Tooltip(
                    message: 'Continues tomorrow',
                    child: Icon(
                      Icons.arrow_forward,
                      size: 12,
                      color: privacyColor,
                    ),
                  ),
              ],
            ),
            // ... rest of event card content ...
          ],
        ),
      ),
    ),
  );
}
```

#### 2C. Handle Event Continuation on Next Day

**File: `CalendarProvider` or event fetching logic**

When fetching events for a specific day, **include events that started yesterday but continue into today:**

**Current query (likely in `event_service.dart`):**
```dart
// Only gets events WHERE start_time is on this day
.gte('start_time', dayStart.toIso8601String())
.lt('start_time', dayEnd.toIso8601String())
```

**New query with continuation support:**
```dart
// Get events that:
// 1. Start on this day, OR
// 2. Start before this day but end during/after this day
.or('start_time.gte.${dayStart.toIso8601String()},and(start_time.lt.${dayStart.toIso8601String()},end_time.gt.${dayStart.toIso8601String()})')
```

**Alternative approach (simpler, may over-fetch):**
```dart
// Get all events that overlap with this day
.gte('end_time', dayStart.toIso8601String())
.lt('start_time', dayEnd.toIso8601String())
```

Then filter/adjust in Flutter:
```dart
List<EventModel> getEventsForDay(DateTime day) {
  final dayStart = DateTime(day.year, day.month, day.day);
  final dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59);

  return allEvents.where((event) {
    // Event overlaps with this day if:
    // - Starts on or before day end AND
    // - Ends on or after day start
    return event.startTime.isBefore(dayEnd.add(Duration(seconds: 1))) &&
           event.endTime.isAfter(dayStart);
  }).map((event) {
    // If event started yesterday, adjust displayed start time to midnight
    if (event.startTime.isBefore(dayStart)) {
      return event.copyWith(
        startTime: dayStart,
        // Store original start in metadata or handle in UI layer
      );
    }
    return event;
  }).toList();
}
```

#### 2D. Visual Treatment for Continued Events

**Event that started yesterday:**
```
┌────────────────────────────┐
│ 12:00 AM ←                 │  ← Left arrow = "Started yesterday"
│ Party @ Jake's House       │
│ 📍 123 Main St             │
└────────────────────────────┘
```

**Event that continues tomorrow:**
```
┌────────────────────────────┐
│ 10:00 PM - 11:59 PM →      │  ← Right arrow = "Continues tomorrow"
│ Overnight Shift            │
│ 📍 Hospital                │
└────────────────────────────┘
```

**Event spanning multiple days (both):**
```
┌────────────────────────────┐
│ ← 12:00 AM - 11:59 PM →    │  ← Both arrows
│ Conference Day 2           │
└────────────────────────────┘
```

---

### Phase 3: All-Day Event Detection Update

**Current logic (line 594-600):**
```dart
bool _isAllDayEvent(EventModel event) {
  final duration = event.endTime.difference(event.startTime);
  final isExactly24Hours = duration.inHours == 24 || duration.inDays >= 1;
  final startsMidnight = event.startTime.hour == 0 && event.startTime.minute == 0;
  final endsMidnight = event.endTime.hour == 0 && event.endTime.minute == 0;

  return isExactly24Hours || (startsMidnight && endsMidnight);
}
```

**Issue:** An event from 10 PM - 2 AM (4 hours) might incorrectly be treated as all-day

**Updated logic:**
```dart
bool _isAllDayEvent(EventModel event) {
  final startsMidnight = event.startTime.hour == 0 && event.startTime.minute == 0;
  final endsMidnightOrLater = event.endTime.hour == 0 && event.endTime.minute == 0;

  // Check if it's a same-day event
  final isSameDay = event.startTime.year == event.endTime.year &&
                    event.startTime.month == event.endTime.month &&
                    event.startTime.day == event.endTime.day;

  // All-day if:
  // 1. Starts at midnight, ends at midnight (same day or next day), AND duration >= 20 hours
  // 2. Spans multiple full days
  if (startsMidnight && endsMidnightOrLater) {
    final duration = event.endTime.difference(event.startTime);
    return duration.inHours >= 20;  // At least 20 hours = likely all-day
  }

  return false;
}
```

---

## Implementation Checklist

### Phase 1: 24-Hour Timeline
- [ ] Update `group_day_timeline_view.dart` constants (lines 50-51)
- [ ] Update all positioning calculations in group day timeline
- [ ] Update `week_grid_view.dart` startHour to 0 (line 30)
- [ ] Test auto-scroll behavior (should still default to 7-8 AM area)
- [ ] Test current time indicator positioning
- [ ] Verify event positioning with early morning events (1-6 AM)
- [ ] Verify event positioning with late night events (11 PM - midnight)

### Phase 2: Multi-Day Event Support
- [ ] Add `isSameDay` helper to event positioning logic
- [ ] Update event height calculation to clamp at day boundary
- [ ] Add `continuesNextDay` property to event card rendering
- [ ] Add right arrow icon (→) for events continuing tomorrow
- [ ] Add left arrow icon (←) for events started yesterday
- [ ] Update `getEventsForDay()` to include continuation events
- [ ] Handle displayed start time adjustment for continued events
- [ ] Test event 10 PM - 2 AM (same start day, next end day)
- [ ] Test event 12 AM - 11:59 PM (full day)
- [ ] Test event starting yesterday, ending today

### Phase 3: All-Day Detection
- [ ] Update `_isAllDayEvent()` logic with duration threshold
- [ ] Test all-day detection for midnight-to-midnight events
- [ ] Test that 4-hour overnight events (10 PM - 2 AM) are NOT all-day
- [ ] Test that 24+ hour events ARE all-day

### Testing Scenarios
- [ ] Event 1 AM - 3 AM (early morning, same day)
- [ ] Event 11 PM - 11:59 PM (late night, same day)
- [ ] Event 10 PM - 2 AM (crosses midnight)
- [ ] Event 8 PM - 8 AM next day (long overnight)
- [ ] Event 12 AM - 12 AM next day (24 hours, all-day)
- [ ] Event spanning 3+ days (conference)
- [ ] Week view with multi-day event
- [ ] Group calendar day view with 24-hour range

---

## Edge Cases to Consider

1. **Event from 11:59 PM - 12:01 AM**
   - Very short, crosses midnight
   - Should show as 2-minute event on Day 1 (until 11:59 PM)
   - Should show continuation on Day 2 (from 12:00 AM - 12:01 AM)

2. **Event spanning 3+ days (e.g., conference)**
   - Day 1: Show start → end of day (with → indicator)
   - Day 2: Show all day (with ← and →)
   - Day 3: Show midnight → actual end (with ← indicator)

3. **All-day event (12 AM - 12 AM)**
   - Should be in all-day section, NOT in timeline

4. **Event ending at exactly midnight (10 PM - 12 AM)**
   - Should NOT show continuation
   - Should end at 11:59 PM visually

5. **Overlapping multi-day events**
   - Two events both 10 PM - 2 AM
   - Should use existing column layout algorithm
   - Both should show continuation indicators

---

## Design Questions

1. **Continuation indicator style:**
   - Option A: Small arrow icon (→/←)
   - Option B: Text label ("Continues..." / "...Continued")
   - Option C: Dashed border at top/bottom
   - **Recommendation:** Option A (clean, minimal, follows iOS Calendar)

2. **Adjusted start time display:**
   - Event started 10 PM yesterday, viewing today
   - Option A: Show "12:00 AM - 2:00 AM" (actual time on THIS day)
   - Option B: Show "Started yesterday - 2:00 AM"
   - **Recommendation:** Option A for consistency, add ← indicator

3. **Default timeline scroll position:**
   - After changing to 24 hours (0-23)
   - Option A: Scroll to 7-8 AM by default (current UX)
   - Option B: Scroll to first event (even if 2 AM)
   - Option C: Scroll to current time (if today)
   - **Recommendation:** Option C (if today), else Option B, fallback Option A

4. **All-day threshold:**
   - How many hours = "all-day" for multi-day events?
   - Option A: Exactly 24 hours
   - Option B: 20+ hours (allows for 12 AM - 8 PM = all-day)
   - Option C: Must be midnight-to-midnight
   - **Recommendation:** Option C (strictest, clearest)

---

## Success Metrics

**User Value:**
- ✅ Can schedule events at any hour (not limited to 6 AM+)
- ✅ Late-night events (parties, shifts) display correctly
- ✅ Multi-day events are clear and understandable
- ✅ Consistent timeline range across all views

**Technical:**
- ✅ No visual overflow beyond day boundaries
- ✅ Continuation indicators show correctly
- ✅ All-day detection is accurate
- ✅ Performance unchanged (no extra queries)

---

## Files to Modify

1. **`lib/presentation/widgets/day_timeline_view.dart`**
   - Update multi-day event positioning (lines 343-349)
   - Add continuation indicator to `_buildEventCard()` (line 370)
   - Update `_isAllDayEvent()` logic (line 594)

2. **`lib/presentation/widgets/group_day_timeline_view.dart`**
   - Change `_startHour = 0` (line 50)
   - Update all hour calculations
   - Add multi-day support
   - Add continuation indicators

3. **`lib/presentation/widgets/week_grid_view.dart`**
   - Change `startHour = 0` (line 30)
   - Verify event positioning logic
   - Add multi-day support

4. **`lib/presentation/providers/calendar_provider.dart`** (or equivalent)
   - Update `getEventsForDay()` to include continuation events
   - Handle adjusted start times for continued events

5. **`lib/core/services/event_service.dart`** (if needed)
   - Update event fetching query to include overlapping events
