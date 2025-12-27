# Day Timeline View - Apple Calendar Style

## Overview

The `DayTimelineView` widget provides an Apple Calendar-style timeline visualization for a single day's events. Events are positioned at their actual times with intelligent overlap handling.

## Features

### 1. Timeline Layout
- **24-hour vertical timeline**: 12 AM → 11 PM
- **60 pixels per hour**: 1 pixel = 1 minute (readable and precise)
- **Hour labels**: Left column shows "12 AM", "1 PM", etc.
- **Horizontal lines**: Visual separation between hours

### 2. All-Day Events
- **Separate section at top**: Fixed-height cards above timeline
- **Visual treatment**: Lighter background with privacy color dot
- **Stacking**: Multiple all-day events stack vertically
- **Clear labeling**: "All Day" header to distinguish from timed events

### 3. Timed Events
- **Positioned by time**: Events appear at their exact start time
- **Duration-based height**: Visual length matches actual duration
- **Minimum height**: 20px for very short events (ensures tappable)
- **Adaptive content**:
  - < 30 min: Title only (compact)
  - 30-60 min: Title + time range
  - > 60 min: Title + time + location

### 4. Overlap Handling
- **Side-by-side layout**: Overlapping events displayed in columns
- **Dynamic width**: Each event gets `availableWidth / numberOfOverlappingEvents`
- **Column assignment**: Greedy algorithm minimizes column count
- **4px gap**: Visual separation between adjacent events

### 5. Privacy Integration
- **Privacy color border**: 3px left border in privacy color (red/orange/green)
- **Background tint**: 15% opacity background matching privacy color
- **Respects color-blind settings**: Uses SettingsProvider to switch palettes

### 6. Current Time Indicator (Today Only)
- **Red line**: Horizontal line at current time (Apple Calendar style)
- **Red dot**: Circle indicator at line start
- **Live position**: Updates as time passes

### 7. Auto-Scroll Behavior
- **Today**: Scrolls to current time - 2 hours (shows context before/after)
- **Other days**: Scrolls to first event - 1 hour
- **No events**: Defaults to 8 AM
- **Smooth animation**: 300ms easeOut curve

## Layout Algorithm

### Positioning Formula
```dart
// Convert DateTime to "minutes since midnight"
final minutesSinceMidnight = (hour * 60) + minute;

// Calculate Y position
final yPosition = minutesSinceMidnight.toDouble(); // 1 pixel per minute

// Calculate height
final durationMinutes = endTime.difference(startTime).inMinutes;
final height = durationMinutes.toDouble();
```

### Overlap Detection
```dart
bool eventsOverlap(EventA, EventB) {
  return EventA.startTime < EventB.endTime &&
         EventA.endTime > EventB.startTime;
}
```

### Column Assignment
1. Sort events by start time
2. For each event, find all overlapping events
3. Assign to first available column (greedy algorithm)
4. Create new column if needed
5. Calculate width: `availableWidth / maxColumns`

## Widget Hierarchy

```
DayTimelineView (StatefulWidget)
├── Column
│   ├── All-Day Events Section (if any)
│   │   ├── "All Day" label
│   │   └── List of all-day event cards
│   └── Expanded (Timeline)
│       └── LayoutBuilder (measures available width)
│           └── ListView.builder (24 hours)
│               └── For each hour:
│                   └── Stack
│                       ├── Row (Time label + Hour line)
│                       ├── Current time indicator (if applicable)
│                       └── Positioned events within this hour
```

## Performance Optimizations

### 1. Efficient Rendering
- Events only rendered in hours they appear (avoids duplicates)
- `ListView.builder` for lazy loading of hours (not all 24 in memory)
- `LayoutBuilder` measures width once, not per event

### 2. Overlap Calculation
- Pre-calculates all overlaps before rendering
- O(n²) complexity, acceptable for typical day (< 50 events)
- Could optimize with interval tree if needed for 100+ events

### 3. Scroll Performance
- `ScrollController` for programmatic scrolling
- Animated scroll on initial load only (not on rebuild)
- Uses `addPostFrameCallback` to wait for layout

## Constants

```dart
static const double _hourHeight = 60.0;              // 60px per hour
static const double _timeColumnWidth = 60.0;         // Time labels width
static const double _allDayEventHeight = 40.0;       // All-day event card height
static const double _currentTimeIndicatorHeight = 2.0; // Red line thickness
static const double _eventMinHeight = 20.0;          // Minimum tappable size
```

## Integration with Day Detail Screen

### Before (List View)
```dart
body: events.isEmpty
  ? _buildEmptyState(context, colorScheme)
  : _buildEventList(context, colorScheme, events),
```

### After (Timeline View)
```dart
body: events.isEmpty
  ? _buildEmptyState(context, colorScheme)
  : DayTimelineView(
      selectedDate: selectedDate,
      events: events,
    ),
```

## Platform Conventions

### iOS (Cupertino)
- Matches Apple Calendar's day view exactly
- Spring physics for scrolling (native feel)
- Swipe gestures feel natural

### Android (Material)
- Similar to Google Calendar's day view
- Material Design elevation and shadows
- Follows Material motion guidelines

## Future Enhancements

### Potential Improvements
1. **Pinch to zoom**: Adjust hour height (30px → 120px per hour)
2. **Tap empty space**: Create new event at tapped time
3. **Drag to resize**: Adjust event duration directly
4. **Drag to move**: Change event start time
5. **Haptic feedback**: On event tap and time indicator crossing
6. **Week view**: Similar timeline across 7 days side-by-side
7. **Work hours focus**: Collapse non-work hours (12 AM - 6 AM)

### Performance for Heavy Users
- If user has 100+ events per day, optimize with:
  - Interval tree for O(log n) overlap detection
  - Virtual scrolling (render only visible hours)
  - Event clustering (combine small gaps)

## Testing Scenarios

### Edge Cases Handled
1. **All-day events**: Separate section at top
2. **Multi-day events**: Only show portion within selected day
3. **Midnight-spanning events**: Event starting 11 PM ending 2 AM
4. **Very short events** (< 20 min): Minimum height ensures tappability
5. **Many overlaps** (5+ events): Side-by-side columns with reduced width
6. **No events**: Empty state (handled by parent screen)
7. **Today vs. other days**: Different auto-scroll behavior
8. **Current time indicator**: Only shows for today

### Visual Tests
- Light mode + dark mode
- Color-blind palette vs. standard palette
- Privacy colors (red/orange/green borders)
- Long event titles (truncation)
- Long locations (truncation)

## Code Examples

### Creating a Day Timeline View
```dart
DayTimelineView(
  selectedDate: DateTime(2025, 12, 26),
  events: [
    EventModel(
      id: '1',
      userId: 'user-1',
      title: 'Team Meeting',
      startTime: DateTime(2025, 12, 26, 9, 0),
      endTime: DateTime(2025, 12, 26, 10, 0),
      location: 'Conference Room A',
      visibility: EventVisibility.sharedWithName,
      category: EventCategory.work,
      createdAt: DateTime.now(),
    ),
    // ... more events
  ],
)
```

### Overlap Example
```
9:00 AM  ┌─────────────┐ ┌─────────────┐
         │ Event A     │ │ Event B     │
9:30 AM  │             │ │             │
         └─────────────┘ │             │
10:00 AM                 │             │
                         └─────────────┘
10:30 AM

Event A: 9:00 - 9:30 (Column 0)
Event B: 9:15 - 10:15 (Column 1)
Total columns: 2
Width per event: (availableWidth / 2) - 4px gap
```

### Privacy Colors in Timeline
```
┌─ Red border (3px)
│ ┌─────────────────┐
│ │ Private Meeting │ ← Light red background (15% opacity)
│ │ 2:00 - 3:00 PM  │
│ └─────────────────┘
```

## Dependencies

- `flutter/material.dart`: UI widgets
- `intl/intl.dart`: Date formatting (DateFormat)
- `provider/provider.dart`: Settings for color-blind palette
- `../../data/models/event_model.dart`: Event data
- `../../utils/privacy_colors.dart`: Privacy color mapping
- `../providers/settings_provider.dart`: User settings
- `../screens/event_detail_screen.dart`: Navigation target

## Summary

The `DayTimelineView` provides a production-ready, Apple Calendar-style timeline that:
- Feels native on both iOS and Android
- Handles edge cases gracefully (overlaps, all-day, short events)
- Respects privacy settings with color-coded borders
- Auto-scrolls intelligently to relevant times
- Performs well with typical event loads (< 50 events/day)
- Maintains brand aesthetic (Deep Blue/Purple/Coral)

This replaces the previous list-based day detail view with a much more professional and intuitive timeline visualization.
