import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/core/theme/app_typography.dart';
import 'package:lockitin_app/core/theme/app_theme.dart';

void main() {
  group('AppTypography', () {
    group('Font Sizes', () {
      test('displayLarge should be 57.0', () {
        expect(AppTypography.displayLarge, 57.0);
      });

      test('displayMedium should be 45.0', () {
        expect(AppTypography.displayMedium, 45.0);
      });

      test('displaySmall should be 36.0', () {
        expect(AppTypography.displaySmall, 36.0);
      });

      test('headlineLarge should be 32.0', () {
        expect(AppTypography.headlineLarge, 32.0);
      });

      test('headlineMedium should be 28.0', () {
        expect(AppTypography.headlineMedium, 28.0);
      });

      test('headlineSmall should be 24.0', () {
        expect(AppTypography.headlineSmall, 24.0);
      });

      test('titleLarge should be 22.0', () {
        expect(AppTypography.titleLarge, 22.0);
      });

      test('titleMedium should be 16.0', () {
        expect(AppTypography.titleMedium, 16.0);
      });

      test('titleSmall should be 14.0', () {
        expect(AppTypography.titleSmall, 14.0);
      });

      test('bodyLarge should be 16.0', () {
        expect(AppTypography.bodyLarge, 16.0);
      });

      test('bodyMedium should be 14.0', () {
        expect(AppTypography.bodyMedium, 14.0);
      });

      test('bodySmall should be 12.0', () {
        expect(AppTypography.bodySmall, 12.0);
      });

      test('labelLarge should be 14.0', () {
        expect(AppTypography.labelLarge, 14.0);
      });

      test('labelMedium should be 12.0', () {
        expect(AppTypography.labelMedium, 12.0);
      });

      test('labelSmall should be 11.0', () {
        expect(AppTypography.labelSmall, 11.0);
      });
    });

    group('Font Weights', () {
      test('light should be w300', () {
        expect(AppTypography.light, FontWeight.w300);
      });

      test('regular should be w400', () {
        expect(AppTypography.regular, FontWeight.w400);
      });

      test('medium should be w500', () {
        expect(AppTypography.medium, FontWeight.w500);
      });

      test('semiBold should be w600', () {
        expect(AppTypography.semiBold, FontWeight.w600);
      });

      test('bold should be w700', () {
        expect(AppTypography.bold, FontWeight.w700);
      });
    });

    group('Line Heights', () {
      test('lineHeightTight should be 1.2', () {
        expect(AppTypography.lineHeightTight, 1.2);
      });

      test('lineHeightNormal should be 1.4', () {
        expect(AppTypography.lineHeightNormal, 1.4);
      });

      test('lineHeightRelaxed should be 1.6', () {
        expect(AppTypography.lineHeightRelaxed, 1.6);
      });
    });

    group('Letter Spacing', () {
      test('letterSpacingTight should be -0.5', () {
        expect(AppTypography.letterSpacingTight, -0.5);
      });

      test('letterSpacingNormal should be 0.0', () {
        expect(AppTypography.letterSpacingNormal, 0.0);
      });

      test('letterSpacingWide should be 0.5', () {
        expect(AppTypography.letterSpacingWide, 0.5);
      });
    });

    group('Helper Methods', () {
      testWidgets('of should return TextTheme from context', (tester) async {
        late TextTheme textTheme;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (context) {
                textTheme = AppTypography.of(context);
                return const SizedBox();
              },
            ),
          ),
        );

        expect(textTheme, isNotNull);
        expect(textTheme.bodyMedium, isNotNull);
      });

      testWidgets('bodyMediumWeight should apply custom weight', (tester) async {
        late TextStyle style;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (context) {
                style = AppTypography.bodyMediumWeight(context, FontWeight.w700);
                return const SizedBox();
              },
            ),
          ),
        );

        expect(style.fontWeight, FontWeight.w700);
      });

      testWidgets('titleMediumWeight should apply custom weight', (tester) async {
        late TextStyle style;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (context) {
                style = AppTypography.titleMediumWeight(context, FontWeight.w600);
                return const SizedBox();
              },
            ),
          ),
        );

        expect(style.fontWeight, FontWeight.w600);
      });
    });
  });
}
