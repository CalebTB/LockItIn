import 'package:flutter/material.dart';
import '../../../core/utils/member_utils.dart';
import '../../../core/utils/rsvp_status_utils.dart';
import '../../../core/theme/app_colors.dart';

/// Reusable avatar widget with optional status badge
///
/// Consolidates avatar rendering logic from:
/// - surprise_party_dashboard_screen.dart (_buildMemberAvatar)
/// - Other screens with similar avatar patterns
///
/// Features:
/// - Displays user avatar or initials with color-coded background
/// - Optional RSVP status badge overlay
/// - Uses MemberUtils for consistent colors/initials
/// - Uses RSVPStatusUtils for status icon/color
class StatusAvatar extends StatelessWidget {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String? statusBadge; // RSVP status: 'accepted', 'maybe', 'declined', 'pending'
  final double radius;

  const StatusAvatar({
    super.key,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.statusBadge,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: MemberUtils.getColorById(userId),
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
          child: avatarUrl == null
              ? Text(
                  MemberUtils.getInitials(displayName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
        ),

        // Status badge overlay (if provided)
        if (statusBadge != null)
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              width: radius * 0.75,
              height: radius * 0.75,
              decoration: BoxDecoration(
                color: RSVPStatusUtils.getColor(statusBadge!, colorScheme, appColors),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                RSVPStatusUtils.getSmallIcon(statusBadge!),
                size: radius * 0.4,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}
