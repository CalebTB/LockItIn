import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/event_model.dart';
import '../../data/models/shadow_calendar_entry.dart';
import '../network/supabase_client.dart';
import '../utils/logger.dart';
import '../utils/timezone_utils.dart';
import 'calendar_manager.dart';

/// Exception thrown when event operations fail
class EventServiceException implements Exception {
  final String message;
  final String? code;
  final String? nativeEventId;
  final String? supabaseEventId;

  EventServiceException(
    this.message, {
    this.code,
    this.nativeEventId,
    this.supabaseEventId,
  });

  @override
  String toString() => 'EventServiceException: $message';
}

/// Service for managing events with dual-write to native calendar and Supabase
/// Handles synchronization between Apple Calendar/Google Calendar and Supabase database
///
/// Uses singleton pattern - access via [EventService.instance] or constructor
class EventService {
  // Singleton instance
  static final EventService _instance = EventService._internal();

  /// Access the singleton instance
  static EventService get instance => _instance;

  /// Factory constructor returns singleton
  factory EventService() => _instance;

  /// Private internal constructor
  EventService._internal();

  final CalendarManager _calendarManager = CalendarManager();

  /// Create event in both native calendar and Supabase
  ///
  /// This performs a dual-write operation:
  /// 1. Save to native calendar (Apple Calendar on iOS, Google Calendar on Android)
  /// 2. Save to Supabase with the native calendar ID for bidirectional sync
  ///
  /// If either operation fails, attempts to clean up the successful write
  ///
  /// Returns the EventModel with updated IDs (native and Supabase)
  Future<EventModel> createEvent(EventModel event) async {
    String? nativeEventId;
    String? supabaseEventId;

    try {
      Logger.info('EventService', 'Creating event: ${event.title}');

      // Step 1: Create in native calendar first
      try {
        nativeEventId = await _calendarManager.createEvent(event);
        Logger.info('EventService', 'Created event in native calendar: $nativeEventId');
      } catch (e) {
        Logger.error('EventService', 'Failed to create event in native calendar', e);
        throw EventServiceException(
          'Failed to save event to your device calendar. Please check calendar permissions.',
        );
      }

      // Step 2: Create in Supabase with native calendar ID
      try {
        final eventWithNativeId = event.copyWith(
          nativeCalendarId: nativeEventId,
          userId: SupabaseClientManager.currentUserId ?? 'anonymous',
        );

        // Log what we're sending to Supabase
        final jsonToSend = eventWithNativeId.toJson();
        Logger.info('EventService', 'Sending to Supabase:');
        Logger.info('EventService', '  - visibility: ${jsonToSend['visibility']}');
        Logger.info('EventService', '  - title: ${jsonToSend['title']}');

        final response = await SupabaseClientManager.client
            .from('events')
            .insert(jsonToSend)
            .select()
            .single();

        // Log what we got back from Supabase
        Logger.info('EventService', 'Received from Supabase:');
        Logger.info('EventService', '  - id: ${response['id']}');
        Logger.info('EventService', '  - visibility: ${response['visibility']}');
        Logger.info('EventService', '  - title: ${response['title']}');

        supabaseEventId = response['id'] as String?;
        if (supabaseEventId == null) {
          throw EventServiceException('Supabase returned null event ID');
        }
        Logger.info('EventService', 'Created event in Supabase: $supabaseEventId');

        // Return the event from the database response (not our local copy)
        // This ensures we get the exact data that was saved
        return EventModel.fromJson(response);
      } on PostgrestException catch (e) {
        Logger.error('EventService', 'Failed to create event in Supabase', e);

        // Rollback: Delete from native calendar
        try {
          await _calendarManager.deleteEvent(nativeEventId);
          Logger.info('EventService', 'Rolled back native calendar event: $nativeEventId');
        } catch (rollbackError) {
          Logger.error('EventService', 'Failed to rollback native calendar event', rollbackError);
        }

        throw _handlePostgrestError(e, nativeEventId: nativeEventId);
      } catch (e) {
        Logger.error('EventService', 'Failed to create event in Supabase', e);

        // Rollback: Delete from native calendar
        try {
          await _calendarManager.deleteEvent(nativeEventId);
          Logger.info('EventService', 'Rolled back native calendar event: $nativeEventId');
        } catch (rollbackError) {
          Logger.error('EventService', 'Failed to rollback native calendar event', rollbackError);
        }

        throw EventServiceException(
          'Failed to sync event to cloud. The event was removed from your device calendar.',
          nativeEventId: nativeEventId,
        );
      }
    } catch (e) {
      if (e is EventServiceException) {
        rethrow;
      }
      Logger.error('EventService', 'Unexpected error creating event', e);
      throw EventServiceException(
        'An unexpected error occurred while creating the event.',
        nativeEventId: nativeEventId,
        supabaseEventId: supabaseEventId,
      );
    }
  }

  /// Update event in both native calendar and Supabase
  ///
  /// Performs dual-write update operation
  /// If native calendar update fails (e.g., event was deleted externally),
  /// we still update Supabase to keep data in sync
  Future<EventModel> updateEvent(EventModel event) async {
    try {
      Logger.info('EventService', 'Updating event: ${event.id}');

      bool nativeUpdateFailed = false;

      // Try to update in native calendar if we have the ID
      if (event.nativeCalendarId != null) {
        try {
          await _calendarManager.updateEvent(event);
          Logger.info('EventService', 'Updated event in native calendar');
        } catch (e) {
          // Native calendar update failed - event might have been deleted externally
          // Continue with Supabase update
          Logger.warning('EventService', 'Native calendar update failed (event may not exist): $e');
          nativeUpdateFailed = true;
        }
      }

      // Update in Supabase (always attempt this)
      try {
        await SupabaseClientManager.client
            .from('events')
            .update(event.toJson())
            .eq('id', event.id);

        Logger.info('EventService', 'Updated event in Supabase');
      } on PostgrestException catch (e) {
        throw _handlePostgrestError(e, supabaseEventId: event.id);
      } catch (e) {
        Logger.error('EventService', 'Failed to update event in Supabase', e);
        throw EventServiceException(
          'Failed to sync event changes to cloud: $e',
        );
      }

      // If native update failed but Supabase succeeded, warn but don't fail
      if (nativeUpdateFailed) {
        Logger.warning('EventService',
          'Event updated in Supabase but native calendar sync failed. '
          'The event may have been modified or deleted in Apple Calendar.');
      }

      return event;
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e, supabaseEventId: event.id);
    } catch (e) {
      if (e is EventServiceException) rethrow;
      Logger.error('EventService', 'Failed to update event', e);
      throw EventServiceException('Failed to update event: $e');
    }
  }

  /// Delete event from both native calendar and Supabase
  ///
  /// Performs dual-delete operation
  /// Attempts to delete from both sources even if one fails
  Future<void> deleteEvent(EventModel event) async {
    final errors = <String>[];

    try {
      Logger.info('EventService', 'Deleting event: ${event.id}');

      // Delete from native calendar
      if (event.nativeCalendarId != null) {
        try {
          await _calendarManager.deleteEvent(event.nativeCalendarId!);
          Logger.info('EventService', 'Deleted event from native calendar');
        } catch (e) {
          Logger.error('EventService', 'Failed to delete from native calendar', e);
          errors.add('Failed to delete from device calendar');
        }
      }

      // Delete from Supabase
      try {
        await SupabaseClientManager.client
            .from('events')
            .delete()
            .eq('id', event.id);

        Logger.info('EventService', 'Deleted event from Supabase');
      } on PostgrestException catch (e) {
        Logger.error('EventService', 'Failed to delete from Supabase: ${e.code} - ${e.message}');
        errors.add('Failed to delete from cloud: ${e.message}');
      } catch (e) {
        Logger.error('EventService', 'Failed to delete from Supabase: $e');
        errors.add('Failed to delete from cloud');
      }

      if (errors.isNotEmpty) {
        throw EventServiceException(
          'Partial delete failure: ${errors.join(', ')}',
        );
      }
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e, supabaseEventId: event.id);
    } catch (e) {
      if (e is EventServiceException) {
        rethrow;
      }
      Logger.error('EventService', 'Unexpected error deleting event: $e');
      throw EventServiceException('Failed to delete event: $e');
    }
  }

  /// Fetch events from Supabase for a date range
  ///
  /// Fetches events created by the user AND events they're invited to
  /// This ensures guest of honor can see surprise party events
  Future<List<EventModel>> fetchEventsFromSupabase({
    required DateTime startDate,
    required DateTime endDate,
    String? userId,
  }) async {
    try {
      final targetUserId = userId ?? SupabaseClientManager.currentUserId;

      if (targetUserId == null) {
        Logger.warning('EventService', 'No user ID available, skipping Supabase event fetch');
        return [];
      }

      Logger.info('EventService',
        'Fetching events from Supabase: ${TimezoneUtils.toUtcString(startDate)} to ${TimezoneUtils.toUtcString(endDate)}',
      );

      // Use RPC function to get both created and invited events
      final response = await SupabaseClientManager.client.rpc(
        'get_user_events',
        params: {
          'p_user_id': targetUserId,
          'p_start_date': TimezoneUtils.toUtcString(startDate),
          'p_end_date': TimezoneUtils.toUtcString(endDate),
        },
      );

      final events = (response as List)
          .map((json) => EventModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Apply decoy titles for surprise party guests of honor
      final processedEvents = _applyDecoyTitles(events, targetUserId);

      Logger.info('EventService', 'Fetched ${processedEvents.length} events from Supabase');
      return processedEvents;
    } on PostgrestException catch (e) {
      Logger.error('EventService', 'Failed to fetch events from Supabase: ${e.code} - ${e.message}');
      // Don't throw - return empty list to allow app to continue with native events
      return [];
    } catch (e) {
      Logger.error('EventService', 'Failed to fetch events from Supabase: $e');
      // Don't throw - return empty list to allow app to continue with native events
      return [];
    }
  }

  /// Fetch visible events for all group members in a date range
  ///
  /// Respects privacy settings:
  /// - 'private' events are excluded (not visible to group)
  /// - 'busyOnly' and 'sharedWithName' events are included (they block time)
  ///
  /// Returns a map of userId to list of events
  Future<Map<String, List<EventModel>>> fetchGroupMembersEvents({
    required List<String> memberUserIds,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Fetch events for all members that overlap with the date range
      // An event overlaps if: start_time < endDate AND end_time > startDate
      // Include all non-private events (shared_with_name or busy_only)
      final response = await SupabaseClientManager.client
          .from('events')
          .select()
          .inFilter('user_id', memberUserIds)
          .neq('visibility', 'private') // Exclude private events
          .lt('start_time', TimezoneUtils.toUtcString(endDate)) // Event starts before end of range
          .gt('end_time', TimezoneUtils.toUtcString(startDate)); // Event ends after start of range

      // Group events by user_id
      final Map<String, List<EventModel>> eventsByUser = {};

      // Initialize empty lists for all members
      for (final userId in memberUserIds) {
        eventsByUser[userId] = [];
      }

      // Parse and group events
      for (final json in response as List) {
        final event = EventModel.fromJson(json as Map<String, dynamic>);
        final userId = event.userId;
        if (eventsByUser.containsKey(userId)) {
          eventsByUser[userId]!.add(event);
        }
      }

      final totalEvents = eventsByUser.values.fold<int>(
        0,
        (sum, events) => sum + events.length,
      );
      Logger.info('EventService', 'Fetched $totalEvents total events for group members');

      return eventsByUser;
    } on PostgrestException catch (e) {
      Logger.error('EventService', 'Failed to fetch group members events: ${e.code} - ${e.message}');
      // Return empty map to allow app to continue
      return {};
    } catch (e) {
      Logger.error('EventService', 'Failed to fetch group members events: $e');
      // Return empty map to allow app to continue
      return {};
    }
  }

  /// Fetch shadow calendar entries for group members
  ///
  /// Uses the optimized get_group_shadow_calendar_v2 RPC function
  /// which enforces group-aware privacy at the database level.
  ///
  /// Events belonging to the requesting group show full details,
  /// while events from other groups show as "busy" blocks.
  ///
  /// Returns a map of userId to list of shadow calendar entries
  Future<Map<String, List<ShadowCalendarEntry>>> fetchGroupShadowCalendar({
    required String groupId,
    required List<String> memberUserIds,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      Logger.info('EventService',
        'Fetching shadow calendar for group $groupId with ${memberUserIds.length} members: '
        '${TimezoneUtils.toUtcString(startDate)} to ${TimezoneUtils.toUtcString(endDate)}',
      );

      // Call the RPC function with group context
      final response = await SupabaseClientManager.client.rpc(
        'get_group_shadow_calendar_v2',
        params: {
          'p_user_ids': memberUserIds,
          'p_requesting_group_id': groupId,
          'p_start_date': TimezoneUtils.toUtcString(startDate),
          'p_end_date': TimezoneUtils.toUtcString(endDate),
        },
      );

      // Group entries by user_id
      final Map<String, List<ShadowCalendarEntry>> entriesByUser = {};

      // Initialize empty lists for all members
      for (final userId in memberUserIds) {
        entriesByUser[userId] = [];
      }

      // Parse and group entries
      for (final json in response as List) {
        final entry = ShadowCalendarEntry.fromJson(json as Map<String, dynamic>);
        final userId = entry.userId;
        if (entriesByUser.containsKey(userId)) {
          entriesByUser[userId]!.add(entry);
        }
      }

      final totalEntries = entriesByUser.values.fold<int>(
        0,
        (sum, entries) => sum + entries.length,
      );
      Logger.info('EventService', 'Fetched $totalEntries shadow calendar entries for group');

      return entriesByUser;
    } on PostgrestException catch (e) {
      Logger.error('EventService', 'Failed to fetch shadow calendar: ${e.code} - ${e.message}');
      // Return empty map to allow app to continue
      return {};
    } catch (e) {
      Logger.error('EventService', 'Failed to fetch shadow calendar: $e');
      // Return empty map to allow app to continue
      return {};
    }
  }

  /// Convert shadow calendar entries to EventModel-like objects
  /// for compatibility with existing availability calculator
  ///
  /// This creates minimal EventModel objects with just the data needed
  /// for availability calculations (start/end times, category)
  ///
  /// IMPORTANT: Preserves all member entries (even empty ones) so the
  /// availability calculator knows how many members exist.
  Map<String, List<EventModel>> shadowToEventModels(
    Map<String, List<ShadowCalendarEntry>> shadowEntries,
  ) {
    final Map<String, List<EventModel>> result = {};

    for (final entry in shadowEntries.entries) {
      final userId = entry.key;
      final entries = entry.value;

      // Always create an entry for each member (even if empty list)
      // This ensures availability calculator counts all members
      result[userId] = entries.map((shadow) {
        return EventModel(
          id: '', // Not needed for availability calculation
          userId: shadow.userId,
          title: shadow.displayText,
          startTime: shadow.startTime,
          endTime: shadow.endTime,
          visibility: shadow.isBusyOnly
              ? EventVisibility.busyOnly
              : EventVisibility.sharedWithName,
          createdAt: TimezoneUtils.nowUtc(),
        );
      }).toList();
    }

    return result;
  }

  /// Convert PostgrestException to user-friendly EventServiceException
  EventServiceException _handlePostgrestError(
    PostgrestException e, {
    String? nativeEventId,
    String? supabaseEventId,
  }) {
    Logger.error('EventService', 'Supabase error: ${e.code} - ${e.message}');

    switch (e.code) {
      case '23505': // unique_violation
        return EventServiceException(
          'This event already exists',
          code: e.code,
          nativeEventId: nativeEventId,
          supabaseEventId: supabaseEventId,
        );
      case '23503': // foreign_key_violation
        return EventServiceException(
          'Referenced record not found',
          code: e.code,
          nativeEventId: nativeEventId,
          supabaseEventId: supabaseEventId,
        );
      case '42501': // insufficient_privilege (RLS)
        return EventServiceException(
          'Permission denied',
          code: e.code,
          nativeEventId: nativeEventId,
          supabaseEventId: supabaseEventId,
        );
      case 'PGRST116': // JWT expired
        return EventServiceException(
          'Session expired, please log in again',
          code: e.code,
          nativeEventId: nativeEventId,
          supabaseEventId: supabaseEventId,
        );
      case 'PGRST301': // Row not found
        return EventServiceException(
          'Event not found',
          code: e.code,
          nativeEventId: nativeEventId,
          supabaseEventId: supabaseEventId,
        );
      default:
        return EventServiceException(
          'Database error: ${e.message}',
          code: e.code,
          nativeEventId: nativeEventId,
          supabaseEventId: supabaseEventId,
        );
    }
  }

  /// Apply decoy titles to surprise party events for guests of honor
  ///
  /// If the current user is the guest of honor for a surprise party,
  /// replace the event title with the decoy title from template_data
  List<EventModel> _applyDecoyTitles(List<EventModel> events, String currentUserId) {
    return events.map((event) {
      Logger.info('EventService', '=== Processing event: ${event.title} ===');
      Logger.info('EventService', '  Has template: ${event.hasTemplate}');
      Logger.info('EventService', '  Template data: ${event.templateData}');
      Logger.info('EventService', '  Is surprise party: ${event.isSurpriseParty}');

      // Check if this is a surprise party with the current user as guest of honor
      if (event.isSurpriseParty) {
        final surpriseTemplate = event.surprisePartyTemplate;
        Logger.info('EventService', '  Surprise template: $surpriseTemplate');
        Logger.info('EventService', '  Guest of honor ID: ${surpriseTemplate?.guestOfHonorId}');
        Logger.info('EventService', '  Current user ID: $currentUserId');
        Logger.info('EventService', '  IDs match: ${surpriseTemplate?.guestOfHonorId == currentUserId}');

        if (surpriseTemplate?.guestOfHonorId == currentUserId) {
          // Replace title with decoy title
          final decoyTitle = surpriseTemplate!.decoyTitle ?? 'Event';
          Logger.info('EventService', '  ✅ Applying decoy title "$decoyTitle" for guest of honor');
          return event.copyWith(title: decoyTitle);
        } else {
          Logger.info('EventService', '  ❌ Not guest of honor, keeping real title');
        }
      }
      return event;
    }).toList();
  }
}
