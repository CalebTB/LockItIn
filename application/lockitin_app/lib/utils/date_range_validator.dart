/// Utility class for validating and adjusting date ranges
class DateRangeValidator {
  /// Validates a date range and returns adjusted dates if needed
  ///
  /// Returns a record with (startDate, endDate) where:
  /// - If startDate > endDate, endDate is updated to match startDate
  /// - If endDate < startDate, startDate is updated to match endDate
  static ({DateTime start, DateTime end}) validateRange({
    required DateTime startDate,
    required DateTime endDate,
    required bool startDateChanged,
  }) {
    if (startDateChanged) {
      // Start date was changed - adjust end if needed
      if (startDate.isAfter(endDate)) {
        return (start: startDate, end: startDate);
      }
    } else {
      // End date was changed - adjust start if needed
      if (endDate.isBefore(startDate)) {
        return (start: endDate, end: endDate);
      }
    }
    return (start: startDate, end: endDate);
  }

  /// Returns the number of days in a given month/year
  static int daysInMonth(int month, int year) {
    return DateTime(year, month + 1, 0).day;
  }

  /// Adjusts the day if it exceeds the max days in the new month/year
  static int adjustDayForMonth(int day, int month, int year) {
    final maxDay = daysInMonth(month, year);
    return day > maxDay ? maxDay : day;
  }

  /// Creates a DateTime with day adjusted for the month
  static DateTime createDateWithAdjustedDay({
    required int year,
    required int month,
    required int day,
  }) {
    final adjustedDay = adjustDayForMonth(day, month, year);
    return DateTime(year, month, adjustedDay);
  }
}
