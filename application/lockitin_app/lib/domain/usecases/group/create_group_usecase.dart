import '../../../data/models/group_model.dart';
import '../../repositories/group_repository.dart';

/// Use case for creating a new group
///
/// Encapsulates the business logic for group creation:
/// - Validates group name
/// - Validates emoji
/// - Creates group and adds creator as owner
class CreateGroupUseCase {
  final IGroupRepository _repository;

  CreateGroupUseCase(this._repository);

  /// Execute the use case
  ///
  /// [name] - The group name (1-100 characters)
  /// [emoji] - The group emoji (single emoji character)
  ///
  /// Returns the created GroupModel
  ///
  /// Throws [CreateGroupException] if validation fails
  Future<GroupModel> execute({
    required String name,
    required String emoji,
  }) async {
    // Validate inputs
    _validateName(name);
    _validateEmoji(emoji);

    // Create the group
    return await _repository.createGroup(
      name: name,
      emoji: emoji,
    );
  }

  void _validateName(String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw CreateGroupException('Group name cannot be empty');
    }
    if (trimmedName.length > 100) {
      throw CreateGroupException('Group name cannot exceed 100 characters');
    }
    if (trimmedName.length < 2) {
      throw CreateGroupException('Group name must be at least 2 characters');
    }
  }

  void _validateEmoji(String emoji) {
    if (emoji.isEmpty) {
      throw CreateGroupException('Emoji is required');
    }
    // Basic emoji validation - check if it contains common emoji ranges
    final emojiRegex = RegExp(
      r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F600}-\u{1F64F}]',
      unicode: true,
    );
    if (!emojiRegex.hasMatch(emoji)) {
      throw CreateGroupException('Please select a valid emoji');
    }
  }
}

/// Exception thrown when group creation fails
class CreateGroupException implements Exception {
  final String message;
  CreateGroupException(this.message);

  @override
  String toString() => 'CreateGroupException: $message';
}
