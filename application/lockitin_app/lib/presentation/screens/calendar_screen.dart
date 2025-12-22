import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import '../../domain/models/calendar_month.dart';
import '../../utils/calendar_utils.dart';
import 'day_detail_screen.dart';

/// Calendar screen showing custom month grid view with horizontal swipe navigation
/// Uses CalendarProvider for state management and caching
/// Custom implementation for seamless cell borders and event preview space
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CalendarProvider(),
      child: const _CalendarView(),
    );
  }
}

class _CalendarView extends StatefulWidget {
  const _CalendarView();

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<CalendarProvider>();
    // Calculate initial page index (current month offset from first month)
    final initialIndex = provider.months.indexWhere(
      (monthData) => CalendarUtils.isSameMonth(monthData.month, provider.focusedDate),
    );
    _pageController = PageController(initialPage: initialIndex >= 0 ? initialIndex : 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Compact Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // App Icon + Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.calendar_month_rounded,
                          color: colorScheme.onPrimary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'LockItIn',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),

                  // Right Controls
                  Row(
                    children: [
                      // Today Button
                      Consumer<CalendarProvider>(
                        builder: (context, provider, _) => TextButton.icon(
                          onPressed: () {
                            // Use dynamic today index (handles month boundary crossings)
                            final todayIndex = provider.todayMonthIndex;
                            _pageController.jumpToPage(todayIndex);
                            // Update provider state (triggers via onPageChanged callback)
                            provider.goToToday();
                          },
                          icon: const Icon(Icons.today, size: 16),
                          label: const Text('Today'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: const Size(0, 44),
                            foregroundColor: colorScheme.primary,
                            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Profile Icon
                      IconButton(
                        icon: Icon(Icons.person_rounded, color: colorScheme.primary),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        iconSize: 24,
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Month Header with Navigation
            Consumer<CalendarProvider>(
              builder: (context, provider, _) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(provider.focusedDate),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.chevron_left, color: colorScheme.primary),
                            onPressed: () {
                              if (_pageController.page! > 0) {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            iconSize: 24,
                          ),
                          IconButton(
                            icon: Icon(Icons.chevron_right, color: colorScheme.primary),
                            onPressed: () {
                              if (_pageController.page! < provider.months.length - 1) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            iconSize: 24,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            // Days of Week Header
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                  child: Row(
                    children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
                      return Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Divider line below days header matching cell border opacity
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: colorScheme.onSurface.withValues(alpha: 0.08),
                ),
              ],
            ),

            // Custom Calendar Grid with PageView for horizontal scroll
            Expanded(
              child: Consumer<CalendarProvider>(
                builder: (context, provider, _) {
                  return PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      if (index >= 0 && index < provider.months.length) {
                        provider.selectDate(provider.months[index].month);
                      }
                    },
                    itemCount: provider.months.length,
                    itemBuilder: (context, pageIndex) {
                      final monthData = provider.months[pageIndex];
                      return _buildMonthGrid(context, monthData, provider);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the month grid with seamlessly touching cells
  Widget _buildMonthGrid(BuildContext context, CalendarMonth monthData, CalendarProvider provider) {
    // Get all dates for the month grid (including padding from prev/next month)
    final firstDayOfMonth = DateTime(monthData.month.year, monthData.month.month, 1);
    final lastDayOfMonth = DateTime(monthData.month.year, monthData.month.month + 1, 0);

    // Calculate padding needed (start from Sunday)
    final startWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    // Build list of all dates to display (6 rows of 7 days = 42 cells)
    final List<DateTime?> dates = [];

    // Add previous month padding
    final prevMonthLastDay = DateTime(monthData.month.year, monthData.month.month, 0);
    for (int i = startWeekday - 1; i >= 0; i--) {
      dates.add(DateTime(prevMonthLastDay.year, prevMonthLastDay.month, prevMonthLastDay.day - i));
    }

    // Add current month days
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      dates.add(DateTime(monthData.month.year, monthData.month.month, day));
    }

    // Add next month padding to complete the grid (always show 6 rows)
    final remainingCells = 42 - dates.length;
    for (int i = 1; i <= remainingCells; i++) {
      dates.add(DateTime(monthData.month.year, monthData.month.month + 1, i));
    }

    // Build grid (6 rows × 7 columns)
    return Column(
      children: List.generate(6, (rowIndex) {
        return Expanded(
          child: Row(
            children: List.generate(7, (colIndex) {
              final cellIndex = rowIndex * 7 + colIndex;
              final date = dates[cellIndex];

              if (date == null) {
                return Expanded(child: Container());
              }

              final isCurrentMonth = date.month == monthData.month.month;
              final isToday = CalendarUtils.isToday(date);
              final isSelected = CalendarUtils.isSameDay(date, provider.focusedDate);

              final hasEvents = provider.hasEvents(date);
              final events = provider.getEventsForDay(date);
              final eventCount = events.length;

              return Expanded(
                child: _buildDateCell(
                  context,
                  date,
                  isToday: isToday,
                  isSelected: isSelected,
                  isOutside: !isCurrentMonth,
                  hasEvents: hasEvents,
                  eventCount: eventCount,
                  onTap: () {
                    provider.selectDate(date);
                    // Navigate to day detail screen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DayDetailScreen(
                          selectedDate: date,
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  /// Build custom date cell with border outline
  /// Cells touch each other seamlessly with shared borders
  /// Cell height is managed by Expanded in parent Row
  Widget _buildDateCell(
    BuildContext context,
    DateTime day,
    {
    required bool isToday,
    required bool isSelected,
    required bool isOutside,
    required bool hasEvents,
    required int eventCount,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    // FIX: Hide dates outside current month - show empty cell with subtle border
    if (isOutside) {
      return Container(
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          border: Border.all(
            color: colorScheme.onSurface.withValues(alpha: 0.03),
            width: 0.5,
          ),
        ),
      );
    }

    // Determine border color for current month dates
    final borderColor = colorScheme.onSurface.withValues(alpha: 0.08);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: colorScheme.primary.withValues(alpha: 0.05),
        child: Container(
          // NO margin - cells touch seamlessly
          margin: EdgeInsets.zero,
          // Border on all sides - cells will share borders perfectly
          decoration: BoxDecoration(
            color: isToday
                ? colorScheme.primaryContainer.withValues(alpha: 0.1)
                : Colors.transparent,
            border: Border.all(
              color: borderColor,
              width: 0.5,
            ),
          ),
        child: Padding(
          // Internal padding for content - reduced to move date numbers closer to corner
          padding: const EdgeInsets.all(4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Date number with today indicator
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: isToday
                    ? BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      )
                    : null,
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                    color: isToday
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // Event indicators
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (hasEvents) ...[
                      // Show up to 3 event dots, then "+X" indicator
                      if (eventCount <= 3)
                        ...List.generate(
                          eventCount,
                          (index) => Container(
                            height: 3,
                            margin: const EdgeInsets.only(bottom: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                        )
                      else ...[
                        // Show 2 dots + "+X more" indicator
                        ...List.generate(
                          2,
                          (index) => Container(
                            height: 3,
                            margin: const EdgeInsets.only(bottom: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            '+${eventCount - 2}',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
