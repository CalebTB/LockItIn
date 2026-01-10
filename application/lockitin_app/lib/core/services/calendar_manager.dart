import 'dart:io';
import 'package:flutter/services.dart';
import '../../data/models/event_model.dart';
import '../utils/logger.dart';
import '../utils/timezone_utils.dart';

/// Exception thrown when calendar access is denied
class CalendarAccessException implements Exception {
  final String message;
  CalendarAccessException(this.message);

  @override
  String toString() => 'CalendarAccessException: $message';
}

/// Permission status for calendar access
enum CalendarPermissionStatus {
  granted,
  denied,
  restricted,
  notDetermined,
}

/// Service for accessing native device calendars via platform channels
/// iOS: EventKit integration
/// Android: CalendarContract integration
class CalendarManager {
  static const _tag = 'CalendarManager';
  static const MethodChannel _channel =
      MethodChannel('com.lockitin.calendar');

  /// Request calendar access permissions
  /// Returns true if permission granted, false otherwise
  Future<CalendarPermissionStatus> requestPermission() async {
    try {
      Logger.info(_tag, 'Requesting calendar permission');
      final String result = await _channel.invokeMethod('requestPermission');
      Logger.info(_tag, 'Calendar permission result: $result');

      return _parsePermissionStatus(result);
    } on MissingPluginException {
      Logger.warning(_tag, 'Platform channel not implemented - calendar integration not available');
      // Return denied when platform channel isn't implemented
      return CalendarPermissionStatus.denied;
    } on PlatformException catch (e) {
      Logger.error(_tag, 'Failed to request calendar permission: ${e.message}');
      throw CalendarAccessException(
        'Failed to request permission: ${e.message}',
      );
    }
  }

  /// Check current calendar permission status
  Future<CalendarPermissionStatus> checkPermission() async {
    try {
      final String result = await _channel.invokeMethod('checkPermission');
      return _parsePermissionStatus(result);
    } on MissingPluginException {
      Logger.warning(_tag, 'Platform channel not implemented - using test events mode');
      // Return notDetermined when platform channel isn't implemented
      return CalendarPermissionStatus.notDetermined;
    } on PlatformException catch (e) {
      Logger.error(_tag, 'Failed to check calendar permission: ${e.message}');
      throw CalendarAccessException(
        'Failed to check permission: ${e.message}',
      );
    }
  }

  /// Fetch events from native calendar within date range
  ///
  /// [startDate] - Start of date range to fetch events (UTC)
  /// [endDate] - End of date range to fetch events (UTC)
  ///
  /// Returns list of events from device calendar (Apple Calendar on iOS,
  /// Google Calendar/device calendar on Android)
  ///
  /// Native calendars work in local time, so we convert UTC → local
  /// before sending, and convert received timestamps local → UTC
  ///
  /// Throws [CalendarAccessException] if permission denied or fetch fails
  Future<List<EventModel>> fetchEvents({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Convert UTC timestamps to local for native calendar query
      final localStart = startDate.toLocal();
      final localEnd = endDate.toLocal();

      Logger.info(
        _tag,
        'Fetching events from ${localStart.toIso8601String()} to ${localEnd.toIso8601String()} (local time)',
      );

      final List<dynamic> result = await _channel.invokeMethod(
        'fetchEvents',
        {
          'startDate': localStart.millisecondsSinceEpoch,
          'endDate': localEnd.millisecondsSinceEpoch,
        },
      );

      Logger.info(_tag, 'Fetched ${result.length} events from native calendar');

      // Convert native events to EventModel
      return result.map((eventData) {
        return _parseNativeEvent(eventData as Map<dynamic, dynamic>);
      }).toList();
    } on MissingPluginException {
      Logger.warning(_tag, 'Platform channel not implemented - returning empty event list');
      return [];
    } on PlatformException catch (e) {
      Logger.error(_tag, 'Failed to fetch events: ${e.message}');

      if (e.code == 'PERMISSION_DENIED') {
        throw CalendarAccessException(
          'Calendar access permission denied. Please enable calendar access in Settings.',
        );
      }

      throw CalendarAccessException('Failed to fetch events: ${e.message}');
    }
  }

  /// Create an event in the native calendar
  ///
  /// [event] - EventModel to create in native calendar
  ///
  /// Native calendars work in local time, so we convert UTC → local
  /// Text fields are sanitized before sending to platform
  ///
  /// Returns native calendar event ID for bidirectional sync
  Future<String> createEvent(EventModel event) async {
    try {
      // Sanitize text fields
      final sanitizedTitle = _sanitizeText(event.title, maxLength: 200) ?? 'Untitled Event';
      final sanitizedDescription = _sanitizeText(event.description, maxLength: 1000);
      final sanitizedLocation = _sanitizeText(event.location, maxLength: 200);

      // Convert UTC timestamps to local for native calendar
      final localStart = event.startTime.toLocal();
      final localEnd = event.endTime.toLocal();

      Logger.info(_tag, 'Creating event in native calendar: $sanitizedTitle');

      final String nativeEventId = await _channel.invokeMethod(
        'createEvent',
        {
          'title': sanitizedTitle,
          'description': sanitizedDescription,
          'startTime': localStart.millisecondsSinceEpoch,
          'endTime': localEnd.millisecondsSinceEpoch,
          'location': sanitizedLocation,
        },
      );

      Logger.info(_tag, 'Created event with native ID: $nativeEventId');
      return nativeEventId;
    } on MissingPluginException {
      Logger.warning(_tag, 'Platform channel not implemented - skipping native calendar sync');
      // Return a placeholder ID when platform channel isn't available (simulator/emulator)
      return 'no_native_calendar_${DateTime.now().millisecondsSinceEpoch}';
    } on PlatformException catch (e) {
      Logger.error(_tag, 'Failed to create event: ${e.message}');
      throw CalendarAccessException('Failed to create event: ${e.message}');
    }
  }

  /// Update an event in the native calendar
  ///
  /// [event] - EventModel with updated data
  ///
  /// Native calendars work in local time, so we convert UTC → local
  /// Text fields are sanitized before sending to platform
  ///
  /// Requires event.nativeCalendarId to be set
  Future<void> updateEvent(EventModel event) async {
    if (event.nativeCalendarId == null) {
      throw CalendarAccessException(
        'Cannot update event without nativeCalendarId',
      );
    }

    try {
      // Sanitize text fields
      final sanitizedTitle = _sanitizeText(event.title, maxLength: 200) ?? 'Untitled Event';
      final sanitizedDescription = _sanitizeText(event.description, maxLength: 1000);
      final sanitizedLocation = _sanitizeText(event.location, maxLength: 200);

      // Convert UTC timestamps to local for native calendar
      final localStart = event.startTime.toLocal();
      final localEnd = event.endTime.toLocal();

      Logger.info(_tag, 'Updating native event: ${event.nativeCalendarId}');

      await _channel.invokeMethod(
        'updateEvent',
        {
          'nativeEventId': event.nativeCalendarId,
          'title': sanitizedTitle,
          'description': sanitizedDescription,
          'startTime': localStart.millisecondsSinceEpoch,
          'endTime': localEnd.millisecondsSinceEpoch,
          'location': sanitizedLocation,
        },
      );

      Logger.info(_tag, 'Updated native event successfully');
    } on MissingPluginException {
      Logger.warning(_tag, 'Platform channel not implemented - skipping native calendar sync');
      // Silently skip when platform channel isn't available (simulator/emulator)
    } on PlatformException catch (e) {
      Logger.error(_tag, 'Failed to update event: ${e.message}');
      throw CalendarAccessException('Failed to update event: ${e.message}');
    }
  }

  /// Delete an event from the native calendar
  ///
  /// [nativeEventId] - Native calendar event ID
  Future<void> deleteEvent(String nativeEventId) async {
    try {
      Logger.info(_tag, 'Deleting native event: $nativeEventId');

      await _channel.invokeMethod(
        'deleteEvent',
        {'nativeEventId': nativeEventId},
      );

      Logger.info(_tag, 'Deleted native event successfully');
    } on MissingPluginException {
      Logger.warning(_tag, 'Platform channel not implemented - skipping native calendar sync');
      // Silently skip when platform channel isn't available (simulator/emulator)
    } on PlatformException catch (e) {
      Logger.error(_tag, 'Failed to delete event: ${e.message}');
      throw CalendarAccessException('Failed to delete event: ${e.message}');
    }
  }

  /// Parse native calendar event data to EventModel
  ///
  /// Native calendars provide timestamps in local time, so we convert to UTC
  /// Text fields are sanitized for consistency
  EventModel _parseNativeEvent(Map<dynamic, dynamic> eventData) {
    // Generate a temporary ID for native events (will be replaced when synced to Supabase)
    final String tempId = 'native_${eventData['nativeEventId']}';

    // Parse timestamps as local time (from native calendar), then convert to UTC for storage
    final localStart = DateTime.fromMillisecondsSinceEpoch(
      eventData['startTime'] as int,
    );
    final localEnd = DateTime.fromMillisecondsSinceEpoch(
      eventData['endTime'] as int,
    );

    // Sanitize text fields from native calendar
    final sanitizedTitle = _sanitizeText(
      eventData['title'] as String?,
      maxLength: 200,
    ) ?? 'Untitled Event';
    final sanitizedDescription = _sanitizeText(
      eventData['description'] as String?,
      maxLength: 1000,
    );
    final sanitizedLocation = _sanitizeText(
      eventData['location'] as String?,
      maxLength: 200,
    );

    return EventModel(
      id: tempId,
      userId: 'temp_user', // Will be set to current user when syncing
      title: sanitizedTitle,
      description: sanitizedDescription,
      startTime: localStart.toUtc(), // Convert local → UTC for storage
      endTime: localEnd.toUtc(),     // Convert local → UTC for storage
      location: sanitizedLocation,
      visibility: EventVisibility.private, // Default to private for native events
      nativeCalendarId: eventData['nativeEventId'] as String,
      createdAt: TimezoneUtils.nowUtc(), // Use UTC timestamp
    );
  }

  /// Parse permission status string to enum
  CalendarPermissionStatus _parsePermissionStatus(String status) {
    switch (status.toLowerCase()) {
      case 'granted':
      case 'authorized':
        return CalendarPermissionStatus.granted;
      case 'denied':
        return CalendarPermissionStatus.denied;
      case 'restricted':
        return CalendarPermissionStatus.restricted;
      case 'notdetermined':
      case 'not_determined':
        return CalendarPermissionStatus.notDetermined;
      default:
        Logger.warning(_tag, 'Unknown permission status: $status');
        return CalendarPermissionStatus.denied;
    }
  }

  /// Get platform name for logging
  String get platformName {
    if (Platform.isIOS) return 'iOS (EventKit)';
    if (Platform.isAndroid) return 'Android (CalendarContract)';
    return 'Unknown';
  }

  /// Sanitize text input for native calendar
  ///
  /// Trims whitespace, validates length, and ensures text is safe for platform APIs
  /// Returns null if input is null or becomes empty after trimming
  String? _sanitizeText(String? text, {required int maxLength}) {
    if (text == null) return null;

    // Trim whitespace
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    // Truncate to max length
    if (trimmed.length > maxLength) {
      Logger.warning(_tag, 'Text truncated from ${trimmed.length} to $maxLength characters');
      return trimmed.substring(0, maxLength);
    }

    return trimmed;
  }
}
