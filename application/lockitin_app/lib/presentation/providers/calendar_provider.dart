import 'package:flutter/material.dart';
import '../../domain/models/calendar_month.dart';
import '../../utils/calendar_utils.dart';
import '../../data/models/event_model.dart';
import '../../core/services/calendar_manager.dart';
import '../../core/services/event_service.dart';
import '../../core/services/test_events_service.dart';
import '../../core/utils/logger.dart';

/// Provider for calendar state management
/// Manages focused date, current page, precomputed month data, and events
class CalendarProvider extends ChangeNotifier {
  /// All months available in the calendar (cached for performance)
  late List<CalendarMonth> _months;

  /// Track when the month cache was created (used to detect month boundary crossings)
  late DateTime _cacheDate;

  /// Currently focused date
  DateTime _focusedDate;

  /// Current page index in the month list
  int _currentPageIndex = 0;

  /// All events indexed by date (YYYY-MM-DD format)
  final Map<String, List<EventModel>> _eventsByDate = {};

  /// Calendar manager for native calendar access
  final CalendarManager _calendarManager = CalendarManager();

  /// Event service for Supabase sync
  final EventService _eventService = EventService();

  /// Loading state for events
  bool _isLoadingEvents = false;

  /// Error state for event loading
  String? _eventLoadError;

  /// Cached event indicators by month key (YYYY-MM format)
  final Map<String, Map<int, List<Color>>> _eventIndicatorsCache = {};

  /// Cached upcoming events list
  List<EventModel>? _upcomingEventsCache;

  /// Timestamp of when upcoming events cache was last computed
  DateTime? _upcomingEventsCacheTime;

  /// Number of months to show backward (10 years back)
  static const int _monthsBackward = 120;

  /// Number of months to show forward (10 years forward)
  static const int _monthsForward = 120;

  /// Total months to generate (10 years back + 10 years forward = 240 months)
  static const int _monthsToShow = _monthsBackward + _monthsForward;

  CalendarProvider({DateTime? initialDate})
      : _focusedDate = initialDate ?? DateTime.now() {
    _initializeMonths();
    _loadEvents();
  }

  // Getters
  List<CalendarMonth> get months {
    // Check if we've crossed into a new month since cache was created
    final today = DateTime.now();
    final currentMonth = DateTime(today.year, today.month, 1);

    if (!CalendarUtils.isSameMonth(_cacheDate, currentMonth)) {
      // Month has changed - refresh cache
      _initializeMonths();
    }

    return _months;
  }

  DateTime get focusedDate => _focusedDate;
  int get currentPageIndex => _currentPageIndex;
  DateTime get currentMonth => _months[_currentPageIndex].month;
  bool get isLoadingEvents => _isLoadingEvents;
  String? get eventLoadError => _eventLoadError;

  /// Get the index of today's month in the months list (dynamically calculated)
  /// This ensures the "Today" button always navigates to the correct month
  int get todayMonthIndex {
    final today = DateTime.now();
    final currentMonth = DateTime(today.year, today.month, 1);

    // Find the index of today's month in the current months list
    final index = months.indexWhere((m) => CalendarUtils.isSameMonth(m.month, currentMonth));

    // Fallback to backward offset if not found (should never happen in normal operation)
    return index >= 0 ? index : _monthsBackward;
  }

  /// Initialize all months (precompute for O(1) lookups)
  /// Generates 240 months: 10 years backward + 10 years forward from today
  void _initializeMonths() {
    final today = DateTime.now();
    final currentMonth = DateTime(today.year, today.month, 1);

    // Store the month for which this cache is valid
    _cacheDate = currentMonth;

    // Start 10 years (120 months) before current month
    final startMonth = DateTime(currentMonth.year, currentMonth.month - _monthsBackward, 1);

    final monthsList = CalendarUtils.generateMonthRange(startMonth, _monthsToShow);

    _months = monthsList.map((month) => CalendarMonth.fromMonth(month)).toList();

    // Set initial page to current month (dynamically calculated)
    _currentPageIndex = todayMonthIndex;
  }

  /// Navigate to today's month
  void goToToday() {
    _focusedDate = DateTime.now();
    _currentPageIndex = todayMonthIndex; // Use dynamic index calculation
    notifyListeners();
  }

  /// Handle page change in calendar
  void onPageChanged(int index) {
    if (index >= 0 && index < _months.length) {
      _currentPageIndex = index;
      _focusedDate = _months[index].month;
      notifyListeners();
    }
  }

  /// Select a specific date
  void selectDate(DateTime date) {
    _focusedDate = date;

    // Find the month containing this date and update page index
    for (int i = 0; i < _months.length; i++) {
      if (CalendarUtils.isSameMonth(date, _months[i].month)) {
        _currentPageIndex = i;
        break;
      }
    }

    notifyListeners();
  }

  /// Load events from native calendar and holidays
  /// Fetches events for a reasonable date range (30 days back, 60 days forward)
  /// Also loads national holidays from JSON asset
  Future<void> _loadEvents() async {
    _isLoadingEvents = true;
    _eventLoadError = null;
    // Don't notify here - reduces unnecessary rebuilds

    try {
      final List<EventModel> allEvents = [];

      // Load national holidays first (always available, no permission needed)
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - 1, now.day);
      final endDate = DateTime(now.year, now.month + 2, now.day);

      // DISABLED: Holidays disabled since we now sync from iOS Calendar
      // final holidays = await HolidayService.getHolidaysInRange(startDate, endDate);
      // allEvents.addAll(holidays);
      // Logger.info('Loaded ${holidays.length} holidays');

      // Load test events for development (if enabled)
      if (TestEventsService.enableTestEvents) {
        final testEvents = TestEventsService.generateTestEvents();
        allEvents.addAll(testEvents);
        Logger.info('Loaded ${testEvents.length} test events');
      }

      // Fetch events from Supabase (user-specific, RLS-protected)
      final supabaseEvents = await _eventService.fetchEventsFromSupabase(
        startDate: startDate,
        endDate: endDate,
      );
      allEvents.addAll(supabaseEvents);
      Logger.info('Loaded ${supabaseEvents.length} events from Supabase');

      // Track native calendar IDs from Supabase to avoid duplicates
      final nativeCalendarIds = supabaseEvents
          .where((e) => e.nativeCalendarId != null)
          .map((e) => e.nativeCalendarId!)
          .toSet();

      // Check permission for native calendar events
      final permission = await _calendarManager.checkPermission();

      if (permission == CalendarPermissionStatus.granted) {
        // Fetch events from native calendar
        final nativeEvents = await _calendarManager.fetchEvents(
          startDate: startDate,
          endDate: endDate,
        );

        // Filter out events that are already in Supabase (avoid duplicates)
        final newNativeEvents = nativeEvents.where((event) {
          return event.nativeCalendarId == null ||
              !nativeCalendarIds.contains(event.nativeCalendarId);
        }).toList();

        allEvents.addAll(newNativeEvents);
        Logger.info(
          'Loaded ${newNativeEvents.length} new events from native calendar '
          '(${nativeEvents.length - newNativeEvents.length} duplicates filtered)',
        );
      } else {
        Logger.info('Calendar permission not granted, showing Supabase events only');
      }

      // Index all events (Supabase + native calendar events) by date
      _indexEventsByDate(allEvents);

      _isLoadingEvents = false;
      notifyListeners();
    } catch (e) {
      Logger.error('Failed to load events: $e');
      _eventLoadError = e.toString();
      _isLoadingEvents = false;
      notifyListeners();
    }
  }

  /// Index events by date for efficient lookup
  /// Groups events by their start date (YYYY-MM-DD format)
  /// Event times are already in local timezone (converted in EventModel.fromJson)
  void _indexEventsByDate(List<EventModel> events) {
    _eventsByDate.clear();

    for (final event in events) {
      final dateKey = _dateKey(event.startTime);

      if (_eventsByDate.containsKey(dateKey)) {
        _eventsByDate[dateKey]!.add(event);
      } else {
        _eventsByDate[dateKey] = [event];
      }
    }

    // Sort events within each day by start time
    for (final dateKey in _eventsByDate.keys) {
      _eventsByDate[dateKey]!.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    // Invalidate computed caches since event data changed
    _invalidateEventCaches();
  }

  /// Generate date key for event indexing (YYYY-MM-DD)
  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get events for a specific day
  List<EventModel> getEventsForDay(DateTime day) {
    final key = _dateKey(day);
    return _eventsByDate[key] ?? [];
  }

  /// Check if a date has events
  bool hasEvents(DateTime date) {
    final key = _dateKey(date);
    return _eventsByDate.containsKey(key) && _eventsByDate[key]!.isNotEmpty;
  }

  /// Refresh events (e.g., after permission granted or manual refresh)
  Future<void> refreshEvents() async {
    await _loadEvents();
  }

  /// Add a new event to the calendar
  /// Event times are already in local timezone (converted in EventModel.fromJson)
  void addEvent(EventModel event) {
    final dateKey = _dateKey(event.startTime);

    if (_eventsByDate.containsKey(dateKey)) {
      _eventsByDate[dateKey]!.add(event);
      // Sort events by start time
      _eventsByDate[dateKey]!.sort((a, b) => a.startTime.compareTo(b.startTime));
    } else {
      _eventsByDate[dateKey] = [event];
    }

    _invalidateEventCaches();
    notifyListeners();
  }

  /// Remove an event from the calendar
  void removeEvent(String eventId, DateTime eventDate) {
    final dateKey = _dateKey(eventDate);

    if (_eventsByDate.containsKey(dateKey)) {
      _eventsByDate[dateKey]!.removeWhere((event) => event.id == eventId);
      if (_eventsByDate[dateKey]!.isEmpty) {
        _eventsByDate.remove(dateKey);
      }
    }

    _invalidateEventCaches();
    notifyListeners();
  }

  /// Update an existing event in the calendar
  /// Handles date changes by moving the event between date keys
  void updateEvent(EventModel oldEvent, EventModel updatedEvent) {
    final oldDateKey = _dateKey(oldEvent.startTime);
    final newDateKey = _dateKey(updatedEvent.startTime);

    // Remove from old date
    if (_eventsByDate.containsKey(oldDateKey)) {
      _eventsByDate[oldDateKey]!.removeWhere((event) => event.id == oldEvent.id);
      if (_eventsByDate[oldDateKey]!.isEmpty) {
        _eventsByDate.remove(oldDateKey);
      }
    }

    // Add to new date
    if (_eventsByDate.containsKey(newDateKey)) {
      _eventsByDate[newDateKey]!.add(updatedEvent);
      // Sort events by start time
      _eventsByDate[newDateKey]!.sort((a, b) => a.startTime.compareTo(b.startTime));
    } else {
      _eventsByDate[newDateKey] = [updatedEvent];
    }

    _invalidateEventCaches();
    notifyListeners();
  }

  // ============================================================================
  // Cached Computations (Performance Optimization)
  // ============================================================================

  /// Get event indicators for a specific month (cached)
  /// Returns Map<dayOfMonth, List<Color>> for dots on mini calendar
  Map<int, List<Color>> getEventIndicatorsForMonth(DateTime month) {
    final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';

    // Return cached value if available
    if (_eventIndicatorsCache.containsKey(monthKey)) {
      return _eventIndicatorsCache[monthKey]!;
    }

    // Compute indicators for this month
    final indicators = <int, List<Color>>{};
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final events = getEventsForDay(date);
      if (events.isNotEmpty) {
        indicators[day] = events
            .map((e) => CalendarUtils.getCategoryColor(e.category))
            .take(3)
            .toList();
      }
    }

    // Cache the result
    _eventIndicatorsCache[monthKey] = indicators;
    return indicators;
  }

  /// Get upcoming events for the next 14 days (cached)
  /// Returns top 5 events sorted by start time
  List<EventModel> getUpcomingEvents() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if cache is still valid (same day)
    if (_upcomingEventsCache != null && _upcomingEventsCacheTime != null) {
      final cacheDay = DateTime(
        _upcomingEventsCacheTime!.year,
        _upcomingEventsCacheTime!.month,
        _upcomingEventsCacheTime!.day,
      );
      if (cacheDay == today) {
        return _upcomingEventsCache!;
      }
    }

    // Compute upcoming events
    final upcoming = <EventModel>[];

    for (int i = 0; i < 14; i++) {
      final date = DateTime(now.year, now.month, now.day + i);
      final events = getEventsForDay(date);
      upcoming.addAll(events);
    }

    // Sort by start time and take top 5
    upcoming.sort((a, b) => a.startTime.compareTo(b.startTime));
    final result = upcoming.take(5).toList();

    // Cache the result
    _upcomingEventsCache = result;
    _upcomingEventsCacheTime = now;

    return result;
  }

  /// Invalidate all event caches (called when events change)
  void _invalidateEventCaches() {
    _eventIndicatorsCache.clear();
    _upcomingEventsCache = null;
    _upcomingEventsCacheTime = null;
  }
}
