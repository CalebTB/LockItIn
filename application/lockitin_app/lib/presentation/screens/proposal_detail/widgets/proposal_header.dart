import 'package:flutter/material.dart';
import '../../../../data/models/proposal_model.dart';
import '../../../../core/theme/app_colors.dart';

/// Header widget for proposal detail screen
///
/// Displays status badge, title, creator info, and deadline countdown
class ProposalHeader extends StatelessWidget {
  final ProposalModel proposal;

  const ProposalHeader({
    super.key,
    required this.proposal,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          _buildStatusBadge(context),

          const SizedBox(height: 12),

          // Title
          Text(
            proposal.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 16),

          // Creator info
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                child: Text(
                  proposal.creatorName?.substring(0, 1).toUpperCase() ?? 'U',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proposal.creatorName ?? 'Unknown',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    Text(
                      'Organizer',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: appColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Deadline / Time remaining
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _getDeadlineColor(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: _getDeadlineColor(context),
                ),
                const SizedBox(width: 6),
                Text(
                  _getDeadlineText(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getDeadlineColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build status badge with appropriate color
  Widget _buildStatusBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    Color badgeColor;
    String statusText;
    IconData icon;

    if (proposal.isExpired) {
      badgeColor = appColors.textMuted;
      statusText = 'Expired';
      icon = Icons.event_busy;
    } else if (!proposal.isVotingOpen) {
      badgeColor = appColors.success;
      statusText = 'Closed';
      icon = Icons.check_circle;
    } else {
      badgeColor = colorScheme.primary;
      statusText = 'Active';
      icon = Icons.how_to_vote;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  /// Get color based on deadline urgency
  Color _getDeadlineColor(BuildContext context) {
    if (proposal.isExpired) {
      return context.appColors.textMuted;
    }

    final hoursLeft = proposal.votingDeadline.difference(DateTime.now()).inHours;

    // CRITICAL: Less than 1 hour remaining
    if (hoursLeft < 1) {
      return Theme.of(context).colorScheme.error;  // Red
    }
    // WARNING: Less than 24 hours remaining
    else if (hoursLeft < 24) {
      return context.appColors.warning;  // Orange
    }
    // NORMAL: More than 24 hours remaining
    return Theme.of(context).colorScheme.primary;  // Primary color
  }

  /// Format deadline text
  String _getDeadlineText() {
    if (proposal.isExpired) {
      return 'Voting ended ${_formatRelativeTime(proposal.votingDeadline)}';
    }

    final timeRemaining = proposal.timeRemaining;
    final days = timeRemaining.inDays;
    final hours = timeRemaining.inHours;
    final minutes = timeRemaining.inMinutes;

    if (days > 0) {
      return 'Voting closes in ${days}d';
    } else if (hours > 0) {
      return 'Voting closes in ${hours}h';
    } else {
      return 'Voting closes in ${minutes}m';
    }
  }

  /// Format relative time for past dates
  String _formatRelativeTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }
}
