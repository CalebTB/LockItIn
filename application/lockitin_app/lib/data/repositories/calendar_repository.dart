import '../../data/models/event_model.dart';
import '../../data/models/shadow_calendar_entry.dart';

/// Abstract repository for calendar data access
///
/// Provides a clean interface for fetching calendar events and group availability.
/// Implementations handle data sources (Supabase, local cache, etc.) and caching strategies.
abstract class CalendarRepository {
  /// Fetch personal calendar events for a date range
  ///
  /// Returns all events (private, busyOnly, sharedWithName) for the authenticated user.
  /// Used by personal calendar view and day detail screens.
  ///
  /// [startDate] - Start of date range (UTC)
  /// [endDate] - End of date range (UTC)
  ///
  /// Throws:
  /// - [PostgrestException] on database errors
  /// - [SocketException] on network errors
  Future<List<EventModel>> getPersonalEvents({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Fetch group availability (shadow calendar entries) for a date range
  ///
  /// Returns shadow calendar entries for all group members, respecting privacy:
  /// - Events from the same group show full details (title visible)
  /// - Events from other groups show as busy blocks (title NULL)
  /// - Private events are excluded (never in shadow_calendar table)
  ///
  /// Used by group calendar heatmap and availability views.
  ///
  /// [groupId] - Group to fetch availability for
  /// [startDate] - Start of date range (UTC)
  /// [endDate] - End of date range (UTC)
  ///
  /// Throws:
  /// - [PostgrestException] on database errors (including access denied)
  /// - [SocketException] on network errors
  Future<List<ShadowCalendarEntry>> getGroupAvailability({
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Watch personal events for realtime updates
  ///
  /// Returns a stream of event lists that updates when events change.
  /// Implements realtime subscription to events table filtered by user_id.
  ///
  /// [startDate] - Start of date range (UTC)
  /// [endDate] - End of date range (UTC)
  ///
  /// Stream emits:
  /// - Initial data immediately
  /// - Updated data on INSERT/UPDATE/DELETE events
  /// - Error events on subscription failures
  ///
  /// Caller must call [disposeWatchers] to clean up subscription.
  Stream<List<EventModel>> watchPersonalEvents({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Dispose all active watchers and subscriptions
  ///
  /// Call this when the repository is no longer needed to prevent memory leaks.
  /// Unsubscribes from all realtime channels.
  void disposeWatchers();
}
