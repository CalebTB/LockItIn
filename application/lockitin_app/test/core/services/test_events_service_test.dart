import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/core/services/test_events_service.dart';
import 'package:lockitin_app/data/models/event_model.dart';

void main() {
  group('TestEventsService', () {
    late List<EventModel> events;

    setUp(() {
      events = TestEventsService.generateTestEvents();
    });

    group('generateTestEvents', () {
      test('should return a non-empty list', () {
        expect(events, isNotEmpty);
      });

      test('should return EventModel instances', () {
        for (final event in events) {
          expect(event, isA<EventModel>());
        }
      });

      test('should have unique IDs for all events', () {
        final ids = events.map((e) => e.id).toSet();
        expect(ids.length, equals(events.length));
      });

      test('should use test-user as userId for all events', () {
        for (final event in events) {
          expect(event.userId, equals('test-user'));
        }
      });

      test('should have events in the current month', () {
        final now = DateTime.now();
        for (final event in events) {
          expect(event.startTime.year, equals(now.year));
          expect(event.startTime.month, equals(now.month));
        }
      });

      test('should have valid time ranges (end after start)', () {
        for (final event in events) {
          expect(
            event.endTime.isAfter(event.startTime) ||
                event.endTime.isAtSameMomentAs(event.startTime),
            isTrue,
            reason: 'Event ${event.id} should have end time >= start time',
          );
        }
      });
    });

    group('Event Visibility', () {
      test('should have events with private visibility', () {
        final privateEvents = events
            .where((e) => e.visibility == EventVisibility.private)
            .toList();
        expect(privateEvents, isNotEmpty);
      });

      test('should have events with sharedWithName visibility', () {
        final sharedEvents = events
            .where((e) => e.visibility == EventVisibility.sharedWithName)
            .toList();
        expect(sharedEvents, isNotEmpty);
      });

      test('should have events with busyOnly visibility', () {
        final busyOnlyEvents = events
            .where((e) => e.visibility == EventVisibility.busyOnly)
            .toList();
        expect(busyOnlyEvents, isNotEmpty);
      });
    });

    group('Event Categories', () {
      test('should have work events', () {
        final workEvents = events
            .where((e) => e.category == EventCategory.work)
            .toList();
        expect(workEvents, isNotEmpty);
      });

      test('should have friend events', () {
        final friendEvents = events
            .where((e) => e.category == EventCategory.friend)
            .toList();
        expect(friendEvents, isNotEmpty);
      });

      test('should have holiday events', () {
        final holidayEvents = events
            .where((e) => e.category == EventCategory.holiday)
            .toList();
        expect(holidayEvents, isNotEmpty);
      });

      test('should have other category events', () {
        final otherEvents = events
            .where((e) => e.category == EventCategory.other)
            .toList();
        expect(otherEvents, isNotEmpty);
      });
    });

    group('Event Properties', () {
      test('should have events with titles', () {
        for (final event in events) {
          expect(event.title, isNotEmpty);
        }
      });

      test('should have events with descriptions', () {
        final eventsWithDescriptions = events
            .where((e) => e.description != null && e.description!.isNotEmpty)
            .toList();
        expect(eventsWithDescriptions, isNotEmpty);
      });

      test('should have events with locations', () {
        final eventsWithLocations = events
            .where((e) => e.location != null && e.location!.isNotEmpty)
            .toList();
        expect(eventsWithLocations, isNotEmpty);
      });

      test('should have createdAt set for all events', () {
        for (final event in events) {
          expect(event.createdAt, isNotNull);
        }
      });

      test('should have null nativeCalendarId for all events', () {
        for (final event in events) {
          expect(event.nativeCalendarId, isNull);
        }
      });
    });

    group('Multiple Events Per Day', () {
      test('should have at least one day with multiple events', () {
        final eventsByDay = <int, List<EventModel>>{};
        for (final event in events) {
          final day = event.startTime.day;
          eventsByDay.putIfAbsent(day, () => []).add(event);
        }

        final daysWithMultipleEvents = eventsByDay.values
            .where((dayEvents) => dayEvents.length > 1)
            .toList();
        expect(daysWithMultipleEvents, isNotEmpty);
      });

      test('day 20 should have many events (overflow test)', () {
        final day20Events = events
            .where((e) => e.startTime.day == 20)
            .toList();
        expect(day20Events.length, greaterThanOrEqualTo(5));
      });
    });

    group('All-Day Events', () {
      test('should have at least one all-day event', () {
        final allDayEvents = events.where((e) {
          return e.startTime.hour == 0 &&
              e.startTime.minute == 0 &&
              e.endTime.hour == 23 &&
              e.endTime.minute == 59;
        }).toList();
        expect(allDayEvents, isNotEmpty);
      });
    });

    group('enableTestEvents', () {
      test('should be a boolean constant', () {
        expect(TestEventsService.enableTestEvents, isA<bool>());
      });

      test('should be false for production', () {
        // This is the expected production value
        expect(TestEventsService.enableTestEvents, isFalse);
      });
    });
  });
}
