import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/event_model.dart';

/// Card displaying an upcoming event with gradient background
/// Features emoji, title, time, location, and attendee avatars
class UpcomingEventCard extends StatelessWidget {
  // Sunset Coral Dark Theme Colors
  static const Color _rose500 = Color(0xFFF43F5E);
  static const Color _rose400 = Color(0xFFFB7185);
  static const Color _rose300 = Color(0xFFFDA4AF);
  static const Color _rose200 = Color(0xFFFECDD3);
  static const Color _rose50 = Color(0xFFFFF1F2);
  static const Color _rose950 = Color(0xFF4C0519);
  static const Color _orange400 = Color(0xFFFB923C);
  static const Color _orange500 = Color(0xFFF97316);
  static const Color _orange600 = Color(0xFFEA580C);
  static const Color _orange950 = Color(0xFF1A0F0A);
  static const Color _amber500 = Color(0xFFF59E0B);
  static const Color _amber300 = Color(0xFFFCD34D);
  static const Color _purple500 = Color(0xFFA855F7);
  static const Color _purple600 = Color(0xFF9333EA);
  static const Color _purple950 = Color(0xFF1A0A1F);
  static const Color _violet500 = Color(0xFF8B5CF6);
  static const Color _pink500 = Color(0xFFEC4899);
  static const Color _pink600 = Color(0xFFDB2777);
  static const Color _teal500 = Color(0xFF14B8A6);
  static const Color _teal600 = Color(0xFF0D9488);
  static const Color _cyan950 = Color(0xFF0A1A1F);

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
    final categoryColors = _getCategoryColors(event.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: categoryColors.cardGradient,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: categoryColors.borderColor,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Container with Emoji
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: categoryColors.iconGradient,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: categoryColors.shadowColor,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  event.emoji ?? _getCategoryEmoji(event.category),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
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
                      color: _rose50,
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
                        color: _rose200.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatEventTime(event),
                        style: TextStyle(
                          fontSize: 13,
                          color: _rose200.withValues(alpha: 0.6),
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
                          color: _rose200.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location!,
                            style: TextStyle(
                              fontSize: 13,
                              color: _rose200.withValues(alpha: 0.6),
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
                              color: _rose300.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ],
                      if (statusBadge != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusBadgeColor ?? _amber500.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(
                              color: _amber500.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            statusBadge!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: statusBadgeColor != null
                                  ? Colors.white
                                  : _amber300,
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
                  colors: [_rose400, _orange400],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: _rose950, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _rose500.withValues(alpha: 0.2),
                    blurRadius: 4,
                  ),
                ],
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
        return '💻';
      case EventCategory.holiday:
        return '🦃';
      case EventCategory.friend:
        return '🎮';
      case EventCategory.other:
        return '🎯';
    }
  }

  _CategoryColors _getCategoryColors(EventCategory category) {
    switch (category) {
      case EventCategory.work:
        // Teal/Cyan theme for work
        return _CategoryColors(
          cardGradient: [_cyan950, const Color(0xFF1A0F14)],
          iconGradient: [_teal500, _teal600],
          borderColor: _teal500.withValues(alpha: 0.2),
          shadowColor: _teal500.withValues(alpha: 0.3),
        );
      case EventCategory.holiday:
        // Amber/Orange theme for holidays (like Friendsgiving in mockup)
        return _CategoryColors(
          cardGradient: [_rose950, _orange950],
          iconGradient: [_amber500, _orange600],
          borderColor: _rose500.withValues(alpha: 0.2),
          shadowColor: _orange500.withValues(alpha: 0.3),
        );
      case EventCategory.friend:
        // Violet/Purple theme for friends (like Game Night in mockup)
        return _CategoryColors(
          cardGradient: [_purple950, _rose950],
          iconGradient: [_violet500, _purple600],
          borderColor: _purple500.withValues(alpha: 0.2),
          shadowColor: _purple500.withValues(alpha: 0.3),
        );
      case EventCategory.other:
        // Rose/Pink theme for other events
        return _CategoryColors(
          cardGradient: [_rose950, _purple950],
          iconGradient: [_rose400, _pink600],
          borderColor: _pink500.withValues(alpha: 0.2),
          shadowColor: _pink500.withValues(alpha: 0.3),
        );
    }
  }
}

class _CategoryColors {
  final List<Color> cardGradient;
  final List<Color> iconGradient;
  final Color borderColor;
  final Color shadowColor;

  const _CategoryColors({
    required this.cardGradient,
    required this.iconGradient,
    required this.borderColor,
    required this.shadowColor,
  });
}
