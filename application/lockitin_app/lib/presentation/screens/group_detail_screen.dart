import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/group_model.dart';
import '../../data/models/event_model.dart';
import '../../core/services/event_service.dart';
import '../../core/services/availability_calculator_service.dart';
import '../../core/utils/time_filter_utils.dart';
import '../providers/group_provider.dart';
import '../providers/calendar_provider.dart';
import '../theme/sunset_coral_theme.dart';
import '../widgets/group_calendar_legend.dart';
import '../widgets/group_members_section.dart';
import '../widgets/group_time_filter_chips.dart';
import '../widgets/group_date_range_filter.dart';
import '../widgets/group_best_days_section.dart';
import '../widgets/suggested_time_slots_card.dart';

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
  static const _rose300 = SunsetCoralTheme.rose300;
  static const _rose200 = SunsetCoralTheme.rose200;
  static const _rose50 = SunsetCoralTheme.rose50;
  static const _orange400 = SunsetCoralTheme.orange400;
  static const _orange500 = SunsetCoralTheme.orange500;
  static const _orange600 = SunsetCoralTheme.orange600;
  static const _amber500 = SunsetCoralTheme.amber500;
  static const _emerald500 = SunsetCoralTheme.emerald500;
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
      // If members still empty, wait a bit and check again
      // (could happen if network is slow)
      return;
    }

    setState(() => _isLoadingMemberEvents = true);

    try {
      // Get member user IDs
      final memberIds = members.map((m) => m.userId).toList();

      // Fetch events for 2 months before and after current month
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - 2, 1);
      final endDate = DateTime(now.year, now.month + 3, 0);

      // Use shadow calendar for privacy-respecting availability data
      final shadowEntries = await EventService.instance.fetchGroupShadowCalendar(
        memberUserIds: memberIds,
        startDate: startDate,
        endDate: endDate,
      );

      // Convert to EventModel format for compatibility with availability calculator
      final events = EventService.instance.shadowToEventModels(shadowEntries);

      if (mounted) {
        setState(() {
          _memberEvents = events;
          _isLoadingMemberEvents = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMemberEvents = false);
      }
    }
  }

  /// Calculate how many group members are available on a specific date
  /// Delegates to AvailabilityCalculatorService
  int _getAvailabilityForDay(CalendarProvider calendarProvider, DateTime date) {
    return _availabilityService.calculateGroupAvailability(
      memberEvents: _memberEvents,
      date: date,
      timeFilters: _selectedTimeFilters,
      customStartTime: _customStartTime,
      customEndTime: _customEndTime,
    );
  }

  /// Get a human-readable description of availability for a specific member
  /// Uses _memberEvents to get the member's events
  String _getMemberAvailabilityDescription(
    String memberId,
    DateTime date,
    TimeFilter filter,
  ) {
    // Get this member's events for the date
    final memberEventsList = _memberEvents[memberId] ?? [];
    final dayStart = DateTime(date.year, date.month, date.day, 0, 0);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final eventsOnDate = memberEventsList
        .where((e) {
          // Convert UTC event times to local for comparison
          final localStart = e.startTime.toLocal();
          final localEnd = e.endTime.toLocal();
          return localStart.isBefore(dayEnd) && localEnd.isAfter(dayStart);
        })
        .where((e) => e.category != EventCategory.holiday)
        .toList();

    return _availabilityService.getAvailabilityDescription(
      events: eventsOnDate,
      date: date,
      filter: filter,
      customStartTime: _customStartTime,
      customEndTime: _customEndTime,
    );
  }

  /// Check if a specific member is available on a date
  bool _isMemberAvailableOnDate(String memberId, DateTime date) {
    final memberEventsList = _memberEvents[memberId] ?? [];
    final dayStart = DateTime(date.year, date.month, date.day, 0, 0);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final eventsOnDate = memberEventsList
        .where((e) {
          // Convert UTC event times to local for comparison
          final localStart = e.startTime.toLocal();
          final localEnd = e.endTime.toLocal();
          return localStart.isBefore(dayEnd) && localEnd.isAfter(dayStart);
        })
        .where((e) => e.category != EventCategory.holiday)
        .toList();

    return _availabilityService.isMemberAvailable(
      events: eventsOnDate,
      date: date,
      timeFilters: _selectedTimeFilters,
      customStartTime: _customStartTime,
      customEndTime: _customEndTime,
    );
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
  /// Matches JSX design: discrete color stops at each threshold
  Color _getHeatmapBackgroundColor(int available, int total) {
    if (total == 0) return _rose950;

    final ratio = available / total;

    // Color stops matching JSX design (from least to most available)
    if (ratio >= 1.0) {
      return _rose400; // 100% - will use gradient instead
    } else if (ratio >= 0.875) {
      return _rose400; // 87.5%+
    } else if (ratio >= 0.75) {
      return _rose500; // 75%+
    } else if (ratio >= 0.625) {
      return _rose600; // 62.5%+
    } else if (ratio >= 0.5) {
      return _rose700; // 50%+
    } else if (ratio >= 0.375) {
      return _rose800; // 37.5%+
    } else if (ratio >= 0.25) {
      return _rose900; // 25%+
    } else {
      return _rose950; // <25%
    }
  }

  /// Get text color for heatmap cell - matches JSX design
  Color _getHeatmapTextColor(int available, int total) {
    if (total == 0) return _rose400;

    final ratio = available / total;

    // Text colors matching JSX design
    if (ratio >= 0.375) {
      return Colors.white; // 37.5%+ - white text
    } else if (ratio >= 0.25) {
      return _rose300; // 25%+ - rose-300
    } else {
      return _rose400; // <25% - rose-400
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
                  // Header with group info (compact)
                  _buildHeader(context),

                  // Month navigation
                  _buildMonthNavigation(),

                  // Date range filter row
                  GroupDateRangeFilter(
                    selectedDateRange: _selectedDateRange,
                    onTap: _showDateRangePicker,
                    onClear: _clearDateRange,
                  ),

                  // Time filter chips
                  GroupTimeFilterChips(
                    selectedFilters: _selectedTimeFilters,
                    onFilterTap: _toggleTimeFilter,
                    onCustomTap: _showCustomTimeRangePicker,
                  ),

                  // Scrollable content: legend + calendar + members + best days
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Availability legend
                          const GroupCalendarLegend(),

                          // Calendar grid (fixed height for 6 rows)
                          SizedBox(
                            height: 360, // Increased height for 6 rows
                            child: _buildCalendarPageView(),
                          ),

                          // Group members section
                          GroupMembersSection(
                            group: widget.group,
                            onInvite: () => _showInviteFlow(context),
                          ),

                          // Best days section
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            icon: const Icon(Icons.chevron_left, size: 24),
            color: Colors.white,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),

          // Group emoji (compact)
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

          // Group name only (member count moved to members section)
          Expanded(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [_rose200, Color(0xFFFED7AA)], // rose-200 to orange-200
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

          // Members button
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Start date selection (defaults to today)
    DateTime selectedStartDate = _selectedDateRange?.start ?? today;
    // End date selection (defaults to 7 days out)
    DateTime selectedEndDate = _selectedDateRange?.end ?? today.add(const Duration(days: 7));

    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final months = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
    // Show current year through 5 years out
    final years = List.generate(6, (i) => now.year + i);

    // Get days in a month
    int daysInMonth(int month, int year) {
      return DateTime(year, month + 1, 0).day;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: _rose950,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          // Get days for start date
          final startDays = List.generate(
            daysInMonth(selectedStartDate.month, selectedStartDate.year),
            (i) => i + 1,
          );
          // Get days for end date
          final endDays = List.generate(
            daysInMonth(selectedEndDate.month, selectedEndDate.year),
            (i) => i + 1,
          );

          // Dropdown builder widget
          Widget buildDropdown({
            required String label,
            required dynamic value,
            required List<dynamic> options,
            required Function(dynamic) onChanged,
            String Function(dynamic)? displayFn,
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
                      menuMaxHeight: 200,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      icon: Icon(Icons.keyboard_arrow_down, color: _rose400, size: 20),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _rose50,
                      ),
                      items: options.map((option) {
                        final display = displayFn != null
                            ? displayFn(option)
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
                    'Select Date Range',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _rose50,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Start Date Section
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
                        'Start Date',
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
                          label: 'MONTH',
                          value: selectedStartDate.month,
                          options: months,
                          displayFn: (m) => monthNames[m - 1],
                          onChanged: (val) {
                            setSheetState(() {
                              final maxDay = daysInMonth(val, selectedStartDate.year);
                              final newDay = selectedStartDate.day > maxDay ? maxDay : selectedStartDate.day;
                              selectedStartDate = DateTime(selectedStartDate.year, val, newDay);
                              // If start is now after end, update end to match start
                              if (selectedStartDate.isAfter(selectedEndDate)) {
                                selectedEndDate = selectedStartDate;
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: buildDropdown(
                          label: 'DAY',
                          value: selectedStartDate.day,
                          options: startDays,
                          displayFn: (d) => d.toString().padLeft(2, '0'),
                          onChanged: (val) {
                            setSheetState(() {
                              selectedStartDate = DateTime(selectedStartDate.year, selectedStartDate.month, val);
                              // If start is now after end, update end to match start
                              if (selectedStartDate.isAfter(selectedEndDate)) {
                                selectedEndDate = selectedStartDate;
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: buildDropdown(
                          label: 'YEAR',
                          value: selectedStartDate.year,
                          options: years,
                          onChanged: (val) {
                            setSheetState(() {
                              final maxDay = daysInMonth(selectedStartDate.month, val);
                              final newDay = selectedStartDate.day > maxDay ? maxDay : selectedStartDate.day;
                              selectedStartDate = DateTime(val, selectedStartDate.month, newDay);
                              // If start is now after end, update end to match start
                              if (selectedStartDate.isAfter(selectedEndDate)) {
                                selectedEndDate = selectedStartDate;
                              }
                            });
                          },
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

                  // End Date Section
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
                        'End Date',
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
                          label: 'MONTH',
                          value: selectedEndDate.month,
                          options: months,
                          displayFn: (m) => monthNames[m - 1],
                          onChanged: (val) {
                            setSheetState(() {
                              final maxDay = daysInMonth(val, selectedEndDate.year);
                              final newDay = selectedEndDate.day > maxDay ? maxDay : selectedEndDate.day;
                              selectedEndDate = DateTime(selectedEndDate.year, val, newDay);
                              // If end is now before start, update start to match end
                              if (selectedEndDate.isBefore(selectedStartDate)) {
                                selectedStartDate = selectedEndDate;
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: buildDropdown(
                          label: 'DAY',
                          value: selectedEndDate.day,
                          options: endDays,
                          displayFn: (d) => d.toString().padLeft(2, '0'),
                          onChanged: (val) {
                            setSheetState(() {
                              selectedEndDate = DateTime(selectedEndDate.year, selectedEndDate.month, val);
                              // If end is now before start, update start to match end
                              if (selectedEndDate.isBefore(selectedStartDate)) {
                                selectedStartDate = selectedEndDate;
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: buildDropdown(
                          label: 'YEAR',
                          value: selectedEndDate.year,
                          options: years,
                          onChanged: (val) {
                            setSheetState(() {
                              final maxDay = daysInMonth(selectedEndDate.month, val);
                              final newDay = selectedEndDate.day > maxDay ? maxDay : selectedEndDate.day;
                              selectedEndDate = DateTime(val, selectedEndDate.month, newDay);
                              // If end is now before start, update start to match end
                              if (selectedEndDate.isBefore(selectedStartDate)) {
                                selectedStartDate = selectedEndDate;
                              }
                            });
                          },
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
                        setState(() {
                          _selectedDateRange = DateTimeRange(
                            start: selectedStartDate,
                            end: selectedEndDate,
                          );
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
                      menuMaxHeight: 200,
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
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    // Calculate first day offset and days in month
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final startWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday
    final daysInMonth = lastDayOfMonth.day;

    return Consumer2<CalendarProvider, GroupProvider>(
      builder: (context, calendarProvider, groupProvider, _) {
        // Get actual member count from the group
        final totalMembers = groupProvider.selectedGroupMembers.isNotEmpty
            ? groupProvider.selectedGroupMembers.length
            : (groupProvider.selectedGroup?.memberCount ?? 1);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              // Day headers
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

              // Calendar cells (fills remaining space)
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 3,
                    mainAxisSpacing: 3,
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
                    final isSelected = _selectedDay == dayNumber &&
                        month.month == _focusedMonth.month;

                    // Check if date is within selected range (if a range is set)
                    final isInRange = _selectedDateRange == null ||
                        (!date.isBefore(_selectedDateRange!.start) &&
                         !date.isAfter(_selectedDateRange!.end));

                    // Only calculate availability if in range
                    final available = isInRange
                        ? _getAvailabilityForDay(calendarProvider, date)
                        : 0;
                    final textColor = isInRange
                        ? _getHeatmapTextColor(available, totalMembers)
                        : _rose500.withValues(alpha: 0.4);

                    // Check if fully available (use gradient) or busy (solid color)
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
                          // Use gradient for fully available, interpolated color for partial
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
                            // Only show availability info if in range
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

  /// Get best days for a specific set of time filters
  /// Uses AvailabilityCalculatorService for consistent availability logic
  List<int> _getBestDaysForFilters(
    CalendarProvider calendarProvider,
    Set<TimeFilter> filters,
  ) {
    // Use the service to find best days based on group availability
    final allBestDays = _availabilityService.findBestDaysInMonth(
      memberEvents: _memberEvents,
      month: _focusedMonth,
      timeFilters: filters,
      dateRange: _selectedDateRange,
      customStartTime: _customStartTime,
      customEndTime: _customEndTime,
    );

    // Filter to only include today or future days, limit to 4
    final now = DateTime.now().subtract(const Duration(days: 1));
    return allBestDays
        .where((day) {
          final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
          return date.isAfter(now);
        })
        .take(4)
        .toList();
  }

  Widget _buildDayDetailSheet() {
    final monthName = DateFormat('MMMM').format(_focusedMonth);
    final groupProvider = context.read<GroupProvider>();
    final totalMembers = groupProvider.selectedGroupMembers.isNotEmpty
        ? groupProvider.selectedGroupMembers.length
        : _memberEvents.length;

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

            // Suggested time slots section
            Builder(
              builder: (context) {
                final groupProvider = context.read<GroupProvider>();
                final members = groupProvider.selectedGroupMembers;

                // Compute best time slots for this date
                final timeSlots = _availabilityService.findBestTimeSlots(
                  memberEvents: _memberEvents,
                  date: date,
                  startHour: 8,
                  endHour: 22,
                );

                return SuggestedTimeSlotsCard(
                  date: date,
                  timeSlots: timeSlots,
                  members: members,
                  onSlotSelected: (slot) {
                    // TODO: Navigate to event proposal flow with pre-selected time
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Selected ${slot.formattedTimeRange} - Event proposals coming in Sprint 3!',
                        ),
                        backgroundColor: _rose500,
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 8),

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
                      // Check actual member availability from their events
                      final isAvailable = _isMemberAvailableOnDate(member.userId, date);

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
                                  // Show availability time description for THIS member
                                  Builder(
                                    builder: (context) {
                                      // Get availability descriptions for selected filters
                                      final descriptions = <String>[];

                                      if (_selectedTimeFilters.contains(TimeFilter.allDay)) {
                                        final desc = _getMemberAvailabilityDescription(
                                          member.userId,
                                          date,
                                          TimeFilter.allDay,
                                        );
                                        descriptions.add(desc);
                                      } else {
                                        for (final filter in _selectedTimeFilters) {
                                          final desc = _getMemberAvailabilityDescription(
                                            member.userId,
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

/// Full members list bottom sheet with role-based management
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
  static const Color _red500 = Color(0xFFEF4444);

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
      child: Consumer<GroupProvider>(
        builder: (context, provider, _) {
          final canManage = provider.canManageMembers;
          final isOwner = provider.isOwner;

          return Column(
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        if (canManage)
                          Text(
                            'Tap member to manage',
                            style: TextStyle(
                              fontSize: 12,
                              color: _rose300.withValues(alpha: 0.6),
                            ),
                          ),
                      ],
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
                child: Builder(
                  builder: (context) {
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

                        return GestureDetector(
                          onTap: canManage
                              ? () => _showMemberOptions(context, member, provider)
                              : null,
                          child: Container(
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
                                    gradient: member.role == GroupMemberRole.owner
                                        ? const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [_rose400, _orange400],
                                          )
                                        : null,
                                    color: member.role == GroupMemberRole.owner ? null : _rose900,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      member.initials,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: member.role == GroupMemberRole.owner
                                            ? Colors.white
                                            : _rose200,
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
                                // Owner badge
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
                                // Co-Owner badge
                                else if (member.role == GroupMemberRole.coOwner)
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
                                      'Co-Owner',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _rose300,
                                      ),
                                    ),
                                  ),

                                // Chevron for manageable members (owners can manage everyone)
                                if (canManage)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Icon(
                                      Icons.chevron_right,
                                      size: 20,
                                      color: _rose400.withValues(alpha: 0.5),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Leave group button (for non-owners)
              if (!isOwner && provider.currentUserRole != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmLeaveGroup(context, provider),
                      icon: const Icon(Icons.exit_to_app, size: 18),
                      label: const Text('Leave Group'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _red500,
                        side: BorderSide(color: _red500.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showMemberOptions(
    BuildContext context,
    GroupMemberProfile member,
    GroupProvider provider,
  ) {
    // Only owners and co-owners can manage members
    if (!provider.canManageMembers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Only owners and co-owners can manage members'),
          backgroundColor: _rose500,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: _rose950,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _MemberOptionsSheet(
        member: member,
        groupId: group.id,
        isOwner: provider.isOwner,
        isCoOwner: provider.isCoOwner,
      ),
    );
  }

  void _confirmLeaveGroup(BuildContext context, GroupProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _rose950,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Leave Group?',
          style: TextStyle(color: _rose50),
        ),
        content: Text(
          'Are you sure you want to leave "${group.name}"? You will need to be invited again to rejoin.',
          style: TextStyle(color: _rose200),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: _rose300)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close members sheet

              final success = await provider.leaveGroup(group.id);

              if (context.mounted) {
                if (success) {
                  Navigator.pop(context); // Close group detail screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Left ${group.name}'),
                      backgroundColor: _rose500,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.actionError ?? 'Failed to leave group'),
                      backgroundColor: _red500,
                    ),
                  );
                }
              }
            },
            child: Text('Leave', style: TextStyle(color: _red500)),
          ),
        ],
      ),
    );
  }
}

/// Member options bottom sheet
class _MemberOptionsSheet extends StatelessWidget {
  final GroupMemberProfile member;
  final String groupId;
  final bool isOwner;
  final bool isCoOwner;

  const _MemberOptionsSheet({
    required this.member,
    required this.groupId,
    required this.isOwner,
    required this.isCoOwner,
  });

  /// Whether current user can manage (is owner or co-owner)
  bool get canManage => isOwner || isCoOwner;

  static const Color _rose950 = Color(0xFF4C0519);
  static const Color _rose500 = Color(0xFFF43F5E);
  static const Color _rose400 = Color(0xFFFB7185);
  static const Color _rose300 = Color(0xFFFDA4AF);
  static const Color _rose200 = Color(0xFFFECDD3);
  static const Color _rose50 = Color(0xFFFFF1F2);
  static const Color _orange400 = Color(0xFFFB923C);
  static const Color _red500 = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Container(
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

          // Member info
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _rose500.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    member.initials,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _rose200,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.displayName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _rose50,
                      ),
                    ),
                    Text(
                      member.roleDisplayName,
                      style: TextStyle(
                        fontSize: 14,
                        color: _rose300,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Options for owners and co-owners
          if (canManage) ...[
            // Cannot manage the owner
            if (member.role != GroupMemberRole.owner) ...[
              // Promote/demote co-owner options
              if (member.role == GroupMemberRole.coOwner)
                _buildOptionTile(
                  context,
                  icon: Icons.person_outline,
                  label: 'Remove Co-Owner',
                  color: _orange400,
                  onTap: () => _demoteFromCoOwner(context),
                )
              else
                _buildOptionTile(
                  context,
                  icon: Icons.stars,
                  label: 'Make Co-Owner',
                  color: _orange400,
                  onTap: () => _promoteToCoOwner(context),
                ),
              const SizedBox(height: 8),

              // Transfer ownership (only owner can do this, only to non-owners)
              if (isOwner) ...[
                _buildOptionTile(
                  context,
                  icon: Icons.swap_horiz,
                  label: 'Transfer Ownership',
                  color: _rose400,
                  onTap: () => _confirmTransferOwnership(context),
                ),
                const SizedBox(height: 8),
              ],

              // Remove from group
              // Co-owners can only remove regular members
              if (isOwner || member.role == GroupMemberRole.member)
                _buildOptionTile(
                  context,
                  icon: Icons.person_remove,
                  label: 'Remove from Group',
                  color: _red500,
                  onTap: () => _confirmRemoveMember(context),
                ),
            ],
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _promoteToCoOwner(BuildContext context) async {
    final provider = context.read<GroupProvider>();

    Navigator.pop(context); // Close options sheet

    final success = await provider.promoteToCoOwner(
      groupId: groupId,
      userId: member.userId,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '${member.displayName} is now a co-owner'
                : provider.actionError ?? 'Failed to promote member',
          ),
          backgroundColor: success ? _rose500 : _red500,
        ),
      );
    }
  }

  void _demoteFromCoOwner(BuildContext context) async {
    final provider = context.read<GroupProvider>();

    Navigator.pop(context); // Close options sheet

    final success = await provider.demoteFromCoOwner(
      groupId: groupId,
      userId: member.userId,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '${member.displayName} is now a member'
                : provider.actionError ?? 'Failed to demote co-owner',
          ),
          backgroundColor: success ? _rose500 : _red500,
        ),
      );
    }
  }

  void _confirmTransferOwnership(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _rose950,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Transfer Ownership?',
          style: TextStyle(color: _rose50),
        ),
        content: Text(
          'Are you sure you want to make ${member.displayName} the owner? You will become a member.',
          style: TextStyle(color: _rose200),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: _rose300)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context); // Close options sheet

              final provider = context.read<GroupProvider>();
              final success = await provider.transferOwnership(
                groupId: groupId,
                newOwnerId: member.userId,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? '${member.displayName} is now the owner'
                          : provider.actionError ?? 'Failed to transfer ownership',
                    ),
                    backgroundColor: success ? _rose500 : _red500,
                  ),
                );
              }
            },
            child: Text('Transfer', style: TextStyle(color: _orange400)),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveMember(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _rose950,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Remove Member?',
          style: TextStyle(color: _rose50),
        ),
        content: Text(
          'Are you sure you want to remove ${member.displayName} from the group?',
          style: TextStyle(color: _rose200),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: _rose300)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context); // Close options sheet

              final provider = context.read<GroupProvider>();
              final success = await provider.removeMember(
                groupId: groupId,
                userId: member.userId,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? '${member.displayName} has been removed'
                          : provider.actionError ?? 'Failed to remove member',
                    ),
                    backgroundColor: success ? _rose500 : _red500,
                  ),
                );
              }
            },
            child: Text('Remove', style: TextStyle(color: _red500)),
          ),
        ],
      ),
    );
  }
}
