import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../group_detail_screen.dart';

/// Platform-adaptive view mode toggle (Month/Day) for GroupDetailScreen
class ViewModeToggle extends StatelessWidget {
  final GroupCalendarViewMode viewMode;
  final DayViewStyle dayViewStyle;
  final ValueChanged<GroupCalendarViewMode> onViewModeChanged;
  final VoidCallback onDayViewStyleToggle;

  const ViewModeToggle({
    super.key,
    required this.viewMode,
    required this.dayViewStyle,
    required this.onViewModeChanged,
    required this.onDayViewStyleToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Platform.isIOS
                ? _buildCupertinoSegmentedControl(context, colorScheme)
                : _buildMaterialSegmentedButton(context, colorScheme, appColors),
          ),
          const SizedBox(width: 8),
          // Day view style toggle (A/B testing)
          Semantics(
            button: true,
            label: dayViewStyle == DayViewStyle.timeline
                ? 'Switch to classic day view'
                : 'Switch to timeline day view',
            child: GestureDetector(
              onTap: onDayViewStyleToggle,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  dayViewStyle == DayViewStyle.timeline
                      ? Icons.view_agenda_outlined
                      : Icons.calendar_view_day_outlined,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCupertinoSegmentedControl(BuildContext context, ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<GroupCalendarViewMode>(
        groupValue: viewMode,
        backgroundColor: colorScheme.surfaceContainerHigh,
        thumbColor: colorScheme.surface,
        onValueChanged: (value) {
          if (value != null) {
            HapticFeedback.selectionClick();
            onViewModeChanged(value);
          }
        },
        children: {
          GroupCalendarViewMode.month: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_view_month_rounded,
                  size: 16,
                  color: viewMode == GroupCalendarViewMode.month
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  'Month',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: viewMode == GroupCalendarViewMode.month
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          GroupCalendarViewMode.day: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.view_day_rounded,
                  size: 16,
                  color: viewMode == GroupCalendarViewMode.day
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  'Day',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: viewMode == GroupCalendarViewMode.day
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        },
      ),
    );
  }

  Widget _buildMaterialSegmentedButton(
    BuildContext context,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    return SegmentedButton<GroupCalendarViewMode>(
      segments: const [
        ButtonSegment<GroupCalendarViewMode>(
          value: GroupCalendarViewMode.month,
          label: Text('Month'),
          icon: Icon(Icons.calendar_view_month_rounded, size: 18),
        ),
        ButtonSegment<GroupCalendarViewMode>(
          value: GroupCalendarViewMode.day,
          label: Text('Day'),
          icon: Icon(Icons.view_day_rounded, size: 18),
        ),
      ],
      selected: {viewMode},
      onSelectionChanged: (selection) {
        onViewModeChanged(selection.first);
      },
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

/// Toggle bar for classic mode to switch to timeline mode
class ClassicModeToggleBar extends StatelessWidget {
  final VoidCallback onSwitchToTimeline;

  const ClassicModeToggleBar({
    super.key,
    required this.onSwitchToTimeline,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Label showing current mode
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_view_day_outlined,
                  size: 14,
                  color: appColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  'Classic View',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: appColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Switch to timeline button
          Semantics(
            button: true,
            label: 'Switch to timeline day view',
            child: GestureDetector(
              onTap: onSwitchToTimeline,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.view_agenda_outlined,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Try Timeline',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
