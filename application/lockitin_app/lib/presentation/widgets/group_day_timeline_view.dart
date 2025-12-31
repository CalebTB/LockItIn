import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/services/availability_calculator_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/time_filter_utils.dart';
import '../../data/models/event_model.dart';
import '../../data/models/group_model.dart';
import '../providers/group_provider.dart';
import '../screens/group_proposal_wizard.dart';

/// Enhanced day timeline view for group availability
/// Shows hour-by-hour timeline with member events, free slots, and member filtering
/// Based on the GroupSync day view design mockup
class GroupDayTimelineView extends StatefulWidget {
  final DateTime selectedDate;
  final DateTime focusedMonth;
  final Map<String, List<EventModel>> memberEvents;
  final Set<TimeFilter> selectedTimeFilters;
  final TimeOfDay customStartTime;
  final TimeOfDay customEndTime;
  final AvailabilityCalculatorService availabilityService;
  final String groupId;
  final String groupName;
  final VoidCallback onSwitchToMonthView;
  final Function(DateTime) onDateChanged;

  const GroupDayTimelineView({
    super.key,
    required this.selectedDate,
    required this.focusedMonth,
    required this.memberEvents,
    required this.selectedTimeFilters,
    required this.customStartTime,
    required this.customEndTime,
    required this.availabilityService,
    required this.groupId,
    required this.groupName,
    required this.onSwitchToMonthView,
    required this.onDateChanged,
  });

  @override
  State<GroupDayTimelineView> createState() => _GroupDayTimelineViewState();
}

class _GroupDayTimelineViewState extends State<GroupDayTimelineView> {
  // Timeline configuration
  static const int _startHour = 7;
  static const int _endHour = 23;
  static const double _hourHeight = 60.0;

  // Display toggles
  bool _showBusyTimes = true;
  bool _showBestTimes = true;

  // Member colors for consistent visual identification
  static const List<Color> _memberColors = [
    AppColors.memberPink,
    AppColors.memberAmber,
    AppColors.memberViolet,
    AppColors.memberCyan,
    AppColors.memberEmerald,
    AppColors.memberTeal,
  ];

  Color _getMemberColor(int index) {
    return _memberColors[index % _memberColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Column(
      children: [
        // Date navigation bar
        _buildDateNavigationBar(colorScheme, appColors),

        // Toggle row (Best times / Busy times)
        _buildToggleRow(colorScheme, appColors),

        // Timeline content
        Expanded(
          child: _buildTimeline(colorScheme, appColors),
        ),
      ],
    );
  }

  Widget _buildDateNavigationBar(ColorScheme colorScheme, AppColorsExtension appColors) {
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(widget.selectedDate);
    final isToday = _isSameDay(widget.selectedDate, DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          // Previous day button
          Semantics(
            button: true,
            label: 'Go to previous day',
            child: IconButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                widget.onDateChanged(widget.selectedDate.subtract(const Duration(days: 1)));
              },
              icon: Icon(Icons.chevron_left, color: colorScheme.primary),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
          ),

          // Date display
          Expanded(
            child: Semantics(
              header: true,
              label: 'Showing $dateStr${isToday ? ", today" : ""}',
              child: Column(
                children: [
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (isToday)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Next day button
          Semantics(
            button: true,
            label: 'Go to next day',
            child: IconButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                widget.onDateChanged(widget.selectedDate.add(const Duration(days: 1)));
              },
              icon: Icon(Icons.chevron_right, color: colorScheme.primary),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(ColorScheme colorScheme, AppColorsExtension appColors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          // Best times toggle
          Semantics(
            button: true,
            toggled: _showBestTimes,
            label: 'Best times ${_showBestTimes ? "on" : "off"}',
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _showBestTimes = !_showBestTimes);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _showBestTimes
                      ? AppColors.success.withValues(alpha: 0.15)
                      : colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: _showBestTimes ? AppColors.success : appColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Best times',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _showBestTimes ? AppColors.success : appColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),

          // Busy times toggle
          Semantics(
            button: true,
            toggled: _showBusyTimes,
            label: 'Busy times ${_showBusyTimes ? "on" : "off"}',
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _showBusyTimes = !_showBusyTimes);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _showBusyTimes
                      ? colorScheme.surfaceContainerHighest
                      : colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Busy times ${_showBusyTimes ? "ON" : "OFF"}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _showBusyTimes ? colorScheme.onSurface : appColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(ColorScheme colorScheme, AppColorsExtension appColors) {
    final dayEvents = _getEventsForDay();
    final positionedEvents = _assignEventColumns(dayEvents);
    final freeSlots = _showBestTimes ? _findFreeSlots(dayEvents) : <_TimeSlot>[];
    final hours = List.generate(_endHour - _startHour + 1, (i) => _startHour + i);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80), // Space for FAB
      child: SizedBox(
        height: (_endHour - _startHour + 1) * _hourHeight,
        child: Stack(
          children: [
            // Hour lines and labels
            ...hours.map((hour) => _buildHourLine(hour, colorScheme, appColors)),

            // Free time slots (Best times)
            if (_showBestTimes)
              ...freeSlots.map((slot) => _buildFreeSlot(slot, colorScheme, appColors)),

            // Current time indicator
            if (_isSameDay(widget.selectedDate, DateTime.now()))
              _buildCurrentTimeIndicator(colorScheme),

            // Events
            ...positionedEvents.map((event) => _buildEventBlock(event, colorScheme, appColors)),
          ],
        ),
      ),
    );
  }

  Widget _buildHourLine(int hour, ColorScheme colorScheme, AppColorsExtension appColors) {
    final top = (hour - _startHour) * _hourHeight;
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final suffix = hour >= 12 ? 'PM' : 'AM';

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '$h $suffix',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: appColors.textMuted,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: colorScheme.outline.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeSlot(_TimeSlot slot, ColorScheme colorScheme, AppColorsExtension appColors) {
    final top = (slot.startHour - _startHour) * _hourHeight + 2;
    final height = (slot.endHour - slot.startHour) * _hourHeight - 4;

    if (height < 30) return const SizedBox.shrink(); // Too small to display

    final startStr = _formatHourShort(slot.startHour);
    final endStr = _formatHourShort(slot.endHour);

    return Positioned(
      top: top,
      left: 52,
      right: 8,
      height: height,
      child: Semantics(
        button: true,
        label: 'Everyone free from $startStr to $endStr, tap to propose event',
        child: GestureDetector(
          onTap: () => _showProposeEventSheet(slot),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.4),
                width: 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Everyone free',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$startStr - $endStr',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.success.withValues(alpha: 0.8),
                    ),
                  ),
                  if (height > 70)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Tap to propose',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.success.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTimeIndicator(ColorScheme colorScheme) {
    final now = DateTime.now();
    final currentHour = now.hour + now.minute / 60;
    if (currentHour < _startHour || currentHour > _endHour) {
      return const SizedBox.shrink();
    }

    final top = (currentHour - _startHour) * _hourHeight;

    return Positioned(
      top: top,
      left: 48,
      right: 0,
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.4),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              height: 2,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventBlock(_PositionedEvent event, ColorScheme colorScheme, AppColorsExtension appColors) {
    final top = (event.startHour - _startHour) * _hourHeight + 1;
    final height = (event.endHour - event.startHour) * _hourHeight - 2;

    // Calculate available width for events (screen width minus time label and padding)
    final availableWidth = MediaQuery.of(context).size.width - 60;
    final gap = 4.0; // Gap between columns
    final totalGaps = (event.totalColumns - 1) * gap;
    final cellWidth = (availableWidth - totalGaps) / event.totalColumns;
    final left = 52.0 + event.column * (cellWidth + gap);

    // Skip very small events (less than 25px can't display content)
    if (height < 25) return const SizedBox.shrink();

    final isBusy = event.event.visibility == EventVisibility.busyOnly ||
        (event.event.title.isEmpty || event.event.title.toLowerCase() == 'busy');

    // Get member color
    final provider = context.read<GroupProvider>();
    final members = provider.selectedGroupMembers;
    final memberIndex = members.indexWhere((m) => m.userId == event.event.userId);
    final memberColor = memberIndex >= 0 ? _getMemberColor(memberIndex) : AppColors.memberPink;
    final member = memberIndex >= 0 ? members[memberIndex] : null;

    // Dynamic padding based on height
    final padding = height < 35 ? 4.0 : 6.0;

    return Positioned(
      top: top,
      left: left,
      width: cellWidth,
      height: height,
      child: Semantics(
        label: '${member?.displayName ?? "Unknown"}, ${event.event.title.isNotEmpty ? event.event.title : "Busy"}, ${_formatHourShort(event.startHour)} to ${_formatHourShort(event.endHour)}',
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            // Could show event details in future
          },
          child: Container(
            decoration: BoxDecoration(
              color: isBusy ? Colors.transparent : memberColor,
              borderRadius: BorderRadius.circular(8),
              border: isBusy
                  ? Border.all(
                      color: memberColor.withValues(alpha: 0.6),
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignInside,
                    )
                  : null,
              boxShadow: isBusy
                  ? null
                  : [
                      BoxShadow(
                        color: memberColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            padding: EdgeInsets.all(padding),
            child: _buildEventContent(
              event: event,
              height: height,
              isBusy: isBusy,
              memberColor: memberColor,
              member: member,
              appColors: appColors,
            ),
          ),
        ),
      ),
    );
  }

  /// Build event content based on available height
  Widget _buildEventContent({
    required _PositionedEvent event,
    required double height,
    required bool isBusy,
    required Color memberColor,
    required GroupMemberProfile? member,
    required AppColorsExtension appColors,
  }) {
    // For very small events, just show a colored bar with member initial
    if (height < 35) {
      return Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isBusy ? memberColor : Colors.white.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                member?.initials.isNotEmpty == true ? member!.initials[0] : '?',
                style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  color: isBusy ? Colors.white : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              isBusy ? (member?.displayName.split(' ').first ?? 'Busy') : event.event.title,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: isBusy ? appColors.textMuted : Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    // Standard content for larger events
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Member avatar (for busy events) or event title
        if (isBusy)
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: memberColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    member?.initials.isNotEmpty == true
                        ? member!.initials[0]
                        : '?',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  member?.displayName.split(' ').first ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: appColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              if (event.event.emoji != null && event.event.emoji!.isNotEmpty)
                Text(event.event.emoji!, style: const TextStyle(fontSize: 11)),
              if (event.event.emoji != null && event.event.emoji!.isNotEmpty)
                const SizedBox(width: 4),
              Expanded(
                child: Text(
                  event.event.title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

        // Location (if space)
        if (height > 50 && event.event.location != null && event.event.location!.isNotEmpty && !isBusy)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              event.event.location!,
              style: TextStyle(
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

        // Member badge (if space and not busy)
        if (height > 60 && !isBusy && member != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      member.initials.isNotEmpty ? member.initials[0] : '?',
                      style: const TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  member.displayName.split(' ').first,
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),

        // Busy label
        if (isBusy && height > 45)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Busy',
              style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: appColors.textMuted,
              ),
            ),
          ),
      ],
    );
  }

  // ========== Helper Methods ==========

  List<_PositionedEvent> _getEventsForDay() {
    final dayStart = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
    );
    final dayEnd = dayStart.add(const Duration(days: 1));

    final events = <_PositionedEvent>[];

    for (final entry in widget.memberEvents.entries) {
      final memberEventsList = entry.value;

      for (final event in memberEventsList) {
        final localStart = event.startTime.toLocal();
        final localEnd = event.endTime.toLocal();

        // Check if event overlaps with selected day
        if (localStart.isBefore(dayEnd) && localEnd.isAfter(dayStart)) {
          // Check if should show busy events
          final isBusy = event.visibility == EventVisibility.busyOnly ||
              event.title.isEmpty ||
              event.title.toLowerCase() == 'busy';
          if (!_showBusyTimes && isBusy) continue;

          // Calculate hours within the day
          final startHour = localStart.isBefore(dayStart)
              ? _startHour.toDouble()
              : localStart.hour + localStart.minute / 60;
          final endHour = localEnd.isAfter(dayEnd)
              ? _endHour.toDouble()
              : localEnd.hour + localEnd.minute / 60;

          // Clamp to visible range
          final clampedStart = startHour.clamp(_startHour.toDouble(), _endHour.toDouble());
          final clampedEnd = endHour.clamp(_startHour.toDouble(), _endHour.toDouble());

          if (clampedEnd > clampedStart) {
            events.add(_PositionedEvent(
              event: event,
              startHour: clampedStart,
              endHour: clampedEnd,
              column: 0,
              totalColumns: 1,
            ));
          }
        }
      }
    }

    return events;
  }

  List<_PositionedEvent> _assignEventColumns(List<_PositionedEvent> events) {
    if (events.isEmpty) return events;

    // Sort by start time, then by duration (longer events first for better layout)
    events.sort((a, b) {
      final startCompare = a.startHour.compareTo(b.startHour);
      if (startCompare != 0) return startCompare;
      // Longer events first (end later = longer)
      return b.endHour.compareTo(a.endHour);
    });

    // Track columns - each column is a list of events that don't overlap
    final columns = <List<_PositionedEvent>>[];

    for (final event in events) {
      bool placed = false;

      for (int col = 0; col < columns.length; col++) {
        // Check if event fits in this column (no overlap with existing events)
        final canPlace = columns[col].every((e) =>
            event.startHour >= e.endHour || event.endHour <= e.startHour);

        if (canPlace) {
          columns[col].add(event);
          event.column = col;
          placed = true;
          break;
        }
      }

      if (!placed) {
        event.column = columns.length;
        columns.add([event]);
      }
    }

    // Build overlap clusters - events that directly or transitively overlap
    // should share the same totalColumns for consistent widths
    final visited = <_PositionedEvent>{};
    final clusters = <List<_PositionedEvent>>[];

    for (final event in events) {
      if (visited.contains(event)) continue;

      // BFS to find all events in this overlap cluster
      final cluster = <_PositionedEvent>[];
      final queue = <_PositionedEvent>[event];

      while (queue.isNotEmpty) {
        final current = queue.removeAt(0);
        if (visited.contains(current)) continue;
        visited.add(current);
        cluster.add(current);

        // Find all events that overlap with current
        for (final other in events) {
          if (!visited.contains(other) &&
              current.startHour < other.endHour &&
              other.startHour < current.endHour) {
            queue.add(other);
          }
        }
      }

      if (cluster.isNotEmpty) {
        clusters.add(cluster);
      }
    }

    // For each cluster, all events get the same totalColumns
    for (final cluster in clusters) {
      final maxColumn = cluster.map((e) => e.column).reduce((a, b) => a > b ? a : b);
      final totalColumns = maxColumn + 1;
      for (final event in cluster) {
        event.totalColumns = totalColumns;
      }
    }

    return events;
  }

  List<_TimeSlot> _findFreeSlots(List<_PositionedEvent> events) {
    final slots = <_TimeSlot>[];
    double currentHour = _startHour.toDouble();

    // Sort events by start time
    final sorted = List<_PositionedEvent>.from(events)
      ..sort((a, b) => a.startHour.compareTo(b.startHour));

    for (final event in sorted) {
      if (event.startHour > currentHour) {
        // Found a gap
        final gapEnd = event.startHour;
        if (gapEnd - currentHour >= 1) {
          // At least 1 hour gap
          slots.add(_TimeSlot(
            startHour: currentHour,
            endHour: gapEnd,
          ));
        }
      }
      currentHour = currentHour > event.endHour ? currentHour : event.endHour;
    }

    // Check for gap at the end
    if (_endHour > currentHour && _endHour - currentHour >= 1) {
      slots.add(_TimeSlot(
        startHour: currentHour,
        endHour: _endHour.toDouble(),
      ));
    }

    return slots;
  }

  void _showProposeEventSheet(_TimeSlot slot) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final provider = context.read<GroupProvider>();
    final members = provider.selectedGroupMembers;

    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Propose Event',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Everyone's available!",
                          style: TextStyle(
                            fontSize: 14,
                            color: appColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: appColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Time slot info
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.schedule,
                        size: 20,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_formatHour(slot.startHour.toInt())} – ${_formatHour(slot.endHour.toInt())}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${(slot.endHour - slot.startHour).toInt()} hours available',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Members available
              Row(
                children: [
                  Icon(Icons.people_outline, size: 14, color: appColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    'All ${members.length} members available',
                    style: TextStyle(
                      fontSize: 13,
                      color: appColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  // Member avatars
                  SizedBox(
                    height: 24,
                    child: Stack(
                      children: members.take(5).toList().asMap().entries.map((entry) {
                        final index = entry.key;
                        final member = entry.value;
                        return Positioned(
                          left: index * 16.0,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _getMemberColor(index),
                              shape: BoxShape.circle,
                              border: Border.all(color: colorScheme.surface, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                member.initials.isNotEmpty ? member.initials[0] : '?',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (members.length > 5)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.surface, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '+${members.length - 5}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: appColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Create proposal button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to proposal wizard with the selected date
                    // The wizard creates a time option at 7pm-9pm for that date
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => GroupProposalWizard(
                          groupId: widget.groupId,
                          groupName: widget.groupName,
                          groupMemberCount: members.length,
                          initialDate: widget.selectedDate,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Create Event Proposal',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatHour(int hour) {
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final suffix = hour >= 12 ? 'PM' : 'AM';
    return '$h $suffix';
  }

  String _formatHourShort(double hour) {
    final h = hour.toInt();
    final display = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    final suffix = h >= 12 ? 'p' : 'a';
    return '$display$suffix';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// Helper class for positioned events in the timeline
class _PositionedEvent {
  final EventModel event;
  final double startHour;
  final double endHour;
  int column;
  int totalColumns;

  _PositionedEvent({
    required this.event,
    required this.startHour,
    required this.endHour,
    required this.column,
    required this.totalColumns,
  });
}

/// Helper class for time slots
class _TimeSlot {
  final double startHour;
  final double endHour;

  _TimeSlot({
    required this.startHour,
    required this.endHour,
  });
}
