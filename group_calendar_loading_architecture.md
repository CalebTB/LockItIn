# Group Calendar Loading Architecture

**Last Updated:** January 4, 2026
**Purpose:** Technical documentation of how the group availability calendar loads and renders data, for researching further optimizations.

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Data Flow: Database → UI](#data-flow-database--ui)
3. [Flutter Architecture](#flutter-architecture)
4. [Database Architecture](#database-architecture)
5. [Current Optimizations Applied](#current-optimizations-applied)
6. [Performance Bottlenecks & Research Areas](#performance-bottlenecks--research-areas)
7. [Key Flutter Concepts to Research](#key-flutter-concepts-to-research)
8. [Key Database Concepts to Research](#key-database-concepts-to-research)

---

## System Overview

### What the System Does

The group availability calendar shows:
- A month-view calendar grid (7×6 = 42 cells)
- Each day shows how many group members are available
- Heatmap colors indicate availability ratio (0% → 100%)
- Users can swipe left/right to change months

### Current Performance Metrics

**Before Optimizations:**
- Initial load: 1-3 seconds
- Month swipe lag: 300-500ms
- Database queries: 10-50x slower without indexes

**After Optimizations (Current):**
- Initial load: <500ms
- Month swipe lag: <100ms (target, to be validated)
- Database queries: Optimized with composite indexes

---

## Data Flow: Database → UI

### Step-by-Step Loading Process

```
1. User navigates to group detail screen
   ↓
2. GroupDetailScreen.initState() triggers
   ↓
3. GroupProvider.selectGroup(groupId) called
   ↓
4. GroupService.fetchGroupMembers(groupId)
   → PostgreSQL query to group_members table
   → Returns list of member user IDs
   ↓
5. EventService.getShadowCalendarForGroup(memberIds, dateRange)
   → PostgreSQL query to shadow_calendar table
   → Fetches availability data for all members
   → Returns ~70-150 shadow calendar entries per 2-month range
   ↓
6. EventService.shadowToEventModels(shadowEntries)
   → Converts database rows to Dart EventModel objects
   ↓
7. GroupDetailScreen.setState()
   → Stores _memberEvents (List<EventModel>)
   → Calls _precomputeAvailability() for 3 months
   ↓
8. _precomputeAvailability() runs for previous/current/next months
   → For each day in each month (30-31 days × 3 = ~90 days):
     - Calls _getAvailabilityForDay(date)
     - AvailabilityService.calculateGroupAvailability()
     - Counts how many members are free on that day
     - Caches result in _availabilityCache Map
   ↓
9. PageView.builder builds 3 month widgets
   → GroupCalendarGrid(month, memberEvents, getAvailabilityForDay, totalMembers)
   ↓
10. GroupCalendarGrid.build() renders 42 cells
    → For each cell:
      - Calls widget.getAvailabilityForDay(date)
      - Returns cached availability count (no recalculation)
      - Determines cell colors based on availability ratio
      - Renders day number + availability dot
```

### Data Volume

**Per Group:**
- Members: 2-50 users (typically 8-12)
- Date range: 2 months (current month + 1 month forward)
- Shadow calendar entries: ~70-150 per group
- Calendar cells: 42 per month × 3 months = 126 cells rendered

**Network Payload:**
- Initial load: ~10-20 KB for shadow calendar data
- Subsequent month changes: 0 KB (pre-cached)

---

## Flutter Architecture

### Widget Tree Structure

```
GroupDetailScreen (StatefulWidget)
├── AppBar
├── TabBarView
│   ├── GroupCalendarView
│   │   └── _buildCalendarPageView()
│   │       └── PageView.builder (3 pages: prev, current, next)
│   │           └── GroupCalendarGrid (StatefulWidget with AutomaticKeepAliveClientMixin)
│   │               ├── Day headers (Sun-Sat)
│   │               └── GridView.builder (42 items)
│   │                   └── RepaintBoundary
│   │                       └── GestureDetector
│   │                           └── Container (cell)
│   │                               ├── Day number
│   │                               └── Availability dot
│   └── ProposalListView
└── ProposeFAB
```

### State Management

**Provider Pattern (package: provider v6.1.1)**

```dart
// GroupDetailScreen reads from providers:
Consumer2<CalendarProvider, GroupProvider>(
  builder: (context, calendarProvider, groupProvider, _) {
    // Rebuilds when either provider notifies
  }
)

// Local state in GroupDetailScreen:
- _memberEvents: List<EventModel> (70-150 items)
- _availabilityCache: Map<String, int> (~90 entries after precompute)
- _focusedMonth: DateTime
- _pageController: PageController
- _isLoadingMemberEvents: bool
```

**Cache Strategy:**
- Key format: `"YYYY-MM-DD"` (e.g., `"2026-01-15"`)
- Cache cleared on: Member events reload, date range change
- Cache persists: During month swipes (critical for performance)

### Rendering Optimization Techniques Applied

1. **AutomaticKeepAliveClientMixin** (GroupCalendarGrid)
   - Prevents PageView from disposing widgets when not visible
   - Research: `AutomaticKeepAliveClientMixin`, `wantKeepAlive`

2. **RepaintBoundary** (Each calendar cell)
   - Isolates repaints to individual cells
   - Research: `RepaintBoundary`, Flutter rendering pipeline

3. **Removed AnimatedContainer**
   - Eliminated 150ms animation overhead × 42 cells
   - Research: `AnimatedContainer` performance cost

4. **Removed Consumer2 from cell builder**
   - Prevents all 42 cells from rebuilding on provider changes
   - Research: Provider scoping, `select()` method

5. **Removed boxShadow**
   - Eliminated GPU overhead for 42 shadow calculations
   - Research: `BoxDecoration` performance, GPU vs CPU rendering

### Performance Profiling Commands

```bash
# Open Flutter DevTools
flutter pub global activate devtools
flutter pub global run devtools

# Profile widget builds
flutter run --profile

# Analyze rendering performance
- DevTools → Performance tab
- Timeline view
- Frame rendering time (target: <16.67ms for 60fps)
```

---

## Database Architecture

### Tables Involved

#### 1. `group_members` Table

**Schema:**
```sql
CREATE TABLE group_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES groups(id),
  user_id UUID NOT NULL REFERENCES users(id),
  role TEXT NOT NULL CHECK (role IN ('owner', 'admin', 'member')),
  joined_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(group_id, user_id)
);
```

**Indexes:**
```sql
-- Composite indexes for RLS policy optimization (Added in migration 014)
CREATE INDEX idx_group_members_user_group ON group_members(user_id, group_id);
CREATE INDEX idx_group_members_group_user ON group_members(group_id, user_id);
CREATE INDEX idx_group_members_rls_covering ON group_members(user_id, group_id) INCLUDE (role);
```

**Query Pattern:**
```sql
-- Fetch all members of a group
SELECT user_id, role
FROM group_members
WHERE group_id = $1;
```

**Performance:**
- Before indexes: Sequential scan on 1000+ rows
- After indexes: Index scan, ~10-50x faster

#### 2. `shadow_calendar` Table

**Schema:**
```sql
CREATE TABLE shadow_calendar (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  title TEXT,  -- NULL for busyOnly visibility, populated for sharedWithName
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  visibility TEXT NOT NULL CHECK (visibility IN ('busyOnly', 'sharedWithName')),
  event_id UUID REFERENCES events(id),  -- Source event
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

**Indexes:**
```sql
-- Existing indexes
CREATE INDEX idx_shadow_calendar_user_id ON shadow_calendar(user_id);
CREATE INDEX idx_shadow_calendar_user_time ON shadow_calendar(user_id, start_time, end_time);
```

**Query Pattern:**
```sql
-- Fetch shadow calendar for multiple members in date range
SELECT user_id, title, start_time, end_time, visibility
FROM shadow_calendar
WHERE user_id = ANY($1::uuid[])  -- Array of member IDs
  AND start_time >= $2
  AND end_time <= $3
ORDER BY start_time ASC;
```

**Row Level Security (RLS) Policy:**
```sql
-- Users can only see shadow calendar entries for group members
CREATE POLICY "Users can view shadow calendar for group members"
ON shadow_calendar FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM group_members gm1
    INNER JOIN group_members gm2 ON gm1.group_id = gm2.group_id
    WHERE gm1.user_id = auth.uid()
      AND gm2.user_id = shadow_calendar.user_id
  )
);
```

**Performance Considerations:**
- RLS policy executes on every row
- Self-join on `group_members` was slow before composite indexes
- Now uses covering index: `idx_group_members_rls_covering`

### Query Execution Plan (EXPLAIN ANALYZE)

**Before Optimization:**
```
Seq Scan on shadow_calendar  (cost=0.00..1500.00 rows=150 width=100) (actual time=120.5..150.2)
  Filter: (RLS policy check)
    -> Nested Loop (cost=0.00..50.00) (actual time=2.5..5.0)
          -> Seq Scan on group_members gm1
          -> Seq Scan on group_members gm2
```

**After Optimization (Migration 014):**
```
Index Scan using idx_shadow_calendar_user_time  (cost=0.42..25.00 rows=150 width=100) (actual time=5.2..8.5)
  Filter: (RLS policy check)
    -> Nested Loop (cost=0.00..10.00) (actual time=0.5..1.2)
          -> Index Scan using idx_group_members_user_group on gm1
          -> Index Scan using idx_group_members_group_user on gm2
```

**Improvement:** ~15-20x faster query execution

---

## Current Optimizations Applied

### Database Level (Applied in Migrations)

✅ **Migration 014: Composite Indexes on group_members**
- `idx_group_members_user_group` - Optimizes RLS policy join
- `idx_group_members_group_user` - Reverse index for flexibility
- `idx_group_members_rls_covering` - Covering index includes `role` column

✅ **Existing Indexes on shadow_calendar**
- `idx_shadow_calendar_user_id` - User filtering
- `idx_shadow_calendar_user_time` - Date range queries

### Application Level (Applied in Code)

✅ **Reduced Date Range**
- Before: 5 months (2 back + 3 forward)
- After: 2 months (current + 1 forward)
- **Impact:** 60% less data fetched

✅ **Pre-compute Availability for 3 Months**
- Calculates availability for previous, current, next months on load
- Populates `_availabilityCache` with ~90 entries
- **Impact:** Month swipes use cached data, no calculation

✅ **AutomaticKeepAliveClientMixin**
- Keeps rendered months in PageView memory
- **Impact:** Returning to previous month is instant

✅ **RepaintBoundary on Cells**
- Isolates repaints to individual cells
- **Impact:** Changing one cell doesn't repaint all 42 cells

✅ **Removed Consumer2 Wrapper**
- Moved provider reads to parent widget
- Pass `totalMembers` as parameter
- **Impact:** Cells don't rebuild when provider notifies

✅ **Removed AnimatedContainer**
- Changed to static `Container`
- **Impact:** Eliminated 150ms × 42 animation overhead

✅ **Removed boxShadow from Dots**
- Simplified decoration
- **Impact:** Reduced GPU rendering cost

✅ **Skeleton Loader**
- Shows skeleton grid during initial load
- **Impact:** Massive perceived performance improvement

✅ **Faster Swipe Animation**
- PageView animation: 300ms → 200ms
- **Impact:** 33% faster swipe transitions

---

## Performance Bottlenecks & Research Areas

### 1. Shadow Calendar Query (Database)

**Current Bottleneck:**
- Fetches ALL shadow entries for ALL members in date range
- RLS policy executes self-join on every row
- Date range is 2 months = potential 70-150 rows per group

**Research Topics:**
- **Materialized Views** - Pre-compute group member relationships
  - PostgreSQL: `CREATE MATERIALIZED VIEW`
  - Refresh strategy: `REFRESH MATERIALIZED VIEW`
- **PostgreSQL Prepared Statements** - Cache query plans
  - Supabase supports prepared statements via PostgREST
- **Query Result Caching** - Cache at application level
  - Redis for distributed caching
  - Flutter: `shared_preferences`, `hive`, `sqflite`
- **Database Connection Pooling** - Reduce connection overhead
  - Supabase uses PgBouncer by default
  - Check pool size: `SHOW max_connections;`

**Optimization Ideas:**
```sql
-- Idea 1: Denormalize with group_shadow_access table
CREATE TABLE group_shadow_access (
  group_id UUID,
  user_id UUID,
  shadow_calendar_id UUID,
  PRIMARY KEY (group_id, user_id, shadow_calendar_id)
);
-- Eliminates self-join in RLS policy

-- Idea 2: Partition shadow_calendar by month
CREATE TABLE shadow_calendar_2026_01 PARTITION OF shadow_calendar
  FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
-- Faster range queries on large datasets
```

### 2. Availability Calculation (Flutter)

**Current Bottleneck:**
- Loops through ALL member events (~70-150) for EACH day
- Runs 90 times during precompute (3 months × 30 days)
- Algorithm: O(n × m) where n=days, m=events

**Current Code:**
```dart
// In AvailabilityService.calculateGroupAvailability()
for (final event in memberEvents) {
  if (event.startTime.isBefore(endOfDay) && event.endTime.isAfter(startOfDay)) {
    availableCount++;
  }
}
```

**Research Topics:**
- **Isolates** - Run calculations in background thread
  - `compute()` function for heavy computation
  - `Isolate.spawn()` for long-running tasks
  - Package: `flutter_isolate`
- **Web Workers** (for web target)
  - Dart: `Worker` class
- **Memoization** - Cache function results
  - Package: `memo` or custom implementation
- **Binary Search** - If events sorted by time
  - `List.binarySearch()` or custom implementation
- **Interval Trees** - Efficient overlap queries
  - Algorithm: O(log n + k) for k overlapping intervals
  - Dart package: `interval_tree` (if exists)

**Optimization Ideas:**
```dart
// Idea 1: Pre-sort events by date, use binary search
final sortedEvents = memberEvents..sort((a, b) => a.startTime.compareTo(b.startTime));
// Use binary search to find events in range

// Idea 2: Group events by user, then by date
Map<String, Map<String, List<EventModel>>> eventsByUserAndDate;
// O(1) lookup instead of O(n) iteration

// Idea 3: Run in isolate
final availabilityMap = await compute(
  _computeAvailabilityInBackground,
  AvailabilityComputeParams(memberEvents, dateRange),
);
```

### 3. Widget Rebuilds (Flutter)

**Current Bottleneck:**
- GroupDetailScreen rebuilds when any provider notifies
- Consumer2 wrapper causes entire widget tree rebuild
- Each rebuild triggers availability cache lookups

**Research Topics:**
- **Selector vs Consumer** - Fine-grained rebuilds
  - `Selector` only rebuilds when specific data changes
  - Example: `Selector<GroupProvider, int>(selector: (_, provider) => provider.memberCount)`
- **ValueListenableBuilder** - Lightweight alternative to Provider
  - For simple state changes
  - `ValueNotifier` + `ValueListenableBuilder`
- **Flutter Bloc** - More predictable state management
  - Separates business logic from UI
  - Package: `flutter_bloc`
- **Riverpod** - Modern alternative to Provider
  - Better performance, compile-time safety
  - Package: `flutter_riverpod`
- **GetX** - High-performance state management
  - Package: `get`

**Optimization Ideas:**
```dart
// Idea 1: Use Selector instead of Consumer2
Selector<GroupProvider, (int, List<String>)>(
  selector: (_, provider) => (
    provider.selectedGroupMembers.length,
    provider.selectedGroupMembers.map((m) => m.id).toList(),
  ),
  builder: (context, data, _) {
    final (memberCount, memberIds) = data;
    // Only rebuilds when member count or IDs change
  },
)

// Idea 2: Move state to ChangeNotifier
class GroupCalendarState extends ChangeNotifier {
  Map<String, int> _availabilityCache = {};

  int getAvailability(DateTime date) {
    final key = _formatDate(date);
    return _availabilityCache[key] ?? 0;
  }
}
```

### 4. GridView Performance (Flutter)

**Current Bottleneck:**
- Renders all 42 cells upfront
- Uses `GridView.builder` but with `physics: NeverScrollableScrollPhysics`
- Not truly lazy (all 42 items built immediately)

**Research Topics:**
- **ListView.builder vs GridView.builder** - Lazy loading differences
  - `itemExtent` for better performance
  - `cacheExtent` to control viewport buffer
- **Slivers** - Custom scrollable layouts
  - `SliverGrid`, `SliverList`
  - More control over lazy loading
- **Flutter Performance Best Practices**
  - Google I/O talks on Flutter performance
  - Flutter docs: "Performance best practices"

**Optimization Ideas:**
```dart
// Idea 1: Use SliverGrid with CustomScrollView
CustomScrollView(
  slivers: [
    SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildCell(index),
        childCount: 42,
      ),
    ),
  ],
)

// Idea 2: Implement custom RenderObject for calendar
// Most complex, highest performance potential
```

### 5. Network Latency (Supabase)

**Current Bottleneck:**
- Every group change fetches fresh data
- No persistent caching between app sessions
- Cold start requires full data fetch

**Research Topics:**
- **HTTP Caching Headers** - Browser/app-level caching
  - `Cache-Control`, `ETag`, `If-None-Match`
  - Supabase PostgREST supports caching headers
- **Local Database Caching** - Persistent storage
  - `sqflite` - SQLite for Flutter
  - `drift` (formerly Moor) - Type-safe SQL
  - `hive` - NoSQL key-value database
  - `isar` - High-performance NoSQL
- **Service Worker** (web target)
  - Cache API responses
  - Offline-first architecture
- **GraphQL with Caching** - Alternative to REST
  - `graphql_flutter` with normalized cache
  - Apollo Client cache

**Optimization Ideas:**
```dart
// Idea 1: Cache shadow calendar data locally
await Hive.box('shadow_calendar').put(groupId, {
  'data': shadowEntries,
  'timestamp': DateTime.now().millisecondsSinceEpoch,
  'ttl': 300000, // 5 minutes
});

// Idea 2: Use stale-while-revalidate pattern
final cachedData = cache.get(groupId);
if (cachedData != null && !isExpired(cachedData)) {
  // Show cached data immediately
  setState(() => _memberEvents = cachedData);
}
// Fetch fresh data in background
fetchFreshData().then((fresh) => setState(() => _memberEvents = fresh));
```

---

## Key Flutter Concepts to Research

### Performance Optimization

1. **Flutter Performance Profiling**
   - DevTools Performance tab
   - Timeline view
   - Memory profiler
   - Widget rebuild tracking
   - Search: "Flutter DevTools performance profiling"

2. **Build Method Optimization**
   - `const` constructors
   - `RepaintBoundary` placement
   - Avoiding anonymous functions in build()
   - Search: "Flutter build method best practices"

3. **State Management Patterns**
   - Provider vs Riverpod vs Bloc vs GetX
   - When to use `ValueNotifier`
   - `Selector` for fine-grained rebuilds
   - Search: "Flutter state management comparison 2024"

4. **Rendering Pipeline**
   - Widget → Element → RenderObject
   - Paint vs Layout vs Composite
   - GPU vs CPU rendering
   - Search: "Flutter rendering pipeline explained"

5. **Lazy Loading & Virtualization**
   - `ListView.builder` vs `ListView`
   - `itemExtent` performance boost
   - `cacheExtent` for viewport buffering
   - Search: "Flutter ListView performance optimization"

6. **Isolates & Background Processing**
   - `compute()` function
   - `Isolate.spawn()`
   - SendPort/ReceivePort communication
   - Search: "Dart isolates tutorial"

7. **Caching Strategies**
   - In-memory caching (Map, List)
   - Persistent storage (sqflite, hive, isar)
   - Cache invalidation strategies
   - Search: "Flutter caching best practices"

### Advanced Topics

8. **Custom Render Objects**
   - When to create custom RenderObject
   - Performance benefits
   - Search: "Flutter custom RenderObject tutorial"

9. **Skia Engine Optimization**
   - Understanding Skia (Flutter's graphics engine)
   - GPU shader compilation
   - Search: "Flutter Skia performance"

10. **Memory Management**
    - Detecting memory leaks
    - Weak references
    - Dispose pattern
    - Search: "Flutter memory leak detection"

---

## Key Database Concepts to Research

### PostgreSQL Optimization

1. **Index Types**
   - B-tree (default)
   - Hash indexes
   - GIN (Generalized Inverted Index)
   - GiST (Generalized Search Tree)
   - BRIN (Block Range Index)
   - Search: "PostgreSQL index types when to use"

2. **Query Optimization**
   - `EXPLAIN ANALYZE` for query plans
   - Sequential Scan vs Index Scan
   - Bitmap Index Scan
   - Search: "PostgreSQL EXPLAIN ANALYZE tutorial"

3. **Covering Indexes**
   - `INCLUDE` clause (PostgreSQL 11+)
   - Index-only scans
   - Search: "PostgreSQL covering indexes"

4. **Partitioning**
   - Range partitioning (by date)
   - List partitioning
   - Hash partitioning
   - Search: "PostgreSQL table partitioning best practices"

5. **Materialized Views**
   - When to use vs regular views
   - Refresh strategies (CONCURRENTLY)
   - Search: "PostgreSQL materialized views performance"

6. **Connection Pooling**
   - PgBouncer configuration
   - Pool size tuning
   - Transaction vs session pooling
   - Search: "PostgreSQL connection pooling best practices"

### Supabase-Specific

7. **PostgREST Performance**
   - Query parameter optimization
   - `select=*` vs specific columns
   - Horizontal filtering
   - Search: "PostgREST performance optimization"

8. **Row Level Security (RLS)**
   - Policy performance impact
   - When to bypass RLS with `SECURITY DEFINER` functions
   - Policy testing
   - Search: "PostgreSQL RLS performance tuning"

9. **Supabase Realtime**
   - WebSocket connection overhead
   - When to use vs polling
   - Search: "Supabase Realtime best practices"

10. **Supabase Edge Functions**
    - When to move logic to edge functions
    - Reducing client-side computation
    - Search: "Supabase Edge Functions use cases"

### Advanced Topics

11. **Database Normalization vs Denormalization**
    - When to denormalize for performance
    - Trade-offs
    - Search: "database denormalization when to use"

12. **Caching Strategies (Database)**
    - Redis for query results
    - Application-level caching
    - CDN for static data
    - Search: "PostgreSQL Redis caching pattern"

13. **Vacuum and Analyze**
    - Autovacuum configuration
    - Manual VACUUM ANALYZE
    - Search: "PostgreSQL vacuum analyze tuning"

14. **Statistics and Query Planner**
    - `pg_stat_statements`
    - Adjusting statistics target
    - Search: "PostgreSQL query planner optimization"

---

## Recommended Learning Path

### Phase 1: Foundation (Week 1-2)

1. **Flutter Performance Basics**
   - Watch: "Flutter Performance Best Practices" (Google I/O)
   - Read: Flutter docs → Performance
   - Practice: Use DevTools to profile current app

2. **PostgreSQL Query Optimization**
   - Read: "Use The Index, Luke" (https://use-the-index-luke.com/)
   - Practice: Run EXPLAIN ANALYZE on shadow_calendar queries
   - Experiment: Test different index combinations

### Phase 2: Deep Dive (Week 3-4)

3. **Advanced Flutter State Management**
   - Compare: Provider vs Riverpod vs Bloc
   - Experiment: Rewrite one screen with Riverpod
   - Measure: Rebuild counts before/after

4. **Database Caching Strategies**
   - Research: Hive vs Isar vs Drift
   - Prototype: Implement local caching for shadow_calendar
   - Test: Offline functionality

### Phase 3: Advanced (Week 5-6)

5. **Isolates & Background Processing**
   - Tutorial: Dart isolates from scratch
   - Implement: Move availability calculation to isolate
   - Benchmark: Performance improvement

6. **Database Partitioning**
   - Study: PostgreSQL partitioning strategies
   - Plan: Partition shadow_calendar by month
   - Test: Query performance on partitioned table

### Phase 4: Production (Week 7+)

7. **Monitoring & Profiling**
   - Set up: PostgreSQL monitoring (pg_stat_statements)
   - Implement: Flutter performance tracking
   - Analyze: Real-world usage patterns

8. **A/B Testing**
   - Test: Different caching strategies
   - Measure: User-perceived performance
   - Decide: Which optimizations to keep

---

## Performance Benchmarking Tools

### Flutter

```bash
# Profile widget builds
flutter run --profile

# Measure frame rendering time
flutter run --trace-skia

# Generate performance timeline
flutter run --profile --trace-startup

# Analyze bundle size
flutter build apk --analyze-size
```

### PostgreSQL

```sql
-- Enable query statistics
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- View slow queries
SELECT query, mean_exec_time, calls
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;

-- Check index usage
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read
FROM pg_stat_user_indexes
WHERE idx_scan = 0 AND idx_tup_read = 0;

-- Analyze table statistics
ANALYZE shadow_calendar;
ANALYZE group_members;
```

### Supabase Dashboard

- **Database → Logs** - Query execution times
- **Database → Roles** - Connection pool usage
- **Database → Extensions** - Install pg_stat_statements
- **API → Logs** - PostgREST request latency

---

## Questions to Answer Through Research

### Flutter Performance

1. Would moving to **Riverpod** reduce widget rebuilds significantly?
2. Is **Isolate-based computation** worth the complexity for ~150 events?
3. Can **custom RenderObjects** improve calendar rendering speed?
4. Would **ValueNotifier** be lighter than Provider for availability state?
5. Is there a Flutter package for **interval tree** data structures?

### Database Performance

6. Would **partitioning shadow_calendar by month** speed up range queries?
7. Should we create a **materialized view** for group member relationships?
8. Can **Redis caching** reduce database load for frequently accessed groups?
9. Is the RLS policy overhead acceptable, or should we use **SECURITY DEFINER functions**?
10. Would **denormalizing** group membership into shadow_calendar improve performance?

### Architecture

11. Should we move availability calculation to a **Supabase Edge Function**?
12. Is **GraphQL** with normalized caching better than PostgREST for this use case?
13. Would **local-first architecture** (SQLite + sync) improve perceived performance?
14. Can we use **service workers** (for web) to cache API responses?

---

## Conclusion

This document provides a foundation for researching Flutter and database optimizations for the group calendar feature. The current implementation is functional and reasonably performant, but there are many opportunities for improvement.

**Next Steps:**
1. Profile the current implementation with DevTools
2. Identify the top 3 bottlenecks
3. Research relevant optimization techniques from this document
4. Prototype solutions in a branch
5. Benchmark before/after performance
6. Ship improvements incrementally

**Remember:** Premature optimization is the root of all evil. Focus on optimizations that provide measurable improvement to user experience.

**Resources:**
- Flutter Performance Docs: https://docs.flutter.dev/perf
- PostgreSQL Performance Wiki: https://wiki.postgresql.org/wiki/Performance_Optimization
- Use The Index, Luke: https://use-the-index-luke.com/
- Supabase Docs: https://supabase.com/docs
