import 'package:flutter/material.dart';
import '../theme/sunset_coral_theme.dart';

/// Legend widget for the group calendar availability heatmap
///
/// Shows the color scale from "Less" (busy) to "More" (available)
/// with gradient indicator for 100% availability.
class GroupCalendarLegend extends StatelessWidget {
  const GroupCalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: SunsetCoralTheme.rose500.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Availability',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
          Row(
            children: [
              const Text(
                'Less',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              // Solid color boxes (rose-950 to rose-500)
              ...SunsetCoralTheme.heatmapScale.map(
                (color) => Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              // Gradient box (rose-400 to orange-400) for 100% available
              Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  gradient: SunsetCoralTheme.availableGradient,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'More',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
