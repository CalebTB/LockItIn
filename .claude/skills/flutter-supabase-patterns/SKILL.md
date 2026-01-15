---
name: flutter-supabase-patterns
description: Development best practices and architectural patterns for Flutter + Supabase applications. Use this skill when implementing features with Flutter, Supabase, PostgreSQL, Row Level Security, or real-time subscriptions. Covers state management, database design, performance optimization, and common pitfalls.
---

# Flutter Supabase Patterns

## Overview

This skill provides battle-tested patterns and best practices for building Flutter mobile applications with Supabase backend. It captures learnings from production development, including performance optimizations, database design principles, state management patterns, and workflow requirements.

**Use this skill when:**
- Building Flutter features that integrate with Supabase
- Designing database schemas with Row Level Security (RLS)
- Implementing real-time features with WebSocket subscriptions
- Optimizing query performance and state management
- Reviewing code for architectural issues or technical debt

## Development Workflow: Read First, Code Second

### Critical Rule: ALWAYS Read Existing Code Before Implementing

**Before writing ANY new feature:**

```bash
# 1. Search for similar patterns
grep -r "keyword" lib/
grep -r "SimilarWidget" lib/presentation/

# 2. Read related files
# - How does this work elsewhere?
# - What state management patterns exist?
# - Are there reusable widgets/utilities?

# 3. Check database configuration
# - Are RLS policies in place?
# - Is realtime enabled for tables?
# - Do indexes exist?
```

**Never write code without reading existing implementations first.**

### Requirements Clarification Checklist

**Ask questions BEFORE building:**

- [ ] What's the expected data volume? (affects UI design, pagination)
- [ ] Are there existing patterns I should follow?
- [ ] What's the access model? (who can see/edit what?)
- [ ] What edge cases should I handle? (empty states, 100+ items, offline)

**Don't assume - confirm with user or project documentation.**

### Full-Stack Configuration Verification

**For real-time features, verify database config FIRST:**

```sql
-- Check if table is in realtime publication
SELECT * FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
AND tablename = 'your_table';

-- Check RLS policies
\d+ your_table

-- Verify indexes exist
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'your_table';
```

**Don't implement client-side WebSocket code until database is configured.**

### Testing with Realistic Data

**Edge cases to test BEFORE shipping:**

- 1 item (empty state)
- 10-12 items (typical case)
- 50+ items (stress test)
- 100+ items (pagination needed?)

**Create test data early, not after building UI.**

## Database Design Patterns

### Pattern 1: Avoid JSONB in RLS Policies

**❌ WRONG: JSONB array parsing in RLS (expensive)**

```sql
-- This runs on EVERY SELECT query - very slow!
CREATE POLICY "coordinators_can_view"
ON invitations FOR SELECT
USING (
  auth.uid()::text = ANY(
    SELECT jsonb_array_elements_text(
      events.template_data->'coordinator_ids'
    )
  )
);
```

**✅ CORRECT: Separate table with indexed columns**

```sql
-- Create join table with indexes
CREATE TABLE event_coordinators (
  event_id UUID REFERENCES events(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (event_id, user_id)
);

CREATE INDEX idx_coordinators_user ON event_coordinators(user_id);
CREATE INDEX idx_coordinators_event ON event_coordinators(event_id);

-- Simple, fast RLS policy
CREATE POLICY "coordinators_can_view"
ON invitations FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM event_coordinators
    WHERE event_id = invitations.event_id
    AND user_id = auth.uid()
  )
);
```

**Why:** Indexed lookups are 100x faster than JSONB parsing. RLS policies run on EVERY query - performance matters.

### Pattern 2: Enable Realtime BEFORE Client Implementation

**Required steps for real-time features:**

```sql
-- 1. Add table to realtime publication
ALTER PUBLICATION supabase_realtime ADD TABLE your_table;

-- 2. Verify it was added
SELECT * FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
AND tablename = 'your_table';

-- 3. Add comment for documentation
COMMENT ON TABLE your_table IS
'Description of table. Realtime enabled for live updates in FeatureName.';
```

**THEN implement Flutter WebSocket subscription:**

```dart
final channel = supabase
  .channel('your-channel')
  .onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'your_table',
    callback: _handleRealtimeUpdate,
  )
  .subscribe();
```

**Note:** Full app restart required after enabling realtime (not just hot reload).

### Pattern 3: Efficient Query Design

**❌ WRONG: N+1 queries with joins on every fetch**

```dart
// Fetches user data 12 times (one per invitation)
final invitations = await supabase
  .from('invitations')
  .select('*, users(id, full_name, avatar_url)')
  .eq('event_id', eventId);
```

**✅ CORRECT: Cache user data, fetch separately**

```dart
// 1. Fetch invitations (lightweight)
final invitations = await supabase
  .from('invitations')
  .select('id, user_id, rsvp_status')
  .eq('event_id', eventId);

// 2. Get unique user IDs
final userIds = invitations
  .map((inv) => inv['user_id'] as String)
  .toSet()
  .toList();

// 3. Batch fetch users (single query)
final users = await supabase
  .from('users')
  .select('id, full_name, avatar_url')
  .in_('id', userIds);

// 4. Cache users in provider for reuse
userProvider.cacheUsers(users);
```

**Why:** 1 invitation query + 1 user query vs 12 joined queries. Massive performance improvement.

## State Management Patterns

### Pattern 1: Provider Pattern for Complex Features

**❌ WRONG: Manual setState() and subscriptions**

```dart
class _MyScreenState extends State<MyScreen> {
  List<dynamic> _data = [];
  RealtimeChannel? _channel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _channel = supabase.channel('my-channel')...;
  }

  @override
  void dispose() {
    _channel?.unsubscribe();  // Easy to forget!
    super.dispose();
  }
}
```

**✅ CORRECT: Provider with lifecycle management**

```dart
class DataProvider extends ChangeNotifier {
  List<DataModel> _items = [];
  RealtimeChannel? _channel;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<DataModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> subscribe(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch data
      final data = await supabase.from('table').select();
      _items = data.map((e) => DataModel.fromJson(e)).toList();

      // Setup realtime
      _channel = supabase
        .channel('channel-$id')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'table',
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
    _channel?.unsubscribe();
    super.dispose();
  }
}

// Usage in widget:
ChangeNotifierProvider(
  create: (_) => DataProvider()..subscribe(id),
  child: Consumer<DataProvider>(
    builder: (context, provider, _) {
      if (provider.isLoading) return LoadingState();
      if (provider.error != null) return ErrorState(provider.error!);
      return DataList(items: provider.items);
    },
  ),
)
```

**Why:** Clean lifecycle, testable, reusable across screens, proper cleanup guaranteed.

### Pattern 2: Optimistic Updates for Real-Time

**❌ WRONG: Re-fetch all data on every update**

```dart
void _handleRealtimeUpdate(RealtimePayload payload) {
  _fetchAllData();  // Expensive!
}
```

**✅ CORRECT: Update single record in state**

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

**Why:** No database query needed. Instant UI updates. Scales to 100+ users.

## Performance Optimization Patterns

### Pattern 1: Pagination for Large Datasets

**When to paginate:**
- Lists with 50+ items
- User-generated content (unbounded growth)
- High-frequency updates

**Implementation:**

```dart
class PaginatedProvider extends ChangeNotifier {
  final int _pageSize = 20;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  Future<void> loadNextPage() async {
    if (!_hasMore || _isLoadingMore) return;

    _isLoadingMore = true;
    notifyListeners();

    final start = _currentPage * _pageSize;
    final data = await supabase
      .from('table')
      .select()
      .range(start, start + _pageSize - 1)
      .order('created_at', ascending: false);

    if (data.length < _pageSize) {
      _hasMore = false;
    }

    _items.addAll(data.map((e) => DataModel.fromJson(e)));
    _currentPage++;
    _isLoadingMore = false;
    notifyListeners();
  }
}

// UI: Infinite scroll
ListView.builder(
  itemCount: items.length + (hasMore ? 1 : 0),
  itemBuilder: (context, index) {
    if (index == items.length) {
      // Load more trigger
      provider.loadNextPage();
      return LoadingIndicator();
    }
    return ItemWidget(items[index]);
  },
)
```

### Pattern 2: Debouncing User Input

**For search, filters, or rapid status changes:**

```dart
Timer? _debounceTimer;

void onSearchChanged(String query) {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(Duration(milliseconds: 500), () {
    _performSearch(query);
  });
}

@override
void dispose() {
  _debounceTimer?.cancel();
  super.dispose();
}
```

### Pattern 3: Caching with TTL

**For user profiles, metadata, or slow-changing data:**

```dart
class CachedDataProvider extends ChangeNotifier {
  final Map<String, CachedItem> _cache = {};
  final Duration _ttl = Duration(minutes: 5);

  Future<DataModel> get(String id) async {
    final cached = _cache[id];

    if (cached != null && !cached.isExpired) {
      return cached.data;
    }

    final data = await supabase.from('table').select().eq('id', id).single();
    _cache[id] = CachedItem(
      data: DataModel.fromJson(data),
      timestamp: DateTime.now(),
    );

    return _cache[id]!.data;
  }
}

class CachedItem {
  final DataModel data;
  final DateTime timestamp;

  CachedItem({required this.data, required this.timestamp});

  bool get isExpired => DateTime.now().difference(timestamp) > Duration(minutes: 5);
}
```

## Error Handling Patterns

### Pattern 1: WebSocket Reconnection Logic

```dart
class RealtimeProvider extends ChangeNotifier {
  RealtimeChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _pollTimer;
  bool _isRealtimeActive = false;

  Future<void> subscribe(String id) async {
    try {
      _channel = supabase
        .channel('channel-$id')
        .onPostgresChanges(...)
        .subscribe((status, error) {
          if (status == RealtimeListenTypes.subscribed) {
            _isRealtimeActive = true;
            _stopPolling();
            notifyListeners();
          } else if (status == RealtimeListenTypes.closed) {
            _isRealtimeActive = false;
            _scheduleReconnect();
            _startPolling();  // Fallback to polling
            notifyListeners();
          }
        });
    } catch (e) {
      _startPolling();  // Immediate fallback
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: 5), () {
      subscribe(_currentId);
    });
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(Duration(seconds: 10), (_) {
      _fetchData();  // Fallback: poll every 10s
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _reconnectTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }
}
```

### Pattern 2: User-Friendly Error Messages

```dart
String _getUserFriendlyError(dynamic error) {
  final errorStr = error.toString().toLowerCase();

  if (errorStr.contains('rate_limit')) {
    return 'Too many requests. Please wait a moment.';
  } else if (errorStr.contains('network')) {
    return 'Network connection lost. Please check your internet.';
  } else if (errorStr.contains('permission') || errorStr.contains('rls')) {
    return 'You don\'t have permission to perform this action.';
  } else if (errorStr.contains('unique')) {
    return 'This item already exists.';
  } else {
    return 'Something went wrong. Please try again.';
  }
}
```

## UI Patterns

### Pattern 1: Loading States with Skeleton Loaders

```dart
if (provider.isLoading) {
  return SkeletonLoader(
    itemCount: 12,
    builder: (context, index) => Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 72,
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}
```

### Pattern 2: Empty States

```dart
if (provider.items.isEmpty) {
  return EmptyState(
    icon: Icons.inbox_outlined,
    title: 'No items yet',
    message: 'Get started by creating your first item',
    action: ElevatedButton(
      onPressed: () => _showCreateDialog(),
      child: Text('Create Item'),
    ),
  );
}
```

## Migration Patterns

### Pattern 1: Documented Migrations

**Always include context in migration comments:**

```sql
-- CONTEXT: Issue #237 - Dashboard showing 1/12 members
-- PROBLEM: RLS policy with JSONB array parsing on every SELECT
-- SOLUTION: Separate coordinators table with indexed columns
-- MIGRATION: Copy in_on_it_user_ids JSONB array to new table
-- PERFORMANCE: Reduces SELECT time from 150ms to 5ms

CREATE TABLE event_coordinators (
  event_id UUID REFERENCES events(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (event_id, user_id)
);

-- Migrate existing data
INSERT INTO event_coordinators (event_id, user_id)
SELECT
  e.id,
  jsonb_array_elements_text(
    COALESCE(
      e.template_data->'in_on_it_user_ids',
      '[]'::jsonb
    )
  )::uuid
FROM events e
WHERE e.template_data->>'type' = 'surprise_party'
AND e.template_data ? 'in_on_it_user_ids';
```

### Pattern 2: Realtime Migration Checklist

```sql
-- 1. Add table to publication
ALTER PUBLICATION supabase_realtime ADD TABLE your_table;

-- 2. Verify
SELECT * FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
AND tablename = 'your_table';

-- 3. Document
COMMENT ON TABLE your_table IS
'Table description. Realtime enabled for feature X.';

-- 4. Test with Flutter app (full restart required!)
```

## Common Pitfalls

### Pitfall 1: Not Testing with Realistic Data

**Problem:** Tested with 1-2 items, shipped UI that overflows with 12+ items.

**Solution:** Create test data BEFORE building UI.

```sql
-- Create test data for 50 members
INSERT INTO group_members (group_id, user_id)
SELECT
  'test-group-id',
  gen_random_uuid()
FROM generate_series(1, 50);
```

### Pitfall 2: Assuming Hot Reload Works for Everything

**Problem:** Changed realtime publication, expected hot reload to work.

**Reality:** WebSocket subscriptions require FULL app restart after database config changes.

**Solution:** Document this in migration comments, restart app after applying migration.

### Pitfall 3: Building Wrong Access Model

**Problem:** Implemented hierarchical roles when collaborative model was needed.

**Solution:** Clarify access model requirements BEFORE implementation:
- "Who can view this?"
- "Who can edit this?"
- "Are there special privileges, or equal access?"

### Pitfall 4: No Input Validation

**Problem:** Storing unvalidated UUIDs in JSONB arrays.

**Solution:** Validate before storing:

```dart
Future<List<String>> validateUserIds(List<String> userIds) async {
  // 1. Check UUID format
  final uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  final validUuids = userIds.where((id) => uuidRegex.hasMatch(id)).toList();

  if (validUuids.length != userIds.length) {
    throw ValidationException('Invalid user IDs');
  }

  // 2. Verify users exist
  final existingUsers = await supabase
    .from('users')
    .select('id')
    .in_('id', validUuids);

  if (existingUsers.length != validUuids.length) {
    throw ValidationException('Some users do not exist');
  }

  return validUuids;
}
```

## Resources

### references/

- `development-workflow.md` - Complete development workflow checklist
- `database-design-principles.md` - RLS, realtime, performance patterns
- `state-management-guide.md` - Provider patterns and lifecycle management
- `common-mistakes.md` - Pitfalls and how to avoid them

### assets/

- `provider-template.dart` - Boilerplate provider with realtime subscription
- `paginated-provider-template.dart` - Pagination pattern implementation

## Related Documentation

- **Post-Mortem:** `docs/solutions/workflow-issues/ai-agent-not-consulting-existing-code-event-templates-20260114.md`
- **GitHub Issues:** #237-#246 (technical debt items)

---

**First documented:** 2026-01-14
**Based on:** Event Templates (Surprise Party) implementation learnings
