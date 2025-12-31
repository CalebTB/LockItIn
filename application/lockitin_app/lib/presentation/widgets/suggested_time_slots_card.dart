import 'package:flutter/material.dart';
import '../../core/services/availability_calculator_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/group_model.dart';

/// Card showing suggested time slots for a selected day
/// Uses Minimal theme color system
///
/// Displays:
/// - Best time slots sorted by availability
/// - Availability count/percentage for each slot
/// - Expandable member list (who's free/busy)
/// - "Use this time" action button
class SuggestedTimeSlotsCard extends StatefulWidget {
  final DateTime date;
  final List<TimeSlotAvailability> timeSlots;
  final List<GroupMemberProfile> members;
  final void Function(TimeSlotAvailability slot)? onSlotSelected;
  final int maxSlotsToShow;

  const SuggestedTimeSlotsCard({
    super.key,
    required this.date,
    required this.timeSlots,
    required this.members,
    this.onSlotSelected,
    this.maxSlotsToShow = 5,
  });

  @override
  State<SuggestedTimeSlotsCard> createState() => _SuggestedTimeSlotsCardState();
}

class _SuggestedTimeSlotsCardState extends State<SuggestedTimeSlotsCard> {
  String? _expandedSlotId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    if (widget.timeSlots.isEmpty) {
      return _buildEmptyState(colorScheme, appColors);
    }

    // Filter to slots with at least some availability and take top N
    final slotsToShow = widget.timeSlots
        .where((s) => s.availableCount > 0)
        .take(widget.maxSlotsToShow)
        .toList();

    if (slotsToShow.isEmpty) {
      return _buildNoAvailabilityState(colorScheme, appColors);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colorScheme, appColors),
          ...slotsToShow.map((slot) => _buildTimeSlotRow(slot, colorScheme, appColors)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, AppColorsExtension appColors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              // Per Minimal theme: solid color, no gradients
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              color: colorScheme.onPrimary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SUGGESTED TIMES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Best times when most people are free',
                  style: TextStyle(
                    fontSize: 12,
                    color: appColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotRow(TimeSlotAvailability slot, ColorScheme colorScheme, AppColorsExtension appColors) {
    final slotId = '${slot.startTime.hour}-${slot.endTime.hour}';
    final isExpanded = _expandedSlotId == slotId;

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expandedSlotId = isExpanded ? null : slotId;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Time range
                Container(
                  width: 85,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getAvailabilityColor(slot.availabilityRatio).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getAvailabilityColor(slot.availabilityRatio).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    slot.formattedTimeRange,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      // Use darker text color for contrast on light backgrounds
                      color: AppColors.getAvailabilityTextColorDark(slot.availabilityRatio),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Availability indicator
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              slot.availabilityDescription,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (slot.isFullyAvailable) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'PERFECT',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: slot.availabilityRatio,
                          backgroundColor: colorScheme.outline.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation(
                            _getAvailabilityColor(slot.availabilityRatio),
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Expand/Use button
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: appColors.textMuted,
                      size: 20,
                    ),
                    if (widget.onSlotSelected != null) ...[
                      const SizedBox(width: 2),
                      GestureDetector(
                        onTap: () => widget.onSlotSelected!(slot),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            // Per Minimal theme: solid primary color
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Use',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),

        // Expanded member list
        if (isExpanded) _buildMemberList(slot, colorScheme, appColors),
      ],
    );
  }

  Widget _buildMemberList(TimeSlotAvailability slot, ColorScheme colorScheme, AppColorsExtension appColors) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedSlotId = null;
        });
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Close hint row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: appColors.textDisabled,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Tap to close',
                  style: TextStyle(
                    fontSize: 10,
                    color: appColors.textDisabled,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Free members
            if (slot.availableMembers.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Free (${slot.availableMembers.length})',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: slot.availableMembers.map((userId) {
                  final member = _getMemberById(userId);
                  return _buildMemberChip(member, true, colorScheme);
                }).toList(),
              ),
            ],

            if (slot.availableMembers.isNotEmpty && slot.busyMembers.isNotEmpty)
              const SizedBox(height: 12),

            // Busy members
            if (slot.busyMembers.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.cancel_rounded,
                    color: colorScheme.error,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Busy (${slot.busyMembers.length})',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: slot.busyMembers.map((userId) {
                  final member = _getMemberById(userId);
                  return _buildMemberChip(member, false, colorScheme);
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMemberChip(GroupMemberProfile? member, bool isFree, ColorScheme colorScheme) {
    final name = member?.displayName ?? 'Unknown';
    final initials = member?.initials ?? '?';
    final chipColor = isFree ? AppColors.success : colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: chipColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: chipColor.withValues(alpha: 0.3),
            child: Text(
              initials,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: chipColor,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            name.split(' ').first,
            style: TextStyle(
              fontSize: 11,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }

  GroupMemberProfile? _getMemberById(String odataId) {
    try {
      return widget.members.firstWhere((m) => m.userId == odataId);
    } on StateError {
      return null;
    }
  }

  /// Get availability color based on ratio (5-tier scale)
  Color _getAvailabilityColor(double ratio) {
    return AppColors.getAvailabilityDotColor(ratio);
  }

  Widget _buildEmptyState(ColorScheme colorScheme, AppColorsExtension appColors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.hourglass_empty_rounded,
            color: appColors.textMuted,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            'Loading time suggestions...',
            style: TextStyle(
              fontSize: 13,
              color: appColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAvailabilityState(ColorScheme colorScheme, AppColorsExtension appColors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.event_busy_rounded,
            color: appColors.textMuted,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Everyone is busy on this day. Try another date!',
              style: TextStyle(
                fontSize: 13,
                color: appColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
