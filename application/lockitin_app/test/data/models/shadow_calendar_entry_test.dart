import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/data/models/shadow_calendar_entry.dart';

void main() {
  group('ShadowCalendarEntry', () {
    test('should create entry from JSON with busyOnly visibility', () {
      final json = {
        'user_id': 'user_123',
        'start_time': '2025-12-30T10:00:00Z',
        'end_time': '2025-12-30T11:00:00Z',
        'visibility': 'busyOnly',
        'event_title': null,
      };

      final entry = ShadowCalendarEntry.fromJson(json);

      expect(entry.userId, 'user_123');
      expect(entry.startTime, DateTime.utc(2025, 12, 30, 10, 0));
      expect(entry.endTime, DateTime.utc(2025, 12, 30, 11, 0));
      expect(entry.visibility, ShadowVisibility.busyOnly);
      expect(entry.eventTitle, isNull);
      expect(entry.isBusyOnly, isTrue);
      expect(entry.displayText, 'Busy');
    });

    test('should create entry from JSON with sharedWithName visibility', () {
      final json = {
        'user_id': 'user_456',
        'start_time': '2025-12-31T14:00:00Z',
        'end_time': '2025-12-31T16:00:00Z',
        'visibility': 'sharedWithName',
        'event_title': 'Team Meeting',
      };

      final entry = ShadowCalendarEntry.fromJson(json);

      expect(entry.userId, 'user_456');
      expect(entry.visibility, ShadowVisibility.sharedWithName);
      expect(entry.eventTitle, 'Team Meeting');
      expect(entry.isBusyOnly, isFalse);
      expect(entry.displayText, 'Team Meeting');
    });

    test('should handle unknown visibility as busyOnly', () {
      final json = {
        'user_id': 'user_789',
        'start_time': '2025-12-30T10:00:00Z',
        'end_time': '2025-12-30T11:00:00Z',
        'visibility': 'unknown_value',
        'event_title': null,
      };

      final entry = ShadowCalendarEntry.fromJson(json);

      expect(entry.visibility, ShadowVisibility.busyOnly);
      expect(entry.displayText, 'Busy');
    });

    test('should display Busy when sharedWithName has null title', () {
      final entry = ShadowCalendarEntry(
        userId: 'user_123',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 1)),
        visibility: ShadowVisibility.sharedWithName,
        eventTitle: null, // Unusual but possible
      );

      expect(entry.displayText, 'Busy'); // Falls back to Busy
    });

    test('should support equality comparison', () {
      final now = DateTime.now();
      final entry1 = ShadowCalendarEntry(
        userId: 'user_123',
        startTime: now,
        endTime: now.add(const Duration(hours: 1)),
        visibility: ShadowVisibility.busyOnly,
      );

      final entry2 = ShadowCalendarEntry(
        userId: 'user_123',
        startTime: now,
        endTime: now.add(const Duration(hours: 1)),
        visibility: ShadowVisibility.busyOnly,
      );

      expect(entry1, equals(entry2));
    });

    test('should detect different entries as not equal', () {
      final now = DateTime.now();
      final entry1 = ShadowCalendarEntry(
        userId: 'user_123',
        startTime: now,
        endTime: now.add(const Duration(hours: 1)),
        visibility: ShadowVisibility.busyOnly,
      );

      final entry2 = ShadowCalendarEntry(
        userId: 'user_456', // Different user
        startTime: now,
        endTime: now.add(const Duration(hours: 1)),
        visibility: ShadowVisibility.busyOnly,
      );

      expect(entry1, isNot(equals(entry2)));
    });
  });
}
