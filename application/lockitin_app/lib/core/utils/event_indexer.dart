import '../../data/models/event_model.dart';
import 'timezone_utils.dart';

/// Utility class for indexing events by date
///
/// Provides consistent event grouping logic used across calendar providers.
/// Events are grouped by local date (YYYY-MM-DD) for calendar display.
class EventIndexer {
  /// Index events by date for efficient lookup
  ///
  /// Groups events by their start date (YYYY-MM-DD format in local timezone).
  /// Event times are stored as UTC DateTime objects, converted to local date keys.
  /// Events within each day are sorted by start time.
  ///
  /// Example:
  /// ```dart
  /// final events = [event1, event2, event3];
  /// final indexed = EventIndexer.groupByDate(events);
  /// final todayEvents = indexed['2026-02-01'] ?? [];
  /// ```
  ///
  /// Returns a map of date keys to event lists, with events sorted by start time.
  static Map<String, List<EventModel>> groupByDate(List<EventModel> events) {
    final Map<String, List<EventModel>> eventsByDate = {};

    // Group events by date
    for (final event in events) {
      final dateKey = TimezoneUtils.getDateKey(event.startTime);

      if (eventsByDate.containsKey(dateKey)) {
        eventsByDate[dateKey]!.add(event);
      } else {
        eventsByDate[dateKey] = [event];
      }
    }

    // Sort events within each day by start time
    for (final dateKey in eventsByDate.keys) {
      eventsByDate[dateKey]!.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    return eventsByDate;
  }

  /// Get events for a specific day from indexed map
  ///
  /// Convenience method to extract events for a date, returning empty list if none found.
  ///
  /// Example:
  /// ```dart
  /// final indexed = EventIndexer.groupByDate(events);
  /// final today = DateTime.now();
  /// final todayEvents = EventIndexer.getEventsForDay(indexed, today);
  /// ```
  static List<EventModel> getEventsForDay(
    Map<String, List<EventModel>> indexedEvents,
    DateTime day,
  ) {
    final key = TimezoneUtils.getDateKey(day);
    return indexedEvents[key] ?? [];
  }

  /// Get all events from indexed map, sorted by start time
  ///
  /// Flattens the date-indexed map into a single list of events.
  /// Useful for displaying all events in chronological order.
  ///
  /// Example:
  /// ```dart
  /// final indexed = EventIndexer.groupByDate(events);
  /// final allEvents = EventIndexer.getAllEvents(indexed);
  /// ```
  static List<EventModel> getAllEvents(
    Map<String, List<EventModel>> indexedEvents,
  ) {
    final allEvents = <EventModel>[];
    for (final events in indexedEvents.values) {
      allEvents.addAll(events);
    }
    allEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
    return allEvents;
  }

  /// Get upcoming events from indexed map (future events only)
  ///
  /// Returns events with start time after the given date, sorted by start time.
  /// Excludes events that have already started.
  ///
  /// [limit] - Optional max number of events to return
  ///
  /// Example:
  /// ```dart
  /// final indexed = EventIndexer.groupByDate(events);
  /// final upcoming = EventIndexer.getUpcomingEvents(indexed, limit: 5);
  /// ```
  static List<EventModel> getUpcomingEvents(
    Map<String, List<EventModel>> indexedEvents, {
    DateTime? fromDate,
    int? limit,
  }) {
    final cutoffDate = fromDate ?? DateTime.now();
    final allEvents = getAllEvents(indexedEvents);

    // Filter to events that haven't started yet
    final upcomingEvents =
        allEvents.where((e) => e.startTime.isAfter(cutoffDate)).toList();

    // Apply limit if provided
    if (limit != null && upcomingEvents.length > limit) {
      return upcomingEvents.sublist(0, limit);
    }

    return upcomingEvents;
  }

  /// Check if indexed map has any events for a specific date
  ///
  /// Faster than calling getEventsForDay when you only need to know if events exist.
  ///
  /// Example:
  /// ```dart
  /// final indexed = EventIndexer.groupByDate(events);
  /// if (EventIndexer.hasEventsForDay(indexed, someDate)) {
  ///   // Show event indicator dot
  /// }
  /// ```
  static bool hasEventsForDay(
    Map<String, List<EventModel>> indexedEvents,
    DateTime day,
  ) {
    final key = TimezoneUtils.getDateKey(day);
    return indexedEvents.containsKey(key) && indexedEvents[key]!.isNotEmpty;
  }
}
