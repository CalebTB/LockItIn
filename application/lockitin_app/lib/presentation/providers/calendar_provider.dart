import 'package:flutter/material.dart';
import '../../domain/models/calendar_month.dart';
import '../../utils/calendar_utils.dart';
import '../../data/models/event_model.dart';
import '../../data/models/event_template_model.dart';
import '../../core/services/calendar_manager.dart';
import '../../core/services/event_service.dart';
import '../../core/services/test_events_service.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/timezone_utils.dart';
import '../../core/network/supabase_client.dart';

/// Provider for calendar state management
/// Manages focused date, current page, precomputed month data, and events
/// Implements WidgetsBindingObserver to detect timezone changes
class CalendarProvider extends ChangeNotifier with WidgetsBindingObserver {
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

  /// Timezone offset (in hours) when events were last loaded
  /// Used to detect timezone changes and refresh events
  int? _lastTimezoneOffsetHours;

  /// Number of months to show backward (10 years back)
  static const int _monthsBackward = 120;

  /// Number of months to show forward (10 years forward)
  static const int _monthsForward = 120;

  /// Total months to generate (10 years back + 10 years forward = 240 months)
  static const int _monthsToShow = _monthsBackward + _monthsForward;

  CalendarProvider({DateTime? initialDate})
      : _focusedDate = initialDate ?? TimezoneUtils.nowUtc() {
    _initializeMonths();
    _loadEvents();

    // Register as lifecycle observer to detect timezone changes
    WidgetsBinding.instance.addObserver(this);

    // Store initial timezone offset
    _lastTimezoneOffsetHours = DateTime.now().timeZoneOffset.inHours;
    Logger.info('CalendarProvider', 'Initial timezone offset: $_lastTimezoneOffsetHours hours');
  }

  // Getters
  List<CalendarMonth> get months {
    // Check if we've crossed into a new month since cache was created
    final today = TimezoneUtils.nowUtc();
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
    final today = TimezoneUtils.nowUtc();
    final currentMonth = DateTime(today.year, today.month, 1);

    // Find the index of today's month in the current months list
    final index = months.indexWhere((m) => CalendarUtils.isSameMonth(m.month, currentMonth));

    // Fallback to backward offset if not found (should never happen in normal operation)
    return index >= 0 ? index : _monthsBackward;
  }

  /// Initialize all months (precompute for O(1) lookups)
  /// Generates 240 months: 10 years backward + 10 years forward from today
  void _initializeMonths() {
    final today = TimezoneUtils.nowUtc();
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

  /// Reset all state (call on logout to prevent data leaks between accounts)
  void reset() {
    _eventsByDate.clear();
    _eventIndicatorsCache.clear();
    _upcomingEventsCache = null;
    _upcomingEventsCacheTime = null;
    _eventLoadError = null;
    _isLoadingEvents = false;
    _focusedDate = TimezoneUtils.nowUtc();
    _initializeMonths();
    notifyListeners();
    Logger.info('CalendarProvider', 'State reset for logout');
  }

  /// Navigate to today's month
  void goToToday() {
    _focusedDate = TimezoneUtils.nowUtc();
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
      final now = TimezoneUtils.nowUtc();
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
        Logger.info('CalendarProvider', 'Loaded ${testEvents.length} test events');
      }

      // Fetch events from Supabase (user-specific, RLS-protected)
      final supabaseEvents = await _eventService.fetchEventsFromSupabase(
        startDate: startDate,
        endDate: endDate,
      );
      allEvents.addAll(supabaseEvents);
      Logger.info('CalendarProvider', 'Loaded ${supabaseEvents.length} events from Supabase');

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
        Logger.info('CalendarProvider',
          'Loaded ${newNativeEvents.length} new events from native calendar '
          '(${nativeEvents.length - newNativeEvents.length} duplicates filtered)',
        );
      } else {
        Logger.info('CalendarProvider', 'Calendar permission not granted, showing Supabase events only');
      }

      // Index all events (Supabase + native calendar events) by date
      _indexEventsByDate(allEvents);

      _isLoadingEvents = false;
      notifyListeners();
    } catch (e) {
      Logger.error('CalendarProvider', 'Failed to load events: $e');
      _eventLoadError = e.toString();
      _isLoadingEvents = false;
      notifyListeners();
    }
  }

  /// Index events by date for efficient lookup
  /// Groups events by their start date (YYYY-MM-DD format)
  /// Event times are stored as UTC DateTime objects, converted to local date keys
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
  /// Converts to local timezone before extracting date components
  /// to ensure events are grouped by local date, not UTC date
  String _dateKey(DateTime date) {
    final localDate = date.toLocal();
    return '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';
  }

  /// Get events for a specific day
  List<EventModel> getEventsForDay(DateTime day) {
    final key = _dateKey(day);
    return _eventsByDate[key] ?? [];
  }

  /// Get all events from all days, sorted by start time
  List<EventModel> getAllEvents() {
    final allEvents = <EventModel>[];
    for (final events in _eventsByDate.values) {
      allEvents.addAll(events);
    }
    allEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
    return allEvents;
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
  /// Applies decoy titles if the current user is the guest of honor
  void addEvent(EventModel event) {
    // Apply decoy title if current user is guest of honor
    final processedEvent = _applyDecoyTitle(event);

    final dateKey = _dateKey(processedEvent.startTime);

    if (_eventsByDate.containsKey(dateKey)) {
      _eventsByDate[dateKey]!.add(processedEvent);
      // Sort events by start time
      _eventsByDate[dateKey]!.sort((a, b) => a.startTime.compareTo(b.startTime));
    } else {
      _eventsByDate[dateKey] = [processedEvent];
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
    final now = TimezoneUtils.nowUtc();
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

  // ============================================================================
  // Surprise Party Template Methods
  // ============================================================================

  /// Toggle the completion status of a surprise party task
  Future<void> toggleSurprisePartyTask(String eventId, String taskId) async {
    try {
      // Find the event
      final event = _findEventById(eventId);
      if (event == null) {
        Logger.error('CalendarProvider', 'Event not found: $eventId');
        return;
      }

      // Check if event has surprise party template
      if (event.surprisePartyTemplate == null) {
        Logger.error('CalendarProvider', 'Event $eventId has no surprise party template');
        return;
      }

      // Toggle the task
      final updatedTemplate = event.surprisePartyTemplate!.toggleTask(taskId);

      // Create updated event with new template
      final updatedEvent = event.copyWith(
        templateData: updatedTemplate,
      );

      // Update Supabase
      await _eventService.updateEvent(updatedEvent);

      // Update local state
      updateEvent(event, updatedEvent);

      Logger.info('CalendarProvider', 'Toggled task $taskId for event $eventId');
    } catch (e) {
      Logger.error('CalendarProvider', 'Failed to toggle task: $e');
      rethrow;
    }
  }

  /// Assign a surprise party task to a user
  Future<void> assignSurprisePartyTask(
    String eventId,
    String taskId,
    String? userId,
  ) async {
    try {
      // Find the event
      final event = _findEventById(eventId);
      if (event == null) {
        Logger.error('CalendarProvider', 'Event not found: $eventId');
        return;
      }

      // Check if event has surprise party template
      if (event.surprisePartyTemplate == null) {
        Logger.error('CalendarProvider', 'Event $eventId has no surprise party template');
        return;
      }

      // Find and update the task
      final tasks = event.surprisePartyTemplate!.tasks.map((task) {
        if (task.id == taskId) {
          return task.copyWith(assignedTo: userId);
        }
        return task;
      }).toList();

      // Create updated template
      final updatedTemplate = SurprisePartyTemplateModel(
        guestOfHonorId: event.surprisePartyTemplate!.guestOfHonorId,
        decoyTitle: event.surprisePartyTemplate!.decoyTitle,
        revealAt: event.surprisePartyTemplate!.revealAt,
        tasks: tasks,
        inOnItUserIds: event.surprisePartyTemplate!.inOnItUserIds,
      );

      // Create updated event with new template
      final updatedEvent = event.copyWith(
        templateData: updatedTemplate,
      );

      // Update Supabase
      await _eventService.updateEvent(updatedEvent);

      // Update local state
      updateEvent(event, updatedEvent);

      Logger.info('CalendarProvider',
          'Assigned task $taskId to ${userId ?? "no one"} for event $eventId');
    } catch (e) {
      Logger.error('CalendarProvider', 'Failed to assign task: $e');
      rethrow;
    }
  }

  /// Delete a surprise party task
  Future<void> deleteSurprisePartyTask(String eventId, String taskId) async {
    try {
      // Find the event
      final event = _findEventById(eventId);
      if (event == null) {
        Logger.error('CalendarProvider', 'Event not found: $eventId');
        return;
      }

      // Check if event has surprise party template
      if (event.surprisePartyTemplate == null) {
        Logger.error('CalendarProvider', 'Event $eventId has no surprise party template');
        return;
      }

      // Remove the task
      final updatedTemplate = event.surprisePartyTemplate!.removeTask(taskId);

      // Create updated event with new template
      final updatedEvent = event.copyWith(
        templateData: updatedTemplate,
      );

      // Update Supabase
      await _eventService.updateEvent(updatedEvent);

      // Update local state
      updateEvent(event, updatedEvent);

      Logger.info('CalendarProvider', 'Deleted task $taskId from event $eventId');
    } catch (e) {
      Logger.error('CalendarProvider', 'Failed to delete task: $e');
      rethrow;
    }
  }

  /// Helper method to find an event by ID across all dates
  EventModel? _findEventById(String eventId) {
    for (final events in _eventsByDate.values) {
      for (final event in events) {
        if (event.id == eventId) {
          return event;
        }
      }
    }
    return null;
  }

  // ============================================================================
  // Lifecycle Observer
  // ============================================================================

  /// Lifecycle observer: Detect when app resumes to check for timezone changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndRefreshOnTimezoneChange();
    }
  }

  /// Check if timezone changed and refresh events if needed
  void _checkAndRefreshOnTimezoneChange() {
    final currentOffsetHours = DateTime.now().timeZoneOffset.inHours;

    if (_lastTimezoneOffsetHours != null && _lastTimezoneOffsetHours != currentOffsetHours) {
      Logger.info(
        'CalendarProvider',
        'Timezone changed from $_lastTimezoneOffsetHours to $currentOffsetHours hours - refreshing events',
      );

      // Update stored offset
      _lastTimezoneOffsetHours = currentOffsetHours;

      // Reload events to refresh with new timezone
      _loadEvents();

      // Force UI update
      notifyListeners();
    }
  }

  /// Apply decoy title to surprise party event if current user is guest of honor
  EventModel _applyDecoyTitle(EventModel event) {
    // Check if this is a surprise party with the current user as guest of honor
    if (event.isSurpriseParty) {
      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) return event;

      final surpriseTemplate = event.surprisePartyTemplate;
      if (surpriseTemplate?.guestOfHonorId == currentUserId) {
        // Replace title with decoy title
        final decoyTitle = surpriseTemplate!.decoyTitle ?? 'Event';
        Logger.info('CalendarProvider', 'Applying decoy title "$decoyTitle" for guest of honor (immediate add)');
        return event.copyWith(title: decoyTitle);
      }
    }
    return event;
  }

  // ==================== Potluck Template Methods ====================

  /// Add a dish to a potluck event
  Future<void> addPotluckDish({
    required String eventId,
    required String category,
    required String dishName,
    String? userId,
    String? description,
    String? servingSize,
    List<String>? dietaryInfo,
  }) async {
    try {
      // Find the event
      final event = _findEventById(eventId);
      if (event == null) {
        Logger.error('CalendarProvider', 'Event not found: $eventId');
        throw Exception('Event not found');
      }

      // Check if event has potluck template
      if (event.potluckTemplate == null) {
        Logger.error('CalendarProvider', 'Event $eventId has no potluck template');
        throw Exception('Event has no potluck template');
      }

      // Add the dish
      final updatedTemplate = event.potluckTemplate!.addDish(
        category: category,
        dishName: dishName,
        userId: userId,
        description: description,
        servingSize: servingSize,
        dietaryInfo: dietaryInfo,
      );

      // Create updated event with new template
      final updatedEvent = event.copyWith(
        templateData: updatedTemplate,
      );

      // Update Supabase
      await _eventService.updateEvent(updatedEvent);

      // Update local state
      updateEvent(event, updatedEvent);

      Logger.info('CalendarProvider', 'Added dish "$dishName" to event $eventId');
    } catch (e) {
      Logger.error('CalendarProvider', 'Failed to add dish: $e');
      rethrow;
    }
  }

  /// Claim or unclaim a potluck dish
  Future<void> togglePotluckDishClaim(String eventId, String dishId) async {
    try {
      // Find the event
      final event = _findEventById(eventId);
      if (event == null) {
        Logger.error('CalendarProvider', 'Event not found: $eventId');
        throw Exception('Event not found');
      }

      // Check if event has potluck template
      if (event.potluckTemplate == null) {
        Logger.error('CalendarProvider', 'Event $eventId has no potluck template');
        throw Exception('Event has no potluck template');
      }

      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Find the dish
      final dish = event.potluckTemplate!.dishes.firstWhere(
        (d) => d.id == dishId,
        orElse: () => throw Exception('Dish not found'),
      );

      // Toggle claim
      final updatedTemplate = dish.isClaimed
          ? event.potluckTemplate!.unclaimDish(dishId)
          : event.potluckTemplate!.claimDish(dishId, currentUserId);

      // Create updated event with new template
      final updatedEvent = event.copyWith(
        templateData: updatedTemplate,
      );

      // Update Supabase
      await _eventService.updateEvent(updatedEvent);

      // Update local state
      updateEvent(event, updatedEvent);

      Logger.info(
        'CalendarProvider',
        '${dish.isClaimed ? "Unclaimed" : "Claimed"} dish $dishId for event $eventId',
      );
    } catch (e) {
      Logger.error('CalendarProvider', 'Failed to toggle dish claim: $e');
      rethrow;
    }
  }

  /// Remove a potluck dish
  Future<void> deletePotluckDish(String eventId, String dishId) async {
    try {
      // Find the event
      final event = _findEventById(eventId);
      if (event == null) {
        Logger.error('CalendarProvider', 'Event not found: $eventId');
        throw Exception('Event not found');
      }

      // Check if event has potluck template
      if (event.potluckTemplate == null) {
        Logger.error('CalendarProvider', 'Event $eventId has no potluck template');
        throw Exception('Event has no potluck template');
      }

      // Remove the dish
      final updatedTemplate = event.potluckTemplate!.removeDish(dishId);

      // Create updated event with new template
      final updatedEvent = event.copyWith(
        templateData: updatedTemplate,
      );

      // Update Supabase
      await _eventService.updateEvent(updatedEvent);

      // Update local state
      updateEvent(event, updatedEvent);

      Logger.info('CalendarProvider', 'Deleted dish $dishId from event $eventId');
    } catch (e) {
      Logger.error('CalendarProvider', 'Failed to delete dish: $e');
      rethrow;
    }
  }

  /// Clean up observer when provider is disposed
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
