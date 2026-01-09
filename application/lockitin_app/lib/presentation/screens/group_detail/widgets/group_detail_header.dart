import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/time_filter_utils.dart';
import '../../../../data/models/group_model.dart';
import '../../../widgets/adaptive_icon_button.dart';
import '../../../widgets/group_filters_sheet.dart';

/// Header widget for GroupDetailScreen
/// Contains back button, group info, and action buttons (filter, members, settings)
class GroupDetailHeader extends StatelessWidget {
  final GroupModel group;
  final DateTimeRange? selectedDateRange;
  final Set<TimeFilter> selectedTimeFilters;
  final VoidCallback onBackPressed;
  final VoidCallback onFilterPressed;
  final VoidCallback onMembersPressed;
  final VoidCallback onSettingsPressed;

  const GroupDetailHeader({
    super.key,
    required this.group,
    required this.selectedDateRange,
    required this.selectedTimeFilters,
    required this.onBackPressed,
    required this.onFilterPressed,
    required this.onMembersPressed,
    required this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          // Back button
          Semantics(
            button: true,
            label: 'Go back',
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: AppSpacing.minTouchTarget,
                minHeight: AppSpacing.minTouchTarget,
              ),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onBackPressed();
                },
                child: Center(
                  child: Icon(
                    Icons.chevron_left,
                    size: 28,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Group emoji badge
          ExcludeSemantics(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  group.emoji,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Group name and member count
          Expanded(
            child: Semantics(
              header: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    group.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${group.memberCount} members',
                    style: TextStyle(
                      fontSize: 12,
                      color: appColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Filter button with badge
          _buildFilterButton(context, colorScheme),
          const SizedBox(width: 8),
          // Members button
          Semantics(
            button: true,
            label: 'View ${group.memberCount} members',
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: AppSpacing.minTouchTarget,
                minHeight: AppSpacing.minTouchTarget,
              ),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onMembersPressed();
                },
                child: Center(
                  child: Icon(
                    Icons.people_rounded,
                    size: 22,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Settings button
          Semantics(
            button: true,
            label: 'Open group settings',
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: AppSpacing.minTouchTarget,
                minHeight: AppSpacing.minTouchTarget,
              ),
              child: GestureDetector(
                onTap: onSettingsPressed,
                child: Center(
                  child: Icon(
                    Icons.more_vert_rounded,
                    size: 22,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context, ColorScheme colorScheme) {
    final activeCount = GroupFiltersSheet.getActiveFilterCount(
      selectedDateRange,
      selectedTimeFilters,
    );

    return Semantics(
      button: true,
      label: activeCount > 0
          ? '$activeCount filters active, tap to change'
          : 'Open filters',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AdaptiveIconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              onFilterPressed();
            },
            icon: Icons.tune_rounded,
            iconSize: 20,
            color: activeCount > 0
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            tooltip: 'Filters',
          ),
          if (activeCount > 0)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$activeCount',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
