import '../../../data/models/proposal_time_option.dart';
import '../../repositories/proposal_repository.dart';

/// Use case for creating a new event proposal
///
/// Encapsulates the business logic for proposal creation:
/// - Validates time options (min 2, max 5)
/// - Validates voting deadline (must be in the future)
/// - Creates proposal with options in a single transaction
class CreateProposalUseCase {
  final IProposalRepository _repository;

  CreateProposalUseCase(this._repository);

  /// Execute the use case
  ///
  /// Throws [CreateProposalException] if validation fails
  Future<String> execute({
    required String groupId,
    required String title,
    String? description,
    String? location,
    required DateTime votingDeadline,
    required List<ProposalTimeOption> timeOptions,
  }) async {
    // Validate inputs
    _validateTitle(title);
    _validateTimeOptions(timeOptions);
    _validateVotingDeadline(votingDeadline);

    // Create proposal
    return await _repository.createProposal(
      groupId: groupId,
      title: title,
      description: description,
      location: location,
      votingDeadline: votingDeadline,
      timeOptions: timeOptions,
    );
  }

  void _validateTitle(String title) {
    if (title.trim().isEmpty) {
      throw CreateProposalException('Title cannot be empty');
    }
    if (title.length > 255) {
      throw CreateProposalException('Title cannot exceed 255 characters');
    }
  }

  void _validateTimeOptions(List<ProposalTimeOption> timeOptions) {
    if (timeOptions.length < 2) {
      throw CreateProposalException('At least 2 time options are required');
    }
    if (timeOptions.length > 5) {
      throw CreateProposalException('Maximum 5 time options allowed');
    }

    // Validate each time option
    for (final option in timeOptions) {
      if (option.endTime.isBefore(option.startTime)) {
        throw CreateProposalException('End time must be after start time');
      }
      if (option.startTime.isBefore(DateTime.now())) {
        throw CreateProposalException('Time options must be in the future');
      }
    }
  }

  void _validateVotingDeadline(DateTime votingDeadline) {
    if (votingDeadline.isBefore(DateTime.now())) {
      throw CreateProposalException('Voting deadline must be in the future');
    }
    if (votingDeadline.isAfter(DateTime.now().add(const Duration(days: 30)))) {
      throw CreateProposalException('Voting deadline cannot exceed 30 days');
    }
  }
}

/// Exception thrown when proposal creation fails
class CreateProposalException implements Exception {
  final String message;
  CreateProposalException(this.message);

  @override
  String toString() => 'CreateProposalException: $message';
}
