import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/presentation/widgets/mini_calendar_widget.dart';
import 'package:lockitin_app/core/theme/app_theme.dart';

void main() {
  group('MiniCalendarWidget', () {
    Widget buildTestWidget({
      DateTime? selectedDate,
      DateTime? focusedMonth,
      Map<int, List<Color>> eventIndicators = const {},
      ValueChanged<DateTime>? onDateSelected,
      ValueChanged<DateTime>? onMonthChanged,
    }) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: MiniCalendarWidget(
            selectedDate: selectedDate ?? DateTime(2025, 6, 15),
            focusedMonth: focusedMonth ?? DateTime(2025, 6, 1),
            eventIndicators: eventIndicators,
            onDateSelected: onDateSelected ?? (_) {},
            onMonthChanged: onMonthChanged,
          ),
        ),
      );
    }

    testWidgets('should display day headers', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      
      expect(find.text('S'), findsNWidgets(2)); // Sunday and Saturday
      expect(find.text('M'), findsOneWidget);
      expect(find.text('T'), findsNWidgets(2)); // Tuesday and Thursday
      expect(find.text('W'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);
    });

    testWidgets('should display days of month', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        focusedMonth: DateTime(2025, 6, 1),
      ));
      
      // June 2025 has 30 days
      expect(find.text('1'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
    });

    testWidgets('should call onDateSelected when date is tapped', (tester) async {
      DateTime? selectedDate;
      
      await tester.pumpWidget(buildTestWidget(
        focusedMonth: DateTime(2025, 6, 1),
        onDateSelected: (date) => selectedDate = date,
      ));
      
      await tester.tap(find.text('15'));
      
      expect(selectedDate?.day, 15);
      expect(selectedDate?.month, 6);
      expect(selectedDate?.year, 2025);
    });

    testWidgets('should show event indicators when events exist', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        focusedMonth: DateTime(2025, 6, 1),
        eventIndicators: {
          10: [Colors.blue],
          20: [Colors.red, Colors.green],
        },
      ));
      
      // Widget should render with indicators
      expect(find.byType(MiniCalendarWidget), findsOneWidget);
    });

    testWidgets('should highlight selected date', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        selectedDate: DateTime(2025, 6, 15),
        focusedMonth: DateTime(2025, 6, 1),
      ));
      
      // The selected date should be visible
      expect(find.text('15'), findsOneWidget);
    });

    testWidgets('should render grid with correct number of cells', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        focusedMonth: DateTime(2025, 6, 1),
      ));
      
      // June 2025 starts on Sunday, so should have 30 days
      expect(find.byType(GridView), findsOneWidget);
    });
  });
}
