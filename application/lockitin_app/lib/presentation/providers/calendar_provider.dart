import 'package:flutter/foundation.dart';
import '../../domain/models/calendar_month.dart';
import '../../utils/calendar_utils.dart';

/// Provider for calendar state management
/// Manages focused date, current page, and precomputed month data
class CalendarProvider extends ChangeNotifier {
  /// All months available in the calendar (cached for performance)
  late List<CalendarMonth> _months;

  /// Track when the month cache was created (used to detect month boundary crossings)
  late DateTime _cacheDate;

  /// Currently focused date
  DateTime _focusedDate;

  /// Current page index in the month list
  int _currentPageIndex = 0;

  /// Number of months to show backward (10 years back)
  static const int _monthsBackward = 120;

  /// Number of months to show forward (10 years forward)
  static const int _monthsForward = 120;

  /// Total months to generate (10 years back + 10 years forward = 240 months)
  static const int _monthsToShow = _monthsBackward + _monthsForward;

  CalendarProvider({DateTime? initialDate})
      : _focusedDate = initialDate ?? DateTime.now() {
    _initializeMonths();
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

  /// Get events for a specific day (placeholder for future implementation)
  List<dynamic> getEventsForDay(DateTime day) {
    // TODO: Implement event fetching from Supabase
    // This will be connected to event repository in future sprints
    return [];
  }

  /// Check if a date has events (placeholder)
  bool hasEvents(DateTime date) {
    return getEventsForDay(date).isNotEmpty;
  }
}
