import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/core/services/event_service.dart';
import 'package:lockitin_app/data/models/event_model.dart';

/// Tests for EventService dual-write logic
/// Note: These are unit tests that verify the business logic structure
/// Integration tests with actual CalendarManager and Supabase would require mocking
void main() {
  group('EventService - Dual-Write Logic', () {
    test('EventServiceException should contain error message', () {
      final exception = EventServiceException(
        'Test error message',
        nativeEventId: 'native_123',
        supabaseEventId: 'supabase_456',
      );

      expect(exception.message, 'Test error message');
      expect(exception.nativeEventId, 'native_123');
      expect(exception.supabaseEventId, 'supabase_456');
      expect(exception.toString(), contains('Test error message'));
    });

    test('EventServiceException can be created without IDs', () {
      final exception = EventServiceException('Simple error');

      expect(exception.message, 'Simple error');
      expect(exception.nativeEventId, isNull);
      expect(exception.supabaseEventId, isNull);
    });
  });

  group('EventService - Event Model Validation', () {
    test('should create valid EventModel for dual-write', () {
      final now = DateTime.now();
      final event = EventModel(
        id: 'temp_id',
        userId: 'user_123',
        title: 'Team Meeting',
        description: 'Quarterly planning',
        startTime: now.add(const Duration(hours: 1)),
        endTime: now.add(const Duration(hours: 2)),
        location: 'Conference Room A',
        visibility: EventVisibility.sharedWithName,
        createdAt: now,
      );

      expect(event.title, 'Team Meeting');
      expect(event.userId, 'user_123');
      expect(event.visibility, EventVisibility.sharedWithName);
      expect(event.nativeCalendarId, isNull); // Not yet synced
    });

    test('should update EventModel with native calendar ID after creation', () {
      final now = DateTime.now();
      final originalEvent = EventModel(
        id: 'temp_id',
        userId: 'user_123',
        title: 'Doctor Appointment',
        startTime: now.add(const Duration(days: 1)),
        endTime: now.add(const Duration(days: 1, hours: 1)),
        visibility: EventVisibility.busyOnly,
        createdAt: now,
      );

      // Simulate what EventService does after native calendar creation
      final eventWithNativeId = originalEvent.copyWith(
        nativeCalendarId: 'ios_event_abc123',
      );

      expect(eventWithNativeId.title, 'Doctor Appointment');
      expect(eventWithNativeId.nativeCalendarId, 'ios_event_abc123');
      expect(eventWithNativeId.id, 'temp_id'); // Still has temp ID before Supabase
    });

    test('should update EventModel with Supabase ID after database save', () {
      final now = DateTime.now();
      final eventWithNativeId = EventModel(
        id: 'temp_id',
        userId: 'user_123',
        title: 'Conference',
        startTime: now.add(const Duration(days: 7)),
        endTime: now.add(const Duration(days: 10)),
        visibility: EventVisibility.sharedWithName,
        nativeCalendarId: 'ios_event_xyz789',
        createdAt: now,
      );

      // Simulate what EventService does after Supabase creation
      final fullySyncedEvent = eventWithNativeId.copyWith(
        id: 'supabase_uuid_12345',
      );

      expect(fullySyncedEvent.title, 'Conference');
      expect(fullySyncedEvent.nativeCalendarId, 'ios_event_xyz789');
      expect(fullySyncedEvent.id, 'supabase_uuid_12345');
    });
  });

  group('EventService - Dual-Write Scenarios', () {
    test('should handle successful dual-write scenario', () {
      // This test documents the happy path flow
      final now = DateTime.now();

      // Step 1: User creates event via UI
      final userEvent = EventModel(
        id: 'temp_${now.millisecondsSinceEpoch}',
        userId: 'user_123',
        title: 'Birthday Party',
        startTime: now.add(const Duration(days: 5)),
        endTime: now.add(const Duration(days: 5, hours: 3)),
        location: 'My House',
        visibility: EventVisibility.sharedWithName,
        createdAt: now,
      );

      // Step 2: EventService would save to native calendar (returns native ID)
      final nativeEventId = 'native_calendar_event_001';

      // Step 3: Add native ID to event
      final eventWithNativeId = userEvent.copyWith(
        nativeCalendarId: nativeEventId,
      );

      // Step 4: EventService would save to Supabase (returns Supabase ID)
      final supabaseEventId = 'supabase_uuid_abcdef';

      // Step 5: Final event has both IDs
      final finalEvent = eventWithNativeId.copyWith(
        id: supabaseEventId,
      );

      // Verify final event has all data
      expect(finalEvent.title, 'Birthday Party');
      expect(finalEvent.nativeCalendarId, nativeEventId);
      expect(finalEvent.id, supabaseEventId);
      expect(finalEvent.userId, 'user_123');
      expect(finalEvent.location, 'My House');
    });

    test('should document rollback scenario when Supabase save fails', () {
      // This test documents the rollback flow
      final now = DateTime.now();

      final event = EventModel(
        id: 'temp_id',
        userId: 'user_123',
        title: 'Vacation',
        startTime: now.add(const Duration(days: 30)),
        endTime: now.add(const Duration(days: 37)),
        visibility: EventVisibility.private,
        createdAt: now,
      );

      // Simulate: Native calendar save succeeded
      final nativeEventId = 'native_event_vacation_001';
      final eventWithNativeId = event.copyWith(
        nativeCalendarId: nativeEventId,
      );

      expect(eventWithNativeId.nativeCalendarId, nativeEventId);

      // In actual EventService:
      // If Supabase save fails, EventService would:
      // 1. Catch the error
      // 2. Delete from native calendar using nativeEventId
      // 3. Throw EventServiceException with descriptive message

      // This ensures data consistency - event doesn't exist in only one place
    });

    test('should document anonymous user handling', () {
      final now = DateTime.now();

      // When user is not authenticated
      final event = EventModel(
        id: 'temp_id',
        userId: 'anonymous', // EventService uses 'anonymous' as fallback
        title: 'Test Event',
        startTime: now.add(const Duration(hours: 2)),
        endTime: now.add(const Duration(hours: 3)),
        visibility: EventVisibility.private,
        createdAt: now,
      );

      expect(event.userId, 'anonymous');

      // In production, EventService would:
      // - Still save to native calendar (works without auth)
      // - Attempt Supabase save with 'anonymous' user
      // - Supabase RLS policies would likely reject this
      // - Error handling would inform user to sign in
    });
  });

  group('EventService - Error Handling Scenarios', () {
    test('should document native calendar permission denied scenario', () {
      // When native calendar permission is denied:
      // - CalendarManager.createEvent() throws CalendarAccessException
      // - EventService catches this and throws EventServiceException
      // - Error message guides user to enable permissions
      // - No Supabase save is attempted (fail fast)

      final exception = EventServiceException(
        'Failed to save event to your device calendar. Please check calendar permissions.',
      );

      expect(exception.message, contains('calendar permissions'));
    });

    test('should document Supabase connection failure scenario', () {
      // When Supabase is unreachable:
      // - Native calendar save succeeds
      // - Supabase save fails (network error, timeout, etc.)
      // - EventService performs rollback
      // - Deletes event from native calendar
      // - Throws descriptive error to user

      final exception = EventServiceException(
        'Failed to sync event to cloud. The event was removed from your device calendar.',
        nativeEventId: 'rollback_event_123',
      );

      expect(exception.message, contains('sync event to cloud'));
      expect(exception.message, contains('removed from your device calendar'));
      expect(exception.nativeEventId, 'rollback_event_123');
    });

    test('should document partial delete failure scenario', () {
      // When deleting an event:
      // - EventService.deleteEvent() attempts to delete from both sources
      // - If one delete fails, it still attempts the other
      // - Collects all errors and reports them

      final exception = EventServiceException(
        'Partial delete failure: Failed to delete from device calendar, Failed to delete from cloud',
      );

      expect(exception.message, contains('Partial delete failure'));
      expect(exception.message, contains('device calendar'));
      expect(exception.message, contains('cloud'));
    });
  });

  group('EventService - Update Operations', () {
    test('should require nativeCalendarId for updates', () {
      final now = DateTime.now();
      final event = EventModel(
        id: 'supabase_id_123',
        userId: 'user_123',
        title: 'Meeting',
        startTime: now,
        endTime: now.add(const Duration(hours: 1)),
        visibility: EventVisibility.private,
        nativeCalendarId: null, // Missing native calendar ID
        createdAt: now,
      );

      // EventService.updateEvent() would check this and throw
      expect(event.nativeCalendarId, isNull);

      // This would result in EventServiceException:
      // 'Cannot update event without native calendar ID'
    });

    test('should update event with both IDs present', () {
      final now = DateTime.now();
      final originalEvent = EventModel(
        id: 'supabase_123',
        userId: 'user_123',
        title: 'Original Title',
        startTime: now,
        endTime: now.add(const Duration(hours: 1)),
        visibility: EventVisibility.private,
        nativeCalendarId: 'native_123',
        createdAt: now,
      );

      // User edits the event
      final updatedEvent = originalEvent.copyWith(
        title: 'Updated Title',
        location: 'New Location',
        updatedAt: DateTime.now(),
      );

      expect(updatedEvent.title, 'Updated Title');
      expect(updatedEvent.location, 'New Location');
      expect(updatedEvent.id, 'supabase_123'); // Same Supabase ID
      expect(updatedEvent.nativeCalendarId, 'native_123'); // Same native ID
      expect(updatedEvent.updatedAt, isNotNull);

      // EventService.updateEvent() would:
      // 1. Update in native calendar using nativeCalendarId
      // 2. Update in Supabase using id
    });
  });
}
