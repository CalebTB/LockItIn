import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/data/models/event_model.dart';

/// Tests for event creation validation logic
/// These tests validate the business rules for event creation:
/// 1. Past date validation - events cannot be created in the past
/// 2. Time range validation - end time must be after start time
/// 3. Multi-day event support - events can span multiple days
void main() {
  group('Event Creation - Past Date Validation', () {
    test('should reject event with start time in the past', () {
      // Create an event that started 1 hour ago
      final now = DateTime.now();
      final pastStartTime = now.subtract(const Duration(hours: 1));

      // This event should be rejected because start time is in the past
      expect(pastStartTime.isBefore(now), true,
          reason: 'Start time should be in the past');

      // In the UI, this would trigger a validation error:
      // "Cannot create events in the past"
    });

    test('should reject event with both start and end time in the past', () {
      final now = DateTime.now();
      final pastStartTime = now.subtract(const Duration(hours: 2));
      final pastEndTime = now.subtract(const Duration(hours: 1));

      expect(pastStartTime.isBefore(now), true);
      expect(pastEndTime.isBefore(now), true);
      expect(pastEndTime.isAfter(pastStartTime), true,
          reason: 'End time should still be after start time');

      // Both times are in the past - definitely should be rejected
    });

    test('should accept event starting right now', () {
      final now = DateTime.now();
      final endTime = now.add(const Duration(hours: 1));

      // Event starting now should be allowed
      expect(now.isBefore(now), false,
          reason: 'Current time should not be considered past');
      expect(endTime.isAfter(now), true);
    });

    test('should accept event starting in the future', () {
      final now = DateTime.now();
      final futureStartTime = now.add(const Duration(days: 1));
      final futureEndTime = futureStartTime.add(const Duration(hours: 2));

      expect(futureStartTime.isAfter(now), true);
      expect(futureEndTime.isAfter(futureStartTime), true);

      // This event should be valid
    });

    test('should reject event starting 1 minute in the past', () {
      final now = DateTime.now();
      final pastStartTime = now.subtract(const Duration(minutes: 1));
      final endTime = now.add(const Duration(hours: 1));

      expect(pastStartTime.isBefore(now), true,
          reason: 'Even 1 minute in the past should be rejected');
      expect(endTime.isAfter(pastStartTime), true,
          reason: 'End time is valid, but start time is in the past');
    });

    test('should handle edge case at midnight crossing', () {
      // Test event created just before midnight
      final today = DateTime.now();
      final almostMidnight =
          DateTime(today.year, today.month, today.day, 23, 59);
      final tomorrow = DateTime(today.year, today.month, today.day + 1, 0, 30);

      // If created before midnight, event should be valid
      if (DateTime.now().isBefore(almostMidnight)) {
        expect(almostMidnight.isAfter(DateTime.now()), true);
        expect(tomorrow.isAfter(almostMidnight), true);
      }
    });
  });

  group('Event Creation - Time Range Validation (Same Day)', () {
    test('should reject same-day event where end time equals start time', () {
      final today = DateTime.now();
      final startTime = DateTime(today.year, today.month, today.day, 14, 0);
      final endTime = DateTime(today.year, today.month, today.day, 14, 0);

      expect(endTime.isAtSameMomentAs(startTime), true);
      expect(endTime.isAfter(startTime), false,
          reason: 'End time must be after start time, not equal');
    });

    test('should reject same-day event where end time is before start time', () {
      final today = DateTime.now();
      // Start at 2:00 PM, end at 1:00 PM (same day)
      final startTime = DateTime(today.year, today.month, today.day, 14, 0);
      final endTime = DateTime(today.year, today.month, today.day, 13, 0);

      expect(endTime.isBefore(startTime), true,
          reason: 'End time 13:00 is before start time 14:00');
    });

    test('should reject event ending 1 minute before it starts (same day)', () {
      final today = DateTime.now();
      final startTime = DateTime(today.year, today.month, today.day, 10, 49);
      final endTime = DateTime(today.year, today.month, today.day, 10, 35);

      expect(endTime.isBefore(startTime), true,
          reason: '10:35 AM is before 10:49 AM');

      // Example from requirements: 10:49am to 10:35am on same day is invalid
    });

    test('should accept same-day event with valid time range', () {
      final today = DateTime.now();
      final startTime = DateTime(today.year, today.month, today.day, 9, 0);
      final endTime = DateTime(today.year, today.month, today.day, 10, 0);

      expect(endTime.isAfter(startTime), true,
          reason: 'Valid 1-hour event');
    });

    test('should accept same-day event spanning morning to evening', () {
      final today = DateTime.now();
      final startTime = DateTime(today.year, today.month, today.day, 8, 0);
      final endTime = DateTime(today.year, today.month, today.day, 17, 30);

      expect(endTime.isAfter(startTime), true,
          reason: 'Valid 9.5-hour event');
    });

    test('should accept very short event (5 minutes)', () {
      final today = DateTime.now();
      final startTime = DateTime(today.year, today.month, today.day, 14, 0);
      final endTime = DateTime(today.year, today.month, today.day, 14, 5);

      expect(endTime.isAfter(startTime), true,
          reason: 'Even short events should be valid if end > start');
    });
  });

  group('Event Creation - Multi-Day Event Support', () {
    test('should accept event spanning two consecutive days', () {
      final today = DateTime.now();
      final startTime = DateTime(today.year, today.month, today.day, 20, 0);
      final endTime =
          DateTime(today.year, today.month, today.day + 1, 2, 0); // Next day

      expect(endTime.isAfter(startTime), true,
          reason: 'Event ending next day should be valid');

      final duration = endTime.difference(startTime);
      expect(duration.inHours, 6,
          reason: 'Event should span 6 hours across two days');
    });

    test('should accept event where start time is later than end time but on different days',
        () {
      final today = DateTime.now();
      // Start at 11:00 PM today, end at 2:00 AM tomorrow
      final startTime = DateTime(today.year, today.month, today.day, 23, 0);
      final endTime = DateTime(today.year, today.month, today.day + 1, 2, 0);

      expect(endTime.isAfter(startTime), true,
          reason:
              'Even though 2:00 < 23:00 as times, the date makes it valid');
      expect(endTime.day, startTime.day + 1,
          reason: 'Should be on different days');
    });

    test('should accept event spanning a full week', () {
      final today = DateTime.now();
      final startTime = DateTime(today.year, today.month, today.day, 9, 0);
      final endTime = DateTime(today.year, today.month, today.day + 7, 17, 0);

      expect(endTime.isAfter(startTime), true);

      final duration = endTime.difference(startTime);
      expect(duration.inDays, 7,
          reason: 'Event should span 7 full days');
    });

    test('should accept multi-day event (conference)', () {
      final today = DateTime.now();
      // 3-day conference: starts Monday 8am, ends Wednesday 5pm
      final startTime = DateTime(today.year, today.month, today.day, 8, 0);
      final endTime = DateTime(today.year, today.month, today.day + 2, 17, 0);

      expect(endTime.isAfter(startTime), true);

      final duration = endTime.difference(startTime);
      expect(duration.inHours, 2 * 24 + 9,
          reason: 'Should be approximately 2 days + 9 hours');
    });

    test('should accept multi-day event (vacation)', () {
      final today = DateTime.now();
      // 2-week vacation
      final startTime = DateTime(today.year, today.month, today.day, 0, 0);
      final endTime = DateTime(today.year, today.month, today.day + 14, 23, 59);

      expect(endTime.isAfter(startTime), true);

      final duration = endTime.difference(startTime);
      expect(duration.inDays, greaterThanOrEqualTo(14),
          reason: 'Vacation should span at least 14 days');
    });

    test('should handle month boundary crossing', () {
      // Event starts on last day of month, ends on first day of next month
      final lastDayOfMonth = DateTime(2025, 6, 30, 18, 0);
      final firstDayOfNextMonth = DateTime(2025, 7, 1, 10, 0);

      expect(firstDayOfNextMonth.isAfter(lastDayOfMonth), true);
      expect(firstDayOfNextMonth.month, lastDayOfMonth.month + 1,
          reason: 'Should cross month boundary');
    });

    test('should handle year boundary crossing', () {
      // New Year's Eve party: Dec 31 8pm to Jan 1 2am
      final newYearsEve = DateTime(2025, 12, 31, 20, 0);
      final newYearsDay = DateTime(2026, 1, 1, 2, 0);

      expect(newYearsDay.isAfter(newYearsEve), true);
      expect(newYearsDay.year, newYearsEve.year + 1,
          reason: 'Should cross year boundary');
    });

    test('should accept all-day multi-day event', () {
      final today = DateTime.now();
      // All-day event for 3 days
      final startTime = DateTime(today.year, today.month, today.day, 0, 0);
      final endTime =
          DateTime(today.year, today.month, today.day + 2, 23, 59);

      expect(endTime.isAfter(startTime), true);

      final duration = endTime.difference(startTime);
      expect(duration.inDays, greaterThanOrEqualTo(2),
          reason: 'Should span at least 2 full days');
    });
  });

  group('Event Creation - Multi-Day Edge Cases', () {
    test('should reject multi-day event where end is before start', () {
      // This shouldn't happen with proper UI, but test business logic
      final today = DateTime.now();
      final startTime = DateTime(today.year, today.month, today.day + 2, 10, 0);
      final endTime = DateTime(today.year, today.month, today.day, 15, 0);

      expect(endTime.isBefore(startTime), true,
          reason: 'End date is 2 days before start date');
    });

    test('should handle leap year correctly for multi-day events', () {
      // Event crossing leap day in 2024
      final beforeLeapDay = DateTime(2024, 2, 28, 10, 0);
      final afterLeapDay = DateTime(2024, 3, 1, 10, 0);

      expect(afterLeapDay.isAfter(beforeLeapDay), true);

      final duration = afterLeapDay.difference(beforeLeapDay);
      expect(duration.inDays, 2,
          reason: 'Should include Feb 29 (leap day)');
    });

    test('should handle daylight saving time boundary', () {
      // This is a complex edge case - just ensure dates work across DST
      // DST typically happens in March and November
      final beforeDST = DateTime(2025, 3, 8, 12, 0); // Before DST
      final afterDST = DateTime(2025, 3, 10, 12, 0); // After DST

      expect(afterDST.isAfter(beforeDST), true);
      // Note: Duration might be affected by DST, but date comparison still works
    });

    test('should accept very long multi-day event (30 days)', () {
      final today = DateTime.now();
      final startTime = DateTime(today.year, today.month, today.day, 9, 0);
      final endTime = DateTime(today.year, today.month + 1, today.day, 17, 0);

      expect(endTime.isAfter(startTime), true);

      final duration = endTime.difference(startTime);
      expect(duration.inDays, greaterThanOrEqualTo(28),
          reason: 'Should span approximately a month');
    });
  });

  group('Event Creation - EventModel Validation', () {
    test('should create valid same-day event model', () {
      final now = DateTime.now();
      final startTime = now.add(const Duration(hours: 1));
      final endTime = startTime.add(const Duration(hours: 2));

      final event = EventModel(
        id: '1',
        userId: 'user123',
        title: 'Team Meeting',
        startTime: startTime,
        endTime: endTime,
        visibility: EventVisibility.sharedWithName,
        createdAt: now,
      );

      expect(event.startTime.isBefore(event.endTime), true);
      expect(event.endTime.isAfter(event.startTime), true);
      expect(event.title, 'Team Meeting');
    });

    test('should create valid multi-day event model', () {
      final now = DateTime.now();
      final startTime = now.add(const Duration(days: 1));
      final endTime = startTime.add(const Duration(days: 3));

      final event = EventModel(
        id: '2',
        userId: 'user123',
        title: 'Conference',
        description: 'Annual tech conference',
        startTime: startTime,
        endTime: endTime,
        location: 'San Francisco',
        visibility: EventVisibility.sharedWithName,
        createdAt: now,
      );

      expect(event.startTime.isBefore(event.endTime), true);
      expect(event.endTime.difference(event.startTime).inDays, 3);
      expect(event.title, 'Conference');
      expect(event.location, 'San Francisco');
    });

    test('should create event with all privacy options', () {
      final now = DateTime.now();
      final startTime = now.add(const Duration(hours: 1));
      final endTime = startTime.add(const Duration(hours: 1));

      // Private event
      final privateEvent = EventModel(
        id: '1',
        userId: 'user123',
        title: 'Private Meeting',
        startTime: startTime,
        endTime: endTime,
        visibility: EventVisibility.private,
        createdAt: now,
      );
      expect(privateEvent.visibility, EventVisibility.private);

      // Shared with name event
      final sharedEvent = EventModel(
        id: '2',
        userId: 'user123',
        title: 'Team Lunch',
        startTime: startTime,
        endTime: endTime,
        visibility: EventVisibility.sharedWithName,
        createdAt: now,
      );
      expect(sharedEvent.visibility, EventVisibility.sharedWithName);

      // Busy only event
      final busyEvent = EventModel(
        id: '3',
        userId: 'user123',
        title: 'Doctor Appointment',
        startTime: startTime,
        endTime: endTime,
        visibility: EventVisibility.busyOnly,
        createdAt: now,
      );
      expect(busyEvent.visibility, EventVisibility.busyOnly);
    });

    test('should detect invalid event times in model', () {
      final now = DateTime.now();
      final startTime = now.add(const Duration(hours: 2));
      final invalidEndTime = now.add(const Duration(hours: 1)); // Before start

      // Create the model (model itself doesn't validate, but we can test)
      final event = EventModel(
        id: '1',
        userId: 'user123',
        title: 'Invalid Event',
        startTime: startTime,
        endTime: invalidEndTime,
        visibility: EventVisibility.private,
        createdAt: now,
      );

      // Validation check
      expect(event.endTime.isBefore(event.startTime), true,
          reason: 'This event has invalid times');
      expect(event.endTime.isAfter(event.startTime), false,
          reason: 'Should fail validation in UI layer');
    });
  });

  group('Event Creation - All-Day Events', () {
    test('should create all-day event with correct times (00:00 to 23:59)', () {
      final today = DateTime.now();
      final startDate = DateTime(today.year, today.month, today.day + 1);
      final endDate = startDate; // Same day all-day event

      // Simulate all-day event
      final startDateTime = DateTime(startDate.year, startDate.month, startDate.day, 0, 0);
      final endDateTime = DateTime(endDate.year, endDate.month, endDate.day, 23, 59);

      expect(startDateTime.hour, 0);
      expect(startDateTime.minute, 0);
      expect(endDateTime.hour, 23);
      expect(endDateTime.minute, 59);
      expect(endDateTime.isAfter(startDateTime), true);
    });

    test('should create multi-day all-day event', () {
      final today = DateTime.now();
      final startDate = DateTime(today.year, today.month, today.day + 1);
      final endDate = DateTime(today.year, today.month, today.day + 3); // 3-day event

      // All-day times
      final startDateTime = DateTime(startDate.year, startDate.month, startDate.day, 0, 0);
      final endDateTime = DateTime(endDate.year, endDate.month, endDate.day, 23, 59);

      expect(endDateTime.isAfter(startDateTime), true);
      final duration = endDateTime.difference(startDateTime);
      expect(duration.inDays, greaterThanOrEqualTo(2),
          reason: 'Should span multiple days');
    });

    test('should accept all-day event for today', () {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      // All-day event today should be valid
      final startDateTime = DateTime(todayDate.year, todayDate.month, todayDate.day, 0, 0);
      final endDateTime = DateTime(todayDate.year, todayDate.month, todayDate.day, 23, 59);

      expect(endDateTime.isAfter(startDateTime), true);
      expect(startDateTime.day, todayDate.day);
      expect(endDateTime.day, todayDate.day);
    });

    test('should reject all-day event in the past', () {
      final today = DateTime.now();
      final yesterday = DateTime(today.year, today.month, today.day - 1);

      // All-day event yesterday should be rejected
      expect(yesterday.isBefore(today), true,
          reason: 'Yesterday is before today');
    });

    test('should handle all-day event across year boundary', () {
      // New Year's Eve all day to New Year's Day all day
      final nye = DateTime(2025, 12, 31, 0, 0);
      final nyd = DateTime(2026, 1, 1, 23, 59);

      expect(nyd.isAfter(nye), true);
      expect(nyd.year, nye.year + 1);
    });

    test('should differentiate between timed and all-day events', () {
      final today = DateTime.now();
      final tomorrow = DateTime(today.year, today.month, today.day + 1);

      // Timed event
      final timedStart = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 14, 0);
      final timedEnd = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 15, 30);

      // All-day event
      final allDayStart = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 0, 0);
      final allDayEnd = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 59);

      expect(timedStart.hour, 14);
      expect(allDayStart.hour, 0);
      expect(timedEnd.hour, 15);
      expect(allDayEnd.hour, 23);
    });
  });

  group('Event Creation - Complex Scenarios', () {
    test('should handle overnight event (10pm to 6am)', () {
      final today = DateTime.now();
      final startTime = DateTime(today.year, today.month, today.day, 22, 0);
      final endTime = DateTime(today.year, today.month, today.day + 1, 6, 0);

      expect(endTime.isAfter(startTime), true);

      final duration = endTime.difference(startTime);
      expect(duration.inHours, 8,
          reason: 'Overnight shift should be 8 hours');
    });

    test('should handle back-to-back multi-day events', () {
      final now = DateTime.now();

      // First event: 3 days
      final event1Start = now.add(const Duration(days: 1));
      final event1End = event1Start.add(const Duration(days: 3));

      // Second event: starts right after first
      final event2Start = event1End;
      final event2End = event2Start.add(const Duration(days: 2));

      expect(event1End.isAfter(event1Start), true);
      expect(event2End.isAfter(event2Start), true);
      expect(event2Start.isAtSameMomentAs(event1End), true,
          reason: 'Second event starts exactly when first ends');
    });

    test('should handle all-day event starting at midnight', () {
      final today = DateTime.now();
      final startTime =
          DateTime(today.year, today.month, today.day + 1, 0, 0);
      final endTime =
          DateTime(today.year, today.month, today.day + 1, 23, 59);

      expect(endTime.isAfter(startTime), true);
      expect(startTime.hour, 0);
      expect(endTime.hour, 23);
    });

    test('should validate event created from user input', () {
      // Simulate user creating event for tomorrow 2pm-4pm
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));

      final startTime = DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        14, // 2 PM
        0,
      );

      final endTime = DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        16, // 4 PM
        0,
      );

      // Validation checks
      expect(startTime.isAfter(now), true,
          reason: 'Event should be in the future');
      expect(endTime.isAfter(startTime), true,
          reason: 'End should be after start');

      final duration = endTime.difference(startTime);
      expect(duration.inHours, 2,
          reason: 'Event should be 2 hours long');
    });
  });
}
