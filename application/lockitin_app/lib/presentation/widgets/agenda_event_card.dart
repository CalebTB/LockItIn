import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/timezone_utils.dart';
import '../../data/models/event_model.dart';
import '../../data/models/event_template_model.dart';
import '../providers/auth_provider.dart';

/// Compact event card for agenda list view
/// Features colored accent bar, time, title, location, and privacy badge
/// Optimized for 64pt height and smooth scrolling
class AgendaEventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;

  const AgendaEventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final accentColor = _getCategoryColor(event.category, colorScheme);

    // Get user role for surprise party privacy
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id;
    final userRole = _getUserRole(currentUserId);
    final displayTitle = _getDisplayTitle(userRole);
    final isSurpriseParty = event.surprisePartyTemplate != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: appColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: appColors.cardBorder,
            width: 1,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Colored accent bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              // Event content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      // Time column
                      SizedBox(
                        width: 56,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_isAllDayEvent(event))
                              Text(
                                'All day',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              )
                            else ...[
                              Text(
                                _formatTime(event.startTime),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                _formatTime(event.endTime),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: appColors.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Event details
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title with emoji and SECRET badge
                            Row(
                              children: [
                                if (event.emoji != null) ...[
                                  Text(
                                    event.emoji!,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          displayTitle,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: colorScheme.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      // SECRET badge for coordinators
                                      if (isSurpriseParty && userRole == 'coordinator') ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                colorScheme.primary,
                                                colorScheme.secondary,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.lock,
                                                size: 10,
                                                color: colorScheme.onPrimary,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                'SECRET',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.5,
                                                  color: colorScheme.onPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Location
                            if (event.location != null && event.location!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 12,
                                      color: appColors.textMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        event.location!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: appColors.textMuted,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Privacy badge
                      _buildPrivacyBadge(context, appColors, colorScheme),
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

  Widget _buildPrivacyBadge(
    BuildContext context,
    AppColorsExtension appColors,
    ColorScheme colorScheme,
  ) {
    IconData icon;
    Color color;
    String tooltip;

    switch (event.visibility) {
      case EventVisibility.private:
        icon = Icons.lock_outline;
        color = appColors.textMuted;
        tooltip = 'Private';
        break;
      case EventVisibility.busyOnly:
        icon = Icons.visibility_off_outlined;
        color = colorScheme.secondary;
        tooltip = 'Busy only';
        break;
      case EventVisibility.sharedWithName:
        icon = Icons.visibility_outlined;
        color = colorScheme.primary;
        tooltip = 'Shared';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Icon(
        icon,
        size: 18,
        color: color,
      ),
    );
  }

  String _formatTime(DateTime time) {
    return TimezoneUtils.formatLocal(time, 'h:mm a').replaceAll(' ', '\n');
  }

  /// Check if event spans the entire day (midnight to midnight or 23:59)
  bool _isAllDayEvent(EventModel event) {
    final start = event.startTime;
    final end = event.endTime;

    // Check if starts at midnight and ends at midnight next day or 23:59
    final startsAtMidnight = start.hour == 0 && start.minute == 0;
    final endsAtMidnight = end.hour == 0 && end.minute == 0;
    final endsAt2359 = end.hour == 23 && end.minute == 59;

    // Duration is ~24 hours
    final duration = end.difference(start);
    final isFullDay = duration.inHours >= 23;

    return startsAtMidnight && (endsAtMidnight || endsAt2359) && isFullDay;
  }

  Color _getCategoryColor(EventCategory category, ColorScheme colorScheme) {
    switch (category) {
      case EventCategory.work:
        return AppColors.categoryWork;
      case EventCategory.holiday:
        return AppColors.categoryHoliday;
      case EventCategory.friend:
        return AppColors.categoryFriend;
      case EventCategory.other:
        return AppColors.categoryOther;
    }
  }

  /// Get user role in surprise party
  /// Returns: 'target' | 'coordinator' | 'neither'
  String _getUserRole(String? currentUserId) {
    final template = event.surprisePartyTemplate;
    if (template == null || currentUserId == null) {
      return 'neither';
    }

    // Check if user is the target
    if (template.guestOfHonorId == currentUserId) {
      return 'target';
    }

    // Check if user is a coordinator
    if (template.isUserInOnIt(currentUserId)) {
      return 'coordinator';
    }

    return 'neither';
  }

  /// Get the title to display based on user role
  String _getDisplayTitle(String userRole) {
    final template = event.surprisePartyTemplate;
    if (template == null) {
      return event.title;
    }

    // Target sees decoy title if set, otherwise real title
    if (userRole == 'target' && template.decoyTitle != null) {
      return template.decoyTitle!;
    }

    // Coordinators and others see real title
    return event.title;
  }
}
