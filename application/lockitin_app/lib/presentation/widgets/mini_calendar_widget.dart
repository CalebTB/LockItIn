import 'package:flutter/material.dart';

/// Compact mini calendar grid for the card calendar view
/// Shows a 7-column grid with dates and event indicators
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
    final today = DateTime.now();
    final daysInMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final startingWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Day headers (S M T W T F S)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
              return SizedBox(
                width: 36,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              );
            }).toList(),
          ),

          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemCount: 42, // 6 weeks
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
                    gradient: isSelected
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme.primary,
                              colorScheme.primary.withValues(alpha: 0.8),
                            ],
                          )
                        : null,
                    color: isSelected
                        ? null
                        : hasEvents && !isToday
                            ? _getEventBackgroundColor(eventColors).withValues(alpha: 0.15)
                            : isToday
                                ? colorScheme.primary.withValues(alpha: 0.1)
                                : null,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isSelected
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
                          fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : hasEvents
                                  ? _getEventBackgroundColor(eventColors)
                                  : isToday
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                        ),
                      ),
                      if (hasEvents && !isSelected) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: eventColors.take(3).map((color) {
                            return Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
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

  Color _getEventBackgroundColor(List<Color> colors) {
    if (colors.isEmpty) return Colors.grey;
    return colors.first;
  }
}
