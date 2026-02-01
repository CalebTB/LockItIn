# Calendar Implementation Analysis
**LockItIn Flutter App - Calendar Architecture Deep Dive**
*Generated: February 1, 2026*

---

## Executive Summary

The LockItIn calendar implementation uses a **dual-architecture pattern** with:
1. **Personal Calendar** - Single provider (`CalendarProvider`) managing user's personal events
2. **Group Calendar** - Separate state in `GroupDetailScreen` managing shadow calendar entries

This analysis identifies code duplication opportunities, architectural patterns, and provides specific recommendations for consolidation.

---

## 1. Current Calendar Architecture

### 1.1 Separate Calendar Views

The app has **4 distinct calendar views**, each with different data fetching approaches:

| View | File | Data Source | Provider |
|------|------|-------------|----------|
| **Personal Calendar (Month Grid)** | `calendar_screen.dart` | `CalendarProvider` | `CalendarProvider` |
| **Personal Calendar (Card View)** | `card_calendar_screen.dart` | `CalendarProvider` | `CalendarProvider` |
| **Day Detail View** | `day_detail_screen.dart` | `CalendarProvider` | `CalendarProvider` |
| **Group Calendar (Heatmap)** | `group_detail/group_detail_screen.dart` | Local state (`_memberEvents`) | None (local state) |

### 1.2 Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    PERSONAL CALENDAR                        │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │         CalendarProvider (Singleton)                  │ │
│  │  - _eventsByDate: Map<String, List<EventModel>>      │ │
│  │  - _loadEvents() - Fetches from:                     │ │
│  │    1. TestEventsService (dev mode)                   │ │
│  │    2. Supabase (user events via EventService)        │ │
│  │    3. Native calendar (iOS/Android via CalendarMgr)  │ │
│  └───────────────────────────────────────────────────────┘ │
│         ▲                                                   │
│         │ Context.watch / Context.read                      │
│         │                                                   │
│  ┌──────┴──────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ CalendarScreen  │  │  CardCalendar│  │ DayDetailScr │  │
│  │  (Month Grid)   │  │   (Cards)    │  │  (Timeline)  │  │
│  └─────────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                     GROUP CALENDAR                          │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │  GroupDetailScreen (Local State - NOT Provider)       │ │
│  │  - _memberEvents: Map<String, List<EventModel>>      │ │
│  │  - _loadMemberEvents() - Fetches from:               │ │
│  │    • EventService.fetchGroupShadowCalendar()         │ │
│  │      └─> RPC: get_group_shadow_calendar_v2           │ │
│  │  - _availabilityCache: Map<String, int>              │ │
│  └───────────────────────────────────────────────────────┘ │
│         ▲                                                   │
│         │ setState() updates                                │
│         │                                                   │
│  ┌──────┴──────────────────────────────────────────────┐   │
│  │     GroupCalendarGrid (Availability Heatmap)        │   │
│  │     - Shows aggregated availability (5/8 free)      │   │
│  │     - Tap day → GroupDayTimelineView                │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Event Visibility Management

### 2.1 Privacy Levels (EventVisibility Enum)

Defined in `/lib/data/models/event_model.dart:8-12`:

```dart
enum EventVisibility {
  private,        // Hidden from all groups
  sharedWithName, // Groups see event title & time
  busyOnly,       // Groups see "busy" block without details
}
```

### 2.2 Shadow Calendar System (Database-Level Privacy)

**Dual-Table Architecture** enforces privacy at the database level:

```
┌─────────────────────────────────────────────────────────────┐
│                      EVENTS TABLE                            │
│  Stores ALL events (private, busyOnly, sharedWithName)      │
│                                                              │
│  RLS Policy: Users can ONLY see their own events            │
│  Used by: Personal calendar view                            │
└─────────────────────────────────────────────────────────────┘
                           │
                           │ Trigger syncs non-private only
                           │ (sync_event_to_shadow_calendar)
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                  SHADOW_CALENDAR TABLE                       │
│  Stores ONLY busyOnly + sharedWithName events               │
│  (Private events NEVER exist here)                          │
│                                                              │
│  RLS Policy: Group members can see each other's entries     │
│  Used by: Group availability heatmap, day detail views      │
└─────────────────────────────────────────────────────────────┘
```

**Key Database Objects:**
- **Table**: `shadow_calendar` (`/supabase/shadow_calendar_schema.sql:23-56`)
- **Trigger**: `sync_event_to_shadow_calendar()` (`shadow_calendar_schema.sql:93-178`)
- **RPC Function**: `get_group_shadow_calendar_v2()` (`/supabase/migrations/021_add_event_data_to_shadow_calendar_rpc.sql:6-77`)

### 2.3 How Privacy is Enforced in Code

**Personal Calendar (CalendarProvider)**
- Fetches from `events` table via `EventService.fetchEventsFromSupabase()`
- **Line**: `calendar_provider.dart:206-212`
- **Privacy**: RLS ensures users only see their own events

**Group Calendar (GroupDetailScreen)**
- Fetches from `shadow_calendar` via `EventService.fetchGroupShadowCalendar()`
- **Line**: `group_detail_screen.dart:108-113`
- **Privacy**: Shadow calendar automatically excludes private events (enforced by trigger)

### 2.4 Group-Aware Visibility Logic

Implemented in `get_group_shadow_calendar_v2` RPC function:

```sql
-- Override visibility for same-group events
CASE
  WHEN sc.group_id = p_requesting_group_id THEN 'sharedWithName'::TEXT
  WHEN sc.group_id IS NOT NULL AND sc.group_id != p_requesting_group_id THEN 'busyOnly'::TEXT
  ELSE sc.visibility::TEXT
END AS visibility
```

**Logic**:
- Events from requesting group → Full details (sharedWithName + title + event_id)
- Events from other groups → Busy blocks (busyOnly + NULL title)
- Personal events → Original visibility setting

---

## 3. Code Duplication Analysis

### 3.1 Critical Duplication Points

#### **A. Event Fetching Logic (2 locations)**

**Location 1: CalendarProvider (`calendar_provider.dart:180-255`)**
```dart
Future<void> _loadEvents() async {
  // Fetch from Supabase
  final supabaseEvents = await _eventService.fetchEventsFromSupabase(
    startDate: startDate,
    endDate: endDate,
  );

  // Fetch from native calendar
  final nativeEvents = await _calendarManager.fetchEvents(...);

  // Index events by date
  _indexEventsByDate(allEvents);
}
```

**Location 2: GroupDetailScreen (`group_detail_screen.dart:89-142`)**
```dart
Future<void> _loadMemberEvents() async {
  // Fetch shadow calendar
  final shadowEntries = await EventService.instance.fetchGroupShadowCalendar(
    groupId: widget.group.id,
    memberUserIds: memberIds,
    startDate: startDate,
    endDate: endDate,
  );

  // Convert shadow entries to EventModel
  final events = EventService.instance.shadowToEventModels(shadowEntries);

  // Pre-compute availability cache
  _precomputeAvailability(_focusedMonth);
}
```

**Duplication**: Date range calculation, error handling, loading state management

---

#### **B. Date Indexing Logic (2 locations)**

**Location 1: CalendarProvider**
```dart
// calendar_provider.dart:257-280
void _indexEventsByDate(List<EventModel> events) {
  _eventsByDate.clear();
  for (final event in events) {
    final dateKey = _dateKey(event.startTime);
    if (_eventsByDate.containsKey(dateKey)) {
      _eventsByDate[dateKey]!.add(event);
    } else {
      _eventsByDate[dateKey] = [event];
    }
  }
  // Sort events within each day by start time
  for (final dateKey in _eventsByDate.keys) {
    _eventsByDate[dateKey]!.sort((a, b) => a.startTime.compareTo(b.startTime));
  }
}
```

**Location 2: GroupDetailScreen** (Implicit in `_memberEvents`)
- Uses same Map structure: `Map<String, List<EventModel>> _memberEvents`
- No explicit sorting (relies on database ORDER BY)

**Duplication**: Map structure, date key generation pattern

---

#### **C. Availability Caching (GroupDetailScreen only)**

**Current Implementation**: `group_detail_screen.dart:69-189`
```dart
final Map<String, int> _availabilityCache = {};

int _getAvailabilityForDay(DateTime date) {
  final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  if (_availabilityCache.containsKey(key)) {
    return _availabilityCache[key]!;
  }

  final result = _availabilityService.calculateGroupAvailability(...);
  _availabilityCache[key] = result;
  return result;
}

void _precomputeAvailability(DateTime month) {
  for (int day = 1; day <= endOfMonth.day; day++) {
    final date = DateTime(month.year, month.month, day);
    _getAvailabilityForDay(date); // Populates cache
  }
}
```

**Issue**: This pattern could be useful for personal calendar too (caching event indicators)

---

#### **D. Month Grid Rendering (Calendar vs Group Calendar)**

**Personal Calendar**: `calendar_screen.dart:402-478`
- Custom grid with 6 rows × 7 columns
- Shows event dots (up to 6) + event count badge
- Handles padding from prev/next months

**Group Calendar**: `group_detail/widgets/group_calendar_grid.dart` (assumed - not read yet)
- Similar grid structure
- Shows availability heatmap colors instead of event dots
- Likely similar padding/layout logic

**Duplication**: Grid layout calculations, cell positioning, date range generation

---

### 3.2 Files Containing Calendar Data Fetching

| File | Method | Data Type | Purpose |
|------|--------|-----------|---------|
| `calendar_provider.dart` | `_loadEvents()` | `List<EventModel>` | Personal events (all sources) |
| `calendar_provider.dart` | `_indexEventsByDate()` | `Map<String, List<EventModel>>` | Date-indexed events |
| `group_detail_screen.dart` | `_loadMemberEvents()` | `Map<String, List<EventModel>>` | Shadow calendar entries |
| `event_service.dart` | `fetchEventsFromSupabase()` | `List<EventModel>` | Supabase events (personal) |
| `event_service.dart` | `fetchGroupShadowCalendar()` | `Map<String, List<ShadowCalendarEntry>>` | Group shadow calendar |
| `event_service.dart` | `shadowToEventModels()` | `Map<String, List<EventModel>>` | Convert shadow → EventModel |

---

## 4. State Management

### 4.1 Current Provider Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  PROVIDER HIERARCHY                          │
└─────────────────────────────────────────────────────────────┘

1. CalendarProvider (Singleton - App-level)
   ├─ Manages: Personal calendar events
   ├─ Data: _eventsByDate (Map<String, List<EventModel>>)
   ├─ Methods: _loadEvents(), addEvent(), updateEvent(), removeEvent()
   └─ Used by: CalendarScreen, CardCalendarScreen, DayDetailScreen

2. GroupProvider (Singleton - App-level)
   ├─ Manages: Groups list, selected group, group members
   ├─ Data: _groups, _selectedGroup, _selectedGroupMembers
   ├─ Methods: loadGroups(), selectGroup(), loadGroupMembers()
   └─ Used by: HomeScreen, GroupsBottomSheet, GroupDetailScreen

3. GroupDetailScreen (LOCAL STATE - NOT Provider)
   ├─ Manages: Member events for current group (shadow calendar)
   ├─ Data: _memberEvents (Map<String, List<EventModel>>)
   ├─ Methods: _loadMemberEvents(), _precomputeAvailability()
   └─ Issue: Not shared with other screens, duplicates CalendarProvider pattern
```

### 4.2 State Sharing Issues

**Problem**: Group calendar data is isolated in `GroupDetailScreen` local state

**Implications**:
1. Cannot pre-load group calendar data before navigating to group detail
2. Must re-fetch on every navigation to group detail
3. No shared caching between different group views
4. Cannot implement "group calendar mini-widget" in other screens (data not accessible)

**Current Workaround**: None - data refetches on every group detail navigation

---

### 4.3 Proposed Provider Structure

```
CalendarProvider (rename to PersonalCalendarProvider)
├─ Manages: Personal events only
└─ Data: _eventsByDate

GroupCalendarProvider (NEW)
├─ Manages: Shadow calendar for selected group
├─ Data: _memberEventsByUser: Map<String, Map<String, List<EventModel>>>
│         └─ Outer key: groupId
│             └─ Inner key: userId
├─ Methods:
│   ├─ loadGroupCalendar(groupId, memberIds, dateRange)
│   ├─ getEventsForUserOnDay(groupId, userId, date)
│   └─ clearGroupCalendar(groupId)
└─ Cache Strategy: Keep last 3 groups in memory (LRU)

GroupProvider (keep existing)
├─ Manages: Groups list, members
└─ Integrates with: GroupCalendarProvider for calendar data
```

---

## 5. Database Schema

### 5.1 Core Tables

**events** (`/supabase/schema.sql:83-100`)
```sql
CREATE TABLE events (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id),
  group_id UUID REFERENCES groups(id),  -- NULL for personal events
  title TEXT NOT NULL,
  description TEXT,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  location TEXT,
  visibility event_visibility NOT NULL DEFAULT 'private',
  category event_category DEFAULT 'other',
  native_calendar_id TEXT,
  all_day BOOLEAN DEFAULT FALSE,
  template_data JSONB,  -- Surprise party, potluck templates
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ
);
```

**shadow_calendar** (`/supabase/shadow_calendar_schema.sql:23-56`)
```sql
CREATE TABLE shadow_calendar (
  id UUID PRIMARY KEY,
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id),
  group_id UUID REFERENCES groups(id),  -- Added in migration
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  visibility event_visibility NOT NULL,
  event_title TEXT,  -- NULL for busyOnly
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ,

  CONSTRAINT valid_title_for_visibility CHECK (
    (visibility = 'busyOnly' AND event_title IS NULL) OR
    (visibility = 'sharedWithName' AND event_title IS NOT NULL)
  )
);
```

### 5.2 Key Indexes

```sql
-- Personal calendar queries
CREATE INDEX idx_events_user_date ON events(user_id, start_time);

-- Shadow calendar queries (group availability)
CREATE INDEX idx_shadow_calendar_user_time
  ON shadow_calendar(user_id, start_time, end_time);

-- Event lookup from shadow calendar
CREATE INDEX idx_shadow_calendar_event_id ON shadow_calendar(event_id);
```

### 5.3 RPC Functions

**get_user_events** (Personal calendar)
```sql
-- Fetches both created events AND events user is invited to
-- Applies decoy titles for surprise party guests of honor
CREATE FUNCTION get_user_events(
  p_user_id UUID,
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ
)
RETURNS SETOF events;
```

**get_group_shadow_calendar_v2** (Group calendar)
```sql
-- Fetches shadow calendar with group-aware visibility
-- Same-group events: Full details + event_id + template_data
-- Other-group events: Busy blocks only
CREATE FUNCTION get_group_shadow_calendar_v2(
  p_user_ids UUID[],
  p_requesting_group_id UUID,
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ
)
RETURNS TABLE (...);
```

---

## 6. Current Pain Points

### 6.1 Performance Issues

**Issue 1: GroupDetailScreen Refetches on Every Navigation**
- **Location**: `group_detail_screen.dart:78-86`
- **Impact**: Slow navigation, unnecessary API calls
- **Current**: 2-month range (optimized from 5 months)
- **Ideal**: Pre-fetch when group is selected in GroupProvider

**Issue 2: Availability Cache is Per-Screen**
- **Location**: `group_detail_screen.dart:69`
- **Impact**: Cache cleared on navigation away from screen
- **Ideal**: Move cache to provider for persistence across navigations

**Issue 3: No Pagination for Large Groups**
- **Current**: Fetches all members' events for 2 months
- **Impact**: Slow for groups with 20+ members
- **Ideal**: Load on-demand by month, lazy-load member details

---

### 6.2 Code Maintainability Issues

**Issue 1: Duplicated Event Indexing Logic**
- **Impact**: Changes must be made in 2 places (CalendarProvider + GroupDetailScreen)
- **Risk**: Bugs from inconsistent implementations

**Issue 2: Shadow Calendar Conversion Scattered**
- **Current**: `EventService.shadowToEventModels()` + local state management
- **Impact**: Unclear ownership of conversion logic
- **Ideal**: Single source of truth in GroupCalendarProvider

**Issue 3: No Clear Separation of Concerns**
- **Issue**: `GroupDetailScreen` handles:
  - UI rendering
  - Data fetching
  - Availability calculations
  - Caching logic
- **Ideal**: Extract data/caching to provider, leave only UI in screen

---

### 6.3 Architecture Inconsistencies

**Issue 1: Different State Management Patterns**
- Personal calendar: Provider-based (clean, testable)
- Group calendar: Local state (scattered, hard to test)

**Issue 2: Event Models Used for Two Purposes**
- Personal events: Full `EventModel` with all fields
- Shadow calendar: Minimal `EventModel` (converted from `ShadowCalendarEntry`)
- **Confusion**: Same type, different data completeness

**Issue 3: No Unified Calendar Interface**
- Cannot easily switch between "My Calendar" and "Group Calendar"
- No shared filtering/sorting logic
- Duplicated UI patterns

---

## 7. Recommendations

### 7.1 Immediate Wins (Low Effort, High Impact)

**Recommendation 1: Extract Event Indexing to Utility Class**
```dart
// Create: /lib/utils/event_indexer.dart
class EventIndexer {
  static Map<String, List<EventModel>> indexByDate(List<EventModel> events) {
    final index = <String, List<EventModel>>{};
    for (final event in events) {
      final key = TimezoneUtils.getDateKey(event.startTime);
      (index[key] ??= []).add(event);
    }
    // Sort events within each day
    index.forEach((key, events) {
      events.sort((a, b) => a.startTime.compareTo(b.startTime));
    });
    return index;
  }

  static String getDateKey(DateTime date) => TimezoneUtils.getDateKey(date);
}
```

**Impact**: Eliminates duplication between CalendarProvider and GroupDetailScreen

---

**Recommendation 2: Create GroupCalendarProvider**
```dart
// Create: /lib/presentation/providers/group_calendar_provider.dart
class GroupCalendarProvider extends ChangeNotifier {
  // Cache shadow calendar data by group ID
  final Map<String, Map<String, List<EventModel>>> _groupCalendars = {};

  // Cache availability calculations
  final Map<String, Map<String, int>> _availabilityCache = {};

  Future<void> loadGroupCalendar(String groupId, ...) async { ... }

  List<EventModel> getEventsForUserOnDay(String groupId, String userId, DateTime date) { ... }

  int getAvailabilityForDay(String groupId, DateTime date, ...) { ... }

  void clearCache(String groupId) { ... }
}
```

**Impact**: Centralizes group calendar state, enables caching across navigations

---

**Recommendation 3: Unify Date Range Calculation**
```dart
// Create: /lib/utils/calendar_date_ranges.dart
class CalendarDateRanges {
  static const int personalCalendarMonthsBack = 1;
  static const int personalCalendarMonthsForward = 2;
  static const int groupCalendarMonthsBack = 0;
  static const int groupCalendarMonthsForward = 2;

  static DateTimeRange personalCalendarRange() {
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, now.month - personalCalendarMonthsBack, 1),
      end: DateTime(now.year, now.month + personalCalendarMonthsForward, 0),
    );
  }

  static DateTimeRange groupCalendarRange() { ... }
}
```

**Impact**: Consistent date range logic, easier to adjust loading strategies

---

### 7.2 Medium-Term Improvements (Refactoring)

**Recommendation 4: Create Base Calendar Provider**
```dart
// Create: /lib/presentation/providers/base_calendar_provider.dart
abstract class BaseCalendarProvider extends ChangeNotifier {
  Map<String, List<EventModel>> _eventsByDate = {};

  // Shared methods
  List<EventModel> getEventsForDay(DateTime date);
  bool hasEvents(DateTime date);
  void _indexEvents(List<EventModel> events);

  // Subclasses must implement
  Future<void> loadEvents();
}

class PersonalCalendarProvider extends BaseCalendarProvider { ... }
class GroupCalendarProvider extends BaseCalendarProvider { ... }
```

**Impact**: Eliminates duplication, enforces consistent interface

---

**Recommendation 5: Separate Shadow Calendar Concerns**
```dart
// Create: /lib/data/repositories/shadow_calendar_repository.dart
class ShadowCalendarRepository {
  Future<Map<String, List<ShadowCalendarEntry>>> fetchGroupShadowCalendar({
    required String groupId,
    required List<String> memberUserIds,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Call EventService, handle errors, add retry logic
  }

  Map<String, List<EventModel>> convertToEventModels(
    Map<String, List<ShadowCalendarEntry>> shadowEntries,
  ) {
    return EventService.instance.shadowToEventModels(shadowEntries);
  }
}
```

**Impact**: Clean separation of data layer from UI, easier testing

---

### 7.3 Long-Term Architecture (Ideal State)

**Recommendation 6: Unified Calendar Service Layer**
```
┌─────────────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER                         │
│  ┌──────────────────────┐    ┌──────────────────────────┐  │
│  │ PersonalCalendar     │    │  GroupCalendarProvider   │  │
│  │ Provider             │    │                          │  │
│  └──────────────────────┘    └──────────────────────────┘  │
└──────────────┬──────────────────────────────┬───────────────┘
               │                              │
               ▼                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   SERVICE LAYER (NEW)                        │
│  ┌──────────────────────────────────────────────────────┐  │
│  │           CalendarDataService                        │  │
│  │  - fetchPersonalEvents()                             │  │
│  │  - fetchGroupShadowCalendar()                        │  │
│  │  - indexEventsByDate()                               │  │
│  │  - cacheAvailability()                               │  │
│  └──────────────────────────────────────────────────────┘  │
└──────────────┬──────────────────────────────┬───────────────┘
               │                              │
               ▼                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  REPOSITORY LAYER                            │
│  ┌──────────────────────┐    ┌──────────────────────────┐  │
│  │ EventRepository      │    │ ShadowCalendarRepository │  │
│  │ (Supabase + Native)  │    │ (Supabase RPC)           │  │
│  └──────────────────────┘    └──────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

**Benefits**:
- Single source of truth for calendar data operations
- Easier to swap Supabase for another backend
- Testable without Flutter dependencies
- Consistent error handling and retry logic

---

## 8. Specific File Paths & Code Snippets

### 8.1 Personal Calendar Provider

**File**: `/Users/calebbyers/Code/LockItIn/application/lockitin_app/lib/presentation/providers/calendar_provider.dart`

**Key Methods**:
- `_loadEvents()` (Lines 180-255) - Fetches events from multiple sources
- `_indexEventsByDate()` (Lines 257-280) - Indexes events by date
- `getEventsForDay()` (Lines 289-293) - Retrieves events for a specific date
- `addEvent()` / `updateEvent()` / `removeEvent()` (Lines 316-377) - CRUD operations
- `_applyDecoyTitle()` (Lines 637-653) - Surprise party privacy

**Event Fetching Flow**:
```
_loadEvents()
  ├─> TestEventsService.generateTestEvents() (dev mode)
  ├─> EventService.fetchEventsFromSupabase()
  │     └─> RPC: get_user_events()
  ├─> CalendarManager.fetchEvents() (native calendar)
  └─> _indexEventsByDate() (local indexing)
```

---

### 8.2 Group Calendar Screen

**File**: `/Users/calebbyers/Code/LockItIn/application/lockitin_app/lib/presentation/screens/group_detail/group_detail_screen.dart`

**Key Methods**:
- `_loadMemberEvents()` (Lines 89-142) - Fetches shadow calendar
- `_precomputeAvailability()` (Lines 144-154) - Pre-fills availability cache
- `_getAvailabilityForDay()` (Lines 170-187) - Cached availability lookup

**Event Fetching Flow**:
```
_loadMemberEvents()
  └─> EventService.fetchGroupShadowCalendar()
        ├─> RPC: get_group_shadow_calendar_v2()
        └─> EventService.shadowToEventModels()
              └─> Returns Map<String, List<EventModel>>
```

---

### 8.3 Event Service (Centralized API)

**File**: `/Users/calebbyers/Code/LockItIn/application/lockitin_app/lib/core/services/event_service.dart`

**Key Methods**:
- `fetchEventsFromSupabase()` (Lines 263-312) - Personal events
- `fetchGroupShadowCalendar()` (Lines 374-438) - Group shadow calendar
- `shadowToEventModels()` (Lines 440-476) - Convert shadow entries to EventModel
- `_applyDecoyTitles()` (Lines 532-562) - Surprise party privacy (duplicate of CalendarProvider)

**Shadow Calendar Conversion** (Lines 448-475):
```dart
Map<String, List<EventModel>> shadowToEventModels(
  Map<String, List<ShadowCalendarEntry>> shadowEntries,
) {
  final Map<String, List<EventModel>> result = {};

  for (final entry in shadowEntries.entries) {
    final userId = entry.key;
    final entries = entry.value;

    result[userId] = entries.map((shadow) {
      return EventModel(
        id: shadow.eventId ?? '',
        userId: shadow.userId,
        title: shadow.displayText,  // "Busy" or actual title
        startTime: shadow.startTime,
        endTime: shadow.endTime,
        visibility: shadow.isBusyOnly
            ? EventVisibility.busyOnly
            : EventVisibility.sharedWithName,
        createdAt: TimezoneUtils.nowUtc(),
        templateData: shadow.templateData,
      );
    }).toList();
  }

  return result;
}
```

---

### 8.4 Database Migration Files

**Shadow Calendar RPC Function**:
`/Users/calebbyers/Code/LockItIn/supabase/migrations/021_add_event_data_to_shadow_calendar_rpc.sql`

**Key Features**:
- Group-aware visibility (Lines 43-47)
- Event ID for navigation (Lines 58-62)
- Template data for surprise parties (Lines 64-69)

---

## 9. Testing Gaps

### 9.1 Current Test Coverage

**Personal Calendar**:
- ✅ `calendar_provider_test.dart` - Provider logic tested
- ✅ `event_service_test.dart` - Service layer tested
- ❌ No tests for month grid rendering
- ❌ No tests for event indicator caching

**Group Calendar**:
- ❌ No tests for `GroupDetailScreen._loadMemberEvents()`
- ❌ No tests for availability caching
- ❌ No tests for shadow calendar conversion
- ✅ `shadow_calendar_entry_test.dart` - Model tests exist

### 9.2 Recommended Tests

**High Priority**:
1. **Shadow Calendar Integration Test**
   - Test `fetchGroupShadowCalendar()` with real Supabase
   - Verify group-aware visibility logic
   - Test decoy title application for surprise parties

2. **Availability Cache Test**
   - Test cache hit/miss logic
   - Test pre-computation performance
   - Test cache invalidation on data changes

3. **Event Indexing Test**
   - Test date key generation across timezones
   - Test sorting within days
   - Test handling of all-day events

---

## 10. Next Steps

### Priority 1: Extract Common Logic (Week 1)
1. Create `EventIndexer` utility class
2. Create `CalendarDateRanges` utility class
3. Update `CalendarProvider` to use new utilities
4. Update `GroupDetailScreen` to use new utilities
5. Write unit tests for new utilities

### Priority 2: Create GroupCalendarProvider (Week 2)
1. Create `GroupCalendarProvider` class
2. Move `_memberEvents` state from `GroupDetailScreen` to provider
3. Move `_availabilityCache` to provider
4. Update `GroupDetailScreen` to use provider
5. Add initialization in `main.dart`

### Priority 3: Refactor Event Service (Week 3)
1. Create `ShadowCalendarRepository`
2. Move shadow calendar logic from `EventService` to repository
3. Update `GroupCalendarProvider` to use repository
4. Add error handling and retry logic
5. Write integration tests

### Priority 4: Performance Optimization (Week 4)
1. Implement LRU cache for group calendars (keep last 3 groups)
2. Add pagination for large groups (load by month)
3. Optimize availability pre-computation (background worker)
4. Add performance monitoring/logging

---

## Appendix: Key Constants

**Date Range Constants** (Personal Calendar):
```dart
// CalendarProvider
static const int _monthsBackward = 120;  // 10 years back
static const int _monthsForward = 120;   // 10 years forward

// Event loading (optimized range)
final startDate = DateTime(now.year, now.month - 1, now.day);  // 30 days back
final endDate = DateTime(now.year, now.month + 2, now.day);    // 60 days forward
```

**Date Range Constants** (Group Calendar):
```dart
// GroupDetailScreen (optimized from 5 months to 2 months)
final startDate = DateTime(now.year, now.month, 1);           // Current month
final endDate = DateTime(now.year, now.month + 2, 0);         // +2 months
```

**Cache Constants**:
```dart
// CalendarProvider
static const Duration _upcomingEventsCacheDuration = Duration(days: 1);

// GroupDetailScreen
// No explicit cache expiration - cleared on screen dispose
```

---

## Glossary

- **Shadow Calendar**: Denormalized availability table for efficient group queries
- **Event Visibility**: Privacy level (private/busyOnly/sharedWithName)
- **RLS**: Row Level Security (Supabase database-level permissions)
- **RPC**: Remote Procedure Call (Supabase database function)
- **Decoy Title**: Fake event title shown to surprise party guest of honor
- **Heatmap**: Color-coded calendar showing group availability (e.g., "5/8 free")

---

**End of Analysis**
