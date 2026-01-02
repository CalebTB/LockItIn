import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/proposal_model.dart';
import '../../data/models/proposal_time_option.dart';
import '../../data/models/vote_model.dart';

/// Repository interface for proposal operations
/// Abstracts the data source (Supabase) from the domain layer
abstract class IProposalRepository {
  /// Create a new proposal with time options
  Future<String> createProposal({
    required String groupId,
    required String title,
    String? description,
    String? location,
    required DateTime votingDeadline,
    required List<ProposalTimeOption> timeOptions,
  });

  /// Get proposals for a group
  Future<List<ProposalModel>> getGroupProposals(String groupId);

  /// Get a single proposal with details
  Future<ProposalModel> getProposal(String proposalId);

  /// Get vote summary for a proposal
  Future<List<VoteSummary>> getVoteSummary(String proposalId);

  /// Get detailed votes for a time option
  Future<List<VoteModel>> getTimeOptionVotes(String proposalId, String timeOptionId);

  /// Cast a vote on a time option
  Future<void> castVote({
    required String proposalId,
    required String timeOptionId,
    required VoteType vote,
  });

  /// Remove a vote
  Future<void> removeVote({
    required String proposalId,
    required String timeOptionId,
  });

  /// Confirm a proposal with winning time option
  Future<String> confirmProposal({
    required String proposalId,
    required String timeOptionId,
  });

  /// Cancel a proposal
  Future<void> cancelProposal(String proposalId);

  /// Update a proposal
  Future<void> updateProposal({
    required String proposalId,
    String? title,
    String? description,
    String? location,
    DateTime? votingDeadline,
  });

  /// Delete a proposal
  Future<void> deleteProposal(String proposalId);

  /// Check if user has voted on a proposal
  Future<bool> hasUserVoted(String proposalId);

  /// Get user's votes for a proposal
  Future<Map<String, VoteType>> getUserVotes(String proposalId);

  /// Subscribe to vote updates
  RealtimeChannel subscribeToVotes({
    required String proposalId,
    required void Function(Map<String, dynamic> payload) onVoteChange,
  });

  /// Subscribe to proposal status changes
  RealtimeChannel subscribeToProposal({
    required String proposalId,
    required void Function(Map<String, dynamic> payload) onStatusChange,
  });

  /// Unsubscribe from a channel
  Future<void> unsubscribe(RealtimeChannel channel);
}
