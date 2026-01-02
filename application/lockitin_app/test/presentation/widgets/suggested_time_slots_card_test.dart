import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/presentation/widgets/suggested_time_slots_card.dart';
import 'package:lockitin_app/core/services/availability_calculator_service.dart';
import 'package:lockitin_app/data/models/group_model.dart';
import 'package:lockitin_app/core/theme/app_theme.dart';

void main() {
  group('SuggestedTimeSlotsCard Widget', () {
    TimeSlotAvailability createTimeSlot({
      required DateTime startTime,
      required DateTime endTime,
      int availableCount = 2,
      int totalMembers = 4,
      List<String> availableMembers = const [],
      List<String> busyMembers = const [],
    }) {
      return TimeSlotAvailability(
        startTime: startTime,
        endTime: endTime,
        availableCount: availableCount,
        totalMembers: totalMembers,
        availableMembers: availableMembers,
        busyMembers: busyMembers,
      );
    }

    GroupMemberProfile createMember({
      required String userId,
      required String fullName,
    }) {
      return GroupMemberProfile(
        memberId: 'member-$userId',
        userId: userId,
        fullName: fullName,
        email: '$userId@example.com',
        role: GroupMemberRole.member,
        joinedAt: DateTime(2025, 1, 1),
      );
    }

    Widget buildTestWidget({
      List<TimeSlotAvailability>? timeSlots,
      List<GroupMemberProfile>? members,
      void Function(TimeSlotAvailability)? onSlotSelected,
      int maxSlotsToShow = 5,
    }) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SuggestedTimeSlotsCard(
              date: DateTime(2025, 6, 15),
              timeSlots: timeSlots ?? [],
              members: members ?? [],
              onSlotSelected: onSlotSelected,
              maxSlotsToShow: maxSlotsToShow,
            ),
          ),
        ),
      );
    }

    testWidgets('should display loading state when timeSlots is empty', (tester) async {
      await tester.pumpWidget(buildTestWidget(timeSlots: []));

      expect(find.text('Loading time suggestions...'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_empty_rounded), findsOneWidget);
    });

    testWidgets('should display no availability state when no one is free', (tester) async {
      final slots = [
        createTimeSlot(
          startTime: DateTime(2025, 6, 15, 10, 0),
          endTime: DateTime(2025, 6, 15, 11, 0),
          availableCount: 0,
          totalMembers: 4,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(timeSlots: slots));

      expect(find.text('Everyone is busy on this day. Try another date!'), findsOneWidget);
      expect(find.byIcon(Icons.event_busy_rounded), findsOneWidget);
    });

    testWidgets('should display header when timeSlots has availability', (tester) async {
      final slots = [
        createTimeSlot(
          startTime: DateTime(2025, 6, 15, 10, 0),
          endTime: DateTime(2025, 6, 15, 11, 0),
          availableCount: 3,
          totalMembers: 4,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(timeSlots: slots));

      expect(find.text('SUGGESTED TIMES'), findsOneWidget);
      expect(find.text('Best times when most people are free'), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline_rounded), findsOneWidget);
    });

    testWidgets('should display time slots with availability', (tester) async {
      final slots = [
        createTimeSlot(
          startTime: DateTime(2025, 6, 15, 10, 0),
          endTime: DateTime(2025, 6, 15, 11, 0),
          availableCount: 3,
          totalMembers: 4,
        ),
        createTimeSlot(
          startTime: DateTime(2025, 6, 15, 14, 0),
          endTime: DateTime(2025, 6, 15, 15, 0),
          availableCount: 2,
          totalMembers: 4,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(timeSlots: slots));

      // Should show progress indicators (one per slot)
      expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
    });

    testWidgets('should show PERFECT badge for fully available slots', (tester) async {
      final slots = [
        createTimeSlot(
          startTime: DateTime(2025, 6, 15, 10, 0),
          endTime: DateTime(2025, 6, 15, 11, 0),
          availableCount: 4,
          totalMembers: 4,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(timeSlots: slots));

      expect(find.text('PERFECT'), findsOneWidget);
    });

    testWidgets('should show Use button when onSlotSelected is provided', (tester) async {
      final slots = [
        createTimeSlot(
          startTime: DateTime(2025, 6, 15, 10, 0),
          endTime: DateTime(2025, 6, 15, 11, 0),
          availableCount: 3,
          totalMembers: 4,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(
        timeSlots: slots,
        onSlotSelected: (_) {},
      ));

      expect(find.text('Use'), findsOneWidget);
    });

    testWidgets('should not show Use button when onSlotSelected is null', (tester) async {
      final slots = [
        createTimeSlot(
          startTime: DateTime(2025, 6, 15, 10, 0),
          endTime: DateTime(2025, 6, 15, 11, 0),
          availableCount: 3,
          totalMembers: 4,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(
        timeSlots: slots,
        onSlotSelected: null,
      ));

      expect(find.text('Use'), findsNothing);
    });

    testWidgets('should call onSlotSelected when Use button is tapped', (tester) async {
      TimeSlotAvailability? selectedSlot;
      final slots = [
        createTimeSlot(
          startTime: DateTime(2025, 6, 15, 10, 0),
          endTime: DateTime(2025, 6, 15, 11, 0),
          availableCount: 3,
          totalMembers: 4,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(
        timeSlots: slots,
        onSlotSelected: (slot) => selectedSlot = slot,
      ));

      await tester.tap(find.text('Use'));

      expect(selectedSlot, isNotNull);
      expect(selectedSlot!.startTime.hour, equals(10));
    });

    testWidgets('should limit displayed slots to maxSlotsToShow', (tester) async {
      final slots = List.generate(
        10,
        (i) => createTimeSlot(
          startTime: DateTime(2025, 6, 15, 8 + i, 0),
          endTime: DateTime(2025, 6, 15, 9 + i, 0),
          availableCount: 3,
          totalMembers: 4,
        ),
      );

      await tester.pumpWidget(buildTestWidget(
        timeSlots: slots,
        maxSlotsToShow: 3,
      ));

      // Should only show 3 progress indicators (one per slot)
      expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
    });

    testWidgets('should have expand/collapse icons for each slot', (tester) async {
      final slots = [
        createTimeSlot(
          startTime: DateTime(2025, 6, 15, 10, 0),
          endTime: DateTime(2025, 6, 15, 11, 0),
          availableCount: 3,
          totalMembers: 4,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(timeSlots: slots));

      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('should expand slot to show member details on tap', (tester) async {
      final members = [
        createMember(userId: 'user-1', fullName: 'Alice Johnson'),
        createMember(userId: 'user-2', fullName: 'Bob Smith'),
      ];

      final slots = [
        createTimeSlot(
          startTime: DateTime(2025, 6, 15, 10, 0),
          endTime: DateTime(2025, 6, 15, 11, 0),
          availableCount: 1,
          totalMembers: 2,
          availableMembers: ['user-1'],
          busyMembers: ['user-2'],
        ),
      ];

      await tester.pumpWidget(buildTestWidget(
        timeSlots: slots,
        members: members,
      ));

      // Tap to expand
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pump();

      // Should now show expanded state
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
      expect(find.text('Free (1)'), findsOneWidget);
      expect(find.text('Busy (1)'), findsOneWidget);
    });
  });
}
