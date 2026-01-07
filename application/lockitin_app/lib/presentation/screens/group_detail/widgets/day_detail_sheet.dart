import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/availability_calculator_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/route_transitions.dart';
import '../../../../core/utils/time_filter_utils.dart';
import '../../../../data/models/event_model.dart';
import '../../../../data/models/group_model.dart';
import '../../../providers/group_provider.dart';
import '../../../widgets/suggested_time_slots_card.dart';
import '../../group_proposal_wizard.dart';

/// Bottom sheet showing detailed availability for a selected day
/// Uses Minimal theme color system (grayscale + emerald for availability)
///
/// Features:
/// - Visual date header with day of week
/// - Availability progress indicator
/// - Suggested time slots
/// - Member list grouped by availability
/// - Propose event action
class DayDetailSheet extends StatelessWidget {
  final DateTime date;
  final DateTime focusedMonth;
  final int? selectedDay;
  final VoidCallback onClose;
  final Map<String, List<EventModel>> memberEvents;
  final Set<TimeFilter> selectedTimeFilters;
  final TimeOfDay customStartTime;
  final TimeOfDay customEndTime;
  final AvailabilityCalculatorService availabilityService;
  final String groupId;
  final String groupName;
  final int groupMemberCount;

  const DayDetailSheet({
    super.key,
    required this.date,
    required this.focusedMonth,
    required this.selectedDay,
    required this.onClose,
    required this.memberEvents,
    required this.selectedTimeFilters,
    required this.customStartTime,
    required this.customEndTime,
    required this.availabilityService,
    required this.groupId,
    required this.groupName,
    required this.groupMemberCount,
  });

  /// Calculate how many group members are available on this date
  int _getAvailabilityForDay() {
    return availabilityService.calculateGroupAvailability(
      memberEvents: memberEvents,
      date: date,
      timeFilters: selectedTimeFilters,
      customStartTime: customStartTime,
      customEndTime: customEndTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final groupProvider = context.read<GroupProvider>();
    final totalMembers = groupProvider.selectedGroupMembers.isNotEmpty
        ? groupProvider.selectedGroupMembers.length
        : memberEvents.length;
    final available = _getAvailabilityForDay();
    final availabilityRatio = totalMembers > 0 ? available / totalMembers : 0.0;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          // Swipe down to dismiss
          if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
            HapticFeedback.lightImpact();
            onClose();
          }
        },
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar - tap to close
              _buildHandle(colorScheme, appColors),

              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with date and availability
                      _buildHeader(context, colorScheme, appColors, available, totalMembers, availabilityRatio),

                      const SizedBox(height: 20),

                      // Suggested time slots section
                      _buildSectionHeader('Suggested Times', colorScheme, appColors),
                      _buildSuggestedTimeSlots(context, colorScheme),

                      const SizedBox(height: 20),

                      // Collapsible member availability section
                      _CollapsibleMemberSection(
                        memberEvents: memberEvents,
                        date: date,
                        selectedTimeFilters: selectedTimeFilters,
                        customStartTime: customStartTime,
                        customEndTime: customEndTime,
                        availabilityService: availabilityService,
                      ),

                      // Propose event button
                      _buildProposeButton(context, colorScheme, available, totalMembers),

                      // Safe area padding
                      SizedBox(height: bottomPadding + 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(ColorScheme colorScheme, AppColorsExtension appColors) {
    final formattedDate = DateFormat('EEEE, MMMM d').format(date);

    return Semantics(
      button: true,
      label: 'Close day details for $formattedDate',
      child: GestureDetector(
        onTap: onClose,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          color: Colors.transparent,
          child: Center(
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Swipe down or tap to close',
                  style: TextStyle(
                    fontSize: 10,
                    color: appColors.textDisabled,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
    int available,
    int totalMembers,
    double availabilityRatio,
  ) {
    final dayOfWeek = DateFormat('EEEE').format(date);
    final monthDay = DateFormat('MMMM d').format(date);
    final isFullyAvailable = available == totalMembers && totalMembers > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date badge
          Container(
            width: 64,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isFullyAvailable
                  ? AppColors.success
                  : colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isFullyAvailable
                    ? AppColors.success
                    : colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('MMM').format(date).toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: isFullyAvailable
                        ? Colors.white.withValues(alpha: 0.9)
                        : appColors.textMuted,
                  ),
                ),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: isFullyAvailable
                        ? Colors.white
                        : colorScheme.onSurface,
                  ),
                ),
                Text(
                  dayOfWeek.substring(0, 3),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isFullyAvailable
                        ? Colors.white.withValues(alpha: 0.9)
                        : appColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Info and progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthDay,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dayOfWeek,
                  style: TextStyle(
                    fontSize: 14,
                    color: appColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),

                // Availability progress bar
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isFullyAvailable
                                    ? Icons.celebration_rounded
                                    : Icons.people_rounded,
                                size: 14,
                                color: isFullyAvailable
                                    ? AppColors.success
                                    : appColors.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$available of $totalMembers available',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isFullyAvailable
                                      ? AppColors.success
                                      : colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: availabilityRatio,
                              minHeight: 6,
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation(
                                availabilityRatio >= 0.75
                                    ? AppColors.success
                                    : availabilityRatio >= 0.5
                                        ? AppColors.warning
                                        : colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Close button
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              onClose();
            },
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: 18, color: colorScheme.onSurfaceVariant),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme, AppColorsExtension appColors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: appColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildSuggestedTimeSlots(BuildContext context, ColorScheme colorScheme) {
    final groupProvider = context.read<GroupProvider>();
    final members = groupProvider.selectedGroupMembers;

    // Calculate time range from selected filters
    int startHour = 8;
    int endHour = 22;

    if (selectedTimeFilters.contains(TimeFilter.allDay)) {
      startHour = customStartTime.hour;
      endHour = customEndTime.hour;
    } else if (selectedTimeFilters.isNotEmpty) {
      startHour = selectedTimeFilters
          .map((f) => f.startHour)
          .reduce((a, b) => a < b ? a : b);
      endHour = selectedTimeFilters
          .map((f) => f.endHour)
          .reduce((a, b) => a > b ? a : b);
      if (endHour < startHour) {
        endHour = 24;
      }
    }

    // Use consolidated time slots (merges adjacent hours with same availability)
    // e.g., 9am-10am + 10am-11am (both 8/8) → 9am-11am (8/8)
    final timeSlots = availabilityService.findConsolidatedTimeSlots(
      memberEvents: memberEvents,
      date: date,
      startHour: startHour,
      endHour: endHour,
    );

    return SuggestedTimeSlotsCard(
      date: date,
      timeSlots: timeSlots,
      members: members,
      onSlotSelected: (slot) {
        HapticFeedback.selectionClick();

        // Navigate to proposal wizard with pre-filled time from suggested slot
        Navigator.of(context).push(
          SlideRoute(
            page: GroupProposalWizard(
              groupId: groupId,
              groupName: groupName,
              groupMemberCount: groupMemberCount,
              initialDate: date,
              initialStartTime: slot.startTime,
              initialEndTime: slot.endTime,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProposeButton(
    BuildContext context,
    ColorScheme colorScheme,
    int available,
    int totalMembers,
  ) {
    final shouldShowButton = available >= (totalMembers * 0.5).ceil() && totalMembers > 0;

    if (!shouldShowButton) {
      return const SizedBox(height: 12);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            HapticFeedback.mediumImpact();

            // Navigate to proposal wizard with selected date
            Navigator.of(context).push(
              SlideRoute(
                page: GroupProposalWizard(
                  groupId: groupId,
                  groupName: groupName,
                  groupMemberCount: groupMemberCount,
                  initialDate: date,
                ),
              ),
            );
          },
          icon: const Icon(Icons.add_circle_outline, size: 20),
          label: Text(
            'Propose Event for ${DateFormat('MMM d').format(date)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}

/// Collapsible section showing member availability
/// Starts expanded by default, can be collapsed to save space
class _CollapsibleMemberSection extends StatefulWidget {
  final Map<String, List<EventModel>> memberEvents;
  final DateTime date;
  final Set<TimeFilter> selectedTimeFilters;
  final TimeOfDay customStartTime;
  final TimeOfDay customEndTime;
  final AvailabilityCalculatorService availabilityService;

  const _CollapsibleMemberSection({
    required this.memberEvents,
    required this.date,
    required this.selectedTimeFilters,
    required this.customStartTime,
    required this.customEndTime,
    required this.availabilityService,
  });

  @override
  State<_CollapsibleMemberSection> createState() => _CollapsibleMemberSectionState();
}

class _CollapsibleMemberSectionState extends State<_CollapsibleMemberSection> {
  bool _isExpanded = true;

  /// Check if a specific member is available on the date
  bool _isMemberAvailableOnDate(String memberId) {
    final memberEventsList = widget.memberEvents[memberId] ?? [];
    final dayStart = DateTime(widget.date.year, widget.date.month, widget.date.day, 0, 0);
    final dayEnd = DateTime(widget.date.year, widget.date.month, widget.date.day, 23, 59, 59);

    final eventsOnDate = memberEventsList
        .where((e) {
          final localStart = e.startTime.toLocal();
          final localEnd = e.endTime.toLocal();
          return localStart.isBefore(dayEnd) && localEnd.isAfter(dayStart);
        })
        .where((e) => e.category != EventCategory.holiday)
        .toList();

    return widget.availabilityService.isMemberAvailable(
      events: eventsOnDate,
      date: widget.date,
      timeFilters: widget.selectedTimeFilters,
      customStartTime: widget.customStartTime,
      customEndTime: widget.customEndTime,
    );
  }

  /// Get a human-readable description of availability for a specific member
  String _getMemberAvailabilityDescription(String memberId, TimeFilter filter) {
    final memberEventsList = widget.memberEvents[memberId] ?? [];
    final dayStart = DateTime(widget.date.year, widget.date.month, widget.date.day, 0, 0);
    final dayEnd = DateTime(widget.date.year, widget.date.month, widget.date.day, 23, 59, 59);

    final eventsOnDate = memberEventsList
        .where((e) {
          final localStart = e.startTime.toLocal();
          final localEnd = e.endTime.toLocal();
          return localStart.isBefore(dayEnd) && localEnd.isAfter(dayStart);
        })
        .where((e) => e.category != EventCategory.holiday)
        .toList();

    return widget.availabilityService.getAvailabilityDescription(
      events: eventsOnDate,
      date: widget.date,
      filter: filter,
      customStartTime: widget.customStartTime,
      customEndTime: widget.customEndTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Consumer<GroupProvider>(
      builder: (context, provider, _) {
        final members = provider.selectedGroupMembers;

        // Count available and busy members for header
        int availableCount = 0;
        int busyCount = 0;
        for (final member in members) {
          if (_isMemberAvailableOnDate(member.userId)) {
            availableCount++;
          } else {
            busyCount++;
          }
        }

        return Column(
          children: [
            // Collapsible header
            Semantics(
              button: true,
              label: _isExpanded
                  ? 'Collapse team availability section'
                  : 'Expand team availability section',
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 16, 8),
                  child: Row(
                    children: [
                      // Section title
                      Text(
                        'TEAM AVAILABILITY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: appColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Summary badges
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$availableCount free',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                      if (busyCount > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$busyCount busy',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      // Expand/collapse icon
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: appColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Collapsible content
            AnimatedCrossFade(
              firstChild: _buildMemberList(members, colorScheme, appColors),
              secondChild: const SizedBox.shrink(),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMemberList(
    List<GroupMemberProfile> members,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    // Sort members: available first, then busy
    final sortedMembers = List<GroupMemberProfile>.from(members);
    sortedMembers.sort((a, b) {
      final aAvailable = _isMemberAvailableOnDate(a.userId);
      final bAvailable = _isMemberAvailableOnDate(b.userId);
      if (aAvailable && !bAvailable) return -1;
      if (!aAvailable && bAvailable) return 1;
      return 0;
    });

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sortedMembers.length,
      itemBuilder: (context, index) {
        final member = sortedMembers[index];
        final isAvailable = _isMemberAvailableOnDate(member.userId);

        return _buildMemberTile(
          member: member,
          isAvailable: isAvailable,
          colorScheme: colorScheme,
          appColors: appColors,
        );
      },
    );
  }

  Widget _buildMemberTile({
    required GroupMemberProfile member,
    required bool isAvailable,
    required ColorScheme colorScheme,
    required AppColorsExtension appColors,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isAvailable
            ? AppColors.success.withValues(alpha: 0.08)
            : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAvailable
              ? AppColors.success.withValues(alpha: 0.25)
              : colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          // Avatar with availability ring
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isAvailable ? AppColors.success : colorScheme.outline.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isAvailable
                    ? AppColors.success.withValues(alpha: 0.15)
                    : colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  member.initials,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isAvailable
                        ? AppColors.success
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name and availability description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.displayName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                _buildAvailabilityDescription(member.userId, isAvailable, appColors, colorScheme),
              ],
            ),
          ),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isAvailable
                  ? AppColors.success.withValues(alpha: 0.15)
                  : colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAvailable ? Icons.check_circle : Icons.cancel,
                  size: 14,
                  color: isAvailable ? AppColors.success : colorScheme.error,
                ),
                const SizedBox(width: 4),
                Text(
                  isAvailable ? 'Free' : 'Busy',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isAvailable ? AppColors.success : colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityDescription(
    String memberId,
    bool isAvailable,
    AppColorsExtension appColors,
    ColorScheme colorScheme,
  ) {
    final descriptions = <String>[];

    if (widget.selectedTimeFilters.contains(TimeFilter.allDay)) {
      final desc = _getMemberAvailabilityDescription(memberId, TimeFilter.allDay);
      descriptions.add(desc);
    } else {
      for (final filter in widget.selectedTimeFilters) {
        final desc = _getMemberAvailabilityDescription(memberId, filter);
        if (widget.selectedTimeFilters.length > 1) {
          descriptions.add('${filter.label}: $desc');
        } else {
          descriptions.add(desc);
        }
      }
    }

    if (descriptions.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayText = descriptions.length == 1
        ? descriptions.first
        : descriptions.join(' | ');

    // Don't show "Free" redundantly - the badge already shows it
    if (displayText == 'Free') {
      return Text(
        'Available all day',
        style: TextStyle(
          fontSize: 12,
          color: appColors.textMuted,
        ),
      );
    }

    return Text(
      displayText,
      style: TextStyle(
        fontSize: 12,
        color: appColors.textMuted,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
