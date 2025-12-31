import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/presentation/widgets/group_date_range_filter.dart';
import 'package:lockitin_app/core/theme/app_theme.dart';

void main() {
  group('GroupDateRangeFilter Widget', () {
    Widget buildTestWidget({
      DateTimeRange? selectedDateRange,
      VoidCallback? onTap,
      VoidCallback? onClear,
    }) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: GroupDateRangeFilter(
            selectedDateRange: selectedDateRange,
            onTap: onTap ?? () {},
            onClear: onClear ?? () {},
          ),
        ),
      );
    }

    group('No Date Range Selected', () {
      testWidgets('should display "All dates" when no range', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.text('All dates'), findsOneWidget);
      });

      testWidgets('should show date range icon', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.byIcon(Icons.date_range_rounded), findsOneWidget);
      });

      testWidgets('should show dropdown arrow when no range', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      });

      testWidgets('should not show close icon when no range', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.byIcon(Icons.close), findsNothing);
      });

      testWidgets('should call onTap when tapped', (tester) async {
        bool tapped = false;

        await tester.pumpWidget(buildTestWidget(
          onTap: () => tapped = true,
        ));

        await tester.tap(find.text('All dates'));
        expect(tapped, isTrue);
      });
    });

    group('Date Range Selected', () {
      final testRange = DateTimeRange(
        start: DateTime(2025, 6, 15),
        end: DateTime(2025, 6, 20),
      );

      testWidgets('should display formatted date range', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          selectedDateRange: testRange,
        ));

        expect(find.text('Jun 15 - Jun 20'), findsOneWidget);
      });

      testWidgets('should show close icon when range selected', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          selectedDateRange: testRange,
        ));

        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('should not show dropdown arrow when range selected', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          selectedDateRange: testRange,
        ));

        expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
      });

      testWidgets('should call onClear when close icon tapped', (tester) async {
        bool cleared = false;

        await tester.pumpWidget(buildTestWidget(
          selectedDateRange: testRange,
          onClear: () => cleared = true,
        ));

        await tester.tap(find.byIcon(Icons.close));
        expect(cleared, isTrue);
      });
    });

    group('Date Range Formatting', () {
      testWidgets('should format same month range correctly', (tester) async {
        final range = DateTimeRange(
          start: DateTime(2025, 6, 15),
          end: DateTime(2025, 6, 20),
        );

        await tester.pumpWidget(buildTestWidget(selectedDateRange: range));

        expect(find.text('Jun 15 - Jun 20'), findsOneWidget);
      });

      testWidgets('should format different month range correctly', (tester) async {
        final range = DateTimeRange(
          start: DateTime(2025, 6, 28),
          end: DateTime(2025, 7, 5),
        );

        await tester.pumpWidget(buildTestWidget(selectedDateRange: range));

        expect(find.text('Jun 28 - Jul 5'), findsOneWidget);
      });

      testWidgets('should format cross-year range with year suffix', (tester) async {
        final range = DateTimeRange(
          start: DateTime(2025, 12, 28),
          end: DateTime(2026, 1, 5),
        );

        await tester.pumpWidget(buildTestWidget(selectedDateRange: range));

        expect(find.text("Dec 28 '25 - Jan 5 '26"), findsOneWidget);
      });
    });

    group('Interaction', () {
      testWidgets('entire container should be tappable', (tester) async {
        bool tapped = false;

        await tester.pumpWidget(buildTestWidget(
          onTap: () => tapped = true,
        ));

        // Tap on the icon instead of text
        await tester.tap(find.byIcon(Icons.date_range_rounded));
        expect(tapped, isTrue);
      });
    });
  });
}
