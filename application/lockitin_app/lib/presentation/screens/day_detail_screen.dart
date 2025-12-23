import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/event_model.dart';
import 'event_detail_screen.dart';

/// Day detail screen showing all events for a selected date
class DayDetailScreen extends StatelessWidget {
  final DateTime selectedDate;
  final List<EventModel> events;

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVACY INDICATOR DESIGN OPTIONS
  // ═══════════════════════════════════════════════════════════════════════
  // Set this to true for OPTION A (pill badge on right side)
  // Set this to false for OPTION B (colored left border)
  static const bool _useOptionA = true;
  // ═══════════════════════════════════════════════════════════════════════

  const DayDetailScreen({
    super.key,
    required this.selectedDate,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE').format(selectedDate),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              DateFormat('MMMM d, yyyy').format(selectedDate),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
      body: events.isEmpty
          ? _buildEmptyState(context, colorScheme)
          : _buildEventList(context, colorScheme, events),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 80,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No events',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have no events scheduled for this day',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList(BuildContext context, ColorScheme colorScheme, List<EventModel> events) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildEventCard(context, colorScheme, event);
      },
    );
  }

  Widget _buildEventCard(BuildContext context, ColorScheme colorScheme, EventModel event) {
    final isAllDay = _isAllDayEvent(event);
    final timeText = isAllDay
        ? 'All day'
        : '${_formatTime(event.startTime)} - ${_formatTime(event.endTime)}';

    // Determine which privacy indicator design to use
    if (_useOptionA) {
      // ═══════════════════════════════════════════════════════════════════
      // OPTION A: Pill Badge Implementation
      // ═══════════════════════════════════════════════════════════════════
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToEventDetail(context, event),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row with privacy badge on the right
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event title (takes remaining space)
                    Expanded(
                      child: Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Privacy pill badge
                    _buildPrivacyPillBadge(event.visibility),
                  ],
                ),

                const SizedBox(height: 8),

                // Time
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeText,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),

                // Location (if available)
                if (event.location != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.location!,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                // Description (if available)
                if (event.description != null && event.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    event.description!,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    } else {
      // ═══════════════════════════════════════════════════════════════════
      // OPTION B: Colored Left Border Implementation
      // ═══════════════════════════════════════════════════════════════════
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToEventDetail(context, event),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Colored left border indicator
                _buildPrivacyBorderDecoration(event.visibility),
                // Event content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event title
                      Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Time
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            timeText,
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),

                      // Location (if available)
                      if (event.location != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                event.location!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Description (if available)
                      if (event.description != null && event.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          event.description!,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  /// Navigate to event detail screen with custom animation
  void _navigateToEventDetail(BuildContext context, EventModel event) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            EventDetailScreen(event: event),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide from right with fade
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

  /// Check if event is all-day (spans exactly 24 hours or midnight to midnight)
  bool _isAllDayEvent(EventModel event) {
    final duration = event.endTime.difference(event.startTime);
    final isExactly24Hours = duration.inHours == 24 || duration.inDays >= 1;
    final startsMidnight = event.startTime.hour == 0 && event.startTime.minute == 0;
    final endsMidnight = event.endTime.hour == 0 && event.endTime.minute == 0;

    return isExactly24Hours || (startsMidnight && endsMidnight);
  }

  /// Format time to "h:mm a" format (e.g., "9:00 AM")
  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVACY INDICATOR HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get privacy color based on visibility setting
  /// Private = Red (#EF4444), Shared = Green (#10B981), Busy Only = Orange (#F59E0B)
  Color _getPrivacyColor(EventVisibility visibility) {
    switch (visibility) {
      case EventVisibility.private:
        return const Color(0xFFEF4444); // Red
      case EventVisibility.sharedWithName:
        return const Color(0xFF10B981); // Green
      case EventVisibility.busyOnly:
        return const Color(0xFFF59E0B); // Orange
    }
  }

  /// Get privacy label text
  String _getPrivacyLabel(EventVisibility visibility) {
    switch (visibility) {
      case EventVisibility.private:
        return 'Private';
      case EventVisibility.sharedWithName:
        return 'Shared';
      case EventVisibility.busyOnly:
        return 'Busy';
    }
  }

  /// Get privacy icon
  IconData _getPrivacyIcon(EventVisibility visibility) {
    switch (visibility) {
      case EventVisibility.private:
        return Icons.lock;
      case EventVisibility.sharedWithName:
        return Icons.people;
      case EventVisibility.busyOnly:
        return Icons.remove_red_eye_outlined;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // OPTION A: Pill Badge on Right Side
  // ═══════════════════════════════════════════════════════════════════════
  // Visual: A rounded pill-shaped badge with icon + text aligned to the right
  // Example: [🔒 Private] in red with light red background
  // Pro: Clear and explicit, easy to read, familiar pattern
  // Con: Takes more horizontal space
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildPrivacyPillBadge(EventVisibility visibility) {
    final privacyColor = _getPrivacyColor(visibility);
    final label = _getPrivacyLabel(visibility);
    final icon = _getPrivacyIcon(visibility);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: privacyColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: privacyColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: privacyColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: privacyColor,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // OPTION B: Colored Left Border
  // ═══════════════════════════════════════════════════════════════════════
  // Visual: A thick colored vertical bar on the left edge of the card
  // Example: A 4px red bar for Private events
  // Pro: Subtle, scannable at a glance, doesn't take content space
  // Con: Less explicit, requires learning what colors mean
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildPrivacyBorderDecoration(EventVisibility visibility) {
    final privacyColor = _getPrivacyColor(visibility);

    return Container(
      width: 4,
      decoration: BoxDecoration(
        color: privacyColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
      ),
    );
  }
}
