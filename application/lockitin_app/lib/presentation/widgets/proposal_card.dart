import 'package:flutter/material.dart';
import '../../data/models/proposal_model.dart';
import '../../core/theme/app_colors.dart';

/// Card widget for displaying a proposal in a list
///
/// Shows proposal title, status badge, creator, deadline, and vote indicator
class ProposalCard extends StatelessWidget {
  final ProposalModel proposal;
  final VoidCallback onTap;

  const ProposalCard({
    super.key,
    required this.proposal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: appColors.cardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Title + Status Badge
              Row(
                children: [
                  // Title (flexible to wrap if needed)
                  Expanded(
                    child: Text(
                      proposal.title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Status Badge
                  _buildStatusBadge(colorScheme, appColors),
                ],
              ),
              const SizedBox(height: 12),

              // Metadata Row: Creator + Deadline
              Row(
                children: [
                  // Creator
                  Icon(
                    Icons.person_outline_rounded,
                    size: 16,
                    color: appColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    proposal.creatorName ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 14,
                      color: appColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Deadline
                  Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: appColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDeadline(),
                    style: TextStyle(
                      fontSize: 14,
                      color: appColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Vote Indicator
              _buildVoteIndicator(colorScheme, appColors),
            ],
          ),
        ),
      ),
    );
  }

  /// Build status badge with appropriate color
  Widget _buildStatusBadge(ColorScheme colorScheme, AppColorsExtension appColors) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (proposal.status) {
      case ProposalStatus.voting:
        backgroundColor = colorScheme.primary.withValues(alpha: 0.1);
        textColor = colorScheme.primary;
        label = 'Active';
        break;
      case ProposalStatus.confirmed:
        backgroundColor = appColors.successBackground;
        textColor = appColors.success;
        label = 'Confirmed';
        break;
      case ProposalStatus.cancelled:
        backgroundColor = appColors.textMuted.withValues(alpha: 0.1);
        textColor = appColors.textMuted;
        label = 'Cancelled';
        break;
      case ProposalStatus.expired:
        backgroundColor = appColors.textMuted.withValues(alpha: 0.1);
        textColor = appColors.textMuted;
        label = 'Expired';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  /// Format deadline countdown
  String _formatDeadline() {
    if (proposal.status != ProposalStatus.voting || proposal.isExpired) {
      return 'Closed';
    }

    final timeRemaining = proposal.timeRemaining;

    // More than 1 day
    if (timeRemaining.inDays > 0) {
      return 'Ends in ${timeRemaining.inDays}d';
    }

    // More than 1 hour
    if (timeRemaining.inHours > 0) {
      return 'Ends in ${timeRemaining.inHours}h';
    }

    // Less than 1 hour
    return 'Ends in ${timeRemaining.inMinutes}m';
  }

  /// Build vote indicator showing user vote status and total votes
  Widget _buildVoteIndicator(ColorScheme colorScheme, AppColorsExtension appColors) {
    final hasVoted = proposal.userHasVoted ?? false;
    final totalVotes = proposal.totalVoters ?? 0;

    return Row(
      children: [
        // Vote status icon
        Icon(
          hasVoted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 18,
          color: hasVoted ? appColors.success : appColors.textMuted,
        ),
        const SizedBox(width: 6),
        // Vote status text
        Text(
          hasVoted ? 'You voted' : 'Not voted',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: hasVoted ? appColors.success : appColors.textMuted,
          ),
        ),
        const SizedBox(width: 12),
        // Divider
        Container(
          width: 1,
          height: 14,
          color: appColors.divider,
        ),
        const SizedBox(width: 12),
        // Total votes
        Icon(
          Icons.how_to_vote_rounded,
          size: 16,
          color: appColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          '$totalVotes ${totalVotes == 1 ? 'vote' : 'votes'}',
          style: TextStyle(
            fontSize: 14,
            color: appColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
