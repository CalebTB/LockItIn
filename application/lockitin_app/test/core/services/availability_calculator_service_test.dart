import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/core/services/availability_calculator_service.dart';
import 'package:lockitin_app/data/models/event_model.dart';

void main() {
  late AvailabilityCalculatorService service;

  setUp(() {
    service = AvailabilityCalculatorService();
  });

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
}
