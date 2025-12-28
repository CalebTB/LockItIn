# Availability Logic Documentation

## Overview

This document explains the logic used to determine if a user is "available" during a given time range on the group calendar. The goal is to answer the practical question: **"Can we actually schedule something here?"**

## Implementation Location

- **File:** `lib/presentation/screens/group_detail_screen.dart`
- **Method:** `_getAvailabilityForDay()`
- **Helper:** `_findLongestFreeBlock()`

## The Contiguous Free Time Approach

### Core Principle

Instead of checking percentage of free time or rejecting any overlap, we check:

> **Is there at least 2 hours of UNINTERRUPTED free time within the selected time range?**

This approach is user-centric because:
1. Most casual meetups are 1-3 hours
2. Users care about "can we meet?" not "what percentage is free?"
3. Events at the edges of a time range shouldn't disqualify the entire range

### Configuration

```dart
static const int _minContiguousFreeMinutes = 120; // 2 hours
```

This value can be adjusted based on user research or made configurable per group.

## Time Filters

| Filter | Time Range | Duration |
|--------|-----------|----------|
| All Day | 12am - 12am | 24 hours |
| Morning | 6am - 12pm | 6 hours |
| Afternoon | 12pm - 5pm | 5 hours |
| Evening | 5pm - 10pm | 5 hours |
| Night | 10pm - 6am | 8 hours (crosses midnight) |

## Algorithm

### Step 1: Get Overlapping Events
```dart
final overlappingEvents = events
    .where((e) => e.startTime.isBefore(rangeEnd) && e.endTime.isAfter(rangeStart))
    .toList()
  ..sort((a, b) => a.startTime.compareTo(b.startTime));
```

### Step 2: Find Free Blocks
Walk through events chronologically and measure gaps:

```
Range:    [============================================]
          6am                                        12pm

Events:   [===]              [========]
          6-7am              9-10:30am

Free:          [============]          [=============]
               7-9am (2hrs)            10:30am-12pm (1.5hrs)

Longest free block: 2 hours -> AVAILABLE
```

### Step 3: Check Threshold
```dart
if (longestFreeMinutes < _minContiguousFreeMinutes) {
  return 0; // Busy
}
return 1; // Available
```

## Examples

### Morning Filter (6am - 12pm, 6 hours total)

| Events | Longest Free Block | Result |
|--------|-------------------|--------|
| None | 6 hours | Available |
| 6-7am meeting | 5 hours (7am-12pm) | Available |
| 11-12pm meeting | 5 hours (6-11am) | Available |
| 9-10am meeting | 3 hours (6-9am) | Available |
| 8-11am meeting | 2 hours (6-8am) | Available |
| 7-11am meeting | 1 hour (6-7am or 11am-12pm) | **Busy** |
| 6-7am AND 10-12pm | 3 hours (7-10am) | Available |
| 6-8am AND 10-12pm | 2 hours (8-10am) | Available |
| 6-8am AND 9-12pm | 1 hour (8-9am) | **Busy** |

### Key Insight

A 1-hour meeting at 9am (middle of morning) still leaves:
- 3 hours before (6-9am)
- 2 hours after (10am-12pm)

Both blocks are usable, so the user is **available**.

## Special Cases

### Holidays
Events with `category: 'holiday'` are excluded from availability calculations. Holidays don't block scheduling.

```dart
final events = calendarProvider.getEventsForDay(date)
    .where((e) => e.category != EventCategory.holiday)
    .toList();
```

### All Day Filter
When "All Day" is selected, any non-holiday event marks the day as busy (no contiguous time check).

```dart
if (_selectedTimeFilters.contains(TimeFilter.allDay)) {
  return events.isEmpty ? 1 : 0;
}
```

### Multiple Time Filters
When multiple filters are selected (e.g., Morning + Evening), the user must have sufficient contiguous free time in ALL selected ranges to be considered available.

### Night Filter (Crosses Midnight)
The night filter spans 10pm - 6am, crossing midnight. The code handles this by setting the end time to the next day:

```dart
if (filter == TimeFilter.night) {
  filterStart = DateTime(date.year, date.month, date.day, 22); // 10pm
  filterEnd = DateTime(date.year, date.month, date.day + 1, 6); // 6am next day
}
```

## Future Enhancements

### Show Free Time Duration
Instead of binary available/busy, show how much time is free:
- "6 hrs free" (no events)
- "4 hrs free" (some events)
- "1 hr free" (mostly busy)

### Configurable Threshold
Allow groups to set their own minimum time:
- Casual hangouts: 1.5 hours
- Team meetings: 1 hour
- Day trips: 4 hours

### Smart Suggestions
"Best time to meet: Tuesday 7-10am (3 hrs free for 6/8 members)"

## Testing Scenarios

When testing availability logic, verify these cases:

1. **No events** -> Available
2. **Event at start of range** -> Available (if enough time after)
3. **Event at end of range** -> Available (if enough time before)
4. **Event in middle** -> Available (if either side has 2+ hours)
5. **Multiple small events** -> Check largest gap
6. **Overlapping events** -> Merge and find gaps
7. **Event spanning entire range** -> Busy
8. **Holiday event** -> Ignored (available)

---

*Last updated: December 27, 2025*
