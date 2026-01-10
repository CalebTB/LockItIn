import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/timezone_utils.dart';

/// Sticky day header for agenda list view
/// Shows formatted date with special labels for TODAY, TOMORROW
/// Uses theme-based colors from the Minimal theme design system
class DayHeader extends StatelessWidget {
  final DateTime date;
  final int eventCount;

  const DayHeader({
    super.key,
    required this.date,
    this.eventCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final isToday = _isToday(date);
    final isTomorrow = _isTomorrow(date);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: appColors.divider,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Date label
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Special label (TODAY, TOMORROW) or day of week
              Text(
                _getDateLabel(date, isToday, isTomorrow),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isToday
                      ? colorScheme.primary
                      : isTomorrow
                          ? colorScheme.secondary
                          : appColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              // Full date
              Text(
                _formatFullDate(date),
                style: TextStyle(
                  fontSize: 12,
                  color: appColors.textMuted,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Event count badge
          if (eventCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isToday
                    ? colorScheme.primary.withValues(alpha: 0.1)
                    : appColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isToday
                      ? colorScheme.primary.withValues(alpha: 0.2)
                      : appColors.cardBorder,
                ),
              ),
              child: Text(
                '$eventCount event${eventCount == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isToday ? colorScheme.primary : appColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  bool _isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
           date.month == tomorrow.month &&
           date.day == tomorrow.day;
  }

  String _getDateLabel(DateTime date, bool isToday, bool isTomorrow) {
    if (isToday) return 'TODAY';
    if (isTomorrow) return 'TOMORROW';
    return TimezoneUtils.formatLocal(date, 'EEEE').toUpperCase();
  }

  String _formatFullDate(DateTime date) {
    return TimezoneUtils.formatLocal(date, 'MMMM d, yyyy');
  }
}
