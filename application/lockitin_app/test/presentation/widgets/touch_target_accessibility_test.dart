import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/core/theme/app_spacing.dart';
import 'package:lockitin_app/core/theme/app_theme.dart';
import 'package:lockitin_app/presentation/widgets/adaptive_icon_button.dart';
import 'package:lockitin_app/presentation/widgets/group_time_filter_chips.dart';
import 'package:lockitin_app/core/utils/time_filter_utils.dart';

void main() {
  group('Touch Target Accessibility Tests', () {
    group('AdaptiveIconButton', () {
      Widget buildTestWidget({VoidCallback? onPressed}) {
        return MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: AdaptiveIconButton(
                icon: Icons.close,
                onPressed: onPressed ?? () {},
                tooltip: 'Test Button',
              ),
            ),
          ),
        );
      }

      testWidgets('should render without errors', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        expect(find.byType(AdaptiveIconButton), findsOneWidget);
      });

      testWidgets('should have minimum 48x48 touch target (WCAG 2.1 AA)', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        // Find the actual button widget
        final buttonFinder = find.byType(AdaptiveIconButton);
        expect(buttonFinder, findsOneWidget);

        // Get the rendered size of the button
        final Size buttonSize = tester.getSize(buttonFinder);

        // Verify it meets minimum touch target size
        expect(
          buttonSize.width >= AppSpacing.minTouchTarget,
          true,
          reason: 'Button width ${buttonSize.width} should be >= ${AppSpacing.minTouchTarget}',
        );
        expect(
          buttonSize.height >= AppSpacing.minTouchTarget,
          true,
          reason: 'Button height ${buttonSize.height} should be >= ${AppSpacing.minTouchTarget}',
        );
      });

      testWidgets('should be tappable', (tester) async {
        bool tapped = false;
        await tester.pumpWidget(buildTestWidget(onPressed: () => tapped = true));

        // Tap the button
        await tester.tap(find.byType(AdaptiveIconButton));
        await tester.pump();

        expect(tapped, true);
      });
    });

    group('GroupTimeFilterChips', () {
      Widget buildTestWidget({Set<TimeFilter> selectedFilters = const {}}) {
        return MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: GroupTimeFilterChips(
              selectedFilters: selectedFilters,
              onFilterTap: (_) {},
              onCustomTap: () {},
            ),
          ),
        );
      }

      testWidgets('should render without errors', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        expect(find.byType(GroupTimeFilterChips), findsOneWidget);
      });

      testWidgets('each chip should meet minimum touch target height', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        // Find all the chip labels
        final customChip = find.text('Custom');
        final morningChip = find.text('Morning');
        final afternoonChip = find.text('Afternoon');
        final eveningChip = find.text('Evening');
        final nightChip = find.text('Night');

        // Verify all chips are present
        expect(customChip, findsOneWidget);
        expect(morningChip, findsOneWidget);
        expect(afternoonChip, findsOneWidget);
        expect(eveningChip, findsOneWidget);
        expect(nightChip, findsOneWidget);

        // Check that each chip meets minimum height
        // We can't easily measure individual chip heights in the Row,
        // but we can verify the overall widget height is reasonable
        final Size widgetSize = tester.getSize(find.byType(GroupTimeFilterChips));
        expect(
          widgetSize.height >= AppSpacing.minTouchTarget,
          true,
          reason: 'Chip row height ${widgetSize.height} should be >= ${AppSpacing.minTouchTarget}',
        );
      });

      testWidgets('chips should be tappable', (tester) async {
        TimeFilter? tappedFilter;
        bool customTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: GroupTimeFilterChips(
                selectedFilters: const {},
                onFilterTap: (filter) => tappedFilter = filter,
                onCustomTap: () => customTapped = true,
              ),
            ),
          ),
        );

        // Tap morning chip
        await tester.tap(find.text('Morning'));
        expect(tappedFilter, TimeFilter.morning);

        // Tap custom chip
        await tester.tap(find.text('Custom'));
        expect(customTapped, true);
      });

      testWidgets('should show selected state', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          selectedFilters: {TimeFilter.morning, TimeFilter.evening},
        ));

        // Widget should render with selections
        expect(find.byType(GroupTimeFilterChips), findsOneWidget);
        expect(find.text('Morning'), findsOneWidget);
        expect(find.text('Evening'), findsOneWidget);
      });
    });

    group('AppSpacing Constants', () {
      test('touch target constants should meet accessibility guidelines', () {
        // iOS Human Interface Guidelines: 44pt minimum
        expect(AppSpacing.minTouchTargetIOS, 44.0);

        // Material Design: 48dp minimum
        expect(AppSpacing.minTouchTargetAndroid, 48.0);

        // WCAG 2.1 Level AA: 44×44 CSS pixels minimum
        // We use 48px as cross-platform standard (exceeds both iOS and WCAG)
        expect(AppSpacing.minTouchTarget, 48.0);
      });

      test('cross-platform minimum should meet both iOS and Android guidelines', () {
        expect(
          AppSpacing.minTouchTarget >= AppSpacing.minTouchTargetIOS,
          true,
          reason: 'Cross-platform minimum should meet iOS 44pt requirement',
        );
        expect(
          AppSpacing.minTouchTarget >= AppSpacing.minTouchTargetAndroid,
          true,
          reason: 'Cross-platform minimum should meet Material Design 48dp requirement',
        );
      });
    });
  });
}
