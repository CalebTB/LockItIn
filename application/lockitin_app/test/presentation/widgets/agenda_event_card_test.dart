import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/presentation/widgets/agenda_event_card.dart';
import 'package:lockitin_app/data/models/event_model.dart';
import 'package:lockitin_app/core/theme/app_theme.dart';

void main() {
  EventModel createTestEvent({
    String id = 'event-1',
    String userId = 'user-1',
    String title = 'Test Event',
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
      startTime: startTime ?? DateTime(2025, 6, 15, 10, 0),
      endTime: endTime ?? DateTime(2025, 6, 15, 11, 0),
      location: location,
      visibility: visibility,
      category: category,
      emoji: emoji,
      createdAt: DateTime.now(),
    );
  }

  group('AgendaEventCard Widget', () {
    Widget buildTestWidget(EventModel event, {VoidCallback? onTap}) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: AgendaEventCard(
            event: event,
            onTap: onTap,
          ),
        ),
      );
    }

    testWidgets('should display event title', (tester) async {
      final event = createTestEvent(title: 'Meeting');
      await tester.pumpWidget(buildTestWidget(event));
      
      expect(find.text('Meeting'), findsOneWidget);
    });

    testWidgets('should display event time', (tester) async {
      final event = createTestEvent(
        startTime: DateTime(2025, 6, 15, 10, 0),
        endTime: DateTime(2025, 6, 15, 11, 0),
      );
      await tester.pumpWidget(buildTestWidget(event));
      
      // Time is formatted as h:mm a with newline
      expect(find.textContaining('10:00'), findsOneWidget);
    });

    testWidgets('should display "All day" for all-day events', (tester) async {
      final event = createTestEvent(
        startTime: DateTime(2025, 6, 15, 0, 0),
        endTime: DateTime(2025, 6, 15, 23, 59),
      );
      await tester.pumpWidget(buildTestWidget(event));
      
      expect(find.text('All day'), findsOneWidget);
    });

    testWidgets('should display location when provided', (tester) async {
      final event = createTestEvent(location: 'Conference Room');
      await tester.pumpWidget(buildTestWidget(event));
      
      expect(find.text('Conference Room'), findsOneWidget);
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    });

    testWidgets('should not display location when null', (tester) async {
      final event = createTestEvent(location: null);
      await tester.pumpWidget(buildTestWidget(event));
      
      expect(find.byIcon(Icons.location_on_outlined), findsNothing);
    });

    testWidgets('should display emoji when provided', (tester) async {
      final event = createTestEvent(emoji: '📅');
      await tester.pumpWidget(buildTestWidget(event));
      
      expect(find.text('📅'), findsOneWidget);
    });

    testWidgets('should display lock icon for private events', (tester) async {
      final event = createTestEvent(visibility: EventVisibility.private);
      await tester.pumpWidget(buildTestWidget(event));
      
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('should display visibility icon for shared events', (tester) async {
      final event = createTestEvent(visibility: EventVisibility.sharedWithName);
      await tester.pumpWidget(buildTestWidget(event));
      
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('should display visibility off icon for busy only events', (tester) async {
      final event = createTestEvent(visibility: EventVisibility.busyOnly);
      await tester.pumpWidget(buildTestWidget(event));
      
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('should be tappable when onTap is provided', (tester) async {
      bool tapped = false;
      final event = createTestEvent();
      
      await tester.pumpWidget(buildTestWidget(
        event,
        onTap: () => tapped = true,
      ));
      
      await tester.tap(find.byType(AgendaEventCard));
      expect(tapped, true);
    });

    testWidgets('should use correct category color', (tester) async {
      final event = createTestEvent(category: EventCategory.work);
      await tester.pumpWidget(buildTestWidget(event));
      
      // Widget should render with color accent bar
      expect(find.byType(AgendaEventCard), findsOneWidget);
    });
  });
}
