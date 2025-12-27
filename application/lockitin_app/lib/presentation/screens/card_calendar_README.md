# Card Calendar View

A modern, card-based calendar UI inspired by contemporary mobile calendar apps, featuring a horizontal day selector and event cards.

## Features

### 1. **Gradient Header**
- Deep Blue → Purple gradient (brand colors)
- Month navigation with chevron buttons
- Month summary badges showing event counts per category
- "Personal Calendar" subtitle

### 2. **Horizontal Day Selector**
- Scrollable horizontal list of all days in the month
- Auto-scrolls to selected day
- Each day card shows:
  - Day of week (abbreviated)
  - Day number
  - Color-coded event indicators (dots)
- Selected day has gradient background
- Today has subtle tint background

### 3. **Selected Day Card**
- Header showing selected date and event count
- Category count badges (color-coded squares)
- Scrollable list of events for the day
- Each event card shows:
  - Category icon with color background
  - Event title
  - Category label
  - Tap to view event details

### 4. **Empty State**
- Friendly icon when no events
- "Tap + to add one" message

### 5. **Floating Action Button**
- Primary color FAB for adding events
- Positioned bottom-right

## Design Principles

### Colors
- Uses brand Deep Blue (#2563EB) and Purple (#8B5CF6) gradients
- Category colors from app_colors.dart:
  - Work: Teal (#14B8A6)
  - Holiday: Coral (#FB923C)
  - Friend: Purple (#8B5CF6)
  - Other: Slate (#64748B)

### Layout
- Card-based UI with subtle shadows
- Rounded corners (12-16px radius)
- Consistent padding and spacing
- White background cards on light gray surface

### Interactions
- Tap day to select
- Auto-scroll animation to selected day
- Tap event card to view details
- Smooth month navigation

## Usage

### Navigation
Add a button to navigate to the card view:

```dart
IconButton(
  icon: Icon(Icons.view_agenda_rounded),
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CardCalendarScreen(),
      ),
    );
  },
)
```

### Integration
The card calendar uses the same `CalendarProvider` as the grid calendar, so all events are synchronized.

## File Structure

```
lib/presentation/screens/
├── card_calendar_screen.dart  # Main card calendar implementation
└── calendar_screen.dart        # Grid calendar with toggle button
```

## Comparison to Grid Calendar

| Feature | Grid Calendar | Card Calendar |
|---------|--------------|---------------|
| **View Type** | Month grid (7×6) | Horizontal day scroll |
| **Event Display** | Colored dots in cells | Event cards with details |
| **Navigation** | Swipe between months | Chevron buttons |
| **Density** | High (see full month) | Low (focus on one day) |
| **Best For** | Overview, planning | Daily agenda, focus |

## Future Enhancements

- [ ] Week view option
- [ ] Upcoming events section
- [ ] Quick add event from FAB
- [ ] Swipe between days
- [ ] Today indicator animation
- [ ] Pull-to-refresh
- [ ] Category filtering
- [ ] Search events

## Inspired By

This design is inspired by modern calendar apps like:
- Google Calendar (card-based agenda)
- Fantastical (horizontal day picker)
- Any.do Calendar (gradient headers)
- Notion Calendar (clean event cards)
