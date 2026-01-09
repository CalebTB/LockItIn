import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../widgets/adaptive_icon_button.dart';

/// Month navigation controls for GroupDetailScreen calendar
class MonthNavigation extends StatelessWidget {
  final DateTime focusedMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const MonthNavigation({
    super.key,
    required this.focusedMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AdaptiveIconButton(
            onPressed: onPreviousMonth,
            icon: Icons.chevron_left,
            iconSize: 24,
            color: colorScheme.onSurfaceVariant,
            tooltip: 'Previous month',
          ),
          Text(
            DateFormat('MMMM yyyy').format(focusedMonth),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          AdaptiveIconButton(
            onPressed: onNextMonth,
            icon: Icons.chevron_right,
            iconSize: 24,
            color: colorScheme.onSurfaceVariant,
            tooltip: 'Next month',
          ),
        ],
      ),
    );
  }
}
