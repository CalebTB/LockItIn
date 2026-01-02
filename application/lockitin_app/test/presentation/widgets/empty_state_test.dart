import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/presentation/widgets/empty_state.dart';
import 'package:lockitin_app/core/theme/app_colors.dart';
import 'package:lockitin_app/core/theme/app_theme.dart';

void main() {
  group('EmptyStateType Enum', () {
    test('should have all expected values', () {
      expect(EmptyStateType.values.length, 7);
      expect(EmptyStateType.values.contains(EmptyStateType.noEventsNewUser), true);
      expect(EmptyStateType.values.contains(EmptyStateType.noEventsThisWeek), true);
      expect(EmptyStateType.values.contains(EmptyStateType.nothingOnDay), true);
      expect(EmptyStateType.values.contains(EmptyStateType.allCaughtUp), true);
      expect(EmptyStateType.values.contains(EmptyStateType.noGroups), true);
      expect(EmptyStateType.values.contains(EmptyStateType.noFriends), true);
      expect(EmptyStateType.values.contains(EmptyStateType.inboxEmpty), true);
    });
  });

  group('EmptyState Widget', () {
    Widget buildTestWidget({
      required EmptyStateType type,
      DateTime? selectedDate,
      VoidCallback? onCreateEvent,
      VoidCallback? onImportCalendar,
      VoidCallback? onViewGroups,
      VoidCallback? onCreateGroup,
      VoidCallback? onAddFriend,
    }) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: EmptyState(
            type: type,
            selectedDate: selectedDate,
            onCreateEvent: onCreateEvent,
            onImportCalendar: onImportCalendar,
            onViewGroups: onViewGroups,
            onCreateGroup: onCreateGroup,
            onAddFriend: onAddFriend,
          ),
        ),
      );
    }

    group('noEventsNewUser', () {
      testWidgets('should display correct content', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          type: EmptyStateType.noEventsNewUser,
          onCreateEvent: () {},
          onImportCalendar: () {},
        ));

        expect(find.text('No events scheduled yet'), findsOneWidget);
        expect(find.text('Create your first event to get started'), findsOneWidget);
        expect(find.text('Create Event'), findsOneWidget);
        expect(find.text('Import from Calendar'), findsOneWidget);
      });

      testWidgets('should hide CTAs when callbacks are null', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          type: EmptyStateType.noEventsNewUser,
        ));

        expect(find.text('Create Event'), findsNothing);
        expect(find.text('Import from Calendar'), findsNothing);
      });
    });

    group('noEventsThisWeek', () {
      testWidgets('should display correct content', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          type: EmptyStateType.noEventsThisWeek,
          onCreateEvent: () {},
          onViewGroups: () {},
        ));

        expect(find.text('Nothing scheduled this week'), findsOneWidget);
        expect(find.text('Time to plan something with your groups?'), findsOneWidget);
        expect(find.text('View Groups'), findsOneWidget);
      });
    });

    group('nothingOnDay', () {
      testWidgets('should display date in title', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          type: EmptyStateType.nothingOnDay,
          selectedDate: DateTime(2025, 6, 15),
          onCreateEvent: () {},
        ));

        expect(find.text('Nothing on June 15'), findsOneWidget);
      });

      testWidgets('should display default text when no date', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          type: EmptyStateType.nothingOnDay,
          onCreateEvent: () {},
        ));

        expect(find.text('Nothing on this day'), findsOneWidget);
      });
    });

    group('allCaughtUp', () {
      testWidgets('should display correct content', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          type: EmptyStateType.allCaughtUp,
        ));

        expect(find.text('All caught up!'), findsOneWidget);
        expect(find.text('No upcoming events'), findsOneWidget);
      });
    });

    group('noGroups', () {
      testWidgets('should display correct content', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          type: EmptyStateType.noGroups,
          onCreateGroup: () {},
        ));

        expect(find.text('No groups yet'), findsOneWidget);
        expect(find.text('Create a group to start coordinating events with friends'), findsOneWidget);
        expect(find.text('Create Group'), findsOneWidget);
      });
    });

    group('noFriends', () {
      testWidgets('should display correct content', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          type: EmptyStateType.noFriends,
          onAddFriend: () {},
        ));

        expect(find.text('No friends added yet'), findsOneWidget);
        expect(find.text('Add friends to create groups and share calendars'), findsOneWidget);
        expect(find.text('Add Friend'), findsOneWidget);
      });
    });

    group('inboxEmpty', () {
      testWidgets('should display correct content', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          type: EmptyStateType.inboxEmpty,
        ));

        expect(find.text('All caught up!'), findsOneWidget);
        expect(find.text('No pending requests or invites'), findsOneWidget);
      });
    });

    group('CTA button interactions', () {
      testWidgets('should call onCreateEvent when tapped', (tester) async {
        bool called = false;
        await tester.pumpWidget(buildTestWidget(
          type: EmptyStateType.noEventsNewUser,
          onCreateEvent: () => called = true,
        ));

        await tester.tap(find.text('Create Event'));
        expect(called, true);
      });

      testWidgets('should call onCreateGroup when tapped', (tester) async {
        bool called = false;
        await tester.pumpWidget(buildTestWidget(
          type: EmptyStateType.noGroups,
          onCreateGroup: () => called = true,
        ));

        await tester.tap(find.text('Create Group'));
        expect(called, true);
      });
    });
  });
}
