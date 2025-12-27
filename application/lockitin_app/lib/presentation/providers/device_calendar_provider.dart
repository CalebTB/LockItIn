import 'package:flutter/foundation.dart';
import '../../core/services/calendar_manager.dart';
import '../../core/services/event_service.dart';
import '../../core/utils/logger.dart';
import '../../data/models/event_model.dart';

/// Provider for managing device calendar events via platform channels
/// Handles permission requests, event fetching, and calendar sync
class DeviceCalendarProvider extends ChangeNotifier {
  final CalendarManager _calendarManager = CalendarManager();
  final EventService _eventService = EventService();

  List<EventModel> _events = [];
  CalendarPermissionStatus _permissionStatus =
      CalendarPermissionStatus.notDetermined;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<EventModel> get events => _events;
  CalendarPermissionStatus get permissionStatus => _permissionStatus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasPermission =>
      _permissionStatus == CalendarPermissionStatus.granted;

  /// Check current calendar permission status
  Future<void> checkPermission() async {
    try {
      _permissionStatus = await _calendarManager.checkPermission();
      Logger.info('Calendar permission status: $_permissionStatus');

      // If platform channel isn't implemented, show a helpful message
      if (_permissionStatus == CalendarPermissionStatus.notDetermined) {
        _errorMessage = 'Native calendar integration coming soon! Use test events for now.';
      }

      notifyListeners();
    } catch (e) {
      Logger.error('Failed to check calendar permission: $e');
      _errorMessage = 'Failed to check calendar permission';
      notifyListeners();
    }
  }

  /// Request calendar access permission
  /// Returns true if permission granted
  Future<bool> requestPermission() async {
    try {
      Logger.info('Requesting calendar permission');
      _errorMessage = null;
      notifyListeners();

      _permissionStatus = await _calendarManager.requestPermission();
      Logger.info('Permission result: $_permissionStatus');

      notifyListeners();
      return hasPermission;
    } catch (e) {
      Logger.error('Failed to request calendar permission: $e');
      _errorMessage = 'Failed to request calendar permission: $e';
      notifyListeners();
      return false;
    }
  }

  /// Fetch events from device calendar within date range
  ///
  /// [startDate] - Start of date range
  /// [endDate] - End of date range
  /// [forceRefresh] - Force refresh even if already loaded
  Future<void> fetchEvents({
    required DateTime startDate,
    required DateTime endDate,
    bool forceRefresh = false,
  }) async {
    // Don't fetch if already loading or no permission
    if (_isLoading && !forceRefresh) return;

    if (!hasPermission) {
      Logger.warning('Cannot fetch events - permission not granted');
      _errorMessage = 'Calendar permission not granted';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      Logger.info(
        'Fetching events from ${startDate.toIso8601String()} to ${endDate.toIso8601String()}',
      );

      final allEvents = <EventModel>[];

      // Fetch from Supabase (user-specific, RLS-protected)
      final supabaseEvents = await _eventService.fetchEventsFromSupabase(
        startDate: startDate,
        endDate: endDate,
      );
      allEvents.addAll(supabaseEvents);
      Logger.info('Fetched ${supabaseEvents.length} events from Supabase');

      // Track native calendar IDs to avoid duplicates
      final nativeCalendarIds = supabaseEvents
          .where((e) => e.nativeCalendarId != null)
          .map((e) => e.nativeCalendarId!)
          .toSet();

      // Fetch from native calendar
      final nativeEvents = await _calendarManager.fetchEvents(
        startDate: startDate,
        endDate: endDate,
      );

      // Filter out duplicates
      final newNativeEvents = nativeEvents.where((event) {
        return event.nativeCalendarId == null ||
            !nativeCalendarIds.contains(event.nativeCalendarId);
      }).toList();

      allEvents.addAll(newNativeEvents);

      Logger.info('Fetched ${nativeEvents.length} events from native calendar');
      Logger.info('Total events after deduplication: ${allEvents.length}');

      _events = allEvents;
    } catch (e) {
      Logger.error('Failed to fetch events: $e');

      if (e is CalendarAccessException) {
        _errorMessage = e.message;

        // Update permission status if access was denied
        if (e.message.contains('permission denied')) {
          _permissionStatus = CalendarPermissionStatus.denied;
        }
      } else {
        _errorMessage = 'Failed to fetch events: $e';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new event in device calendar
  ///
  /// Returns native calendar event ID for bidirectional sync
  Future<String?> createEvent(EventModel event) async {
    if (!hasPermission) {
      Logger.warning('Cannot create event - permission not granted');
      _errorMessage = 'Calendar permission not granted';
      notifyListeners();
      return null;
    }

    try {
      Logger.info('Creating event in device calendar: ${event.title}');
      final nativeEventId = await _calendarManager.createEvent(event);
      Logger.info('Created event with native ID: $nativeEventId');

      // Optionally refresh events list
      // await fetchEvents(startDate: ..., endDate: ...);

      return nativeEventId;
    } catch (e) {
      Logger.error('Failed to create event: $e');
      _errorMessage = 'Failed to create event: $e';
      notifyListeners();
      return null;
    }
  }

  /// Update an existing event in device calendar
  Future<bool> updateEvent(EventModel event) async {
    if (!hasPermission) {
      Logger.warning('Cannot update event - permission not granted');
      _errorMessage = 'Calendar permission not granted';
      notifyListeners();
      return false;
    }

    if (event.nativeCalendarId == null) {
      Logger.warning('Cannot update event - missing nativeCalendarId');
      _errorMessage = 'Event not linked to device calendar';
      notifyListeners();
      return false;
    }

    try {
      Logger.info('Updating event in device calendar: ${event.nativeCalendarId}');
      await _calendarManager.updateEvent(event);
      Logger.info('Updated event successfully');

      // Update local event list
      final index = _events.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        _events[index] = event;
        notifyListeners();
      }

      return true;
    } catch (e) {
      Logger.error('Failed to update event: $e');
      _errorMessage = 'Failed to update event: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete an event from device calendar
  Future<bool> deleteEvent(EventModel event) async {
    if (!hasPermission) {
      Logger.warning('Cannot delete event - permission not granted');
      _errorMessage = 'Calendar permission not granted';
      notifyListeners();
      return false;
    }

    if (event.nativeCalendarId == null) {
      Logger.warning('Cannot delete event - missing nativeCalendarId');
      _errorMessage = 'Event not linked to device calendar';
      notifyListeners();
      return false;
    }

    try {
      Logger.info('Deleting event from device calendar: ${event.nativeCalendarId}');
      await _calendarManager.deleteEvent(event.nativeCalendarId!);
      Logger.info('Deleted event successfully');

      // Remove from local event list
      _events.removeWhere((e) => e.id == event.id);
      notifyListeners();

      return true;
    } catch (e) {
      Logger.error('Failed to delete event: $e');
      _errorMessage = 'Failed to delete event: $e';
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get permission status display text
  String get permissionStatusText {
    switch (_permissionStatus) {
      case CalendarPermissionStatus.granted:
        return 'Calendar access granted';
      case CalendarPermissionStatus.denied:
        return 'Calendar access denied';
      case CalendarPermissionStatus.restricted:
        return 'Calendar access restricted';
      case CalendarPermissionStatus.notDetermined:
        return 'Calendar permission not determined';
    }
  }
}
