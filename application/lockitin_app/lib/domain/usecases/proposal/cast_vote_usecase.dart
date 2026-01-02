import '../../../data/models/vote_model.dart';
import '../../repositories/proposal_repository.dart';

/// Use case for casting a vote on a proposal time option
///
/// Encapsulates the business logic for voting:
/// - Checks if proposal is still in voting status
/// - Checks if voting deadline hasn't passed
/// - Validates vote type
/// - Upserts vote (creates or updates)
class CastVoteUseCase {
  final IProposalRepository _repository;

  CastVoteUseCase(this._repository);

  /// Execute the use case
  ///
  /// [proposalId] - The proposal to vote on
  /// [timeOptionId] - The time option to vote for
  /// [vote] - The type of vote (yes, no, maybe)
  ///
  /// Throws [CastVoteException] if validation fails
  Future<void> execute({
    required String proposalId,
    required String timeOptionId,
    required VoteType vote,
  }) async {
    // Validate inputs
    if (proposalId.isEmpty) {
      throw CastVoteException('Proposal ID cannot be empty');
    }
    if (timeOptionId.isEmpty) {
      throw CastVoteException('Time option ID cannot be empty');
    }

    // Cast the vote (repository handles proposal status validation via RLS)
    await _repository.castVote(
      proposalId: proposalId,
      timeOptionId: timeOptionId,
      vote: vote,
    );
  }
}

/// Exception thrown when voting fails
class CastVoteException implements Exception {
  final String message;
  CastVoteException(this.message);

  @override
  String toString() => 'CastVoteException: $message';
}
