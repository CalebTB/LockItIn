import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/time_filter_utils.dart';

/// Consolidated filter sheet for group calendar
/// Combines date range and time filters in a single modal
///
/// Uses Minimal theme color system
class GroupFiltersSheet extends StatefulWidget {
  final DateTimeRange? initialDateRange;
  final Set<TimeFilter> initialTimeFilters;
  final TimeOfDay customStartTime;
  final TimeOfDay customEndTime;
  final void Function(DateTimeRange?) onDateRangeChanged;
  final void Function(Set<TimeFilter>) onTimeFiltersChanged;
  final void Function(TimeOfDay start, TimeOfDay end) onCustomTimeChanged;

  const GroupFiltersSheet({
    super.key,
    required this.initialDateRange,
    required this.initialTimeFilters,
    required this.customStartTime,
    required this.customEndTime,
    required this.onDateRangeChanged,
    required this.onTimeFiltersChanged,
    required this.onCustomTimeChanged,
  });

  /// Show this sheet as a modal bottom sheet
  static Future<void> show({
    required BuildContext context,
    required DateTimeRange? dateRange,
    required Set<TimeFilter> timeFilters,
    required TimeOfDay customStartTime,
    required TimeOfDay customEndTime,
    required void Function(DateTimeRange?) onDateRangeChanged,
    required void Function(Set<TimeFilter>) onTimeFiltersChanged,
    required void Function(TimeOfDay start, TimeOfDay end) onCustomTimeChanged,
  }) {
    HapticFeedback.selectionClick();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GroupFiltersSheet(
        initialDateRange: dateRange,
        initialTimeFilters: timeFilters,
        customStartTime: customStartTime,
        customEndTime: customEndTime,
        onDateRangeChanged: onDateRangeChanged,
        onTimeFiltersChanged: onTimeFiltersChanged,
        onCustomTimeChanged: onCustomTimeChanged,
      ),
    );
  }

  /// Calculate number of active filters
  static int getActiveFilterCount(DateTimeRange? dateRange, Set<TimeFilter> timeFilters) {
    int count = 0;
    if (dateRange != null) count++;
    // Count time filters (allDay doesn't count as a filter)
    if (!timeFilters.contains(TimeFilter.allDay) && timeFilters.isNotEmpty) {
      count += timeFilters.length;
    }
    return count;
  }

  @override
  State<GroupFiltersSheet> createState() => _GroupFiltersSheetState();
}

class _GroupFiltersSheetState extends State<GroupFiltersSheet> {
  late DateTimeRange? _dateRange;
  late Set<TimeFilter> _timeFilters;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    _dateRange = widget.initialDateRange;
    _timeFilters = Set.from(widget.initialTimeFilters);
    _startTime = widget.customStartTime;
    _endTime = widget.customEndTime;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
          // Handle
          _buildHandle(colorScheme),
          // Header
          _buildHeader(colorScheme, appColors),
          // Divider
          Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.15)),
          // Filters content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date range section
                  _buildSectionHeader('DATE RANGE', colorScheme, appColors),
                  const SizedBox(height: 12),
                  _buildDateRangeSelector(colorScheme, appColors),
                  const SizedBox(height: 24),
                  // Time of day section
                  _buildSectionHeader('TIME OF DAY', colorScheme, appColors),
                  const SizedBox(height: 12),
                  _buildTimeFilterChips(colorScheme, appColors),
                  // Custom time range (when allDay is selected)
                  if (_timeFilters.contains(TimeFilter.allDay)) ...[
                    const SizedBox(height: 16),
                    _buildCustomTimeSelector(colorScheme, appColors),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Action buttons
          _buildActionButtons(colorScheme, appColors),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }

  Widget _buildHandle(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: colorScheme.outline.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, AppColorsExtension appColors) {
    final activeCount = GroupFiltersSheet.getActiveFilterCount(_dateRange, _timeFilters);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.filter_list_rounded,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  activeCount == 0
                      ? 'No filters applied'
                      : '$activeCount ${activeCount == 1 ? 'filter' : 'filters'} active',
                  style: TextStyle(
                    fontSize: 13,
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

  Widget _buildSectionHeader(
    String title,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: appColors.textMuted,
      ),
    );
  }

  Widget _buildDateRangeSelector(
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    final hasRange = _dateRange != null;

    return Column(
      children: [
        // All dates option
        _buildRadioTile(
          title: 'All dates',
          subtitle: 'Show availability for entire month',
          isSelected: !hasRange,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _dateRange = null);
          },
          colorScheme: colorScheme,
          appColors: appColors,
        ),
        const SizedBox(height: 8),
        // Custom range option
        _buildRadioTile(
          title: hasRange ? _formatDateRange(_dateRange!) : 'Custom range',
          subtitle: hasRange ? 'Tap to change' : 'Select specific dates',
          isSelected: hasRange,
          onTap: () async {
            HapticFeedback.selectionClick();
            final range = await showDateRangePicker(
              context: context,
              firstDate: DateTime.now().subtract(const Duration(days: 30)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              initialDateRange: _dateRange,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: colorScheme,
                  ),
                  child: child!,
                );
              },
            );
            if (range != null) {
              setState(() => _dateRange = range);
            }
          },
          colorScheme: colorScheme,
          appColors: appColors,
          trailing: hasRange
              ? IconButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => _dateRange = null);
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: appColors.textMuted,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              : null,
        ),
      ],
    );
  }

  Widget _buildRadioTile({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required AppColorsExtension appColors,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.08)
              : colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.3)
                : colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? colorScheme.primary : appColors.textMuted,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: appColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilterChips(
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TimeFilter.values.map((filter) {
        final isSelected = _timeFilters.contains(filter);
        final label = filter == TimeFilter.allDay ? 'Custom time' : filter.label;

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              if (filter == TimeFilter.allDay) {
                // Custom/allDay is exclusive - selecting it clears other filters
                _timeFilters = {TimeFilter.allDay};
              } else {
                // Remove allDay if selecting a specific time
                _timeFilters.remove(TimeFilter.allDay);
                if (isSelected) {
                  _timeFilters.remove(filter);
                  // If no filters selected, default back to allDay
                  if (_timeFilters.isEmpty) {
                    _timeFilters.add(TimeFilter.allDay);
                  }
                } else {
                  _timeFilters.add(filter);
                }
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (filter != TimeFilter.allDay)
                  Icon(
                    _getFilterIcon(filter),
                    size: 16,
                    color: isSelected
                        ? colorScheme.onPrimary
                        : appColors.textSecondary,
                  ),
                if (filter != TimeFilter.allDay) const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? colorScheme.onPrimary
                        : appColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getFilterIcon(TimeFilter filter) {
    switch (filter) {
      case TimeFilter.morning:
        return Icons.wb_sunny_rounded;
      case TimeFilter.afternoon:
        return Icons.wb_cloudy_rounded;
      case TimeFilter.evening:
        return Icons.nights_stay_rounded;
      case TimeFilter.night:
        return Icons.dark_mode_rounded;
      case TimeFilter.allDay:
        return Icons.schedule_rounded;
    }
  }

  Widget _buildCustomTimeSelector(
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTimePicker(
              label: 'From',
              time: _startTime,
              onTap: () => _selectTime(isStart: true),
              colorScheme: colorScheme,
              appColors: appColors,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: appColors.textMuted,
            ),
          ),
          Expanded(
            child: _buildTimePicker(
              label: 'To',
              time: _endTime,
              onTap: () => _selectTime(isStart: false),
              colorScheme: colorScheme,
              appColors: appColors,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required AppColorsExtension appColors,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: appColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              time.format(context),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime({required bool isStart}) async {
    final initialTime = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Widget _buildActionButtons(
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          // Reset button
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _dateRange = null;
                  _timeFilters = {TimeFilter.allDay};
                  _startTime = const TimeOfDay(hour: 9, minute: 0);
                  _endTime = const TimeOfDay(hour: 17, minute: 0);
                });
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Reset',
                style: TextStyle(
                  color: appColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Apply button
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                widget.onDateRangeChanged(_dateRange);
                widget.onTimeFiltersChanged(_timeFilters);
                widget.onCustomTimeChanged(_startTime, _endTime);
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Apply Filters',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateRange(DateTimeRange range) {
    final start = range.start;
    final end = range.end;
    final formatter = DateFormat('MMM d');

    if (start.year != end.year) {
      return '${formatter.format(start)}, ${start.year} - ${formatter.format(end)}, ${end.year}';
    }
    return '${formatter.format(start)} - ${formatter.format(end)}';
  }
}
