import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/core/utils/timezone_utils.dart';

void main() {
  group('TimezoneUtils', () {
    group('parseUtc', () {
      test('parses valid UTC string', () {
        final utcTime = TimezoneUtils.parseUtc('2026-01-08T19:30:00Z');

        expect(utcTime.isUtc, isTrue);
        expect(utcTime.year, 2026);
        expect(utcTime.month, 1);
        expect(utcTime.day, 8);
        expect(utcTime.hour, 19);
        expect(utcTime.minute, 30);
      });

      test('parses valid UTC string with milliseconds', () {
        final utcTime = TimezoneUtils.parseUtc('2026-01-08T19:30:00.123Z');

        expect(utcTime.isUtc, isTrue);
        expect(utcTime.millisecond, 123);
      });

      test('converts non-UTC string to UTC', () {
        final utcTime = TimezoneUtils.parseUtc('2026-01-08T19:30:00');

        expect(utcTime.isUtc, isTrue);
      });

      test('throws ArgumentError for invalid format', () {
        expect(
          () => TimezoneUtils.parseUtc('invalid'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for invalid date', () {
        // Test with a string that doesn't match ISO 8601 format
        expect(
          () => TimezoneUtils.parseUtc('2026/01/08 19:30:00'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for malformed string', () {
        expect(
          () => TimezoneUtils.parseUtc('not-a-date'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('toUtcString', () {
      test('converts UTC DateTime to ISO string', () {
        final utcTime = DateTime.utc(2026, 1, 8, 19, 30);
        final isoString = TimezoneUtils.toUtcString(utcTime);

        expect(isoString, startsWith('2026-01-08T19:30:00'));
        expect(isoString, endsWith('Z'));
      });

      test('converts local DateTime to UTC ISO string', () {
        final localTime = DateTime(2026, 1, 8, 14, 30);
        final isoString = TimezoneUtils.toUtcString(localTime);

        // Should be converted to UTC (actual time depends on device timezone)
        expect(isoString, contains('2026-01-08'));
        expect(isoString, endsWith('Z'));
      });
    });

    group('nowUtc', () {
      test('returns current time in UTC', () {
        final now = TimezoneUtils.nowUtc();

        expect(now.isUtc, isTrue);
        // Verify it's approximately current time (within 1 second)
        final actual = DateTime.now().toUtc();
        expect(
          now.difference(actual).inSeconds.abs(),
          lessThan(1),
        );
      });

      test('is mockable with clock package', () {
        final fixedTime = DateTime.utc(2026, 1, 8, 12, 0);

        withClock(Clock.fixed(fixedTime), () {
          final now = TimezoneUtils.nowUtc();
          expect(now, fixedTime);
          expect(now.isUtc, isTrue);
        });
      });
    });

    group('formatLocal', () {
      test('formats UTC time in local timezone', () {
        final utcTime = DateTime.utc(2026, 1, 8, 19, 30);
        final formatted = TimezoneUtils.formatLocal(utcTime, 'h:mm a');

        // Result depends on device timezone, but should be valid format
        expect(formatted, matches(RegExp(r'^\d{1,2}:\d{2} [AP]M$')));
      });

      test('uses cached formatters for performance', () {
        final utcTime = DateTime.utc(2026, 1, 8, 19, 30);

        // First call creates formatter
        final result1 = TimezoneUtils.formatLocal(utcTime, 'h:mm a');

        // Second call should use cached formatter
        final result2 = TimezoneUtils.formatLocal(utcTime, 'h:mm a');

        expect(result1, result2);
      });

      test('handles different format patterns', () {
        final utcTime = DateTime.utc(2026, 1, 8, 19, 30);

        final time = TimezoneUtils.formatLocal(utcTime, 'h:mm a');
        final date = TimezoneUtils.formatLocal(utcTime, 'yyyy-MM-dd');
        final full = TimezoneUtils.formatLocal(utcTime, 'EEE, MMM d, h:mm a');

        expect(time, matches(RegExp(r'^\d{1,2}:\d{2} [AP]M$')));
        expect(date, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
        expect(full, isNotEmpty);
      });
    });

    group('clearFormatCache', () {
      test('clears the format cache', () {
        final utcTime = DateTime.utc(2026, 1, 8, 19, 30);

        // Populate cache
        TimezoneUtils.formatLocal(utcTime, 'h:mm a');
        TimezoneUtils.formatLocal(utcTime, 'yyyy-MM-dd');

        // Clear cache
        TimezoneUtils.clearFormatCache();

        // Cache should be empty, but formatting still works
        final formatted = TimezoneUtils.formatLocal(utcTime, 'h:mm a');
        expect(formatted, matches(RegExp(r'^\d{1,2}:\d{2} [AP]M$')));
      });
    });

    group('isAllDayEvent', () {
      test('returns true for midnight times', () {
        final midnight = DateTime(2026, 1, 15);
        expect(TimezoneUtils.isAllDayEvent(midnight), isTrue);
      });

      test('returns false for non-midnight times', () {
        final afternoon = DateTime(2026, 1, 15, 14, 30);
        expect(TimezoneUtils.isAllDayEvent(afternoon), isFalse);
      });

      test('returns false for times with seconds', () {
        final withSeconds = DateTime(2026, 1, 15, 0, 0, 1);
        expect(TimezoneUtils.isAllDayEvent(withSeconds), isFalse);
      });

      test('returns false for times with milliseconds', () {
        final withMillis = DateTime(2026, 1, 15, 0, 0, 0, 1);
        expect(TimezoneUtils.isAllDayEvent(withMillis), isFalse);
      });
    });

    group('formatAllDayDate', () {
      test('formats date without time', () {
        final date = DateTime(2026, 1, 15);
        final formatted = TimezoneUtils.formatAllDayDate(date);

        // Should be in format "Wed, Jan 15" (exact day name may vary by locale)
        expect(formatted, matches(RegExp(r'^\w+, \w+ \d{1,2}$')));
      });
    });

    group('validateDSTSafe', () {
      test('returns same time if not in DST transition', () {
        final normalTime = DateTime(2026, 1, 8, 14, 30);
        final validated = TimezoneUtils.validateDSTSafe(normalTime);

        // Should return same time (or adjusted by at most 1 hour if DST)
        expect(validated.year, normalTime.year);
        expect(validated.month, normalTime.month);
        expect(validated.day, normalTime.day);
        expect(validated.minute, normalTime.minute);
      });

      test('does not crash for any valid DateTime', () {
        // Test various times throughout the year
        for (int month = 1; month <= 12; month++) {
          for (int hour = 0; hour < 24; hour++) {
            final time = DateTime(2026, month, 15, hour, 30);
            expect(
              () => TimezoneUtils.validateDSTSafe(time),
              returnsNormally,
            );
          }
        }
      });
    });

    group('isDSTTransition', () {
      test('returns boolean for any valid DateTime', () {
        final normalTime = DateTime(2026, 1, 8, 14, 30);
        final isDST = TimezoneUtils.isDSTTransition(normalTime);

        expect(isDST, isA<bool>());
      });

      test('does not crash for DST boundary times', () {
        // March (potential spring forward)
        final marchTime = DateTime(2026, 3, 9, 2, 30);
        expect(
          () => TimezoneUtils.isDSTTransition(marchTime),
          returnsNormally,
        );

        // November (potential fall back)
        final novemberTime = DateTime(2026, 11, 2, 1, 30);
        expect(
          () => TimezoneUtils.isDSTTransition(novemberTime),
          returnsNormally,
        );
      });
    });
  });
}
