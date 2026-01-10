import 'package:flutter/material.dart';
import '../../../../data/models/proposal_time_option.dart';
import '../../../../data/models/vote_model.dart';
import '../../../../core/services/proposal_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/timezone_utils.dart';

/// Bottom sheet showing detailed vote breakdown for a time option
///
/// Displays who voted Yes/Maybe/No with avatars, names, and timestamps.
/// Groups votes by type with colored section headers.
class VoteBreakdownSheet extends StatefulWidget {
  final ProposalTimeOption timeOption;
  final String proposalId;

  const VoteBreakdownSheet({
    super.key,
    required this.timeOption,
    required this.proposalId,
  });

  @override
  State<VoteBreakdownSheet> createState() => _VoteBreakdownSheetState();
}

class _VoteBreakdownSheetState extends State<VoteBreakdownSheet> {
  final ProposalService _proposalService = ProposalService.instance;
  List<VoteModel> _votes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVotes();
  }

  Future<void> _loadVotes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final votes = await _proposalService.getTimeOptionVotes(
        widget.proposalId,
        widget.timeOption.id!,
      );

      if (mounted) {
        setState(() {
          _votes = votes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: appColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vote Breakdown',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimeRange(
                          widget.timeOption.startTime,
                          widget.timeOption.endTime,
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: appColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: _buildContent(context, colorScheme, appColors),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: appColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Votes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: appColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _loadVotes,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_votes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.how_to_vote_outlined,
              size: 64,
              color: appColors.textDisabled,
            ),
            const SizedBox(height: 16),
            Text(
              'No votes yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: appColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to vote on this time option',
              style: TextStyle(
                color: appColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Group votes by type
    final yesVotes = _votes.where((v) => v.vote == VoteType.yes).toList();
    final maybeVotes = _votes.where((v) => v.vote == VoteType.maybe).toList();
    final noVotes = _votes.where((v) => v.vote == VoteType.no).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Yes votes
          if (yesVotes.isNotEmpty) ...[
            _buildVoteSection(
              context,
              'Yes',
              yesVotes.length,
              yesVotes,
              appColors.success,
              Icons.check_circle,
            ),
            const SizedBox(height: 20),
          ],

          // Maybe votes
          if (maybeVotes.isNotEmpty) ...[
            _buildVoteSection(
              context,
              'Maybe',
              maybeVotes.length,
              maybeVotes,
              appColors.warning,
              Icons.help_outline,
            ),
            const SizedBox(height: 20),
          ],

          // No votes
          if (noVotes.isNotEmpty) ...[
            _buildVoteSection(
              context,
              'No',
              noVotes.length,
              noVotes,
              colorScheme.error,
              Icons.cancel,
            ),
          ],
        ],
      ),
    );
  }

  /// Build a section for a specific vote type
  Widget _buildVoteSection(
    BuildContext context,
    String label,
    int count,
    List<VoteModel> votes,
    Color color,
    IconData icon,
  ) {
    final appColors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              '$label ($count)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Vote list
        ...votes.map((vote) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildVoteItem(context, vote, color, appColors),
            )),
      ],
    );
  }

  /// Build a single vote item with avatar and name
  Widget _buildVoteItem(
    BuildContext context,
    VoteModel vote,
    Color color,
    AppColorsExtension appColors,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayName = vote.userFullName ?? 'Anonymous';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Row(
      children: [
        // Avatar
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initial,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Name and timestamp
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatVoteTime(vote.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: appColors.textMuted,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Format time range (e.g., "2:00 PM - 4:00 PM")
  String _formatTimeRange(DateTime start, DateTime end) {
    return '${TimezoneUtils.formatLocal(start, 'EEE, MMM d')} • ${TimezoneUtils.formatLocal(start, 'h:mm a')} - ${TimezoneUtils.formatLocal(end, 'h:mm a')}';
  }

  /// Format vote timestamp relative to now
  String _formatVoteTime(DateTime voteTime) {
    final now = DateTime.now();
    final difference = now.difference(voteTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return TimezoneUtils.formatLocal(voteTime, 'MMM d, yyyy');
    }
  }
}
