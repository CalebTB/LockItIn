# Feature Plan: Show Group Name on Calendar Events

**Issue:** #226
**Branch:** `feature/show-group-on-calendar-events`
**Goal:** Display which group an event belongs to when viewing the personal calendar

---

## Current State Analysis

### Database Schema (Migration 014)
When a proposal is confirmed via `confirm_proposal()` function:
- Events are created for all YES voters
- Fields populated: `user_id`, `title`, `description`, `location`, `start_time`, `end_time`, `visibility`
- **MISSING:** No `group_id` or `proposal_id` is stored with the event

### Event Model (`event_model.dart`)
Current fields:
```dart
class EventModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final EventVisibility visibility;
  final EventCategory category;
  final String? emoji;
  final String? nativeCalendarId;
  // ❌ NO group_id or proposal_id
}
```

### Current UI (`agenda_event_card.dart`)
Event card displays:
- **Left:** 4px colored accent bar (category color)
- **Middle-Left:** Time (56px width)
- **Middle:** Title + emoji, location (if present)
- **Right:** Privacy badge (lock/visibility icon)

**Layout structure:**
```
┌─────────────────────────────────────────────┐
│ │ 9:00 AM  📅 Team Meeting          🔓     │
│█│ 10:00AM     Google Meet                  │
└─────────────────────────────────────────────┘
 ▲   ▲         ▲                      ▲
 │   │         │                      │
bar time    details              privacy
```

---

## Implementation Plan

### Phase 1: Database Schema Changes

**Migration: `017_add_group_and_proposal_to_events.sql`**

```sql
-- Add group_id and proposal_id to events table
ALTER TABLE events
ADD COLUMN group_id UUID REFERENCES groups(id) ON DELETE SET NULL,
ADD COLUMN proposal_id UUID REFERENCES event_proposals(id) ON DELETE SET NULL;

-- Add index for efficient group event queries
CREATE INDEX idx_events_group_id ON events(group_id) WHERE group_id IS NOT NULL;
CREATE INDEX idx_events_proposal_id ON events(proposal_id) WHERE proposal_id IS NOT NULL;

-- Update confirm_proposal to include group_id and proposal_id
DROP FUNCTION IF EXISTS confirm_proposal(UUID, UUID);
CREATE OR REPLACE FUNCTION confirm_proposal(
  p_proposal_id UUID,
  p_option_id UUID
)
RETURNS UUID AS $$
DECLARE
  v_proposal event_proposals%ROWTYPE;
  v_time_option proposal_time_options%ROWTYPE;
  v_creator_event_id UUID;
  v_event_count INTEGER;
BEGIN
  -- Fetch proposal
  SELECT * INTO v_proposal FROM event_proposals WHERE id = p_proposal_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Proposal not found: %', p_proposal_id;
  END IF;

  -- Validate user is creator
  IF v_proposal.created_by != auth.uid() THEN
    RAISE EXCEPTION 'Only proposal creator can confirm';
  END IF;

  -- Validate status
  IF v_proposal.status != 'voting' THEN
    RAISE EXCEPTION 'Proposal status must be "voting", current: %', v_proposal.status;
  END IF;

  -- Fetch time option
  SELECT * INTO v_time_option
  FROM proposal_time_options
  WHERE id = p_option_id AND proposal_id = p_proposal_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Time option not found or does not belong to proposal';
  END IF;

  -- Create events for all YES voters WITH group_id and proposal_id
  INSERT INTO events (
    user_id,
    title,
    description,
    location,
    start_time,
    end_time,
    visibility,
    group_id,          -- NEW
    proposal_id,       -- NEW
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
    v_proposal.group_id,    -- NEW
    v_proposal.id,          -- NEW
    now()
  FROM proposal_votes pv
  WHERE pv.time_option_id = p_option_id
    AND pv.vote = 'yes';

  GET DIAGNOSTICS v_event_count = ROW_COUNT;

  -- Get the creator's event ID
  SELECT id INTO v_creator_event_id
  FROM events
  WHERE user_id = v_proposal.created_by
    AND title = v_proposal.title
    AND start_time = v_time_option.start_time
  ORDER BY created_at DESC
  LIMIT 1;

  -- Update proposal status
  UPDATE event_proposals
  SET
    status = 'confirmed',
    confirmed_time_option_id = p_option_id,
    confirmed_event_id = v_creator_event_id,
    updated_at = now()
  WHERE id = p_proposal_id;

  -- Notify all group members
  INSERT INTO notifications (
    user_id,
    type,
    title,
    message,
    related_proposal_id,
    created_at
  )
  SELECT
    gm.user_id,
    'proposal_confirmed',
    'Event Confirmed: ' || v_proposal.title,
    'The event "' || v_proposal.title || '" has been scheduled for ' ||
      to_char(v_time_option.start_time AT TIME ZONE 'UTC', 'Mon DD at HH12:MI AM'),
    v_proposal.id,
    now()
  FROM group_members gm
  WHERE gm.group_id = v_proposal.group_id;

  RETURN v_creator_event_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION confirm_proposal(UUID, UUID) TO authenticated;

-- Backfill existing events (if any exist from proposals)
-- Match events to proposals by title, start_time, and user being a group member
UPDATE events e
SET
  group_id = ep.group_id,
  proposal_id = ep.id
FROM event_proposals ep
WHERE e.title = ep.title
  AND e.start_time = (
    SELECT pto.start_time
    FROM proposal_time_options pto
    WHERE pto.id = ep.confirmed_time_option_id
  )
  AND e.user_id IN (
    SELECT user_id
    FROM group_members
    WHERE group_id = ep.group_id
  )
  AND ep.status = 'confirmed'
  AND e.group_id IS NULL;  -- Only update if not already set
```

---

### Phase 2: Flutter Data Model Changes

**File: `lib/data/models/event_model.dart`**

```dart
class EventModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final EventVisibility visibility;
  final EventCategory category;
  final String? emoji;
  final String? nativeCalendarId;

  // NEW: Group association fields
  final String? groupId;
  final String? proposalId;

  // NEW: Populated when fetched with JOIN
  final String? groupName;
  final String? groupEmoji;

  final DateTime createdAt;
  final DateTime? updatedAt;

  const EventModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    required this.visibility,
    this.category = EventCategory.other,
    this.emoji,
    this.nativeCalendarId,
    this.groupId,           // NEW
    this.proposalId,        // NEW
    this.groupName,         // NEW
    this.groupEmoji,        // NEW
    required this.createdAt,
    this.updatedAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      location: json['location'] as String?,
      visibility: _visibilityFromString(json['visibility'] as String),
      category: json['category'] != null
          ? _categoryFromString(json['category'] as String)
          : EventCategory.other,
      emoji: json['emoji'] as String?,
      nativeCalendarId: json['native_calendar_id'] as String?,
      groupId: json['group_id'] as String?,        // NEW
      proposalId: json['proposal_id'] as String?,  // NEW
      groupName: json['group_name'] as String?,    // NEW (from JOIN)
      groupEmoji: json['group_emoji'] as String?,  // NEW (from JOIN)
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'location': location,
      'visibility': _visibilityToString(visibility),
      'category': _categoryToString(category),
      'native_calendar_id': nativeCalendarId,
      'group_id': groupId,        // NEW
      'proposal_id': proposalId,  // NEW
      // Note: groupName and groupEmoji are read-only from JOINs
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Update copyWith to include new fields
  EventModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    EventVisibility? visibility,
    EventCategory? category,
    String? emoji,
    String? nativeCalendarId,
    String? groupId,         // NEW
    String? proposalId,      // NEW
    String? groupName,       // NEW
    String? groupEmoji,      // NEW
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      visibility: visibility ?? this.visibility,
      category: category ?? this.category,
      emoji: emoji ?? this.emoji,
      nativeCalendarId: nativeCalendarId ?? this.nativeCalendarId,
      groupId: groupId ?? this.groupId,              // NEW
      proposalId: proposalId ?? this.proposalId,      // NEW
      groupName: groupName ?? this.groupName,        // NEW
      groupEmoji: groupEmoji ?? this.groupEmoji,      // NEW
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        startTime,
        endTime,
        location,
        visibility,
        category,
        emoji,
        nativeCalendarId,
        groupId,       // NEW
        proposalId,    // NEW
        groupName,     // NEW
        groupEmoji,    // NEW
        createdAt,
        updatedAt,
      ];
}
```

---

### Phase 3: Update Event Fetching to Include Group Info

**File: `lib/core/services/event_service.dart`**

Update query to LEFT JOIN with groups table:

```dart
Future<List<EventModel>> getUserEvents({
  DateTime? startDate,
  DateTime? endDate,
}) async {
  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) {
    throw Exception('User not authenticated');
  }

  // Query with LEFT JOIN to get group info
  var query = _supabase
      .from('events')
      .select('''
        *,
        groups:group_id (
          name,
          emoji
        )
      ''')
      .eq('user_id', userId);

  if (startDate != null) {
    query = query.gte('start_time', startDate.toIso8601String());
  }

  if (endDate != null) {
    query = query.lte('start_time', endDate.toIso8601String());
  }

  final response = await query.order('start_time');

  return (response as List).map((json) {
    // Flatten group data into event JSON
    if (json['groups'] != null) {
      json['group_name'] = json['groups']['name'];
      json['group_emoji'] = json['groups']['emoji'];
    }
    return EventModel.fromJson(json);
  }).toList();
}
```

---

### Phase 4: Update UI to Show Group Badge

**Option A: Add below title (Recommended)**

```
┌─────────────────────────────────────────────┐
│ │ 9:00 AM  📅 Team Meeting          🔓     │
│█│ 10:00AM  👥 Work Squad                    │
└─────────────────────────────────────────────┘
 ▲   ▲         ▲                      ▲
 │   │      title + group            privacy
bar time
```

**Option B: Add to right side (Alternative)**

```
┌─────────────────────────────────────────────┐
│ │ 9:00 AM  📅 Team Meeting  👥 Squad  🔓   │
│█│ 10:00AM                                   │
└─────────────────────────────────────────────┘
```

**File: `lib/presentation/widgets/agenda_event_card.dart`**

```dart
Widget build(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  final appColors = context.appColors;
  final accentColor = _getCategoryColor(event.category, colorScheme);

  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: appColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: appColors.cardBorder,
          width: 1,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Colored accent bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            // Event content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    // Time column
                    SizedBox(
                      width: 56,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isAllDayEvent(event))
                            Text('All day', ...)
                          else ...[
                            Text(_formatTime(event.startTime), ...),
                            Text(_formatTime(event.endTime), ...),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Event details
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title with emoji
                          Row(
                            children: [
                              if (event.emoji != null) ...[
                                Text(event.emoji!, ...),
                                const SizedBox(width: 6),
                              ],
                              Expanded(
                                child: Text(event.title, ...),
                              ),
                            ],
                          ),
                          // GROUP BADGE - NEW
                          if (event.groupId != null && event.groupName != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: _buildGroupBadge(context, appColors, colorScheme),
                            ),
                          // Location
                          if (event.location != null && event.location!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(...), // existing location row
                            ),
                        ],
                      ),
                    ),
                    // Privacy badge
                    _buildPrivacyBadge(context, appColors, colorScheme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// NEW: Group badge widget
Widget _buildGroupBadge(
  BuildContext context,
  AppColorsExtension appColors,
  ColorScheme colorScheme,
) {
  return GestureDetector(
    onTap: () {
      // Navigate to group detail screen
      Navigator.of(context).pushNamed(
        '/group-detail',
        arguments: event.groupId,
      );
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (event.groupEmoji != null) ...[
            Text(
              event.groupEmoji!,
              style: const TextStyle(fontSize: 10),
            ),
            const SizedBox(width: 3),
          ],
          Icon(
            Icons.people_outline,
            size: 11,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              event.groupName!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colorScheme.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );
}
```

---

## Design Considerations

### Visual Treatment Options

**1. Subtle Badge (Recommended)**
- Small badge below title
- Group emoji + name
- Tappable to navigate to group
- Primary color with light background

**2. Icon-Only**
- Just a group icon next to title
- Show group name on long-press/tooltip

**3. Colored Border**
- Use different border color for group events
- Could conflict with category color system

### User Experience

**Navigation:**
- Tapping group badge → Navigate to Group Detail Screen
- Shows context: "This event is from [Group Name]"
- User can see who else has the event

**Visual Hierarchy:**
```
Priority 1: Event title (most prominent)
Priority 2: Time
Priority 3: Group badge (NEW - helps with context)
Priority 4: Location
Priority 5: Privacy badge
```

### Edge Cases

1. **Event has no group** (personal event or manual event)
   - Don't show badge

2. **Group was deleted**
   - Show badge but disable tap (or show "Deleted Group")

3. **User left the group**
   - Badge should still show (event is still in their calendar)
   - Tap behavior: Show "You're no longer in this group" message

4. **Long group names**
   - Truncate with ellipsis after 20 characters
   - Full name in tooltip

---

## Implementation Checklist

### Backend (Database)
- [ ] Create Migration 017
- [ ] Add `group_id` and `proposal_id` columns to events table
- [ ] Add indexes for performance
- [ ] Update `confirm_proposal()` function
- [ ] Backfill existing events (if any)
- [ ] Apply migration to database
- [ ] Verify with test proposal

### Data Layer (Flutter)
- [ ] Update `EventModel` class with new fields
- [ ] Update `fromJson()` to parse group_id, proposal_id, group_name, group_emoji
- [ ] Update `toJson()` to include new fields
- [ ] Update `copyWith()` method
- [ ] Update `props` list for Equatable
- [ ] Update `event_service.dart` query to JOIN groups table
- [ ] Add tests for updated EventModel

### UI Layer (Flutter)
- [ ] Update `agenda_event_card.dart` to show group badge
- [ ] Create `_buildGroupBadge()` widget
- [ ] Add navigation to group detail on badge tap
- [ ] Update `upcoming_event_card.dart` (if used)
- [ ] Update `day_timeline_view.dart` event display
- [ ] Test visual layout on different screen sizes
- [ ] Test long group names (truncation)
- [ ] Add accessibility labels for group badge

### Testing
- [ ] Test creating new proposal → confirm → verify group shows on event
- [ ] Test events without groups (don't show badge)
- [ ] Test deleted group scenario
- [ ] Test navigation to group detail
- [ ] Test on iOS and Android
- [ ] Widget tests for `AgendaEventCard` with/without group

### Documentation
- [ ] Update `EVENT_MODEL.md` (if exists) with new fields
- [ ] Add screenshots to PR showing before/after
- [ ] Document migration steps

---

## Success Metrics

**User Value:**
- Users can instantly see which events are group-coordinated
- Quick navigation to group context
- Reduces confusion about event source

**Technical:**
- Database query remains performant (<100ms)
- UI doesn't feel cluttered
- Backwards compatible (old events without group_id work fine)

---

## Questions for User

1. **Visual treatment preference?**
   - Option A: Badge below title
   - Option B: Badge to right of title
   - Option C: Different border color for group events

2. **What happens when tapping group badge?**
   - Navigate to Group Detail Screen? (recommended)
   - Show modal with group members?
   - Just show group name (non-interactive)?

3. **Show for all group events or only proposal-created events?**
   - Currently scoped to proposal-created events (have proposal_id)
   - Could expand to manually-created events if user assigns them to a group

4. **Backfill existing events?**
   - Try to match existing confirmed proposal events?
   - Or only apply to new events going forward?
