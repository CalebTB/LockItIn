import '../../data/models/event_model.dart';

/// Service for generating test events for development and testing
/// These events showcase different privacy levels and event types
class TestEventsService {
  /// Generate test events for the current month
  /// Includes events with different privacy levels and multiple events per day
  static List<EventModel> generateTestEvents() {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    return [
      // Day 5 - Multiple events (Private + Shared)
      EventModel(
        id: 'test-1',
        userId: 'test-user',
        title: 'Team Standup',
        description: 'Daily team sync meeting',
        startTime: DateTime(currentYear, currentMonth, 5, 9, 0),
        endTime: DateTime(currentYear, currentMonth, 5, 9, 30),
        location: 'Conference Room A',
        visibility: EventVisibility.sharedWithName,
        nativeCalendarId: null,
        createdAt: DateTime.now(),
      ),
      EventModel(
        id: 'test-2',
        userId: 'test-user',
        title: 'Doctor Appointment',
        description: 'Annual checkup',
        startTime: DateTime(currentYear, currentMonth, 5, 14, 0),
        endTime: DateTime(currentYear, currentMonth, 5, 15, 0),
        location: 'Medical Center',
        visibility: EventVisibility.private,
        nativeCalendarId: null,
        createdAt: DateTime.now(),
      ),

      // Day 10 - Busy event
      EventModel(
        id: 'test-3',
        userId: 'test-user',
        title: 'Personal Time',
        description: 'Private personal matters',
        startTime: DateTime(currentYear, currentMonth, 10, 10, 0),
        endTime: DateTime(currentYear, currentMonth, 10, 12, 0),
        location: null,
        visibility: EventVisibility.busyOnly,
        nativeCalendarId: null,
        createdAt: DateTime.now(),
      ),

      // Day 12 - Multiple shared events
      EventModel(
        id: 'test-4',
        userId: 'test-user',
        title: 'Lunch with Sarah',
        description: 'Catch up over lunch',
        startTime: DateTime(currentYear, currentMonth, 12, 12, 0),
        endTime: DateTime(currentYear, currentMonth, 12, 13, 0),
        location: 'Downtown Cafe',
        visibility: EventVisibility.sharedWithName,
        nativeCalendarId: null,
        createdAt: DateTime.now(),
      ),
      EventModel(
        id: 'test-5',
        userId: 'test-user',
        title: 'Project Deadline',
        description: 'Final submission for Q4 project',
        startTime: DateTime(currentYear, currentMonth, 12, 17, 0),
        endTime: DateTime(currentYear, currentMonth, 12, 18, 0),
        location: 'Office',
        visibility: EventVisibility.sharedWithName,
        nativeCalendarId: null,
        createdAt: DateTime.now(),
      ),

      // Day 15 - All-day private event
      EventModel(
        id: 'test-6',
        userId: 'test-user',
        title: 'Vacation Day',
        description: 'Taking the day off',
        startTime: DateTime(currentYear, currentMonth, 15, 0, 0),
        endTime: DateTime(currentYear, currentMonth, 15, 23, 59, 59),
        location: null,
        visibility: EventVisibility.private,
        nativeCalendarId: null,
        createdAt: DateTime.now(),
      ),

      // Day 18 - Multiple events (all types)
      EventModel(
        id: 'test-7',
        userId: 'test-user',
        title: 'Morning Workout',
        description: 'Gym session',
        startTime: DateTime(currentYear, currentMonth, 18, 6, 0),
        endTime: DateTime(currentYear, currentMonth, 18, 7, 0),
        location: 'Fitness Center',
        visibility: EventVisibility.private,
        nativeCalendarId: null,
        createdAt: DateTime.now(),
      ),
      EventModel(
        id: 'test-8',
        userId: 'test-user',
        title: 'Client Meeting',
        description: 'Quarterly review with client',
        startTime: DateTime(currentYear, currentMonth, 18, 10, 0),
        endTime: DateTime(currentYear, currentMonth, 18, 11, 30),
        location: 'Client Office',
        visibility: EventVisibility.sharedWithName,
        nativeCalendarId: null,
        createdAt: DateTime.now(),
      ),
      EventModel(
        id: 'test-9',
        userId: 'test-user',
        title: 'Busy',
        description: 'Confidential appointment',
        startTime: DateTime(currentYear, currentMonth, 18, 14, 0),
        endTime: DateTime(currentYear, currentMonth, 18, 16, 0),
        location: null,
        visibility: EventVisibility.busyOnly,
        nativeCalendarId: null,
        createdAt: DateTime.now(),
      ),

      // Day 22 - Shared event with long title
      EventModel(
        id: 'test-10',
        userId: 'test-user',
        title: 'Annual Company Holiday Party and Year-End Celebration',
        description: 'Join us for food, drinks, and festivities',
        startTime: DateTime(currentYear, currentMonth, 22, 18, 0),
        endTime: DateTime(currentYear, currentMonth, 22, 22, 0),
        location: 'Grand Ballroom, Downtown Hotel',
        visibility: EventVisibility.sharedWithName,
        nativeCalendarId: null,
        createdAt: DateTime.now(),
      ),

      // Day 27 - Private event
      EventModel(
        id: 'test-11',
        userId: 'test-user',
        title: 'Dentist Appointment',
        description: 'Teeth cleaning',
        startTime: DateTime(currentYear, currentMonth, 27, 9, 0),
        endTime: DateTime(currentYear, currentMonth, 27, 10, 0),
        location: 'Dental Clinic',
        visibility: EventVisibility.private,
        nativeCalendarId: null,
        createdAt: DateTime.now(),
      ),

      // Day 28 - Multiple events
      EventModel(
        id: 'test-12',
        userId: 'test-user',
        title: 'Coffee with Mike',
        description: 'Networking coffee',
        startTime: DateTime(currentYear, currentMonth, 28, 8, 0),
        endTime: DateTime(currentYear, currentMonth, 28, 9, 0),
        location: 'Starbucks',
        visibility: EventVisibility.sharedWithName,
        nativeCalendarId: null,
        createdAt: DateTime.now(),
      ),
      EventModel(
        id: 'test-13',
        userId: 'test-user',
        title: 'Personal Errands',
        description: null,
        startTime: DateTime(currentYear, currentMonth, 28, 15, 0),
        endTime: DateTime(currentYear, currentMonth, 28, 17, 0),
        location: null,
        visibility: EventVisibility.busyOnly,
        nativeCalendarId: null,
        createdAt: DateTime.now(),
      ),
    ];
  }

  /// Check if test events should be loaded
  /// Set this to true during development, false for production
  static const bool enableTestEvents = true;
}
