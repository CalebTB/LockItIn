import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/models/group_model.dart';
import '../../../data/models/event_model.dart';
import '../../../core/services/event_service.dart';
import '../../../core/services/availability_calculator_service.dart';
import '../../../core/utils/time_filter_utils.dart';
import '../../providers/group_provider.dart';
import '../../providers/calendar_provider.dart';
import '../../theme/sunset_coral_theme.dart';
import '../../widgets/group_calendar_legend.dart';
import '../../widgets/group_members_section.dart';
import '../../widgets/group_time_filter_chips.dart';
import '../../widgets/group_date_range_filter.dart';
import '../../widgets/group_best_days_section.dart';
import 'widgets/widgets.dart';

/// Group detail screen showing group calendar with availability heatmap
/// Adapted from CalendarScreen with Sunset Coral Dark theme
class GroupDetailScreen extends StatefulWidget {
  final GroupModel group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  // Use theme colors from SunsetCoralTheme
  static const _rose950 = SunsetCoralTheme.rose950;
  static const _rose900 = SunsetCoralTheme.rose900;
  static const _rose800 = SunsetCoralTheme.rose800;
  static const _rose500 = SunsetCoralTheme.rose500;
  static const _rose400 = SunsetCoralTheme.rose400;
  static const _rose200 = SunsetCoralTheme.rose200;
  static const _orange400 = SunsetCoralTheme.orange400;
  static const _orange600 = SunsetCoralTheme.orange600;
  static const _amber500 = SunsetCoralTheme.amber500;
  static const _slate950 = SunsetCoralTheme.slate950;

  // Availability calculation service
  final _availabilityService = AvailabilityCalculatorService();

  late DateTime _focusedMonth;
  int? _selectedDay;
  late PageController _pageController;
  Set<TimeFilter> _selectedTimeFilters = {TimeFilter.allDay};
  DateTimeRange? _selectedDateRange;

  // Custom time range (used when allDay/Custom is selected)
  TimeOfDay _customStartTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _customEndTime = const TimeOfDay(hour: 17, minute: 0);

  // Group members' events for availability calculation
  Map<String, List<EventModel>> _memberEvents = {};
  bool _isLoadingMemberEvents = false;
  String? _memberEventsError;

  // Availability cache for performance (Issue #100)
  // Key format: 'YYYY-MM-DD', Value: number of available members
  final Map<String, int> _availabilityCache = {};

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
    _pageController = PageController(initialPage: 12); // Start at current month

    // Load group members and their events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGroupData();
    });
  }

  /// Initialize group data - load members, then their events
  Future<void> _initializeGroupData() async {
    final groupProvider = context.read<GroupProvider>();

    // Wait for group selection and member loading to complete
    await groupProvider.selectGroup(widget.group.id);

    // Now load member events
    await _loadMemberEvents();
  }

  /// Load shadow calendar entries for all group members
  /// Uses the privacy-respecting shadow calendar system
  Future<void> _loadMemberEvents() async {
    final groupProvider = context.read<GroupProvider>();
    final members = groupProvider.selectedGroupMembers;

    if (members.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingMemberEvents = true;
      _memberEventsError = null;
    });

    try {
      final memberIds = members.map((m) => m.userId).toList();

      // Fetch events for 2 months before and after current month
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - 2, 1);
      final endDate = DateTime(now.year, now.month + 3, 0);

      final shadowEntries = await EventService.instance.fetchGroupShadowCalendar(
        memberUserIds: memberIds,
        startDate: startDate,
        endDate: endDate,
      );

      final events = EventService.instance.shadowToEventModels(shadowEntries);

      if (mounted) {
        setState(() {
          _memberEvents = events;
          _isLoadingMemberEvents = false;
          _memberEventsError = null;
          _clearAvailabilityCache(); // Clear cache when member events change
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMemberEvents = false;
          _memberEventsError = 'Failed to load member availability';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not load group availability'),
            backgroundColor: _rose500,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadMemberEvents,
            ),
          ),
        );
      }
    }
  }

  /// Calculate how many group members are available on a specific date
  /// Uses memoization cache to avoid recalculating 42 times per build (Issue #100)
  int _getAvailabilityForDay(CalendarProvider calendarProvider, DateTime date) {
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    // Return cached value if available
    if (_availabilityCache.containsKey(key)) {
      return _availabilityCache[key]!;
    }

    // Calculate and cache the result
    final result = _availabilityService.calculateGroupAvailability(
      memberEvents: _memberEvents,
      date: date,
      timeFilters: _selectedTimeFilters,
      customStartTime: _customStartTime,
      customEndTime: _customEndTime,
    );

    _availabilityCache[key] = result;
    return result;
  }

  /// Clear availability cache when filters or data change
  void _clearAvailabilityCache() {
    _availabilityCache.clear();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Additional rose colors for heatmap gradient
  static const Color _rose600 = Color(0xFFE11D48);
  static const Color _rose700 = Color(0xFFBE123C);

  /// Get background color for heatmap cell based on availability ratio
  Color _getHeatmapBackgroundColor(int available, int total) {
    if (total == 0) return _rose950;

    final ratio = available / total;

    if (ratio >= 1.0) {
      return _rose400;
    } else if (ratio >= 0.875) {
      return _rose400;
    } else if (ratio >= 0.75) {
      return _rose500;
    } else if (ratio >= 0.625) {
      return _rose600;
    } else if (ratio >= 0.5) {
      return _rose700;
    } else if (ratio >= 0.375) {
      return _rose800;
    } else if (ratio >= 0.25) {
      return _rose900;
    } else {
      return _rose950;
    }
  }

  /// Get text color for heatmap cell
  Color _getHeatmapTextColor(int available, int total) {
    if (total == 0) return _rose400;

    final ratio = available / total;

    if (ratio >= 0.375) {
      return Colors.white;
    } else if (ratio >= 0.25) {
      return SunsetCoralTheme.rose300;
    } else {
      return _rose400;
    }
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
                  _buildHeader(context),
                  if (_memberEventsError != null) _buildErrorBanner(),
                  _buildMonthNavigation(),
                  GroupDateRangeFilter(
                    selectedDateRange: _selectedDateRange,
                    onTap: _showDateRangePicker,
                    onClear: _clearDateRange,
                  ),
                  GroupTimeFilterChips(
                    selectedFilters: _selectedTimeFilters,
                    onFilterTap: _toggleTimeFilter,
                    onCustomTap: _showCustomTimeRangePicker,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const GroupCalendarLegend(),
                          SizedBox(
                            height: 360,
                            child: _buildCalendarPageView(),
                          ),
                          GroupMembersSection(
                            group: widget.group,
                            onInvite: () => _showInviteFlow(context),
                          ),
                          GroupBestDaysSection(
                            focusedMonth: _focusedMonth,
                            selectedTimeFilters: _selectedTimeFilters,
                            customStartTime: _customStartTime,
                            customEndTime: _customEndTime,
                            getBestDaysForFilters: (filters) =>
                                _getBestDaysForFilters(
                                  context.read<CalendarProvider>(),
                                  filters,
                                ),
                            onDaySelected: (day) =>
                                setState(() => _selectedDay = day),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Day detail bottom sheet
              if (_selectedDay != null) ...[
                GestureDetector(
                  onTap: () => setState(() => _selectedDay = null),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                ),
                DayDetailSheet(
                  date: DateTime(_focusedMonth.year, _focusedMonth.month, _selectedDay ?? 1),
                  focusedMonth: _focusedMonth,
                  selectedDay: _selectedDay,
                  onClose: () => setState(() => _selectedDay = null),
                  memberEvents: _memberEvents,
                  selectedTimeFilters: _selectedTimeFilters,
                  customStartTime: _customStartTime,
                  customEndTime: _customEndTime,
                  availabilityService: _availabilityService,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _rose500.withValues(alpha: 0.2),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 18, color: _orange400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _memberEventsError ?? 'Error loading availability',
              style: TextStyle(fontSize: 13, color: _rose200),
            ),
          ),
          TextButton(
            onPressed: _loadMemberEvents,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Retry',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _orange400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _rose500.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.chevron_left, size: 24),
            color: Colors.white,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_amber500, _orange600],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                widget.group.emoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [_rose200, Color(0xFFFED7AA)],
              ).createShader(bounds),
              child: Text(
                widget.group.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => _showMembersSheet(context),
            icon: const Icon(Icons.people_rounded, size: 20),
            color: Colors.white,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
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

  void _showDateRangePicker() {
    showDateRangePickerModal(
      context: context,
      currentRange: _selectedDateRange,
      onRangeSelected: (range) {
        setState(() {
          _selectedDateRange = range;
          _clearAvailabilityCache(); // Clear cache when date range changes
        });
      },
    );
  }

  void _clearDateRange() {
    setState(() {
      _selectedDateRange = null;
      _clearAvailabilityCache(); // Clear cache when date range changes
    });
  }

  void _toggleTimeFilter(TimeFilter filter) {
    setState(() {
      if (filter == TimeFilter.allDay) {
        _selectedTimeFilters = {TimeFilter.allDay};
      } else {
        _selectedTimeFilters.remove(TimeFilter.allDay);

        if (_selectedTimeFilters.contains(filter)) {
          _selectedTimeFilters.remove(filter);
          if (_selectedTimeFilters.isEmpty) {
            _selectedTimeFilters = {TimeFilter.allDay};
          }
        } else {
          _selectedTimeFilters.add(filter);
        }
      }
      _clearAvailabilityCache(); // Clear cache when time filters change
    });
  }

  void _showCustomTimeRangePicker() {
    showCustomTimePickerModal(
      context: context,
      currentStartTime: _customStartTime,
      currentEndTime: _customEndTime,
      onTimeSelected: (startTime, endTime) {
        setState(() {
          _customStartTime = startTime;
          _customEndTime = endTime;
          _selectedTimeFilters = {TimeFilter.allDay};
          _clearAvailabilityCache(); // Clear cache when custom time range changes
        });
      },
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
      itemCount: 24,
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
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final startWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;

    return Consumer2<CalendarProvider, GroupProvider>(
      builder: (context, calendarProvider, groupProvider, _) {
        final totalMembers = groupProvider.selectedGroupMembers.isNotEmpty
            ? groupProvider.selectedGroupMembers.length
            : (groupProvider.selectedGroup?.memberCount ?? 1);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
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
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 3,
                    mainAxisSpacing: 3,
                  ),
                  itemCount: 42,
                  itemBuilder: (context, index) {
                    final dayNumber = index - startWeekday + 1;

                    if (dayNumber < 1 || dayNumber > daysInMonth) {
                      return const SizedBox.shrink();
                    }

                    final date = DateTime(month.year, month.month, dayNumber);
                    final isSelected = _selectedDay == dayNumber &&
                        month.month == _focusedMonth.month;

                    final isInRange = _selectedDateRange == null ||
                        (!date.isBefore(_selectedDateRange!.start) &&
                         !date.isAfter(_selectedDateRange!.end));

                    final available = isInRange
                        ? _getAvailabilityForDay(calendarProvider, date)
                        : 0;
                    final textColor = isInRange
                        ? _getHeatmapTextColor(available, totalMembers)
                        : _rose500.withValues(alpha: 0.4);

                    final isFullyAvailable = isInRange && available == totalMembers && totalMembers > 0;

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
                          gradient: isFullyAvailable
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [_rose400, _orange400],
                                )
                              : null,
                          color: isFullyAvailable
                              ? null
                              : (isInRange
                                  ? _getHeatmapBackgroundColor(available, totalMembers)
                                  : _rose950.withValues(alpha: 0.3)),
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
                            if (isInRange)
                              _isLoadingMemberEvents
                                ? SizedBox(
                                    width: 8,
                                    height: 8,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1,
                                      color: textColor.withValues(alpha: 0.5),
                                    ),
                                  )
                                : Text(
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

  List<int> _getBestDaysForFilters(
    CalendarProvider calendarProvider,
    Set<TimeFilter> filters,
  ) {
    final allBestDays = _availabilityService.findBestDaysInMonth(
      memberEvents: _memberEvents,
      month: _focusedMonth,
      timeFilters: filters,
      dateRange: _selectedDateRange,
      customStartTime: _customStartTime,
      customEndTime: _customEndTime,
    );

    final now = DateTime.now().subtract(const Duration(days: 1));
    return allBestDays
        .where((day) {
          final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
          return date.isAfter(now);
        })
        .take(4)
        .toList();
  }

  void _showMembersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MembersBottomSheet(group: widget.group),
    );
  }

  void _showInviteFlow(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Invite flow coming soon!'),
        backgroundColor: _rose500,
      ),
    );
  }
}
