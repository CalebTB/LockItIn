import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/event_model.dart';

/// Week grid view showing 7 days with hourly time slots
/// Features:
/// - 7 columns for days of the week
/// - Time slots from 6am to midnight
/// - Events displayed as colored blocks
/// - Current time indicator (red line)
class WeekGridView extends StatelessWidget {
  final List<EventModel> events;
  final DateTime focusedDate;
  final void Function(EventModel event)? onEventTap;
  final void Function(DateTime date)? onDayTap;

  /// Start hour for the grid (default 6am)
  final int startHour;

  /// End hour for the grid (default midnight/24)
  final int endHour;

  const WeekGridView({
    super.key,
    required this.events,
    required this.focusedDate,
    this.onEventTap,
    this.onDayTap,
    this.startHour = 6,
    this.endHour = 24,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final weekDays = _getWeekDays(focusedDate);
    final totalHours = endHour - startHour;

    return Column(
      children: [
        // Day headers
        _buildDayHeaders(context, colorScheme, appColors, weekDays),

        // Scrollable time grid
        Expanded(
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time labels column
                _buildTimeLabels(context, appColors, totalHours),

                // Day columns with events
                Expanded(
                  child: _buildDayColumns(
                    context,
                    colorScheme,
                    appColors,
                    weekDays,
                    totalHours,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayHeaders(
    BuildContext context,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
    List<DateTime> weekDays,
  ) {
    final today = DateTime.now();

    return Container(
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
          // Empty cell for time column alignment
          const SizedBox(width: 48),

          // Day headers
          ...weekDays.map((day) {
            final isToday = _isSameDay(day, today);
            return Expanded(
              child: GestureDetector(
                onTap: onDayTap != null ? () => onDayTap!(day) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isToday
                        ? colorScheme.primary.withValues(alpha: 0.1)
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('E').format(day).toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isToday
                              ? colorScheme.primary
                              : appColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isToday ? colorScheme.primary : null,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isToday
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimeLabels(
    BuildContext context,
    AppColorsExtension appColors,
    int totalHours,
  ) {
    return SizedBox(
      width: 48,
      child: Column(
        children: List.generate(totalHours, (index) {
          final hour = startHour + index;
          final timeLabel = _formatHour(hour);

          return Container(
            height: 48,
            alignment: Alignment.topRight,
            padding: const EdgeInsets.only(right: 8, top: 0),
            child: Text(
              timeLabel,
              style: TextStyle(
                fontSize: 11,
                color: appColors.textMuted,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayColumns(
    BuildContext context,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
    List<DateTime> weekDays,
    int totalHours,
  ) {
    final now = DateTime.now();
    final gridHeight = totalHours * 48.0;

    return SizedBox(
      height: gridHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final dayWidth = availableWidth / 7;

          return Stack(
            children: [
              // Grid background
              Row(
                children: weekDays.map((day) {
                  return Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: appColors.divider,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Column(
                        children: List.generate(totalHours, (hourIndex) {
                          return Container(
                            height: 48,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: appColors.divider.withValues(alpha: 0.5),
                                  width: 0.5,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Events for each day
              ...weekDays.asMap().entries.expand((entry) {
                final dayIndex = entry.key;
                final day = entry.value;
                final dayEvents = _getEventsForDay(day);
                return dayEvents.map((event) => _buildEventBlock(
                      context,
                      colorScheme,
                      appColors,
                      event,
                      dayIndex,
                      dayWidth,
                    ));
              }),

              // Current time indicator
              if (_isCurrentWeek(weekDays, now))
                _buildCurrentTimeIndicator(colorScheme, weekDays, now, totalHours),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventBlock(
    BuildContext context,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
    EventModel event,
    int dayIndex,
    double dayWidth,
  ) {
    final startMinutes = (event.startTime.hour - startHour) * 60 + event.startTime.minute;
    final endMinutes = (event.endTime.hour - startHour) * 60 + event.endTime.minute;
    final durationMinutes = endMinutes - startMinutes;

    // Calculate position and size
    final top = startMinutes * (48.0 / 60.0);
    final height = (durationMinutes * (48.0 / 60.0)).clamp(20.0, double.infinity);

    // Skip events outside the visible range
    if (startMinutes < 0 || top < 0) return const SizedBox.shrink();

    final accentColor = _getCategoryColor(event.category, colorScheme);

    return Positioned(
      top: top,
      left: dayIndex * dayWidth + 2,
      width: dayWidth - 4,
      height: height,
      child: GestureDetector(
        onTap: onEventTap != null ? () => onEventTap!(event) : null,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border(
              left: BorderSide(
                color: accentColor,
                width: 3,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event.emoji != null)
                Text(
                  event.emoji!,
                  style: const TextStyle(fontSize: 10),
                ),
              Expanded(
                child: Text(
                  event.title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTimeIndicator(
    ColorScheme colorScheme,
    List<DateTime> weekDays,
    DateTime now,
    int totalHours,
  ) {
    final dayIndex = weekDays.indexWhere((day) => _isSameDay(day, now));
    if (dayIndex == -1) return const SizedBox.shrink();

    final currentMinutes = (now.hour - startHour) * 60 + now.minute;
    if (currentMinutes < 0 || currentMinutes > totalHours * 60) {
      return const SizedBox.shrink();
    }

    final top = currentMinutes * (48.0 / 60.0);

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: colorScheme.error,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(
              height: 2,
              color: colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  List<DateTime> _getWeekDays(DateTime date) {
    // Find the start of the week (Sunday)
    final weekStart = date.subtract(Duration(days: date.weekday % 7));
    return List.generate(7, (i) => weekStart.add(Duration(days: i)));
  }

  List<EventModel> _getEventsForDay(DateTime day) {
    return events.where((event) {
      return _isSameDay(event.startTime, day);
    }).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isCurrentWeek(List<DateTime> weekDays, DateTime now) {
    return weekDays.any((day) => _isSameDay(day, now));
  }

  String _formatHour(int hour) {
    if (hour == 0 || hour == 24) return '12 AM';
    if (hour == 12) return '12 PM';
    if (hour < 12) return '$hour AM';
    return '${hour - 12} PM';
  }

  Color _getCategoryColor(EventCategory category, ColorScheme colorScheme) {
    switch (category) {
      case EventCategory.work:
        return AppColors.categoryWork;
      case EventCategory.holiday:
        return AppColors.categoryHoliday;
      case EventCategory.friend:
        return AppColors.categoryFriend;
      case EventCategory.other:
        return AppColors.categoryOther;
    }
  }
}
