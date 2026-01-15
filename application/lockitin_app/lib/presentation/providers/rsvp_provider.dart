import 'package:flutter/foundation.dart';
import '../../core/services/rsvp_service.dart';
import '../../core/utils/logger.dart';

/// Provider for RSVP system state management
///
/// Manages event invitation state following the same Provider/Service pattern
/// used by CalendarProvider, GroupProvider, etc.
///
/// Replaces direct Supabase calls in:
/// - surprise_party_dashboard_screen.dart
/// - event_detail_screen.dart
/// - rsvp_response_sheet.dart
class RSVPProvider extends ChangeNotifier {
  static const _tag = 'RSVPProvider';
  final RSVPService _rsvpService = RSVPService.instance;

  /// Invitations by event ID
  final Map<String, List<Map<String, dynamic>>> _invitationsByEvent = {};

  /// Current user's RSVP statuses by event ID
  final Map<String, String?> _userRsvpStatuses = {};

  /// Loading states by event ID
  final Map<String, bool> _loadingStates = {};

  /// Error messages by event ID
  final Map<String, String?> _errorMessages = {};

  // ============================================================================
  // Getters
  // ============================================================================

  /// Get invitations for a specific event
  List<Map<String, dynamic>> getInvitations(String eventId) {
    return _invitationsByEvent[eventId] ?? [];
  }

  /// Get current user's RSVP status for an event
  String? getUserRsvpStatus(String eventId) {
    return _userRsvpStatuses[eventId];
  }

  /// Check if invitations are loading for an event
  bool isLoading(String eventId) {
    return _loadingStates[eventId] ?? false;
  }

  /// Get error message for an event
  String? getError(String eventId) {
    return _errorMessages[eventId];
  }

  /// Get RSVP statistics for an event
  Map<String, int> getStats(String eventId) {
    final invitations = getInvitations(eventId);

    return {
      'going': invitations.where((i) => i['rsvp_status'] == 'accepted').length,
      'maybe': invitations.where((i) => i['rsvp_status'] == 'maybe').length,
      'declined': invitations.where((i) => i['rsvp_status'] == 'declined').length,
      'pending': invitations.where((i) => i['rsvp_status'] == 'pending').length,
      'total': invitations.length,
    };
  }

  // ============================================================================
  // Methods
  // ============================================================================

  /// Load invitations for an event
  Future<void> loadEventInvitations(String eventId) async {
    try {
      Logger.info(_tag, 'Loading invitations for event: $eventId');

      _loadingStates[eventId] = true;
      _errorMessages[eventId] = null;
      notifyListeners();

      final invitations = await _rsvpService.getEventInvitations(eventId);

      _invitationsByEvent[eventId] = invitations;
      _loadingStates[eventId] = false;
      notifyListeners();

      Logger.info(_tag, 'Loaded ${invitations.length} invitations');
    } catch (e, stackTrace) {
      Logger.error(_tag, 'Failed to load invitations: $e', e, stackTrace);

      _loadingStates[eventId] = false;
      _errorMessages[eventId] = 'Failed to load RSVP data: $e';
      notifyListeners();
    }
  }

  /// Load current user's RSVP status for an event
  Future<void> loadUserRsvpStatus(String eventId, String userId) async {
    try {
      Logger.info(_tag, 'Loading user RSVP status for event: $eventId');

      final status = await _rsvpService.getUserRsvpStatus(eventId, userId);

      _userRsvpStatuses[eventId] = status;
      notifyListeners();

      Logger.info(_tag, 'Loaded user RSVP status: $status');
    } catch (e, stackTrace) {
      Logger.error(_tag, 'Failed to load user RSVP status: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Update RSVP status
  Future<void> updateRsvpStatus(
    String eventId,
    String userId,
    String status,
  ) async {
    try {
      Logger.info(_tag, 'Updating RSVP status to: $status');

      await _rsvpService.updateRsvpStatus(eventId, userId, status);

      // Update local cache
      _userRsvpStatuses[eventId] = status;

      // Reload invitations to reflect changes
      await loadEventInvitations(eventId);

      Logger.info(_tag, 'RSVP status updated successfully');
    } catch (e, stackTrace) {
      Logger.error(_tag, 'Failed to update RSVP status: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Clear cached data for an event
  void clearEventCache(String eventId) {
    _invitationsByEvent.remove(eventId);
    _userRsvpStatuses.remove(eventId);
    _loadingStates.remove(eventId);
    _errorMessages.remove(eventId);
    notifyListeners();
  }

  /// Clear all cached data
  void clearAll() {
    _invitationsByEvent.clear();
    _userRsvpStatuses.clear();
    _loadingStates.clear();
    _errorMessages.clear();
    notifyListeners();
  }
}
