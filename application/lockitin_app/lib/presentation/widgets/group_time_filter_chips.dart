import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/time_filter_utils.dart';

/// Row of time filter chips for filtering group availability
/// Uses Minimal theme color system
///
/// Displays chips for: Custom, Morning, Afternoon, Evening, Night
/// Supports multi-select (except Custom which is exclusive).
class GroupTimeFilterChips extends StatelessWidget {
  final Set<TimeFilter> selectedFilters;
  final ValueChanged<TimeFilter> onFilterTap;
  final VoidCallback onCustomTap;

  const GroupTimeFilterChips({
    super.key,
    required this.selectedFilters,
    required this.onFilterTap,
    required this.onCustomTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: TimeFilter.values.map((filter) {
          final isSelected = selectedFilters.contains(filter);

          // For "All Day", show "Custom" label instead
          final label = filter == TimeFilter.allDay ? 'Custom' : filter.label;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
                onTap: () {
                  if (filter == TimeFilter.allDay) {
                    // Show custom time picker
                    onCustomTap();
                  } else {
                    onFilterTap(filter);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    // Per Minimal theme: solid primary color when selected, no gradients
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : appColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
