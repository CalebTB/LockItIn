import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/time_filter_utils.dart';
import '../../data/models/group_model.dart';

/// Data class for best day information with availability details
class BestDayInfo {
  final int day;
  final int availableCount;
  final int totalMembers;
  final List<GroupMemberProfile> unavailableMembers;

  const BestDayInfo({
    required this.day,
    required this.availableCount,
    required this.totalMembers,
    this.unavailableMembers = const [],
  });

  bool get isFullAvailability => availableCount == totalMembers && totalMembers > 0;
  double get ratio => totalMembers > 0 ? availableCount / totalMembers : 0;
}

/// Section showing the best days for scheduling in the current month
/// Uses Minimal theme color system - emerald for best days (availability)
///
/// Displays:
/// - "Best Days This Month" header with time range badge
/// - Large cards with availability counts and conflict details
/// - "No dates to propose" message when no good days found
class GroupBestDaysSection extends StatelessWidget {
  final DateTime focusedMonth;
  final Set<TimeFilter> selectedTimeFilters;
  final TimeOfDay customStartTime;
  final TimeOfDay customEndTime;
  final List<int> Function(Set<TimeFilter> filters) getBestDaysForFilters;
  final ValueChanged<int> onDaySelected;

  // New callbacks for availability details
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final hasSpecificFilters = !selectedTimeFilters.contains(TimeFilter.allDay);
    final customTimeLabel = '${_formatTimeOfDay(customStartTime)} - ${_formatTimeOfDay(customEndTime)}';

    // Get best days for custom time range (when Custom filter is selected)
    final customBestDays = getBestDaysForFilters({TimeFilter.allDay});

    // Get best days for selected filters if specific ones are selected
    List<int> filteredBestDays = [];
    String filterLabel = '';
    if (hasSpecificFilters) {
      filteredBestDays = getBestDaysForFilters(selectedTimeFilters);
      // Consolidate time ranges into earliest start - latest end
      final filters = selectedTimeFilters.toList();
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
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show custom time range when Custom filter is selected
          if (!hasSpecificFilters) ...[
            _buildHeader(context, customTimeLabel, colorScheme, appColors),
            const SizedBox(height: 12),
            if (customBestDays.isNotEmpty)
              _buildBestDayCards(context, customBestDays, colorScheme, appColors)
            else
              _buildNoDatesMessage(context, colorScheme, appColors),
          ],

          // Show filtered best days when specific filters are selected
          if (hasSpecificFilters) ...[
            _buildHeader(context, filterLabel, colorScheme, appColors),
            const SizedBox(height: 12),
            if (filteredBestDays.isNotEmpty)
              _buildBestDayCards(context, filteredBestDays, colorScheme, appColors)
            else
              _buildNoDatesMessage(context, colorScheme, appColors),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String timeLabel,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    return Row(
      children: [
        // Coral star icon for visual prominence
        Icon(
          Icons.star_rounded,
          size: 16,
          color: AppColors.secondary, // Coral/orange for "best days"
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
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            timeLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
            ),
          ),
        ),
      ],
    );
  }

  /// Build large cards with availability details instead of simple chips
  Widget _buildBestDayCards(
    BuildContext context,
    List<int> days,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: days.map((day) {
          final info = _getBestDayInfo(day);
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildBestDayCard(context, info, colorScheme, appColors),
          );
        }).toList(),
      ),
    );
  }

  /// Build a single best day card with rich details
  Widget _buildBestDayCard(
    BuildContext context,
    BestDayInfo info,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    final date = DateTime(focusedMonth.year, focusedMonth.month, info.day);
    final dayOfWeek = DateFormat('EEE').format(date);
    final monthDay = DateFormat('MMM d').format(date);

    // Color based on availability
    final cardColor = info.isFullAvailability
        ? AppColors.success
        : (info.ratio >= 0.5 ? AppColors.warning : AppColors.secondary);

    final cardBgColor = cardColor.withValues(alpha: 0.08);
    final cardBorderColor = cardColor.withValues(alpha: 0.25);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onDaySelected(info.day);
      },
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorderColor),
          boxShadow: [
            BoxShadow(
              color: cardColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day and date header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    dayOfWeek,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  monthDay,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Availability count
            Row(
              children: [
                Icon(
                  info.isFullAvailability
                      ? Icons.check_circle_rounded
                      : Icons.people_rounded,
                  size: 14,
                  color: cardColor,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    info.isFullAvailability
                        ? 'Everyone free!'
                        : '${info.availableCount}/${info.totalMembers} available',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),

            // Conflict details (who's busy) - only show if not fully available
            if (!info.isFullAvailability && info.unavailableMembers.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                _formatUnavailableMembers(info.unavailableMembers),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: appColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Format unavailable members for display
  String _formatUnavailableMembers(List<GroupMemberProfile> members) {
    if (members.isEmpty) return '';

    if (members.length == 1) {
      return '${members.first.displayName.split(' ').first} busy';
    } else if (members.length == 2) {
      final names = members.map((m) => m.displayName.split(' ').first).toList();
      return '${names[0]} & ${names[1]} busy';
    } else {
      final firstName = members.first.displayName.split(' ').first;
      return '$firstName +${members.length - 1} busy';
    }
  }

  Widget _buildNoDatesMessage(
    BuildContext context,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 18,
              color: appColors.textMuted,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No dates to propose this month',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Try expanding your time filters',
                  style: TextStyle(
                    fontSize: 11,
                    color: appColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
