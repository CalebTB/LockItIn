import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Compact mini calendar grid for the card calendar view
/// Shows a 7-column grid with dates and event indicators
/// Uses theme-based colors from the Minimal theme design system
class MiniCalendarWidget extends StatelessWidget {
  final DateTime selectedDate;
  final DateTime focusedMonth;
  final Map<int, List<Color>> eventIndicators; // day -> list of event colors
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<DateTime>? onMonthChanged;

  const MiniCalendarWidget({
    super.key,
    required this.selectedDate,
    required this.focusedMonth,
    required this.eventIndicators,
    required this.onDateSelected,
    this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final today = DateTime.now();
    final daysInMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final startingWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    // Calculate total cells needed for dates only
    final totalDayCells = startingWeekday + daysInMonth;
    final numWeeks = (totalDayCells / 7).ceil();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Day headers row - minimal height
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
                return Expanded(
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: appColors.textMuted,
                    ),
                  ),
                );
              }).toList(),
          ),

          // Date grid
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              childAspectRatio: 1,
            ),
            itemCount: numWeeks * 7,
            itemBuilder: (context, index) {
              final dayNumber = index - startingWeekday + 1;

              // Check if this cell is a valid day in the month
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }

              final date = DateTime(focusedMonth.year, focusedMonth.month, dayNumber);
              final isSelected = _isSameDay(date, selectedDate);
              final isToday = _isSameDay(date, today);
              final hasEvents = eventIndicators.containsKey(dayNumber);
              final eventColors = eventIndicators[dayNumber] ?? [];

              return GestureDetector(
                onTap: () => onDateSelected(date),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected || isToday
                        ? colorScheme.primary
                        : hasEvents
                            ? colorScheme.secondary.withValues(alpha: 0.15)
                            : null,
                    shape: BoxShape.circle,
                    boxShadow: isSelected || isToday
                        ? [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected || isToday ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected || isToday
                              ? colorScheme.onPrimary
                              : hasEvents
                                  ? colorScheme.secondary
                                  : colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                      if (hasEvents) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: eventColors.take(3).map((color) {
                            return Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 0.5),
                              decoration: BoxDecoration(
                                color: isSelected || isToday
                                    ? colorScheme.onPrimary
                                    : color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (isSelected || isToday
                                        ? colorScheme.onPrimary
                                        : color).withValues(alpha: 0.5),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
