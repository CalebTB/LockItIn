import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/proposal_model.dart';
import '../../../../data/models/proposal_time_option.dart';
import '../../../../data/models/vote_model.dart';
import '../../../../core/theme/app_colors.dart';

/// Card displaying a single time option with voting interface
///
/// Shows date/time, vote counts, progress bar, and voting buttons.
/// Tappable to view detailed vote breakdown.
class TimeOptionCard extends StatelessWidget {
  final ProposalTimeOption option;
  final ProposalModel proposal;
  final Function(VoteType) onVote;
  final VoidCallback onShowBreakdown;

  const TimeOptionCard({
    super.key,
    required this.option,
    required this.proposal,
    required this.onVote,
    required this.onShowBreakdown,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    final hasVoted = option.userVote != null;
    final canVote = proposal.isVotingOpen && !proposal.isExpired;

    return Semantics(
      label: 'Time option: ${_formatDate(option.startTime)}, ${_formatTimeRange(option.startTime, option.endTime)}. '
          '${option.yesCount} yes votes, ${option.maybeCount} maybe votes, ${option.noCount} no votes. '
          '${hasVoted ? 'You voted ${option.userVote!.name}. ' : ''}'
          'Tap to see who voted.',
      button: true,
      enabled: true,
      child: GestureDetector(
        onTap: onShowBreakdown,
        child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasVoted
              ? colorScheme.primary.withValues(alpha: 0.05)
              : appColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasVoted ? colorScheme.primary : appColors.cardBorder,
            width: hasVoted ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date/Time header
            Row(
              children: [
                Icon(
                  Icons.event,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(option.startTime),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        _formatTimeRange(option.startTime, option.endTime),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: appColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                // User's vote indicator
                if (hasVoted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getVoteColor(option.userVote!, context)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      option.userVote!.name.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _getVoteColor(option.userVote!, context),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Vote counts
            Row(
              children: [
                _buildVoteCount(
                  context,
                  Icons.check_circle,
                  option.yesCount,
                  appColors.success,
                  'Yes',
                ),
                const SizedBox(width: 16),
                _buildVoteCount(
                  context,
                  Icons.help_outline,
                  option.maybeCount,
                  appColors.warning,
                  'Maybe',
                ),
                const SizedBox(width: 16),
                _buildVoteCount(
                  context,
                  Icons.cancel,
                  option.noCount,
                  colorScheme.error,
                  'No',
                ),
                const Spacer(),
                Text(
                  '${option.totalVotes} total',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: appColors.textSecondary,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Visual vote tally (progress bar)
            if (option.totalVotes > 0) _buildVoteTally(context),

            if (option.totalVotes > 0) const SizedBox(height: 16),

            // Voting buttons
            if (canVote)
              Row(
                children: [
                  Expanded(
                    child: _buildVoteButton(
                      context,
                      VoteType.yes,
                      'Yes',
                      Icons.check,
                      appColors.success,
                      option.userVote == VoteType.yes,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildVoteButton(
                      context,
                      VoteType.maybe,
                      'Maybe',
                      Icons.help_outline,
                      appColors.warning,
                      option.userVote == VoteType.maybe,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildVoteButton(
                      context,
                      VoteType.no,
                      'No',
                      Icons.close,
                      colorScheme.error,
                      option.userVote == VoteType.no,
                    ),
                  ),
                ],
              ),

            // Voting closed message
            if (!canVote)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: appColors.textMuted.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_clock,
                      size: 16,
                      color: appColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Voting has closed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: appColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),

            // Tap to see breakdown hint
            if (option.totalVotes > 0)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app,
                      size: 14,
                      color: appColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tap to see who voted',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: appColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ), // Close Container
    ), // Close GestureDetector
    ); // Close Semantics
  }

  /// Build vote count with icon
  Widget _buildVoteCount(
    BuildContext context,
    IconData icon,
    int count,
    Color color,
    String label,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  /// Build visual vote tally progress bar
  Widget _buildVoteTally(BuildContext context) {
    final total = option.totalVotes;
    if (total == 0) return const SizedBox.shrink();

    final yesPercent = option.yesCount / total;
    final maybePercent = option.maybeCount / total;
    final noPercent = option.noCount / total;

    final appColors = context.appColors;
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            if (option.yesCount > 0)
              Expanded(
                flex: (yesPercent * 100).toInt(),
                child: Container(
                  color: appColors.success,
                ),
              ),
            if (option.maybeCount > 0)
              Expanded(
                flex: (maybePercent * 100).toInt(),
                child: Container(
                  color: appColors.warning,
                ),
              ),
            if (option.noCount > 0)
              Expanded(
                flex: (noPercent * 100).toInt(),
                child: Container(
                  color: colorScheme.error,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build vote button
  Widget _buildVoteButton(
    BuildContext context,
    VoteType voteType,
    String label,
    IconData icon,
    Color color,
    bool isSelected,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'Vote $label${isSelected ? ', currently selected' : ''}',
      hint: 'Double tap to vote $label for this time option',
      child: Material(
        color: isSelected ? color : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onVote(voteType);
          },
          borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? colorScheme.onPrimary : color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isSelected ? colorScheme.onPrimary : color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ), // Close Row
        ), // Close Container
      ), // Close InkWell
    ), // Close Material
    ); // Close Semantics
  }

  /// Get color for vote type
  Color _getVoteColor(VoteType voteType, BuildContext context) {
    final appColors = context.appColors;
    final colorScheme = Theme.of(context).colorScheme;

    switch (voteType) {
      case VoteType.yes:
        return appColors.success;
      case VoteType.maybe:
        return appColors.warning;
      case VoteType.no:
        return colorScheme.error;
    }
  }

  /// Format date (Today, Tomorrow, or "Wed, Jan 15")
  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return 'Today';
    } else if (date == tomorrow) {
      return 'Tomorrow';
    } else {
      return DateFormat('EEE, MMM d').format(dateTime);
    }
  }

  /// Format time range (e.g., "2:00 PM - 4:00 PM")
  String _formatTimeRange(DateTime start, DateTime end) {
    final startTime = DateFormat.jm().format(start);
    final endTime = DateFormat.jm().format(end);
    return '$startTime - $endTime';
  }
}
