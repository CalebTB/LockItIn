import '../../utils/calendar_utils.dart';

/// Data model representing a calendar month with all its dates
class CalendarMonth {
  /// The first day of the month (always day 1)
  final DateTime month;

  /// All 42 dates to display (6 weeks including prev/next month padding)
  final List<DateTime> dates;

  const CalendarMonth({
    required this.month,
    required this.dates,
  });

  /// Factory constructor to create a CalendarMonth from a DateTime
  factory CalendarMonth.fromMonth(DateTime month) {
    final firstDay = CalendarUtils.getFirstDayOfMonth(month);
    return CalendarMonth(
      month: firstDay,
      dates: CalendarUtils.generateMonthDates(firstDay),
    );
  }

  /// Get the year of this month
  int get year => month.year;

  /// Get the month number (1-12)
  int get monthNumber => month.month;

  /// Check if this month contains today's date
  bool get containsToday {
    final today = DateTime.now();
    return month.year == today.year && month.month == today.month;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarMonth &&
          runtimeType == other.runtimeType &&
          month == other.month;

  @override
  int get hashCode => month.hashCode;

  @override
  String toString() => 'CalendarMonth(${month.year}-${month.month})';
}
