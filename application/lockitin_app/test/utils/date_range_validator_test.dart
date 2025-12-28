import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/utils/date_range_validator.dart';

void main() {
  group('DateRangeValidator', () {
    group('validateRange', () {
      test('returns unchanged dates when range is valid', () {
        final start = DateTime(2025, 12, 25);
        final end = DateTime(2025, 12, 31);

        final result = DateRangeValidator.validateRange(
          startDate: start,
          endDate: end,
          startDateChanged: true,
        );

        expect(result.start, equals(start));
        expect(result.end, equals(end));
      });

      test('updates end date when start date is moved after end date', () {
        final start = DateTime(2026, 1, 15); // Start moved to after end
        final end = DateTime(2025, 12, 31);

        final result = DateRangeValidator.validateRange(
          startDate: start,
          endDate: end,
          startDateChanged: true,
        );

        expect(result.start, equals(start));
        expect(result.end, equals(start)); // End should match start
      });

      test('updates start date when end date is moved before start date', () {
        final start = DateTime(2025, 12, 25);
        final end = DateTime(2025, 12, 20); // End moved to before start

        final result = DateRangeValidator.validateRange(
          startDate: start,
          endDate: end,
          startDateChanged: false,
        );

        expect(result.start, equals(end)); // Start should match end
        expect(result.end, equals(end));
      });

      test('handles same day range correctly', () {
        final sameDay = DateTime(2025, 12, 25);

        final result = DateRangeValidator.validateRange(
          startDate: sameDay,
          endDate: sameDay,
          startDateChanged: true,
        );

        expect(result.start, equals(sameDay));
        expect(result.end, equals(sameDay));
      });

      test('handles year boundary crossing - start after end', () {
        final start = DateTime(2026, 1, 5); // January next year
        final end = DateTime(2025, 12, 28); // December this year

        final result = DateRangeValidator.validateRange(
          startDate: start,
          endDate: end,
          startDateChanged: true,
        );

        expect(result.start, equals(start));
        expect(result.end, equals(start)); // End should be updated to Jan 5, 2026
      });

      test('handles year boundary crossing - end before start', () {
        final start = DateTime(2026, 1, 5);
        final end = DateTime(2025, 12, 28);

        final result = DateRangeValidator.validateRange(
          startDate: start,
          endDate: end,
          startDateChanged: false, // End date changed
        );

        expect(result.start, equals(end)); // Start should be updated to Dec 28, 2025
        expect(result.end, equals(end));
      });
    });

    group('daysInMonth', () {
      test('returns 31 for January', () {
        expect(DateRangeValidator.daysInMonth(1, 2025), equals(31));
      });

      test('returns 28 for February in non-leap year', () {
        expect(DateRangeValidator.daysInMonth(2, 2025), equals(28));
      });

      test('returns 29 for February in leap year', () {
        expect(DateRangeValidator.daysInMonth(2, 2024), equals(29));
      });

      test('returns 30 for April', () {
        expect(DateRangeValidator.daysInMonth(4, 2025), equals(30));
      });

      test('returns 31 for December', () {
        expect(DateRangeValidator.daysInMonth(12, 2025), equals(31));
      });
    });

    group('adjustDayForMonth', () {
      test('returns same day when valid for month', () {
        expect(DateRangeValidator.adjustDayForMonth(15, 1, 2025), equals(15));
      });

      test('returns max day when day exceeds month days', () {
        // February 2025 has 28 days
        expect(DateRangeValidator.adjustDayForMonth(31, 2, 2025), equals(28));
      });

      test('handles leap year February', () {
        // February 2024 has 29 days (leap year)
        expect(DateRangeValidator.adjustDayForMonth(29, 2, 2024), equals(29));
        expect(DateRangeValidator.adjustDayForMonth(30, 2, 2024), equals(29));
      });

      test('handles 30-day months', () {
        // April has 30 days
        expect(DateRangeValidator.adjustDayForMonth(31, 4, 2025), equals(30));
      });
    });

    group('createDateWithAdjustedDay', () {
      test('creates date with same day when valid', () {
        final date = DateRangeValidator.createDateWithAdjustedDay(
          year: 2025,
          month: 12,
          day: 25,
        );

        expect(date, equals(DateTime(2025, 12, 25)));
      });

      test('creates date with adjusted day for short month', () {
        // Trying to create Feb 31, should become Feb 28
        final date = DateRangeValidator.createDateWithAdjustedDay(
          year: 2025,
          month: 2,
          day: 31,
        );

        expect(date, equals(DateTime(2025, 2, 28)));
      });

      test('creates date with adjusted day for leap year February', () {
        // Trying to create Feb 30 in leap year, should become Feb 29
        final date = DateRangeValidator.createDateWithAdjustedDay(
          year: 2024,
          month: 2,
          day: 30,
        );

        expect(date, equals(DateTime(2024, 2, 29)));
      });
    });

    group('edge cases', () {
      test('handles start and end on consecutive days', () {
        final start = DateTime(2025, 12, 30);
        final end = DateTime(2025, 12, 31);

        final result = DateRangeValidator.validateRange(
          startDate: start,
          endDate: end,
          startDateChanged: true,
        );

        expect(result.start, equals(start));
        expect(result.end, equals(end));
      });

      test('handles moving start to same day as end', () {
        final start = DateTime(2025, 12, 31);
        final end = DateTime(2025, 12, 31);

        final result = DateRangeValidator.validateRange(
          startDate: start,
          endDate: end,
          startDateChanged: true,
        );

        expect(result.start, equals(start));
        expect(result.end, equals(end));
      });

      test('handles dates far in the future', () {
        final start = DateTime(2030, 6, 15);
        final end = DateTime(2030, 6, 20);

        final result = DateRangeValidator.validateRange(
          startDate: start,
          endDate: end,
          startDateChanged: true,
        );

        expect(result.start, equals(start));
        expect(result.end, equals(end));
      });

      test('handles month with 31 days to month with 30 days', () {
        // If we're on Jan 31 and switch to April, should become April 30
        final date = DateRangeValidator.createDateWithAdjustedDay(
          year: 2025,
          month: 4,
          day: 31,
        );

        expect(date, equals(DateTime(2025, 4, 30)));
      });
    });
  });
}
