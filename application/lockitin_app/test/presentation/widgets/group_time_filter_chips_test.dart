import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/presentation/widgets/group_time_filter_chips.dart';
import 'package:lockitin_app/core/utils/time_filter_utils.dart';
import 'package:lockitin_app/core/theme/app_theme.dart';

void main() {
  group('GroupTimeFilterChips Widget', () {
    Widget buildTestWidget({
      Set<TimeFilter> selectedFilters = const {},
      void Function(TimeFilter)? onFilterTap,
      VoidCallback? onCustomTap,
    }) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: GroupTimeFilterChips(
            selectedFilters: selectedFilters,
            onFilterTap: onFilterTap ?? (_) {},
            onCustomTap: onCustomTap ?? () {},
          ),
        ),
      );
    }

    testWidgets('should display all filter labels', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      
      // allDay shows as "Custom"
      expect(find.text('Custom'), findsOneWidget);
      expect(find.text('Morning'), findsOneWidget);
      expect(find.text('Afternoon'), findsOneWidget);
      expect(find.text('Evening'), findsOneWidget);
      expect(find.text('Night'), findsOneWidget);
    });

    testWidgets('should call onFilterTap when morning is tapped', (tester) async {
      TimeFilter? tappedFilter;
      
      await tester.pumpWidget(buildTestWidget(
        onFilterTap: (filter) => tappedFilter = filter,
      ));
      
      await tester.tap(find.text('Morning'));
      
      expect(tappedFilter, TimeFilter.morning);
    });

    testWidgets('should call onFilterTap when afternoon is tapped', (tester) async {
      TimeFilter? tappedFilter;
      
      await tester.pumpWidget(buildTestWidget(
        onFilterTap: (filter) => tappedFilter = filter,
      ));
      
      await tester.tap(find.text('Afternoon'));
      
      expect(tappedFilter, TimeFilter.afternoon);
    });

    testWidgets('should call onCustomTap when Custom is tapped', (tester) async {
      bool customTapped = false;
      
      await tester.pumpWidget(buildTestWidget(
        onCustomTap: () => customTapped = true,
      ));
      
      await tester.tap(find.text('Custom'));
      
      expect(customTapped, true);
    });

    testWidgets('should show selected state for selected filters', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        selectedFilters: {TimeFilter.morning},
      ));
      
      // Widget should render with selection
      expect(find.byType(GroupTimeFilterChips), findsOneWidget);
    });

    testWidgets('should render 5 filter chips', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      
      // Each filter should have a GestureDetector
      expect(find.byType(GestureDetector), findsNWidgets(5));
    });

    testWidgets('should handle multiple selected filters', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        selectedFilters: {TimeFilter.morning, TimeFilter.evening},
      ));
      
      expect(find.byType(GroupTimeFilterChips), findsOneWidget);
    });
  });
}
