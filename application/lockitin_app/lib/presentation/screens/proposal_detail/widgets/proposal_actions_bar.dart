import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/models/proposal_model.dart';
import '../../../../data/models/proposal_time_option.dart';
import '../../../../core/theme/app_colors.dart';

/// Action bar for proposal creators to confirm or cancel proposals
///
/// Only visible to the proposal creator while voting is open.
/// Shows the winning time option and action buttons.
class ProposalActionsBar extends StatelessWidget {
  final ProposalModel proposal;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ProposalActionsBar({
    super.key,
    required this.proposal,
    required this.onConfirm,
    required this.onCancel,
  });

  /// Check if current user is the creator
  bool get _isCreator {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    return currentUserId != null && currentUserId == proposal.createdBy;
  }

  /// Get the winning time option (highest score)
  ProposalTimeOption? get _winningOption {
    if (proposal.timeOptions == null || proposal.timeOptions!.isEmpty) {
      return null;
    }

    // Sort by score (yes*2 + maybe) descending
    final sorted = List<ProposalTimeOption>.from(proposal.timeOptions!)
      ..sort((a, b) => b.score.compareTo(a.score));

    return sorted.first;
  }

  /// Check if there are any votes
  bool get _hasVotes {
    if (proposal.timeOptions == null) return false;
    return proposal.timeOptions!.any((option) => option.totalVotes > 0);
  }

  @override
  Widget build(BuildContext context) {
    // Only show for creator when voting is open
    if (!_isCreator || !proposal.isVotingOpen) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final winningOption = _winningOption;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: appColors.divider),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Winning option display
            if (winningOption != null && _hasVotes) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: appColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: appColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: appColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Top Choice',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: appColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTimeOption(winningOption),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: appColors.success,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${winningOption.yesCount} YES',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Action buttons
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showCancelDialog(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Confirm button
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _hasVotes
                        ? () => _showConfirmDialog(context, winningOption)
                        : null,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Confirm'),
                    style: FilledButton.styleFrom(
                      backgroundColor: appColors.success,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: appColors.textDisabled,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            // Help text
            if (!_hasVotes)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Waiting for votes to confirm',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: appColors.textMuted,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Format time option for display
  String _formatTimeOption(ProposalTimeOption option) {
    final dateFormat = DateFormat('EEE, MMM d');
    final timeFormat = DateFormat.jm();
    return '${dateFormat.format(option.startTime)} • ${timeFormat.format(option.startTime)} - ${timeFormat.format(option.endTime)}';
  }

  /// Show cancel confirmation dialog
  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Proposal'),
        content: const Text(
          'Are you sure you want to cancel this proposal? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Proposal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onCancel();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Cancel Proposal'),
          ),
        ],
      ),
    );
  }

  /// Show confirm confirmation dialog
  void _showConfirmDialog(BuildContext context, ProposalTimeOption? winningOption) {
    if (winningOption == null) return;

    final appColors = context.appColors;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.event_available,
              color: appColors.success,
            ),
            const SizedBox(width: 8),
            const Expanded(child: Text('Confirm Proposal')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will create a calendar event for all members who voted YES on:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: appColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: appColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    proposal.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimeOption(winningOption),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: appColors.textSecondary,
                        ),
                  ),
                  if (proposal.location != null && proposal.location!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: appColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            proposal.location!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: appColors.textSecondary,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 16,
                  color: appColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${winningOption.yesCount} ${winningOption.yesCount == 1 ? 'person' : 'people'} will be invited',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: appColors.textSecondary,
                      ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            icon: const Icon(Icons.check_circle),
            label: const Text('Create Event'),
            style: FilledButton.styleFrom(
              backgroundColor: appColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
