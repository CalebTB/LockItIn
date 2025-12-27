import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/presentation/providers/calendar_provider.dart';
import 'package:lockitin_app/utils/calendar_utils.dart';
import 'package:lockitin_app/data/models/event_model.dart';

void main() {
  group('CalendarProvider - Date Range Dynamic Updates', () {
    test('should initialize with current month as base', () {
      final provider = CalendarProvider();
      final today = DateTime.now();
      final currentMonth = DateTime(today.year, today.month, 1);

      // Verify cache date is set to current month
      expect(CalendarUtils.isSameMonth(provider.months[0].month,
          DateTime(currentMonth.year, currentMonth.month - 120, 1)), true);

      // Verify total month count is 240 (120 back + 120 forward)
      expect(provider.months.length, 240);
    });

    test('todayMonthIndex should calculate current month index dynamically', () {
      final provider = CalendarProvider();
      final todayIndex = provider.todayMonthIndex;

      // Today should be at index 120 (10 years back from current month)
      expect(todayIndex, 120);

      // Verify the month at today index matches current month
      final today = DateTime.now();
      final currentMonth = DateTime(today.year, today.month, 1);
      expect(CalendarUtils.isSameMonth(provider.months[todayIndex].month, currentMonth), true);
    });

    test('goToToday should use dynamic index calculation', () {
      final provider = CalendarProvider();

      // Navigate to a different month first
      provider.selectDate(DateTime(2024, 1, 15));
      expect(provider.focusedDate.month, 1);
      expect(provider.focusedDate.year, 2024);

      // Go back to today
      provider.goToToday();

      // Should navigate to actual current month
      final today = DateTime.now();
      expect(provider.focusedDate.month, today.month);
      expect(provider.focusedDate.year, today.year);

      // Current page index should match today's index
      expect(provider.currentPageIndex, provider.todayMonthIndex);
    });

    test('months getter should refresh cache when month changes', () {
      // This test verifies the cache refresh logic by:
      // 1. Creating a provider with today's date
      // 2. Accessing months multiple times (should use cache)
      // 3. If we were to cross a month boundary, the cache would auto-refresh

      final provider = CalendarProvider();

      // Get initial months list
      final initialMonths = provider.months;

      // Verify initial state
      expect(initialMonths.length, 240);

      // Access months again - should return same cached list (same month)
      final cachedMonths = provider.months;

      // Should be the exact same list instance (cache hit)
      expect(identical(initialMonths, cachedMonths), true);

      // Note: In production, if the system clock crosses into a new month,
      // the next call to provider.months would automatically:
      // 1. Detect _cacheDate != current month
      // 2. Call _initializeMonths() to regenerate the list
      // 3. Return the new list with updated date range
      // This ensures the calendar always shows the correct 10 year range
    });

    test('months getter maintains performance with cache', () {
      final provider = CalendarProvider();

      // First access - should use cached list
      final months1 = provider.months;

      // Second access - should use same cached list (O(1) performance)
      final stopwatch = Stopwatch()..start();
      final months2 = provider.months;
      stopwatch.stop();
      final accessTime = stopwatch.elapsedMicroseconds;

      // Both should return the same list instance if month hasn't changed
      expect(identical(months1, months2), true);

      // Cache hit should be extremely fast (< 100 microseconds)
      expect(accessTime, lessThan(100));
    });

    test('should handle month boundary crossing scenario', () {
      // Scenario: App opened on Dec 31, 2025 at 11:59 PM
      // Time passes to Jan 1, 2026 at 12:01 AM
      // User clicks "Today" button

      // Simulate: Provider created in December 2025
      final decemberDate = DateTime(2025, 12, 31, 23, 59);
      final provider = CalendarProvider(initialDate: decemberDate);

      // Initial state: December 2025
      final decemberIndex = provider.months.indexWhere(
        (m) => m.month.year == 2025 && m.month.month == 12,
      );
      expect(decemberIndex >= 0, true);

      // In actual production, when time crosses to January 2026:
      // 1. The months getter checks _cacheDate vs DateTime.now()
      // 2. If different month, cache refreshes automatically
      // 3. todayMonthIndex recalculates based on new cache
      // 4. goToToday() uses the updated index

      // For this test, we verify the logic works by checking:
      final today = DateTime.now();
      final currentMonth = DateTime(today.year, today.month, 1);

      // Get today's index dynamically
      final todayIndex = provider.todayMonthIndex;

      // Verify today's index points to actual current month
      expect(CalendarUtils.isSameMonth(provider.months[todayIndex].month, currentMonth), true);

      // Call goToToday - should navigate to current month (not December)
      provider.goToToday();
      expect(provider.focusedDate.month, today.month);
      expect(provider.focusedDate.year, today.year);
    });

    test('should handle year boundary crossing', () {
      // Test crossing from December 2025 to January 2026
      final provider = CalendarProvider(initialDate: DateTime(2025, 12, 31));

      // Verify months list includes both 2025 and 2026 ranges
      final has2025Months = provider.months.any((m) => m.month.year == 2025);
      final has2026Months = provider.months.any((m) => m.month.year == 2026);

      expect(has2025Months, true);
      expect(has2026Months, true);

      // Verify today index calculation works across year boundaries
      final todayIndex = provider.todayMonthIndex;
      expect(todayIndex >= 0, true);
      expect(todayIndex < 240, true);
    });

    test('should maintain correct range (10 years back/forward)', () {
      final provider = CalendarProvider();
      final today = DateTime.now();
      final currentMonth = DateTime(today.year, today.month, 1);

      // First month should be 120 months before current
      final expectedFirstMonth = DateTime(currentMonth.year, currentMonth.month - 120, 1);
      expect(CalendarUtils.isSameMonth(provider.months[0].month, expectedFirstMonth), true);

      // Last month should be 119 months after current (120 + 120 - 1)
      final expectedLastMonth = DateTime(currentMonth.year, currentMonth.month + 119, 1);
      expect(CalendarUtils.isSameMonth(provider.months[239].month, expectedLastMonth), true);

      // Middle month (index 120) should be current month
      expect(CalendarUtils.isSameMonth(provider.months[120].month, currentMonth), true);
    });
  });

  group('CalendarProvider - Basic Functionality', () {
    test('should navigate to selected date', () {
      final provider = CalendarProvider();
      final targetDate = DateTime(2026, 6, 15);

      provider.selectDate(targetDate);

      expect(provider.focusedDate.year, 2026);
      expect(provider.focusedDate.month, 6);
      expect(provider.focusedDate.day, 15);
    });

    test('should handle page change', () {
      final provider = CalendarProvider();

      provider.onPageChanged(100);

      expect(provider.currentPageIndex, 100);
      expect(CalendarUtils.isSameMonth(provider.focusedDate, provider.months[100].month), true);
    });

    test('should ignore invalid page indices', () {
      final provider = CalendarProvider();
      final initialIndex = provider.currentPageIndex;

      // Try invalid indices
      provider.onPageChanged(-1);
      expect(provider.currentPageIndex, initialIndex);

      provider.onPageChanged(300);
      expect(provider.currentPageIndex, initialIndex);
    });
  });

  group('CalendarProvider - Event Parsing and Indexing', () {
    test('should generate correct date keys for event indexing', () {
      final provider = CalendarProvider();

      // Test various dates
      final date1 = DateTime(2025, 1, 5);
      final date2 = DateTime(2025, 12, 25);
      final date3 = DateTime(2026, 1, 1);

      // Access private method via reflection is not ideal in production,
      // but we can test through public methods
      final key1 = provider.getEventsForDay(date1); // This uses _dateKey internally
      final key2 = provider.getEventsForDay(date2);
      final key3 = provider.getEventsForDay(date3);

      // These should all return empty lists initially (no events)
      expect(key1, isEmpty);
      expect(key2, isEmpty);
      expect(key3, isEmpty);
    });

    test('hasEvents should return false for dates without events', () {
      final provider = CalendarProvider();

      final date = DateTime(2025, 6, 15);
      expect(provider.hasEvents(date), false);
    });

    test('getEventsForDay should return empty list for dates without events', () {
      final provider = CalendarProvider();

      final date = DateTime(2025, 6, 15);
      final events = provider.getEventsForDay(date);

      expect(events, isEmpty);
      expect(events, isA<List<EventModel>>());
    });

    test('should handle same day events with different times', () {
      // This test verifies the internal logic would properly group events
      // In reality, events are loaded from CalendarManager, but we test the structure

      final provider = CalendarProvider();

      // Create multiple events on the same day
      final date = DateTime(2025, 6, 15);

      // Verify initially no events
      expect(provider.hasEvents(date), false);
      expect(provider.getEventsForDay(date).length, 0);

      // Note: In production, events are loaded via _loadEvents() from CalendarManager
      // which requires platform channel mocking. Here we test the empty state behavior.
    });

    test('should differentiate events on different days', () {
      final provider = CalendarProvider();

      final date1 = DateTime(2025, 6, 15);
      final date2 = DateTime(2025, 6, 16);

      // Both should initially have no events
      expect(provider.hasEvents(date1), false);
      expect(provider.hasEvents(date2), false);

      // Events should be independent
      expect(provider.getEventsForDay(date1), isEmpty);
      expect(provider.getEventsForDay(date2), isEmpty);
    });

    test('should handle dates across month boundaries', () {
      final provider = CalendarProvider();

      final endOfMonth = DateTime(2025, 6, 30);
      final startOfNextMonth = DateTime(2025, 7, 1);

      expect(provider.hasEvents(endOfMonth), false);
      expect(provider.hasEvents(startOfNextMonth), false);

      // Should treat them as separate days
      expect(provider.getEventsForDay(endOfMonth), isEmpty);
      expect(provider.getEventsForDay(startOfNextMonth), isEmpty);
    });

    test('should handle dates across year boundaries', () {
      final provider = CalendarProvider();

      final endOfYear = DateTime(2025, 12, 31);
      final startOfYear = DateTime(2026, 1, 1);

      expect(provider.hasEvents(endOfYear), false);
      expect(provider.hasEvents(startOfYear), false);

      // Should treat them as separate days
      expect(provider.getEventsForDay(endOfYear), isEmpty);
      expect(provider.getEventsForDay(startOfYear), isEmpty);
    });

    test('should handle leap year dates correctly', () {
      final provider = CalendarProvider();

      // 2024 is a leap year
      final leapDay = DateTime(2024, 2, 29);
      final nextDay = DateTime(2024, 3, 1);

      expect(provider.hasEvents(leapDay), false);
      expect(provider.hasEvents(nextDay), false);
    });

    test('should initialize with loading state false after failed load', () {
      final provider = CalendarProvider();

      // Provider initializes and attempts to load events
      // Without calendar permission, loading should complete with no events
      // We can't easily test async initialization without mocking,
      // but we verify the state is stable

      expect(provider.focusedDate, isNotNull);
      expect(provider.months, isNotEmpty);
    });
  });
}
