import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/time_filter_utils.dart';
import '../../data/models/group_model.dart';
import '../../core/utils/timezone_utils.dart';

/// Data class for best day information with availability details
class BestDayInfo {
  final int day;
  final int availableCount;
  final int totalMembers;
  final List<GroupMemberProfile> unavailableMembers;
  final String? timeSlot;

  const BestDayInfo({
    required this.day,
    required this.availableCount,
    required this.totalMembers,
    this.unavailableMembers = const [],
    this.timeSlot,
  });

  bool get isFullAvailability => availableCount == totalMembers && totalMembers > 0;
  double get ratio => totalMembers > 0 ? availableCount / totalMembers : 0;
}

/// Section showing the best days for scheduling in the current month
/// Redesigned to match screenshot: vertical stacked cards with rich details
///
/// Displays:
/// - "Best Days to Meet" header with target icon
/// - Vertical cards with date, member count, availability badge, time slot
/// - "View all X best days →" link at bottom
/// - "No dates to propose" message when no good days found
class GroupBestDaysSection extends StatelessWidget {
  final DateTime focusedMonth;
  final Set<TimeFilter> selectedTimeFilters;
  final TimeOfDay customStartTime;
  final TimeOfDay customEndTime;
  final List<int> Function(Set<TimeFilter> filters) getBestDaysForFilters;
  final ValueChanged<int> onDaySelected;

  // Callbacks for availability details
  final int Function(DateTime date)? getAvailabilityForDay;
  final int Function()? getTotalMembers;
  final List<GroupMemberProfile> Function(DateTime date)? getUnavailableMembersForDay;

  const GroupBestDaysSection({
    super.key,
    required this.focusedMonth,
    required this.selectedTimeFilters,
    required this.customStartTime,
    required this.customEndTime,
    required this.getBestDaysForFilters,
    required this.onDaySelected,
    this.getAvailabilityForDay,
    this.getTotalMembers,
    this.getUnavailableMembersForDay,
  });

  /// Format TimeOfDay to string like "9am" or "5:30pm"
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'am' : 'pm';
    if (time.minute == 0) {
      return '$hour$period';
    }
    return '$hour:${time.minute.toString().padLeft(2, '0')}$period';
  }

  /// Get time slot label based on current filters
  String _getTimeSlotLabel() {
    final hasSpecificFilters = !selectedTimeFilters.contains(TimeFilter.allDay);

    if (!hasSpecificFilters) {
      return '${_formatTimeOfDay(customStartTime)}-${_formatTimeOfDay(customEndTime)}';
    }

    // Consolidate time ranges into earliest start - latest end
    final filters = selectedTimeFilters.toList();
    int earliestStart = 24;
    int latestEnd = 0;
    for (final filter in filters) {
      if (filter.startHour < earliestStart) {
        earliestStart = filter.startHour;
      }
      final effectiveEnd = filter == TimeFilter.night ? 30 : filter.endHour;
      if (effectiveEnd > latestEnd) {
        latestEnd = effectiveEnd;
      }
    }

    String formatHour(int hour) {
      final h = hour % 24;
      if (h == 0) return '12am';
      if (h == 12) return '12pm';
      if (h < 12) return '${h}am';
      return '${h - 12}pm';
    }

    return '${formatHour(earliestStart)}-${formatHour(latestEnd % 24)}';
  }

  /// Get BestDayInfo for a specific day
  BestDayInfo _getBestDayInfo(int day) {
    final date = DateTime(focusedMonth.year, focusedMonth.month, day);
    final totalMembers = getTotalMembers?.call() ?? 0;
    final availableCount = getAvailabilityForDay?.call(date) ?? totalMembers;
    final unavailable = getUnavailableMembersForDay?.call(date) ?? [];

    return BestDayInfo(
      day: day,
      availableCount: availableCount,
      totalMembers: totalMembers,
      unavailableMembers: unavailable,
      timeSlot: _getTimeSlotLabel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    // Get best days for current filters
    final hasSpecificFilters = !selectedTimeFilters.contains(TimeFilter.allDay);
    final bestDays = hasSpecificFilters
        ? getBestDaysForFilters(selectedTimeFilters)
        : getBestDaysForFilters({TimeFilter.allDay});

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with target icon
          _buildHeader(appColors),
          const SizedBox(height: 12),

          // Best day card (single top recommendation) or empty state
          // Show only 1 card for compact layout - maximizes calendar visibility
          // "View all" link provides access to more options (progressive disclosure)
          if (bestDays.isNotEmpty) ...[
            _buildBestDayCards(context, bestDays.take(1).toList(), colorScheme, appColors),
            // "View all X best days" link - show only if 2+ best days exist
            if (bestDays.length > 1) ...[
              const SizedBox(height: 10),
              _buildViewAllLink(context, bestDays, colorScheme, appColors),
            ],
          ] else
            _buildNoDatesMessage(context, colorScheme, appColors),
        ],
      ),
    );
  }

  Widget _buildHeader(AppColorsExtension appColors) {
    return Row(
      children: [
        Icon(
          Icons.gps_fixed_rounded, // Target icon like in screenshot
          size: 16,
          color: AppColors.secondary,
        ),
        const SizedBox(width: 6),
        Text(
          'BEST DAYS TO MEET',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: appColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Build vertical stacked cards matching screenshot design
  Widget _buildBestDayCards(
    BuildContext context,
    List<int> days,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    return Column(
      children: days.asMap().entries.map((entry) {
        final index = entry.key;
        final day = entry.value;
        final info = _getBestDayInfo(day);
        return Padding(
          padding: EdgeInsets.only(bottom: index < days.length - 1 ? 8 : 0),
          child: _buildBestDayCard(context, info, index == 0, colorScheme, appColors),
        );
      }).toList(),
    );
  }

  /// Build a single best day card matching screenshot design
  Widget _buildBestDayCard(
    BuildContext context,
    BestDayInfo info,
    bool isFirst,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    final date = DateTime(focusedMonth.year, focusedMonth.month, info.day);

    // Card styling based on availability
    final isEveryoneFree = info.isFullAvailability;
    final cardBgColor = isFirst
        ? AppColors.secondary.withValues(alpha: 0.08)
        : colorScheme.surface;
    final cardBorderColor = isFirst
        ? AppColors.secondary.withValues(alpha: 0.25)
        : colorScheme.outline.withValues(alpha: 0.2);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onDaySelected(info.day);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Date and availability badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Date and member count
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TimezoneUtils.formatLocal(date, 'EEE, MMM d'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${info.availableCount}/${info.totalMembers} members available',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                // Availability badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isEveryoneFree
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isEveryoneFree
                        ? 'Everyone free'
                        : '${info.availableCount} free',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isEveryoneFree ? AppColors.success : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            // Time slot info with icon
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isEveryoneFree
                      ? Icons.check_circle_rounded
                      : Icons.schedule_rounded,
                  size: 14,
                  color: isEveryoneFree ? AppColors.success : appColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  isEveryoneFree
                      ? 'Everyone free ${info.timeSlot ?? ''}'
                      : _formatConflictInfo(info),
                  style: TextStyle(
                    fontSize: 12,
                    color: isEveryoneFree ? AppColors.success : appColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Format conflict info for partially available days
  String _formatConflictInfo(BestDayInfo info) {
    if (info.unavailableMembers.isEmpty) {
      return info.timeSlot ?? '';
    }

    if (info.unavailableMembers.length == 1) {
      final name = info.unavailableMembers.first.displayName.split(' ').first;
      return '$name has conflict';
    } else {
      return '${info.unavailableMembers.length} members have conflicts';
    }
  }

  /// "View all X best days →" link
  Widget _buildViewAllLink(
    BuildContext context,
    List<int> allBestDays,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showAllBestDaysSheet(context, allBestDays, colorScheme, appColors);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'View all ${allBestDays.length} best days',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.arrow_forward_rounded,
            size: 16,
            color: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  /// Show bottom sheet with all best days
  void _showAllBestDaysSheet(
    BuildContext context,
    List<int> allBestDays,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.gps_fixed_rounded,
                      size: 18,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'All Best Days to Meet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.close_rounded,
                        size: 24,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: colorScheme.outline.withValues(alpha: 0.15)),
              // List of all best days
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: allBestDays.length,
                  itemBuilder: (context, index) {
                    final day = allBestDays[index];
                    final info = _getBestDayInfo(day);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildBestDayCardInSheet(
                        context,
                        info,
                        index == 0,
                        colorScheme,
                        appColors,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build best day card for the sheet (with close on tap)
  Widget _buildBestDayCardInSheet(
    BuildContext context,
    BestDayInfo info,
    bool isFirst,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    final date = DateTime(focusedMonth.year, focusedMonth.month, info.day);
    final isEveryoneFree = info.isFullAvailability;

    final cardBgColor = isFirst
        ? AppColors.secondary.withValues(alpha: 0.08)
        : colorScheme.surface;
    final cardBorderColor = isFirst
        ? AppColors.secondary.withValues(alpha: 0.25)
        : colorScheme.outline.withValues(alpha: 0.2);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).pop(); // Close sheet
        onDaySelected(info.day); // Select the day
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Date and availability badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Date and member count
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TimezoneUtils.formatLocal(date, 'EEE, MMM d'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${info.availableCount}/${info.totalMembers} members available',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                // Availability badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isEveryoneFree
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isEveryoneFree
                        ? 'Everyone free'
                        : '${info.availableCount} free',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isEveryoneFree ? AppColors.success : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            // Time slot info with icon
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isEveryoneFree
                      ? Icons.check_circle_rounded
                      : Icons.schedule_rounded,
                  size: 14,
                  color: isEveryoneFree ? AppColors.success : appColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  isEveryoneFree
                      ? 'Everyone free ${info.timeSlot ?? ''}'
                      : _formatConflictInfo(info),
                  style: TextStyle(
                    fontSize: 12,
                    color: isEveryoneFree ? AppColors.success : appColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDatesMessage(
    BuildContext context,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 20,
            color: appColors.textMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No ideal days this month',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Try adjusting your time filters',
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
}
