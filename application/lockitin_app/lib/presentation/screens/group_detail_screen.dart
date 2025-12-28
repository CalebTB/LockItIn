import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/group_model.dart';
import '../../data/models/event_model.dart';
import '../providers/group_provider.dart';
import '../providers/calendar_provider.dart';

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
}

/// Group detail screen showing group calendar with availability heatmap
/// Adapted from CalendarScreen with Sunset Coral Dark theme
class GroupDetailScreen extends StatefulWidget {
  final GroupModel group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  // Sunset Coral Dark Theme Colors
  static const Color _rose950 = Color(0xFF4C0519);
  static const Color _rose900 = Color(0xFF881337);
  static const Color _rose800 = Color(0xFF9F1239);
  static const Color _rose700 = Color(0xFFBE123C);
  static const Color _rose600 = Color(0xFFE11D48);
  static const Color _rose500 = Color(0xFFF43F5E);
  static const Color _rose400 = Color(0xFFFB7185);
  static const Color _rose300 = Color(0xFFFDA4AF);
  static const Color _rose200 = Color(0xFFFECDD3);
  static const Color _rose50 = Color(0xFFFFF1F2);
  static const Color _orange400 = Color(0xFFFB923C);
  static const Color _orange500 = Color(0xFFF97316);
  static const Color _orange600 = Color(0xFFEA580C);
  static const Color _amber500 = Color(0xFFF59E0B);
  static const Color _emerald500 = Color(0xFF10B981);
  static const Color _slate950 = Color(0xFF020617);

  late DateTime _focusedMonth;
  int? _selectedDay;
  late PageController _pageController;
  Set<TimeFilter> _selectedTimeFilters = {TimeFilter.allDay};
  DateTimeRange? _selectedDateRange;

  // Custom time range (used when allDay/Custom is selected)
  TimeOfDay _customStartTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _customEndTime = const TimeOfDay(hour: 17, minute: 0);

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
    _pageController = PageController(initialPage: 12); // Start at current month

    // Load group members
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProvider>().selectGroup(widget.group.id);
    });
  }

  /// Minimum contiguous free time required to be considered "available" (in minutes)
  static const int _minContiguousFreeMinutes = 120; // 2 hours

  /// Check if user has any events on a specific date within the selected time filters
  /// Returns 0 if busy, 1 if available
  ///
  /// Availability Logic (Contiguous Free Time):
  /// - Available if there's at least 2 hours of UNINTERRUPTED free time
  /// - Events at the edges are fine as long as they leave enough contiguous time
  /// - This answers "Can we actually schedule something here?"
  ///
  /// See: lockitin_docs/availability-logic.md for full documentation
  int _getAvailabilityForDay(CalendarProvider calendarProvider, DateTime date) {
    // Filter out holidays - they don't count as busy time
    final events = calendarProvider.getEventsForDay(date)
        .where((e) => e.category != EventCategory.holiday)
        .toList();

    // If "Custom" filter is selected, use custom time range
    if (_selectedTimeFilters.contains(TimeFilter.allDay)) {
      final filterStart = DateTime(
        date.year, date.month, date.day,
        _customStartTime.hour, _customStartTime.minute,
      );
      final filterEnd = DateTime(
        date.year, date.month, date.day,
        _customEndTime.hour, _customEndTime.minute,
      );

      // Find the longest contiguous free block
      final longestFreeMinutes = _findLongestFreeBlock(events, filterStart, filterEnd);

      // Available if there's at least 2 hours of contiguous free time
      return longestFreeMinutes >= _minContiguousFreeMinutes ? 1 : 0;
    }

    // Check each selected time filter
    for (final filter in _selectedTimeFilters) {
      final startHour = filter.startHour;
      final endHour = filter.endHour;

      // Create time boundaries for this filter on this date
      final DateTime filterStart;
      final DateTime filterEnd;

      if (filter == TimeFilter.night) {
        // Night spans 10pm - 6am (crosses midnight)
        filterStart = DateTime(date.year, date.month, date.day, startHour);
        filterEnd = DateTime(date.year, date.month, date.day + 1, endHour);
      } else {
        filterStart = DateTime(date.year, date.month, date.day, startHour);
        filterEnd = DateTime(date.year, date.month, date.day, endHour);
      }

      // Find the longest contiguous free block
      final longestFreeMinutes = _findLongestFreeBlock(
        events,
        filterStart,
        filterEnd,
      );

      // Available if there's at least 2 hours of contiguous free time
      if (longestFreeMinutes < _minContiguousFreeMinutes) {
        return 0; // Busy - not enough contiguous free time
      }
    }

    return 1; // Available - has sufficient contiguous free time
  }

  /// Find the longest contiguous free block within a time range
  /// Returns the duration in minutes
  int _findLongestFreeBlock(
    List<dynamic> events,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
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
  /// Returns "Free" if no conflicts, or shows conflict count and times
  String _getAvailabilityDescription(
    CalendarProvider calendarProvider,
    DateTime date,
    TimeFilter filter,
  ) {
    final events = calendarProvider.getEventsForDay(date)
        .where((e) => e.category != EventCategory.holiday)
        .toList();

    // Get filter time boundaries
    final DateTime filterStart;
    final DateTime filterEnd;
    final startHour = filter.startHour;
    final endHour = filter.endHour;

    if (filter == TimeFilter.allDay) {
      // Use custom time range
      filterStart = DateTime(
        date.year, date.month, date.day,
        _customStartTime.hour, _customStartTime.minute,
      );
      filterEnd = DateTime(
        date.year, date.month, date.day,
        _customEndTime.hour, _customEndTime.minute,
      );
    } else if (filter == TimeFilter.night) {
      filterStart = DateTime(date.year, date.month, date.day, startHour);
      filterEnd = DateTime(date.year, date.month, date.day + 1, endHour);
    } else {
      filterStart = DateTime(date.year, date.month, date.day, startHour);
      filterEnd = DateTime(date.year, date.month, date.day, endHour);
    }

    // Get overlapping events (conflicts) sorted by start time
    // Use stored hour/minute directly (wall clock time - no timezone conversion)
    final conflicts = events
        .where((e) {
          final eventStart = DateTime(
            date.year, date.month, date.day,
            e.startTime.hour, e.startTime.minute,
          );
          final eventEnd = DateTime(
            date.year, date.month, date.day,
            e.endTime.hour, e.endTime.minute,
          );
          return eventStart.isBefore(filterEnd) && eventEnd.isAfter(filterStart);
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
      final displayStart = eventStart.isBefore(filterStart) ? filterStart : eventStart;
      final displayEnd = eventEnd.isAfter(filterEnd) ? filterEnd : eventEnd;

      return 'Busy ${formatTime(displayStart)} - ${formatTime(displayEnd)}';
    }

    // Multiple conflicts - show count
    return '${conflicts.length} conflicts';
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Get text color for heatmap cell - always white for readability
  Color _getHeatmapTextColor(int available, int total) {
    return Colors.white;
  }

  void _previousMonth() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextMonth() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_rose950, _slate950],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Header with group info
                  _buildHeader(context),

                  // Month navigation
                  _buildMonthNavigation(),

                  // Time filter chips
                  _buildTimeFilterChips(),

                  // Availability legend
                  _buildLegend(),

                  // Calendar grid
                  Expanded(
                    child: _buildCalendarPageView(),
                  ),

                  // Group members section
                  _buildMembersSection(),

                  // Best days section
                  _buildBestDaysSection(),

                  const SizedBox(height: 16),
                ],
              ),

              // Day detail bottom sheet
              if (_selectedDay != null) ...[
                // Backdrop
                GestureDetector(
                  onTap: () => setState(() => _selectedDay = null),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                ),
                // Bottom sheet
                _buildDayDetailSheet(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _rose500.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.chevron_left, size: 28),
            color: Colors.white,
          ),

          // Group emoji
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_amber500, _orange600],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _orange500.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.group.emoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Group name and member count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [_rose200, Color(0xFFFED7AA)], // rose-200 to orange-200
                  ).createShader(bounds),
                  child: Text(
                    widget.group.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  '${widget.group.memberCount} members',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Date range picker
          _buildHeaderDateRangePicker(),

          const SizedBox(width: 4),

          // Members button
          IconButton(
            onPressed: () => _showMembersSheet(context),
            icon: const Icon(Icons.people_rounded, size: 22),
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _previousMonth,
            icon: const Icon(Icons.chevron_left, size: 24),
            color: _rose400.withValues(alpha: 0.6),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [_rose200, Color(0xFFFED7AA)],
            ).createShader(bounds),
            child: Text(
              DateFormat('MMMM yyyy').format(_focusedMonth),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: _nextMonth,
            icon: const Icon(Icons.chevron_right, size: 24),
            color: _rose400.withValues(alpha: 0.6),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final now = DateTime.now();
    final initialRange = _selectedDateRange ?? DateTimeRange(
      start: now,
      end: now.add(const Duration(days: 14)),
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: initialRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: _rose500,
              onPrimary: Colors.white,
              surface: const Color(0xFF1a1a2e),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _clearDateRange() {
    setState(() {
      _selectedDateRange = null;
    });
  }

  void _toggleTimeFilter(TimeFilter filter) {
    setState(() {
      if (filter == TimeFilter.allDay) {
        // Selecting "All Day" clears other selections
        _selectedTimeFilters = {TimeFilter.allDay};
      } else {
        // Remove "All Day" if selecting a specific range
        _selectedTimeFilters.remove(TimeFilter.allDay);

        // Toggle the specific filter
        if (_selectedTimeFilters.contains(filter)) {
          _selectedTimeFilters.remove(filter);
          // If nothing selected, default back to "All Day"
          if (_selectedTimeFilters.isEmpty) {
            _selectedTimeFilters = {TimeFilter.allDay};
          }
        } else {
          _selectedTimeFilters.add(filter);
        }
      }
    });
  }

  Widget _buildTimeFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: TimeFilter.values.map((filter) {
          final isSelected = _selectedTimeFilters.contains(filter);

          // For "All Day", show "Custom" label instead
          final label = filter == TimeFilter.allDay ? 'Custom' : filter.label;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
                onTap: () {
                  if (filter == TimeFilter.allDay) {
                    // Show custom time picker
                    _showCustomTimeRangePicker();
                  } else {
                    _toggleTimeFilter(filter);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_rose500, _orange500],
                          )
                        : null,
                    color: isSelected ? null : _rose900.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : _rose500.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : _rose300,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showCustomTimeRangePicker() {
    // Convert TimeOfDay to dropdown values
    int startHour = _customStartTime.hourOfPeriod == 0 ? 12 : _customStartTime.hourOfPeriod;
    int startMinute = (_customStartTime.minute ~/ 15) * 15; // Round to nearest 15
    String startPeriod = _customStartTime.period == DayPeriod.am ? 'AM' : 'PM';

    int endHour = _customEndTime.hourOfPeriod == 0 ? 12 : _customEndTime.hourOfPeriod;
    int endMinute = (_customEndTime.minute ~/ 15) * 15;
    String endPeriod = _customEndTime.period == DayPeriod.am ? 'AM' : 'PM';

    final hours = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
    final minutes = [0, 15, 30, 45];
    final periods = ['AM', 'PM'];

    showModalBottomSheet(
      context: context,
      backgroundColor: _rose950,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          // Dropdown builder widget
          Widget buildDropdown({
            required String label,
            required dynamic value,
            required List<dynamic> options,
            required Function(dynamic) onChanged,
          }) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: _rose400,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    color: _rose900.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _rose500.withValues(alpha: 0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<dynamic>(
                      value: value,
                      isExpanded: true,
                      dropdownColor: _rose900,
                      borderRadius: BorderRadius.circular(12),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      icon: Icon(Icons.keyboard_arrow_down, color: _rose400, size: 20),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _rose50,
                      ),
                      items: options.map((option) {
                        final display = option is int
                            ? option.toString().padLeft(2, '0')
                            : option.toString();
                        return DropdownMenuItem(
                          value: option,
                          child: Text(display),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) onChanged(val);
                      },
                    ),
                  ),
                ),
              ],
            );
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _rose500.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    'Select Time Range',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _rose50,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Start Time Section
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _rose500,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Start Time',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _rose200,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: buildDropdown(
                          label: 'HOUR',
                          value: startHour,
                          options: hours,
                          onChanged: (val) => setSheetState(() => startHour = val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: buildDropdown(
                          label: 'MIN',
                          value: startMinute,
                          options: minutes,
                          onChanged: (val) => setSheetState(() => startMinute = val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: buildDropdown(
                          label: '',
                          value: startPeriod,
                          options: periods,
                          onChanged: (val) => setSheetState(() => startPeriod = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Divider with "to"
                  Row(
                    children: [
                      Expanded(child: Divider(color: _rose500.withValues(alpha: 0.3))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'to',
                          style: TextStyle(color: _rose400, fontSize: 14),
                        ),
                      ),
                      Expanded(child: Divider(color: _rose500.withValues(alpha: 0.3))),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // End Time Section
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _orange500,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'End Time',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _rose200,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: buildDropdown(
                          label: 'HOUR',
                          value: endHour,
                          options: hours,
                          onChanged: (val) => setSheetState(() => endHour = val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: buildDropdown(
                          label: 'MIN',
                          value: endMinute,
                          options: minutes,
                          onChanged: (val) => setSheetState(() => endMinute = val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: buildDropdown(
                          label: '',
                          value: endPeriod,
                          options: periods,
                          onChanged: (val) => setSheetState(() => endPeriod = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Done Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Convert dropdown values back to TimeOfDay
                        final startHour24 = startPeriod == 'AM'
                            ? (startHour == 12 ? 0 : startHour)
                            : (startHour == 12 ? 12 : startHour + 12);
                        final endHour24 = endPeriod == 'AM'
                            ? (endHour == 12 ? 0 : endHour)
                            : (endHour == 12 ? 12 : endHour + 12);

                        setState(() {
                          _customStartTime = TimeOfDay(hour: startHour24, minute: startMinute);
                          _customEndTime = TimeOfDay(hour: endHour24, minute: endMinute);
                          _selectedTimeFilters = {TimeFilter.allDay};
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ).copyWith(
                        backgroundColor: WidgetStateProperty.all(Colors.transparent),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_rose500, _orange500],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderDateRangePicker() {
    final dateFormat = DateFormat('M/d');
    final hasRange = _selectedDateRange != null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _showDateRangePicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: hasRange
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_rose500, _orange500],
                    )
                  : null,
              color: hasRange ? null : _rose900.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasRange
                    ? Colors.transparent
                    : _rose500.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.date_range_rounded,
                  size: 12,
                  color: hasRange ? Colors.white : _rose300,
                ),
                const SizedBox(width: 4),
                Text(
                  hasRange
                      ? '${dateFormat.format(_selectedDateRange!.start)} - ${dateFormat.format(_selectedDateRange!.end)}'
                      : 'All',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: hasRange ? FontWeight.w600 : FontWeight.w500,
                    color: hasRange ? Colors.white : _rose300,
                  ),
                ),
                if (hasRange) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _clearDateRange,
                    child: Icon(
                      Icons.close,
                      size: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _rose500.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Availability',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
          Row(
            children: [
              Text(
                'Less',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              // Solid color boxes (rose-950 to rose-500)
              ...[_rose950, _rose900, _rose800, _rose700, _rose600, _rose500]
                  .map((color) => Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      )),
              // Gradient box (rose-400 to orange-400) for 100% available
              Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_rose400, _orange400],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'More',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarPageView() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        final monthOffset = index - 12;
        setState(() {
          _focusedMonth = DateTime(
            DateTime.now().year,
            DateTime.now().month + monthOffset,
          );
        });
      },
      itemCount: 24, // 12 months before + 12 months after
      itemBuilder: (context, pageIndex) {
        final monthOffset = pageIndex - 12;
        final month = DateTime(
          DateTime.now().year,
          DateTime.now().month + monthOffset,
        );
        return _buildCalendarGrid(month);
      },
    );
  }

  Widget _buildCalendarGrid(DateTime month) {
    // For now, show 0/1 based on current user's events only
    // In the future, this will aggregate availability from all group members
    const totalMembers = 1; // Just the current user for now
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    // Calculate first day offset and days in month
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final startWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday
    final daysInMonth = lastDayOfMonth.day;

    return Consumer<CalendarProvider>(
      builder: (context, calendarProvider, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              // Day headers
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: days
                      .map((day) => Expanded(
                            child: Center(
                              child: Text(
                                day,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),

              // Calendar cells
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: 42, // 6 rows * 7 days
                  itemBuilder: (context, index) {
                    final dayNumber = index - startWeekday + 1;

                    // Empty cell for days outside current month
                    if (dayNumber < 1 || dayNumber > daysInMonth) {
                      return const SizedBox.shrink();
                    }

                    // Get availability based on real events
                    final date = DateTime(month.year, month.month, dayNumber);
                    final available = _getAvailabilityForDay(calendarProvider, date);
                    final isSelected = _selectedDay == dayNumber &&
                        month.month == _focusedMonth.month;
                    final textColor = _getHeatmapTextColor(available, totalMembers);

                    // Check if fully available (use gradient) or busy (solid color)
                    final isFullyAvailable = available == totalMembers && totalMembers > 0;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDay = dayNumber;
                          _focusedMonth = month;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          // Use gradient for available, solid color for busy
                          gradient: isFullyAvailable
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [_rose400, _orange400],
                                )
                              : null,
                          color: isFullyAvailable ? null : _rose950,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: _orange400, width: 2)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: _orange400.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$dayNumber',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                            Text(
                              '$available/$totalMembers',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMembersSection() {
    return Consumer<GroupProvider>(
      builder: (context, provider, _) {
        final members = provider.selectedGroupMembers;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: _rose500.withValues(alpha: 0.2)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'GROUP MEMBERS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${widget.group.memberCount} people',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Member avatars (stacked)
                  if (provider.isLoadingMembers)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _rose400,
                      ),
                    )
                  else
                    SizedBox(
                      width: (members.length.clamp(0, 6) * 28.0) + 8,
                      height: 36,
                      child: Stack(
                        children: [
                          ...members.take(6).toList().asMap().entries.map((entry) {
                            final index = entry.key;
                            final member = entry.value;
                            return Positioned(
                              left: index * 28.0,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: index == 0
                                      ? null
                                      : _rose900.withValues(alpha: 0.8),
                                  gradient: index == 0
                                      ? const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [_rose400, _orange400],
                                        )
                                      : null,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _rose950, width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    member.initials,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: index == 0 ? Colors.white : _rose200,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                  if (members.length > 6)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        '+${members.length - 6}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),

                  const Spacer(),

                  // Invite button
                  TextButton.icon(
                    onPressed: () => _showInviteFlow(context),
                    icon: Icon(Icons.person_add_rounded, size: 18, color: Colors.white),
                    label: Text(
                      'Invite',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: _rose500.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Get best days for a specific set of time filters
  List<int> _getBestDaysForFilters(
    CalendarProvider calendarProvider,
    Set<TimeFilter> filters,
  ) {
    final lastDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;

    final bestDays = <int>[];
    for (int day = 1; day <= daysInMonth && bestDays.length < 4; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);

      // Skip if outside selected date range
      if (_selectedDateRange != null) {
        if (date.isBefore(_selectedDateRange!.start) ||
            date.isAfter(_selectedDateRange!.end)) {
          continue;
        }
      }

      // Only consider today or future days
      if (date.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
        // Check availability for this specific filter set
        final events = calendarProvider.getEventsForDay(date)
            .where((e) => e.category != EventCategory.holiday)
            .toList();

        bool isAvailable = true;

        if (filters.contains(TimeFilter.allDay)) {
          // Use custom time range
          final filterStart = DateTime(
            date.year, date.month, date.day,
            _customStartTime.hour, _customStartTime.minute,
          );
          final filterEnd = DateTime(
            date.year, date.month, date.day,
            _customEndTime.hour, _customEndTime.minute,
          );

          // Find the longest contiguous free block
          final longestFreeMinutes = _findLongestFreeBlock(events, filterStart, filterEnd);
          isAvailable = longestFreeMinutes >= _minContiguousFreeMinutes;
        } else {
          // Check each filter
          for (final filter in filters) {
            final startHour = filter.startHour;
            final endHour = filter.endHour;

            final DateTime filterStart;
            final DateTime filterEnd;

            if (filter == TimeFilter.night) {
              filterStart = DateTime(date.year, date.month, date.day, startHour);
              filterEnd = DateTime(date.year, date.month, date.day + 1, endHour);
            } else {
              filterStart = DateTime(date.year, date.month, date.day, startHour);
              filterEnd = DateTime(date.year, date.month, date.day, endHour);
            }

            for (final event in events) {
              if (event.startTime.isBefore(filterEnd) && event.endTime.isAfter(filterStart)) {
                isAvailable = false;
                break;
              }
            }
            if (!isAvailable) break;
          }
        }

        if (isAvailable) {
          bestDays.add(day);
        }
      }
    }
    return bestDays;
  }

  /// Format TimeOfDay to string like "9am" or "5:30pm"
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'am' : 'pm';
    if (time.minute == 0) {
      return '$hour$period';
    }
    return '$hour:${time.minute.toString().padLeft(2, '0')}$period';
  }

  Widget _buildBestDaysSection() {
    final hasSpecificFilters = !_selectedTimeFilters.contains(TimeFilter.allDay);
    final customTimeLabel = '${_formatTimeOfDay(_customStartTime)} - ${_formatTimeOfDay(_customEndTime)}';

    return Consumer<CalendarProvider>(
      builder: (context, calendarProvider, _) {
        // Get best days for custom time range (when Custom filter is selected)
        final customBestDays = _getBestDaysForFilters(
          calendarProvider,
          {TimeFilter.allDay},
        );

        // Get best days for selected filters if specific ones are selected
        List<int> filteredBestDays = [];
        String filterLabel = '';
        if (hasSpecificFilters) {
          filteredBestDays = _getBestDaysForFilters(
            calendarProvider,
            _selectedTimeFilters,
          );
          // Consolidate time ranges into earliest start - latest end
          final filters = _selectedTimeFilters.toList();
          int earliestStart = 24;
          int latestEnd = 0;
          for (final filter in filters) {
            if (filter.startHour < earliestStart) {
              earliestStart = filter.startHour;
            }
            // Handle night filter (ends at 6am next day = 30 in 24h terms)
            final effectiveEnd = filter == TimeFilter.night ? 30 : filter.endHour;
            if (effectiveEnd > latestEnd) {
              latestEnd = effectiveEnd;
            }
          }
          // Format the consolidated range
          String formatHour(int hour) {
            final h = hour % 24;
            if (h == 0) return '12am';
            if (h == 12) return '12pm';
            if (h < 12) return '${h}am';
            return '${h - 12}pm';
          }
          filterLabel = '${formatHour(earliestStart)} - ${formatHour(latestEnd % 24)}';
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: _rose500.withValues(alpha: 0.2)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show custom time range when Custom filter is selected
              if (!hasSpecificFilters) ...[
                Row(
                  children: [
                    Text(
                      'BEST DAYS THIS MONTH',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_rose500, _orange500],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        customTimeLabel,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (customBestDays.isNotEmpty)
                  _buildBestDayChips(customBestDays)
                else
                  _buildNoDatesMessage(),
              ],

              // Show filtered best days when specific filters are selected
              if (hasSpecificFilters) ...[
                Row(
                  children: [
                    Text(
                      'BEST DAYS THIS MONTH',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_rose500, _orange500],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        filterLabel,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (filteredBestDays.isNotEmpty)
                  _buildBestDayChips(filteredBestDays)
                else
                  _buildNoDatesMessage(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBestDayChips(List<int> days) {
    final monthName = DateFormat('MMM').format(_focusedMonth);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: days.map((day) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedDay = day),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_rose500, _orange500],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _rose500.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '$monthName $day',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNoDatesMessage() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _rose900.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _rose500.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 16,
              color: _rose400.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Text(
              'No dates to propose this month',
              style: TextStyle(
                fontSize: 13,
                color: _rose300.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayDetailSheet() {
    // For now, just user's availability (0 = busy, 1 = available)
    const totalMembers = 1;
    final monthName = DateFormat('MMMM').format(_focusedMonth);

    return Consumer<CalendarProvider>(
      builder: (context, calendarProvider, _) {
        final date = DateTime(_focusedMonth.year, _focusedMonth.month, _selectedDay ?? 1);
        final available = _getAvailabilityForDay(calendarProvider, date);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_rose950, _slate950],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: _rose500.withValues(alpha: 0.2)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: _rose500.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [_rose200, Color(0xFFFED7AA)],
                        ).createShader(bounds),
                        child: Text(
                          '$monthName $_selectedDay',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        '$available/$totalMembers members available',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => setState(() => _selectedDay = null),
                    icon: const Icon(Icons.close, size: 22),
                    color: _rose300,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Member availability list
            Consumer<GroupProvider>(
              builder: (context, provider, _) {
                final members = provider.selectedGroupMembers;

                return Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.35,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      // Mock availability status
                      final isAvailable = index < available;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isAvailable
                                ? [
                                    _rose900.withValues(alpha: 0.5),
                                    _rose900.withValues(alpha: 0.3),
                                  ]
                                : [
                                    _rose950.withValues(alpha: 0.5),
                                    _rose950.withValues(alpha: 0.3),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isAvailable
                                ? _rose500.withValues(alpha: 0.2)
                                : _rose500.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: index == 0
                                    ? null
                                    : _rose800,
                                gradient: index == 0
                                    ? const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [_rose400, _orange400],
                                      )
                                    : null,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  member.initials,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: index == 0 ? Colors.white : _rose200,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Name and availability time
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.displayName,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: isAvailable
                                          ? _rose50
                                          : _rose400.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  // Show availability time description
                                  Builder(
                                    builder: (context) {
                                      // Get availability descriptions for selected filters
                                      final descriptions = <String>[];

                                      if (_selectedTimeFilters.contains(TimeFilter.allDay)) {
                                        final desc = _getAvailabilityDescription(
                                          calendarProvider,
                                          date,
                                          TimeFilter.allDay,
                                        );
                                        descriptions.add(desc);
                                      } else {
                                        for (final filter in _selectedTimeFilters) {
                                          final desc = _getAvailabilityDescription(
                                            calendarProvider,
                                            date,
                                            filter,
                                          );
                                          // Add filter prefix if multiple filters
                                          if (_selectedTimeFilters.length > 1) {
                                            descriptions.add('${filter.label}: $desc');
                                          } else {
                                            descriptions.add(desc);
                                          }
                                        }
                                      }

                                      // Show the description(s)
                                      if (descriptions.length == 1) {
                                        final desc = descriptions.first;
                                        final isFree = desc == 'Free';

                                        return Row(
                                          children: [
                                            Icon(
                                              isFree
                                                  ? Icons.check_circle_outline
                                                  : Icons.event_busy_rounded,
                                              size: 12,
                                              color: isFree
                                                  ? _emerald500
                                                  : _orange400,
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                desc,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isFree
                                                      ? _emerald500
                                                      : _orange400,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        );
                                      }

                                      // Multiple filters - show each on its own line
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: descriptions.map((desc) {
                                          final isFree = desc == 'Free' || desc.endsWith('Free');

                                          return Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  isFree
                                                      ? Icons.check_circle_outline
                                                      : Icons.event_busy_rounded,
                                                  size: 11,
                                                  color: isFree
                                                      ? _emerald500
                                                      : _orange400,
                                                ),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    desc,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: isFree
                                                          ? _emerald500
                                                          : _orange400,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                            // Status icon
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isAvailable
                                    ? _emerald500.withValues(alpha: 0.2)
                                    : _rose500.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isAvailable ? Icons.check : Icons.close,
                                size: 16,
                                color: isAvailable ? _emerald500 : _rose400,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            // Propose event button
            if (available >= (totalMembers * 0.5).ceil())
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Navigate to event proposal flow
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Event proposals coming in Sprint 3!',
                          ),
                          backgroundColor: _rose500,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _rose500,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      'Propose Event for ${DateFormat('MMM').format(_focusedMonth)} $_selectedDay',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 20),
          ],
        ),
      ),
    );
      },
    );
  }

  void _showMembersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _MembersBottomSheet(group: widget.group),
    );
  }

  void _showInviteFlow(BuildContext context) {
    // TODO: Implement invite flow (Issue #21 or later)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Invite flow coming soon!'),
        backgroundColor: _rose500,
      ),
    );
  }
}

/// Full members list bottom sheet
class _MembersBottomSheet extends StatelessWidget {
  final GroupModel group;

  const _MembersBottomSheet({required this.group});

  static const Color _rose950 = Color(0xFF4C0519);
  static const Color _rose900 = Color(0xFF881337);
  static const Color _rose500 = Color(0xFFF43F5E);
  static const Color _rose400 = Color(0xFFFB7185);
  static const Color _rose300 = Color(0xFFFDA4AF);
  static const Color _rose200 = Color(0xFFFECDD3);
  static const Color _rose50 = Color(0xFFFFF1F2);
  static const Color _orange400 = Color(0xFFFB923C);
  static const Color _slate950 = Color(0xFF020617);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_rose950, _slate950],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: _rose500.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [_rose200, Color(0xFFFED7AA)],
                  ).createShader(bounds),
                  child: Text(
                    'Members (${group.memberCount})',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: _rose300,
                ),
              ],
            ),
          ),

          // Members list
          Expanded(
            child: Consumer<GroupProvider>(
              builder: (context, provider, _) {
                if (provider.isLoadingMembers) {
                  return Center(
                    child: CircularProgressIndicator(color: _rose400),
                  );
                }

                final members = provider.selectedGroupMembers;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _rose900.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _rose500.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: index == 0
                                  ? const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [_rose400, _orange400],
                                    )
                                  : null,
                              color: index == 0 ? null : _rose900,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                member.initials,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: index == 0 ? Colors.white : _rose200,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Name and role
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.displayName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: _rose50,
                                  ),
                                ),
                                Text(
                                  member.roleDisplayName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: member.role == GroupMemberRole.owner
                                        ? _orange400
                                        : _rose300.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Role badge
                          if (member.role == GroupMemberRole.owner)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_rose500, _orange400],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Owner',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          else if (member.role == GroupMemberRole.admin)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _rose500.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Admin',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _rose300,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
