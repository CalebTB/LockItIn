import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/event_model.dart';
import '../../utils/privacy_colors.dart';

/// Full-screen month grid view
/// Features:
/// - 7-column calendar grid filling available space
/// - Event dots (max 3 + overflow indicator)
/// - Tap cell to select day
/// - Month navigation
class MonthGridView extends StatelessWidget {
  final List<EventModel> events;
  final DateTime focusedMonth;
  final DateTime? selectedDate;
  final void Function(DateTime date)? onDateSelected;
  final void Function(DateTime month)? onMonthChanged;

  const MonthGridView({
    super.key,
    required this.events,
    required this.focusedMonth,
    this.selectedDate,
    this.onDateSelected,
    this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Column(
      children: [
        // Month navigation header
        _buildMonthHeader(context, colorScheme, appColors),

        // Day of week headers
        _buildDayHeaders(context, appColors),

        // Calendar grid
        Expanded(
          child: _buildCalendarGrid(context, colorScheme, appColors),
        ),
      ],
    );
  }

  Widget _buildMonthHeader(
    BuildContext context,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              final previousMonth = DateTime(
                focusedMonth.year,
                focusedMonth.month - 1,
                1,
              );
              onMonthChanged?.call(previousMonth);
            },
            icon: Icon(
              Icons.chevron_left_rounded,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            DateFormat('MMMM yyyy').format(focusedMonth),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          IconButton(
            onPressed: () {
              final nextMonth = DateTime(
                focusedMonth.year,
                focusedMonth.month + 1,
                1,
              );
              onMonthChanged?.call(nextMonth);
            },
            icon: Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayHeaders(BuildContext context, AppColorsExtension appColors) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: days.map((day) {
          return Expanded(
            child: Text(
              day,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: appColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(
    BuildContext context,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    final today = DateTime.now();
    final daysInMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final startingWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    // Previous month days to show
    final prevMonth = DateTime(focusedMonth.year, focusedMonth.month, 0);
    final prevMonthDays = prevMonth.day;

    // Replaced GridView.builder with Table for better performance on fixed grids
    // Table provides O(1) layout per frame with no virtualization overhead
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: RepaintBoundary(
        // SINGLE RepaintBoundary for entire grid (not per-cell)
        // Research shows 42 boundaries = counterproductive (~420KB overhead)
        child: Table(
          children: List.generate(6, (weekIndex) {
            return TableRow(
              children: List.generate(7, (dayIndex) {
                final index = weekIndex * 7 + dayIndex;
                DateTime date;
                bool isCurrentMonth = true;

                if (index < startingWeekday) {
                  // Previous month
                  final day = prevMonthDays - (startingWeekday - index - 1);
                  date = DateTime(prevMonth.year, prevMonth.month, day);
                  isCurrentMonth = false;
                } else if (index >= startingWeekday + daysInMonth) {
                  // Next month
                  final day = index - startingWeekday - daysInMonth + 1;
                  date = DateTime(focusedMonth.year, focusedMonth.month + 1, day);
                  isCurrentMonth = false;
                } else {
                  // Current month
                  final day = index - startingWeekday + 1;
                  date = DateTime(focusedMonth.year, focusedMonth.month, day);
                }

                final isToday = _isSameDay(date, today);
                final isSelected = selectedDate != null && _isSameDay(date, selectedDate!);
                final dayEvents = _getEventsForDay(date);
                final hasEvents = dayEvents.isNotEmpty;

                // Padding wrapper provides spacing between cells (replaces GridView spacing)
                return Padding(
                  padding: const EdgeInsets.all(1), // Provides 2px total spacing (1+1)
                  child: AspectRatio(
                    aspectRatio: 0.85, // Slightly taller cells for event dots
                    child: GestureDetector(
                      onTap: () => onDateSelected?.call(date),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary
                              : isToday
                                  ? colorScheme.primary.withValues(alpha: 0.1)
                                  : null,
                          borderRadius: BorderRadius.circular(8),
                          border: isToday && !isSelected
                              ? Border.all(
                                  color: colorScheme.primary,
                                  width: 1.5,
                                )
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Date number
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isToday || isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? colorScheme.onPrimary
                                    : isCurrentMonth
                                        ? colorScheme.onSurface
                                        : appColors.textDisabled,
                              ),
                            ),

                            // Event dots
                            if (hasEvents) ...[
                              const SizedBox(height: 4),
                              _buildEventDots(
                                dayEvents,
                                colorScheme,
                                isSelected,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildEventDots(
    List<EventModel> dayEvents,
    ColorScheme colorScheme,
    bool isSelected,
  ) {
    final displayEvents = dayEvents.take(3).toList();
    final hasMore = dayEvents.length > 3;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...displayEvents.map((event) {
          final color = PrivacyColors.getPrivacyColor(event.visibility);
          return Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.onPrimary : color,
              shape: BoxShape.circle,
            ),
          );
        }),
        if (hasMore)
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(left: 1),
            alignment: Alignment.center,
            child: Text(
              '+',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
              ),
            ),
          ),
      ],
    );
  }

  List<EventModel> _getEventsForDay(DateTime day) {
    return events.where((event) {
      return _isSameDay(event.startTime, day);
    }).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
