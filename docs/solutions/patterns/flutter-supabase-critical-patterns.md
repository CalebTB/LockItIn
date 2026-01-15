# Flutter + Supabase Critical Patterns - Required Reading

⚠️ **MANDATORY**: All AI agents MUST read this before implementing Flutter + Supabase features.

These patterns were learned from costly mistakes (D+ grade, 30% time wasted on rework). Following these patterns prevents repeating the same errors.

**Source:** Post-mortem analysis from Event Templates implementation (2026-01-14)
**Full Documentation:** `docs/solutions/workflow-issues/ai-agent-not-consulting-existing-code-event-templates-20260114.md`

---

## Pattern 1: Read Existing Code BEFORE Implementing

### ❌ WRONG: Start coding without research

```dart
// Agent immediately writes new code without checking codebase
void showRSVPSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (context) => RSVPSheet(),
  );
}
```

**Impact:** Duplicates existing patterns, inconsistent code style, wastes time rebuilding what exists.

### ✅ CORRECT: Search first, code second

```bash
# ALWAYS run BEFORE implementing:
grep -r "showModalBottomSheet" lib/
grep -r "RSVP" lib/
grep -r "similar_pattern" lib/

# Read related files to understand existing patterns
```

**Rule:** Never write code without reading existing implementations first. If similar functionality exists, reuse or adapt it.

---

## Pattern 2: Clarify Requirements Upfront

### ❌ WRONG: Build based on assumptions

```dart
// Assumed coordinators need special privileges
if (userRole == 'coordinator') {
  // Built hierarchical access model
  return CoordinatorDashboard();
}
```

**Impact:** Built wrong access model, wasted ~30% development time on rework.

### ✅ CORRECT: Ask questions BEFORE building

**Questions to ask:**
- "Should coordinators have special privileges, or equal access?"
- "What's the expected group size? (affects UI/performance design)"
- "Are there existing patterns I should follow?"

**Rule:** Don't assume - confirm requirements and constraints upfront. Better to ask now than rebuild later.

---

## Pattern 3: Don't Use JSONB in RLS Policies

### ❌ WRONG: JSONB array parsing in RLS

```sql
-- This runs on EVERY SELECT query (expensive!)
CREATE POLICY "coordinators_can_view"
ON event_invitations FOR SELECT
USING (
  auth.uid()::text = ANY(
    SELECT jsonb_array_elements_text(
      events.template_data->'coordinator_ids'
    )
  )
);
```

**Impact:** Expensive parsing on every query, can't use indexes, scales poorly (50+ coordinators = slow).

### ✅ CORRECT: Use separate indexed table

```sql
-- Relational design with indexed columns
CREATE TABLE event_coordinators (
  event_id UUID REFERENCES events(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  PRIMARY KEY (event_id, user_id)
);
CREATE INDEX idx_coordinators_user ON event_coordinators(user_id);

-- Fast RLS policy using index
CREATE POLICY "coordinators_can_view"
ON event_invitations FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM event_coordinators
    WHERE event_id = event_invitations.event_id
    AND user_id = auth.uid()
  )
);
```

**Rule:** JSONB is for flexible metadata, NOT for relationships or access control. Use proper tables with indexes for RLS.

---

## Pattern 4: Update Single Record in State, Don't Re-fetch All

### ❌ WRONG: Re-fetch everything on realtime update

```dart
void _handleRealtimeUpdate(PostgresChangePayload payload) {
  // Re-fetches ALL 12 invitations on EVERY update
  _fetchInvitations();
}
```

**Impact:** 12 members changing RSVP = 12 full database queries. Slow, hammers database.

### ✅ CORRECT: Update single record in state

```dart
void _handleRealtimeUpdate(PostgresChangePayload payload) {
  if (payload.eventType == PostgresChangeEvent.update) {
    final index = _items.indexWhere(
      (item) => item.id == payload.newRecord['id']
    );
    if (index != -1) {
      _items[index] = DataModel.fromJson(payload.newRecord);
      notifyListeners();
    }
  } else if (payload.eventType == PostgresChangeEvent.insert) {
    _items.add(DataModel.fromJson(payload.newRecord));
    notifyListeners();
  } else if (payload.eventType == PostgresChangeEvent.delete) {
    _items.removeWhere((item) => item.id == payload.oldRecord['id']);
    notifyListeners();
  }
}
```

**Rule:** Only query database when you don't have the data. Realtime updates give you the changed record - use it directly.

---

## Pattern 5: Use Provider for Complex Features

### ❌ WRONG: Manual state management with setState()

```dart
class _DashboardState extends State<DashboardScreen> {
  List<dynamic> _invitations = [];
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _channel = supabase.channel('invitations')...
    // Subscription not cleaned up if widget rebuilds
    // State scattered across multiple variables
  }
}
```

**Impact:** Memory leaks, subscription not cleaned up, hard to test, state management errors.

### ✅ CORRECT: Provider pattern with lifecycle management

```dart
class InvitationsProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Invitation> _items = [];
  bool _isLoading = false;
  String? _error;
  RealtimeChannel? _channel;

  Future<void> subscribe(String eventId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _supabase.from('invitations').select();
      _items = data.map((e) => Invitation.fromJson(e)).toList();

      _channel = _supabase
        .channel('invitations-$eventId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'event_invitations',
          callback: _handleUpdate,
        )
        .subscribe();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();  // Guaranteed cleanup
    super.dispose();
  }
}
```

**Rule:** For stateful features with subscriptions, use Provider (not StatefulWidget). Ensures proper cleanup and testability.

---

## Pattern 6: Check Database Config BEFORE Writing Client Code

### ❌ WRONG: Write WebSocket code without verifying database setup

```dart
// Wrote client-side realtime subscription...
_channel = supabase.channel('invitations').subscribe();

// ...but table wasn't in supabase_realtime publication!
// No updates appeared, wasted 20 minutes debugging client code
```

**Impact:** Silent failures, time wasted debugging client when issue is database config.

### ✅ CORRECT: Verify database config FIRST

```sql
-- BEFORE implementing client-side WebSocket code:
-- 1. Check if table is in realtime publication
SELECT * FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
AND tablename = 'event_invitations';

-- 2. If not found, enable it:
ALTER PUBLICATION supabase_realtime ADD TABLE event_invitations;

-- 3. Add comment for documentation
COMMENT ON TABLE event_invitations IS
'Event invitations with RSVP status. Realtime enabled for live updates.';
```

**Then** write client code:
```dart
_channel = supabase.channel('invitations').subscribe();
```

**Rule:** Verify full-stack configuration BEFORE writing client code. Database setup, RLS policies, publications must be correct first.

---

## Pattern 7: Test with Realistic Data

### ❌ WRONG: Test with 1-2 items

```dart
// Tested with 1-2 members
// UI looked fine
```

**Impact:** UI overflowed by 432 pixels with 12+ members. Caught only after user reported it.

### ✅ CORRECT: Create realistic test data upfront

```sql
-- Generate test data BEFORE building UI
INSERT INTO event_invitations (event_id, user_id, rsvp_status)
SELECT
  'test-event-id',
  gen_random_uuid(),
  CASE (random() * 2)::int
    WHEN 0 THEN 'going'
    WHEN 1 THEN 'maybe'
    ELSE 'not_going'
  END
FROM generate_series(1, 50);
```

**Test edge cases:**
- 0 items (empty state)
- 1 item (minimal case)
- 12 items (typical case)
- 50+ items (stress test - pagination needed?)
- 100+ items (overflow, performance issues)

**Rule:** Test with realistic data volumes, not just 1-2 items. Build empty states, loading states, and error states.

---

## Pattern 8: Hot Reload ≠ Full Restart for Database Changes

### ❌ WRONG: Expect hot reload to work after database migration

```sql
-- Applied migration enabling realtime
ALTER PUBLICATION supabase_realtime ADD TABLE event_invitations;
```

```dart
// Hot reloaded app (R key)
// Expected realtime updates to work
// No updates appeared because WebSocket didn't reconnect!
```

**Impact:** Wasted time expecting logs that couldn't appear. Confusion about why WebSocket wasn't working.

### ✅ CORRECT: Full restart after database config changes

```sql
-- NOTE: Full app restart required (not just hot reload)
ALTER PUBLICATION supabase_realtime ADD TABLE event_invitations;
```

**After migration:**
1. Stop app completely (not hot reload)
2. Full restart: `flutter run`
3. Verify WebSocket reconnects with new config

**Rule:** Hot reload works for code changes, NOT database config changes (RLS policies, realtime publications, schema changes).

---

## Pattern 9: Implement All UI States

### ❌ WRONG: Only show success state

```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemCard(items[index]),
)
```

**Impact:** Jarring experience, no guidance when empty, confusing loading behavior.

### ✅ CORRECT: Handle all 4 states

```dart
Widget build(BuildContext context) {
  if (provider.isLoading) {
    return SkeletonLoader(itemCount: 12);
  }

  if (provider.error != null) {
    return ErrorState(
      message: provider.error!,
      onRetry: provider.refresh,
    );
  }

  if (provider.items.isEmpty) {
    return EmptyState(
      icon: Icons.inbox_outlined,
      title: 'No invitations yet',
      message: 'Invite friends to see them here',
    );
  }

  return ListView.builder(
    itemCount: provider.items.length,
    itemBuilder: (context, index) => ItemCard(provider.items[index]),
  );
}
```

**Rule:** Every async data load needs 4 states: loading, empty, error, and success. Never show blank screen or jarring jumps.

---

## Workflow Checklist

**MANDATORY checklist before implementing ANY feature:**

- [ ] **Read existing code** - Search for similar patterns, read related files
- [ ] **Clarify requirements** - Ask questions about user intent and edge cases
- [ ] **Check database config** - Verify RLS, indexes, realtime publications
- [ ] **Create realistic test data** - Test with 0, 1, 12, 50+, 100+ items
- [ ] **Review architecture** - Consider performance, scalability, state management
- [ ] **Follow existing patterns** - Match naming conventions, coding standards
- [ ] **Document decisions** - Explain WHY in comments and migrations
- [ ] **Test all UI states** - Loading, empty, error, success

**If ANY checkbox is unchecked, STOP and complete it before writing code.**

---

## Technical Debt Reference

The following issues exist in production and need fixing (see GitHub issues #237-#246):

1. **RLS Performance** - Replace JSONB array parsing with indexed table (#237)
2. **Realtime Updates** - Update single record instead of re-fetch all (#238)
3. **Query Caching** - Cache user profiles instead of repeated joins (#239)
4. **State Management** - Migrate to Provider pattern (#240)
5. **Error Handling** - Add WebSocket reconnection logic (#241)
6. **Pagination** - Implement for 100+ member groups (#242)
7. **Code Duplication** - Extract RSVP sheet to reusable utility (#243)
8. **Loading States** - Add skeleton loaders and empty states (#244)
9. **Input Validation** - Validate JSONB arrays for size/format (#245)
10. **Rate Limiting** - Debounce RSVP updates (#246)

---

## Pattern 10: Use MCP Tools When Available

### ❌ WRONG: Ask user to manually perform operations

```
AI: "Please run this SQL in your Supabase SQL Editor:

ALTER PUBLICATION supabase_realtime ADD TABLE events;

Then verify it worked by running:

SELECT * FROM pg_publication_tables WHERE...
"

User: [manually navigates to dashboard, copies SQL, pastes, runs, copies output back]
```

**Impact:** Added friction, delays, potential copy-paste errors, breaks flow.

### ✅ CORRECT: Use MCP tool directly

```dart
// Check current status
await mcp__supabase__execute_sql(
  query: """
    SELECT * FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
    AND tablename = 'events';
  """
);

// Apply fix immediately
await mcp__supabase__execute_sql(
  query: "ALTER PUBLICATION supabase_realtime ADD TABLE events;"
);

// Verify
await mcp__supabase__execute_sql(
  query: """
    SELECT tablename FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
    ORDER BY tablename;
  """
);
```

**Rule:** When MCP tools are available (Supabase, GitHub, IDE, etc.), use them instead of asking users to manually perform operations. MCP tools are first-class capabilities that should be preferred.

**Example from real issue:** During Potluck template debugging, the AI initially created helper scripts and asked the user to manually run SQL in the Supabase dashboard. Only after the user said "supabase mcp is connected you do it" did the AI realize it should use the MCP tool. This added unnecessary delay and friction.

**See:** [Potluck Real-time Updates Issue](../integration-issues/realtime-updates-not-working-potluck-events-table-20260115.md) - Lesson learned about using MCP tools

---

**Post-Mortem Grade: D+**

The feature works, but with significant technical debt. The biggest lesson: **Clarify requirements and read existing code BEFORE implementing**. Following these patterns prevents wasting 30% of development time on avoidable rework.
