import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../data/models/proposal_model.dart';
import '../../../data/models/proposal_time_option.dart';
import '../../../data/models/vote_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/proposal_provider.dart';
import '../../widgets/skeleton_loader.dart';
import 'widgets/proposal_header.dart';
import 'widgets/proposal_info_section.dart';
import 'widgets/time_option_card.dart';
import 'widgets/vote_breakdown_sheet.dart';
import 'widgets/proposal_actions_bar.dart';
import 'widgets/proposal_status_banner.dart';

/// Detail view for a single proposal with voting interface
///
/// Displays full proposal information, time options with vote counts,
/// and allows users to cast votes. Shows real-time vote updates via WebSocket.
class ProposalDetailScreen extends StatefulWidget {
  final String proposalId;
  final String groupId;

  const ProposalDetailScreen({
    super.key,
    required this.proposalId,
    required this.groupId,
  });

  @override
  State<ProposalDetailScreen> createState() => _ProposalDetailScreenState();
}

class _ProposalDetailScreenState extends State<ProposalDetailScreen> {
  ProposalProvider? _provider;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeProposal();
  }

  Future<void> _initializeProposal() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Wait for frame to render before accessing Provider
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        _provider = context.read<ProposalProvider>();

        // Subscribe to real-time vote updates
        _provider?.subscribeToProposalVotes(widget.proposalId);

        // Always load proposal details to ensure time options are loaded
        // (List view may have cached proposal without time options)
        await _provider?.loadProposal(widget.proposalId);

        if (mounted) {
          setState(() => _isLoading = false);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _getUserFriendlyError(e);
          _isLoading = false;
        });
      }
    }
  }

  ProposalModel? _getProposalFromProvider() {
    if (_provider == null) return null;
    try {
      return _provider!.proposals.firstWhere((p) => p.id == widget.proposalId);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    // Clean up this proposal's vote subscription
    // Don't call unsubscribeAll() as it would kill subscriptions for other screens
    _provider?.unsubscribeFromProposal(widget.proposalId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Proposal')),
        body: const ProposalDetailSkeleton(),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Proposal')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: context.appColors.textMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to Load Proposal',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: context.appColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _initializeProposal,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Consumer<ProposalProvider>(
      builder: (context, provider, _) {
        final proposal = _getProposalFromProvider();

        if (proposal == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Proposal')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 80,
                      color: context.appColors.textDisabled,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Proposal Not Found',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This proposal may have been deleted.',
                      style: TextStyle(
                        color: context.appColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return _buildProposalDetail(context, proposal, provider);
      },
    );
  }

  Widget _buildProposalDetail(
    BuildContext context,
    ProposalModel proposal,
    ProposalProvider provider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proposal Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMoreOptions(context, proposal),
          ),
        ],
      ),
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _refreshProposal(provider),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              // Connection status banner
              if (!provider.isRealtimeConnected)
                _buildConnectionBanner(context, provider),

              // Header: Status, Title, Creator, Deadline
              ProposalHeader(proposal: proposal),

              const SizedBox(height: 16),

              // Info Section: Description, Location
              ProposalInfoSection(
                proposal: proposal,
                groupId: widget.groupId,
              ),

              const SizedBox(height: 16),

              // Status banner for closed proposals
              ProposalStatusBanner(proposal: proposal),

              const SizedBox(height: 24),

              // Time Options Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_available,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Vote on Time Options',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // List of time options with voting
              if (proposal.timeOptions != null && proposal.timeOptions!.isNotEmpty)
                ...proposal.timeOptions!.map((option) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: TimeOptionCard(
                        option: option,
                        proposal: proposal,
                        onVote: (voteType) => _handleVote(
                          provider,
                          proposal.id,
                          option.id!,
                          voteType,
                        ),
                        onShowBreakdown: () => _showVoteBreakdown(
                          context,
                          option,
                          proposal,
                        ),
                      ),
                    ))
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context.appColors.cardBorder,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 48,
                            color: context.appColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No time options available',
                            style: TextStyle(
                              color: context.appColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),

          // Creator actions bar (only for creator when voting is open)
          ProposalActionsBar(
            proposal: proposal,
            onConfirm: () => _handleConfirmProposal(provider, proposal),
            onCancel: () => _handleCancelProposal(provider, proposal),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshProposal(ProposalProvider provider) async {
    await provider.loadProposal(widget.proposalId);
  }

  /// Build connection status banner
  Widget _buildConnectionBanner(BuildContext context, ProposalProvider provider) {
    final appColors = context.appColors;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: appColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off,
            size: 20,
            color: appColors.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reconnecting to live updates...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: appColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (provider.connectionError != null)
                  Text(
                    provider.connectionError!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: appColors.textSecondary,
                        ),
                  ),
              ],
            ),
          ),
          // Loading indicator
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(appColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle vote casting with optimistic UI and error handling
  Future<void> _handleVote(
    ProposalProvider provider,
    String proposalId,
    String timeOptionId,
    VoteType voteType,
  ) async {
    try {
      // Cast vote (will trigger optimistic update in provider)
      await provider.castVote(proposalId, timeOptionId, voteType);

      // Haptic feedback on successful vote
      if (mounted) {
        HapticFeedback.selectionClick();

        // Optional: Show brief confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voted ${voteType.name.toUpperCase()}'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getUserFriendlyError(e)),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _handleVote(
                provider,
                proposalId,
                timeOptionId,
                voteType,
              ),
            ),
          ),
        );
      }
    }
  }

  /// Show vote breakdown bottom sheet
  void _showVoteBreakdown(
    BuildContext context,
    ProposalTimeOption option,
    ProposalModel proposal,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => VoteBreakdownSheet(
          timeOption: option,
          proposalId: proposal.id,
        ),
      ),
    );
  }

  /// Handle proposal confirmation
  Future<void> _handleConfirmProposal(
    ProposalProvider provider,
    ProposalModel proposal,
  ) async {
    // Get winning time option
    final winningOption = proposal.timeOptions
        ?.reduce((a, b) => a.score > b.score ? a : b);

    if (winningOption == null || winningOption.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No time option selected'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Confirm proposal and create event
      await provider.confirmProposal(
        proposal.id,
        winningOption.id!,
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event created successfully!'),
            backgroundColor: context.appColors.success,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Navigate to event detail when implemented
              },
            ),
          ),
        );

        // Navigate back to group detail
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getUserFriendlyError(e)),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _handleConfirmProposal(provider, proposal),
            ),
          ),
        );
      }
    }
  }

  /// Handle proposal cancellation
  Future<void> _handleCancelProposal(
    ProposalProvider provider,
    ProposalModel proposal,
  ) async {
    try {
      // Cancel proposal
      await provider.cancelProposal(proposal.id);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Proposal cancelled'),
            backgroundColor: context.appColors.textSecondary,
          ),
        );

        // Navigate back to group detail
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getUserFriendlyError(e)),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _handleCancelProposal(provider, proposal),
            ),
          ),
        );
      }
    }
  }

  void _showMoreOptions(BuildContext context, ProposalModel proposal) {
    // Future: Share, report, etc.
  }

  /// Convert technical error messages to user-friendly text
  String _getUserFriendlyError(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    // Network errors
    if (errorStr.contains('network') || errorStr.contains('socket') || errorStr.contains('connection')) {
      return 'Check your connection and try again';
    }

    // Proposal expired
    if (errorStr.contains('expired') || errorStr.contains('deadline')) {
      return 'This proposal has expired';
    }

    // Permission errors
    if (errorStr.contains('permission') || errorStr.contains('policy') || errorStr.contains('unauthorized')) {
      return 'You don\'t have permission to do that';
    }

    // Voting deadline passed
    if (errorStr.contains('voting') && errorStr.contains('closed')) {
      return 'Voting has closed for this proposal';
    }

    // Already voted
    if (errorStr.contains('already voted') || errorStr.contains('duplicate')) {
      return 'You\'ve already voted on this option';
    }

    // Not found
    if (errorStr.contains('not found') || errorStr.contains('404')) {
      return 'Proposal not found';
    }

    // Default fallback
    return 'Something went wrong. Please try again';
  }
}
