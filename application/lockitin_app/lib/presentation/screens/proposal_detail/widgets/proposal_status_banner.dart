import 'package:flutter/material.dart';
import '../../../../data/models/proposal_model.dart';
import '../../../../core/theme/app_colors.dart';

/// Banner showing proposal status when voting is closed
///
/// Displays different messages and styles for confirmed, cancelled, or expired proposals.
class ProposalStatusBanner extends StatelessWidget {
  final ProposalModel proposal;

  const ProposalStatusBanner({
    super.key,
    required this.proposal,
  });

  @override
  Widget build(BuildContext context) {
    // Only show when voting is closed
    if (proposal.isVotingOpen) {
      return const SizedBox.shrink();
    }

    final appColors = context.appColors;

    // Determine banner content based on status
    final bannerData = _getBannerData(context, appColors);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerData.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: bannerData.borderColor,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            bannerData.icon,
            color: bannerData.iconColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bannerData.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: bannerData.textColor,
                      ),
                ),
                if (bannerData.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    bannerData.subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: bannerData.textColor.withValues(alpha: 0.8),
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  _BannerData _getBannerData(BuildContext context, AppColorsExtension appColors) {
    switch (proposal.status) {
      case ProposalStatus.confirmed:
        return _BannerData(
          icon: Icons.check_circle,
          iconColor: appColors.success,
          backgroundColor: appColors.success.withValues(alpha: 0.1),
          borderColor: appColors.success.withValues(alpha: 0.3),
          textColor: appColors.success,
          title: 'Event Created',
          subtitle: 'This proposal has been confirmed and added to calendars',
        );

      case ProposalStatus.cancelled:
        return _BannerData(
          icon: Icons.cancel,
          iconColor: appColors.textMuted,
          backgroundColor: appColors.textMuted.withValues(alpha: 0.1),
          borderColor: appColors.textMuted.withValues(alpha: 0.3),
          textColor: appColors.textSecondary,
          title: 'Proposal Cancelled',
          subtitle: 'The organizer cancelled this proposal',
        );

      case ProposalStatus.expired:
        return _BannerData(
          icon: Icons.event_busy,
          iconColor: appColors.warning,
          backgroundColor: appColors.warning.withValues(alpha: 0.1),
          borderColor: appColors.warning.withValues(alpha: 0.3),
          textColor: appColors.warning,
          title: 'Voting Closed',
          subtitle: 'The deadline has passed',
        );

      case ProposalStatus.voting:
        // Should not reach here as we check isVotingOpen above
        return _BannerData(
          icon: Icons.info_outline,
          iconColor: appColors.textMuted,
          backgroundColor: appColors.textMuted.withValues(alpha: 0.1),
          borderColor: appColors.textMuted.withValues(alpha: 0.3),
          textColor: appColors.textSecondary,
          title: 'Voting Closed',
          subtitle: null,
        );
    }
  }
}

class _BannerData {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final String title;
  final String? subtitle;

  _BannerData({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.title,
    this.subtitle,
  });
}
