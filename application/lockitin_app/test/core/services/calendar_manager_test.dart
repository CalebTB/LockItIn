import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/core/services/calendar_manager.dart';
import 'package:lockitin_app/data/models/event_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CalendarManager', () {
    late CalendarManager calendarManager;
    const MethodChannel channel = MethodChannel('com.lockitin.calendar');

    setUp(() {
      calendarManager = CalendarManager();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    group('Permission Management', () {
      test('requestPermission returns granted status', () async {
        // Mock the method channel response
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'requestPermission') {
            return 'granted';
          }
          return null;
        });

        final result = await calendarManager.requestPermission();

        expect(result, CalendarPermissionStatus.granted);
      });

      test('requestPermission returns denied status', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'requestPermission') {
            return 'denied';
          }
          return null;
        });

        final result = await calendarManager.requestPermission();

        expect(result, CalendarPermissionStatus.denied);
      });

      test('checkPermission returns current status', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'checkPermission') {
            return 'granted';
          }
          return null;
        });

        final result = await calendarManager.checkPermission();

        expect(result, CalendarPermissionStatus.granted);
      });

      test('requestPermission throws CalendarAccessException on error',
          () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'requestPermission') {
            throw PlatformException(
              code: 'PERMISSION_ERROR',
              message: 'Failed to request permission',
            );
          }
          return null;
        });

        expect(
          () => calendarManager.requestPermission(),
          throwsA(isA<CalendarAccessException>()),
        );
      });
    });

    group('Fetch Events', () {
      test('fetchEvents returns list of events', () async {
        final startDate = DateTime(2025, 1, 1);
        final endDate = DateTime(2025, 1, 31);

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'fetchEvents') {
            return [
              {
                'nativeEventId': '1',
                'title': 'Test Event 1',
                'description': 'Test Description',
                'startTime': DateTime(2025, 1, 15, 10, 0).millisecondsSinceEpoch,
                'endTime': DateTime(2025, 1, 15, 11, 0).millisecondsSinceEpoch,
                'location': 'Test Location',
              },
              {
                'nativeEventId': '2',
                'title': 'Test Event 2',
                'description': null,
                'startTime': DateTime(2025, 1, 20, 14, 0).millisecondsSinceEpoch,
                'endTime': DateTime(2025, 1, 20, 15, 0).millisecondsSinceEpoch,
                'location': null,
              },
            ];
          }
          return null;
        });

        final events = await calendarManager.fetchEvents(
          startDate: startDate,
          endDate: endDate,
        );

        expect(events, hasLength(2));
        expect(events[0].title, 'Test Event 1');
        expect(events[0].nativeCalendarId, '1');
        expect(events[0].location, 'Test Location');
        expect(events[1].title, 'Test Event 2');
        expect(events[1].nativeCalendarId, '2');
      });

      test('fetchEvents throws CalendarAccessException when permission denied',
          () async {
        final startDate = DateTime(2025, 1, 1);
        final endDate = DateTime(2025, 1, 31);

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'fetchEvents') {
            throw PlatformException(
              code: 'PERMISSION_DENIED',
              message: 'Calendar access denied',
            );
          }
          return null;
        });

        expect(
          () => calendarManager.fetchEvents(
            startDate: startDate,
            endDate: endDate,
          ),
          throwsA(isA<CalendarAccessException>()),
        );
      });

      test('fetchEvents handles empty event list', () async {
        final startDate = DateTime(2025, 1, 1);
        final endDate = DateTime(2025, 1, 31);

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'fetchEvents') {
            return [];
          }
          return null;
        });

        final events = await calendarManager.fetchEvents(
          startDate: startDate,
          endDate: endDate,
        );

        expect(events, isEmpty);
      });
    });

    group('Create Event', () {
      test('createEvent returns native event ID', () async {
        final event = EventModel(
          id: 'test-id',
          userId: 'user-id',
          title: 'New Event',
          description: 'Event Description',
          startTime: DateTime(2025, 1, 15, 10, 0),
          endTime: DateTime(2025, 1, 15, 11, 0),
          location: 'Office',
          visibility: EventVisibility.private,
          createdAt: DateTime.now(),
        );

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'createEvent') {
            expect(methodCall.arguments['title'], 'New Event');
            expect(methodCall.arguments['description'], 'Event Description');
            expect(methodCall.arguments['location'], 'Office');
            return 'native-event-123';
          }
          return null;
        });

        final nativeEventId = await calendarManager.createEvent(event);

        expect(nativeEventId, 'native-event-123');
      });

      test('createEvent throws CalendarAccessException on error', () async {
        final event = EventModel(
          id: 'test-id',
          userId: 'user-id',
          title: 'New Event',
          startTime: DateTime(2025, 1, 15, 10, 0),
          endTime: DateTime(2025, 1, 15, 11, 0),
          visibility: EventVisibility.private,
          createdAt: DateTime.now(),
        );

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'createEvent') {
            throw PlatformException(
              code: 'CREATE_FAILED',
              message: 'Failed to create event',
            );
          }
          return null;
        });

        expect(
          () => calendarManager.createEvent(event),
          throwsA(isA<CalendarAccessException>()),
        );
      });
    });

    group('Update Event', () {
      test('updateEvent updates existing event', () async {
        final event = EventModel(
          id: 'test-id',
          userId: 'user-id',
          title: 'Updated Event',
          startTime: DateTime(2025, 1, 15, 10, 0),
          endTime: DateTime(2025, 1, 15, 11, 0),
          visibility: EventVisibility.private,
          nativeCalendarId: 'native-123',
          createdAt: DateTime.now(),
        );

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'updateEvent') {
            expect(methodCall.arguments['nativeEventId'], 'native-123');
            expect(methodCall.arguments['title'], 'Updated Event');
            return null;
          }
          return null;
        });

        await calendarManager.updateEvent(event);
        // Should complete without throwing
      });

      test('updateEvent throws exception when nativeCalendarId is null',
          () async {
        final event = EventModel(
          id: 'test-id',
          userId: 'user-id',
          title: 'Event',
          startTime: DateTime(2025, 1, 15, 10, 0),
          endTime: DateTime(2025, 1, 15, 11, 0),
          visibility: EventVisibility.private,
          createdAt: DateTime.now(),
        );

        expect(
          () => calendarManager.updateEvent(event),
          throwsA(isA<CalendarAccessException>()),
        );
      });
    });

    group('Delete Event', () {
      test('deleteEvent deletes event by native ID', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'deleteEvent') {
            expect(methodCall.arguments['nativeEventId'], 'native-123');
            return null;
          }
          return null;
        });

        await calendarManager.deleteEvent('native-123');
        // Should complete without throwing
      });

      test('deleteEvent throws CalendarAccessException on error', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'deleteEvent') {
            throw PlatformException(
              code: 'DELETE_FAILED',
              message: 'Event not found',
            );
          }
          return null;
        });

        expect(
          () => calendarManager.deleteEvent('native-123'),
          throwsA(isA<CalendarAccessException>()),
        );
      });
    });
  });
}
