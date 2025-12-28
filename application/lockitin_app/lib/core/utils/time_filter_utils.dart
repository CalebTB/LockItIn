import 'package:flutter/material.dart';

/// Time range filter options for availability
enum TimeFilter {
  allDay,
  morning,    // 6am - 12pm
  afternoon,  // 12pm - 5pm
  evening,    // 5pm - 10pm
  night,      // 10pm - 6am
}

extension TimeFilterExtension on TimeFilter {
  String get label {
    switch (this) {
      case TimeFilter.allDay:
        return 'All Day';
      case TimeFilter.morning:
        return 'Morning';
      case TimeFilter.afternoon:
        return 'Afternoon';
      case TimeFilter.evening:
        return 'Evening';
      case TimeFilter.night:
        return 'Night';
    }
  }

  String get timeRange {
    switch (this) {
      case TimeFilter.allDay:
        return '12am - 12am';
      case TimeFilter.morning:
        return '6am - 12pm';
      case TimeFilter.afternoon:
        return '12pm - 5pm';
      case TimeFilter.evening:
        return '5pm - 10pm';
      case TimeFilter.night:
        return '10pm - 6am';
    }
  }

  /// Get start hour (0-23)
  int get startHour {
    switch (this) {
      case TimeFilter.allDay:
        return 0;
      case TimeFilter.morning:
        return 6;
      case TimeFilter.afternoon:
        return 12;
      case TimeFilter.evening:
        return 17;
      case TimeFilter.night:
        return 22;
    }
  }

  /// Get end hour (0-23)
  int get endHour {
    switch (this) {
      case TimeFilter.allDay:
        return 24;
      case TimeFilter.morning:
        return 12;
      case TimeFilter.afternoon:
        return 17;
      case TimeFilter.evening:
        return 22;
      case TimeFilter.night:
        return 6; // Wraps to next day
    }
  }

  /// Get time boundaries for this filter on a specific date
  ({DateTime start, DateTime end}) getTimeBoundaries(
    DateTime date, {
    TimeOfDay? customStart,
    TimeOfDay? customEnd,
  }) {
    if (this == TimeFilter.allDay && customStart != null && customEnd != null) {
      return (
        start: DateTime(date.year, date.month, date.day, customStart.hour, customStart.minute),
        end: DateTime(date.year, date.month, date.day, customEnd.hour, customEnd.minute),
      );
    }

    if (this == TimeFilter.night) {
      // Night spans 10pm - 6am (crosses midnight)
      return (
        start: DateTime(date.year, date.month, date.day, startHour),
        end: DateTime(date.year, date.month, date.day + 1, endHour),
      );
    }

    return (
      start: DateTime(date.year, date.month, date.day, startHour),
      end: DateTime(date.year, date.month, date.day, endHour),
    );
  }
}
