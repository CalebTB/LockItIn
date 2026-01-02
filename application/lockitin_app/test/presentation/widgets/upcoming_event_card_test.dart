import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/presentation/widgets/upcoming_event_card.dart';
import 'package:lockitin_app/data/models/event_model.dart';
import 'package:lockitin_app/core/theme/app_theme.dart';

void main() {
  EventModel createTestEvent({
    String id = 'event-1',
    String userId = 'user-1',
    String title = 'Test Event',
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    EventVisibility visibility = EventVisibility.private,
    EventCategory category = EventCategory.other,
    String? emoji,
  }) {
    return EventModel(
      id: id,
      userId: userId,
      title: title,
      description: description,
      startTime: startTime ?? DateTime(2025, 6, 15, 10, 0),
      endTime: endTime ?? DateTime(2025, 6, 15, 11, 0),
      location: location,
      visibility: visibility,
      category: category,
      emoji: emoji,
      createdAt: DateTime.now(),
    );
  }

  group('UpcomingEventCard Widget', () {
    Widget buildTestWidget(EventModel event, {
      VoidCallback? onTap,
      List<String>? attendeeInitials,
      int? additionalAttendees,
      String? statusBadge,
    }) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: UpcomingEventCard(
            event: event,
            onTap: onTap,
            attendeeInitials: attendeeInitials,
            additionalAttendees: additionalAttendees,
            statusBadge: statusBadge,
          ),
        ),
      );
    }

    testWidgets('should display event title', (tester) async {
      final event = createTestEvent(title: 'Team Meeting');
      await tester.pumpWidget(buildTestWidget(event));
      
      expect(find.text('Team Meeting'), findsOneWidget);
    });

    testWidgets('should display event time', (tester) async {
      final event = createTestEvent(
        startTime: DateTime(2025, 6, 15, 10, 0),
      );
      await tester.pumpWidget(buildTestWidget(event));
      
      // Should show formatted date and time
      expect(find.textContaining('Jun 15'), findsOneWidget);
    });

    testWidgets('should display location when provided', (tester) async {
      final event = createTestEvent(location: 'Room 101');
      await tester.pumpWidget(buildTestWidget(event));
      
      expect(find.text('Room 101'), findsOneWidget);
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    });

    testWidgets('should not display location when null', (tester) async {
      final event = createTestEvent(location: null);
      await tester.pumpWidget(buildTestWidget(event));
      
      expect(find.byIcon(Icons.location_on_outlined), findsNothing);
    });

    testWidgets('should display custom emoji when provided', (tester) async {
      final event = createTestEvent(emoji: '🎉');
      await tester.pumpWidget(buildTestWidget(event));
      
      expect(find.text('🎉'), findsOneWidget);
    });

    testWidgets('should display default category emoji when no custom emoji', (tester) async {
      final event = createTestEvent(category: EventCategory.work, emoji: null);
      await tester.pumpWidget(buildTestWidget(event));
      
      expect(find.text('💻'), findsOneWidget);
    });

    testWidgets('should be tappable when onTap is provided', (tester) async {
      bool tapped = false;
      final event = createTestEvent();
      
      await tester.pumpWidget(buildTestWidget(
        event,
        onTap: () => tapped = true,
      ));
      
      await tester.tap(find.byType(UpcomingEventCard));
      expect(tapped, true);
    });

    testWidgets('should display attendee avatars when provided', (tester) async {
      final event = createTestEvent();
      
      await tester.pumpWidget(buildTestWidget(
        event,
        attendeeInitials: ['JD', 'AS', 'BK'],
      ));
      
      expect(find.text('JD'), findsOneWidget);
      expect(find.text('AS'), findsOneWidget);
      expect(find.text('BK'), findsOneWidget);
    });

    testWidgets('should display additional attendees count', (tester) async {
      final event = createTestEvent();
      
      await tester.pumpWidget(buildTestWidget(
        event,
        attendeeInitials: ['JD'],
        additionalAttendees: 5,
      ));
      
      expect(find.text('+5 going'), findsOneWidget);
    });

    testWidgets('should display status badge when provided', (tester) async {
      final event = createTestEvent();
      
      await tester.pumpWidget(buildTestWidget(
        event,
        statusBadge: 'Pending',
      ));
      
      expect(find.text('Pending'), findsOneWidget);
    });
  });
}
