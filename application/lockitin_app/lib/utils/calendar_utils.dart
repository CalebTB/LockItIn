import 'package:flutter/material.dart';
import '../data/models/event_model.dart';
import '../core/theme/app_colors.dart';

/// Calendar utility functions for date calculations and formatting
class CalendarUtils {
  /// Private constructor to prevent instantiation
  CalendarUtils._();

  /// Generate all dates for a month view (including prev/next month padding)
  /// Returns exactly 42 dates (6 weeks) for consistent grid height
  static List<DateTime> generateMonthDates(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    // Start from the Sunday before (or on) the first day of month
    final startDate = firstDayOfMonth.subtract(Duration(days: firstWeekday));

    // Generate 42 dates (6 weeks) to ensure all months fill the same space
    return List.generate(42, (i) => startDate.add(Duration(days: i)));
  }

  /// Generate list of months from start month for specified count
  static List<DateTime> generateMonthRange(DateTime startMonth, int count) {
    return List.generate(
      count,
      (i) => DateTime(startMonth.year, startMonth.month + i, 1),
    );
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  /// Check if date belongs to given month
  static bool isSameMonth(DateTime date, DateTime month) {
    return date.year == month.year && date.month == month.month;
  }

  /// Check if two dates are the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Get the first day of the month for a given date
  static DateTime getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get the last day of the month for a given date
  static DateTime getLastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// Calculate number of days between two dates (inclusive)
  static int daysBetween(DateTime start, DateTime end) {
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    return endDate.difference(startDate).inDays + 1;
  }

  /// Get list of all dates between start and end (inclusive)
  static List<DateTime> getDateRange(DateTime start, DateTime end) {
    final days = daysBetween(start, end);
    return List.generate(
      days,
      (i) => DateTime(start.year, start.month, start.day + i),
    );
  }

  /// Get color for event category
  /// Work = Green, Holiday = Red, Friend = Purple, Other = Yellow
  static Color getCategoryColor(EventCategory category) {
    switch (category) {
      case EventCategory.work:
        return AppColors.categoryWork;
      case EventCategory.holiday:
        return AppColors.categoryHoliday;
      case EventCategory.friend:
        return AppColors.categoryFriend;
      case EventCategory.other:
        return AppColors.categoryOther;
    }
  }

  /// Get icon for event category
  static IconData getCategoryIcon(EventCategory category) {
    switch (category) {
      case EventCategory.work:
        return Icons.work;
      case EventCategory.holiday:
        return Icons.celebration;
      case EventCategory.friend:
        return Icons.people;
      case EventCategory.other:
        return Icons.event;
    }
  }

  /// Check if event is all-day (spans midnight to end of day)
  /// An event is considered all-day if:
  /// - It starts at 00:00 and ends at 23:59, OR
  /// - Duration is exactly 24 hours or more
  static bool isAllDayEvent(EventModel event) {
    final duration = event.endTime.difference(event.startTime);
    final isExactly24Hours = duration.inHours == 24 || duration.inDays >= 1;
    final startsMidnight = event.startTime.hour == 0 && event.startTime.minute == 0;
    final endsMidnight = event.endTime.hour == 0 && event.endTime.minute == 0;
    final endsEndOfDay = event.endTime.hour == 23 && event.endTime.minute == 59;

    return isExactly24Hours || (startsMidnight && endsMidnight) || (startsMidnight && endsEndOfDay);
  }
}
