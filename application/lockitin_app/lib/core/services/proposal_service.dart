import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';
import '../../data/models/proposal_model.dart';
import '../../data/models/proposal_time_option.dart';
import '../../data/models/vote_model.dart';

/// Service for managing event proposals and voting
class ProposalService {
  static const _tag = 'ProposalService';
  static final ProposalService _instance = ProposalService._internal();
  static ProposalService get instance => _instance;
  ProposalService._internal();

  final _supabase = Supabase.instance.client;

  /// Create a new proposal with time options
  Future<String> createProposal({
    required String groupId,
    required String title,
    String? description,
    String? location,
    required DateTime votingDeadline,
    required List<ProposalTimeOption> timeOptions,
  }) async {
    try {
      Logger.info('ProposalService', 'Creating proposal for group: $groupId');

      // Convert time options to JSON array
      final timeOptionsJson = timeOptions
          .map((option) => option.toCreateJson())
          .toList();

      // Call RPC function to create proposal with options in a single transaction
      final result = await _supabase.rpc(
        'create_proposal_with_options',
        params: {
          'p_group_id': groupId,
          'p_title': title,
          'p_description': description,
          'p_location': location,
          'p_voting_deadline': votingDeadline.toIso8601String(),
          'p_time_options': jsonEncode(timeOptionsJson),
        },
      );

      final proposalId = result as String;
      Logger.info('ProposalService', 'Created proposal: $proposalId');
      return proposalId;
    } catch (e) {
      Logger.error(_tag, 'Failed to create proposal: $e');
      rethrow;
    }
  }

  /// Get proposals for a group
  Future<List<ProposalModel>> getGroupProposals(String groupId) async {
    try {
      Logger.info('ProposalService', 'Fetching proposals for group: $groupId');

      final result = await _supabase.rpc(
        'get_group_proposals',
        params: {'p_group_id': groupId},
      );

      final proposals = (result as List)
          .map((json) => ProposalModel.fromJson(json as Map<String, dynamic>))
          .toList();

      Logger.info('ProposalService', 'Fetched ${proposals.length} proposals');
      return proposals;
    } catch (e) {
      Logger.error(_tag, 'Failed to fetch group proposals: $e');
      rethrow;
    }
  }

  /// Get a single proposal with time options and vote summaries
  Future<ProposalModel> getProposal(String proposalId) async {
    try {
      Logger.info('ProposalService', 'Fetching proposal: $proposalId');

      // Fetch proposal
      final proposalResult = await _supabase
          .from('event_proposals')
          .select('*, users!created_by(full_name)')
          .eq('id', proposalId)
          .single();

      // Fetch vote summary
      final voteSummary = await _supabase.rpc(
        'get_proposal_vote_summary',
        params: {'p_proposal_id': proposalId},
      );

      // Build time options with vote counts
      final timeOptions = (voteSummary as List)
          .map((json) => ProposalTimeOption.fromVoteSummary(json as Map<String, dynamic>))
          .toList();

      // Build proposal with time options
      final proposal = ProposalModel.fromJson({
        ...proposalResult,
        'creator_name': proposalResult['users']?['full_name'],
        'time_options': timeOptions.map((o) => {
          'id': o.id,
          'start_time': o.startTime.toIso8601String(),
          'end_time': o.endTime.toIso8601String(),
          'yes_count': o.yesCount,
          'maybe_count': o.maybeCount,
          'no_count': o.noCount,
        }).toList(),
      });

      Logger.info('ProposalService', 'Fetched proposal with ${timeOptions.length} options');
      return proposal;
    } catch (e) {
      Logger.error(_tag, 'Failed to fetch proposal: $e');
      rethrow;
    }
  }

  /// Get vote summary for a proposal
  Future<List<VoteSummary>> getVoteSummary(String proposalId) async {
    try {
      final result = await _supabase.rpc(
        'get_proposal_vote_summary',
        params: {'p_proposal_id': proposalId},
      );

      return (result as List)
          .map((json) => VoteSummary.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      Logger.error(_tag, 'Failed to fetch vote summary: $e');
      rethrow;
    }
  }

  /// Get detailed votes for a time option
  Future<List<VoteModel>> getTimeOptionVotes(
    String proposalId,
    String timeOptionId,
  ) async {
    try {
      final result = await _supabase.rpc(
        'get_time_option_votes',
        params: {'p_time_option_id': timeOptionId},
      );

      return (result as List)
          .map((json) => VoteModel.fromRpcJson(
                json as Map<String, dynamic>,
                proposalId,
                timeOptionId,
              ))
          .toList();
    } catch (e) {
      Logger.error(_tag, 'Failed to fetch time option votes: $e');
      rethrow;
    }
  }

  /// Cast a vote on a time option
  Future<void> castVote({
    required String proposalId,
    required String timeOptionId,
    required VoteType vote,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      Logger.info('ProposalService', 'Casting vote: $vote for option: $timeOptionId');

      await _supabase.from('proposal_votes').upsert({
        'proposal_id': proposalId,
        'time_option_id': timeOptionId,
        'user_id': userId,
        'vote': vote.name,
      }, onConflict: 'proposal_id,time_option_id,user_id');

      Logger.info('ProposalService', 'Vote cast successfully');
    } catch (e) {
      Logger.error(_tag, 'Failed to cast vote: $e');
      rethrow;
    }
  }

  /// Remove a vote
  Future<void> removeVote({
    required String proposalId,
    required String timeOptionId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase
          .from('proposal_votes')
          .delete()
          .eq('proposal_id', proposalId)
          .eq('time_option_id', timeOptionId)
          .eq('user_id', userId);

      Logger.info('ProposalService', 'Vote removed successfully');
    } catch (e) {
      Logger.error(_tag, 'Failed to remove vote: $e');
      rethrow;
    }
  }

  /// Confirm a proposal with a winning time option
  Future<String> confirmProposal({
    required String proposalId,
    required String timeOptionId,
  }) async {
    try {
      Logger.info('ProposalService', 'Confirming proposal: $proposalId with option: $timeOptionId');

      final result = await _supabase.rpc(
        'confirm_proposal',
        params: {
          'p_proposal_id': proposalId,
          'p_time_option_id': timeOptionId,
        },
      );

      final eventId = result as String;
      Logger.info('ProposalService', 'Proposal confirmed, event created: $eventId');
      return eventId;
    } catch (e) {
      Logger.error(_tag, 'Failed to confirm proposal: $e');
      rethrow;
    }
  }

  /// Cancel a proposal
  Future<void> cancelProposal(String proposalId) async {
    try {
      await _supabase
          .from('event_proposals')
          .update({'status': 'cancelled'})
          .eq('id', proposalId);

      Logger.info('ProposalService', 'Proposal cancelled: $proposalId');
    } catch (e) {
      Logger.error(_tag, 'Failed to cancel proposal: $e');
      rethrow;
    }
  }

  /// Update a proposal
  Future<void> updateProposal({
    required String proposalId,
    String? title,
    String? description,
    String? location,
    DateTime? votingDeadline,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (location != null) updates['location'] = location;
      if (votingDeadline != null) {
        updates['voting_deadline'] = votingDeadline.toIso8601String();
      }

      if (updates.isEmpty) return;

      await _supabase
          .from('event_proposals')
          .update(updates)
          .eq('id', proposalId);

      Logger.info('ProposalService', 'Proposal updated: $proposalId');
    } catch (e) {
      Logger.error(_tag, 'Failed to update proposal: $e');
      rethrow;
    }
  }

  /// Delete a proposal
  Future<void> deleteProposal(String proposalId) async {
    try {
      await _supabase
          .from('event_proposals')
          .delete()
          .eq('id', proposalId);

      Logger.info('ProposalService', 'Proposal deleted: $proposalId');
    } catch (e) {
      Logger.error(_tag, 'Failed to delete proposal: $e');
      rethrow;
    }
  }

  /// Check if user has voted on a proposal
  Future<bool> hasUserVoted(String proposalId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final result = await _supabase.rpc(
        'has_user_voted_on_proposal',
        params: {
          'p_proposal_id': proposalId,
          'p_user_id': userId,
        },
      );

      return result as bool;
    } catch (e) {
      Logger.error(_tag, 'Failed to check user vote status: $e');
      return false;
    }
  }

  /// Get user's votes for a proposal
  Future<Map<String, VoteType>> getUserVotes(String proposalId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      final result = await _supabase
          .from('proposal_votes')
          .select('time_option_id, vote')
          .eq('proposal_id', proposalId)
          .eq('user_id', userId);

      final votes = <String, VoteType>{};
      for (final row in result as List) {
        votes[row['time_option_id'] as String] =
            VoteType.fromString(row['vote'] as String);
      }
      return votes;
    } catch (e) {
      Logger.error(_tag, 'Failed to fetch user votes: $e');
      return {};
    }
  }

  /// Subscribe to vote updates for a proposal
  RealtimeChannel subscribeToVotes({
    required String proposalId,
    required void Function(Map<String, dynamic> payload) onVoteChange,
  }) {
    Logger.info('ProposalService', 'Subscribing to votes for proposal: $proposalId');

    return _supabase.channel('proposal_votes:$proposalId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'proposal_votes',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'proposal_id',
          value: proposalId,
        ),
        callback: (payload) {
          Logger.info('ProposalService', 'Vote change received: ${payload.eventType}');
          onVoteChange(payload.newRecord);
        },
      )
      .subscribe();
  }

  /// Subscribe to proposal status changes
  RealtimeChannel subscribeToProposal({
    required String proposalId,
    required void Function(Map<String, dynamic> payload) onStatusChange,
  }) {
    Logger.info('ProposalService', 'Subscribing to proposal: $proposalId');

    return _supabase.channel('event_proposals:$proposalId')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'event_proposals',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: proposalId,
        ),
        callback: (payload) {
          Logger.info('ProposalService', 'Proposal status change received');
          onStatusChange(payload.newRecord);
        },
      )
      .subscribe();
  }

  /// Unsubscribe from a channel
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
    Logger.info('ProposalService', 'Unsubscribed from channel');
  }
}
