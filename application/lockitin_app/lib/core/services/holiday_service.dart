import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../data/models/event_model.dart';
import '../utils/logger.dart';

/// Service for loading national holidays from JSON assets
class HolidayService {
  static const String _holidaysAssetPath = 'assets/lockitin_events/lockitin-holiday-events.json';

  /// Cached holidays list
  static List<EventModel>? _cachedHolidays;

  /// Load holidays from JSON asset file
  /// Returns a list of EventModel objects representing national holidays
  static Future<List<EventModel>> loadHolidays() async {
    // Return cached holidays if already loaded
    if (_cachedHolidays != null) {
      return _cachedHolidays!;
    }

    try {
      // Load JSON file from assets
      final String jsonString = await rootBundle.loadString(_holidaysAssetPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      // Parse holidays array
      final List<dynamic> holidaysJson = jsonData['holidays'] as List<dynamic>;

      // Convert JSON objects to EventModel instances
      final List<EventModel> holidays = holidaysJson.map((holidayJson) {
        return _parseHoliday(holidayJson as Map<String, dynamic>);
      }).toList();

      // Cache the loaded holidays
      _cachedHolidays = holidays;

      return holidays;
    } catch (e) {
      // If loading fails, return empty list (app continues to work without holidays)
      Logger.error('HolidayService', 'Failed to load holidays', e);
      return [];
    }
  }

  /// Parse a single holiday JSON object into an EventModel
  static EventModel _parseHoliday(Map<String, dynamic> json) {
    final DateTime date = DateTime.parse(json['date'] as String);

    // Create start and end times for all-day events
    // All-day events span from midnight to midnight (24 hours)
    final DateTime startTime = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final DateTime endTime = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return EventModel(
      id: json['id'] as String,
      userId: 'system', // System-generated event, not user-created
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: startTime,
      endTime: endTime,
      location: null, // Holidays don't have a specific location
      visibility: EventVisibility.sharedWithName, // Holidays are visible to all users
      nativeCalendarId: null, // Not synced from native calendar
      createdAt: DateTime.now(),
      updatedAt: null,
    );
  }

  /// Get holidays for a specific date range
  static Future<List<EventModel>> getHolidaysInRange(DateTime startDate, DateTime endDate) async {
    final List<EventModel> allHolidays = await loadHolidays();

    return allHolidays.where((holiday) {
      return (holiday.startTime.isAfter(startDate) || holiday.startTime.isAtSameMomentAs(startDate)) &&
             (holiday.startTime.isBefore(endDate) || holiday.startTime.isAtSameMomentAs(endDate));
    }).toList();
  }

  /// Clear cached holidays (useful for testing or if JSON is updated)
  static void clearCache() {
    _cachedHolidays = null;
  }
}
