import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/proposal_repository.dart';
import '../../core/services/proposal_service.dart';
import '../models/proposal_model.dart';
import '../models/proposal_time_option.dart';
import '../models/vote_model.dart';

/// Implementation of IProposalRepository using ProposalService
class ProposalRepositoryImpl implements IProposalRepository {
  final ProposalService _service;

  ProposalRepositoryImpl({ProposalService? service})
      : _service = service ?? ProposalService.instance;

  @override
  Future<String> createProposal({
    required String groupId,
    required String title,
    String? description,
    String? location,
    required DateTime votingDeadline,
    required List<ProposalTimeOption> timeOptions,
  }) {
    return _service.createProposal(
      groupId: groupId,
      title: title,
      description: description,
      location: location,
      votingDeadline: votingDeadline,
      timeOptions: timeOptions,
    );
  }

  @override
  Future<List<ProposalModel>> getGroupProposals(String groupId) {
    return _service.getGroupProposals(groupId);
  }

  @override
  Future<ProposalModel> getProposal(String proposalId) {
    return _service.getProposal(proposalId);
  }

  @override
  Future<List<VoteSummary>> getVoteSummary(String proposalId) {
    return _service.getVoteSummary(proposalId);
  }

  @override
  Future<List<VoteModel>> getTimeOptionVotes(String proposalId, String timeOptionId) {
    return _service.getTimeOptionVotes(proposalId, timeOptionId);
  }

  @override
  Future<void> castVote({
    required String proposalId,
    required String timeOptionId,
    required VoteType vote,
  }) {
    return _service.castVote(
      proposalId: proposalId,
      timeOptionId: timeOptionId,
      vote: vote,
    );
  }

  @override
  Future<void> removeVote({
    required String proposalId,
    required String timeOptionId,
  }) {
    return _service.removeVote(
      proposalId: proposalId,
      timeOptionId: timeOptionId,
    );
  }

  @override
  Future<String> confirmProposal({
    required String proposalId,
    required String timeOptionId,
  }) {
    return _service.confirmProposal(
      proposalId: proposalId,
      timeOptionId: timeOptionId,
    );
  }

  @override
  Future<void> cancelProposal(String proposalId) {
    return _service.cancelProposal(proposalId);
  }

  @override
  Future<void> updateProposal({
    required String proposalId,
    String? title,
    String? description,
    String? location,
    DateTime? votingDeadline,
  }) {
    return _service.updateProposal(
      proposalId: proposalId,
      title: title,
      description: description,
      location: location,
      votingDeadline: votingDeadline,
    );
  }

  @override
  Future<void> deleteProposal(String proposalId) {
    return _service.deleteProposal(proposalId);
  }

  @override
  Future<bool> hasUserVoted(String proposalId) {
    return _service.hasUserVoted(proposalId);
  }

  @override
  Future<Map<String, VoteType>> getUserVotes(String proposalId) {
    return _service.getUserVotes(proposalId);
  }

  @override
  RealtimeChannel subscribeToVotes({
    required String proposalId,
    required void Function(Map<String, dynamic> payload) onVoteChange,
  }) {
    return _service.subscribeToVotes(
      proposalId: proposalId,
      onVoteChange: onVoteChange,
    );
  }

  @override
  RealtimeChannel subscribeToProposal({
    required String proposalId,
    required void Function(Map<String, dynamic> payload) onStatusChange,
  }) {
    return _service.subscribeToProposal(
      proposalId: proposalId,
      onStatusChange: onStatusChange,
    );
  }

  @override
  Future<void> unsubscribe(RealtimeChannel channel) {
    return _service.unsubscribe(channel);
  }
}
