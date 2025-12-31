import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../providers/calendar_provider.dart';
import '../../../providers/group_provider.dart';
import '../group_detail_screen.dart';

/// Helper class to hold cell colors for the heatmap calendar
class CellColors {
  final Color background;
  final Color text;
  final Color subtext;

  const CellColors({
    required this.background,
    required this.text,
    required this.subtext,
  });
}

/// Availability heatmap calendar grid for GroupDetailScreen
class GroupCalendarGrid extends StatelessWidget {
  final DateTime month;
  final DateTime? selectedDate;
  final DateTimeRange? selectedDateRange;
  final DayViewStyle dayViewStyle;
  final bool isLoadingMemberEvents;
  final int Function(DateTime date) getAvailabilityForDay;
  final void Function(DateTime date) onDayTapped;
  final void Function(int day) onDaySelected;

  const GroupCalendarGrid({
    super.key,
    required this.month,
    required this.selectedDate,
    required this.selectedDateRange,
    required this.dayViewStyle,
    required this.isLoadingMemberEvents,
    required this.getAvailabilityForDay,
    required this.onDayTapped,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final startWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Consumer2<CalendarProvider, GroupProvider>(
      builder: (context, calendarProvider, groupProvider, _) {
        final colorScheme = Theme.of(context).colorScheme;
        final appColors = context.appColors;
        final brightness = Theme.of(context).brightness;
        final totalMembers = groupProvider.selectedGroupMembers.isNotEmpty
            ? groupProvider.selectedGroupMembers.length
            : (groupProvider.selectedGroup?.memberCount ?? 1);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              // Day headers
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Row(
                  children: days.asMap().entries.map((entry) {
                    final index = entry.key;
                    final day = entry.value;
                    final isWeekend = index == 0 || index == 6;
                    return Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isWeekend
                                ? appColors.textMuted
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: 42,
                  itemBuilder: (context, index) {
                    final dayNumber = index - startWeekday + 1;

                    if (dayNumber < 1 || dayNumber > daysInMonth) {
                      return const SizedBox.shrink();
                    }

                    final date = DateTime(month.year, month.month, dayNumber);
                    final isToday = date.isAtSameMomentAs(today);
                    final isPast = date.isBefore(today);
                    // Only show selection if this exact date matches selectedDate
                    final isSelected = selectedDate != null &&
                        selectedDate!.day == dayNumber &&
                        selectedDate!.month == month.month &&
                        selectedDate!.year == month.year;

                    final isInRange = selectedDateRange == null ||
                        (!date.isBefore(selectedDateRange!.start) &&
                         !date.isAfter(selectedDateRange!.end));

                    final available = (isInRange && !isPast)
                        ? getAvailabilityForDay(date)
                        : 0;

                    final isFullyAvailable = isInRange && !isPast &&
                        available == totalMembers && totalMembers > 0;

                    final cellColors = _getCellColors(
                      isPast: isPast,
                      isInRange: isInRange,
                      isFullyAvailable: isFullyAvailable,
                      available: available,
                      totalMembers: totalMembers,
                      brightness: brightness,
                      colorScheme: colorScheme,
                      appColors: appColors,
                    );

                    final semanticLabel = _getSemanticLabelForCell(
                      date: date,
                      isToday: isToday,
                      isPast: isPast,
                      isInRange: isInRange,
                      available: available,
                      totalMembers: totalMembers,
                    );

                    return Semantics(
                      button: !isPast,
                      label: semanticLabel,
                      selected: isSelected,
                      child: GestureDetector(
                        onTap: isPast
                            ? null
                            : () {
                                if (dayViewStyle == DayViewStyle.classic) {
                                  HapticFeedback.selectionClick();
                                  onDaySelected(dayNumber);
                                } else {
                                  onDayTapped(date);
                                }
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOut,
                          decoration: BoxDecoration(
                            color: cellColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: _getCellBorder(
                              isToday: isToday,
                              isSelected: isSelected,
                              colorScheme: colorScheme,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: colorScheme.primary.withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (isToday && !isSelected)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$dayNumber',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isToday || isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: cellColors.text,
                                    ),
                                  ),
                                  if (!isPast && isInRange)
                                    isLoadingMemberEvents
                                        ? Padding(
                                            padding: const EdgeInsets.only(top: 3),
                                            child: SizedBox(
                                              width: 8,
                                              height: 8,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 1.5,
                                                color: cellColors.text.withValues(alpha: 0.5),
                                              ),
                                            ),
                                          )
                                        : Padding(
                                            padding: const EdgeInsets.only(top: 3),
                                            child: Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: _getHeatmapDotColor(available, totalMembers),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: _getHeatmapDotColor(available, totalMembers)
                                                        .withValues(alpha: 0.4),
                                                    blurRadius: 3,
                                                    spreadRadius: 0,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Border? _getCellBorder({
    required bool isToday,
    required bool isSelected,
    required ColorScheme colorScheme,
  }) {
    if (isSelected) {
      return Border.all(color: colorScheme.primary, width: 2.5);
    }
    if (isToday) {
      return Border.all(color: colorScheme.primary.withValues(alpha: 0.5), width: 1.5);
    }
    return null;
  }

  CellColors _getCellColors({
    required bool isPast,
    required bool isInRange,
    required bool isFullyAvailable,
    required int available,
    required int totalMembers,
    required Brightness brightness,
    required ColorScheme colorScheme,
    required AppColorsExtension appColors,
  }) {
    if (isPast) {
      return CellColors(
        background: colorScheme.surfaceContainerLow,
        text: appColors.textDisabled,
        subtext: appColors.textDisabled,
      );
    }

    if (!isInRange) {
      return CellColors(
        background: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        text: colorScheme.onSurface.withValues(alpha: 0.3),
        subtext: colorScheme.onSurface.withValues(alpha: 0.2),
      );
    }

    if (isFullyAvailable) {
      return CellColors(
        background: AppColors.success,
        text: Colors.white,
        subtext: Colors.white.withValues(alpha: 0.9),
      );
    }

    final backgroundColor = _getHeatmapBackgroundColor(available, totalMembers, brightness);
    final textColor = _getHeatmapTextColor(available, totalMembers, brightness);

    return CellColors(
      background: backgroundColor,
      text: textColor,
      subtext: textColor.withValues(alpha: 0.8),
    );
  }

  Color _getHeatmapBackgroundColor(int available, int total, Brightness brightness) {
    if (total == 0) {
      return brightness == Brightness.dark
          ? AppColors.neutral900
          : AppColors.gray100;
    }
    final ratio = available / total;
    return AppColors.getAvailabilityColor(ratio, brightness);
  }

  Color _getHeatmapTextColor(int available, int total, Brightness brightness) {
    if (total == 0) {
      return brightness == Brightness.dark
          ? AppColors.neutral500
          : AppColors.gray500;
    }
    final ratio = available / total;
    return AppColors.getAvailabilityTextColor(ratio, brightness);
  }

  Color _getHeatmapDotColor(int available, int total) {
    if (total == 0) return AppColors.neutral400;
    final ratio = available / total;
    return AppColors.getAvailabilityDotColor(ratio);
  }

  String _getSemanticLabelForCell({
    required DateTime date,
    required bool isToday,
    required bool isPast,
    required bool isInRange,
    required int available,
    required int totalMembers,
  }) {
    final dateFormat = DateFormat('EEEE, MMMM d');
    final dateStr = dateFormat.format(date);

    final parts = <String>[dateStr];

    if (isToday) {
      parts.add('today');
    }

    if (isPast) {
      parts.add('past date');
    } else if (isInRange) {
      if (available == totalMembers && totalMembers > 0) {
        parts.add('everyone available');
      } else if (available > 0) {
        parts.add('$available of $totalMembers members available');
      } else {
        parts.add('no members available');
      }
      parts.add('double tap to see details');
    } else {
      parts.add('outside selected date range');
    }

    return parts.join(', ');
  }
}
