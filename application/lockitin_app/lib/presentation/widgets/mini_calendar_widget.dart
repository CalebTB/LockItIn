import 'package:flutter/material.dart';

/// Compact mini calendar grid for the card calendar view
/// Shows a 7-column grid with dates and event indicators
class MiniCalendarWidget extends StatelessWidget {
  // Sunset Coral Dark Theme Colors
  static const Color _rose500 = Color(0xFFF43F5E);
  static const Color _rose300 = Color(0xFFFDA4AF);
  static const Color _rose50 = Color(0xFFFFF1F2);
  static const Color _orange500 = Color(0xFFF97316);
  static const Color _amber500 = Color(0xFFF59E0B);
  static const Color _amber300 = Color(0xFFFCD34D);

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
                      color: _rose300.withValues(alpha: 0.6),
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
                    gradient: isSelected || isToday
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_rose500, _orange500],
                          )
                        : null,
                    color: isSelected || isToday
                        ? null
                        : hasEvents
                            ? _amber500.withValues(alpha: 0.2)
                            : null,
                    shape: BoxShape.circle,
                    boxShadow: isSelected || isToday
                        ? [
                            BoxShadow(
                              color: _rose500.withValues(alpha: 0.3),
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
                              ? Colors.white
                              : hasEvents
                                  ? _amber300
                                  : _rose50.withValues(alpha: 0.8),
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
                                color: isSelected || isToday ? Colors.white : color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (isSelected || isToday ? Colors.white : color).withValues(alpha: 0.5),
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
