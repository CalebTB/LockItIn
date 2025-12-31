import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/group_model.dart';
import '../../../data/models/event_model.dart';
import '../../../core/services/event_service.dart';
import '../../../core/services/availability_calculator_service.dart';
import '../../../core/utils/time_filter_utils.dart';
import '../../providers/group_provider.dart';
import '../../providers/calendar_provider.dart';
import '../../widgets/group_calendar_legend.dart';
import '../../widgets/group_members_section.dart';
import '../../widgets/group_members_sheet.dart';
import '../../widgets/group_time_filter_chips.dart';
import '../../widgets/group_date_range_filter.dart';
import '../../widgets/group_best_days_section.dart';
import 'widgets/widgets.dart';

/// Group detail screen showing group calendar with availability heatmap
/// Uses Minimal theme color system (grayscale + emerald for availability)
class GroupDetailScreen extends StatefulWidget {
  final GroupModel group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  // Colors are now accessed via Theme.of(context).colorScheme and context.appColors
  // No more hardcoded color constants

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
            backgroundColor: Theme.of(context).colorScheme.error,
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

  /// Get background color for heatmap cell based on availability ratio
  /// Uses Minimal theme: emerald for available, grayscale for unavailable
  Color _getHeatmapBackgroundColor(int available, int total, Brightness brightness) {
    if (total == 0) {
      return brightness == Brightness.dark
          ? AppColors.neutral900
          : AppColors.gray100;
    }

    final ratio = available / total;
    return AppColors.getAvailabilityColor(ratio, brightness);
  }

  /// Get text color for heatmap cell
  Color _getHeatmapTextColor(int available, int total, Brightness brightness) {
    if (total == 0) {
      return brightness == Brightness.dark
          ? AppColors.neutral500
          : AppColors.gray500;
    }

    final ratio = available / total;
    return AppColors.getAvailabilityTextColor(ratio, brightness);
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: _buildProposeFAB(colorScheme),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context, colorScheme),
                if (_memberEventsError != null) _buildErrorBanner(colorScheme, context.appColors),
                _buildMonthNavigation(colorScheme),
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
                        // Best Days section at TOP - most actionable info (#174)
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
                        // Calendar legend and heatmap
                        const GroupCalendarLegend(),
                        SizedBox(
                          height: 360,
                          child: _buildCalendarPageView(),
                        ),
                        // Members section at bottom
                        GroupMembersSection(
                          group: widget.group,
                          onInvite: () => _showInviteFlow(context),
                          onViewAllMembers: () => _showMembersSheet(context),
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
    );
  }

  Widget _buildErrorBanner(ColorScheme colorScheme, AppColorsExtension appColors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colorScheme.error.withValues(alpha: 0.15),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 18, color: appColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _memberEventsError ?? 'Error loading availability',
              style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
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
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          // Back button with haptic and accessibility
          Semantics(
            button: true,
            label: 'Go back',
            child: IconButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.chevron_left, size: 24),
              color: colorScheme.onSurface,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Go back',
            ),
          ),
          const SizedBox(width: 8),
          // Group emoji badge (excluded from semantics - decorative)
          ExcludeSemantics(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  widget.group.emoji,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Group name with semantic header
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                widget.group.name,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
          // Members button with haptic and accessibility
          Semantics(
            button: true,
            label: 'View ${widget.group.memberCount} members',
            child: IconButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                _showMembersSheet(context);
              },
              icon: const Icon(Icons.people_rounded, size: 20),
              color: colorScheme.onSurfaceVariant,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'View members',
            ),
          ),
          // Settings menu with accessibility
          Semantics(
            button: true,
            label: 'More options',
            child: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              tooltip: 'More options',
              padding: EdgeInsets.zero,
              onSelected: (value) => _handleMenuAction(value, context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: colorScheme.surfaceContainerHigh,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_rounded, size: 18, color: colorScheme.onSurface),
                    const SizedBox(width: 10),
                    Text('Group settings', style: TextStyle(color: colorScheme.onSurface)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share_rounded, size: 18, color: colorScheme.onSurface),
                    const SizedBox(width: 10),
                    Text('Share group', style: TextStyle(color: colorScheme.onSurface)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app_rounded, size: 18, color: colorScheme.error),
                    const SizedBox(width: 10),
                    Text('Leave group', style: TextStyle(color: colorScheme.error)),
                  ],
                ),
              ),
            ],
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, BuildContext context) {
    HapticFeedback.selectionClick();
    final colorScheme = Theme.of(context).colorScheme;

    switch (action) {
      case 'settings':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Group settings coming soon!'),
            backgroundColor: colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        break;
      case 'share':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Share group coming soon!'),
            backgroundColor: colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        break;
      case 'leave':
        _showLeaveGroupConfirmation(context);
        break;
    }
  }

  void _showLeaveGroupConfirmation(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Leave ${widget.group.name}?',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: Text(
          'You will no longer be able to see group availability or receive event proposals.',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.of(context).pop();
              _leaveGroup(context);
            },
            child: Text(
              'Leave',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _leaveGroup(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final groupName = widget.group.name;
    final groupId = widget.group.id;
    final provider = context.read<GroupProvider>();

    try {
      await provider.leaveGroup(groupId);
      if (mounted) {
        navigator.pop(); // Go back to groups list
        messenger.showSnackBar(
          SnackBar(
            content: Text('Left $groupName'),
            backgroundColor: colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Could not leave group'),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Widget _buildMonthNavigation(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _previousMonth,
            icon: const Icon(Icons.chevron_left, size: 24),
            color: colorScheme.onSurfaceVariant,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Text(
            DateFormat('MMMM yyyy').format(_focusedMonth),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          IconButton(
            onPressed: _nextMonth,
            icon: const Icon(Icons.chevron_right, size: 24),
            color: colorScheme.onSurfaceVariant,
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

    // Today reference for highlighting and past day detection
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Consumer2<CalendarProvider, GroupProvider>(
      builder: (context, calendarProvider, groupProvider, _) {
        final colorScheme = Theme.of(context).colorScheme;
        final appColors = context.appColors;
        final brightness = Theme.of(context).brightness;
        final totalMembers = groupProvider.selectedGroupMembers.isNotEmpty
            ? groupProvider.selectedGroupMembers.length
            : (groupProvider.selectedGroup?.memberCount ?? 1);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              // Day headers with improved styling
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Row(
                  children: days.asMap().entries.map((entry) {
                    final index = entry.key;
                    final day = entry.value;
                    // Highlight weekend headers slightly differently
                    final isWeekend = index == 0 || index == 6;
                    return Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isWeekend
                                ? appColors.textMuted
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: 42,
                  itemBuilder: (context, index) {
                    final dayNumber = index - startWeekday + 1;

                    if (dayNumber < 1 || dayNumber > daysInMonth) {
                      return const SizedBox.shrink();
                    }

                    final date = DateTime(month.year, month.month, dayNumber);
                    final isToday = date.isAtSameMomentAs(today);
                    final isPast = date.isBefore(today);
                    final isSelected = _selectedDay == dayNumber &&
                        month.month == _focusedMonth.month;

                    final isInRange = _selectedDateRange == null ||
                        (!date.isBefore(_selectedDateRange!.start) &&
                         !date.isAfter(_selectedDateRange!.end));

                    // Don't calculate availability for past days
                    final available = (isInRange && !isPast)
                        ? _getAvailabilityForDay(calendarProvider, date)
                        : 0;

                    final isFullyAvailable = isInRange && !isPast &&
                        available == totalMembers && totalMembers > 0;

                    // Determine colors based on state
                    final CellColors cellColors = _getCellColors(
                      isPast: isPast,
                      isToday: isToday,
                      isSelected: isSelected,
                      isInRange: isInRange,
                      isFullyAvailable: isFullyAvailable,
                      available: available,
                      totalMembers: totalMembers,
                      brightness: brightness,
                      colorScheme: colorScheme,
                      appColors: appColors,
                    );

                    return GestureDetector(
                      onTap: isPast
                          ? null // Disable tap for past days
                          : () {
                              // Haptic feedback on selection
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedDay = dayNumber;
                                _focusedMonth = month;
                              });
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOut,
                        decoration: BoxDecoration(
                          color: cellColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: _getCellBorder(
                            isToday: isToday,
                            isSelected: isSelected,
                            colorScheme: colorScheme,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                  ),
                                ]
                              : null,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Today indicator dot (top-right)
                            if (isToday && !isSelected)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            // Main content
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$dayNumber',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isToday || isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: cellColors.text,
                                  ),
                                ),
                                if (!isPast && isInRange)
                                  _isLoadingMemberEvents
                                      ? Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: SizedBox(
                                            width: 8,
                                            height: 8,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.5,
                                              color: cellColors.text.withValues(alpha: 0.5),
                                            ),
                                          ),
                                        )
                                      : Padding(
                                          padding: const EdgeInsets.only(top: 1),
                                          child: Text(
                                            '$available/$totalMembers',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              color: cellColors.subtext,
                                            ),
                                          ),
                                        ),
                              ],
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

  /// Get cell border based on state
  Border? _getCellBorder({
    required bool isToday,
    required bool isSelected,
    required ColorScheme colorScheme,
  }) {
    if (isSelected) {
      return Border.all(color: colorScheme.primary, width: 2.5);
    }
    if (isToday) {
      return Border.all(color: colorScheme.primary.withValues(alpha: 0.5), width: 1.5);
    }
    return null;
  }

  /// Get colors for a calendar cell based on its state
  CellColors _getCellColors({
    required bool isPast,
    required bool isToday,
    required bool isSelected,
    required bool isInRange,
    required bool isFullyAvailable,
    required int available,
    required int totalMembers,
    required Brightness brightness,
    required ColorScheme colorScheme,
    required AppColorsExtension appColors,
  }) {
    // Past days - dimmed
    if (isPast) {
      return CellColors(
        background: colorScheme.surfaceContainerLow,
        text: appColors.textDisabled,
        subtext: appColors.textDisabled,
      );
    }

    // Not in selected date range
    if (!isInRange) {
      return CellColors(
        background: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        text: colorScheme.onSurface.withValues(alpha: 0.3),
        subtext: colorScheme.onSurface.withValues(alpha: 0.2),
      );
    }

    // Fully available - emerald highlight
    if (isFullyAvailable) {
      return CellColors(
        background: AppColors.success,
        text: Colors.white,
        subtext: Colors.white.withValues(alpha: 0.9),
      );
    }

    // Partial availability - use heatmap colors
    final backgroundColor = _getHeatmapBackgroundColor(available, totalMembers, brightness);
    final textColor = _getHeatmapTextColor(available, totalMembers, brightness);

    return CellColors(
      background: backgroundColor,
      text: textColor,
      subtext: textColor.withValues(alpha: 0.8),
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
    final provider = context.read<GroupProvider>();
    final members = provider.selectedGroupMembers;

    GroupMembersSheet.show(
      context: context,
      group: widget.group,
      members: members,
      currentUserId: _getCurrentUserId(),
    );
  }

  String? _getCurrentUserId() {
    return SupabaseClientManager.currentUserId;
  }

  /// FAB for proposing a new event - primary action for this screen
  Widget _buildProposeFAB(ColorScheme colorScheme) {
    return Semantics(
      button: true,
      label: 'Propose a new event for ${widget.group.name}',
      child: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showProposeEventFlow(context);
        },
        tooltip: 'Propose a new event',
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Propose',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _showProposeEventFlow(BuildContext context) {
    // TODO: Navigate to propose event screen with pre-filled group
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Event proposal coming soon!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showInviteFlow(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Invite flow coming soon!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

/// Helper class to hold cell colors for the heatmap calendar
class CellColors {
  final Color background;
  final Color text;
  final Color subtext;

  const CellColors({
    required this.background,
    required this.text,
    required this.subtext,
  });
}
