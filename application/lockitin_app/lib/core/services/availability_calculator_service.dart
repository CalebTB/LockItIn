import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/event_model.dart';
import '../utils/time_filter_utils.dart';

/// Represents availability for a specific time slot
class TimeSlotAvailability {
  final DateTime startTime;
  final DateTime endTime;
  final int availableCount;
  final int totalMembers;
  final List<String> availableMembers;
  final List<String> busyMembers;

  const TimeSlotAvailability({
    required this.startTime,
    required this.endTime,
    required this.availableCount,
    required this.totalMembers,
    required this.availableMembers,
    required this.busyMembers,
  });

  /// Percentage of members available (0.0 to 1.0)
  double get availabilityRatio =>
      totalMembers > 0 ? availableCount / totalMembers : 0.0;

  /// Whether everyone is available
  bool get isFullyAvailable => availableCount == totalMembers;

  /// Whether no one is available
  bool get isEmpty => availableCount == 0;

  /// Duration of this time slot
  Duration get duration => endTime.difference(startTime);

  /// Formatted time range string (e.g., "2pm - 4pm")
  String get formattedTimeRange {
    final startFormat = DateFormat('ha');
    final endFormat = DateFormat('ha');
    return '${startFormat.format(startTime).toLowerCase()} - ${endFormat.format(endTime).toLowerCase()}';
  }

  /// Availability description (e.g., "7/8 available")
  String get availabilityDescription => '$availableCount/$totalMembers available';

  @override
  String toString() => 'TimeSlotAvailability($formattedTimeRange: $availabilityDescription)';
}

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

      // First check if the event actually occurs on/overlaps with this date
      // An event overlaps with the date if it starts before range end AND ends after range start
      // This handles multi-day events and events on different days
      if (localStart.isBefore(rangeEnd) && localEnd.isAfter(rangeStart)) {
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
    // Use actual event times (not reconstructed) to handle multi-day events correctly
    final conflicts = events
        .where((e) => e.category != EventCategory.holiday)
        .where((e) {
          final localStart = e.startTime.toLocal();
          final localEnd = e.endTime.toLocal();
          // Event overlaps if it starts before bounds end AND ends after bounds start
          return localStart.isBefore(bounds.end) && localEnd.isAfter(bounds.start);
        })
        .toList()
      ..sort((a, b) => a.startTime.toLocal().compareTo(b.startTime.toLocal()));

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

      // Clamp to filter range for display (use actual times, not reconstructed)
      final displayStart = localStart.isBefore(bounds.start) ? bounds.start : localStart;
      final displayEnd = localEnd.isAfter(bounds.end) ? bounds.end : localEnd;

      return 'Busy ${formatTime(displayStart)} - ${formatTime(displayEnd)}';
    }

    // Multiple conflicts - show count
    return '${conflicts.length} conflicts';
  }

  /// Find the best time slots on a specific date when most members are free
  ///
  /// Returns a list of TimeSlotAvailability objects sorted by:
  /// 1. Available count (highest first)
  /// 2. Start time (earliest first for same availability)
  ///
  /// [memberEvents] - Map of userId to their events
  /// [date] - The date to analyze
  /// [startHour] - Start hour of the range to analyze (0-23)
  /// [endHour] - End hour of the range to analyze (1-24)
  /// [slotDurationMinutes] - Duration of each slot (default 60 minutes)
  List<TimeSlotAvailability> findBestTimeSlots({
    required Map<String, List<EventModel>> memberEvents,
    required DateTime date,
    int startHour = 8,
    int endHour = 22,
    int slotDurationMinutes = 60,
  }) {
    if (memberEvents.isEmpty) {
      return [];
    }

    final slots = <TimeSlotAvailability>[];
    final totalMembers = memberEvents.length;

    // Generate time slots
    var currentTime = DateTime(date.year, date.month, date.day, startHour);
    final endTime = DateTime(date.year, date.month, date.day, endHour);

    while (currentTime.isBefore(endTime)) {
      final slotEnd = currentTime.add(Duration(minutes: slotDurationMinutes));
      if (slotEnd.isAfter(endTime)) break;

      // Count available members for this slot
      int availableCount = 0;
      final availableMembers = <String>[];
      final busyMembers = <String>[];

      for (final entry in memberEvents.entries) {
        final userId = entry.key;
        final events = entry.value;

        // Check if this member has any event during this slot
        final hasBusyBlock = _hasEventInRange(events, currentTime, slotEnd);

        if (!hasBusyBlock) {
          availableCount++;
          availableMembers.add(userId);
        } else {
          busyMembers.add(userId);
        }
      }

      slots.add(TimeSlotAvailability(
        startTime: currentTime,
        endTime: slotEnd,
        availableCount: availableCount,
        totalMembers: totalMembers,
        availableMembers: availableMembers,
        busyMembers: busyMembers,
      ));

      currentTime = slotEnd;
    }

    // Sort by availability (highest first), then by start time (earliest first)
    slots.sort((a, b) {
      final availCompare = b.availableCount.compareTo(a.availableCount);
      if (availCompare != 0) return availCompare;
      return a.startTime.compareTo(b.startTime);
    });

    return slots;
  }

  /// Get hour-by-hour availability breakdown for a specific date
  ///
  /// Returns a map of hour (0-23) to availability count.
  /// Useful for displaying hourly heatmaps.
  Map<int, int> getHourlyAvailability({
    required Map<String, List<EventModel>> memberEvents,
    required DateTime date,
    int startHour = 0,
    int endHour = 24,
  }) {
    final hourlyAvailability = <int, int>{};

    for (int hour = startHour; hour < endHour; hour++) {
      final slotStart = DateTime(date.year, date.month, date.day, hour);
      final slotEnd = DateTime(date.year, date.month, date.day, hour + 1);

      int availableCount = 0;
      for (final events in memberEvents.values) {
        if (!_hasEventInRange(events, slotStart, slotEnd)) {
          availableCount++;
        }
      }

      hourlyAvailability[hour] = availableCount;
    }

    return hourlyAvailability;
  }

  /// Find contiguous time blocks where a minimum number of members are available
  ///
  /// Returns merged time blocks where availability meets the threshold.
  /// Useful for finding "windows" of availability.
  List<TimeSlotAvailability> findAvailableWindows({
    required Map<String, List<EventModel>> memberEvents,
    required DateTime date,
    required int minimumAvailable,
    int startHour = 8,
    int endHour = 22,
  }) {
    if (memberEvents.isEmpty) {
      return [];
    }

    final totalMembers = memberEvents.length;
    final windows = <TimeSlotAvailability>[];

    // Get hourly availability first
    final hourlySlots = findBestTimeSlots(
      memberEvents: memberEvents,
      date: date,
      startHour: startHour,
      endHour: endHour,
      slotDurationMinutes: 60,
    );

    // Sort by time for merging
    hourlySlots.sort((a, b) => a.startTime.compareTo(b.startTime));

    // Merge contiguous slots that meet the threshold
    TimeSlotAvailability? currentWindow;

    for (final slot in hourlySlots) {
      if (slot.availableCount >= minimumAvailable) {
        if (currentWindow == null) {
          // Start a new window
          currentWindow = slot;
        } else if (slot.startTime == currentWindow.endTime) {
          // Extend the current window
          currentWindow = TimeSlotAvailability(
            startTime: currentWindow.startTime,
            endTime: slot.endTime,
            availableCount: (currentWindow.availableCount + slot.availableCount) ~/ 2,
            totalMembers: totalMembers,
            availableMembers: currentWindow.availableMembers
                .toSet()
                .intersection(slot.availableMembers.toSet())
                .toList(),
            busyMembers: currentWindow.busyMembers
                .toSet()
                .union(slot.busyMembers.toSet())
                .toList(),
          );
        } else {
          // Gap found - save current window and start new
          windows.add(currentWindow);
          currentWindow = slot;
        }
      } else {
        // Below threshold - save current window if exists
        if (currentWindow != null) {
          windows.add(currentWindow);
          currentWindow = null;
        }
      }
    }

    // Don't forget the last window
    if (currentWindow != null) {
      windows.add(currentWindow);
    }

    return windows;
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
