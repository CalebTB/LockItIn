import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/event_model.dart';

/// Card displaying an upcoming event with gradient background
/// Features emoji, title, time, location, and attendee avatars
class UpcomingEventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;
  final List<String>? attendeeInitials;
  final int? additionalAttendees;
  final String? statusBadge;
  final Color? statusBadgeColor;

  const UpcomingEventCard({
    super.key,
    required this.event,
    this.onTap,
    this.attendeeInitials,
    this.additionalAttendees,
    this.statusBadge,
    this.statusBadgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getEventColors(event.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              colors.backgroundColor,
              colors.backgroundColor.withValues(alpha: 0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colors.borderColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji
            Text(
              _getCategoryEmoji(event.category),
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: 12),

            // Event details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937), // gray-900
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Time and location row
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatEventTime(event),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),

                  // Location if available
                  if (event.location != null && event.location!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Attendees or status badge row
                  Row(
                    children: [
                      if (attendeeInitials != null && attendeeInitials!.isNotEmpty) ...[
                        _buildAttendeeAvatars(),
                        if (additionalAttendees != null && additionalAttendees! > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '+$additionalAttendees going',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                      if (statusBadge != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusBadgeColor ?? const Color(0xFFFEF3C7), // yellow-100
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusBadge!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: statusBadgeColor != null
                                  ? Colors.white
                                  : const Color(0xFFB45309), // yellow-700
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendeeAvatars() {
    final avatarCount = attendeeInitials!.take(3).length;
    // Calculate width: first avatar is 24px, each subsequent adds 16px (overlap)
    final width = 24.0 + ((avatarCount - 1) * 16.0);

    return SizedBox(
      width: width,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: attendeeInitials!.take(3).toList().asMap().entries.map((entry) {
          return Positioned(
            left: entry.key * 16.0,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF60A5FA), Color(0xFF8B5CF6)], // blue-400 to purple-500
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  entry.value,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatEventTime(EventModel event) {
    final dateFormat = DateFormat('MMM d');
    final timeFormat = DateFormat('h:mm a');
    return '${dateFormat.format(event.startTime)} · ${timeFormat.format(event.startTime)}';
  }

  String _getCategoryEmoji(EventCategory category) {
    switch (category) {
      case EventCategory.work:
        return '💼';
      case EventCategory.holiday:
        return '🎉';
      case EventCategory.friend:
        return '👥';
      case EventCategory.other:
        return '📅';
    }
  }

  _EventColors _getEventColors(EventCategory category) {
    switch (category) {
      case EventCategory.work:
        return _EventColors(
          backgroundColor: const Color(0xFFEFF6FF), // blue-50
          borderColor: const Color(0xFF93C5FD), // blue-300
        );
      case EventCategory.holiday:
        return _EventColors(
          backgroundColor: const Color(0xFFFFF7ED), // orange-50
          borderColor: const Color(0xFFFDBA74), // orange-300
        );
      case EventCategory.friend:
        return _EventColors(
          backgroundColor: const Color(0xFFF5F3FF), // purple-50
          borderColor: const Color(0xFFC4B5FD), // purple-300
        );
      case EventCategory.other:
        return _EventColors(
          backgroundColor: const Color(0xFFF0FDF4), // green-50
          borderColor: const Color(0xFF86EFAC), // green-300
        );
    }
  }
}

class _EventColors {
  final Color backgroundColor;
  final Color borderColor;

  const _EventColors({
    required this.backgroundColor,
    required this.borderColor,
  });
}
