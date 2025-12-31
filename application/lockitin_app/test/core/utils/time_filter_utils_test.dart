import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/core/utils/time_filter_utils.dart';

void main() {
  group('TimeFilter Enum', () {
    test('should have all expected values', () {
      expect(TimeFilter.values.length, 5);
      expect(TimeFilter.values.contains(TimeFilter.allDay), true);
      expect(TimeFilter.values.contains(TimeFilter.morning), true);
      expect(TimeFilter.values.contains(TimeFilter.afternoon), true);
      expect(TimeFilter.values.contains(TimeFilter.evening), true);
      expect(TimeFilter.values.contains(TimeFilter.night), true);
    });
  });

  group('TimeFilterExtension', () {
    group('label', () {
      test('should return correct labels for each filter', () {
        expect(TimeFilter.allDay.label, 'All Day');
        expect(TimeFilter.morning.label, 'Morning');
        expect(TimeFilter.afternoon.label, 'Afternoon');
        expect(TimeFilter.evening.label, 'Evening');
        expect(TimeFilter.night.label, 'Night');
      });
    });

    group('timeRange', () {
      test('should return correct time ranges for each filter', () {
        expect(TimeFilter.allDay.timeRange, '12am - 12am');
        expect(TimeFilter.morning.timeRange, '6am - 12pm');
        expect(TimeFilter.afternoon.timeRange, '12pm - 5pm');
        expect(TimeFilter.evening.timeRange, '5pm - 10pm');
        expect(TimeFilter.night.timeRange, '10pm - 6am');
      });
    });

    group('startHour', () {
      test('should return correct start hours for each filter', () {
        expect(TimeFilter.allDay.startHour, 0);
        expect(TimeFilter.morning.startHour, 6);
        expect(TimeFilter.afternoon.startHour, 12);
        expect(TimeFilter.evening.startHour, 17);
        expect(TimeFilter.night.startHour, 22);
      });
    });

    group('endHour', () {
      test('should return correct end hours for each filter', () {
        expect(TimeFilter.allDay.endHour, 24);
        expect(TimeFilter.morning.endHour, 12);
        expect(TimeFilter.afternoon.endHour, 17);
        expect(TimeFilter.evening.endHour, 22);
        expect(TimeFilter.night.endHour, 6); // Wraps to next day
      });
    });

    group('getTimeBoundaries', () {
      final testDate = DateTime(2025, 6, 15);

      test('should return correct boundaries for morning filter', () {
        final boundaries = TimeFilter.morning.getTimeBoundaries(testDate);

        expect(boundaries.start, DateTime(2025, 6, 15, 6, 0));
        expect(boundaries.end, DateTime(2025, 6, 15, 12, 0));
      });

      test('should return correct boundaries for afternoon filter', () {
        final boundaries = TimeFilter.afternoon.getTimeBoundaries(testDate);

        expect(boundaries.start, DateTime(2025, 6, 15, 12, 0));
        expect(boundaries.end, DateTime(2025, 6, 15, 17, 0));
      });

      test('should return correct boundaries for evening filter', () {
        final boundaries = TimeFilter.evening.getTimeBoundaries(testDate);

        expect(boundaries.start, DateTime(2025, 6, 15, 17, 0));
        expect(boundaries.end, DateTime(2025, 6, 15, 22, 0));
      });

      test('should return correct boundaries for night filter (crosses midnight)', () {
        final boundaries = TimeFilter.night.getTimeBoundaries(testDate);

        expect(boundaries.start, DateTime(2025, 6, 15, 22, 0));
        expect(boundaries.end, DateTime(2025, 6, 16, 6, 0)); // Next day
      });

      test('should return correct boundaries for allDay filter', () {
        final boundaries = TimeFilter.allDay.getTimeBoundaries(testDate);

        expect(boundaries.start, DateTime(2025, 6, 15, 0, 0));
        expect(boundaries.end, DateTime(2025, 6, 15, 24, 0));
      });

      test('should use custom times for allDay filter when provided', () {
        final boundaries = TimeFilter.allDay.getTimeBoundaries(
          testDate,
          customStart: const TimeOfDay(hour: 9, minute: 0),
          customEnd: const TimeOfDay(hour: 17, minute: 0),
        );

        expect(boundaries.start, DateTime(2025, 6, 15, 9, 0));
        expect(boundaries.end, DateTime(2025, 6, 15, 17, 0));
      });

      test('should ignore custom times for non-allDay filters', () {
        final boundaries = TimeFilter.morning.getTimeBoundaries(
          testDate,
          customStart: const TimeOfDay(hour: 9, minute: 0),
          customEnd: const TimeOfDay(hour: 17, minute: 0),
        );

        // Should use morning filter times, not custom times
        expect(boundaries.start, DateTime(2025, 6, 15, 6, 0));
        expect(boundaries.end, DateTime(2025, 6, 15, 12, 0));
      });
    });
  });
}
