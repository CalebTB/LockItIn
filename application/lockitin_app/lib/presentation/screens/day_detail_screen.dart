import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/event_model.dart';

/// Day detail screen showing all events for a selected date
class DayDetailScreen extends StatelessWidget {
  final DateTime selectedDate;
  final List<EventModel> events;

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
        onTap: () {
          // TODO: Navigate to event detail screen when implemented
        },
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
}
