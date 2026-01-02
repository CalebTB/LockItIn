import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/utils/date_range_validator.dart';

void main() {
  group('DateRangeValidator', () {
    group('validateRange', () {
      test('should return unchanged dates when range is valid', () {
        final start = DateTime(2025, 6, 15);
        final end = DateTime(2025, 6, 20);

        final result = DateRangeValidator.validateRange(
          startDate: start,
          endDate: end,
          startDateChanged: true,
        );

        expect(result.start, start);
        expect(result.end, end);
      });

      test('should adjust end date when start changes to after end', () {
        final start = DateTime(2025, 6, 25);
        final end = DateTime(2025, 6, 20);

        final result = DateRangeValidator.validateRange(
          startDate: start,
          endDate: end,
          startDateChanged: true,
        );

        expect(result.start, start);
        expect(result.end, start);
      });

      test('should adjust start date when end changes to before start', () {
        final start = DateTime(2025, 6, 20);
        final end = DateTime(2025, 6, 15);

        final result = DateRangeValidator.validateRange(
          startDate: start,
          endDate: end,
          startDateChanged: false,
        );

        expect(result.start, end);
        expect(result.end, end);
      });

      test('should handle same day for start and end', () {
        final date = DateTime(2025, 6, 15);

        final result = DateRangeValidator.validateRange(
          startDate: date,
          endDate: date,
          startDateChanged: true,
        );

        expect(result.start, date);
        expect(result.end, date);
      });
    });

    group('daysInMonth', () {
      test('should return 31 for January', () {
        expect(DateRangeValidator.daysInMonth(1, 2025), 31);
      });

      test('should return 28 for February non-leap year', () {
        expect(DateRangeValidator.daysInMonth(2, 2025), 28);
      });

      test('should return 29 for February leap year', () {
        expect(DateRangeValidator.daysInMonth(2, 2024), 29);
      });

      test('should return 30 for April', () {
        expect(DateRangeValidator.daysInMonth(4, 2025), 30);
      });

      test('should return 31 for July', () {
        expect(DateRangeValidator.daysInMonth(7, 2025), 31);
      });

      test('should return 30 for November', () {
        expect(DateRangeValidator.daysInMonth(11, 2025), 30);
      });

      test('should return 31 for December', () {
        expect(DateRangeValidator.daysInMonth(12, 2025), 31);
      });
    });

    group('adjustDayForMonth', () {
      test('should return same day if within month bounds', () {
        expect(DateRangeValidator.adjustDayForMonth(15, 6, 2025), 15);
      });

      test('should return same day for day 1', () {
        expect(DateRangeValidator.adjustDayForMonth(1, 2, 2025), 1);
      });

      test('should adjust day 31 to 30 for 30-day month', () {
        expect(DateRangeValidator.adjustDayForMonth(31, 6, 2025), 30);
      });

      test('should adjust day 31 to 28 for February non-leap year', () {
        expect(DateRangeValidator.adjustDayForMonth(31, 2, 2025), 28);
      });

      test('should adjust day 30 to 29 for February leap year', () {
        expect(DateRangeValidator.adjustDayForMonth(30, 2, 2024), 29);
      });

      test('should return day 31 for 31-day month', () {
        expect(DateRangeValidator.adjustDayForMonth(31, 7, 2025), 31);
      });
    });

    group('createDateWithAdjustedDay', () {
      test('should create date with same day when valid', () {
        final date = DateRangeValidator.createDateWithAdjustedDay(
          year: 2025,
          month: 6,
          day: 15,
        );

        expect(date, DateTime(2025, 6, 15));
      });

      test('should adjust day when exceeds month maximum', () {
        final date = DateRangeValidator.createDateWithAdjustedDay(
          year: 2025,
          month: 2,
          day: 31,
        );

        expect(date, DateTime(2025, 2, 28));
      });

      test('should handle February leap year adjustment', () {
        final date = DateRangeValidator.createDateWithAdjustedDay(
          year: 2024,
          month: 2,
          day: 30,
        );

        expect(date, DateTime(2024, 2, 29));
      });

      test('should handle 30-day month adjustment', () {
        final date = DateRangeValidator.createDateWithAdjustedDay(
          year: 2025,
          month: 4,
          day: 31,
        );

        expect(date, DateTime(2025, 4, 30));
      });

      test('should handle day 1 for any month', () {
        final date = DateRangeValidator.createDateWithAdjustedDay(
          year: 2025,
          month: 2,
          day: 1,
        );

        expect(date, DateTime(2025, 2, 1));
      });
    });
  });
}
