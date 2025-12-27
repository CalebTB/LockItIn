import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import '../../data/models/event_model.dart';
import '../../core/services/event_service.dart';
import '../../utils/calendar_utils.dart';
import 'event_creation_screen.dart';
import 'event_detail_screen.dart';

/// Card-based calendar view with horizontal day selector
/// Inspired by modern mobile calendar apps with card UI
class CardCalendarScreen extends StatefulWidget {
  const CardCalendarScreen({super.key});

  @override
  State<CardCalendarScreen> createState() => _CardCalendarScreenState();
}

class _CardCalendarScreenState extends State<CardCalendarScreen> {
  late DateTime _selectedDate;
  late ScrollController _dayScrollController;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _dayScrollController = ScrollController();

    // Auto-scroll to selected day after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDay();
    });
  }

  @override
  void dispose() {
    _dayScrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedDay() {
    if (!_dayScrollController.hasClients) return;

    final dayIndex = _selectedDate.day - 1;
    final scrollOffset = dayIndex * 60.0; // 60px per day card

    _dayScrollController.animateTo(
      scrollOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _selectDay(int day) {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, day);
    });
    _scrollToSelectedDay();
  }

  /// Handle event creation with dual-write to native calendar and Supabase
  Future<void> _handleCreateEvent(CalendarProvider provider) async {
    // Navigate to event creation screen with selected date
    final result = await Navigator.of(context).push<EventModel>(
      MaterialPageRoute(
        builder: (context) => EventCreationScreen(initialDate: _selectedDate),
      ),
    );

    // If user canceled, return early
    if (result == null || !mounted) return;

    // Show loading dialog
    if (mounted) {
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
      // Create event using EventService (dual-write)
      final eventService = EventService();
      final savedEvent = await eventService.createEvent(result);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Add event to provider for immediate UI update
      provider.addEvent(savedEvent);

      // Show success message
      if (mounted) {
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
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
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
    final provider = context.watch<CalendarProvider>();

    return Scaffold(
      backgroundColor: colorScheme.surface.withValues(alpha: 0.95),
      body: Column(
        children: [
          // Gradient header that extends to top of screen
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.secondary,
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: _buildGradientHeader(context, colorScheme, provider),
            ),
          ),

          const SizedBox(height: 6),

          // Horizontal Day Selector
          _buildHorizontalDaySelector(context, colorScheme, provider),

          const SizedBox(height: 6),

          // Category Summary Bubble
          _buildCategorySummaryBubble(context, colorScheme, provider),

          const SizedBox(height: 6),

          // Selected Day Events Card - Takes remaining space
          Expanded(
            child: _buildSelectedDayCard(context, colorScheme, provider),
          ),
        ],
      ),

      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () => _handleCreateEvent(provider),
        backgroundColor: colorScheme.primary,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  /// Build gradient header with month navigation
  Widget _buildGradientHeader(
    BuildContext context,
    ColorScheme colorScheme,
    CalendarProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back to Grid View',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(_selectedDate),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Personal Calendar',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  /// Build category summary bubble
  Widget _buildCategorySummaryBubble(
    BuildContext context,
    ColorScheme colorScheme,
    CalendarProvider provider,
  ) {
    // Calculate month totals by category
    final monthTotals = _calculateMonthTotals(provider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(child: _buildCategoryBadge('Work', monthTotals[EventCategory.work] ?? 0, EventCategory.work)),
          Expanded(child: _buildCategoryBadge('Holiday', monthTotals[EventCategory.holiday] ?? 0, EventCategory.holiday)),
          Expanded(child: _buildCategoryBadge('Friend', monthTotals[EventCategory.friend] ?? 0, EventCategory.friend)),
          Expanded(child: _buildCategoryBadge('Other', monthTotals[EventCategory.other] ?? 0, EventCategory.other)),
        ],
      ),
    );
  }

  /// Build category summary badge
  Widget _buildCategoryBadge(String label, int count, EventCategory category) {
    final categoryColor = CalendarUtils.getCategoryColor(category);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: categoryColor,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.black.withValues(alpha: 0.6),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  /// Build horizontal scrollable day selector
  Widget _buildHorizontalDaySelector(
    BuildContext context,
    ColorScheme colorScheme,
    CalendarProvider provider,
  ) {
    final daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    final today = DateTime.now();
    final isCurrentMonth = _selectedDate.year == today.year && _selectedDate.month == today.month;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: SizedBox(
        height: 80,
        child: ListView.builder(
          controller: _dayScrollController,
          scrollDirection: Axis.horizontal,
          itemCount: daysInMonth,
          itemBuilder: (context, index) {
            final day = index + 1;
            final date = DateTime(_selectedDate.year, _selectedDate.month, day);
            final isSelected = day == _selectedDate.day;
            final isToday = isCurrentMonth && day == today.day;
            final events = provider.getEventsForDay(date);
            final hasEvents = events.isNotEmpty;

            // Get event counts by category
            final eventCounts = <EventCategory, int>{};
            for (final event in events) {
              eventCounts[event.category] = (eventCounts[event.category] ?? 0) + 1;
            }

            return GestureDetector(
              onTap: () => _selectDay(day),
              child: Container(
                width: 56,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primary,
                            colorScheme.secondary,
                          ],
                        )
                      : null,
                  color: isSelected
                      ? null
                      : isToday
                          ? colorScheme.secondary.withValues(alpha: 0.1)
                          : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Day name
                    Text(
                      DateFormat('E').format(date),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.8)
                            : colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Day number
                    Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Event indicators
                    if (hasEvents)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: eventCounts.entries.take(4).map((entry) {
                          return Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : CalendarUtils.getCategoryColor(entry.key),
                              shape: BoxShape.circle,
                            ),
                          );
                        }).toList(),
                      )
                    else
                      const SizedBox(height: 6),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Build selected day card with events
  Widget _buildSelectedDayCard(
    BuildContext context,
    ColorScheme colorScheme,
    CalendarProvider provider,
  ) {
    final events = provider.getEventsForDay(_selectedDate);
    final eventCounts = <EventCategory, int>{};
    for (final event in events) {
      eventCounts[event.category] = (eventCounts[event.category] ?? 0) + 1;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  colorScheme.surface.withValues(alpha: 0.5),
                  colorScheme.surface.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.onSurface.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMM d').format(_selectedDate),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${events.length} event${events.length != 1 ? 's' : ''} scheduled',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                if (events.isNotEmpty)
                  Row(
                    children: eventCounts.entries.map((entry) {
                      return Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: CalendarUtils.getCategoryColor(entry.key),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '${entry.value}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),

          // Events list
          Expanded(
            child: events.isEmpty
                ? _buildEmptyState(colorScheme)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 80), // Extra bottom padding for FAB
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      return _buildEventCard(context, colorScheme, events[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Build empty state when no events
  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 64,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No events this day',
            style: TextStyle(
              fontSize: 18,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add one',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual event card
  Widget _buildEventCard(BuildContext context, ColorScheme colorScheme, EventModel event) {
    final categoryColor = CalendarUtils.getCategoryColor(event.category);
    final timeRange = '${DateFormat('h:mm a').format(event.startTime)} - ${DateFormat('h:mm a').format(event.endTime)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: categoryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EventDetailScreen(event: event),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Category icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: categoryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    CalendarUtils.getCategoryIcon(event.category),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Event details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Time
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: categoryColor,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              timeRange,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      // Location (if available)
                      if (event.location != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: categoryColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.location!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Arrow icon
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Calculate total events by category for current month
  Map<EventCategory, int> _calculateMonthTotals(CalendarProvider provider) {
    final totals = <EventCategory, int>{};
    final daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_selectedDate.year, _selectedDate.month, day);
      final events = provider.getEventsForDay(date);

      for (final event in events) {
        totals[event.category] = (totals[event.category] ?? 0) + 1;
      }
    }

    return totals;
  }
}
