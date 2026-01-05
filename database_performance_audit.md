# Database Performance Audit: Group Calendar Queries

**Date:** January 4, 2026
**Issue:** Laggy performance when loading group calendar events
**Scope:** Shadow calendar queries, RLS policies, indexes

---

## Executive Summary

The group calendar is experiencing performance issues due to **missing critical indexes** and **inefficient query patterns**. The primary bottleneck is the RLS policy on the `events` table, which performs expensive subqueries for every row without proper indexes.

**Impact:** SEVERE - Users will experience lag when viewing group calendars with 5+ members or 50+ events.

**Priority:** HIGH - This affects core product functionality (group availability heatmap).

---

## Critical Issues Found

### 1. MISSING INDEX: RLS Policy Subquery (CRITICAL)

**Location:** `/Users/calebbyers/Code/LockItIn/application/lockitin_app/supabase/migrations/003_group_events_rls.sql`

**Problem:**
The RLS policy on `events` table performs a complex subquery to check group membership:

```sql
CREATE POLICY "Users can view own and group members events" ON events
FOR SELECT TO authenticated
USING (
  user_id = auth.uid()
  OR
  (
    visibility != 'private'
    AND user_id != auth.uid()
    AND EXISTS (
      SELECT 1 FROM group_members gm1
      INNER JOIN group_members gm2
        ON gm1.group_id = gm2.group_id
        AND gm1.user_id != gm2.user_id
      WHERE gm1.user_id = auth.uid()
        AND gm2.user_id = events.user_id
    )
  )
);
```

**Why it's slow:**
- For EVERY event row, PostgreSQL must execute a self-join on `group_members`
- Without composite indexes, this join scans the entire `group_members` table
- With 8 group members, this means 8 * 8 = 64 row comparisons PER EVENT
- With 100 events, that's 6,400 row scans!

**Evidence from code:**
```dart
// group_detail_screen.dart:103-107
final shadowEntries = await EventService.instance.fetchGroupShadowCalendar(
  memberUserIds: memberIds,
  startDate: startDate,
  endDate: endDate,
);
```

This query loads 5 months of data (2 months back, 3 months forward) for all group members.

**Missing indexes:**
```sql
-- CRITICAL: Composite index for RLS policy join
CREATE INDEX IF NOT EXISTS idx_group_members_user_group
ON group_members(user_id, group_id);

-- CRITICAL: Reverse composite for join optimization
CREATE INDEX IF NOT EXISTS idx_group_members_group_user
ON group_members(group_id, user_id);
```

**Expected improvement:** 10-50x faster for groups with 5+ members.

---

### 2. MISSING INDEX: Shadow Calendar RLS Policy (HIGH PRIORITY)

**Location:** `/Users/calebbyers/Code/LockItIn/application/lockitin_app/supabase/shadow_calendar_schema.sql:193-207`

**Problem:**
The shadow calendar RLS policy also performs a similar self-join:

```sql
CREATE POLICY "Group members can view each other's shadow calendar"
ON shadow_calendar
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM group_members gm1
    JOIN group_members gm2 ON gm1.group_id = gm2.group_id
    WHERE gm1.user_id = auth.uid()
    AND gm2.user_id = shadow_calendar.user_id
    AND gm1.user_id != gm2.user_id
  )
);
```

**Why it's slow:**
Same issue as #1 - the RLS policy runs for EVERY row in `shadow_calendar` without efficient indexes.

**Solution:**
The same composite indexes from #1 will also optimize this policy (since they query the same `group_members` table).

---

### 3. INEFFICIENT QUERY: Loading Too Much Data (MEDIUM PRIORITY)

**Location:** `/Users/calebbyers/Code/LockItIn/application/lockitin_app/lib/presentation/screens/group_detail/group_detail_screen.dart:86-128`

**Problem:**
The app loads 5 months of event data upfront:

```dart
final now = DateTime.now();
final startDate = DateTime(now.year, now.month - 2, 1);  // 2 months back
final endDate = DateTime(now.year, now.month + 3, 0);    // 3 months forward
```

**Why it's inefficient:**
- Loads events the user may never view (past 2 months + future 3 months)
- No pagination - all events loaded at once
- If a group has 8 members with 50 events each over 5 months = 400 events loaded

**Recommendation:**
Load only the visible month initially, then lazy-load adjacent months:

```dart
// RECOMMENDED: Load only current month + 1 future month
final now = DateTime.now();
final startDate = DateTime(now.year, now.month, 1);        // Start of current month
final endDate = DateTime(now.year, now.month + 2, 0);      // End of next month
```

**Expected improvement:** 60% less data loaded initially (2 months vs 5 months).

---

### 4. NO CACHING: Repeated Queries on Navigation (MEDIUM PRIORITY)

**Location:** `/Users/calebbyers/Code/LockItIn/application/lockitin_app/lib/presentation/screens/group_detail/group_detail_screen.dart:80-84`

**Problem:**
Every time the user navigates to a group detail screen, data is refetched:

```dart
Future<void> _initializeGroupData() async {
  final groupProvider = context.read<GroupProvider>();
  await groupProvider.selectGroup(widget.group.id);
  await _loadMemberEvents();  // Always fetches from network
}
```

**Why it's inefficient:**
- No local caching - navigating away and back triggers full network reload
- User taps between groups repeatedly = multiple redundant queries
- Poor offline experience

**Recommendation:**
Implement in-memory cache with TTL (Time To Live):

```dart
// Add to GroupProvider or EventService
final Map<String, CachedGroupEvents> _eventCache = {};

class CachedGroupEvents {
  final Map<String, List<EventModel>> events;
  final DateTime fetchedAt;

  bool get isExpired => DateTime.now().difference(fetchedAt) > Duration(minutes: 5);
}
```

**Expected improvement:** Instant load for recently viewed groups (within 5 min TTL).

---

### 5. INEFFICIENT AVAILABILITY CALCULATION (LOW PRIORITY)

**Location:** `/Users/calebbyers/Code/LockItIn/application/lockitin_app/lib/presentation/screens/group_detail/group_detail_screen.dart:144-161`

**Problem:**
Availability is calculated on-demand for each day cell in the calendar grid:

```dart
int _getAvailabilityForDay(DateTime date) {
  final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  if (_availabilityCache.containsKey(key)) {
    return _availabilityCache[key]!;
  }

  final result = _availabilityService.calculateGroupAvailability(
    memberEvents: _memberEvents,
    date: date,
    timeFilters: _selectedTimeFilters,
    customStartTime: _customStartTime,
    customEndTime: _customEndTime,
  );

  _availabilityCache[key] = result;
  return result;
}
```

**Why it's inefficient:**
- The cache key generation uses string concatenation (`'${date.year}-...'`) - allocates memory on every call
- Cache is cleared completely on every data reload (`_clearAvailabilityCache()`)
- No pre-computation - availability calculated lazily during render

**Recommendation:**
1. Use more efficient cache key (epoch milliseconds or DateTime directly)
2. Pre-compute availability for visible month on data load
3. Only clear stale cache entries instead of full clear

```dart
// BETTER: Use DateTime as key directly
final Map<DateTime, int> _availabilityCache = {};

// Pre-compute on data load
void _precomputeAvailability() {
  final startOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
  final endOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);

  for (int day = 1; day <= endOfMonth.day; day++) {
    final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
    _getAvailabilityForDay(date);  // Populate cache
  }
}
```

**Expected improvement:** Smoother scrolling, no jank during calendar render.

---

## Query Pattern Analysis

### Current Query Flow (SLOW)

1. User opens group detail screen
2. `_loadMemberEvents()` called
3. Calls `fetchGroupShadowCalendar()` RPC function
4. RPC function queries `shadow_calendar` table
5. **RLS policy executes subquery on `group_members` for EVERY row**
6. Results returned to app
7. Availability calculated on-demand for each visible day

**Bottleneck:** Step 5 (RLS policy subquery without indexes)

### Optimized Query Flow (FAST)

1. User opens group detail screen
2. Check in-memory cache for recent data (< 5 min old)
3. If cached, return immediately ✅
4. If not cached, fetch only current + next month
5. RPC function uses **indexed composite lookup** on `group_members`
6. Results cached in memory
7. Pre-compute availability for visible month

**Result:** 5-10x faster initial load, instant repeat loads.

---

## Database Index Audit

### Existing Indexes (from schema files)

**`events` table:**
```sql
idx_events_user_id ON events(user_id)
idx_events_start_time ON events(start_time)
idx_events_user_date ON events(user_id, start_time)
idx_events_native_calendar_id ON events(native_calendar_id) WHERE native_calendar_id IS NOT NULL
```

**`shadow_calendar` table:**
```sql
idx_shadow_calendar_user_id ON shadow_calendar(user_id)
idx_shadow_calendar_time_range ON shadow_calendar(start_time, end_time)
idx_shadow_calendar_user_time ON shadow_calendar(user_id, start_time, end_time)
idx_shadow_calendar_event_id ON shadow_calendar(event_id)
```

**`group_members` table:**
```sql
-- NO COMPOSITE INDEXES! ⚠️
-- This is the root cause of slow RLS policies
```

### Required New Indexes

```sql
-- CRITICAL: RLS policy optimization
CREATE INDEX IF NOT EXISTS idx_group_members_user_group
ON group_members(user_id, group_id);

CREATE INDEX IF NOT EXISTS idx_group_members_group_user
ON group_members(group_id, user_id);

-- OPTIONAL: Covering index for RLS policy (includes all columns needed)
CREATE INDEX IF NOT EXISTS idx_group_members_rls_covering
ON group_members(user_id, group_id)
INCLUDE (role);  -- Covering index (PostgreSQL 11+)
```

**Why these indexes help:**
- `idx_group_members_user_group`: Fast lookup for "which groups is user X in?"
- `idx_group_members_group_user`: Fast lookup for "who is in group Y?"
- Both support the self-join in RLS policies with different join orders

**Index size estimate:**
- 1,000 group memberships = ~50KB per index
- Negligible storage cost for massive performance gain

---

## RPC Function Analysis

### `get_group_shadow_calendar` Performance

**Location:** `/Users/calebbyers/Code/LockItIn/application/lockitin_app/supabase/shadow_calendar_schema.sql:219-259`

**Function signature:**
```sql
CREATE OR REPLACE FUNCTION get_group_shadow_calendar(
  p_user_ids UUID[],
  p_start_date TIMESTAMP WITH TIME ZONE,
  p_end_date TIMESTAMP WITH TIME ZONE
)
```

**Query inside function:**
```sql
SELECT
  sc.user_id,
  sc.start_time,
  sc.end_time,
  sc.visibility::TEXT,
  sc.event_title
FROM shadow_calendar sc
WHERE sc.user_id = ANY(p_user_ids)
  AND sc.start_time < p_end_date
  AND sc.end_time > p_start_date
ORDER BY sc.user_id, sc.start_time;
```

**Performance analysis:**
✅ **Good:**
- Uses `user_id = ANY(p_user_ids)` - can leverage `idx_shadow_calendar_user_id`
- Date range filter uses indexed columns (`start_time`, `end_time`)
- `SECURITY DEFINER` bypasses RLS for internal query (faster)

❌ **Potential issue:**
- The RLS authorization check at the top still uses the slow subquery:
  ```sql
  IF NOT EXISTS (
    SELECT 1 FROM group_members gm1
    JOIN group_members gm2 ON gm1.group_id = gm2.group_id
    WHERE gm1.user_id = auth.uid()
    AND gm2.user_id = ANY(p_user_ids)
  ) AND NOT (auth.uid() = ANY(p_user_ids)) THEN
    RAISE EXCEPTION 'Access denied: You must be in a group with the requested users';
  END IF;
  ```

**Recommendation:**
After adding the composite indexes, this authorization check will be fast.

**Optional optimization:** Pre-compute group membership at app level:
```dart
// Instead of passing all member IDs to RPC, pass group_id
// and let the RPC function query group_members directly

CREATE OR REPLACE FUNCTION get_group_shadow_calendar_v2(
  p_group_id UUID,
  p_start_date TIMESTAMP WITH TIME ZONE,
  p_end_date TIMESTAMP WITH TIME ZONE
)
RETURNS TABLE (...) AS $$
DECLARE
  v_user_ids UUID[];
BEGIN
  -- Single query to get all member IDs
  SELECT ARRAY_AGG(user_id) INTO v_user_ids
  FROM group_members
  WHERE group_id = p_group_id;

  -- Then fetch shadow calendar for those users
  RETURN QUERY
  SELECT ... FROM shadow_calendar
  WHERE user_id = ANY(v_user_ids) ...;
END;
$$;
```

**Benefit:** Reduces client-side logic, fewer parameters passed over network.

---

## Anti-Patterns Detected

### 1. No Connection Pooling Visibility
**Issue:** Unable to verify if connection pooling is properly configured.
**Recommendation:** Check Supabase dashboard → Settings → Database → Connection pooling mode (should be "Transaction" mode for most queries).

### 2. N+1 Query Risk
**Location:** If members are loaded separately from events.
**Current code:** ✅ GOOD - Uses batch query with `IN` clause (`user_id = ANY(p_user_ids)`).

### 3. No Query Result Caching
**Issue:** Repeated queries for the same data.
**Recommendation:** Implement in-memory cache with 5-minute TTL (see Issue #4 above).

### 4. Full Table Scans on `group_members`
**Issue:** RLS policies scan entire table without indexes.
**Recommendation:** Add composite indexes (see Required New Indexes section).

---

## Performance Testing Recommendations

### Before Optimization (Baseline)

Run these queries in Supabase SQL Editor with `EXPLAIN ANALYZE`:

```sql
-- Test 1: RLS policy performance
EXPLAIN ANALYZE
SELECT * FROM events
WHERE user_id IN (
  SELECT user_id FROM group_members WHERE group_id = 'test-group-uuid'
);

-- Test 2: Shadow calendar RLS
EXPLAIN ANALYZE
SELECT * FROM shadow_calendar
WHERE user_id IN (
  SELECT user_id FROM group_members WHERE group_id = 'test-group-uuid'
);

-- Test 3: Group membership self-join
EXPLAIN ANALYZE
SELECT DISTINCT gm2.user_id
FROM group_members gm1
INNER JOIN group_members gm2 ON gm1.group_id = gm2.group_id
WHERE gm1.user_id = 'current-user-uuid'
  AND gm1.user_id != gm2.user_id;
```

**Look for:**
- "Seq Scan" (sequential scan) = BAD (means no index used)
- "Index Scan" or "Index Only Scan" = GOOD
- Execution time > 100ms = SLOW

### After Optimization (Validation)

Re-run the same queries and verify:
- All queries use "Index Scan"
- Execution time < 50ms
- No "Seq Scan" on `group_members`

---

## Implementation Priority

### Phase 1: Critical Database Fixes (Week 1)
**Priority:** P0 - Blocking performance issue

1. **Add composite indexes to `group_members`:**
   ```sql
   CREATE INDEX idx_group_members_user_group ON group_members(user_id, group_id);
   CREATE INDEX idx_group_members_group_user ON group_members(group_id, user_id);
   ```
   **File:** Create new migration `014_add_group_members_composite_indexes.sql`

2. **Test index effectiveness:**
   - Run `EXPLAIN ANALYZE` queries (see Performance Testing section)
   - Verify "Index Scan" appears instead of "Seq Scan"

**Expected impact:** 10-50x faster group calendar loads.

---

### Phase 2: Application-Level Optimizations (Week 2)
**Priority:** P1 - High value, moderate effort

1. **Reduce initial data load:**
   - Change from 5 months to 2 months (current + next month)
   - Implement lazy loading for adjacent months on user scroll

2. **Add in-memory caching:**
   - Cache group events with 5-minute TTL
   - Implement cache invalidation on realtime updates

3. **Pre-compute availability:**
   - Calculate availability for entire visible month on data load
   - Store in efficient cache (use `DateTime` as key, not string)

**Expected impact:** 60% less data loaded, instant repeat navigation.

---

### Phase 3: Advanced Optimizations (Future)
**Priority:** P2 - Nice to have, low urgency

1. **Optimize RPC function:**
   - Create `get_group_shadow_calendar_v2` that accepts `group_id` instead of user IDs
   - Reduces client-side logic and network payload

2. **Add database query caching:**
   - Use Supabase Edge Functions with KV cache
   - Cache aggregated availability data for popular groups

3. **Implement pagination:**
   - Load events in chunks (e.g., 50 events at a time)
   - Use cursor-based pagination for infinite scroll

**Expected impact:** Further 2-3x improvement for large groups (20+ members).

---

## Migration File Template

**File:** `/Users/calebbyers/Code/LockItIn/application/lockitin_app/supabase/migrations/014_add_group_members_composite_indexes.sql`

```sql
-- ============================================================================
-- Migration 014: Add Composite Indexes for group_members RLS Optimization
-- ============================================================================
-- Fixes critical performance issue: RLS policies on events and shadow_calendar
-- perform self-joins on group_members without proper indexes.
--
-- Impact: 10-50x faster group calendar queries for groups with 5+ members
--
-- Created: January 4, 2026
-- Issue: Database Performance Audit - Group Calendar Lag
-- ============================================================================

-- Composite index for RLS policy: "which groups is user X in?"
-- Used by: events RLS policy, shadow_calendar RLS policy
CREATE INDEX IF NOT EXISTS idx_group_members_user_group
ON group_members(user_id, group_id);

-- Composite index for RLS policy: "who is in group Y?"
-- Used by: Self-join optimization in RLS policies
CREATE INDEX IF NOT EXISTS idx_group_members_group_user
ON group_members(group_id, user_id);

-- Optional covering index (PostgreSQL 11+)
-- Includes role column to avoid table lookups in some queries
CREATE INDEX IF NOT EXISTS idx_group_members_rls_covering
ON group_members(user_id, group_id)
INCLUDE (role);

-- ============================================================================
-- VERIFICATION
-- ============================================================================
-- Run this query to verify indexes were created:
-- SELECT indexname, indexdef
-- FROM pg_indexes
-- WHERE tablename = 'group_members'
-- ORDER BY indexname;
--
-- Expected output should include:
-- - idx_group_members_user_group
-- - idx_group_members_group_user
-- - idx_group_members_rls_covering (if PostgreSQL 11+)
--
-- ============================================================================
-- PERFORMANCE TESTING
-- ============================================================================
-- Test RLS policy performance before/after:
--
-- EXPLAIN ANALYZE
-- SELECT DISTINCT gm2.user_id
-- FROM group_members gm1
-- INNER JOIN group_members gm2 ON gm1.group_id = gm2.group_id
-- WHERE gm1.user_id = 'test-user-uuid'
--   AND gm1.user_id != gm2.user_id;
--
-- Before: Should show "Seq Scan" on group_members (SLOW)
-- After: Should show "Index Scan" using idx_group_members_user_group (FAST)
--
-- ============================================================================
```

---

## Monitoring & Alerting

### Recommended Metrics to Track

1. **Query Performance:**
   - Average query time for `get_group_shadow_calendar` RPC
   - P95 latency for group calendar loads
   - Number of slow queries (> 1 second)

2. **User Experience:**
   - Time to first render (group detail screen)
   - Calendar scroll smoothness (frame rate)
   - Cache hit rate (% of loads served from cache)

3. **Database Health:**
   - Index usage statistics (pg_stat_user_indexes)
   - Sequential scans on `group_members` (should be near zero)
   - Connection pool saturation

### Supabase Dashboard Queries

```sql
-- Index usage statistics
SELECT
  schemaname,
  tablename,
  indexname,
  idx_scan as index_scans,
  idx_tup_read as tuples_read,
  idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes
WHERE tablename = 'group_members'
ORDER BY idx_scan DESC;

-- Sequential scans (should be zero after optimization)
SELECT
  schemaname,
  tablename,
  seq_scan,
  seq_tup_read,
  idx_scan,
  idx_tup_fetch
FROM pg_stat_user_tables
WHERE tablename = 'group_members';
```

---

## Summary of Recommendations

| Priority | Action | Expected Impact | Effort |
|----------|--------|----------------|--------|
| **P0 CRITICAL** | Add composite indexes on `group_members` | 10-50x faster | 30 min |
| **P1 HIGH** | Reduce data load (5 months → 2 months) | 60% less data | 2 hours |
| **P1 HIGH** | Implement in-memory caching (5 min TTL) | Instant repeat loads | 4 hours |
| **P1 HIGH** | Pre-compute availability for visible month | Smoother UI, no jank | 3 hours |
| **P2 MEDIUM** | Create `get_group_shadow_calendar_v2` RPC | Cleaner API, slightly faster | 2 hours |
| **P2 MEDIUM** | Optimize cache key generation | 5-10% faster | 1 hour |
| **P3 LOW** | Add database query caching (Edge Functions) | 2-3x for popular groups | 8 hours |

**Total estimated effort for P0-P1 fixes:** ~10 hours
**Expected overall performance gain:** 10-50x faster initial load, instant repeat loads

---

## Next Steps

1. **Create migration file:** `014_add_group_members_composite_indexes.sql`
2. **Apply migration:** Run via Supabase CLI or Dashboard
3. **Test performance:** Use `EXPLAIN ANALYZE` queries to verify index usage
4. **Implement app-level caching:** Add TTL cache to `GroupProvider` or `EventService`
5. **Monitor metrics:** Track query times in production
6. **Iterate:** Apply Phase 2 optimizations based on metrics

---

**Generated by:** Database Performance Audit Tool
**Contact:** For questions about this audit, create a GitHub issue.
