import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/presentation/widgets/day_header.dart';
import 'package:lockitin_app/core/theme/app_theme.dart';

void main() {
  group('DayHeader Widget', () {
    Widget buildTestWidget({
      required DateTime date,
      int eventCount = 0,
    }) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: DayHeader(
            date: date,
            eventCount: eventCount,
          ),
        ),
      );
    }

    group('date labels', () {
      testWidgets('should show TODAY for current date', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          date: DateTime.now(),
        ));

        expect(find.text('TODAY'), findsOneWidget);
      });

      testWidgets('should show TOMORROW for next day', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          date: DateTime.now().add(const Duration(days: 1)),
        ));

        expect(find.text('TOMORROW'), findsOneWidget);
      });

      testWidgets('should show day of week for other dates', (tester) async {
        // Use a specific date that's neither today nor tomorrow
        final date = DateTime(2025, 6, 15); // A Sunday
        await tester.pumpWidget(buildTestWidget(
          date: date,
        ));

        expect(find.text('SUNDAY'), findsOneWidget);
      });
    });

    group('full date format', () {
      testWidgets('should display full date', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          date: DateTime(2025, 6, 15),
        ));

        expect(find.text('June 15, 2025'), findsOneWidget);
      });
    });

    group('event count', () {
      testWidgets('should not show badge when count is 0', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          date: DateTime(2025, 6, 15),
          eventCount: 0,
        ));

        expect(find.textContaining('event'), findsNothing);
      });

      testWidgets('should show singular "event" for count of 1', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          date: DateTime(2025, 6, 15),
          eventCount: 1,
        ));

        expect(find.text('1 event'), findsOneWidget);
      });

      testWidgets('should show plural "events" for count > 1', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          date: DateTime(2025, 6, 15),
          eventCount: 3,
        ));

        expect(find.text('3 events'), findsOneWidget);
      });

      testWidgets('should handle large event counts', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          date: DateTime(2025, 6, 15),
          eventCount: 99,
        ));

        expect(find.text('99 events'), findsOneWidget);
      });
    });
  });
}
