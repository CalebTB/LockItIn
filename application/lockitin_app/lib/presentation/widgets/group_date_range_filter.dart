import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Date range filter row with tap-to-select picker
/// Uses Minimal theme color system
///
/// Shows:
/// - Current date range or "All dates" when no range set
/// - Primary color highlight when range is active
/// - Clear button to remove filter
class GroupDateRangeFilter extends StatelessWidget {
  final DateTimeRange? selectedDateRange;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const GroupDateRangeFilter({
    super.key,
    required this.selectedDateRange,
    required this.onTap,
    required this.onClear,
  });

  String _formatDateRange() {
    if (selectedDateRange == null) return 'All dates';
    final start = selectedDateRange!.start;
    final end = selectedDateRange!.end;
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    if (start.year != end.year) {
      // Format with year when crossing years: Dec 29 '25 - Jan 3 '26
      final startYr = start.year.toString().substring(2);
      final endYr = end.year.toString().substring(2);
      return "${monthNames[start.month - 1]} ${start.day} '$startYr - ${monthNames[end.month - 1]} ${end.day} '$endYr";
    } else {
      // Format without year: Dec 27 - Jan 3
      return '${monthNames[start.month - 1]} ${start.day} - ${monthNames[end.month - 1]} ${end.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final hasRange = selectedDateRange != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            // Per Minimal theme: solid colors only, no gradients
            color: hasRange
                ? colorScheme.primary
                : colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasRange
                  ? Colors.transparent
                  : colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.date_range_rounded,
                size: 18,
                color: hasRange ? colorScheme.onPrimary : appColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _formatDateRange(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: hasRange ? FontWeight.w600 : FontWeight.w500,
                    color: hasRange ? colorScheme.onPrimary : appColors.textSecondary,
                  ),
                ),
              ),
              if (hasRange)
                GestureDetector(
                  onTap: onClear,
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: colorScheme.onPrimary.withValues(alpha: 0.8),
                  ),
                )
              else
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: appColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
