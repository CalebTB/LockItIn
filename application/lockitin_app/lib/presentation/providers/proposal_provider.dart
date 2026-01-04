import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/proposal_model.dart';
import '../../data/models/proposal_time_option.dart';
import '../../data/models/vote_model.dart';
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

  /// Track real-time connection state
  bool _isRealtimeConnected = true;
  String? _connectionError;

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

  /// Check if real-time connection is active
  bool get isRealtimeConnected => _isRealtimeConnected;

  /// Get connection error message if any
  String? get connectionError => _connectionError;

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
      Logger.info('ProposalProvider', 'Already subscribed to proposal: $proposalId');
      return;
    }

    Logger.info('ProposalProvider', 'Subscribing to votes for proposal: $proposalId');

    try {
      final subscription = _proposalService.subscribeToVotes(
        proposalId: proposalId,
        onVoteChange: (payload) {
          // Check if this vote belongs to our proposal
          final optionId = payload['option_id'] as String?;
          if (optionId == null) {
            Logger.warning('ProposalProvider', 'Received vote change without option_id');
            return;
          }

          // Get the proposal to check if this option belongs to it
          final proposal = getProposalById(proposalId);
          if (proposal?.timeOptions == null) return;

          // Only refresh if the vote is for one of this proposal's time options
          final belongsToProposal = proposal!.timeOptions!.any((option) => option.id == optionId);
          if (!belongsToProposal) {
            Logger.info('ProposalProvider', 'Vote change for different proposal, ignoring');
            return;
          }

          Logger.info('ProposalProvider', 'Vote changed for proposal: $proposalId');

          // Mark connection as active
          if (!_isRealtimeConnected) {
            _isRealtimeConnected = true;
            _connectionError = null;
            Logger.info('ProposalProvider', 'Real-time connection restored');
            notifyListeners();
          }

          // Refresh the specific proposal's data
          _refreshProposal(proposalId);
        },
      );

      _voteSubscriptions[proposalId] = subscription;

      // Mark connection as active
      _isRealtimeConnected = true;
      _connectionError = null;

      Logger.info('ProposalProvider', 'Successfully subscribed to votes for proposal: $proposalId');
    } catch (e) {
      Logger.error('ProposalProvider', 'Failed to subscribe to votes: $e');
      _isRealtimeConnected = false;
      _connectionError = e.toString();
      notifyListeners();
    }
  }

  /// Refresh a single proposal's data (for real-time updates)
  Future<void> _refreshProposal(String proposalId) async {
    try {
      Logger.info('ProposalProvider', 'Refreshing proposal data: $proposalId');

      final updatedProposal = await _proposalService.getProposal(proposalId);

      // Find and update the proposal in the list
      final index = _proposals.indexWhere((p) => p.id == proposalId);
      if (index != -1) {
        _proposals[index] = updatedProposal;
        notifyListeners();
        Logger.info('ProposalProvider', 'Proposal refreshed successfully');
      } else {
        Logger.warning('ProposalProvider', 'Proposal not found in local state: $proposalId');
      }
    } catch (e) {
      Logger.error('ProposalProvider', 'Failed to refresh proposal: $e');

      // Mark connection as potentially lost
      _isRealtimeConnected = false;
      _connectionError = 'Failed to sync latest data';
      notifyListeners();

      // Attempt to reconnect after a delay
      Future.delayed(const Duration(seconds: 5), () {
        if (!_isRealtimeConnected) {
          Logger.info('ProposalProvider', 'Attempting to reconnect...');
          _attemptReconnect(proposalId);
        }
      });
    }
  }

  /// Attempt to reconnect real-time subscription
  Future<void> _attemptReconnect(String proposalId) async {
    try {
      Logger.info('ProposalProvider', 'Reconnecting to proposal: $proposalId');

      // Unsubscribe old channel
      final oldSubscription = _voteSubscriptions.remove(proposalId);
      await oldSubscription?.unsubscribe();

      // Resubscribe
      subscribeToProposalVotes(proposalId);
    } catch (e) {
      Logger.error('ProposalProvider', 'Failed to reconnect: $e');
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

  // ============================================================================
  // Voting & Proposal Management
  // ============================================================================

  /// Load a single proposal by ID (for detail view)
  Future<void> loadProposal(String proposalId) async {
    try {
      Logger.info('ProposalProvider', 'Loading proposal: $proposalId');

      final proposal = await _proposalService.getProposal(proposalId);

      // Update in proposals list if exists, otherwise add
      final index = _proposals.indexWhere((p) => p.id == proposalId);
      if (index != -1) {
        _proposals[index] = proposal;
      } else {
        _proposals.add(proposal);
      }

      notifyListeners();
      Logger.info('ProposalProvider', 'Proposal loaded successfully');
    } catch (e) {
      Logger.error('ProposalProvider', 'Failed to load proposal: $e');
      rethrow;
    }
  }

  /// Get proposal by ID from cached list
  ProposalModel? getProposalById(String proposalId) {
    try {
      return _proposals.firstWhere((p) => p.id == proposalId);
    } catch (e) {
      return null;
    }
  }

  /// Cast vote with optimistic UI update
  Future<void> castVote(
    String proposalId,
    String timeOptionId,
    VoteType voteType,
  ) async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Find proposal and option
    final proposalIndex = _proposals.indexWhere((p) => p.id == proposalId);
    if (proposalIndex == -1) {
      throw Exception('Proposal not found in local state');
    }

    final proposal = _proposals[proposalIndex];
    if (proposal.timeOptions == null) {
      throw Exception('No time options available');
    }

    final optionIndex = proposal.timeOptions!.indexWhere((o) => o.id == timeOptionId);
    if (optionIndex == -1) {
      throw Exception('Time option not found');
    }

    // Store old state for rollback
    final oldProposal = proposal;

    try {
      Logger.info('ProposalProvider', 'Casting vote: $voteType on option: $timeOptionId');

      // Optimistic update
      final updatedOption = _updateOptionVote(
        proposal.timeOptions![optionIndex],
        currentUserId,
        voteType,
      );

      final updatedOptions = List<ProposalTimeOption>.from(proposal.timeOptions!);
      updatedOptions[optionIndex] = updatedOption;

      final updatedProposal = proposal.copyWith(timeOptions: updatedOptions);
      _proposals[proposalIndex] = updatedProposal;
      notifyListeners();

      // Perform actual vote
      await _proposalService.castVote(
        proposalId: proposalId,
        timeOptionId: timeOptionId,
        vote: voteType,
      );

      Logger.info('ProposalProvider', 'Vote cast successfully');
    } catch (e) {
      // Rollback on error
      Logger.error('ProposalProvider', 'Failed to cast vote, rolling back: $e');
      _proposals[proposalIndex] = oldProposal;
      notifyListeners();
      rethrow;
    }
  }

  /// Helper to update vote optimistically
  ProposalTimeOption _updateOptionVote(
    ProposalTimeOption option,
    String userId,
    VoteType voteType,
  ) {
    // Calculate new vote counts
    int yesCount = option.yesCount;
    int maybeCount = option.maybeCount;
    int noCount = option.noCount;

    // Remove old vote if user already voted
    if (option.userVote != null) {
      switch (option.userVote!) {
        case VoteType.yes:
          yesCount = (yesCount - 1).clamp(0, double.infinity).toInt();
          break;
        case VoteType.maybe:
          maybeCount = (maybeCount - 1).clamp(0, double.infinity).toInt();
          break;
        case VoteType.no:
          noCount = (noCount - 1).clamp(0, double.infinity).toInt();
          break;
      }
    }

    // Add new vote
    switch (voteType) {
      case VoteType.yes:
        yesCount++;
        break;
      case VoteType.maybe:
        maybeCount++;
        break;
      case VoteType.no:
        noCount++;
        break;
    }

    return option.copyWith(
      yesCount: yesCount,
      maybeCount: maybeCount,
      noCount: noCount,
      userVote: voteType,
    );
  }

  /// Confirm a proposal with a specific time option (creator only)
  /// Creates a calendar event and updates proposal status to confirmed
  Future<String> confirmProposal(String proposalId, String timeOptionId) async {
    try {
      Logger.info('ProposalProvider', 'Confirming proposal: $proposalId with option: $timeOptionId');

      // Call service to confirm and create event
      final eventId = await _proposalService.confirmProposal(
        proposalId: proposalId,
        timeOptionId: timeOptionId,
      );

      // Refresh the proposal to get updated status
      await loadProposal(proposalId);

      Logger.info('ProposalProvider', 'Proposal confirmed, event created: $eventId');
      return eventId;
    } catch (e) {
      Logger.error('ProposalProvider', 'Failed to confirm proposal: $e');
      rethrow;
    }
  }

  /// Cancel a proposal (creator only)
  /// Updates proposal status to cancelled
  Future<void> cancelProposal(String proposalId) async {
    try {
      Logger.info('ProposalProvider', 'Cancelling proposal: $proposalId');

      // Call service to cancel
      await _proposalService.cancelProposal(proposalId);

      // Refresh the proposal to get updated status
      await loadProposal(proposalId);

      Logger.info('ProposalProvider', 'Proposal cancelled successfully');
    } catch (e) {
      Logger.error('ProposalProvider', 'Failed to cancel proposal: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
  }
}
