import '../../data/models/event_model.dart';

/// Extension methods for EventModel to handle Surprise Party logic
///
/// Centralizes user role detection and title display logic to eliminate
/// code duplication across:
/// - event_detail_screen.dart
/// - agenda_event_card.dart
/// - upcoming_event_card.dart
extension SurprisePartyEventExtension on EventModel {
  /// Determine user's role in the surprise party
  ///
  /// Returns:
  /// - 'target': User is the guest of honor
  /// - 'coordinator': User is "in on it" (organizing the surprise)
  /// - 'member': User is a group member (not implemented here, check at call site)
  /// - 'neither': Not a surprise party or user not involved
  String getUserRole(String? currentUserId) {
    if (surprisePartyTemplate == null || currentUserId == null) {
      return 'neither';
    }

    final template = surprisePartyTemplate!;

    // Check if user is the target (guest of honor)
    if (template.guestOfHonorId == currentUserId) {
      return 'target';
    }

    // Check if user is a coordinator (in on it)
    if (template.isUserInOnIt(currentUserId)) {
      return 'coordinator';
    }

    return 'neither';
  }

  /// Get the appropriate title to display based on user role
  ///
  /// - Target sees decoy title if set, otherwise real title
  /// - Coordinators and others see real title
  String getDisplayTitle(String? currentUserId) {
    if (surprisePartyTemplate == null) {
      return title;
    }

    final role = getUserRole(currentUserId);
    final template = surprisePartyTemplate!;

    // Target sees decoy title if set, otherwise real title
    if (role == 'target' && template.decoyTitle != null) {
      return template.decoyTitle!;
    }

    // Coordinators and others see real title
    return title;
  }

  /// Check if this is a surprise party event
  bool get isSurpriseParty => surprisePartyTemplate != null;
}
