import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/data/models/event_model.dart';

void main() {
  group('EventVisibility Enum', () {
    test('should have all expected values', () {
      expect(EventVisibility.values.length, 3);
      expect(EventVisibility.values.contains(EventVisibility.private), true);
      expect(EventVisibility.values.contains(EventVisibility.sharedWithName), true);
      expect(EventVisibility.values.contains(EventVisibility.busyOnly), true);
    });
  });

  group('EventCategory Enum', () {
    test('should have all expected values', () {
      expect(EventCategory.values.length, 4);
      expect(EventCategory.values.contains(EventCategory.work), true);
      expect(EventCategory.values.contains(EventCategory.holiday), true);
      expect(EventCategory.values.contains(EventCategory.friend), true);
      expect(EventCategory.values.contains(EventCategory.other), true);
    });
  });

  group('EventModel', () {
    final testDate = DateTime(2025, 6, 15, 10, 0);
    final testEndDate = DateTime(2025, 6, 15, 11, 0);

    EventModel createTestEvent({
      String id = 'event-123',
      String userId = 'user-456',
      String title = 'Test Event',
      String? description,
      DateTime? startTime,
      DateTime? endTime,
      String? location,
      EventVisibility visibility = EventVisibility.private,
      EventCategory category = EventCategory.other,
      String? emoji,
      String? nativeCalendarId,
      DateTime? createdAt,
      DateTime? updatedAt,
    }) {
      return EventModel(
        id: id,
        userId: userId,
        title: title,
        description: description,
        startTime: startTime ?? testDate,
        endTime: endTime ?? testEndDate,
        location: location,
        visibility: visibility,
        category: category,
        emoji: emoji,
        nativeCalendarId: nativeCalendarId,
        createdAt: createdAt ?? testDate,
        updatedAt: updatedAt,
      );
    }

    group('Constructor', () {
      test('should create EventModel with required fields', () {
        final event = createTestEvent();

        expect(event.id, 'event-123');
        expect(event.userId, 'user-456');
        expect(event.title, 'Test Event');
        expect(event.startTime, testDate);
        expect(event.endTime, testEndDate);
        expect(event.visibility, EventVisibility.private);
        expect(event.category, EventCategory.other);
      });

      test('should have null optional fields by default', () {
        final event = createTestEvent();

        expect(event.description, isNull);
        expect(event.location, isNull);
        expect(event.emoji, isNull);
        expect(event.nativeCalendarId, isNull);
        expect(event.updatedAt, isNull);
      });

      test('should accept all optional fields', () {
        final event = createTestEvent(
          description: 'Test description',
          location: 'Test location',
          emoji: '🎉',
          nativeCalendarId: 'native-123',
          updatedAt: testDate,
        );

        expect(event.description, 'Test description');
        expect(event.location, 'Test location');
        expect(event.emoji, '🎉');
        expect(event.nativeCalendarId, 'native-123');
        expect(event.updatedAt, testDate);
      });
    });

    group('fromJson', () {
      test('should parse complete JSON correctly', () {
        final json = {
          'id': 'event-123',
          'user_id': 'user-456',
          'title': 'Meeting',
          'description': 'Team sync',
          'start_time': '2025-06-15T10:00:00.000Z',
          'end_time': '2025-06-15T11:00:00.000Z',
          'location': 'Room A',
          'visibility': 'private',
          'category': 'work',
          'native_calendar_id': 'native-123',
          'created_at': '2025-06-15T09:00:00.000Z',
          'updated_at': '2025-06-15T09:30:00.000Z',
        };

        final event = EventModel.fromJson(json);

        expect(event.id, 'event-123');
        expect(event.userId, 'user-456');
        expect(event.title, 'Meeting');
        expect(event.description, 'Team sync');
        expect(event.location, 'Room A');
        expect(event.visibility, EventVisibility.private);
        expect(event.category, EventCategory.work);
        expect(event.nativeCalendarId, 'native-123');
      });

      test('should parse all visibility values', () {
        final baseJson = {
          'id': 'e1',
          'user_id': 'u1',
          'title': 'T',
          'start_time': '2025-06-15T10:00:00.000Z',
          'end_time': '2025-06-15T11:00:00.000Z',
          'created_at': '2025-06-15T09:00:00.000Z',
        };

        final privateEvent = EventModel.fromJson({...baseJson, 'visibility': 'private'});
        final sharedEvent = EventModel.fromJson({...baseJson, 'visibility': 'shared_with_name'});
        final busyEvent = EventModel.fromJson({...baseJson, 'visibility': 'busy_only'});

        expect(privateEvent.visibility, EventVisibility.private);
        expect(sharedEvent.visibility, EventVisibility.sharedWithName);
        expect(busyEvent.visibility, EventVisibility.busyOnly);
      });

      test('should default to private for unknown visibility', () {
        final json = {
          'id': 'e1',
          'user_id': 'u1',
          'title': 'T',
          'start_time': '2025-06-15T10:00:00.000Z',
          'end_time': '2025-06-15T11:00:00.000Z',
          'visibility': 'unknown_value',
          'created_at': '2025-06-15T09:00:00.000Z',
        };

        final event = EventModel.fromJson(json);
        expect(event.visibility, EventVisibility.private);
      });

      test('should parse all category values', () {
        final baseJson = {
          'id': 'e1',
          'user_id': 'u1',
          'title': 'T',
          'start_time': '2025-06-15T10:00:00.000Z',
          'end_time': '2025-06-15T11:00:00.000Z',
          'visibility': 'private',
          'created_at': '2025-06-15T09:00:00.000Z',
        };

        final workEvent = EventModel.fromJson({...baseJson, 'category': 'work'});
        final holidayEvent = EventModel.fromJson({...baseJson, 'category': 'holiday'});
        final friendEvent = EventModel.fromJson({...baseJson, 'category': 'friend'});
        final otherEvent = EventModel.fromJson({...baseJson, 'category': 'other'});

        expect(workEvent.category, EventCategory.work);
        expect(holidayEvent.category, EventCategory.holiday);
        expect(friendEvent.category, EventCategory.friend);
        expect(otherEvent.category, EventCategory.other);
      });

      test('should default to other for null category', () {
        final json = {
          'id': 'e1',
          'user_id': 'u1',
          'title': 'T',
          'start_time': '2025-06-15T10:00:00.000Z',
          'end_time': '2025-06-15T11:00:00.000Z',
          'visibility': 'private',
          'category': null,
          'created_at': '2025-06-15T09:00:00.000Z',
        };

        final event = EventModel.fromJson(json);
        expect(event.category, EventCategory.other);
      });

      test('should handle null optional fields', () {
        final json = {
          'id': 'e1',
          'user_id': 'u1',
          'title': 'T',
          'start_time': '2025-06-15T10:00:00.000Z',
          'end_time': '2025-06-15T11:00:00.000Z',
          'visibility': 'private',
          'description': null,
          'location': null,
          'native_calendar_id': null,
          'updated_at': null,
          'created_at': '2025-06-15T09:00:00.000Z',
        };

        final event = EventModel.fromJson(json);
        expect(event.description, isNull);
        expect(event.location, isNull);
        expect(event.nativeCalendarId, isNull);
        expect(event.updatedAt, isNull);
      });
    });

    group('toJson', () {
      test('should serialize to JSON correctly', () {
        final event = createTestEvent(
          description: 'Desc',
          location: 'Loc',
          nativeCalendarId: 'native-1',
        );

        final json = event.toJson();

        expect(json['id'], 'event-123');
        expect(json['user_id'], 'user-456');
        expect(json['title'], 'Test Event');
        expect(json['description'], 'Desc');
        expect(json['location'], 'Loc');
        expect(json['visibility'], 'private');
        expect(json['category'], 'other');
        expect(json['native_calendar_id'], 'native-1');
      });

      test('should serialize all visibility values', () {
        final privateEvent = createTestEvent(visibility: EventVisibility.private);
        final sharedEvent = createTestEvent(visibility: EventVisibility.sharedWithName);
        final busyEvent = createTestEvent(visibility: EventVisibility.busyOnly);

        expect(privateEvent.toJson()['visibility'], 'private');
        expect(sharedEvent.toJson()['visibility'], 'shared_with_name');
        expect(busyEvent.toJson()['visibility'], 'busy_only');
      });

      test('should serialize all category values', () {
        final workEvent = createTestEvent(category: EventCategory.work);
        final holidayEvent = createTestEvent(category: EventCategory.holiday);
        final friendEvent = createTestEvent(category: EventCategory.friend);
        final otherEvent = createTestEvent(category: EventCategory.other);

        expect(workEvent.toJson()['category'], 'work');
        expect(holidayEvent.toJson()['category'], 'holiday');
        expect(friendEvent.toJson()['category'], 'friend');
        expect(otherEvent.toJson()['category'], 'other');
      });

      test('should include null for missing optional fields', () {
        final event = createTestEvent();
        final json = event.toJson();

        expect(json['description'], isNull);
        expect(json['location'], isNull);
        expect(json['updated_at'], isNull);
      });
    });

    group('copyWith', () {
      test('should create copy with updated title', () {
        final original = createTestEvent();
        final copy = original.copyWith(title: 'New Title');

        expect(copy.title, 'New Title');
        expect(copy.id, original.id); // unchanged
        expect(copy.userId, original.userId); // unchanged
      });

      test('should create copy with updated visibility', () {
        final original = createTestEvent(visibility: EventVisibility.private);
        final copy = original.copyWith(visibility: EventVisibility.sharedWithName);

        expect(copy.visibility, EventVisibility.sharedWithName);
        expect(copy.title, original.title); // unchanged
      });

      test('should create copy with updated category', () {
        final original = createTestEvent(category: EventCategory.other);
        final copy = original.copyWith(category: EventCategory.work);

        expect(copy.category, EventCategory.work);
      });

      test('should create copy with updated times', () {
        final original = createTestEvent();
        final newStart = DateTime(2025, 7, 1, 14, 0);
        final newEnd = DateTime(2025, 7, 1, 15, 0);

        final copy = original.copyWith(startTime: newStart, endTime: newEnd);

        expect(copy.startTime, newStart);
        expect(copy.endTime, newEnd);
      });

      test('should preserve all fields when no changes specified', () {
        final original = createTestEvent(
          description: 'Desc',
          location: 'Loc',
          emoji: '🎉',
          nativeCalendarId: 'native-1',
        );
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.userId, original.userId);
        expect(copy.title, original.title);
        expect(copy.description, original.description);
        expect(copy.location, original.location);
        expect(copy.emoji, original.emoji);
        expect(copy.nativeCalendarId, original.nativeCalendarId);
        expect(copy.visibility, original.visibility);
        expect(copy.category, original.category);
      });
    });

    group('Equatable', () {
      test('two events with same properties should be equal', () {
        final event1 = createTestEvent();
        final event2 = createTestEvent();

        expect(event1, equals(event2));
      });

      test('two events with different ids should not be equal', () {
        final event1 = createTestEvent(id: 'event-1');
        final event2 = createTestEvent(id: 'event-2');

        expect(event1, isNot(equals(event2)));
      });

      test('two events with different titles should not be equal', () {
        final event1 = createTestEvent(title: 'Title 1');
        final event2 = createTestEvent(title: 'Title 2');

        expect(event1, isNot(equals(event2)));
      });

      test('props should include all fields', () {
        final event = createTestEvent();

        expect(event.props.length, 13);
        expect(event.props.contains(event.id), true);
        expect(event.props.contains(event.title), true);
        expect(event.props.contains(event.visibility), true);
        expect(event.props.contains(event.category), true);
      });
    });

    group('JSON Round Trip', () {
      test('should survive JSON serialization and deserialization', () {
        final original = createTestEvent(
          description: 'Description',
          location: 'Location',
          visibility: EventVisibility.sharedWithName,
          category: EventCategory.work,
          nativeCalendarId: 'native-123',
        );

        final json = original.toJson();
        final restored = EventModel.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.userId, original.userId);
        expect(restored.title, original.title);
        expect(restored.description, original.description);
        expect(restored.location, original.location);
        expect(restored.visibility, original.visibility);
        expect(restored.category, original.category);
        expect(restored.nativeCalendarId, original.nativeCalendarId);
      });
    });
  });
}
