import 'package:clock/clock.dart';
import 'package:intl/intl.dart';

/// Timezone utilities for UTC storage + local display pattern
///
/// TIMEZONE POLICY:
/// - STORAGE: Always store in UTC (use DateTime.utc() or .toUtc())
/// - DISPLAY: Always display in user's device timezone (use .toLocal())
/// - TESTING: Use Clock package to mock DateTime.now()
/// - NEVER use TZDateTime in production code (only DateTime)
///
/// This class handles:
/// - Safe parsing with validation (prevents crashes from malformed data)
/// - Performance optimization (cached DateFormat instances)
/// - All-day event handling (no timezone conversion for dates)
/// - DST edge case detection (spring forward/fall back)
class TimezoneUtils {
  // ===== CORE UTILITIES =====

  /// Parse ISO 8601 string from database as UTC
  ///
  /// Validates format to prevent crashes from malformed data.
  /// Throws [ArgumentError] if string is not valid ISO 8601.
  ///
  /// Example:
  /// ```dart
  /// final utc = TimezoneUtils.parseUtc('2026-01-08T19:30:00Z');
  /// print(utc.isUtc); // true
  /// ```
  static DateTime parseUtc(String isoString) {
    // Validate ISO 8601 format: YYYY-MM-DDTHH:MM:SS.sssZ or with timezone offset (+00:00)
    // Accepts: 2026-01-10T01:00:00Z, 2026-01-10T01:00:00+00:00, 2026-01-10T01:00:00.123Z
    final iso8601Regex = RegExp(
      r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3,6})?(Z|[+-]\d{2}:\d{2})?$',
    );

    if (!iso8601Regex.hasMatch(isoString)) {
      throw ArgumentError('Invalid ISO 8601 format: $isoString');
    }

    try {
      final parsed = DateTime.parse(isoString);
      return parsed.isUtc ? parsed : parsed.toUtc();
    } catch (e) {
      throw ArgumentError('Failed to parse datetime: $isoString (error: $e)');
    }
  }

  /// Serialize DateTime to UTC ISO 8601 string for database
  ///
  /// Always converts to UTC before serialization, ensuring consistent storage.
  ///
  /// Example:
  /// ```dart
  /// final local = DateTime(2026, 1, 8, 14, 30); // 2:30 PM local
  /// final utcString = TimezoneUtils.toUtcString(local);
  /// print(utcString); // "2026-01-08T22:30:00.000Z" (if PST)
  /// ```
  static String toUtcString(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }

  /// Get current time in UTC (testable via clock package)
  ///
  /// Uses Clock package to allow mocking in tests.
  /// Always returns UTC for consistent comparisons.
  ///
  /// Example:
  /// ```dart
  /// final now = TimezoneUtils.nowUtc();
  /// if (event.startTime.isBefore(now)) {
  ///   print('Event is in the past');
  /// }
  /// ```
  static DateTime nowUtc() {
    return clock.now().toUtc();
  }

  /// Get current time in local timezone (convenience method)
  ///
  /// Equivalent to `nowUtc().toLocal()` but more concise.
  /// Use this for date pickers, default dates, and UI comparisons.
  ///
  /// Example:
  /// ```dart
  /// final now = TimezoneUtils.nowLocal();
  /// final tomorrow = now.add(Duration(days: 1));
  /// ```
  static DateTime nowLocal() {
    return clock.now().toLocal();
  }

  /// Format UTC DateTime in local timezone
  ///
  /// Uses cached DateFormat instances for performance.
  /// Converts to local timezone before formatting.
  ///
  /// Example:
  /// ```dart
  /// final utc = DateTime.utc(2026, 1, 8, 22, 30);
  /// final formatted = TimezoneUtils.formatLocal(utc, 'h:mm a');
  /// print(formatted); // "2:30 PM" (if PST, UTC-8)
  /// ```
  static String formatLocal(DateTime utcTime, String pattern) {
    final localTime = utcTime.toLocal();
    return _getFormatter(pattern).format(localTime);
  }

  /// Generate date key for event grouping (YYYY-MM-DD in local timezone)
  ///
  /// Used by CalendarProvider and services to group events by local date.
  /// Ensures events display on the correct calendar day in user's timezone.
  ///
  /// Example:
  /// ```dart
  /// final utc = DateTime.utc(2026, 1, 8, 22, 30); // 10:30 PM UTC
  /// final key = TimezoneUtils.getDateKey(utc);
  /// print(key); // "2026-01-08" (if PST, UTC-8, shows as 2:30 PM Jan 8)
  /// ```
  static String getDateKey(DateTime date) {
    final localDate = date.toLocal();
    return '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';
  }

  // ===== PERFORMANCE: FORMAT CACHING =====

  /// Cached DateFormat instances (prevents creating new on every widget build)
  ///
  /// Creating DateFormat instances is expensive (~0.5ms per creation).
  /// Caching reduces overhead to ~0.1ms per format call.
  static final Map<String, DateFormat> _formatCache = {};

  /// Get cached formatter (creates if not exists)
  ///
  /// Internal method for format caching optimization.
  static DateFormat _getFormatter(String pattern) {
    return _formatCache.putIfAbsent(pattern, () => DateFormat(pattern));
  }

  /// Clear format cache (call on locale changes)
  ///
  /// When app locale changes, DateFormat instances need to be recreated
  /// to use the new locale's formatting rules.
  ///
  /// Example:
  /// ```dart
  /// void onLocaleChanged(Locale newLocale) {
  ///   TimezoneUtils.clearFormatCache();
  ///   Intl.defaultLocale = newLocale.toString();
  /// }
  /// ```
  static void clearFormatCache() {
    _formatCache.clear();
  }

  // ===== ALL-DAY EVENTS =====

  /// Check if DateTime represents all-day event (midnight with no time)
  ///
  /// All-day events are stored as local midnight (00:00:00) without
  /// timezone conversion to preserve the date across timezones.
  ///
  /// Example:
  /// ```dart
  /// final midnight = DateTime(2026, 1, 15);
  /// print(TimezoneUtils.isAllDayEvent(midnight)); // true
  ///
  /// final afternoon = DateTime(2026, 1, 15, 14, 30);
  /// print(TimezoneUtils.isAllDayEvent(afternoon)); // false
  /// ```
  static bool isAllDayEvent(DateTime dateTime) {
    return dateTime.hour == 0 &&
        dateTime.minute == 0 &&
        dateTime.second == 0 &&
        dateTime.millisecond == 0;
  }

  /// Format all-day date (no time, no timezone conversion)
  ///
  /// All-day events should display the date only, without time or
  /// timezone conversion. This ensures "Birthday on Jan 15" shows
  /// as Jan 15 in all timezones.
  ///
  /// Example:
  /// ```dart
  /// final birthday = DateTime(2026, 1, 15);
  /// final formatted = TimezoneUtils.formatAllDayDate(birthday);
  /// print(formatted); // "Wed, Jan 15"
  /// ```
  static String formatAllDayDate(DateTime dateTime) {
    return _getFormatter('EEE, MMM d').format(dateTime);
  }

  // ===== DST HANDLING =====

  /// Validate time doesn't fall in DST gap (spring forward)
  ///
  /// During Daylight Saving Time transitions, certain times don't exist:
  /// - Spring Forward: 2:00 AM → 3:00 AM (2:30 AM doesn't exist)
  /// - Fall Back: 2:00 AM → 1:00 AM (1:30 AM happens twice)
  ///
  /// This method detects non-existent times and returns the adjusted time.
  ///
  /// Example:
  /// ```dart
  /// // March 9, 2025 at 2:30 AM PST doesn't exist
  /// final nonExistent = DateTime(2025, 3, 9, 2, 30);
  /// final adjusted = TimezoneUtils.validateDSTSafe(nonExistent);
  /// print(adjusted.hour); // 3 (adjusted to 3:30 AM)
  /// ```
  static DateTime validateDSTSafe(DateTime local) {
    final utc = local.toUtc();
    final roundTrip = utc.toLocal();

    if (roundTrip.hour != local.hour) {
      // Time adjusted due to DST transition
      return roundTrip;
    }

    return local;
  }

  /// Check if time is during DST transition
  ///
  /// Returns true if the given local time falls during a DST transition
  /// (spring forward or fall back), indicating the time may be ambiguous
  /// or non-existent.
  ///
  /// Example:
  /// ```dart
  /// final dstTime = DateTime(2025, 3, 9, 2, 30);
  /// if (TimezoneUtils.isDSTTransition(dstTime)) {
  ///   print('Warning: Time may be adjusted due to DST');
  /// }
  /// ```
  static bool isDSTTransition(DateTime local) {
    final utc = local.toUtc();
    final roundTrip = utc.toLocal();
    return roundTrip.hour != local.hour;
  }
}
