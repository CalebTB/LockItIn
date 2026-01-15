# Add RSVP Status to Surprise Party Dashboard

## Overview

Add real-time RSVP status tracking to the Surprise Party Dashboard, showing which invited members have accepted/declined/maybe/pending for the surprise event. This leverages the existing `event_invitations` table (migration 017) and follows established UI patterns from `group_members_section.dart`.

**Key Value:** Organizers can see at a glance who's confirmed attendance for the surprise party, helping with planning decisions (venue size, food, etc.) while maintaining the surprise for the guest of honor.

## Problem Statement / Motivation

Currently, the Surprise Party Dashboard shows:
- Event details and decoy title
- Task list with assignments
- Coordinator avatars ("IN ON IT" members)

**Missing:** Who has RSVP'd and their response status

**Impact:**
- Organizers must manually track attendance via messages/spreadsheets
- No visibility into confirmation rate ("Are enough people coming?")
- Can't identify who hasn't responded for follow-up
- Misses opportunity for social proof ("12 people are going!")

**User Need:** "I need to see if enough people confirmed before booking the venue"

## Proposed Solution

Add a new **"WHO'S COMING"** section to the Surprise Party Dashboard below the coordinator avatars, displaying:
1. **Aggregate counts:** "8/12 Responded" summary card
2. **Status-grouped member lists:**
   - ✅ Going (accepted)
   - ❓ Maybe (tentative)
   - ❌ Can't Go (declined)
   - ⏱️ Pending (no response)
3. **Real-time updates** via Supabase Realtime when members change their RSVP
4. **Member avatars** with color-coded status indicators

**Reuses existing patterns:**
- CircleAvatar with color hash from `group_members_section.dart`
- Status badges similar to vote indicators in `proposal_votes`
- Card layout consistent with existing dashboard sections

## Technical Approach

### Database Schema (Already Exists)

From migration `017_event_invitations_table.sql`:
```sql
CREATE TABLE event_invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rsvp_status rsvp_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ,

  CONSTRAINT unique_event_user UNIQUE (event_id, user_id)
);

CREATE TYPE rsvp_status AS ENUM ('pending', 'accepted', 'declined', 'maybe');
```

**RLS Policies:**
- Organizer can view all invitations for their events
- Members can view their own invitations
- Guest of honor excluded via existing template_data logic

### Data Fetching

**Option 1: Direct Query with JOIN (Recommended)**
```dart
// In SurprisePartyDashboardScreen
Future<List<Map<String, dynamic>>> _fetchInvitations() async {
  return await supabase
    .from('event_invitations')
    .select('''
      *,
      users:user_id (
        id,
        display_name,
        avatar_url
      )
    ''')
    .eq('event_id', widget.eventId)
    .order('created_at', ascending: false);
}
```

**Option 2: RPC Function (If JOIN performance issues)**
```sql
CREATE FUNCTION get_event_rsvps(p_event_id UUID)
RETURNS TABLE (...) AS $$
  SELECT ei.*, u.display_name, u.avatar_url
  FROM event_invitations ei
  JOIN users u ON ei.user_id = u.id
  WHERE ei.event_id = p_event_id;
$$;
```

### Real-Time Subscriptions

```dart
RealtimeChannel? _rsvpChannel;

void _subscribeToRSVPUpdates() {
  _rsvpChannel = supabase.channel('rsvps-${widget.eventId}');

  _rsvpChannel!
    .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'event_invitations',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'event_id',
        value: widget.eventId,
      ),
      callback: (payload) {
        setState(() {
          _handleRSVPUpdate(payload);
        });
      },
    )
    .subscribe();
}

@override
void dispose() {
  _rsvpChannel?.unsubscribe();
  super.dispose();
}
```

### UI Components

**Component Structure:**
```
SurprisePartyDashboardScreen
├── [Existing sections...]
└── _buildRSVPSection()
    ├── _buildAggregateCounts()  // "8/12 Responded" card
    └── _buildStatusGroups()
        ├── _buildStatusGroup('Going', acceptedInvitations, Icons.check_circle, Colors.green)
        ├── _buildStatusGroup('Maybe', maybeInvitations, Icons.help_outline, Colors.orange)
        ├── _buildStatusGroup('Can\'t Go', declinedInvitations, Icons.cancel, Colors.red)
        └── _buildStatusGroup('Pending', pendingInvitations, Icons.schedule, Colors.grey)
```

**Reusable Widget:**
```dart
class RSVPMemberAvatar extends StatelessWidget {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final RsvpStatus status;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: _getMemberColor(userId),
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
          child: avatarUrl == null ? Text(_getInitials(displayName)) : null,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: _getStatusColor(status),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(_getStatusIcon(status), size: 10, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
```

## Acceptance Criteria

### Functional Requirements
- [ ] Dashboard shows "WHO'S COMING" section below coordinator avatars
- [ ] Aggregate count displays "X/Y Responded" (X = accepted + declined + maybe, Y = total invited)
- [ ] Members grouped by status: Going, Maybe, Can't Go, Pending
- [ ] Each group shows member avatars with status badge overlay (checkmark, question, X, clock)
- [ ] Real-time updates when members change RSVP (avatar moves between groups, counts update)
- [ ] Empty states for groups with 0 members (section hidden or shows "No acceptances yet")
- [ ] Guest of honor CANNOT see RSVP section (hidden entirely from their view)

### Non-Functional Requirements
- [ ] Invitations load within 500ms for groups up to 50 members
- [ ] Real-time updates appear within 1 second of database change
- [ ] UI remains responsive during rapid status changes (5+ updates/second)
- [ ] Avatars use color-coded status indicators (not just color - icon + color for accessibility)
- [ ] Works offline with cached data + "Offline" indicator

### Quality Gates
- [ ] No N+1 query issues (single query fetches invitations + user data)
- [ ] WebSocket subscription cleaned up on screen dispose (no memory leaks)
- [ ] Reuses existing `_getMemberColor()` and `_getInitials()` patterns from codebase
- [ ] Status colors match app theme (`appColors.success`, `appColors.warning`, etc.)

## Technical Considerations

### Access Control
- **Organizer only:** Event creator can view RSVP section
- **Guest of honor exclusion:** If current user is `guestOfHonorId` in template_data, hide section entirely
- **RLS verification:** Test that existing policies allow organizer to query invitations

### Performance
- **Query optimization:** Use single query with JOIN rather than N+1 (fetch users per invitation)
- **Large groups:** If 50+ invitations, consider virtualization or "+N more" collapse pattern
- **Subscription scope:** Subscribe only to this event's invitations, not global table

### Error Handling
- **Network failure:** Show cached data with offline banner, manual refresh button
- **RLS denial:** Show "Access denied" if non-organizer tries to access
- **Partial data:** If some invitations fail to load, show loaded subset + error count

### Edge Cases
- **All pending:** Show motivational empty state "Invitations sent! Waiting for responses..."
- **All declined:** Show count but avoid negative messaging
- **No invitations:** Show prompt to invite members (link to group member selection?)
- **User deleted account:** Show placeholder avatar with "Removed" status
- **Invitation deleted:** Avatar fades out with animation, counts update

## Implementation Steps

### Phase 1: Data Layer
1. Create `RSVPStats` model for aggregated counts
   ```dart
   class RSVPStats {
     final int total;
     final int accepted;
     final int declined;
     final int maybe;
     final int pending;

     int get responded => accepted + declined + maybe;
   }
   ```

2. Add invitation fetching method to SurprisePartyDashboardScreen
   ```dart
   Future<List<Map<String, dynamic>>> _fetchInvitations() async { ... }
   ```

3. Implement real-time subscription with cleanup
   ```dart
   void _subscribeToRSVPUpdates() { ... }
   void _handleRSVPUpdate(PostgresChangePayload payload) { ... }
   ```

### Phase 2: UI Components
4. Create `_buildRSVPSection()` method in dashboard
   - Aggregate count card
   - Status groups (Going, Maybe, Can't Go, Pending)
   - Empty states

5. Create `RSVPMemberAvatar` widget
   - CircleAvatar with color hash
   - Status badge overlay (checkmark/question/X/clock)
   - Initials fallback for no avatar

6. Add animation for status changes
   ```dart
   AnimatedSwitcher(
     duration: Duration(milliseconds: 300),
     child: _buildStatusGroup(...),
   )
   ```

### Phase 3: Integration
7. Wire up subscription lifecycle
   - Subscribe on `initState()` after fetching initial data
   - Unsubscribe on `dispose()`
   - Refetch on `didUpdateWidget()` if eventId changes

8. Add pull-to-refresh
   ```dart
   RefreshIndicator(
     onRefresh: () async {
       final invitations = await _fetchInvitations();
       setState(() { _invitations = invitations; });
     },
     child: SingleChildScrollView(...),
   )
   ```

9. Test guest of honor exclusion
   - Verify section hidden when `currentUserId == guestOfHonorId`
   - Test with multiple users (organizer, member, guest)

### Phase 4: Polish
10. Add loading states (shimmer skeletons for avatars)
11. Add error states with retry button
12. Test with large groups (50+ invitations)
13. Verify accessibility (screen reader labels, color contrast)
14. Add analytics events (rsvp_section_viewed, rsvp_refreshed)

## Dependencies & Risks

**Dependencies:**
- ✅ `event_invitations` table exists (migration 017)
- ✅ `EventInvitationModel` exists (`lib/data/models/event_invitation_model.dart`)
- ✅ RLS policies in place
- ✅ Surprise Party Dashboard exists
- ✅ GroupProvider for user resolution
- ⚠️ Assumes `users` table has `display_name` and `avatar_url` columns

**Risks:**
- **RLS policy gaps:** Existing policies may not cover all access scenarios (organizer vs. member vs. honoree)
  - *Mitigation:* Test with multiple user roles before launch
- **Large group performance:** 100+ invitations could cause UI lag
  - *Mitigation:* Virtualize list or paginate if needed
- **WebSocket connection issues:** Network instability could cause missed updates
  - *Mitigation:* Implement reconnection logic with exponential backoff

## Success Metrics

**Engagement:**
- % of organizers who view RSVP section (target: >80% of dashboard views)
- Average time spent on dashboard increases by >20% (indicates value from RSVP data)

**Functional:**
- Real-time update latency <1 second (95th percentile)
- Query performance <500ms for groups up to 50 members

**Quality:**
- Zero reports of guest of honor seeing RSVP section (privacy maintained)
- <5% error rate on RSVP data fetching

## References & Research

### Internal References
- Surprise Party Dashboard: `lib/presentation/screens/surprise_party_dashboard_screen.dart`
- Event Invitations Model: `lib/data/models/event_invitation_model.dart`
- Event Template Model: `lib/data/models/event_template_model.dart`
- Group Members Section (avatar pattern): `lib/presentation/widgets/group_members_section.dart`
- Migration: `supabase/migrations/017_event_invitations_table.sql`

### External References
- [Supabase Realtime - Postgres Changes](https://context7.com/supabase/supabase-flutter/llms.txt)
- [Supabase Joins and Nesting](https://supabase.com/docs/guides/database/joins-and-nesting)
- [Flutter StreamBuilder Documentation](https://docs.flutter.dev/ui/widgets/async)
- [Material Design Status Indicators](https://m3.material.io/components/badges)
- [WCAG Color Contrast Requirements](https://www.w3.org/TR/WCAG21/)

### Best Practices
- Use icons + color for status (not color alone) - WCAG 1.4.1 compliance
- Minimum 4.5:1 contrast for text, 3:1 for UI components - WCAG 1.4.3
- Single query with JOIN for invitations + user data (avoid N+1)
- Unsubscribe from Realtime channels in dispose() (prevent memory leaks)
- Use `AlwaysScrollableScrollPhysics` for pull-to-refresh on short lists

### Related Work
- Issue #67: Surprise Party Template (completed - base infrastructure)
- Migration 021: Exclude guest of honor from votes (similar privacy pattern)
- PR #XXX: Group members section (avatar display pattern to reuse)

## Assumptions

1. **Access control:** Only event organizer can view RSVP section (not all group members)
2. **Status values:** RSVP status enum is `pending`, `accepted`, `declined`, `maybe` (from migration 017)
3. **Initial state:** New invitations default to `pending` status
4. **Layout:** Vertical sections, one per status, with horizontal scrollable avatar rows
5. **Empty states:** Hide sections with 0 members (don't show "Going (0)")
6. **Guest of honor:** If user is guest of honor, entire RSVP section hidden (not just data)
7. **Timestamps:** Don't show "Accepted 2h ago" timestamps (just current status)
8. **Overflow:** Show all avatars with scroll (no pagination unless performance issues)
9. **Names:** Show initials in avatar only, full name on tap/tooltip
10. **Uninvited users:** If invitation deleted, avatar disappears with fade animation

---

## Files to Create/Modify

### Create
- `lib/presentation/widgets/rsvp_member_avatar.dart` - Status badge overlay on CircleAvatar
- `lib/domain/models/rsvp_stats.dart` - Aggregate count model

### Modify
- `lib/presentation/screens/surprise_party_dashboard_screen.dart` - Add `_buildRSVPSection()` method, real-time subscription
- `lib/data/models/event_invitation_model.dart` - Add helper methods if needed (statusColor, statusIcon getters)

### Database (If needed)
- `supabase/migrations/023_event_invitations_user_join_index.sql` - Add index for JOIN performance:
  ```sql
  CREATE INDEX IF NOT EXISTS idx_event_invitations_user_lookup
  ON event_invitations(event_id, user_id);
  ```

---

## Open Questions

1. **Should members (non-organizers) see RSVP status?**
   - If yes: Add RLS policy for group members to view invitations
   - If no: Current organizer-only assumption is correct

2. **Should toast notifications appear for status changes?**
   - Example: "Alice accepted the invitation" snackbar
   - Recommendation: No (visual update is sufficient, avoid notification fatigue)

3. **Should tapping an avatar show member details?**
   - Example: Bottom sheet with name, status, "Send Reminder" button
   - Recommendation: Yes, but defer to future iteration (V2 feature)

4. **How to handle 100+ invitations (very large groups)?**
   - Recommendation: Implement if needed, start with "show all" approach

5. **Should offline cached data be used?**
   - Recommendation: Yes, cache last fetched invitations in memory, show with offline banner

---

**Last Updated:** 2026-01-14
**Author:** Claude (via /workflows:plan)
**Status:** Ready for review
