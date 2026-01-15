import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

/// Service for managing RSVP invitations
///
/// Centralizes all Supabase queries for event invitations to replace
/// direct Supabase calls in:
/// - surprise_party_dashboard_screen.dart
/// - event_detail_screen.dart
/// - rsvp_response_sheet.dart
class RSVPService {
  static const _tag = 'RSVPService';
  static final RSVPService _instance = RSVPService._internal();
  static RSVPService get instance => _instance;
  RSVPService._internal();

  final _supabase = Supabase.instance.client;

  /// Get all invitations for an event with user details
  Future<List<Map<String, dynamic>>> getEventInvitations(String eventId) async {
    try {
      Logger.info(_tag, 'Fetching invitations for event: $eventId');

      final response = await _supabase
          .from('event_invitations')
          .select('*, users:user_id(id, full_name, avatar_url)')
          .eq('event_id', eventId);

      Logger.info(_tag, 'Fetched ${(response as List).length} invitations');
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      Logger.error(_tag, 'Failed to fetch event invitations: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Get the current user's RSVP status for an event
  Future<String?> getUserRsvpStatus(String eventId, String userId) async {
    try {
      Logger.info(_tag, 'Fetching RSVP status for user $userId on event $eventId');

      final response = await _supabase
          .from('event_invitations')
          .select('rsvp_status')
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        Logger.info(_tag, 'No invitation found for user');
        return null;
      }

      final status = response['rsvp_status'] as String?;
      Logger.info(_tag, 'User RSVP status: $status');
      return status;
    } catch (e, stackTrace) {
      Logger.error(_tag, 'Failed to fetch user RSVP status: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Update a user's RSVP status
  Future<void> updateRsvpStatus(
    String eventId,
    String userId,
    String status,
  ) async {
    try {
      Logger.info(_tag, 'Updating RSVP status for user $userId on event $eventId to: $status');

      await _supabase.from('event_invitations').update({
        'rsvp_status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).match({
        'event_id': eventId,
        'user_id': userId,
      });

      Logger.info(_tag, 'RSVP status updated successfully');
    } catch (e, stackTrace) {
      Logger.error(_tag, 'Failed to update RSVP status: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Watch invitations for an event with real-time updates
  Stream<List<Map<String, dynamic>>> watchEventInvitations(String eventId) {
    Logger.info(_tag, 'Setting up real-time watch for event invitations: $eventId');

    return _supabase
        .from('event_invitations')
        .stream(primaryKey: ['id'])
        .eq('event_id', eventId)
        .map((data) {
          Logger.info(_tag, 'Real-time update received: ${data.length} invitations');
          return List<Map<String, dynamic>>.from(data);
        });
  }
}
