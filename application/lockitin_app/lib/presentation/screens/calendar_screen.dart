import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import '../../domain/models/calendar_month.dart';
import '../../data/models/event_model.dart';
import '../../utils/calendar_utils.dart';
import '../../core/services/event_service.dart';
import '../../core/utils/route_transitions.dart';
import 'day_detail_screen.dart';
import 'card_calendar_screen.dart';
import 'event_creation_screen.dart';
import '../../core/utils/timezone_utils.dart';
import '../../core/utils/logger.dart';

/// Calendar screen showing custom month grid view with horizontal swipe navigation
/// Uses CalendarProvider for state management and caching
/// Custom implementation for seamless cell borders and event preview space
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // CalendarProvider is now provided at app level in main.dart
    return const _CalendarView();
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

  /// Handle event creation with dual-write to native calendar and Supabase
  Future<void> _handleCreateEvent(
    BuildContext context,
    CalendarProvider provider,
  ) async {
    Logger.info('CalendarScreen', '=== _handleCreateEvent() called ===');

    // Navigate to event creation screen
    final result = await Navigator.of(context).push<EventModel>(
      SlideRoute(
        page: const EventCreationScreen(
          mode: EventCreationMode.personalEvent,
        ),
      ),
    );

    Logger.info('CalendarScreen', 'Returned from EventCreationScreen');
    Logger.info('CalendarScreen', '  - result != null: ${result != null}');
    Logger.info('CalendarScreen', '  - context.mounted: ${context.mounted}');
    if (result != null) {
      Logger.info('CalendarScreen', '  - Event ID: ${result.id}');
      Logger.info('CalendarScreen', '  - Event Title: ${result.title}');
    }

    // If user canceled, return early
    if (result == null || !context.mounted) {
      Logger.info('CalendarScreen', 'Early return - not saving event');
      if (result == null) {
        Logger.info('CalendarScreen', '  - Reason: result is null (user cancelled)');
      }
      if (!context.mounted) {
        Logger.info('CalendarScreen', '  - Reason: context not mounted');
      }
      return;
    }

    Logger.info('CalendarScreen', 'Proceeding to save event');

    // Show loading dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Saving event...'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    try {
      Logger.info('CalendarScreen', 'Calling EventService.createEvent()...');
      // Create event using EventService (dual-write)
      final eventService = EventService();
      final savedEvent = await eventService.createEvent(result);
      Logger.info('CalendarScreen', 'EventService.createEvent() completed successfully');

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Add event to provider for immediate UI update
      provider.addEvent(savedEvent);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event "${savedEvent.title}" created successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on EventServiceException catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show generic error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create event: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
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

                      // Card View Toggle
                      Consumer<CalendarProvider>(
                        builder: (context, provider, _) => IconButton(
                          icon: Icon(Icons.view_agenda_rounded, color: colorScheme.primary),
                          onPressed: () {
                            Navigator.of(context).push(
                              SlideRoute(
                                page: ChangeNotifierProvider.value(
                                  value: provider,
                                  child: const CardCalendarScreen(),
                                ),
                              ),
                            );
                          },
                          iconSize: 24,
                          padding: const EdgeInsets.all(12),
                          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                          tooltip: 'Card View',
                        ),
                      ),

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
                        TimezoneUtils.formatLocal(provider.currentMonth, 'MMMM yyyy'),
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
      floatingActionButton: Consumer<CalendarProvider>(
        builder: (context, provider, _) => FloatingActionButton(
          onPressed: () => _handleCreateEvent(context, provider),
          backgroundColor: colorScheme.primary,
          child: const Icon(Icons.add, size: 28),
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

              return Expanded(
                child: _buildDateCell(
                  context,
                  date,
                  isToday: isToday,
                  isSelected: isSelected,
                  isOutside: !isCurrentMonth,
                  hasEvents: hasEvents,
                  events: events,
                  onTap: () {
                    provider.selectDate(date);
                    // Navigate to day detail screen (reads events from CalendarProvider)
                    Navigator.of(context).push(
                      SlideRoute(
                        page: DayDetailScreen(
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
    required List<dynamic> events,
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

    // Check if this day has any holiday events
    final hasHolidayEvent = events.any((event) => event.category == EventCategory.holiday);

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
                : (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday)
                    ? colorScheme.tertiary.withValues(alpha: 0.1)
                    : Colors.transparent,
            border: hasHolidayEvent
                ? Border(
                    left: BorderSide(color: colorScheme.tertiary, width: 2),
                    top: BorderSide(color: borderColor, width: 0.5),
                    right: BorderSide(color: borderColor, width: 0.5),
                    bottom: BorderSide(color: borderColor, width: 0.5),
                  )
                : Border.all(
                    color: borderColor,
                    width: 0.5,
                  ),
          ),
        child: Padding(
          // Internal padding for content - reduced to move date numbers closer to corner
          padding: const EdgeInsets.all(4.0),
          child: Stack(
            children: [
              // Main content - date number and event circles
              Column(
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
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colorScheme.primary,   // Deep Blue
                                colorScheme.secondary, // Purple
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          )
                        : null,
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                        color: isToday
                            ? Colors.white
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Event indicators as colored circles
                  if (hasEvents)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Wrap(
                          spacing: 3,
                          runSpacing: 3,
                          children: [
                            // Show up to 6 colored circles
                            ...events.take(6).map(
                              (event) => Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: CalendarUtils.getCategoryColor(event.category),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 1,
                                      offset: const Offset(0, 0.5),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Show "+X" text if more than 6 events
                            if (events.length > 6)
                              Padding(
                                padding: const EdgeInsets.only(left: 2),
                                child: Text(
                                  '+${events.length - 6}',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                                    height: 1.0,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              // Event count badge positioned at bottom-right
              if (hasEvents)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.secondary.withValues(alpha: 0.7), // Purple
                          colorScheme.tertiary.withValues(alpha: 0.7),  // Warm Coral
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      '${events.length}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
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
