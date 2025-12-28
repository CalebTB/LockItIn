import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/utils/time_filter_utils.dart';
import '../theme/sunset_coral_theme.dart';

/// Section showing the best days for scheduling in the current month
///
/// Displays:
/// - "Best Days This Month" header with time range badge
/// - Horizontally scrollable chips for best days
/// - "No dates to propose" message when no good days found
class GroupBestDaysSection extends StatelessWidget {
  final DateTime focusedMonth;
  final Set<TimeFilter> selectedTimeFilters;
  final TimeOfDay customStartTime;
  final TimeOfDay customEndTime;
  final List<int> Function(Set<TimeFilter> filters) getBestDaysForFilters;
  final ValueChanged<int> onDaySelected;

  const GroupBestDaysSection({
    super.key,
    required this.focusedMonth,
    required this.selectedTimeFilters,
    required this.customStartTime,
    required this.customEndTime,
    required this.getBestDaysForFilters,
    required this.onDaySelected,
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

  @override
  Widget build(BuildContext context) {
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
          top: BorderSide(
            color: SunsetCoralTheme.rose500.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show custom time range when Custom filter is selected
          if (!hasSpecificFilters) ...[
            _buildHeader(customTimeLabel),
            const SizedBox(height: 12),
            if (customBestDays.isNotEmpty)
              _buildBestDayChips(customBestDays)
            else
              _buildNoDatesMessage(),
          ],

          // Show filtered best days when specific filters are selected
          if (hasSpecificFilters) ...[
            _buildHeader(filterLabel),
            const SizedBox(height: 12),
            if (filteredBestDays.isNotEmpty)
              _buildBestDayChips(filteredBestDays)
            else
              _buildNoDatesMessage(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(String timeLabel) {
    return Row(
      children: [
        const Text(
          'BEST DAYS THIS MONTH',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                SunsetCoralTheme.rose500,
                SunsetCoralTheme.orange500,
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            timeLabel,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBestDayChips(List<int> days) {
    final monthName = DateFormat('MMM').format(focusedMonth);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: days.map((day) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onDaySelected(day),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      SunsetCoralTheme.rose500,
                      SunsetCoralTheme.orange500,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: SunsetCoralTheme.rose500.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '$monthName $day',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNoDatesMessage() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: SunsetCoralTheme.rose900.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: SunsetCoralTheme.rose500.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 16,
              color: SunsetCoralTheme.rose400.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Text(
              'No dates to propose this month',
              style: TextStyle(
                fontSize: 13,
                color: SunsetCoralTheme.rose300.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
