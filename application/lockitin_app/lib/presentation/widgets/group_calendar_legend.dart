import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Legend widget for the group calendar availability heatmap
/// Uses Minimal theme color system (grayscale + emerald for availability)
///
/// Shows:
/// - Color scale from "Less" (busy) to "More" (available)
/// - Emerald indicator for full availability
/// - Today indicator explanation
class GroupCalendarLegend extends StatelessWidget {
  const GroupCalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final appColors = context.appColors;

    // Build heatmap scale colors based on theme brightness
    // Per Minimal theme: grayscale for busy, emerald only for full availability
    final heatmapColors = [
      brightness == Brightness.dark ? AppColors.neutral900 : AppColors.gray100,
      brightness == Brightness.dark ? AppColors.neutral800 : AppColors.gray200,
      brightness == Brightness.dark ? AppColors.neutral700 : AppColors.gray300,
      brightness == Brightness.dark ? AppColors.neutral600 : AppColors.gray400,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          // Today indicator
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Today',
                style: TextStyle(
                  fontSize: 11,
                  color: appColors.textMuted,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Availability scale
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Less',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: appColors.textMuted,
                ),
              ),
              const SizedBox(width: 6),
              // Grayscale boxes from dark (busy) to light
              ...heatmapColors.map(
                (color) => Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // Emerald box for 100% available (only functional color)
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'All free',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: appColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
