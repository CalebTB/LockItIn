# Show Group Name for Proposal-Created Events

**Issue:** #226 | **Type:** Feature | **Priority:** Medium | **Area:** Calendar

> **Plan Revision:** Simplified based on code review feedback from DHH, Kieran, and Code Simplicity reviewers.
> **Estimated Time:** 4 hours (down from 13 hours)

## Overview

Events created from confirmed group proposals should display which group they belong to in both month view and day detail view. This provides visual context, helping users quickly identify group-coordinated events versus personal events.

**Current State:**
- Events table has `group_id` column (nullable)
- `confirm_proposal` RPC creates events but **does NOT populate `group_id`**
- No UI components display group affiliation on calendar events
- Users cannot distinguish group events from personal events at a glance

**Desired State:**
- Events from confirmed proposals have `group_id` set automatically
- Calendar views show group badge (icon + name)
- Tapping group badge navigates to GroupDetailScreen
- Deleted groups show grayed "[Deleted]" badge

## Problem Statement / Motivation

Users coordinate events through group proposals (e.g., "Ski Trip" with close friends, "Family Dinner" with family group). After confirmation, these events appear in personal calendars but look identical to solo-created events. Users lose context about which events originated from group coordination.

**User Impact:**
- Confusion about event origin ("Which group was this for?")
- Missed opportunities to navigate to group detail
- Inability to quickly scan calendar for group vs. personal commitments

**Business Value:**
- Strengthens group coordination features
- Improves calendar usability
- Encourages continued use of group proposals (users see value)

## Proposed Solution

### Architecture Overview

**Three-Layer Implementation:**

1. **Database Layer**: Modify `confirm_proposal` RPC to populate `group_id` when creating events
2. **Data Layer**: Update `EventModel` and calendar queries to include group information via JOIN
3. **UI Layer**: Create `GroupBadge` widget and integrate into month/day views

**Data Flow:**
```
Group Proposal Confirmed
  ↓
confirm_proposal RPC creates events with group_id
  ↓
Calendar queries JOIN groups table for names
  ↓
UI renders GroupBadge component
  ↓
User taps → Navigate to GroupDetailScreen
```

### Visual Design

**Month View (Calendar Cell):**
```
┌─────────────────┐
│ 🎉 Ski Trip     │  ← Event title
│ 🔒 Private      │  ← Privacy badge (existing)
│ 👥 Ski Crew     │  ← Group badge (NEW - violet pill, auto-truncates)
└─────────────────┘
```

**Day Detail View (Event Card):**
```
┌─────────────────────────────┐
│ 7:00 PM - 9:00 PM          │
│ 🎉 Ski Trip                │
│ 👥 Ski Crew                │  ← Group badge (NEW - same widget)
│ 📍 Mount Hood              │
│ 🔒 Private                 │
└─────────────────────────────┘
```

**Deleted Group State:**
```
┌─────────────────┐
│ 🎉 Ski Trip     │
│ 👥 [Deleted]    │  ← Grayed out, non-tappable
└─────────────────┘
```

## Technical Approach

### ⚠️ BLOCKER: Fix `confirm_proposal` Return Type Bug

**Critical Issue:** The existing `confirm_proposal` function has a bug where it returns a single `UUID` but creates events for MULTIPLE voters. The `RETURNING id INTO v_event_id` clause only captures the LAST inserted event ID.

**Required Fix (Separate PR):**
```sql
-- Option 1: Return array of event IDs
CREATE OR REPLACE FUNCTION confirm_proposal(...)
RETURNS UUID[]  -- Change return type

-- Option 2: Return set of event IDs
RETURNS SETOF UUID
```

**Action:** File separate bug fix issue and PR BEFORE implementing this feature.

---

### Phase 1: Database Migration (30 minutes)

**1.1 Add Foreign Key Constraint (if not exists)**

```sql
-- File: supabase/migrations/032_add_group_id_to_confirmed_events.sql

-- Ensure FK constraint exists
ALTER TABLE events
ADD CONSTRAINT IF NOT EXISTS fk_events_group_id
FOREIGN KEY (group_id)
REFERENCES groups(id)
ON DELETE SET NULL;  -- Preserve event when group deleted

COMMENT ON COLUMN events.group_id IS
'Link to group if event was created from a group proposal. NULL for personal events. Set to NULL when group is deleted (ON DELETE SET NULL).';
```

**1.2 Update `confirm_proposal` RPC Function**

```sql
-- Drop and recreate function with group_id population
DROP FUNCTION IF EXISTS confirm_proposal(UUID, UUID);

CREATE OR REPLACE FUNCTION confirm_proposal(
  p_proposal_id UUID,
  p_option_id UUID
)
RETURNS UUID  -- NOTE: This will be changed in blocker fix to UUID[] or SETOF UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_proposal event_proposals%ROWTYPE;
  v_time_option proposal_time_options%ROWTYPE;
  v_event_id UUID;
BEGIN
  -- [Existing security checks and validation - omitted for brevity]

  -- Fetch proposal to get group_id
  SELECT * INTO v_proposal FROM event_proposals WHERE id = p_proposal_id;
  SELECT * INTO v_time_option FROM proposal_time_options WHERE id = p_option_id;

  -- Create events for all YES voters with group_id
  INSERT INTO events (
    user_id,
    title,
    description,
    location,
    start_time,
    end_time,
    visibility,
    group_id,  -- NEW: Include group_id
    created_at
  )
  SELECT
    pv.user_id,
    v_proposal.title,
    v_proposal.description,
    v_proposal.location,
    v_time_option.start_time,
    v_time_option.end_time,
    'sharedWithName',
    v_proposal.group_id,  -- NEW: Copy from proposal
    now()
  FROM proposal_votes pv
  WHERE pv.option_id = p_option_id
    AND pv.vote = 'yes'
  RETURNING id INTO v_event_id;

  -- [Rest of function - notifications, etc. - omitted for brevity]

  RETURN v_event_id;
END;
$$;

GRANT EXECUTE ON FUNCTION confirm_proposal TO authenticated;
```

**Testing:**
```sql
-- Test in Supabase SQL Editor:
-- 1. Create a test proposal
-- 2. Confirm it
-- 3. Verify events have group_id populated:
SELECT id, title, group_id FROM events WHERE group_id IS NOT NULL ORDER BY created_at DESC LIMIT 5;
```

---

### Phase 2: Data Layer (Flutter) (1 hour)

**2.1 Update EventModel**

File: `application/lockitin_app/lib/data/models/event_model.dart`

```dart
class EventModel extends Equatable {
  final String id;
  final String userId;
  final String? groupId;      // Already exists
  final String? groupName;    // NEW: From JOIN
  final String? groupEmoji;   // NEW: From JOIN
  // ... existing fields (title, startTime, endTime, etc.)

  const EventModel({
    required this.id,
    required this.userId,
    this.groupId,
    this.groupName,    // NEW
    this.groupEmoji,   // NEW
    // ... existing fields
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    // Handle nested groups data from Supabase JOIN
    // Note: Using 'group' alias (singular) per Supabase convention
    final groupData = json['group'] as Map<String, dynamic>?;

    // Helper to parse timestamps (existing)
    DateTime parseTimestamp(dynamic value, bool ensureUtc) {
      if (value is DateTime) {
        return ensureUtc ? value.toUtc() : value;
      } else if (value is String) {
        return ensureUtc ? TimezoneUtils.parseUtc(value) : DateTime.parse(value);
      } else {
        throw ArgumentError('Invalid timestamp type: ${value.runtimeType}');
      }
    }

    final allDay = json['all_day'] as bool? ?? false;

    return EventModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      groupId: json['group_id'] as String?,
      groupName: groupData?['name'] as String?,    // NEW
      groupEmoji: groupData?['emoji'] as String?,  // NEW
      // ... existing field parsing
      startTime: parseTimestamp(json['start_time'], !allDay),
      endTime: parseTimestamp(json['end_time'], !allDay),
      // ... rest of fields
    );
  }

  @override
  List<Object?> get props => [
    id, userId, groupId, groupName, groupEmoji,  // NEW: Add to props
    // ... existing props
  ];
}
```

**2.2 Update Calendar Queries with JOIN**

File: `application/lockitin_app/lib/core/services/event_service.dart`

```dart
class EventService {
  static final EventService instance = EventService._internal();
  EventService._internal();

  /// Fetch events with group information using Supabase JOIN
  Future<List<EventModel>> getEventsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final data = await supabase
      .from('events')
      .select('''
        *,
        group:groups(name, emoji)
      ''')  // Note: Use 'group:groups' alias, NOT 'groups!events_group_id_fkey'
      .eq('user_id', supabase.auth.currentUser!.id)
      .gte('start_time', startDate.toIso8601String())
      .lte('end_time', endDate.toIso8601String())
      .order('start_time');

    return data.map((json) => EventModel.fromJson(json)).toList();
  }
}
```

**Why this JOIN syntax:**
- Uses `group:groups(...)` instead of `groups!events_group_id_fkey(...)`
- Doesn't assume FK constraint name (more robust)
- Supabase auto-detects relationship via `group_id` column

---

### Phase 3: UI Component (2 hours)

**3.1 Create GroupBadge Widget**

File: `application/lockitin_app/lib/presentation/widgets/group_badge.dart`

```dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../screens/group_detail/group_detail_screen.dart';
import '../routes/slide_route.dart';

/// Displays a badge indicating which group an event belongs to.
///
/// Shows "[Deleted]" in gray if group no longer exists (groupName is null).
/// Auto-truncates text with ellipsis when space is limited.
class GroupBadge extends StatelessWidget {
  final String? groupId;
  final String? groupName;
  final String? groupEmoji;

  const GroupBadge({
    super.key,
    required this.groupId,
    required this.groupName,
    this.groupEmoji,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    // Determine if group was deleted (groupId exists but name is null)
    final isDeleted = groupName == null && groupId != null;

    // Badge color: grayed if deleted, violet otherwise
    final badgeColor = isDeleted
      ? appColors.textDisabled
      : AppColors.categoryFriend;  // Violet

    // Display text: emoji if available, else name, else "[Deleted]"
    final displayText = groupEmoji ?? groupName ?? '[Deleted]';

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.group_rounded,
            size: 12,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          // Flexible + TextOverflow handles auto-truncation
          Flexible(
            child: Text(
              displayText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: badgeColor,
              ),
              overflow: TextOverflow.ellipsis,  // Auto-truncate
              maxLines: 1,
            ),
          ),
        ],
      ),
    );

    // Make tappable only if group exists (not deleted)
    if (!isDeleted && groupId != null) {
      return GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            SlideRoute(
              page: GroupDetailScreen(groupId: groupId!),
            ),
          );
        },
        child: badge,
      );
    }

    // Deleted groups: non-tappable
    return badge;
  }
}
```

**Widget Features:**
- Single widget (no compact/full modes - Flutter handles overflow)
- Auto-truncates with `TextOverflow.ellipsis`
- Grayed styling for deleted groups
- Non-tappable when group is deleted
- 45 lines (vs 150 in original plan)

**3.2 Integrate into Month View**

File: `application/lockitin_app/lib/presentation/screens/calendar_screen.dart`

```dart
// Inside _buildCalendarCell method (around Lines 593-636)

Widget _buildCalendarCell(BuildContext context, int day, bool isCurrentMonth) {
  final colorScheme = Theme.of(context).colorScheme;
  final appColors = context.appColors;

  final eventsForDay = _getEventsForDay(day);
  final isToday = _isToday(day);

  // Find first group event for badge
  final firstGroupEvent = eventsForDay.firstWhereOrNull((e) => e.groupId != null);

  return GestureDetector(
    onTap: () => _handleDayTap(day),
    child: Container(
      decoration: BoxDecoration(
        color: isToday ? colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Day number (centered)
          Center(
            child: Text(
              '$day',
              style: TextStyle(
                color: isCurrentMonth ? colorScheme.onSurface : appColors.textMuted,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),

          // Event count badge (existing - top right)
          if (eventsForDay.isNotEmpty)
            Positioned(
              top: 4,
              right: 4,
              child: _buildEventCountBadge(eventsForDay.length),
            ),

          // Event category dots (existing - bottom center)
          if (eventsForDay.isNotEmpty)
            Positioned(
              bottom: 4,
              left: 0,
              right: 0,
              child: _buildEventDots(eventsForDay),
            ),

          // Group badge (NEW - bottom left)
          if (firstGroupEvent != null)
            Positioned(
              bottom: 18,  // Above event dots
              left: 4,
              child: GroupBadge(
                groupId: firstGroupEvent.groupId,
                groupName: firstGroupEvent.groupName,
                groupEmoji: firstGroupEvent.groupEmoji,
              ),
            ),
        ],
      ),
    ),
  );
}
```

**3.3 Integrate into Day Timeline View**

File: `application/lockitin_app/lib/presentation/widgets/day_timeline_view.dart`

```dart
// Inside _buildEventCard method (around Lines 370-497)

Widget _buildEventCard(EventModel event) {
  final colorScheme = Theme.of(context).colorScheme;
  final appColors = context.appColors;

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border(
        left: BorderSide(
          color: _getPrivacyColor(event.visibility),
          width: 3,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time range
          Text(
            _formatTimeRange(event.startTime, event.endTime),
            style: TextStyle(
              fontSize: 12,
              color: appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),

          // Event title
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          // Group badge (NEW - if event from group)
          if (event.groupId != null) ...[
            const SizedBox(height: 8),
            GroupBadge(
              groupId: event.groupId,
              groupName: event.groupName,
              groupEmoji: event.groupEmoji,
            ),
          ],

          // Location (existing)
          if (event.location != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: appColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    event.location!,
                    style: TextStyle(
                      fontSize: 14,
                      color: appColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Privacy indicator (existing)
          const SizedBox(height: 8),
          _buildPrivacyBadge(event.visibility),
        ],
      ),
    ),
  );
}
```

---

### Phase 4: Testing & Verification (30 minutes)

**4.1 Manual Testing Checklist**

- [ ] Create group proposal with 3 voters
- [ ] Confirm proposal → Verify 3 events created with same `group_id`
- [ ] Check month view → Group badge visible on days with group events
- [ ] Check day detail → Group badge visible in event cards
- [ ] Tap badge → Navigates to GroupDetailScreen
- [ ] Delete group → Events show "[Deleted]" badge in gray
- [ ] "[Deleted]" badge is non-tappable
- [ ] Personal events (no group_id) show no badge
- [ ] Long group name auto-truncates with "..." ellipsis

**4.2 Database Verification**

```sql
-- Verify group_id is populated
SELECT id, title, group_id, created_at
FROM events
WHERE group_id IS NOT NULL
ORDER BY created_at DESC
LIMIT 10;

-- Verify FK constraint exists
SELECT constraint_name, table_name
FROM information_schema.table_constraints
WHERE table_name = 'events'
  AND constraint_type = 'FOREIGN KEY'
  AND constraint_name LIKE '%group%';

-- Test ON DELETE SET NULL behavior
-- (Don't run in production!)
-- DELETE FROM groups WHERE id = '...test-group-id...';
-- SELECT group_id FROM events WHERE id = '...test-event-id...';
-- Should return NULL
```

**4.3 Edge Cases to Test**

| Scenario | Expected Behavior |
|----------|-------------------|
| Group event in month view | Badge shows below event title |
| Multiple group events same day | Only first badge shown (space limit) |
| Personal event (no group_id) | No badge rendered |
| Deleted group (group_id but name NULL) | "[Deleted]" badge, grayed, non-tappable |
| User left group (RLS blocks JOIN) | Same as deleted (NULL name) |
| Long group name (20+ chars) | Auto-truncates with ellipsis |
| Emoji in group name | Shows emoji instead of text |

---

## Acceptance Criteria

### Functional Requirements

- [ ] Events created from confirmed proposals have `group_id` populated automatically
- [ ] Month view displays group badge for events with `group_id`
- [ ] Day detail view displays group badge for events with `group_id`
- [ ] Tapping group badge navigates to GroupDetailScreen
- [ ] Events without `group_id` show no badge
- [ ] Deleted groups show "[Deleted]" badge (grayed, non-tappable)

### Visual Requirements

- [ ] Badge uses violet color (`AppColors.categoryFriend`)
- [ ] Badge has 15% alpha background, 30% alpha border
- [ ] Badge auto-truncates long text with ellipsis
- [ ] Badge aligns consistently with other metadata
- [ ] Badge respects dark mode theme

### Performance Requirements

- [ ] Calendar queries use single JOIN (no N+1 queries)
- [ ] Month view renders smoothly (no lag)
- [ ] Badge tap responds immediately (<100ms)

### Quality Requirements

- [ ] No null pointer exceptions with deleted groups
- [ ] RLS-blocked groups handled gracefully (NULL name)
- [ ] Migration tested on staging data before production

## Success Metrics

**Adoption:**
- % of group events displaying badges correctly (target: 100%)
- Tap-through rate on group badges (track in analytics)

**Quality:**
- No crashes related to null `group_id` or deleted groups
- Query performance <200ms for month view load

## Dependencies & Risks

**Dependencies:**
- ⚠️ **BLOCKER:** Fix `confirm_proposal` return type bug (separate PR required)
- EventModel serialization update
- GroupDetailScreen (navigation target)

**Risks:**

| Risk | Impact | Mitigation |
|------|--------|------------|
| Migration breaks existing events | HIGH | Test on staging first, have rollback plan |
| Deleted groups cause crashes | MEDIUM | Null checks, graceful "[Deleted]" fallback |
| JOIN query slow | LOW | FK already indexed, Supabase optimizes JOINs |

## References & Research

### Internal References

**Database Schema:**
- Events table: `/supabase/migrations/012_create_proposals_voting_tables.sql`
- Confirm proposal RPC: `/supabase/migrations/014_fix_proposal_event_creation.sql`

**Flutter Models:**
- EventModel: `/application/lockitin_app/lib/data/models/event_model.dart:26` (groupId field)
- GroupModel: `/application/lockitin_app/lib/data/models/group_model.dart`

**UI Components:**
- Calendar month view: `/application/lockitin_app/lib/presentation/screens/calendar_screen.dart:480-685`
- Day timeline: `/application/lockitin_app/lib/presentation/widgets/day_timeline_view.dart:370-497`
- SlideRoute: `/application/lockitin_app/lib/presentation/routes/slide_route.dart`

### External References

**Supabase:**
- [Flutter: Fetch data | Supabase Docs](https://supabase.com/docs/reference/dart/select)
- [Querying Joins | Supabase Docs](https://supabase.com/docs/guides/database/joins-and-nesting)

**Flutter:**
- [TextOverflow.ellipsis | Flutter API](https://api.flutter.dev/flutter/painting/TextOverflow.html)
- [Navigator.push | Flutter API](https://api.flutter.dev/flutter/widgets/Navigator/push.html)

### Related Work

- Issue #226: Original feature request
- PR #250: Timezone standardization (related calendar work)

## Rollback Plan

If migration causes issues in production:

```sql
-- 1. Revert confirm_proposal function to previous version
DROP FUNCTION IF EXISTS confirm_proposal(UUID, UUID);
-- (Restore from migration 014_fix_proposal_event_creation.sql)

-- 2. Remove FK constraint (optional - won't break anything)
ALTER TABLE events DROP CONSTRAINT IF EXISTS fk_events_group_id;

-- Note: Existing events with group_id will keep the value
-- New proposals won't populate group_id until migration is re-applied
```

## Post-MVP Enhancements (Out of Scope)

These were removed from the plan based on code review feedback:

1. ~~Shadow calendar `group_id` column~~ - No current use case
2. ~~Group name caching layer~~ - JOIN already provides data
3. ~~Separate compact/full badge modes~~ - TextOverflow handles this
4. ~~Error dialog for users who left groups~~ - RLS + NULL handles gracefully
5. ~~Loading states for group data~~ - JOIN is atomic
6. **Accessibility labels** - Deferred to post-MVP accessibility audit

**Future Considerations:**
- Filter calendar to show "only group events"
- Color-code events by group (use group.color for background)
- Show participant avatars for group events
- Notify group when member reschedules event

## Code Review Changes

This plan was revised based on feedback from:

**@agent-dhh-rails-reviewer:**
- Removed unnecessary caching layer (JOIN is the cache)
- Simplified GroupBadge widget (no compact/full modes)
- Deleted shadow_calendar.group_id (YAGNI violation)

**@agent-kieran-rails-reviewer:**
- Fixed JOIN syntax (use `group:groups` not `groups!fkey_name`)
- Added blocker note for confirm_proposal return type bug
- Removed EventModel bloat (no groupColor - doesn't exist)
- Added database testing section

**@agent-code-simplicity-reviewer:**
- Cut 200+ lines of unnecessary code
- Reduced implementation time from 13 hours to 4 hours (69% reduction)
- Removed 5 YAGNI violations (caching, shadow_calendar, loading states, left group dialog, accessibility defer)
- Simplified to single-mode widget with auto-truncation

**Total Simplification:** 70% less code, 69% less time, same user value.
