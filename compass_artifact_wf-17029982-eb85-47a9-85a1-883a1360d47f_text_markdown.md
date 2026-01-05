# Flutter + Supabase Calendar App: Complete Performance Optimization Guide

Your calendar app's **62.7ms build time** (3.75× over the 16.67ms budget) stems from three critical issues: excessive widget rebuilds triggered by `_focusedMonth` state changes, 90 redundant `Theme.of(context)` calls per frame, and inefficient grid rendering. This comprehensive guide provides battle-tested solutions that can reduce your build time to under **15ms**.

The most impactful fix is isolating `_focusedMonth` changes using `ValueNotifier`—this alone can reduce widget rebuilds from 90+ to under 10 per swipe. Combined with theme caching and Riverpod's `.select()` for fine-grained state subscriptions, you can achieve smooth 60fps performance.

---

## Critical fixes: Immediate performance wins

### Isolating _focusedMonth from PageView rebuilds

**The core problem**: Your `setState()` on month change rebuilds the entire widget tree including all 42 calendar cells, even though only the header needs the focused month value.

```dart
// ❌ BEFORE: Full rebuild on every swipe (62.7ms)
class _GroupCalendarState extends State<GroupCalendar> {
  DateTime _focusedMonth = DateTime.now();
  
  void _onPageChanged(int index) {
    setState(() {  // Triggers 90+ widget rebuilds
      _focusedMonth = _calculateMonth(index);
    });
  }
}

// ✅ AFTER: Isolated state updates (~12ms)
class _GroupCalendarState extends State<GroupCalendar> {
  final ValueNotifier<DateTime> _focusedMonthNotifier = ValueNotifier(DateTime.now());
  late final PageController _pageController;
  late final CalendarThemeData _themeData;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cache theme ONCE when dependencies change
    _themeData = CalendarThemeData.fromTheme(Theme.of(context));
  }
  
  @override
  void dispose() {
    _focusedMonthNotifier.dispose();
    _pageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Only header rebuilds when focused month changes
        ValueListenableBuilder<DateTime>(
          valueListenable: _focusedMonthNotifier,
          builder: (context, focusedMonth, child) {
            return CalendarHeader(focusedMonth: focusedMonth);
          },
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: 24,
            onPageChanged: (index) {
              // Updates notifier WITHOUT setState - no full rebuild
              _focusedMonthNotifier.value = _calculateMonth(index);
            },
            itemBuilder: (context, index) {
              return GroupCalendarGrid(
                month: _calculateMonth(index),
                themeData: _themeData,  // Cached theme passed down
                focusedMonthNotifier: _focusedMonthNotifier,
              );
            },
          ),
        ),
      ],
    );
  }
}
```

**Expected impact**: Reduces rebuilds from **90+ to 1-7 widgets** per swipe (~90% reduction).

### Eliminating repeated Theme.of(context) calls

Your 90 `Theme.of(context)` calls per rebuild add significant overhead. Cache theme data once at the grid level:

```dart
// Pre-computed theme data class
class CalendarThemeData {
  final TextStyle dayTextStyle;
  final TextStyle todayTextStyle;
  final TextStyle outsideMonthTextStyle;
  final Color cellColor;
  final Color todayCellColor;
  final Color selectedCellColor;
  
  const CalendarThemeData({
    required this.dayTextStyle,
    required this.todayTextStyle,
    required this.outsideMonthTextStyle,
    required this.cellColor,
    required this.todayCellColor,
    required this.selectedCellColor,
  });
  
  factory CalendarThemeData.fromTheme(ThemeData theme) {
    return CalendarThemeData(
      dayTextStyle: theme.textTheme.bodyMedium!,
      todayTextStyle: theme.textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
      outsideMonthTextStyle: theme.textTheme.bodyMedium!.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.5),
      ),
      cellColor: theme.colorScheme.surface,
      todayCellColor: theme.colorScheme.primaryContainer,
      selectedCellColor: theme.colorScheme.primary,
    );
  }
}

// Cell uses pre-computed theme - zero lookups
class _GroupCalendarCell extends StatelessWidget {
  final DateTime date;
  final CalendarThemeData themeData;
  final bool isInMonth;
  final bool isToday;
  
  const _GroupCalendarCell({
    required this.date,
    required this.themeData,
    required this.isInMonth,
    required this.isToday,
  });
  
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isToday ? themeData.todayCellColor : themeData.cellColor,
      ),
      child: Center(
        child: Text(
          '${date.day}',
          style: isInMonth ? themeData.dayTextStyle : themeData.outsideMonthTextStyle,
        ),
      ),
    );
  }
}
```

**Expected impact**: Reduces Theme.of calls from **90× to 1×** per rebuild (~99% reduction in lookup overhead).

---

## State management with Riverpod 2.x

Riverpod's `.select()` and `.family()` provide surgical control over rebuilds—essential for your 42-cell grid.

### Fine-grained subscriptions with .select()

```dart
// Only rebuild when THIS specific condition changes
class CalendarDayCell extends ConsumerWidget {
  final DateTime date;
  
  const CalendarDayCell({required this.date});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Cell only rebuilds when its selection state changes
    final isSelected = ref.watch(
      calendarProvider.select((state) => 
        state.selectedDay?.year == date.year &&
        state.selectedDay?.month == date.month &&
        state.selectedDay?.day == date.day
      ),
    );
    
    return Container(
      color: isSelected ? Colors.blue : Colors.transparent,
      child: Text('${date.day}'),
    );
  }
}
```

### Parameterized providers with .family()

```dart
// Each month has its own cached availability data
@riverpod
Future<List<TimeSlot>> monthAvailability(Ref ref, DateTime month) async {
  final repository = ref.watch(availabilityRepositoryProvider);
  return repository.getAvailability(month);
}

// Usage - each cell watches only its specific date's data
final monthData = ref.watch(monthAvailabilityProvider(DateTime(date.year, date.month)));
```

### Migration from setState() to Riverpod

```yaml
# pubspec.yaml additions
dependencies:
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  freezed_annotation: ^2.4.1

dev_dependencies:
  riverpod_generator: ^2.4.2
  riverpod_lint: ^2.3.12
  freezed: ^2.4.3
```

```dart
// Wrap app with ProviderScope
void main() {
  runApp(ProviderScope(child: MyApp()));
}

// Convert StatefulWidget to ConsumerStatefulWidget
class CalendarScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  void _onMonthChanged(DateTime month) {
    ref.read(calendarProvider.notifier).selectMonth(month);
    // Only widgets using .select() for focusedMonth rebuild
  }
}
```

---

## Grid rendering optimization

### Why Table widget is slow for calendars

Table performs **double layout passes** when cells need uniform sizing, querying all 42 cells twice. For a fixed 6×7 grid, use Row/Column with pre-built cells instead:

```dart
// ✅ Optimized: Row/Column with cached widgets
class GroupCalendarGrid extends StatefulWidget {
  final DateTime month;
  final CalendarThemeData themeData;
  
  @override
  State<GroupCalendarGrid> createState() => _GroupCalendarGridState();
}

class _GroupCalendarGridState extends State<GroupCalendarGrid> {
  late List<Widget> _cachedCells;
  
  @override
  void initState() {
    super.initState();
    _buildCellCache();
  }
  
  @override
  void didUpdateWidget(GroupCalendarGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.month != oldWidget.month) {
      _buildCellCache();
    }
  }
  
  void _buildCellCache() {
    final dates = _generateMonthDates(widget.month);
    _cachedCells = List.generate(42, (index) {
      return _GroupCalendarCell(
        key: ValueKey(dates[index]),
        date: dates[index],
        themeData: widget.themeData,
        isInMonth: dates[index].month == widget.month.month,
        isToday: _isToday(dates[index]),
      );
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(6, (row) => Row(
          children: List.generate(7, (col) => Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: _cachedCells[row * 7 + col],
            ),
          )),
        )),
      ),
    );
  }
}
```

### CustomMultiChildLayout for maximum performance

When every millisecond counts, CustomMultiChildLayout provides single-pass layout:

```dart
class _CalendarGridDelegate extends MultiChildLayoutDelegate {
  final int rows = 6;
  final int columns = 7;
  
  @override
  void performLayout(Size size) {
    final cellWidth = size.width / columns;
    final cellHeight = size.height / rows;
    
    for (int i = 0; i < rows * columns; i++) {
      if (hasChild(i)) {
        // Tight constraints - single pass, no intrinsic measurement
        layoutChild(i, BoxConstraints.tight(Size(cellWidth, cellHeight)));
        final row = i ~/ columns;
        final col = i % columns;
        positionChild(i, Offset(col * cellWidth, row * cellHeight));
      }
    }
  }
  
  @override
  bool shouldRelayout(covariant MultiChildLayoutDelegate oldDelegate) => false;
}
```

**Performance comparison**:
| Approach | Expected Build Time |
|----------|-------------------|
| Table (current) | 62.7ms |
| Row/Column + cache | ~20-25ms |
| CustomMultiChildLayout | ~12-16ms |

---

## Supabase PostgreSQL optimization

### RLS performance patterns

Your `get_group_shadow_calendar` RPC function can be significantly optimized:

```sql
-- ❌ ANTI-PATTERN: Unwrapped function calls (called per-row)
CREATE POLICY "bad_policy" ON calendar_events
USING (auth.uid() = user_id);

-- ✅ OPTIMIZED: Wrap functions in SELECT (cached per-statement)
CREATE POLICY "select_group_events" ON calendar_events
FOR SELECT TO authenticated
USING ((SELECT auth.uid()) = user_id);

-- ✅ SECURITY DEFINER for RPC (bypasses RLS overhead)
CREATE OR REPLACE FUNCTION get_group_shadow_calendar(
  p_group_id UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE (event_date DATE, availability JSONB)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''  -- CRITICAL for security
AS $$
BEGIN
  -- Manual authorization check
  IF NOT EXISTS (
    SELECT 1 FROM public.group_members 
    WHERE group_id = p_group_id AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;
  
  RETURN QUERY
  SELECT sc.event_date, sc.availability_data
  FROM public.shadow_calendar_cache sc
  WHERE sc.group_id = p_group_id
    AND sc.event_date BETWEEN p_start_date AND p_end_date
  ORDER BY sc.event_date;
END;
$$;

REVOKE EXECUTE ON FUNCTION get_group_shadow_calendar FROM public, anon;
GRANT EXECUTE ON FUNCTION get_group_shadow_calendar TO authenticated;
```

### Composite index design

For date-range + user_id queries, put equality columns **first**, range columns **last**:

```sql
-- Optimal index for: WHERE group_id = X AND date BETWEEN Y AND Z
CREATE INDEX idx_shadow_cache_group_date 
ON shadow_calendar_cache (group_id, event_date);

-- Covering index (avoids table lookup)
CREATE INDEX idx_shadow_cache_covering 
ON shadow_calendar_cache (group_id, event_date) 
INCLUDE (availability_data);
```

**RLS benchmark impact** (from Supabase testing on 100K rows):
| Scenario | Before | After |
|----------|--------|-------|
| Unindexed RLS column | 171ms | <0.1ms (with index) |
| Unwrapped function calls | 11,000ms | 7ms (wrapped in SELECT) |

---

## Caching strategy architecture

### Recommended stack: Drift + LRU + PowerSync

```
┌─────────────────────────────────────────────────┐
│                    UI Layer                      │
│  CalendarView ←→ AvailabilityCubit              │
└─────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────┐
│               Repository Layer                   │
│  ├─ LRU Memory Cache (6 months, 10min TTL)      │
│  ├─ Drift SQLite (persistent, 90 days)          │
│  └─ Supabase/PowerSync (source of truth)        │
└─────────────────────────────────────────────────┘
```

### Stale-while-revalidate implementation

```dart
class AvailabilityRepository {
  final SupabaseClient _supabase;
  final AppDatabase _db;
  final CalendarLRUCache _memoryCache = CalendarLRUCache(maxMonths: 6);
  final Duration _staleDuration = Duration(minutes: 5);
  
  Future<AvailabilityResult> getMonthAvailability(DateTime month) async {
    final key = '${month.year}-${month.month}';
    
    // Step 1: Check memory cache first
    final cached = _memoryCache.get(key);
    if (cached != null) {
      final isStale = _memoryCache.isStale(key);
      if (isStale) {
        _revalidateInBackground(month, key);  // Non-blocking refresh
      }
      return AvailabilityResult(data: cached, isStale: isStale);
    }
    
    // Step 2: Check persistent cache (Drift)
    final persisted = await _db.getCachedAvailability(key);
    if (persisted != null) {
      _memoryCache.put(key, persisted.data);
      _revalidateInBackground(month, key);
      return AvailabilityResult(data: persisted.data, isStale: true);
    }
    
    // Step 3: Fetch from network
    final fresh = await _fetchFromSupabase(month);
    _memoryCache.put(key, fresh);
    await _db.cacheAvailability(key, fresh);
    return AvailabilityResult(data: fresh, isStale: false);
  }
  
  Future<void> _revalidateInBackground(DateTime month, String key) async {
    try {
      final fresh = await _fetchFromSupabase(month);
      _memoryCache.put(key, fresh);
      await _db.cacheAvailability(key, fresh);
    } catch (e) {
      // Silently fail - user sees cached data
    }
  }
}
```

### Database comparison for 2024-2025

| Database | Write 1K | Read 1K | Web Support | Recommendation |
|----------|----------|---------|-------------|----------------|
| **Drift** | ~300ms | ~200ms | ✅ | **Best for calendar** |
| Hive | ~800ms | ~0ms | ✅ | Deprecated (author recommends Isar) |
| Isar | ~69ms iOS | ~0ms | ✅ | Development uncertain |
| ObjectBox | ~5.5ms | ~1ms | ❌ | No web support |

**Drift wins** because calendar data is inherently relational (dates → slots → availability), and PowerSync integrates natively.

---

## Memory management optimization

### AutomaticKeepAliveClientMixin scope reduction

Your current 3-month keep-alive is excessive. Use conditional keep-alive:

```dart
class _MonthViewState extends State<MonthView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive {
    // Only keep current month ±1 alive (3 pages max)
    final distance = (widget.monthIndex - currentMonthIndex).abs();
    return distance <= 1;
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context);  // REQUIRED for mixin
    return _buildContent();
  }
}
```

### Image cache constraints

```dart
void main() {
  // Limit in-memory image cache
  PaintingBinding.instance.imageCache.maximumSize = 50;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024;  // 50MB
  runApp(MyApp());
}

// Constrain avatar decode size
CachedNetworkImage(
  imageUrl: avatarUrl,
  memCacheWidth: (48 * MediaQuery.of(context).devicePixelRatio).round(),
  memCacheHeight: (48 * MediaQuery.of(context).devicePixelRatio).round(),
)
```

---

## Flutter 3.27+ and Impeller

### Current Impeller status

| Platform | Status |
|----------|--------|
| iOS | Default, no opt-out (Flutter 3.29+) |
| Android API 29+ | Default since Flutter 3.27 |
| Android older | Falls back to Skia OpenGL |

**Key benefit**: Impeller eliminates shader compilation jank completely—no warm-up needed.

### Shader warm-up is no longer required

```dart
// OLD approach - NO LONGER REQUIRED with Impeller
// flutter run --profile --cache-sksl
// flutter build apk --bundle-sksl-path flutter_01.sksl.json

// With Impeller: Just build normally
flutter build apk  // Shaders pre-compiled at build time
```

---

## When to use compute() isolates

| Task | Size Threshold | Recommendation |
|------|----------------|----------------|
| JSON parsing | >100KB | Use `compute()` |
| List filtering | >1,000 items | Consider `compute()` |
| Date calculations | <1,000 dates | Main thread OK |
| Availability calculation | >50 users × 7 days | Use `compute()` |

```dart
Future<List<TimeSlot>> calculateAvailabilityAsync(List<UserSchedule> schedules) async {
  if (schedules.length > 10 || _totalEvents(schedules) > 100) {
    return await compute(_calculateAvailabilityIsolate, schedules);
  }
  return _findCommonSlots(schedules);  // Small data: main thread faster
}

// Must be top-level or static function
List<TimeSlot> _calculateAvailabilityIsolate(List<UserSchedule> schedules) {
  return _findCommonSlots(schedules);
}
```

---

## Anti-patterns to avoid

### Critical don'ts

- **DON'T** call `Theme.of(context)` in every cell's build method
- **DON'T** use `setState()` for `_focusedMonth` changes that don't affect PageView content
- **DON'T** wrap large subtrees in `Opacity` widget (forces expensive saveLayer)
- **DON'T** use `Table` with `IntrinsicColumnWidth()` (triggers double layout pass)
- **DON'T** keep all 24 PageView pages alive with AutomaticKeepAliveClientMixin
- **DON'T** create new BoxDecoration instances in build methods
- **DON'T** use unwrapped `auth.uid()` in RLS policies (called per-row)

### Code smells to fix immediately

```dart
// ❌ Creates new objects every build (GC pressure)
Widget build(BuildContext context) {
  return Container(
    decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
  );
}

// ✅ Cache static decorations
static const _decoration = BoxDecoration(
  border: Border.fromBorderSide(BorderSide(color: Colors.grey)),
);

Widget build(BuildContext context) {
  return Container(decoration: _decoration);
}
```

---

## Implementation priority roadmap

### Week 1: Critical fixes (expected: 62.7ms → 20ms)
1. Extract `_focusedMonth` to `ValueNotifier`
2. Create `CalendarThemeData` class and cache at grid level
3. Add `const` constructors to all calendar cells

### Week 2: State management migration (expected: 20ms → 15ms)
4. Migrate to Riverpod 2.x with `.select()` for cells
5. Implement `.family()` providers for month data
6. Add `RepaintBoundary` around grid

### Week 3: Backend optimization
7. Wrap RLS functions in SELECT
8. Add composite indexes to Supabase tables
9. Implement stale-while-revalidate caching

### Week 4: Polish
10. Configure PowerSync for offline-first
11. Reduce AutomaticKeepAliveClientMixin scope to ±1 month
12. Profile with DevTools and fine-tune

---

## Profiling workflow

```dart
// Enable rebuild tracking in debug mode
void main() {
  debugPrintRebuildDirtyWidgets = true;
  runApp(MyApp());
}
```

**DevTools Performance tab targets**:
| Metric | Good | Your Current | Target |
|--------|------|--------------|--------|
| UI Thread | <8ms | ~50ms | <10ms |
| Total Frame | <16.67ms | 62.7ms | <16ms |
| Widget rebuilds/swipe | <10 | 90+ | <10 |

## Conclusion

The path from 62.7ms to sub-16ms frames requires a systematic approach: isolate state with `ValueNotifier`, eliminate redundant `Theme.of()` calls, leverage Riverpod's granular subscriptions, and optimize your Supabase backend with proper indexing and RLS patterns. The `ValueNotifier` isolation of `_focusedMonth` alone should cut your rebuild count by 90%—implement this first and measure before proceeding to other optimizations.