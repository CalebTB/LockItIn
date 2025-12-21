import 'dart:io';
import 'package:flutter/services.dart';
import '../../data/models/event_model.dart';
import '../utils/logger.dart';

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
  static const MethodChannel _channel =
      MethodChannel('com.lockitin.calendar');

  /// Request calendar access permissions
  /// Returns true if permission granted, false otherwise
  Future<CalendarPermissionStatus> requestPermission() async {
    try {
      Logger.info('Requesting calendar permission');
      final String result = await _channel.invokeMethod('requestPermission');
      Logger.info('Calendar permission result: $result');

      return _parsePermissionStatus(result);
    } on PlatformException catch (e) {
      Logger.error('Failed to request calendar permission: ${e.message}');
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
    } on PlatformException catch (e) {
      Logger.error('Failed to check calendar permission: ${e.message}');
      throw CalendarAccessException(
        'Failed to check permission: ${e.message}',
      );
    }
  }

  /// Fetch events from native calendar within date range
  ///
  /// [startDate] - Start of date range to fetch events
  /// [endDate] - End of date range to fetch events
  ///
  /// Returns list of events from device calendar (Apple Calendar on iOS,
  /// Google Calendar/device calendar on Android)
  ///
  /// Throws [CalendarAccessException] if permission denied or fetch fails
  Future<List<EventModel>> fetchEvents({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      Logger.info(
        'Fetching events from ${startDate.toIso8601String()} to ${endDate.toIso8601String()}',
      );

      final List<dynamic> result = await _channel.invokeMethod(
        'fetchEvents',
        {
          'startDate': startDate.millisecondsSinceEpoch,
          'endDate': endDate.millisecondsSinceEpoch,
        },
      );

      Logger.info('Fetched ${result.length} events from native calendar');

      // Convert native events to EventModel
      return result.map((eventData) {
        return _parseNativeEvent(eventData as Map<dynamic, dynamic>);
      }).toList();
    } on PlatformException catch (e) {
      Logger.error('Failed to fetch events: ${e.message}');

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
  /// Returns native calendar event ID for bidirectional sync
  Future<String> createEvent(EventModel event) async {
    try {
      Logger.info('Creating event in native calendar: ${event.title}');

      final String nativeEventId = await _channel.invokeMethod(
        'createEvent',
        {
          'title': event.title,
          'description': event.description,
          'startTime': event.startTime.millisecondsSinceEpoch,
          'endTime': event.endTime.millisecondsSinceEpoch,
          'location': event.location,
        },
      );

      Logger.info('Created event with native ID: $nativeEventId');
      return nativeEventId;
    } on PlatformException catch (e) {
      Logger.error('Failed to create event: ${e.message}');
      throw CalendarAccessException('Failed to create event: ${e.message}');
    }
  }

  /// Update an event in the native calendar
  ///
  /// [event] - EventModel with updated data
  ///
  /// Requires event.nativeCalendarId to be set
  Future<void> updateEvent(EventModel event) async {
    if (event.nativeCalendarId == null) {
      throw CalendarAccessException(
        'Cannot update event without nativeCalendarId',
      );
    }

    try {
      Logger.info('Updating native event: ${event.nativeCalendarId}');

      await _channel.invokeMethod(
        'updateEvent',
        {
          'nativeEventId': event.nativeCalendarId,
          'title': event.title,
          'description': event.description,
          'startTime': event.startTime.millisecondsSinceEpoch,
          'endTime': event.endTime.millisecondsSinceEpoch,
          'location': event.location,
        },
      );

      Logger.info('Updated native event successfully');
    } on PlatformException catch (e) {
      Logger.error('Failed to update event: ${e.message}');
      throw CalendarAccessException('Failed to update event: ${e.message}');
    }
  }

  /// Delete an event from the native calendar
  ///
  /// [nativeEventId] - Native calendar event ID
  Future<void> deleteEvent(String nativeEventId) async {
    try {
      Logger.info('Deleting native event: $nativeEventId');

      await _channel.invokeMethod(
        'deleteEvent',
        {'nativeEventId': nativeEventId},
      );

      Logger.info('Deleted native event successfully');
    } on PlatformException catch (e) {
      Logger.error('Failed to delete event: ${e.message}');
      throw CalendarAccessException('Failed to delete event: ${e.message}');
    }
  }

  /// Parse native calendar event data to EventModel
  EventModel _parseNativeEvent(Map<dynamic, dynamic> eventData) {
    // Generate a temporary ID for native events (will be replaced when synced to Supabase)
    final String tempId = 'native_${eventData['nativeEventId']}';

    return EventModel(
      id: tempId,
      userId: 'temp_user', // Will be set to current user when syncing
      title: eventData['title'] as String? ?? 'Untitled Event',
      description: eventData['description'] as String?,
      startTime: DateTime.fromMillisecondsSinceEpoch(
        eventData['startTime'] as int,
      ),
      endTime: DateTime.fromMillisecondsSinceEpoch(
        eventData['endTime'] as int,
      ),
      location: eventData['location'] as String?,
      visibility: EventVisibility.private, // Default to private for native events
      nativeCalendarId: eventData['nativeEventId'] as String,
      createdAt: DateTime.now(),
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
        Logger.warning('Unknown permission status: $status');
        return CalendarPermissionStatus.denied;
    }
  }

  /// Get platform name for logging
  String get platformName {
    if (Platform.isIOS) return 'iOS (EventKit)';
    if (Platform.isAndroid) return 'Android (CalendarContract)';
    return 'Unknown';
  }
}
