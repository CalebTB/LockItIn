import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/proposal_model.dart';
import '../../core/services/proposal_service.dart';
import '../../core/utils/logger.dart';

/// Provider for proposal system state management
///
/// Manages proposal list, voting state, and real-time updates for a group
class ProposalProvider extends ChangeNotifier {
  final ProposalService _proposalService = ProposalService.instance;

  /// List of proposals for the currently selected group
  List<ProposalModel> _proposals = [];

  /// Currently selected group ID
  String? _selectedGroupId;

  /// Loading state for proposals
  bool _isLoadingProposals = false;

  /// Error state for proposal operations
  String? _proposalsError;

  /// Whether initial data has been loaded
  bool _isInitialized = false;

  /// Real-time subscription for proposal changes
  RealtimeChannel? _proposalSubscription;

  /// Map of vote subscriptions per proposal (for real-time vote updates)
  final Map<String, RealtimeChannel> _voteSubscriptions = {};

  // ============================================================================
  // Getters
  // ============================================================================

  List<ProposalModel> get proposals => _proposals;

  /// Get only active proposals (status == voting)
  List<ProposalModel> get activeProposals =>
      _proposals.where((p) => p.status == ProposalStatus.voting).toList();

  /// Get closed proposals (status != voting)
  List<ProposalModel> get closedProposals =>
      _proposals.where((p) => p.status != ProposalStatus.voting).toList();

  bool get isLoadingProposals => _isLoadingProposals;
  String? get proposalsError => _proposalsError;
  bool get isInitialized => _isInitialized;

  /// Total count of proposals
  int get proposalCount => _proposals.length;

  /// Check if user has any proposals
  bool get hasProposals => _proposals.isNotEmpty;

  /// Get currently selected group ID
  String? get selectedGroupId => _selectedGroupId;

  // ============================================================================
  // Initialization & Loading
  // ============================================================================

  /// Initialize the provider and load proposals for the given group
  /// Skips if already initialized for this group - use [refresh] to force reload
  Future<void> initialize(String groupId) async {
    if (_isInitialized && _selectedGroupId == groupId) {
      Logger.info('ProposalProvider', 'Already initialized for group: $groupId');
      return;
    }

    // Clean up old subscriptions if switching groups
    if (_selectedGroupId != groupId) {
      unsubscribeAll();
    }

    _selectedGroupId = groupId;
    await loadProposals(groupId);
    subscribeToGroupProposals(groupId);
    _isInitialized = true;
  }

  /// Load proposals for a specific group
  Future<void> loadProposals(String groupId) async {
    _isLoadingProposals = true;
    _proposalsError = null;
    // Don't notify here - reduces unnecessary rebuilds

    try {
      _proposals = await _proposalService.getGroupProposals(groupId);
      _selectedGroupId = groupId;
      Logger.info('ProposalProvider', 'Loaded ${_proposals.length} proposals for group: $groupId');
    } catch (e) {
      Logger.error('ProposalProvider', 'Failed to load proposals: $e');
      _proposalsError = e.toString();
    } finally {
      _isLoadingProposals = false;
      notifyListeners(); // Single rebuild with final state
    }
  }

  /// Refresh proposals for the current group
  /// Forces a reload even if already initialized
  Future<void> refresh() async {
    if (_selectedGroupId == null) {
      Logger.warning('ProposalProvider', 'Cannot refresh: no group selected');
      return;
    }
    await loadProposals(_selectedGroupId!);
  }

  /// Reset all state - call this on logout or when navigating away
  ///
  /// CRITICAL: This must be called to clear cached data and prevent
  /// data leaking between users or groups
  void reset() {
    Logger.info('ProposalProvider', 'Resetting ProposalProvider state');

    // Clean up subscriptions
    unsubscribeAll();

    // Clear all cached data
    _proposals = [];
    _selectedGroupId = null;

    // Reset loading states
    _isLoadingProposals = false;

    // Clear errors
    _proposalsError = null;

    // Mark as uninitialized
    _isInitialized = false;

    notifyListeners();
  }

  // ============================================================================
  // Real-Time Subscriptions
  // ============================================================================

  /// Subscribe to proposal changes for a group
  /// Automatically refreshes the list when proposals are created/updated
  void subscribeToGroupProposals(String groupId) {
    // Clean up existing subscription
    _proposalSubscription?.unsubscribe();

    Logger.info('ProposalProvider', 'Subscribing to proposals for group: $groupId');

    try {
      _proposalSubscription = _proposalService.subscribeToProposal(
        proposalId: groupId,
        onStatusChange: (payload) {
          Logger.info('ProposalProvider', 'Proposal status changed, refreshing...');
          loadProposals(groupId);
        },
      );
    } catch (e) {
      Logger.error('ProposalProvider', 'Failed to subscribe to proposals: $e');
    }
  }

  /// Subscribe to vote updates for a specific proposal
  /// Used for real-time vote count updates in detail view
  void subscribeToProposalVotes(String proposalId) {
    // Don't subscribe if already subscribed
    if (_voteSubscriptions.containsKey(proposalId)) {
      return;
    }

    Logger.info('ProposalProvider', 'Subscribing to votes for proposal: $proposalId');

    try {
      final subscription = _proposalService.subscribeToVotes(
        proposalId: proposalId,
        onVoteChange: (payload) {
          Logger.info('ProposalProvider', 'Vote changed for proposal: $proposalId');
          // Refresh the specific proposal's data
          _refreshProposal(proposalId);
        },
      );

      _voteSubscriptions[proposalId] = subscription;
    } catch (e) {
      Logger.error('ProposalProvider', 'Failed to subscribe to votes: $e');
    }
  }

  /// Refresh a single proposal's data (for real-time updates)
  Future<void> _refreshProposal(String proposalId) async {
    try {
      final updatedProposal = await _proposalService.getProposal(proposalId);

      // Find and update the proposal in the list
      final index = _proposals.indexWhere((p) => p.id == proposalId);
      if (index != -1) {
        _proposals[index] = updatedProposal;
        notifyListeners();
      }
    } catch (e) {
      Logger.error('ProposalProvider', 'Failed to refresh proposal: $e');
    }
  }

  /// Unsubscribe from all real-time channels
  void unsubscribeAll() {
    Logger.info('ProposalProvider', 'Unsubscribing from all channels');

    // Unsubscribe from group proposals
    _proposalSubscription?.unsubscribe();
    _proposalSubscription = null;

    // Unsubscribe from all vote channels
    for (final subscription in _voteSubscriptions.values) {
      subscription.unsubscribe();
    }
    _voteSubscriptions.clear();
  }

  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
  }
}
