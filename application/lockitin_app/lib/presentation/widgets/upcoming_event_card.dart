import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/event_model.dart';
import '../../utils/privacy_colors.dart';

/// Card displaying an upcoming event with category-based styling
/// Features emoji, title, time, location, and attendee avatars
/// Uses theme-based colors from the Minimal theme design system
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
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final categoryColors = _getCategoryColors(event.category, colorScheme);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: appColors.cardBackground,
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
                color: categoryColors.iconBackground,
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
                  // Title with privacy badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Compact privacy badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: PrivacyColors.getPrivacyBackgroundColor(event.visibility),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PrivacyColors.getPrivacyIcon(event.visibility),
                              size: 12,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Time and location row
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: appColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatEventTime(event),
                        style: TextStyle(
                          fontSize: 13,
                          color: appColors.textMuted,
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
                          color: appColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location!,
                            style: TextStyle(
                              fontSize: 13,
                              color: appColors.textMuted,
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
                        _buildAttendeeAvatars(colorScheme),
                        if (additionalAttendees != null && additionalAttendees! > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '+$additionalAttendees going',
                            style: TextStyle(
                              fontSize: 12,
                              color: appColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                      if (statusBadge != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusBadgeColor?.withValues(alpha: 0.2) ??
                                appColors.warningBackground,
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(
                              color: statusBadgeColor?.withValues(alpha: 0.3) ??
                                  appColors.warning.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            statusBadge!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: statusBadgeColor ?? appColors.warning,
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

  Widget _buildAttendeeAvatars(ColorScheme colorScheme) {
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
                color: colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.surface,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimary,
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

  _CategoryColors _getCategoryColors(EventCategory category, ColorScheme colorScheme) {
    // Use semantic colors based on category
    switch (category) {
      case EventCategory.work:
        return _CategoryColors(
          iconBackground: AppColors.memberTeal.withValues(alpha: 0.15),
          borderColor: AppColors.memberTeal.withValues(alpha: 0.2),
          shadowColor: AppColors.memberTeal.withValues(alpha: 0.2),
        );
      case EventCategory.holiday:
        return _CategoryColors(
          iconBackground: colorScheme.secondary.withValues(alpha: 0.15),
          borderColor: colorScheme.secondary.withValues(alpha: 0.2),
          shadowColor: colorScheme.secondary.withValues(alpha: 0.2),
        );
      case EventCategory.friend:
        return _CategoryColors(
          iconBackground: AppColors.memberViolet.withValues(alpha: 0.15),
          borderColor: AppColors.memberViolet.withValues(alpha: 0.2),
          shadowColor: AppColors.memberViolet.withValues(alpha: 0.2),
        );
      case EventCategory.other:
        return _CategoryColors(
          iconBackground: colorScheme.primary.withValues(alpha: 0.15),
          borderColor: colorScheme.primary.withValues(alpha: 0.2),
          shadowColor: colorScheme.primary.withValues(alpha: 0.2),
        );
    }
  }
}

class _CategoryColors {
  final Color iconBackground;
  final Color borderColor;
  final Color shadowColor;

  const _CategoryColors({
    required this.iconBackground,
    required this.borderColor,
    required this.shadowColor,
  });
}
