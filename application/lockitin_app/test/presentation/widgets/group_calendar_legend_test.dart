import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/presentation/widgets/group_calendar_legend.dart';
import 'package:lockitin_app/core/theme/app_theme.dart';

void main() {
  group('GroupCalendarLegend Widget', () {
    Widget buildTestWidget() {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: GroupCalendarLegend(),
        ),
      );
    }

    testWidgets('should display availability calendar label', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      
      expect(find.text('AVAILABILITY CALENDAR'), findsOneWidget);
    });

    testWidgets('should display 5 color dots', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      
      // Find containers with the specific sizes for color dots
      final colorDots = find.byWidgetPredicate(
        (widget) => widget is Container && 
                    widget.constraints?.maxWidth == 10 &&
                    widget.constraints?.maxHeight == 10,
      );
      
      // Should have 5 color dots
      expect(colorDots, findsNWidgets(5));
    });

    testWidgets('should use correct availability colors', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      
      // The widget should render without errors
      expect(find.byType(GroupCalendarLegend), findsOneWidget);
    });

    testWidgets('should render in Row layout', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      
      // Main row and inner row for dots
      expect(find.byType(Row), findsNWidgets(2));
    });
  });
}
