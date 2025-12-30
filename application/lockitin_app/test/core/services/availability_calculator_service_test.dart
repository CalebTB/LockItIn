import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/core/services/availability_calculator_service.dart';
import 'package:lockitin_app/core/utils/time_filter_utils.dart';
import 'package:lockitin_app/data/models/event_model.dart';

void main() {
  late AvailabilityCalculatorService service;

  setUp(() {
    service = AvailabilityCalculatorService();
  });

  // Helper to create test events
  EventModel createEvent({
    required DateTime startTime,
    required DateTime endTime,
    String userId = 'user1',
    EventCategory category = EventCategory.work,
  }) {
    return EventModel(
      id: 'event-${startTime.millisecondsSinceEpoch}',
      userId: userId,
      title: 'Test Event',
      startTime: startTime,
      endTime: endTime,
      visibility: EventVisibility.busyOnly,
      category: category,
      createdAt: DateTime.now(),
    );
  }

  group('TimeSlotAvailability', () {
    test('should calculate availability ratio correctly', () {
      final slot = TimeSlotAvailability(
        startTime: DateTime(2025, 1, 15, 14, 0),
        endTime: DateTime(2025, 1, 15, 15, 0),
        availableCount: 6,
        totalMembers: 8,
        availableMembers: ['a', 'b', 'c', 'd', 'e', 'f'],
        busyMembers: ['g', 'h'],
      );

      expect(slot.availabilityRatio, 0.75);
      expect(slot.isFullyAvailable, false);
      expect(slot.isEmpty, false);
    });

    test('should format time range correctly', () {
      final slot = TimeSlotAvailability(
        startTime: DateTime(2025, 1, 15, 14, 0),
        endTime: DateTime(2025, 1, 15, 16, 0),
        availableCount: 8,
        totalMembers: 8,
        availableMembers: [],
        busyMembers: [],
      );

      expect(slot.formattedTimeRange, '2pm - 4pm');
      expect(slot.isFullyAvailable, true);
    });

    test('should handle empty availability', () {
      final slot = TimeSlotAvailability(
        startTime: DateTime(2025, 1, 15, 9, 0),
        endTime: DateTime(2025, 1, 15, 10, 0),
        availableCount: 0,
        totalMembers: 5,
        availableMembers: [],
        busyMembers: ['a', 'b', 'c', 'd', 'e'],
      );

      expect(slot.isEmpty, true);
      expect(slot.availabilityRatio, 0.0);
    });
  });

  group('findBestTimeSlots', () {
    test('should return empty list when no members', () {
      final slots = service.findBestTimeSlots(
        memberEvents: {},
        date: DateTime(2025, 1, 15),
      );

      expect(slots, isEmpty);
    });

    test('should return all slots as available when no events', () {
      final memberEvents = {
        'user1': <EventModel>[],
        'user2': <EventModel>[],
        'user3': <EventModel>[],
      };

      final slots = service.findBestTimeSlots(
        memberEvents: memberEvents,
        date: DateTime(2025, 1, 15),
        startHour: 9,
        endHour: 12,
      );

      expect(slots.length, 3); // 9-10, 10-11, 11-12
      expect(slots.first.availableCount, 3);
      expect(slots.first.isFullyAvailable, true);
    });

    test('should correctly identify busy slots', () {
      final date = DateTime(2025, 1, 15);
      final memberEvents = {
        'user1': <EventModel>[
          EventModel(
            id: '1',
            userId: 'user1',
            title: 'Meeting',
            startTime: DateTime(2025, 1, 15, 10, 0),
            endTime: DateTime(2025, 1, 15, 11, 0),
            visibility: EventVisibility.busyOnly,
            createdAt: date,
          ),
        ],
        'user2': <EventModel>[],
        'user3': <EventModel>[],
      };

      final slots = service.findBestTimeSlots(
        memberEvents: memberEvents,
        date: date,
        startHour: 9,
        endHour: 12,
      );

      // Find the 10-11 slot
      final busySlot = slots.firstWhere(
        (s) => s.startTime.hour == 10,
      );

      expect(busySlot.availableCount, 2); // user2 and user3 are free
      expect(busySlot.busyMembers, contains('user1'));
    });

    test('should sort by availability then by time', () {
      final date = DateTime(2025, 1, 15);
      final memberEvents = {
        'user1': <EventModel>[
          EventModel(
            id: '1',
            userId: 'user1',
            title: 'Morning Meeting',
            startTime: DateTime(2025, 1, 15, 9, 0),
            endTime: DateTime(2025, 1, 15, 10, 0),
            visibility: EventVisibility.busyOnly,
            createdAt: date,
          ),
        ],
        'user2': <EventModel>[
          EventModel(
            id: '2',
            userId: 'user2',
            title: 'Morning Meeting',
            startTime: DateTime(2025, 1, 15, 9, 0),
            endTime: DateTime(2025, 1, 15, 10, 0),
            visibility: EventVisibility.busyOnly,
            createdAt: date,
          ),
        ],
      };

      final slots = service.findBestTimeSlots(
        memberEvents: memberEvents,
        date: date,
        startHour: 9,
        endHour: 11,
      );

      // First slot should be the one with highest availability (10-11)
      expect(slots.first.startTime.hour, 10);
      expect(slots.first.availableCount, 2);

      // Second slot has lower availability (9-10)
      expect(slots.last.startTime.hour, 9);
      expect(slots.last.availableCount, 0);
    });
  });

  group('getHourlyAvailability', () {
    test('should return availability for each hour', () {
      final memberEvents = {
        'user1': <EventModel>[],
        'user2': <EventModel>[],
      };

      final hourly = service.getHourlyAvailability(
        memberEvents: memberEvents,
        date: DateTime(2025, 1, 15),
        startHour: 9,
        endHour: 12,
      );

      expect(hourly.length, 3);
      expect(hourly[9], 2);
      expect(hourly[10], 2);
      expect(hourly[11], 2);
    });

    test('should reflect busy hours correctly', () {
      final date = DateTime(2025, 1, 15);
      final memberEvents = {
        'user1': <EventModel>[
          EventModel(
            id: '1',
            userId: 'user1',
            title: 'Lunch',
            startTime: DateTime(2025, 1, 15, 12, 0),
            endTime: DateTime(2025, 1, 15, 13, 0),
            visibility: EventVisibility.busyOnly,
            createdAt: date,
          ),
        ],
        'user2': <EventModel>[],
      };

      final hourly = service.getHourlyAvailability(
        memberEvents: memberEvents,
        date: date,
        startHour: 11,
        endHour: 14,
      );

      expect(hourly[11], 2); // Both free
      expect(hourly[12], 1); // user1 busy
      expect(hourly[13], 2); // Both free
    });
  });

  group('findAvailableWindows', () {
    test('should return empty when no members', () {
      final windows = service.findAvailableWindows(
        memberEvents: {},
        date: DateTime(2025, 1, 15),
        minimumAvailable: 1,
      );

      expect(windows, isEmpty);
    });

    test('should find contiguous available windows', () {
      final date = DateTime(2025, 1, 15);
      final memberEvents = {
        'user1': <EventModel>[
          EventModel(
            id: '1',
            userId: 'user1',
            title: 'Meeting',
            startTime: DateTime(2025, 1, 15, 12, 0),
            endTime: DateTime(2025, 1, 15, 13, 0),
            visibility: EventVisibility.busyOnly,
            createdAt: date,
          ),
        ],
        'user2': <EventModel>[],
      };

      final windows = service.findAvailableWindows(
        memberEvents: memberEvents,
        date: date,
        minimumAvailable: 2, // Both must be free
        startHour: 10,
        endHour: 15,
      );

      // Should find 2 windows: 10-12 and 13-15
      // (12-13 excluded because user1 is busy)
      expect(windows.length, 2);
    });

    test('should merge contiguous slots into windows', () {
      final memberEvents = {
        'user1': <EventModel>[],
        'user2': <EventModel>[],
        'user3': <EventModel>[],
      };

      final windows = service.findAvailableWindows(
        memberEvents: memberEvents,
        date: DateTime(2025, 1, 15),
        minimumAvailable: 3,
        startHour: 9,
        endHour: 12,
      );

      // All 3 users free from 9-12, should be one window
      expect(windows.length, 1);
      expect(windows.first.startTime.hour, 9);
      expect(windows.first.endTime.hour, 12);
    });
  });

  group('calculateGroupAvailability', () {
    test('should return 0 when no members', () {
      final result = service.calculateGroupAvailability(
        memberEvents: {},
        date: DateTime(2025, 1, 15),
        timeFilters: {TimeFilter.morning},
      );

      expect(result, 0);
    });

    test('should return total member count when all are free', () {
      final memberEvents = {
        'user1': <EventModel>[],
        'user2': <EventModel>[],
        'user3': <EventModel>[],
        'user4': <EventModel>[],
        'user5': <EventModel>[],
      };

      final result = service.calculateGroupAvailability(
        memberEvents: memberEvents,
        date: DateTime(2025, 1, 15),
        timeFilters: {TimeFilter.morning},
      );

      expect(result, 5);
    });

    test('should return 0 when all members are busy', () {
      final date = DateTime(2025, 1, 15);
      final memberEvents = {
        'user1': [
          createEvent(
            startTime: DateTime(2025, 1, 15, 8, 0),
            endTime: DateTime(2025, 1, 15, 10, 0),
            userId: 'user1',
          ),
        ],
        'user2': [
          createEvent(
            startTime: DateTime(2025, 1, 15, 9, 0),
            endTime: DateTime(2025, 1, 15, 11, 0),
            userId: 'user2',
          ),
        ],
        'user3': [
          createEvent(
            startTime: DateTime(2025, 1, 15, 6, 0),
            endTime: DateTime(2025, 1, 15, 12, 0),
            userId: 'user3',
          ),
        ],
      };

      final result = service.calculateGroupAvailability(
        memberEvents: memberEvents,
        date: date,
        timeFilters: {TimeFilter.morning}, // 6am - 12pm
      );

      expect(result, 0);
    });

    test('should return correct count for mixed availability', () {
      final date = DateTime(2025, 1, 15);
      final memberEvents = {
        'user1': [
          createEvent(
            startTime: DateTime(2025, 1, 15, 8, 0),
            endTime: DateTime(2025, 1, 15, 10, 0),
            userId: 'user1',
          ),
        ],
        'user2': <EventModel>[], // Free
        'user3': <EventModel>[], // Free
        'user4': [
          createEvent(
            startTime: DateTime(2025, 1, 15, 9, 0),
            endTime: DateTime(2025, 1, 15, 11, 0),
            userId: 'user4',
          ),
        ],
        'user5': <EventModel>[], // Free
      };

      final result = service.calculateGroupAvailability(
        memberEvents: memberEvents,
        date: date,
        timeFilters: {TimeFilter.morning},
      );

      expect(result, 3); // user2, user3, user5 are free
    });

    test('should exclude holidays from availability calculation', () {
      final date = DateTime(2025, 1, 15);
      final memberEvents = {
        'user1': [
          createEvent(
            startTime: DateTime(2025, 1, 15, 8, 0),
            endTime: DateTime(2025, 1, 15, 10, 0),
            userId: 'user1',
            category: EventCategory.holiday, // Should be ignored
          ),
        ],
        'user2': <EventModel>[],
      };

      final result = service.calculateGroupAvailability(
        memberEvents: memberEvents,
        date: date,
        timeFilters: {TimeFilter.morning},
      );

      expect(result, 2); // Both free (holiday is excluded)
    });
  });

  group('calculateGroupAvailability - Time Filters', () {
    test('should only check morning time range (6am-12pm)', () {
      final date = DateTime(2025, 1, 15);
      final memberEvents = {
        'user1': [
          // Event is in afternoon, not morning
          createEvent(
            startTime: DateTime(2025, 1, 15, 14, 0),
            endTime: DateTime(2025, 1, 15, 15, 0),
            userId: 'user1',
          ),
        ],
        'user2': <EventModel>[],
      };

      final result = service.calculateGroupAvailability(
        memberEvents: memberEvents,
        date: date,
        timeFilters: {TimeFilter.morning}, // 6am - 12pm
      );

      expect(result, 2); // Both free in the morning
    });

    test('should only check afternoon time range (12pm-5pm)', () {
      final date = DateTime(2025, 1, 15);
      final memberEvents = {
        'user1': [
          // Event is in morning, not afternoon
          createEvent(
            startTime: DateTime(2025, 1, 15, 9, 0),
            endTime: DateTime(2025, 1, 15, 10, 0),
            userId: 'user1',
          ),
        ],
        'user2': [
          // Event is in afternoon
          createEvent(
            startTime: DateTime(2025, 1, 15, 14, 0),
            endTime: DateTime(2025, 1, 15, 15, 0),
            userId: 'user2',
          ),
        ],
      };

      final result = service.calculateGroupAvailability(
        memberEvents: memberEvents,
        date: date,
        timeFilters: {TimeFilter.afternoon}, // 12pm - 5pm
      );

      expect(result, 1); // Only user1 is free in the afternoon
    });

    test('should only check evening time range (5pm-10pm)', () {
      final date = DateTime(2025, 1, 15);
      final memberEvents = {
        'user1': [
          // Event is in evening
          createEvent(
            startTime: DateTime(2025, 1, 15, 18, 0),
            endTime: DateTime(2025, 1, 15, 20, 0),
            userId: 'user1',
          ),
        ],
        'user2': <EventModel>[],
      };

      final result = service.calculateGroupAvailability(
        memberEvents: memberEvents,
        date: date,
        timeFilters: {TimeFilter.evening}, // 5pm - 10pm
      );

      expect(result, 1); // Only user2 is free in the evening
    });

    test('should require availability across multiple filters', () {
      final date = DateTime(2025, 1, 15);
      final memberEvents = {
        'user1': [
          // Busy in morning only
          createEvent(
            startTime: DateTime(2025, 1, 15, 9, 0),
            endTime: DateTime(2025, 1, 15, 10, 0),
            userId: 'user1',
          ),
        ],
        'user2': [
          // Busy in afternoon only
          createEvent(
            startTime: DateTime(2025, 1, 15, 14, 0),
            endTime: DateTime(2025, 1, 15, 15, 0),
            userId: 'user2',
          ),
        ],
        'user3': <EventModel>[], // Free all day
      };

      final result = service.calculateGroupAvailability(
        memberEvents: memberEvents,
        date: date,
        timeFilters: {TimeFilter.morning, TimeFilter.afternoon},
      );

      // Only user3 is free in BOTH morning AND afternoon
      expect(result, 1);
    });

    test('should use custom time range when allDay filter with custom times', () {
      final date = DateTime(2025, 1, 15);
      final memberEvents = {
        'user1': [
          // Event is at 10am
          createEvent(
            startTime: DateTime(2025, 1, 15, 10, 0),
            endTime: DateTime(2025, 1, 15, 11, 0),
            userId: 'user1',
          ),
        ],
        'user2': <EventModel>[],
      };

      // Custom range is 2pm-4pm, so user1's 10am event shouldn't matter
      final result = service.calculateGroupAvailability(
        memberEvents: memberEvents,
        date: date,
        timeFilters: {TimeFilter.allDay},
        customStartTime: const TimeOfDay(hour: 14, minute: 0),
        customEndTime: const TimeOfDay(hour: 16, minute: 0),
      );

      expect(result, 2); // Both free in the 2pm-4pm range
    });
  });

  group('calculateGroupAvailability - Multi-day Events', () {
    test('should handle event that spans midnight correctly', () {
      final date = DateTime(2025, 1, 15);
      final memberEvents = {
        'user1': [
          // Event spans from 10pm on Jan 14 to 2am on Jan 15
          createEvent(
            startTime: DateTime(2025, 1, 14, 22, 0),
            endTime: DateTime(2025, 1, 15, 2, 0),
            userId: 'user1',
          ),
        ],
        'user2': <EventModel>[],
      };

      // Check morning of Jan 15 - user1 should be free (event ends at 2am)
      final result = service.calculateGroupAvailability(
        memberEvents: memberEvents,
        date: date,
        timeFilters: {TimeFilter.morning}, // 6am - 12pm
      );

      expect(result, 2); // Both free in morning (event ended at 2am)
    });

    test('should mark user busy for multi-day event on second day', () {
      final date = DateTime(2025, 1, 15);
      final memberEvents = {
        'user1': [
          // All-day event spanning multiple days
          createEvent(
            startTime: DateTime(2025, 1, 14, 0, 0),
            endTime: DateTime(2025, 1, 16, 0, 0),
            userId: 'user1',
          ),
        ],
        'user2': <EventModel>[],
      };

      final result = service.calculateGroupAvailability(
        memberEvents: memberEvents,
        date: date,
        timeFilters: {TimeFilter.morning},
      );

      expect(result, 1); // Only user2 is free (user1 has multi-day event)
    });
  });

  group('isMemberAvailable', () {
    test('should return true when no events', () {
      final result = service.isMemberAvailable(
        events: [],
        date: DateTime(2025, 1, 15),
        timeFilters: {TimeFilter.morning},
      );

      expect(result, true);
    });

    test('should return false when event overlaps with filter', () {
      final result = service.isMemberAvailable(
        events: [
          createEvent(
            startTime: DateTime(2025, 1, 15, 9, 0),
            endTime: DateTime(2025, 1, 15, 10, 0),
          ),
        ],
        date: DateTime(2025, 1, 15),
        timeFilters: {TimeFilter.morning},
      );

      expect(result, false);
    });

    test('should return true when event is outside filter time', () {
      final result = service.isMemberAvailable(
        events: [
          createEvent(
            startTime: DateTime(2025, 1, 15, 14, 0),
            endTime: DateTime(2025, 1, 15, 15, 0),
          ),
        ],
        date: DateTime(2025, 1, 15),
        timeFilters: {TimeFilter.morning}, // 6am - 12pm
      );

      expect(result, true); // Event is in afternoon, not morning
    });
  });

  group('getAvailabilityDescription', () {
    test('should return Free when no conflicts', () {
      final result = service.getAvailabilityDescription(
        events: [],
        date: DateTime(2025, 1, 15),
        filter: TimeFilter.morning,
      );

      expect(result, 'Free');
    });

    test('should return busy time range for single conflict', () {
      final result = service.getAvailabilityDescription(
        events: [
          createEvent(
            startTime: DateTime(2025, 1, 15, 9, 0),
            endTime: DateTime(2025, 1, 15, 10, 30),
          ),
        ],
        date: DateTime(2025, 1, 15),
        filter: TimeFilter.morning,
      );

      expect(result, contains('Busy'));
      expect(result, contains('9'));
      expect(result, contains('10:30'));
    });

    test('should return conflict count for multiple conflicts', () {
      final result = service.getAvailabilityDescription(
        events: [
          createEvent(
            startTime: DateTime(2025, 1, 15, 8, 0),
            endTime: DateTime(2025, 1, 15, 9, 0),
          ),
          createEvent(
            startTime: DateTime(2025, 1, 15, 10, 0),
            endTime: DateTime(2025, 1, 15, 11, 0),
          ),
          createEvent(
            startTime: DateTime(2025, 1, 15, 11, 0),
            endTime: DateTime(2025, 1, 15, 12, 0),
          ),
        ],
        date: DateTime(2025, 1, 15),
        filter: TimeFilter.morning,
      );

      expect(result, '3 conflicts');
    });

    test('should exclude holidays from conflict count', () {
      final result = service.getAvailabilityDescription(
        events: [
          createEvent(
            startTime: DateTime(2025, 1, 15, 8, 0),
            endTime: DateTime(2025, 1, 15, 9, 0),
            category: EventCategory.holiday,
          ),
        ],
        date: DateTime(2025, 1, 15),
        filter: TimeFilter.morning,
      );

      expect(result, 'Free'); // Holiday is excluded
    });
  });

  group('findLongestFreeBlock', () {
    test('should return entire range when no events', () {
      final rangeStart = DateTime(2025, 1, 15, 9, 0);
      final rangeEnd = DateTime(2025, 1, 15, 12, 0);

      final result = service.findLongestFreeBlock(
        events: [],
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );

      expect(result, 180); // 3 hours = 180 minutes
    });

    test('should find free block before event', () {
      final rangeStart = DateTime(2025, 1, 15, 9, 0);
      final rangeEnd = DateTime(2025, 1, 15, 12, 0);

      final result = service.findLongestFreeBlock(
        events: [
          createEvent(
            startTime: DateTime(2025, 1, 15, 11, 0),
            endTime: DateTime(2025, 1, 15, 12, 0),
          ),
        ],
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );

      expect(result, 120); // 2 hours free (9-11)
    });

    test('should find free block after event', () {
      final rangeStart = DateTime(2025, 1, 15, 9, 0);
      final rangeEnd = DateTime(2025, 1, 15, 12, 0);

      final result = service.findLongestFreeBlock(
        events: [
          createEvent(
            startTime: DateTime(2025, 1, 15, 9, 0),
            endTime: DateTime(2025, 1, 15, 10, 0),
          ),
        ],
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );

      expect(result, 120); // 2 hours free (10-12)
    });
  });

  group('findBestDaysInMonth', () {
    test('should return empty list when no members', () {
      final result = service.findBestDaysInMonth(
        memberEvents: {},
        month: DateTime(2025, 1, 1),
        timeFilters: {TimeFilter.morning},
        dateRange: null,
      );

      expect(result, isEmpty);
    });

    test('should return days sorted by availability', () {
      final memberEvents = {
        'user1': [
          createEvent(
            startTime: DateTime(2025, 1, 10, 9, 0),
            endTime: DateTime(2025, 1, 10, 10, 0),
            userId: 'user1',
          ),
        ],
        'user2': <EventModel>[],
      };

      final result = service.findBestDaysInMonth(
        memberEvents: memberEvents,
        month: DateTime(2025, 1, 1),
        timeFilters: {TimeFilter.morning},
        dateRange: DateTimeRange(
          start: DateTime(2025, 1, 1),
          end: DateTime(2025, 1, 15),
        ),
      );

      // Day 10 should be last (only 1 person free)
      // Other days should have 2 people free
      expect(result.isNotEmpty, true);
      expect(result.contains(10), true);
      expect(result.last, 10); // Day 10 has lowest availability
    });

    test('should respect date range filter', () {
      final memberEvents = {
        'user1': <EventModel>[],
        'user2': <EventModel>[],
      };

      final result = service.findBestDaysInMonth(
        memberEvents: memberEvents,
        month: DateTime(2025, 1, 1),
        timeFilters: {TimeFilter.morning},
        dateRange: DateTimeRange(
          start: DateTime(2025, 1, 10),
          end: DateTime(2025, 1, 15),
        ),
      );

      // Should only return days 10-15
      expect(result.length, 6);
      expect(result.every((day) => day >= 10 && day <= 15), true);
    });
  });
}
