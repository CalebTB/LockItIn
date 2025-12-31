import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/utils/calendar_utils.dart';
import 'package:lockitin_app/data/models/event_model.dart';
import 'package:lockitin_app/core/theme/app_colors.dart';

void main() {
  group('CalendarUtils', () {
    group('generateMonthDates', () {
      test('should return exactly 42 dates', () {
        final dates = CalendarUtils.generateMonthDates(DateTime(2025, 6, 1));
        expect(dates.length, 42);
      });

      test('should start from Sunday before first day of month', () {
        // June 2025 starts on Sunday, so first date should be June 1
        final juneDate = CalendarUtils.generateMonthDates(DateTime(2025, 6, 1));
        expect(juneDate.first.weekday, DateTime.sunday);

        // May 2025 starts on Thursday, so first date should be April 27
        final mayDates = CalendarUtils.generateMonthDates(DateTime(2025, 5, 1));
        expect(mayDates.first.weekday, DateTime.sunday);
        expect(mayDates.first.month, 4); // April
        expect(mayDates.first.day, 27);
      });

      test('should include all days of the month', () {
        final dates = CalendarUtils.generateMonthDates(DateTime(2025, 6, 1));

        // Should contain all days of June
        for (int day = 1; day <= 30; day++) {
          final hasDay = dates.any(
            (d) => d.year == 2025 && d.month == 6 && d.day == day,
          );
          expect(hasDay, true, reason: 'Should contain June $day');
        }
      });
    });

    group('generateMonthRange', () {
      test('should generate correct number of months', () {
        final months = CalendarUtils.generateMonthRange(DateTime(2025, 1, 1), 6);
        expect(months.length, 6);
      });

      test('should handle year rollover', () {
        final months = CalendarUtils.generateMonthRange(DateTime(2025, 10, 1), 6);

        expect(months[0].month, 10);
        expect(months[0].year, 2025);
        expect(months[2].month, 12);
        expect(months[2].year, 2025);
        expect(months[3].month, 1);
        expect(months[3].year, 2026);
      });
    });

    group('isToday', () {
      test('should return true for today', () {
        final today = DateTime.now();
        expect(CalendarUtils.isToday(today), true);
      });

      test('should return false for yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(CalendarUtils.isToday(yesterday), false);
      });

      test('should return false for tomorrow', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        expect(CalendarUtils.isToday(tomorrow), false);
      });

      test('should ignore time component', () {
        final now = DateTime.now();
        final todayMidnight = DateTime(now.year, now.month, now.day, 0, 0, 0);
        final todayNoon = DateTime(now.year, now.month, now.day, 12, 0, 0);
        final todayLate = DateTime(now.year, now.month, now.day, 23, 59, 59);

        expect(CalendarUtils.isToday(todayMidnight), true);
        expect(CalendarUtils.isToday(todayNoon), true);
        expect(CalendarUtils.isToday(todayLate), true);
      });
    });

    group('isSameMonth', () {
      test('should return true for same month', () {
        final date1 = DateTime(2025, 6, 1);
        final date2 = DateTime(2025, 6, 30);

        expect(CalendarUtils.isSameMonth(date1, date2), true);
      });

      test('should return false for different months', () {
        final date1 = DateTime(2025, 6, 1);
        final date2 = DateTime(2025, 7, 1);

        expect(CalendarUtils.isSameMonth(date1, date2), false);
      });

      test('should return false for same month different year', () {
        final date1 = DateTime(2025, 6, 1);
        final date2 = DateTime(2024, 6, 1);

        expect(CalendarUtils.isSameMonth(date1, date2), false);
      });
    });

    group('isSameDay', () {
      test('should return true for same day', () {
        final date1 = DateTime(2025, 6, 15, 10, 0);
        final date2 = DateTime(2025, 6, 15, 14, 30);

        expect(CalendarUtils.isSameDay(date1, date2), true);
      });

      test('should return false for different days', () {
        final date1 = DateTime(2025, 6, 15);
        final date2 = DateTime(2025, 6, 16);

        expect(CalendarUtils.isSameDay(date1, date2), false);
      });
    });

    group('getFirstDayOfMonth', () {
      test('should return first day of month', () {
        final date = DateTime(2025, 6, 15);
        final firstDay = CalendarUtils.getFirstDayOfMonth(date);

        expect(firstDay, DateTime(2025, 6, 1));
      });
    });

    group('getLastDayOfMonth', () {
      test('should return last day of month with 31 days', () {
        final date = DateTime(2025, 7, 15);
        final lastDay = CalendarUtils.getLastDayOfMonth(date);

        expect(lastDay, DateTime(2025, 7, 31));
      });

      test('should return last day of month with 30 days', () {
        final date = DateTime(2025, 6, 15);
        final lastDay = CalendarUtils.getLastDayOfMonth(date);

        expect(lastDay, DateTime(2025, 6, 30));
      });

      test('should return last day of February non-leap year', () {
        final date = DateTime(2025, 2, 1);
        final lastDay = CalendarUtils.getLastDayOfMonth(date);

        expect(lastDay, DateTime(2025, 2, 28));
      });

      test('should return last day of February leap year', () {
        final date = DateTime(2024, 2, 1);
        final lastDay = CalendarUtils.getLastDayOfMonth(date);

        expect(lastDay, DateTime(2024, 2, 29));
      });
    });

    group('daysBetween', () {
      test('should return 1 for same day', () {
        final date = DateTime(2025, 6, 15);
        expect(CalendarUtils.daysBetween(date, date), 1);
      });

      test('should return correct count for consecutive days', () {
        final start = DateTime(2025, 6, 15);
        final end = DateTime(2025, 6, 17);

        expect(CalendarUtils.daysBetween(start, end), 3);
      });

      test('should handle month boundaries', () {
        final start = DateTime(2025, 6, 28);
        final end = DateTime(2025, 7, 2);

        expect(CalendarUtils.daysBetween(start, end), 5);
      });
    });

    group('getDateRange', () {
      test('should return single date for same day', () {
        final date = DateTime(2025, 6, 15);
        final range = CalendarUtils.getDateRange(date, date);

        expect(range.length, 1);
        expect(range[0], DateTime(2025, 6, 15));
      });

      test('should return correct dates for range', () {
        final start = DateTime(2025, 6, 15);
        final end = DateTime(2025, 6, 17);
        final range = CalendarUtils.getDateRange(start, end);

        expect(range.length, 3);
        expect(range[0], DateTime(2025, 6, 15));
        expect(range[1], DateTime(2025, 6, 16));
        expect(range[2], DateTime(2025, 6, 17));
      });
    });

    group('getCategoryColor', () {
      test('should return correct colors for each category', () {
        expect(CalendarUtils.getCategoryColor(EventCategory.work), AppColors.categoryWork);
        expect(CalendarUtils.getCategoryColor(EventCategory.holiday), AppColors.categoryHoliday);
        expect(CalendarUtils.getCategoryColor(EventCategory.friend), AppColors.categoryFriend);
        expect(CalendarUtils.getCategoryColor(EventCategory.other), AppColors.categoryOther);
      });
    });

    group('getCategoryIcon', () {
      test('should return correct icons for each category', () {
        expect(CalendarUtils.getCategoryIcon(EventCategory.work), Icons.work);
        expect(CalendarUtils.getCategoryIcon(EventCategory.holiday), Icons.celebration);
        expect(CalendarUtils.getCategoryIcon(EventCategory.friend), Icons.people);
        expect(CalendarUtils.getCategoryIcon(EventCategory.other), Icons.event);
      });
    });

    group('isAllDayEvent', () {
      EventModel createEvent({
        required DateTime startTime,
        required DateTime endTime,
      }) {
        return EventModel(
          id: 'event-1',
          userId: 'user-1',
          title: 'Test Event',
          startTime: startTime,
          endTime: endTime,
          visibility: EventVisibility.private,
          category: EventCategory.other,
          createdAt: DateTime.now(),
        );
      }

      test('should return true for event spanning midnight to end of day', () {
        final event = createEvent(
          startTime: DateTime(2025, 6, 15, 0, 0),
          endTime: DateTime(2025, 6, 15, 23, 59),
        );

        expect(CalendarUtils.isAllDayEvent(event), true);
      });

      test('should return true for event spanning exactly 24 hours', () {
        final event = createEvent(
          startTime: DateTime(2025, 6, 15, 0, 0),
          endTime: DateTime(2025, 6, 16, 0, 0),
        );

        expect(CalendarUtils.isAllDayEvent(event), true);
      });

      test('should return true for multi-day event', () {
        final event = createEvent(
          startTime: DateTime(2025, 6, 15, 0, 0),
          endTime: DateTime(2025, 6, 17, 0, 0),
        );

        expect(CalendarUtils.isAllDayEvent(event), true);
      });

      test('should return false for regular timed event', () {
        final event = createEvent(
          startTime: DateTime(2025, 6, 15, 10, 0),
          endTime: DateTime(2025, 6, 15, 11, 0),
        );

        expect(CalendarUtils.isAllDayEvent(event), false);
      });

      test('should return false for event starting at midnight but not all-day', () {
        final event = createEvent(
          startTime: DateTime(2025, 6, 15, 0, 0),
          endTime: DateTime(2025, 6, 15, 6, 0),
        );

        expect(CalendarUtils.isAllDayEvent(event), false);
      });
    });
  });
}
