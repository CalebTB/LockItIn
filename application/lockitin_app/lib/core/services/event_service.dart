import '../../data/models/event_model.dart';
import '../../data/models/shadow_calendar_entry.dart';
import '../network/supabase_client.dart';
import '../utils/logger.dart';
import 'calendar_manager.dart';

/// Exception thrown when event operations fail
class EventServiceException implements Exception {
  final String message;
  final String? nativeEventId;
  final String? supabaseEventId;

  EventServiceException(
    this.message, {
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
      Logger.info('Creating event: ${event.title}');

      // Step 1: Create in native calendar first
      try {
        nativeEventId = await _calendarManager.createEvent(event);
        Logger.info('Created event in native calendar: $nativeEventId');
      } catch (e) {
        Logger.error('Failed to create event in native calendar: $e');
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

        final response = await SupabaseClientManager.client
            .from('events')
            .insert(eventWithNativeId.toJson())
            .select()
            .single();

        supabaseEventId = response['id'] as String;
        Logger.info('Created event in Supabase: $supabaseEventId');

        // Return the complete event with both IDs
        return eventWithNativeId.copyWith(id: supabaseEventId);
      } catch (e) {
        Logger.error('Failed to create event in Supabase: $e');

        // Rollback: Delete from native calendar
        // nativeEventId is guaranteed to be non-null here since Step 1 succeeded
        try {
          await _calendarManager.deleteEvent(nativeEventId);
          Logger.info('Rolled back native calendar event: $nativeEventId');
        } catch (rollbackError) {
          Logger.error('Failed to rollback native calendar event: $rollbackError');
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
      Logger.error('Unexpected error creating event: $e');
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
      Logger.info('Updating event: ${event.id}');

      bool nativeUpdateFailed = false;

      // Try to update in native calendar if we have the ID
      if (event.nativeCalendarId != null) {
        try {
          await _calendarManager.updateEvent(event);
          Logger.info('Updated event in native calendar');
        } catch (e) {
          // Native calendar update failed - event might have been deleted externally
          // Continue with Supabase update
          Logger.warning('Native calendar update failed (event may not exist): $e');
          nativeUpdateFailed = true;
        }
      }

      // Update in Supabase (always attempt this)
      try {
        await SupabaseClientManager.client
            .from('events')
            .update(event.toJson())
            .eq('id', event.id);

        Logger.info('Updated event in Supabase');
      } catch (e) {
        Logger.error('Failed to update event in Supabase: $e');
        throw EventServiceException(
          'Failed to sync event changes to cloud: $e',
        );
      }

      // If native update failed but Supabase succeeded, warn but don't fail
      if (nativeUpdateFailed) {
        Logger.warning(
          'Event updated in Supabase but native calendar sync failed. '
          'The event may have been modified or deleted in Apple Calendar.',
        );
      }

      return event;
    } catch (e) {
      if (e is EventServiceException) rethrow;
      Logger.error('Failed to update event: $e');
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
      Logger.info('Deleting event: ${event.id}');

      // Delete from native calendar
      if (event.nativeCalendarId != null) {
        try {
          await _calendarManager.deleteEvent(event.nativeCalendarId!);
          Logger.info('Deleted event from native calendar');
        } catch (e) {
          Logger.error('Failed to delete from native calendar: $e');
          errors.add('Failed to delete from device calendar');
        }
      }

      // Delete from Supabase
      try {
        await SupabaseClientManager.client
            .from('events')
            .delete()
            .eq('id', event.id);

        Logger.info('Deleted event from Supabase');
      } catch (e) {
        Logger.error('Failed to delete from Supabase: $e');
        errors.add('Failed to delete from cloud');
      }

      if (errors.isNotEmpty) {
        throw EventServiceException(
          'Partial delete failure: ${errors.join(', ')}',
        );
      }
    } catch (e) {
      if (e is EventServiceException) {
        rethrow;
      }
      Logger.error('Unexpected error deleting event: $e');
      throw EventServiceException('Failed to delete event: $e');
    }
  }

  /// Fetch events from Supabase for a date range
  ///
  /// This complements native calendar events with cloud-synced events
  Future<List<EventModel>> fetchEventsFromSupabase({
    required DateTime startDate,
    required DateTime endDate,
    String? userId,
  }) async {
    try {
      final targetUserId = userId ?? SupabaseClientManager.currentUserId;

      if (targetUserId == null) {
        Logger.warning('No user ID available, skipping Supabase event fetch');
        return [];
      }

      Logger.info(
        'Fetching events from Supabase: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}',
      );

      final response = await SupabaseClientManager.client
          .from('events')
          .select()
          .eq('user_id', targetUserId)
          .gte('start_time', startDate.toIso8601String())
          .lte('start_time', endDate.toIso8601String());

      final events = (response as List)
          .map((json) => EventModel.fromJson(json as Map<String, dynamic>))
          .toList();

      Logger.info('Fetched ${events.length} events from Supabase');
      return events;
    } catch (e) {
      Logger.error('Failed to fetch events from Supabase: $e');
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
          .lt('start_time', endDate.toIso8601String()) // Event starts before end of range
          .gt('end_time', startDate.toIso8601String()); // Event ends after start of range

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
      Logger.info('Fetched $totalEvents total events for group members');

      return eventsByUser;
    } catch (e) {
      Logger.error('Failed to fetch group members events: $e');
      // Return empty map to allow app to continue
      return {};
    }
  }

  /// Fetch shadow calendar entries for group members
  ///
  /// Uses the optimized get_group_shadow_calendar RPC function
  /// which enforces privacy at the database level.
  ///
  /// Returns a map of userId to list of shadow calendar entries
  Future<Map<String, List<ShadowCalendarEntry>>> fetchGroupShadowCalendar({
    required List<String> memberUserIds,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      Logger.info(
        'Fetching shadow calendar for ${memberUserIds.length} members: '
        '${startDate.toIso8601String()} to ${endDate.toIso8601String()}',
      );

      // Call the RPC function
      final response = await SupabaseClientManager.client.rpc(
        'get_group_shadow_calendar',
        params: {
          'p_user_ids': memberUserIds,
          'p_start_date': startDate.toIso8601String(),
          'p_end_date': endDate.toIso8601String(),
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
      Logger.info('Fetched $totalEntries shadow calendar entries for group');

      return entriesByUser;
    } catch (e) {
      Logger.error('Failed to fetch shadow calendar: $e');
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
          createdAt: DateTime.now(),
        );
      }).toList();
    }

    return result;
  }
}
