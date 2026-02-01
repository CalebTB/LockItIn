# Common Mistakes in Flutter + Supabase Development

This reference documents the most common mistakes made during Flutter + Supabase development and how to avoid them.

## Source

Based on post-mortem analysis from Event Templates (Surprise Party) implementation:
- **Documentation:** `docs/solutions/workflow-issues/ai-agent-not-consulting-existing-code-event-templates-20260114.md`
- **GitHub Issues:** #237-#246 (technical debt items)
- **Date:** 2026-01-14

## Architecture & Design Mistakes

### 1. Not Reading Existing Code Before Implementing

**Mistake:** Implemented features without searching for similar patterns in the codebase.

**Impact:**
- Duplicate code when reusable patterns existed
- Inconsistent coding styles
- Missed opportunities for code reuse
- Time wasted rebuilding what already exists

**How to Avoid:**

```bash
# ALWAYS run these before implementing:
grep -r "keyword" lib/
grep -r "SimilarWidget" lib/presentation/
grep -r "showModalBottomSheet" lib/

# Read related files:
# - How does this work elsewhere?
# - What patterns exist?
# - Can I reuse existing code?
```

**Rule:** Never write code without reading existing implementations first.

### 2. Building Without Clarifying Requirements

**Mistake:** Built hierarchical coordinator/member access model without asking user's intent.

**Impact:**
- Wasted ~30% development time on rework
- Had to refactor entire access model mid-implementation
- User frustration from wrong assumptions

**How to Avoid:**

Ask BEFORE building:
- "Should coordinators have special privileges, or equal access?"
- "What's the expected group size?"
- "What edge cases should I handle?"

**Rule:** Don't assume - confirm requirements upfront.

### 3. Inefficient Database Schema Design

**Mistake:** Stored coordinator IDs in JSONB array instead of separate table.

**Impact:**
- RLS policies run expensive JSONB parsing on EVERY SELECT query
- Cannot use indexes efficiently
- Scales poorly (50+ coordinators = slow queries)
- No referential integrity

**Example of Bad Design:**

```sql
-- Stored in JSONB (bad!)
template_data: {
  "coordinator_ids": ["uuid1", "uuid2", ...]
}

-- RLS policy parses JSONB on every query
CREATE POLICY "..."
USING (
  auth.uid()::text = ANY(
    SELECT jsonb_array_elements_text(...)  -- Expensive!
  )
);
```

**How to Avoid:**

Use proper relational design:

```sql
CREATE TABLE event_coordinators (
  event_id UUID REFERENCES events(id),
  user_id UUID REFERENCES users(id),
  PRIMARY KEY (event_id, user_id)
);
CREATE INDEX idx_coordinators_user ON event_coordinators(user_id);
```

**Rule:** JSONB is for flexible metadata, NOT for relationships or access control.

## Database Configuration Mistakes

### 4. Forgetting to Enable Realtime

**Mistake:** Implemented WebSocket client code without checking if table was in realtime publication.

**Impact:**
- RSVP updates only appeared after hot restart, not real-time
- Spent 20 minutes debugging client code when issue was database config
- Users saw stale data

**How to Avoid:**

BEFORE implementing client-side WebSocket code:

```sql
-- Check if table is enabled
SELECT * FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
AND tablename = 'your_table';

-- If not, enable it:
ALTER PUBLICATION supabase_realtime ADD TABLE your_table;
```

**Rule:** Verify full-stack configuration BEFORE writing client code.

### 5. Incomplete RLS Policies

**Mistake:** RLS policy only allowed users to see their own invitation OR all if they created the event. Didn't account for coordinators who weren't event creators.

**Impact:**
- Dashboard showed 1/12 invitations instead of all
- Had to create emergency migration mid-development

**How to Avoid:**

Think through ALL access patterns:
- Who can view this data?
- Who can edit this data?
- What about special roles (coordinators, admins, etc.)?

Test RLS policies with different user roles:

```sql
-- Test as coordinator (not creator)
SET ROLE authenticated;
SET request.jwt.claims.sub = 'coordinator-uuid';
SELECT * FROM event_invitations WHERE event_id = 'test-event';
```

**Rule:** Design RLS policies AFTER fully understanding all user roles and access needs.

## Performance Mistakes

### 6. Redundant Database Queries

**Mistake:** Re-fetched ALL invitations on every realtime update instead of updating single record in state.

**Impact:**
- 12 members changing RSVP = 12 full database queries
- Each query fetches 12 invitations + 12 user joins
- Slow updates, hammers database

**Example:**

```dart
// Bad: Re-fetch everything
void _handleRSVPUpdate(RealtimePayload payload) {
  _fetchInvitations();  // Queries database again!
}
```

**How to Avoid:**

Update single record in state:

```dart
void _handleRealtimeUpdate(PostgresChangePayload payload) {
  final index = _items.indexWhere(
    (item) => item.id == payload.newRecord['id']
  );
  if (index != -1) {
    _items[index] = DataModel.fromJson(payload.newRecord);
    notifyListeners();
  }
}
```

**Rule:** Only query database when you don't have the data. Update state directly when possible.

### 7. No Query Caching

**Mistake:** Fetched user data with EVERY invitation query (12 invitations = 12 user joins).

**Impact:**
- Same user data fetched multiple times
- Slow queries
- Network overhead

**How to Avoid:**

Cache user profiles in provider:

```dart
// Fetch invitations (lightweight)
final invitations = await supabase
  .from('invitations')
  .select('id, user_id, rsvp_status');

// Batch fetch unique users (single query)
final userIds = invitations.map((inv) => inv['user_id']).toSet();
final users = await supabase
  .from('users')
  .select()
  .in_('id', userIds);

// Cache for reuse
userProvider.cacheUsers(users);
```

**Rule:** Cache slow-changing data (user profiles, metadata) instead of fetching repeatedly.

### 8. No Pagination for Large Datasets

**Mistake:** Loaded ALL invitations at once (could be 500+ with large groups).

**Impact:**
- Slow initial load
- High memory usage
- Task assignment sheet unusable with 100+ members

**How to Avoid:**

Implement pagination for lists with 50+ items:

```dart
final data = await supabase
  .from('invitations')
  .select()
  .range(0, 19)  // First 20 items
  .order('created_at', ascending: false);
```

**Rule:** If dataset is unbounded (user-generated content), implement pagination from the start.

## Testing Mistakes

### 9. Not Testing with Realistic Data

**Mistake:** Tested with 1-2 members instead of 12+.

**Impact:**
- UI overflowed by 432 pixels with 12+ members (not scrollable)
- Caught issue only after user reported it

**How to Avoid:**

Create test data BEFORE building UI:

```sql
-- Generate 50 test members
INSERT INTO group_members (group_id, user_id)
SELECT 'test-group', gen_random_uuid()
FROM generate_series(1, 50);
```

Test edge cases:
- 1 item (empty state)
- 12 items (typical case)
- 50+ items (stress test)
- 100+ items (pagination needed?)

**Rule:** Test with realistic data volumes, not just 1-2 items.

### 10. Assuming Hot Reload Works for Everything

**Mistake:** Changed realtime publication, expected hot reload to pick up changes.

**Impact:**
- No realtime updates appeared
- Wasted time expecting logs that couldn't appear
- Confusion about why WebSocket wasn't working

**Reality:** WebSocket subscriptions require FULL app restart after database config changes.

**How to Avoid:**

After database migrations that affect realtime:
1. Stop app completely
2. Full restart (not hot reload)
3. Verify subscription reconnects

Document this in migration comments:

```sql
-- NOTE: Full app restart required (not just hot reload)
ALTER PUBLICATION supabase_realtime ADD TABLE your_table;
```

**Rule:** Hot reload works for code changes, NOT database config changes.

## Code Quality Mistakes

### 11. Manual State Management

**Mistake:** Used `setState()` and manual WebSocket subscriptions instead of Provider pattern.

**Impact:**
- Subscription not cleaned up if widget rebuilds
- State scattered across multiple variables
- Hard to test
- Easy to introduce memory leaks

**How to Avoid:**

Use Provider for complex features:

```dart
class DataProvider extends ChangeNotifier {
  RealtimeChannel? _channel;

  Future<void> subscribe(String id) { ... }

  @override
  void dispose() {
    _channel?.unsubscribe();  // Guaranteed cleanup
    super.dispose();
  }
}
```

**Rule:** For stateful features with subscriptions, use Provider (not StatefulWidget).

### 12. No Error Handling

**Mistake:** Assumed WebSocket always works, no reconnection logic or fallback.

**Impact:**
- Silent failures when network drops
- Users don't see updates after connection loss
- No recovery when connection restored

**How to Avoid:**

Implement reconnection + polling fallback:

```dart
.subscribe((status, error) {
  if (status == RealtimeListenTypes.closed) {
    _scheduleReconnect();
    _startPolling();  // Fallback to polling
  }
});
```

**Rule:** Always handle connection failures for real-time features.

### 13. No Input Validation

**Mistake:** Stored unvalidated UUIDs in JSONB arrays.

**Impact:**
- Invalid UUIDs could break queries
- No size limits (1000+ coordinators could DoS database)
- No referential integrity checks

**How to Avoid:**

Validate before storing:

```dart
Future<List<String>> validateUserIds(List<String> ids) async {
  // 1. Check UUID format
  final uuidRegex = RegExp(r'^[0-9a-f]{8}-...');
  final validUuids = ids.where((id) => uuidRegex.hasMatch(id));

  // 2. Check size limit
  if (validUuids.length > 50) {
    throw ValidationException('Max 50 coordinators');
  }

  // 3. Verify users exist
  final existing = await supabase.from('users').select('id').in_('id', ids);
  if (existing.length != ids.length) {
    throw ValidationException('Invalid user IDs');
  }

  return validUuids;
}
```

**Rule:** Validate all user input before database operations.

### 14. No Rate Limiting

**Mistake:** No protection against rapid RSVP updates.

**Impact:**
- User can spam button → 100 updates/second
- Could overwhelm realtime system
- No protection against malicious abuse

**How to Avoid:**

Client-side debouncing:

```dart
Timer? _debounceTimer;

void _selectStatus(String status) {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(Duration(milliseconds: 500), () {
    _submitStatus(status);
  });
}
```

Server-side rate limiting:

```sql
CREATE OR REPLACE FUNCTION update_rsvp_with_rate_limit(...)
RETURNS VOID AS $$
BEGIN
  -- Check last update was >10 seconds ago
  IF EXTRACT(EPOCH FROM (NOW() - last_update)) < 10 THEN
    RAISE EXCEPTION 'Rate limit exceeded';
  END IF;
  -- Update...
END;
$$ LANGUAGE plpgsql;
```

**Rule:** Debounce user actions, rate limit on server.

## UI/UX Mistakes

### 15. No Loading/Empty States

**Mistake:** Jumped from empty to full list with no skeleton loader or empty state.

**Impact:**
- Jarring user experience
- Poor perceived performance
- No guidance when list is empty

**How to Avoid:**

Add proper states:

```dart
if (provider.isLoading) {
  return SkeletonLoader(itemCount: 12);
}

if (provider.items.isEmpty) {
  return EmptyState(
    icon: Icons.inbox,
    title: 'No items yet',
    message: 'Get started by creating one!',
  );
}

return ListView(...);
```

**Rule:** Every async data load needs: loading, empty, error, and success states.

### 16. Inconsistent DateTime Handling

**Mistake:** Created DateFormat instances directly, duplicated date key logic, used verbose timezone conversions instead of centralized helpers.

**Impact:**
- Performance overhead (~0.5ms per DateFormat creation on every widget build)
- Code duplication across calendar views
- Risk of inconsistent timezone handling between personal and group calendars
- Untestable time-dependent code (direct `DateTime.now()` calls)

**Example of Bad Code:**

```dart
// Creating formatters repeatedly (expensive!)
final timeFormat = DateFormat('h:mm a');
final formatted = timeFormat.format(event.startTime);

// Verbose timezone conversion
DateTime _votingDeadline = TimezoneUtils.nowUtc().toLocal().add(Duration(hours: 48));

// Duplicated date key logic
String _dateKey(DateTime date) {
  final localDate = date.toLocal();
  return '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';
}

// Untestable direct time calls
final now = DateTime.now();
```

**How to Avoid:**

Always use TimezoneUtils helpers:

```dart
// Use cached formatters (reduces overhead to ~0.1ms)
final formatted = TimezoneUtils.formatLocal(event.startTime, 'h:mm a');

// Concise timezone conversion
DateTime _votingDeadline = TimezoneUtils.nowLocal().add(Duration(hours: 48));

// Centralized date key generation
String _dateKey(DateTime date) {
  return TimezoneUtils.getDateKey(date);
}

// Testable time via Clock package
final nowUtc = TimezoneUtils.nowUtc();
final nowLocal = TimezoneUtils.nowLocal();
```

**Timezone Policy (from TimezoneUtils):**
- **Storage**: Always UTC (`DateTime.utc()` or `.toUtc()`)
- **Display**: Always local (`.toLocal()`)
- **Testing**: Use Clock package (`clock.now()`)

**Rule:** Never create DateFormat instances directly, never use `DateTime.now()` directly, never duplicate timezone logic. All datetime operations go through TimezoneUtils helpers.

**See Also:**
- [Timezone Standardization Solution](../../../docs/solutions/best-practices/timezone-date-handling-standardization-calendar-20260201.md)
- [Pattern 11 in Critical Patterns](../../../docs/solutions/patterns/flutter-supabase-critical-patterns.md#pattern-11-use-timezoneutils-helpers-for-all-datetime-operations)

## Summary Scorecard

| Category | Common Mistakes | Prevention |
|----------|----------------|------------|
| **Workflow** | Not reading existing code, no requirements clarification | Read first, ask questions upfront |
| **Database** | JSONB in RLS, forgetting realtime, incomplete policies | Use relational design, verify config, test all roles |
| **Performance** | Redundant queries, no caching, no pagination | Update state directly, cache data, paginate large lists |
| **Testing** | Testing with 1-2 items, assuming hot reload works | Create realistic test data, full restart for DB changes |
| **Code Quality** | Manual state management, no error handling, no validation | Use Provider, handle failures, validate input |
| **UI/UX** | No loading/empty states | Implement all 4 states: loading, empty, error, success |

## Post-Mortem Grade: D+

The feature works, but ~30% of development time was wasted on preventable mistakes.

**Key Lesson:** Read existing code BEFORE implementing. Clarify requirements upfront. Verify full-stack configuration. Test with realistic data.
