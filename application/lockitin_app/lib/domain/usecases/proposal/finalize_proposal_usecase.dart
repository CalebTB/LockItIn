import '../../repositories/proposal_repository.dart';

/// Use case for finalizing (confirming) a proposal with a winning time option
///
/// Encapsulates the business logic for proposal confirmation:
/// - Validates that user is the proposal creator
/// - Validates that proposal is still in voting status
/// - Creates the confirmed event
/// - Updates proposal status
class FinalizeProposalUseCase {
  final IProposalRepository _repository;

  FinalizeProposalUseCase(this._repository);

  /// Execute the use case to confirm a proposal
  ///
  /// [proposalId] - The proposal to confirm
  /// [timeOptionId] - The winning time option
  ///
  /// Returns the ID of the created event
  ///
  /// Throws [FinalizeProposalException] if validation fails
  Future<String> confirm({
    required String proposalId,
    required String timeOptionId,
  }) async {
    // Validate inputs
    if (proposalId.isEmpty) {
      throw FinalizeProposalException('Proposal ID cannot be empty');
    }
    if (timeOptionId.isEmpty) {
      throw FinalizeProposalException('Time option ID cannot be empty');
    }

    // Confirm the proposal (RLS validates creator and status)
    return await _repository.confirmProposal(
      proposalId: proposalId,
      timeOptionId: timeOptionId,
    );
  }

  /// Execute the use case to cancel a proposal
  ///
  /// [proposalId] - The proposal to cancel
  ///
  /// Throws [FinalizeProposalException] if validation fails
  Future<void> cancel(String proposalId) async {
    if (proposalId.isEmpty) {
      throw FinalizeProposalException('Proposal ID cannot be empty');
    }

    await _repository.cancelProposal(proposalId);
  }
}

/// Exception thrown when proposal finalization fails
class FinalizeProposalException implements Exception {
  final String message;
  FinalizeProposalException(this.message);

  @override
  String toString() => 'FinalizeProposalException: $message';
}
