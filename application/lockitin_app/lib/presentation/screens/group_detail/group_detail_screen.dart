import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/group_model.dart';
import '../../../data/models/event_model.dart';
import '../../../core/services/event_service.dart';
import '../../../core/services/availability_calculator_service.dart';
import '../../../core/utils/time_filter_utils.dart';
import '../../providers/group_provider.dart';
import '../../widgets/group_calendar_legend.dart';
import '../../widgets/group_members_sheet.dart';
import '../../widgets/group_filters_sheet.dart';
import '../../widgets/group_best_days_section.dart';
import '../../widgets/group_settings_sheet.dart';
import '../../widgets/group_day_timeline_view.dart';
import '../group_proposal_wizard.dart';
import 'widgets/widgets.dart';
import 'widgets/proposal_list_view.dart';

/// View modes for the group detail screen calendar
enum GroupCalendarViewMode { month, day }

/// Day view style options - allows A/B testing between old and new designs
enum DayViewStyle {
  /// New full-screen timeline with member filtering
  timeline,
  /// Classic bottom sheet overlay
  classic,
}

/// Group detail screen showing group calendar with availability heatmap
/// Uses Minimal theme color system (grayscale + emerald for availability)
class GroupDetailScreen extends StatefulWidget {
  final GroupModel group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  final _availabilityService = AvailabilityCalculatorService();

  GroupCalendarViewMode _viewMode = GroupCalendarViewMode.month;
  DayViewStyle _dayViewStyle = DayViewStyle.timeline;

  late DateTime _focusedMonth;
  DateTime? _selectedDate;
  int? _selectedDay;
  late PageController _pageController;
  late TabController _tabController;
  Set<TimeFilter> _selectedTimeFilters = {TimeFilter.allDay};
  DateTimeRange? _selectedDateRange;

  TimeOfDay _customStartTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _customEndTime = const TimeOfDay(hour: 17, minute: 0);

  Map<String, List<EventModel>> _memberEvents = {};
  bool _isLoadingMemberEvents = false;
  String? _memberEventsError;

  final Map<String, int> _availabilityCache = {};

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
    _pageController = PageController(initialPage: 12);
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGroupData();
    });
  }

  Future<void> _initializeGroupData() async {
    final groupProvider = context.read<GroupProvider>();
    await groupProvider.selectGroup(widget.group.id);
    await _loadMemberEvents();
  }

  Future<void> _loadMemberEvents() async {
    final groupProvider = context.read<GroupProvider>();
    final members = groupProvider.selectedGroupMembers;

    if (members.isEmpty) return;

    setState(() {
      _isLoadingMemberEvents = true;
      _memberEventsError = null;
    });

    try {
      final memberIds = members.map((m) => m.userId).toList();
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
          _clearAvailabilityCache();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMemberEvents = false;
          _memberEventsError = 'Failed to load member availability';
        });
        _showErrorSnackBar('Could not load group availability');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _loadMemberEvents,
        ),
      ),
    );
  }

  int _getAvailabilityForDay(DateTime date) {
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    if (_availabilityCache.containsKey(key)) {
      return _availabilityCache[key]!;
    }

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

  void _clearAvailabilityCache() => _availabilityCache.clear();

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
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

  /// Jump to a specific month, keeping PageController and _focusedMonth in sync
  void _jumpToMonth(DateTime targetMonth) {
    // If in day view mode, just update _focusedMonth directly
    // (PageController is only attached in month view)
    if (_viewMode == GroupCalendarViewMode.day) {
      setState(() {
        _focusedMonth = DateTime(targetMonth.year, targetMonth.month);
      });
      return;
    }

    final now = DateTime.now();
    final monthDiff = (targetMonth.year - now.year) * 12 + (targetMonth.month - now.month);
    final targetPage = 12 + monthDiff;

    // Clamp to valid page range [0, 23]
    if (targetPage >= 0 && targetPage < 24) {
      _pageController.jumpToPage(targetPage);
      // _focusedMonth will be updated via onPageChanged callback
    }
  }

  void _switchToDayView(DateTime date) {
    HapticFeedback.selectionClick();
    setState(() {
      _viewMode = GroupCalendarViewMode.day;
      _selectedDate = date;
      _selectedDay = date.day;
      // Keep focusedMonth in sync with the date being viewed
      _focusedMonth = DateTime(date.year, date.month);
    });
  }

  void _switchToMonthView() {
    HapticFeedback.selectionClick();

    // Determine target month BEFORE setState
    // Use selectedDate's month if available, otherwise keep current focusedMonth
    final DateTime targetMonth;
    if (_selectedDate != null) {
      targetMonth = DateTime(_selectedDate!.year, _selectedDate!.month);
    } else {
      targetMonth = _focusedMonth;
    }

    setState(() {
      _viewMode = GroupCalendarViewMode.month;
      // Update focusedMonth immediately to match the date we're showing
      _focusedMonth = targetMonth;
      if (_selectedDate != null) {
        _selectedDay = _selectedDate!.day;
      }
    });

    // Jump PageController to correct page AFTER rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _jumpToMonth(targetMonth);
      }
    });
  }

  void _handleViewModeChanged(GroupCalendarViewMode mode) {
    if (mode == GroupCalendarViewMode.day) {
      // Determine which date to show in day view
      DateTime dateToShow;
      if (_selectedDate != null) {
        // Use existing selected date
        dateToShow = _selectedDate!;
      } else {
        // No date selected yet - check if we're in current month
        final today = DateTime.now();
        final isFocusedMonthCurrent =
            _focusedMonth.year == today.year && _focusedMonth.month == today.month;

        if (isFocusedMonthCurrent && _selectedDay == null) {
          // In current month with no selection - show today
          dateToShow = today;
        } else {
          // In different month or have a selected day - use that
          dateToShow = DateTime(_focusedMonth.year, _focusedMonth.month, _selectedDay ?? 1);
        }
      }
      _switchToDayView(dateToShow);
    } else {
      _switchToMonthView();
    }
  }

  void _handleDayViewStyleToggle() {
    HapticFeedback.selectionClick();
    final wasTimeline = _dayViewStyle == DayViewStyle.timeline;
    final wasInDayView = _viewMode == GroupCalendarViewMode.day;

    // Determine the target month BEFORE setState
    // If coming from day view, use selectedDate; otherwise use focusedMonth
    final DateTime targetMonth;
    if (wasTimeline && wasInDayView && _selectedDate != null) {
      targetMonth = DateTime(_selectedDate!.year, _selectedDate!.month);
    } else {
      targetMonth = DateTime(_focusedMonth.year, _focusedMonth.month);
    }

    setState(() {
      _dayViewStyle = wasTimeline ? DayViewStyle.classic : DayViewStyle.timeline;
      _viewMode = GroupCalendarViewMode.month;

      // When switching to month view, preserve _selectedDate but clear _selectedDay
      // This prevents the day detail sheet from auto-opening in classic view
      if (wasTimeline && wasInDayView && _selectedDate != null) {
        // Coming from timeline day view - preserve selectedDate, clear selectedDay
        // (selectedDate will be used if user switches back to day view)
        _selectedDay = null;
      } else {
        // Coming from month view - ensure we have a selectedDate for later
        if (_selectedDate == null) {
          // No date selected - set selectedDate to today if in current month, else day 1
          final today = DateTime.now();
          final isFocusedMonthCurrent =
              _focusedMonth.year == today.year && _focusedMonth.month == today.month;

          final day = _selectedDay ?? (isFocusedMonthCurrent ? today.day : 1);
          _selectedDate = DateTime(_focusedMonth.year, _focusedMonth.month, day);
        }
        // Clear selectedDay to prevent day detail sheet from auto-opening
        _selectedDay = null;
      }
    });

    // ALWAYS jump PageController to correct page AFTER new PageView is built
    // This is critical because PageController may reset to initialPage during widget rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _jumpToMonth(targetMonth);
      }
    });
  }

  void _showSnackBar(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    if (_dayViewStyle == DayViewStyle.classic) {
      return _buildClassicLayout(colorScheme, appColors);
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: _selectedDay == null
          ? ProposeFAB(
              groupName: widget.group.name,
              onPressed: () => _showProposeEventFlow(context),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            GroupDetailHeader(
              group: widget.group,
              selectedDateRange: _selectedDateRange,
              selectedTimeFilters: _selectedTimeFilters,
              onBackPressed: () => Navigator.of(context).pop(),
              onFilterPressed: () => _showFiltersSheet(context),
              onMembersPressed: () => _showMembersSheet(context),
              onSettingsPressed: () => _showSettingsSheet(context),
            ),
            if (_memberEventsError != null)
              ErrorBanner(
                errorMessage: _memberEventsError,
                onRetry: _loadMemberEvents,
              ),
            TabBar(
              controller: _tabController,
              labelColor: colorScheme.primary,
              unselectedLabelColor: appColors.textSecondary,
              indicatorColor: colorScheme.primary,
              tabs: const [
                Tab(
                  text: 'Calendar',
                  icon: Icon(Icons.calendar_month_rounded),
                ),
                Tab(
                  text: 'Proposals',
                  icon: Icon(Icons.how_to_vote_rounded),
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Calendar (existing content with month/day logic)
                  _viewMode == GroupCalendarViewMode.month
                      ? Column(
                          children: [
                            ViewModeToggle(
                              viewMode: _viewMode,
                              dayViewStyle: _dayViewStyle,
                              onViewModeChanged: _handleViewModeChanged,
                              onDayViewStyleToggle: _handleDayViewStyleToggle,
                            ),
                            Expanded(
                              child: _buildMonthView(colorScheme, appColors),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            ViewModeToggle(
                              viewMode: _viewMode,
                              dayViewStyle: _dayViewStyle,
                              onViewModeChanged: _handleViewModeChanged,
                              onDayViewStyleToggle: _handleDayViewStyleToggle,
                            ),
                            Expanded(
                              child: _buildDayView(),
                            ),
                          ],
                        ),

                  // Tab 2: Proposals (new)
                  ProposalListView(
                    groupId: widget.group.id,
                    groupName: widget.group.name,
                    groupMemberCount: widget.group.memberCount,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassicLayout(ColorScheme colorScheme, AppColorsExtension appColors) {
    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: _selectedDay == null
          ? ProposeFAB(
              groupName: widget.group.name,
              onPressed: () => _showProposeEventFlow(context),
            )
          : null,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                GroupDetailHeader(
                  group: widget.group,
                  selectedDateRange: _selectedDateRange,
                  selectedTimeFilters: _selectedTimeFilters,
                  onBackPressed: () => Navigator.of(context).pop(),
                  onFilterPressed: () => _showFiltersSheet(context),
                  onMembersPressed: () => _showMembersSheet(context),
                  onSettingsPressed: () => _showSettingsSheet(context),
                ),
                if (_memberEventsError != null)
                  ErrorBanner(
                    errorMessage: _memberEventsError,
                    onRetry: _loadMemberEvents,
                  ),
                ClassicModeToggleBar(
                  onSwitchToTimeline: () {
                    HapticFeedback.selectionClick();

                    // Capture focusedMonth before setState (PageController may lose position during rebuild)
                    final targetMonth = DateTime(_focusedMonth.year, _focusedMonth.month);

                    setState(() {
                      _dayViewStyle = DayViewStyle.timeline;
                      _viewMode = GroupCalendarViewMode.month;

                      // Sync selectedDate to match the current focusedMonth
                      if (_selectedDate == null) {
                        // No date selected - default to today if in current month, else day 1
                        final today = DateTime.now();
                        final isFocusedMonthCurrent =
                            _focusedMonth.year == today.year && _focusedMonth.month == today.month;

                        final day = _selectedDay ?? (isFocusedMonthCurrent ? today.day : 1);
                        _selectedDate = DateTime(_focusedMonth.year, _focusedMonth.month, day);
                      }
                      // Clear selectedDay to prevent day detail sheet from auto-opening in classic view
                      _selectedDay = null;
                    });

                    // Jump PageController to correct page AFTER new PageView is built
                    // This is needed because PageController may reset to initialPage during widget rebuild
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_pageController.hasClients) {
                        _jumpToMonth(targetMonth);
                      }
                    });
                  },
                ),
                MonthNavigation(
                  focusedMonth: _focusedMonth,
                  onPreviousMonth: _previousMonth,
                  onNextMonth: _nextMonth,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildBestDaysSection(),
                        const GroupCalendarLegend(),
                        SizedBox(
                          height: 380,
                          child: _buildCalendarPageView(),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_selectedDay != null) ...[
              GestureDetector(
                onTap: () => setState(() => _selectedDay = null),
                child: Container(color: Colors.black.withValues(alpha: 0.6)),
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
                groupId: widget.group.id,
                groupName: widget.group.name,
                groupMemberCount: widget.group.memberCount,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMonthView(ColorScheme colorScheme, AppColorsExtension appColors) {
    return SingleChildScrollView(
      child: Column(
        children: [
          MonthNavigation(
            focusedMonth: _focusedMonth,
            onPreviousMonth: _previousMonth,
            onNextMonth: _nextMonth,
          ),
          _buildBestDaysSection(),
          const GroupCalendarLegend(),
          SizedBox(
            height: 380,
            child: _buildCalendarPageView(),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildBestDaysSection() {
    return GroupBestDaysSection(
      focusedMonth: _focusedMonth,
      selectedTimeFilters: _selectedTimeFilters,
      customStartTime: _customStartTime,
      customEndTime: _customEndTime,
      getBestDaysForFilters: (filters) => _getBestDaysForFilters(filters),
      onDaySelected: (day) => _dayViewStyle == DayViewStyle.classic
          ? setState(() => _selectedDay = day)
          : _switchToDayView(DateTime(_focusedMonth.year, _focusedMonth.month, day)),
      getAvailabilityForDay: _getAvailabilityForDay,
      getTotalMembers: _getTotalMemberCount,
      getUnavailableMembersForDay: _getUnavailableMembersForDate,
    );
  }

  Widget _buildDayView() {
    return GroupDayTimelineView(
      selectedDate: _selectedDate ?? DateTime.now(),
      focusedMonth: _focusedMonth,
      memberEvents: _memberEvents,
      selectedTimeFilters: _selectedTimeFilters,
      customStartTime: _customStartTime,
      customEndTime: _customEndTime,
      availabilityService: _availabilityService,
      groupId: widget.group.id,
      groupName: widget.group.name,
      onSwitchToMonthView: _switchToMonthView,
      onDateChanged: (date) {
        setState(() {
          _selectedDate = date;
          // If month changed, jump PageController to keep it in sync
          if (date.month != _focusedMonth.month || date.year != _focusedMonth.year) {
            _jumpToMonth(DateTime(date.year, date.month));
          }
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
        return GroupCalendarGrid(
          month: month,
          selectedDate: _selectedDate,
          selectedDateRange: _selectedDateRange,
          dayViewStyle: _dayViewStyle,
          isLoadingMemberEvents: _isLoadingMemberEvents,
          getAvailabilityForDay: _getAvailabilityForDay,
          onDayTapped: _switchToDayView,
          onDaySelected: (day) => setState(() {
            _selectedDay = day;
            _selectedDate = DateTime(month.year, month.month, day);
            // Note: _focusedMonth is already correct (set by PageView.onPageChanged)
            // No need to manually sync - PageController is source of truth
          }),
        );
      },
    );
  }

  List<int> _getBestDaysForFilters(Set<TimeFilter> filters) {
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

  int _getTotalMemberCount() {
    final groupProvider = context.read<GroupProvider>();
    return groupProvider.selectedGroupMembers.isNotEmpty
        ? groupProvider.selectedGroupMembers.length
        : (groupProvider.selectedGroup?.memberCount ?? 1);
  }

  List<GroupMemberProfile> _getUnavailableMembersForDate(DateTime date) {
    final groupProvider = context.read<GroupProvider>();
    final members = groupProvider.selectedGroupMembers;
    final unavailable = <GroupMemberProfile>[];

    for (final member in members) {
      final memberEventList = _memberEvents[member.userId] ?? [];
      final isBusy = _availabilityService.isMemberBusyOnDate(
        events: memberEventList,
        date: date,
        timeFilters: _selectedTimeFilters,
        customStartTime: _customStartTime,
        customEndTime: _customEndTime,
      );
      if (isBusy) unavailable.add(member);
    }

    return unavailable;
  }

  void _showFiltersSheet(BuildContext context) {
    GroupFiltersSheet.show(
      context: context,
      dateRange: _selectedDateRange,
      timeFilters: _selectedTimeFilters,
      customStartTime: _customStartTime,
      customEndTime: _customEndTime,
      onDateRangeChanged: (range) {
        setState(() {
          _selectedDateRange = range;
          _clearAvailabilityCache();
        });
      },
      onTimeFiltersChanged: (filters) {
        setState(() {
          _selectedTimeFilters = filters;
          _clearAvailabilityCache();
        });
      },
      onCustomTimeChanged: (start, end) {
        setState(() {
          _customStartTime = start;
          _customEndTime = end;
          _clearAvailabilityCache();
        });
      },
    );
  }

  void _showMembersSheet(BuildContext context) {
    final provider = context.read<GroupProvider>();
    final members = provider.selectedGroupMembers;

    GroupMembersSheet.show(
      context: context,
      group: widget.group,
      members: members,
      currentUserId: SupabaseClientManager.currentUserId,
      onMembersChanged: () {
        // Refresh member list after members are added
        provider.loadGroupMembers(widget.group.id);
      },
    );
  }

  void _showSettingsSheet(BuildContext context) {
    GroupSettingsSheet.show(
      context: context,
      group: widget.group,
      onRename: () => _showSnackBar('Rename group coming soon!'),
      onNotifications: () => _showSnackBar('Notification settings coming soon!'),
      onPrivacy: () => _showSnackBar('Privacy settings coming soon!'),
      onShare: () => _showSnackBar('Share group coming soon!'),
      onLeave: () => _showLeaveGroupConfirmation(context),
    );
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
            child: Text('Cancel', style: TextStyle(color: colorScheme.primary)),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.of(context).pop();
              _leaveGroup(context);
            },
            child: Text('Leave', style: TextStyle(color: colorScheme.error)),
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
        navigator.pop();
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

  void _showProposeEventFlow(BuildContext context) {
    final groupProvider = context.read<GroupProvider>();
    final members = groupProvider.selectedGroupMembers;
    final memberCount = members.length;
    final memberIds = members.map((m) => m.userId).toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GroupProposalWizard(
          groupId: widget.group.id,
          groupName: widget.group.name,
          groupMemberCount: memberCount > 0 ? memberCount : 1,
          initialDate: _selectedDay != null
              ? DateTime(_focusedMonth.year, _focusedMonth.month, _selectedDay!)
              : null,
          memberEvents: _memberEvents,
          memberIds: memberIds,
        ),
      ),
    );
  }
}
