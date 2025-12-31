import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Legend widget for the group calendar availability heatmap
/// Uses 5-tier semantic colors: Green → Lime → Yellow → Orange → Red
///
/// Shows:
/// - "Availability Calendar" header label
/// - Five colored dots showing availability gradient
class GroupCalendarLegend extends StatelessWidget {
  const GroupCalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // "Availability Calendar" label
          Text(
            'AVAILABILITY CALENDAR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: appColors.textMuted,
            ),
          ),
          // 5-tier color dots legend (green → lime → yellow → orange → red)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Green dot - perfect availability (>85%)
              _buildColorDot(AppColors.availabilityPerfect),
              // Lime dot - high availability (65-85%)
              _buildColorDot(AppColors.availabilityHigh),
              // Amber dot - medium availability (50-65%)
              _buildColorDot(AppColors.availabilityMedium),
              // Orange dot - low availability (25-50%)
              _buildColorDot(AppColors.availabilityLow),
              // Red dot - poor availability (<25%)
              _buildColorDot(AppColors.availabilityPoor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
