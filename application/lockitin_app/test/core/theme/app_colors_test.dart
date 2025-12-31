import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/core/theme/app_colors.dart';

void main() {
  group('AppColors', () {
    group('Static Color Constants', () {
      test('primary should be rose 500', () {
        expect(AppColors.primary, const Color(0xFFF43F5E));
      });

      test('secondary should be orange 500', () {
        expect(AppColors.secondary, const Color(0xFFF97316));
      });

      test('success should be emerald', () {
        expect(AppColors.success, const Color(0xFF10B981));
      });

      test('warning should be amber', () {
        expect(AppColors.warning, const Color(0xFFF59E0B));
      });

      test('error should match primary rose', () {
        expect(AppColors.error, AppColors.primary);
      });
    });

    group('Category Colors', () {
      test('categoryWork should be teal', () {
        expect(AppColors.categoryWork, AppColors.memberTeal);
      });

      test('categoryHoliday should be secondary orange', () {
        expect(AppColors.categoryHoliday, AppColors.secondary);
      });

      test('categoryFriend should be violet', () {
        expect(AppColors.categoryFriend, AppColors.memberViolet);
      });

      test('categoryOther should be primary rose', () {
        expect(AppColors.categoryOther, AppColors.primary);
      });
    });

    group('getAvailabilityColor', () {
      test('should return perfect color for ratio >= 0.85', () {
        final lightColor = AppColors.getAvailabilityColor(0.85, Brightness.light);
        expect(lightColor, AppColors.availabilityPerfectBgLight);

        final darkColor = AppColors.getAvailabilityColor(0.90, Brightness.dark);
        expect(darkColor, AppColors.availabilityPerfectBgDark);
      });

      test('should return high color for ratio 0.65-0.84', () {
        final lightColor = AppColors.getAvailabilityColor(0.70, Brightness.light);
        expect(lightColor, AppColors.availabilityHighBgLight);

        final darkColor = AppColors.getAvailabilityColor(0.65, Brightness.dark);
        expect(darkColor, AppColors.availabilityHighBgDark);
      });

      test('should return medium color for ratio 0.50-0.64', () {
        final lightColor = AppColors.getAvailabilityColor(0.55, Brightness.light);
        expect(lightColor, AppColors.availabilityMediumBgLight);

        final darkColor = AppColors.getAvailabilityColor(0.50, Brightness.dark);
        expect(darkColor, AppColors.availabilityMediumBgDark);
      });

      test('should return low color for ratio 0.25-0.49', () {
        final lightColor = AppColors.getAvailabilityColor(0.30, Brightness.light);
        expect(lightColor, AppColors.availabilityLowBgLight);

        final darkColor = AppColors.getAvailabilityColor(0.25, Brightness.dark);
        expect(darkColor, AppColors.availabilityLowBgDark);
      });

      test('should return poor color for ratio 0.01-0.24', () {
        final lightColor = AppColors.getAvailabilityColor(0.15, Brightness.light);
        expect(lightColor, AppColors.availabilityPoorBgLight);

        final darkColor = AppColors.getAvailabilityColor(0.10, Brightness.dark);
        expect(darkColor, AppColors.availabilityPoorBgDark);
      });

      test('should return none color for ratio 0', () {
        final lightColor = AppColors.getAvailabilityColor(0, Brightness.light);
        expect(lightColor, AppColors.availabilityNoneBgLight);

        final darkColor = AppColors.getAvailabilityColor(0, Brightness.dark);
        expect(darkColor, AppColors.availabilityNoneBgDark);
      });
    });

    group('getAvailabilityDotColor', () {
      test('should return perfect color for ratio >= 0.85', () {
        expect(AppColors.getAvailabilityDotColor(0.85), AppColors.availabilityPerfect);
        expect(AppColors.getAvailabilityDotColor(1.0), AppColors.availabilityPerfect);
      });

      test('should return high color for ratio 0.65-0.84', () {
        expect(AppColors.getAvailabilityDotColor(0.70), AppColors.availabilityHigh);
      });

      test('should return medium color for ratio 0.50-0.64', () {
        expect(AppColors.getAvailabilityDotColor(0.55), AppColors.availabilityMedium);
      });

      test('should return low color for ratio 0.25-0.49', () {
        expect(AppColors.getAvailabilityDotColor(0.30), AppColors.availabilityLow);
      });

      test('should return poor color for ratio 0.01-0.24', () {
        expect(AppColors.getAvailabilityDotColor(0.15), AppColors.availabilityPoor);
      });

      test('should return neutral color for ratio 0', () {
        expect(AppColors.getAvailabilityDotColor(0), AppColors.neutral400);
      });
    });

    group('generateAvatarColor', () {
      test('should return default color when useDefault is true', () {
        final color = AppColors.generateAvatarColor('test', useDefault: true);
        expect(color, AppColors.avatarDefault);
      });

      test('should generate same color for same text', () {
        final color1 = AppColors.generateAvatarColor('john@example.com');
        final color2 = AppColors.generateAvatarColor('john@example.com');
        expect(color1, color2);
      });

      test('should generate different colors for different text', () {
        final color1 = AppColors.generateAvatarColor('john@example.com');
        final color2 = AppColors.generateAvatarColor('jane@example.com');
        expect(color1, isNot(color2));
      });

      test('should generate valid colors', () {
        final color = AppColors.generateAvatarColor('test');
        expect(color.alpha, 255); // Fully opaque
      });
    });

    group('ColorSchemes', () {
      test('getLightColorScheme should have light brightness', () {
        final scheme = AppColors.getLightColorScheme();
        expect(scheme.brightness, Brightness.light);
      });

      test('getDarkColorScheme should have dark brightness', () {
        final scheme = AppColors.getDarkColorScheme();
        expect(scheme.brightness, Brightness.dark);
      });

      test('light scheme should have rose primary', () {
        final scheme = AppColors.getLightColorScheme();
        expect(scheme.primary, AppColors.rose500);
      });

      test('dark scheme should have rose primary', () {
        final scheme = AppColors.getDarkColorScheme();
        expect(scheme.primary, AppColors.rose500);
      });

      test('light scheme surface should be white', () {
        final scheme = AppColors.getLightColorScheme();
        expect(scheme.surface, Colors.white);
      });

      test('dark scheme surface should be neutral950', () {
        final scheme = AppColors.getDarkColorScheme();
        expect(scheme.surface, AppColors.neutral950);
      });
    });
  });

  group('AppColorsExtension', () {
    test('light should have correct text colors', () {
      expect(AppColorsExtension.light.textSecondary, AppColors.gray700);
      expect(AppColorsExtension.light.textMuted, AppColors.gray500);
    });

    test('dark should have correct text colors', () {
      expect(AppColorsExtension.dark.textSecondary, AppColors.neutral300);
      expect(AppColorsExtension.dark.textMuted, AppColors.neutral500);
    });

    test('copyWith should update specified fields', () {
      final original = AppColorsExtension.light;
      final copy = original.copyWith(textSecondary: Colors.red);

      expect(copy.textSecondary, Colors.red);
      expect(copy.textMuted, original.textMuted); // Unchanged
    });

    test('copyWith should preserve all fields when no changes', () {
      final original = AppColorsExtension.light;
      final copy = original.copyWith();

      expect(copy.textSecondary, original.textSecondary);
      expect(copy.textTertiary, original.textTertiary);
      expect(copy.textMuted, original.textMuted);
      expect(copy.textDisabled, original.textDisabled);
      expect(copy.success, original.success);
      expect(copy.warning, original.warning);
      expect(copy.cardBackground, original.cardBackground);
    });

    test('lerp should return this when other is not AppColorsExtension', () {
      final result = AppColorsExtension.light.lerp(null, 0.5);
      expect(result, AppColorsExtension.light);
    });

    test('lerp should interpolate colors', () {
      final result = AppColorsExtension.light.lerp(AppColorsExtension.dark, 0.5);
      
      // Should be somewhere between light and dark values
      expect(result.textSecondary, isNot(AppColorsExtension.light.textSecondary));
      expect(result.textSecondary, isNot(AppColorsExtension.dark.textSecondary));
    });
  });

  group('AppColorSchemeExtension', () {
    test('avatarDefault should return primary', () {
      final scheme = AppColors.getLightColorScheme();
      expect(scheme.avatarDefault, AppColors.avatarDefault);
    });

    test('successColor should return success in light mode', () {
      final scheme = AppColors.getLightColorScheme();
      expect(scheme.successColor, AppColors.success);
    });

    test('successColor should return successLight in dark mode', () {
      final scheme = AppColors.getDarkColorScheme();
      expect(scheme.successColor, AppColors.successLight);
    });

    test('warningColor should return warning in light mode', () {
      final scheme = AppColors.getLightColorScheme();
      expect(scheme.warningColor, AppColors.warning);
    });

    test('warningColor should return warningLight in dark mode', () {
      final scheme = AppColors.getDarkColorScheme();
      expect(scheme.warningColor, AppColors.warningLight);
    });
  });
}
