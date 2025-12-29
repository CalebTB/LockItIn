import 'package:flutter/material.dart';
import '../../core/services/availability_calculator_service.dart';
import '../../data/models/group_model.dart';
import '../theme/sunset_coral_theme.dart';

/// Card showing suggested time slots for a selected day
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
    if (widget.timeSlots.isEmpty) {
      return _buildEmptyState();
    }

    // Filter to slots with at least some availability and take top N
    final slotsToShow = widget.timeSlots
        .where((s) => s.availableCount > 0)
        .take(widget.maxSlotsToShow)
        .toList();

    if (slotsToShow.isEmpty) {
      return _buildNoAvailabilityState();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: SunsetCoralTheme.rose950.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: SunsetCoralTheme.rose500.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          ...slotsToShow.map((slot) => _buildTimeSlotRow(slot)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  SunsetCoralTheme.rose500,
                  SunsetCoralTheme.orange500,
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SUGGESTED TIMES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Best times when most people are free',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotRow(TimeSlotAvailability slot) {
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
                  width: 100,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getAvailabilityColor(slot.availabilityRatio),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Availability indicator
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            slot.availabilityDescription,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          if (slot.isFullyAvailable) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'PERFECT',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.greenAccent,
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
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
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
                      color: Colors.white60,
                      size: 20,
                    ),
                    if (widget.onSlotSelected != null) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => widget.onSlotSelected!(slot),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                SunsetCoralTheme.rose500,
                                SunsetCoralTheme.orange500,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Use',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
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
        if (isExpanded) _buildMemberList(slot),
      ],
    );
  }

  Widget _buildMemberList(TimeSlotAvailability slot) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SunsetCoralTheme.rose900.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Free members
          if (slot.availableMembers.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.greenAccent.withValues(alpha: 0.8),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'Free (${slot.availableMembers.length})',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.greenAccent.withValues(alpha: 0.8),
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
                return _buildMemberChip(member, true);
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
                  color: SunsetCoralTheme.rose400.withValues(alpha: 0.8),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'Busy (${slot.busyMembers.length})',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: SunsetCoralTheme.rose400.withValues(alpha: 0.8),
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
                return _buildMemberChip(member, false);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMemberChip(GroupMemberProfile? member, bool isFree) {
    final name = member?.displayName ?? 'Unknown';
    final initials = member?.initials ?? '?';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isFree
            ? Colors.greenAccent.withValues(alpha: 0.1)
            : SunsetCoralTheme.rose500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFree
              ? Colors.greenAccent.withValues(alpha: 0.3)
              : SunsetCoralTheme.rose500.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: isFree
                ? Colors.greenAccent.withValues(alpha: 0.3)
                : SunsetCoralTheme.rose500.withValues(alpha: 0.3),
            child: Text(
              initials,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: isFree ? Colors.greenAccent : SunsetCoralTheme.rose300,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            name.split(' ').first,
            style: TextStyle(
              fontSize: 11,
              color: isFree ? Colors.greenAccent : SunsetCoralTheme.rose300,
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

  Color _getAvailabilityColor(double ratio) {
    if (ratio >= 1.0) return Colors.greenAccent;
    if (ratio >= 0.75) return Colors.lightGreenAccent;
    if (ratio >= 0.5) return SunsetCoralTheme.amber500;
    if (ratio >= 0.25) return SunsetCoralTheme.orange400;
    return SunsetCoralTheme.rose400;
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SunsetCoralTheme.rose950.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: SunsetCoralTheme.rose500.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.hourglass_empty_rounded,
            color: SunsetCoralTheme.rose400.withValues(alpha: 0.6),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            'Loading time suggestions...',
            style: TextStyle(
              fontSize: 13,
              color: SunsetCoralTheme.rose300.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAvailabilityState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SunsetCoralTheme.rose950.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: SunsetCoralTheme.rose500.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.event_busy_rounded,
            color: SunsetCoralTheme.rose400.withValues(alpha: 0.6),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Everyone is busy on this day. Try another date!',
              style: TextStyle(
                fontSize: 13,
                color: SunsetCoralTheme.rose300.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
