import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/event_model.dart';
import '../../utils/privacy_colors.dart';
import '../providers/settings_provider.dart';
import '../screens/event_detail_screen.dart';

/// Apple Calendar-style timeline view for a single day
/// Shows events positioned at their actual times with overlap handling
class DayTimelineView extends StatefulWidget {
  final DateTime selectedDate;
  final List<EventModel> events;

  const DayTimelineView({
    super.key,
    required this.selectedDate,
    required this.events,
  });

  @override
  State<DayTimelineView> createState() => _DayTimelineViewState();
}

class _DayTimelineViewState extends State<DayTimelineView> {
  final ScrollController _scrollController = ScrollController();

  // Constants for layout calculations
  static const double _hourHeight = 60.0; // 60 pixels per hour = 1 pixel per minute
  static const double _timeColumnWidth = 60.0; // Width of time labels (e.g., "9 AM")
  static const double _allDayEventHeight = 40.0; // Height per all-day event
  static const double _currentTimeIndicatorHeight = 2.0;
  static const double _eventMinHeight = 20.0; // Minimum event height for very short events

  @override
  void initState() {
    super.initState();
    // Auto-scroll after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToRelevantTime();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Auto-scroll to current time (if today) or first event
  void _scrollToRelevantTime() {
    if (!_scrollController.hasClients) return;

    final now = DateTime.now();
    final isToday = widget.selectedDate.year == now.year &&
        widget.selectedDate.month == now.month &&
        widget.selectedDate.day == now.day;

    double scrollOffset;

    if (isToday) {
      // Scroll to current time minus 2 hours for context
      final currentMinutes = now.hour * 60 + now.minute;
      final targetMinutes = (currentMinutes - 120).clamp(0, 24 * 60 - 1);
      scrollOffset = targetMinutes.toDouble();
    } else {
      // Scroll to first timed event (not all-day) minus 1 hour
      final timedEvents = widget.events.where((e) => !_isAllDayEvent(e)).toList();
      if (timedEvents.isNotEmpty) {
        final firstEvent = timedEvents.first;
        final eventMinutes = firstEvent.startTime.hour * 60 + firstEvent.startTime.minute;
        final targetMinutes = (eventMinutes - 60).clamp(0, 24 * 60 - 1);
        scrollOffset = targetMinutes.toDouble();
      } else {
        // Default to 8 AM if no events
        scrollOffset = 8 * 60.0;
      }
    }

    _scrollController.animateTo(
      scrollOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final allDayEvents = widget.events.where(_isAllDayEvent).toList();
    final timedEvents = widget.events.where((e) => !_isAllDayEvent(e)).toList();

    return Column(
      children: [
        // All-day events section (if any)
        if (allDayEvents.isNotEmpty)
          _buildAllDayEventsSection(context, colorScheme, allDayEvents),

        // Timeline section
        Expanded(
          child: _buildTimeline(context, colorScheme, timedEvents),
        ),
      ],
    );
  }

  /// Build all-day events section at the top
  Widget _buildAllDayEventsSection(
    BuildContext context,
    ColorScheme colorScheme,
    List<EventModel> allDayEvents,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // "All Day" label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              'All Day',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                letterSpacing: 0.5,
              ),
            ),
          ),
          // All-day event cards
          ...allDayEvents.map((event) => _buildAllDayEventCard(context, colorScheme, event)),
        ],
      ),
    );
  }

  /// Build a single all-day event card
  Widget _buildAllDayEventCard(
    BuildContext context,
    ColorScheme colorScheme,
    EventModel event,
  ) {
    final privacyColor = _getPrivacyColor(context, event.visibility);

    return Container(
      height: _allDayEventHeight,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: privacyColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _navigateToEventDetail(context, event),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Privacy indicator dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: privacyColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                // Event title
                Expanded(
                  child: Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build the main scrollable timeline
  Widget _buildTimeline(
    BuildContext context,
    ColorScheme colorScheme,
    List<EventModel> timedEvents,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final eventColumnWidth = constraints.maxWidth - _timeColumnWidth;

        // Calculate overlapping event groups
        final eventGroups = _calculateEventLayout(timedEvents);

        return SingleChildScrollView(
          controller: _scrollController,
          child: SizedBox(
            height: 24 * _hourHeight, // Total height for 24 hours
            child: Stack(
              children: [
                // Hour grid (time labels and horizontal lines)
                Column(
                  children: List.generate(24, (hour) {
                    return _buildHourRow(
                      context,
                      colorScheme,
                      hour,
                    );
                  }),
                ),

                // Events layer (positioned absolutely over the grid)
                ..._buildAllEvents(
                  context,
                  colorScheme,
                  eventColumnWidth,
                  eventGroups,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build a single hour row in the timeline (grid background only, no events)
  Widget _buildHourRow(
    BuildContext context,
    ColorScheme colorScheme,
    int hour,
  ) {
    return SizedBox(
      height: _hourHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time label (e.g., "9 AM")
          // Aligned exactly with the horizontal separator line
          SizedBox(
            width: _timeColumnWidth,
            child: Transform.translate(
              offset: const Offset(0, -6), // Shift up by half the text height to align with line
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  _formatHour(hour),
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    height: 1.0, // Tight line height for precise alignment
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ),
          // Event area with horizontal line
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: colorScheme.onSurface.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build all events positioned absolutely in the 24-hour timeline
  List<Widget> _buildAllEvents(
    BuildContext context,
    ColorScheme colorScheme,
    double eventColumnWidth,
    List<_EventGroup> eventGroups,
  ) {
    final widgets = <Widget>[];

    // Add current time indicator if today
    final now = DateTime.now();
    final isToday = widget.selectedDate.year == now.year &&
        widget.selectedDate.month == now.month &&
        widget.selectedDate.day == now.day;

    if (isToday) {
      // Calculate position from midnight
      final totalMinutes = now.hour * 60 + now.minute;
      final topOffset = totalMinutes.toDouble();

      widgets.add(
        Positioned(
          left: _timeColumnWidth,
          right: 0,
          top: topOffset,
          child: Row(
            children: [
              // Red dot
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              // Red line
              Expanded(
                child: Container(
                  height: _currentTimeIndicatorHeight,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Render all events
    for (final group in eventGroups) {
      for (final eventLayout in group.events) {
        final event = eventLayout.event;

        // Calculate vertical position from midnight (0:00)
        final startMinutes = event.startTime.hour * 60 + event.startTime.minute;
        final topOffset = startMinutes.toDouble();

        // Calculate total height for the event
        final totalDurationMinutes = event.endTime.difference(event.startTime).inMinutes;
        final totalHeight = totalDurationMinutes.toDouble().clamp(_eventMinHeight, double.infinity);

        // Calculate horizontal position and width based on overlap
        final columnWidth = eventColumnWidth / group.columnCount;
        final leftOffset = _timeColumnWidth + (eventLayout.column * columnWidth);

        widgets.add(
          Positioned(
            left: leftOffset,
            top: topOffset,
            width: columnWidth - 4, // 4px gap between columns
            height: totalHeight,
            child: _buildEventCard(context, colorScheme, event),
          ),
        );
      }
    }

    return widgets;
  }

  /// Build an individual event card in the timeline
  Widget _buildEventCard(
    BuildContext context,
    ColorScheme colorScheme,
    EventModel event,
  ) {
    final privacyColor = _getPrivacyColor(context, event.visibility);
    final durationMinutes = event.endTime.difference(event.startTime).inMinutes;

    // Categorize event by duration for adaptive layout
    final isVeryShortEvent = durationMinutes < 45; // Less than 45 minutes
    final isShortEvent = durationMinutes < 60; // Less than 60 minutes

    // Format time range
    final startTime = _formatTimeShort(event.startTime);
    final endTime = _formatTimeShort(event.endTime);
    final timeRange = '$startTime-$endTime';

    // Adaptive padding based on duration
    // Very short events (< 45 min): Minimal padding to fit content
    // Short events (45-60 min): Standard compact padding
    // Long events (>= 60 min): Comfortable padding
    final verticalPadding = isVeryShortEvent ? 2.0 : (isShortEvent ? 3.0 : 4.0);
    final horizontalPadding = isVeryShortEvent ? 4.0 : 6.0;
    final contentSpacing = isVeryShortEvent ? 1.0 : 2.0;

    // Adaptive font sizes for very short events
    final timeFontSize = isVeryShortEvent ? 9.0 : 10.0;
    final titleFontSize = isVeryShortEvent ? 10.0 : (isShortEvent ? 11.0 : 13.0);

    return Material(
      color: privacyColor.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _navigateToEventDetail(context, event),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: privacyColor,
                width: 3,
              ),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Time range - always show at top
              Text(
                timeRange,
                style: TextStyle(
                  fontSize: timeFontSize,
                  fontWeight: FontWeight.w600,
                  color: privacyColor,
                  height: 1.2, // Tight line height to save space
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: contentSpacing),

              // For short events (< 60 min): Show title and location compactly
              if (isShortEvent) ...[
                Text(
                  event.location != null ? '${event.title} • ${event.location}' : event.title,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    height: 1.2, // Tight line height to save space
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ]
              // For longer events (>= 60 min): Show title and location on separate lines
              else ...[
                // Title
                Text(
                  event.title,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Location (if available)
                if (event.location != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 10,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          event.location!,
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // OVERLAP DETECTION & LAYOUT ALGORITHM
  // ═══════════════════════════════════════════════════════════════════════

  /// Calculate event layout with overlap detection
  /// Groups overlapping events and assigns them to columns
  List<_EventGroup> _calculateEventLayout(List<EventModel> events) {
    if (events.isEmpty) return [];

    // Sort events by start time
    final sortedEvents = List<EventModel>.from(events)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final groups = <_EventGroup>[];
    final processed = <String>{};

    for (final event in sortedEvents) {
      if (processed.contains(event.id)) continue;

      // Find all events that overlap with this one
      final overlapping = <EventModel>[event];
      processed.add(event.id);

      for (final other in sortedEvents) {
        if (processed.contains(other.id)) continue;
        if (_eventsOverlap(event, other)) {
          overlapping.add(other);
          processed.add(other.id);
        }
      }

      // Assign columns to overlapping events
      final eventLayouts = _assignColumns(overlapping);
      groups.add(_EventGroup(
        events: eventLayouts,
        columnCount: eventLayouts.map((e) => e.column + 1).reduce((a, b) => a > b ? a : b),
      ));
    }

    return groups;
  }

  /// Check if two events overlap in time
  bool _eventsOverlap(EventModel a, EventModel b) {
    return a.startTime.isBefore(b.endTime) && a.endTime.isAfter(b.startTime);
  }

  /// Assign column indices to overlapping events
  /// Uses a greedy algorithm to minimize column count
  List<_EventLayout> _assignColumns(List<EventModel> events) {
    final layouts = <_EventLayout>[];
    final columns = <List<EventModel>>[];

    for (final event in events) {
      // Find the first column where this event fits
      int columnIndex = 0;
      bool placed = false;

      for (int i = 0; i < columns.length; i++) {
        final column = columns[i];
        bool fits = true;

        // Check if event overlaps with any event in this column
        for (final existing in column) {
          if (_eventsOverlap(event, existing)) {
            fits = false;
            break;
          }
        }

        if (fits) {
          column.add(event);
          columnIndex = i;
          placed = true;
          break;
        }
      }

      // If no column found, create a new one
      if (!placed) {
        columns.add([event]);
        columnIndex = columns.length - 1;
      }

      layouts.add(_EventLayout(event: event, column: columnIndex));
    }

    return layouts;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════

  /// Check if event is all-day (spans exactly 24 hours or midnight to midnight)
  bool _isAllDayEvent(EventModel event) {
    final duration = event.endTime.difference(event.startTime);
    final isExactly24Hours = duration.inHours == 24 || duration.inDays >= 1;
    final startsMidnight = event.startTime.hour == 0 && event.startTime.minute == 0;
    final endsMidnight = event.endTime.hour == 0 && event.endTime.minute == 0;

    return isExactly24Hours || (startsMidnight && endsMidnight);
  }

  /// Format hour as "12 AM", "1 PM", etc.
  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  /// Format time in compact format for event cards (e.g., "12:30PM", "9AM")
  String _formatTimeShort(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;

    // Format hour
    String hourStr;
    String period;
    if (hour == 0) {
      hourStr = '12';
      period = 'AM';
    } else if (hour < 12) {
      hourStr = '$hour';
      period = 'AM';
    } else if (hour == 12) {
      hourStr = '12';
      period = 'PM';
    } else {
      hourStr = '${hour - 12}';
      period = 'PM';
    }

    // Only show minutes if not on the hour
    if (minute == 0) {
      return '$hourStr$period';
    } else {
      return '$hourStr:${minute.toString().padLeft(2, '0')}$period';
    }
  }

  /// Get privacy color based on visibility setting
  Color _getPrivacyColor(BuildContext context, EventVisibility visibility) {
    final useColorBlindPalette = context.watch<SettingsProvider>().useColorBlindPalette;
    return PrivacyColors.getPrivacyColor(visibility, useColorBlindPalette: useColorBlindPalette);
  }

  /// Navigate to event detail screen
  void _navigateToEventDetail(BuildContext context, EventModel event) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            EventDetailScreen(event: event),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var slideTween = Tween(begin: begin, end: end)
              .chain(CurveTween(curve: curve));
          var fadeTween = Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(slideTween),
            child: FadeTransition(
              opacity: animation.drive(fadeTween),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════

/// Represents a group of overlapping events
class _EventGroup {
  final List<_EventLayout> events;
  final int columnCount;

  _EventGroup({
    required this.events,
    required this.columnCount,
  });
}

/// Represents an event's layout position (which column it occupies)
class _EventLayout {
  final EventModel event;
  final int column;

  _EventLayout({
    required this.event,
    required this.column,
  });
}
