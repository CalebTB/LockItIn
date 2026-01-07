import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/proposal_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/route_transitions.dart';
import '../../../providers/proposal_provider.dart';
import '../../../widgets/proposal_card.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/skeleton_loader.dart';
import '../../proposal_detail/proposal_detail_screen.dart';
import '../../group_proposal_wizard.dart';

/// Filter options for proposal list
enum ProposalFilter {
  active,
  closed,
}

/// List view for displaying group proposals with filtering
///
/// Shows all proposals for a group with ability to filter by active/closed status
class ProposalListView extends StatefulWidget {
  final String groupId;
  final String groupName;
  final int groupMemberCount;
  final VoidCallback? onProposalConfirmed;

  const ProposalListView({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.groupMemberCount,
    this.onProposalConfirmed,
  });

  @override
  State<ProposalListView> createState() => _ProposalListViewState();
}

class _ProposalListViewState extends State<ProposalListView> {
  ProposalFilter _filter = ProposalFilter.active;
  ProposalProvider? _provider;

  @override
  void initState() {
    super.initState();
    // Initialize provider with groupId after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _provider = context.read<ProposalProvider>();
        _provider?.initialize(widget.groupId);
      }
    });
  }

  @override
  void dispose() {
    // Don't call unsubscribeAll() - provider manages subscriptions globally
    // Individual proposal detail screens handle their own subscription cleanup
    // Only call unsubscribeAll() on logout or app-level cleanup
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProposalProvider>(
      builder: (context, provider, _) {
        // State hierarchy: Loading → Error → Empty → Content
        return _buildContent(context, provider);
      },
    );
  }

  Widget _buildContent(BuildContext context, ProposalProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    // Loading state (first load only) - Show skeleton loaders
    if (provider.isLoadingProposals && !provider.isInitialized) {
      return ListView.builder(
        padding: const EdgeInsets.only(top: 16, bottom: 16),
        itemCount: 3, // Show 3 skeleton cards
        itemBuilder: (context, index) => const ProposalCardSkeleton(),
      );
    }

    // Error state
    if (provider.proposalsError != null) {
      return _buildErrorState(colorScheme, appColors, provider);
    }

    // Get filtered proposals
    final proposals = _filter == ProposalFilter.active
        ? provider.activeProposals
        : provider.closedProposals;

    // Always show filter toggle + content below
    return Column(
      children: [
        // Filter Toggle (always visible)
        _buildFilterToggle(colorScheme, appColors),
        const SizedBox(height: 8),

        // Content: List or Empty State
        Expanded(
          child: proposals.isEmpty
              ? _buildEmptyState(appColors)
              : RefreshIndicator(
                  onRefresh: () => provider.refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: proposals.length,
                    itemBuilder: (context, index) {
                      final proposal = proposals[index];
                      return ProposalCard(
                        proposal: proposal,
                        onTap: () => _navigateToProposalDetail(proposal),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  /// Build filter toggle (Active / Closed)
  Widget _buildFilterToggle(ColorScheme colorScheme, AppColorsExtension appColors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<ProposalFilter>(
        segments: const [
          ButtonSegment(
            value: ProposalFilter.active,
            label: Text('Active'),
            icon: Icon(Icons.how_to_vote_outlined),
          ),
          ButtonSegment(
            value: ProposalFilter.closed,
            label: Text('Closed'),
            icon: Icon(Icons.check_circle_outline_rounded),
          ),
        ],
        selected: {_filter},
        onSelectionChanged: (Set<ProposalFilter> newSelection) {
          setState(() {
            _filter = newSelection.first;
          });
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.primary;
            }
            return colorScheme.surface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.onPrimary;
            }
            return appColors.textSecondary;
          }),
        ),
      ),
    );
  }

  /// Build error state with retry button
  Widget _buildErrorState(
    ColorScheme colorScheme,
    AppColorsExtension appColors,
    ProposalProvider provider,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: appColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load proposals',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              provider.proposalsError ?? 'Unknown error',
              style: TextStyle(
                fontSize: 15,
                color: appColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton.icon(
                onPressed: () => provider.refresh(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state with CTA
  Widget _buildEmptyState(AppColorsExtension appColors) {
    // Show different empty states based on filter
    if (_filter == ProposalFilter.closed) {
      // No closed proposals - simple message
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 80,
                color: appColors.textDisabled,
              ),
              const SizedBox(height: 24),
              Text(
                'No closed proposals',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: appColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Confirmed, cancelled, and expired proposals will appear here',
                style: TextStyle(
                  fontSize: 15,
                  color: appColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // No active proposals - show EmptyState with CTA
    return EmptyState(
      type: EmptyStateType.noProposals,
      onCreateProposal: _onCreateProposal,
    );
  }

  /// Navigate to proposal detail screen
  Future<void> _navigateToProposalDetail(ProposalModel proposal) async {
    final confirmed = await Navigator.push<bool>(
      context,
      SlideRoute(
        page: ProposalDetailScreen(
          proposalId: proposal.id,
          groupId: proposal.groupId,
        ),
      ),
    );

    // If proposal was confirmed, trigger callback to refresh group calendar
    if (confirmed == true && widget.onProposalConfirmed != null) {
      widget.onProposalConfirmed!();
    }
  }

  /// Trigger proposal creation wizard
  Future<void> _onCreateProposal() async {
    final created = await Navigator.of(context).push<bool>(
      SlideRoute(
        page: GroupProposalWizard(
          groupId: widget.groupId,
          groupName: widget.groupName,
          groupMemberCount: widget.groupMemberCount,
        ),
      ),
    );

    // If proposal was created, refresh the proposals list
    if (created == true && mounted) {
      _provider?.loadProposals(widget.groupId);
    }
  }
}
