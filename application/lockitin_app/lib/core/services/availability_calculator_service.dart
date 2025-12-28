import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/event_model.dart';
import '../utils/time_filter_utils.dart';

/// Service for calculating group availability based on member events
///
/// This service handles all availability logic:
/// - Determining if a member is available on a specific date
/// - Counting available members for group heatmap display
/// - Generating human-readable availability descriptions
///
/// A member is considered "busy" if they have ANY event during the
/// selected time filter. No events = available.
class AvailabilityCalculatorService {

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
      // Get events for this member that overlap with this date
      // An event overlaps if it starts before end of day AND ends after start of day
      final dayStart = DateTime(date.year, date.month, date.day, 0, 0);
      final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final eventsOnDate = entry.value
          .where((e) {
            // Convert UTC event times to local for comparison
            final localStart = e.startTime.toLocal();
            final localEnd = e.endTime.toLocal();
            // Event overlaps with this date if:
            // - Event starts before or during this day AND
            // - Event ends after or during this day
            return localStart.isBefore(dayEnd) && localEnd.isAfter(dayStart);
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
  /// Returns true if the member has NO events overlapping with the selected
  /// time filters. Any event during the time range means they're busy.
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

      // Check if any event overlaps with this time range
      final hasConflict = _hasEventInRange(events, bounds.start, bounds.end);
      return !hasConflict;
    }

    // Check each selected time filter - must be free in ALL selected filters
    for (final filter in timeFilters) {
      final bounds = filter.getTimeBoundaries(date);

      // If any event overlaps with this filter, member is not available
      if (_hasEventInRange(events, bounds.start, bounds.end)) {
        return false;
      }
    }

    return true; // Available - no events in any selected time filter
  }

  /// Check if any event overlaps with the given time range
  bool _hasEventInRange(List<EventModel> events, DateTime rangeStart, DateTime rangeEnd) {
    for (final event in events) {
      final localStart = event.startTime.toLocal();
      final localEnd = event.endTime.toLocal();

      // Create event times on the same date as the range
      final eventStart = DateTime(
        rangeStart.year, rangeStart.month, rangeStart.day,
        localStart.hour, localStart.minute,
      );
      final eventEnd = DateTime(
        rangeStart.year, rangeStart.month, rangeStart.day,
        localEnd.hour, localEnd.minute,
      );

      // Event overlaps if it starts before range ends AND ends after range starts
      if (eventStart.isBefore(rangeEnd) && eventEnd.isAfter(rangeStart)) {
        return true;
      }
    }
    return false;
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
    // Convert UTC times to local for correct hour/minute extraction
    final overlappingEvents = events
        .where((e) {
          final localStart = e.startTime.toLocal();
          final localEnd = e.endTime.toLocal();
          final eventStart = DateTime(
            rangeStart.year, rangeStart.month, rangeStart.day,
            localStart.hour, localStart.minute,
          );
          final eventEnd = DateTime(
            rangeStart.year, rangeStart.month, rangeStart.day,
            localEnd.hour, localEnd.minute,
          );
          return eventStart.isBefore(rangeEnd) && eventEnd.isAfter(rangeStart);
        })
        .toList()
      ..sort((a, b) => a.startTime.toLocal().hour.compareTo(b.startTime.toLocal().hour));

    if (overlappingEvents.isEmpty) {
      // No events - entire range is free
      return rangeEnd.difference(rangeStart).inMinutes;
    }

    var longestFreeBlock = 0;
    var currentFreeStart = rangeStart;

    for (final event in overlappingEvents) {
      // Convert UTC to local for correct hour/minute
      final localStart = event.startTime.toLocal();
      final localEnd = event.endTime.toLocal();
      final eventStartWall = DateTime(
        rangeStart.year, rangeStart.month, rangeStart.day,
        localStart.hour, localStart.minute,
      );
      final eventEndWall = DateTime(
        rangeStart.year, rangeStart.month, rangeStart.day,
        localEnd.hour, localEnd.minute,
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
    // Convert UTC times to local for correct hour/minute
    final conflicts = events
        .where((e) => e.category != EventCategory.holiday)
        .where((e) {
          final localStart = e.startTime.toLocal();
          final localEnd = e.endTime.toLocal();
          final eventStart = DateTime(
            date.year, date.month, date.day,
            localStart.hour, localStart.minute,
          );
          final eventEnd = DateTime(
            date.year, date.month, date.day,
            localEnd.hour, localEnd.minute,
          );
          return eventStart.isBefore(bounds.end) && eventEnd.isAfter(bounds.start);
        })
        .toList()
      ..sort((a, b) => a.startTime.toLocal().hour.compareTo(b.startTime.toLocal().hour));

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
      final localStart = event.startTime.toLocal();
      final localEnd = event.endTime.toLocal();
      final eventStart = DateTime(
        date.year, date.month, date.day,
        localStart.hour, localStart.minute,
      );
      final eventEnd = DateTime(
        date.year, date.month, date.day,
        localEnd.hour, localEnd.minute,
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
