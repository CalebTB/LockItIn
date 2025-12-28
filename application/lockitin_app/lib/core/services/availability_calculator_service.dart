import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/event_model.dart';
import '../utils/time_filter_utils.dart';

/// Service for calculating group availability based on member events
///
/// This service handles all availability logic:
/// - Determining if a member is available on a specific date
/// - Counting available members for group heatmap display
/// - Finding the longest contiguous free time blocks
/// - Generating human-readable availability descriptions
///
/// Availability is defined as having at least [minContiguousFreeMinutes]
/// of uninterrupted free time within the selected time filter.
class AvailabilityCalculatorService {
  /// Minimum contiguous free time required to be considered "available" (in minutes)
  static const int minContiguousFreeMinutes = 120; // 2 hours

  /// Calculate how many group members are available on a specific date
  ///
  /// Returns the count of available members (0 to totalMembers)
  ///
  /// [memberEvents] - Map of userId to their events
  /// [date] - The date to check availability for
  /// [timeFilters] - Set of time filters to apply
  /// [customStartTime] - Custom start time (used when allDay filter is selected)
  /// [customEndTime] - Custom end time (used when allDay filter is selected)
  int calculateGroupAvailability({
    required Map<String, List<EventModel>> memberEvents,
    required DateTime date,
    required Set<TimeFilter> timeFilters,
    TimeOfDay? customStartTime,
    TimeOfDay? customEndTime,
  }) {
    if (memberEvents.isEmpty) {
      return 0;
    }

    int availableCount = 0;

    for (final entry in memberEvents.entries) {
      // Get events for this member on this date
      final eventsOnDate = entry.value
          .where((e) {
            final eventDate = e.startTime;
            return eventDate.year == date.year &&
                   eventDate.month == date.month &&
                   eventDate.day == date.day;
          })
          .where((e) => e.category != EventCategory.holiday)
          .toList();

      // Check if this member is available
      if (isMemberAvailable(
        events: eventsOnDate,
        date: date,
        timeFilters: timeFilters,
        customStartTime: customStartTime,
        customEndTime: customEndTime,
      )) {
        availableCount++;
      }
    }

    return availableCount;
  }

  /// Check if a single member is available on a date based on their events
  ///
  /// Returns true if the member has at least [minContiguousFreeMinutes]
  /// of contiguous free time within ALL selected time filters.
  bool isMemberAvailable({
    required List<EventModel> events,
    required DateTime date,
    required Set<TimeFilter> timeFilters,
    TimeOfDay? customStartTime,
    TimeOfDay? customEndTime,
  }) {
    // If "All Day" (Custom) filter is selected, use custom time range
    if (timeFilters.contains(TimeFilter.allDay)) {
      final bounds = TimeFilter.allDay.getTimeBoundaries(
        date,
        customStart: customStartTime,
        customEnd: customEndTime,
      );

      final longestFreeMinutes = findLongestFreeBlock(
        events: events,
        rangeStart: bounds.start,
        rangeEnd: bounds.end,
      );

      return longestFreeMinutes >= minContiguousFreeMinutes;
    }

    // Check each selected time filter - must be available in ALL selected filters
    for (final filter in timeFilters) {
      final bounds = filter.getTimeBoundaries(date);

      final longestFreeMinutes = findLongestFreeBlock(
        events: events,
        rangeStart: bounds.start,
        rangeEnd: bounds.end,
      );

      if (longestFreeMinutes < minContiguousFreeMinutes) {
        return false; // Busy - not enough contiguous free time in this filter
      }
    }

    return true; // Available - has sufficient contiguous free time in all filters
  }

  /// Find the longest contiguous free block within a time range
  ///
  /// Returns the duration in minutes of the longest uninterrupted free time.
  int findLongestFreeBlock({
    required List<EventModel> events,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    // Get events that overlap with this range, sorted by start time
    // Use stored hour/minute directly (wall clock time - no timezone conversion)
    final overlappingEvents = events
        .where((e) {
          final eventStart = DateTime(
            rangeStart.year, rangeStart.month, rangeStart.day,
            e.startTime.hour, e.startTime.minute,
          );
          final eventEnd = DateTime(
            rangeStart.year, rangeStart.month, rangeStart.day,
            e.endTime.hour, e.endTime.minute,
          );
          return eventStart.isBefore(rangeEnd) && eventEnd.isAfter(rangeStart);
        })
        .toList()
      ..sort((a, b) => a.startTime.hour.compareTo(b.startTime.hour));

    if (overlappingEvents.isEmpty) {
      // No events - entire range is free
      return rangeEnd.difference(rangeStart).inMinutes;
    }

    var longestFreeBlock = 0;
    var currentFreeStart = rangeStart;

    for (final event in overlappingEvents) {
      // Use stored hour/minute directly
      final eventStartWall = DateTime(
        rangeStart.year, rangeStart.month, rangeStart.day,
        event.startTime.hour, event.startTime.minute,
      );
      final eventEndWall = DateTime(
        rangeStart.year, rangeStart.month, rangeStart.day,
        event.endTime.hour, event.endTime.minute,
      );

      // Clamp event times to the filter range
      final eventStart = eventStartWall.isAfter(rangeStart)
          ? eventStartWall
          : rangeStart;
      final eventEnd = eventEndWall.isBefore(rangeEnd)
          ? eventEndWall
          : rangeEnd;

      // Free block before this event
      if (eventStart.isAfter(currentFreeStart)) {
        final freeMinutes = eventStart.difference(currentFreeStart).inMinutes;
        if (freeMinutes > longestFreeBlock) {
          longestFreeBlock = freeMinutes;
        }
      }

      // Move current position past this event (if it extends further)
      if (eventEnd.isAfter(currentFreeStart)) {
        currentFreeStart = eventEnd;
      }
    }

    // Check free block after last event
    if (rangeEnd.isAfter(currentFreeStart)) {
      final freeMinutes = rangeEnd.difference(currentFreeStart).inMinutes;
      if (freeMinutes > longestFreeBlock) {
        longestFreeBlock = freeMinutes;
      }
    }

    return longestFreeBlock;
  }

  /// Get a human-readable description of availability
  ///
  /// Returns "Free" if no conflicts, or shows the busy time range / conflict count.
  String getAvailabilityDescription({
    required List<EventModel> events,
    required DateTime date,
    required TimeFilter filter,
    TimeOfDay? customStartTime,
    TimeOfDay? customEndTime,
  }) {
    final bounds = filter.getTimeBoundaries(
      date,
      customStart: customStartTime,
      customEnd: customEndTime,
    );

    // Get overlapping events (conflicts) sorted by start time
    final conflicts = events
        .where((e) => e.category != EventCategory.holiday)
        .where((e) {
          final eventStart = DateTime(
            date.year, date.month, date.day,
            e.startTime.hour, e.startTime.minute,
          );
          final eventEnd = DateTime(
            date.year, date.month, date.day,
            e.endTime.hour, e.endTime.minute,
          );
          return eventStart.isBefore(bounds.end) && eventEnd.isAfter(bounds.start);
        })
        .toList()
      ..sort((a, b) => a.startTime.hour.compareTo(b.startTime.hour));

    // No conflicts - completely free
    if (conflicts.isEmpty) {
      return 'Free';
    }

    // Format time helper
    final timeFormat = DateFormat('h:mma');
    final hourFormat = DateFormat('ha');

    String formatTime(DateTime dt) {
      if (dt.minute == 0) {
        return hourFormat.format(dt).toLowerCase();
      }
      return timeFormat.format(dt).toLowerCase();
    }

    // Single conflict - show the busy time range
    if (conflicts.length == 1) {
      final event = conflicts.first;
      final eventStart = DateTime(
        date.year, date.month, date.day,
        event.startTime.hour, event.startTime.minute,
      );
      final eventEnd = DateTime(
        date.year, date.month, date.day,
        event.endTime.hour, event.endTime.minute,
      );

      // Clamp to filter range for display
      final displayStart = eventStart.isBefore(bounds.start) ? bounds.start : eventStart;
      final displayEnd = eventEnd.isAfter(bounds.end) ? bounds.end : eventEnd;

      return 'Busy ${formatTime(displayStart)} - ${formatTime(displayEnd)}';
    }

    // Multiple conflicts - show count
    return '${conflicts.length} conflicts';
  }

  /// Find the best days in a month based on group availability
  ///
  /// Returns a list of day numbers (1-31) sorted by availability count (highest first).
  List<int> findBestDaysInMonth({
    required Map<String, List<EventModel>> memberEvents,
    required DateTime month,
    required Set<TimeFilter> timeFilters,
    required DateTimeRange? dateRange,
    TimeOfDay? customStartTime,
    TimeOfDay? customEndTime,
  }) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final totalMembers = memberEvents.length;

    if (totalMembers == 0) {
      return [];
    }

    // Calculate availability for each day
    final dayAvailability = <int, int>{};

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);

      // Skip days outside the date range filter
      if (dateRange != null) {
        if (date.isBefore(dateRange.start) || date.isAfter(dateRange.end)) {
          continue;
        }
      }

      final available = calculateGroupAvailability(
        memberEvents: memberEvents,
        date: date,
        timeFilters: timeFilters,
        customStartTime: customStartTime,
        customEndTime: customEndTime,
      );

      // Only include days where at least someone is available
      if (available > 0) {
        dayAvailability[day] = available;
      }
    }

    // Sort by availability count (descending), then by day number (ascending)
    final sortedDays = dayAvailability.keys.toList()
      ..sort((a, b) {
        final availCompare = dayAvailability[b]!.compareTo(dayAvailability[a]!);
        if (availCompare != 0) return availCompare;
        return a.compareTo(b);
      });

    return sortedDays;
  }
}
