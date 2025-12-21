import 'package:flutter/foundation.dart';
import '../../domain/models/calendar_month.dart';
import '../../utils/calendar_utils.dart';
import '../../data/models/event_model.dart';
import '../../core/services/calendar_manager.dart';
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
  Map<String, List<EventModel>> _eventsByDate = {};

  /// Calendar manager for native calendar access
  final CalendarManager _calendarManager = CalendarManager();

  /// Loading state for events
  bool _isLoadingEvents = false;

  /// Error state for event loading
  String? _eventLoadError;

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

  /// Load events from native calendar
  /// Fetches events for a reasonable date range (30 days back, 60 days forward)
  Future<void> _loadEvents() async {
    _isLoadingEvents = true;
    _eventLoadError = null;
    notifyListeners();

    try {
      // Check permission first
      final permission = await _calendarManager.checkPermission();

      if (permission != CalendarPermissionStatus.granted) {
        Logger.info('Calendar permission not granted, skipping event load');
        _isLoadingEvents = false;
        notifyListeners();
        return;
      }

      // Fetch events for reasonable range (30 days back, 60 days forward)
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - 1, now.day);
      final endDate = DateTime(now.year, now.month + 2, now.day);

      final events = await _calendarManager.fetchEvents(
        startDate: startDate,
        endDate: endDate,
      );

      Logger.info('Loaded ${events.length} events from native calendar');

      // Index events by date
      _indexEventsByDate(events);

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
}
