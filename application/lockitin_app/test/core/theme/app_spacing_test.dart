import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/core/theme/app_spacing.dart';

void main() {
  group('AppSpacing', () {
    group('Base Unit', () {
      test('unit should be 8.0', () {
        expect(AppSpacing.unit, 8.0);
      });
    });

    group('Spacing Scale', () {
      test('xxs should be 4.0 (half unit)', () {
        expect(AppSpacing.xxs, 4.0);
        expect(AppSpacing.xxs, AppSpacing.unit / 2);
      });

      test('xs should be 8.0 (1 unit)', () {
        expect(AppSpacing.xs, 8.0);
        expect(AppSpacing.xs, AppSpacing.unit);
      });

      test('sm should be 12.0 (1.5 units)', () {
        expect(AppSpacing.sm, 12.0);
        expect(AppSpacing.sm, AppSpacing.unit * 1.5);
      });

      test('md should be 16.0 (2 units)', () {
        expect(AppSpacing.md, 16.0);
        expect(AppSpacing.md, AppSpacing.unit * 2);
      });

      test('ml should be 20.0 (2.5 units)', () {
        expect(AppSpacing.ml, 20.0);
        expect(AppSpacing.ml, AppSpacing.unit * 2.5);
      });

      test('lg should be 24.0 (3 units)', () {
        expect(AppSpacing.lg, 24.0);
        expect(AppSpacing.lg, AppSpacing.unit * 3);
      });

      test('xl should be 32.0 (4 units)', () {
        expect(AppSpacing.xl, 32.0);
        expect(AppSpacing.xl, AppSpacing.unit * 4);
      });

      test('xxl should be 40.0 (5 units)', () {
        expect(AppSpacing.xxl, 40.0);
        expect(AppSpacing.xxl, AppSpacing.unit * 5);
      });

      test('xxxl should be 48.0 (6 units)', () {
        expect(AppSpacing.xxxl, 48.0);
        expect(AppSpacing.xxxl, AppSpacing.unit * 6);
      });

      test('huge should be 64.0 (8 units)', () {
        expect(AppSpacing.huge, 64.0);
        expect(AppSpacing.huge, AppSpacing.unit * 8);
      });
    });

    group('Semantic Spacing', () {
      test('screenPadding should equal md', () {
        expect(AppSpacing.screenPadding, AppSpacing.md);
      });

      test('cardPadding should equal md', () {
        expect(AppSpacing.cardPadding, AppSpacing.md);
      });

      test('sectionSpacing should equal lg', () {
        expect(AppSpacing.sectionSpacing, AppSpacing.lg);
      });

      test('itemSpacing should equal sm', () {
        expect(AppSpacing.itemSpacing, AppSpacing.sm);
      });

      test('iconTextSpacing should equal xs', () {
        expect(AppSpacing.iconTextSpacing, AppSpacing.xs);
      });

      test('buttonPaddingH should equal md', () {
        expect(AppSpacing.buttonPaddingH, AppSpacing.md);
      });

      test('buttonPaddingV should equal sm', () {
        expect(AppSpacing.buttonPaddingV, AppSpacing.sm);
      });

      test('formFieldSpacing should equal md', () {
        expect(AppSpacing.formFieldSpacing, AppSpacing.md);
      });

      test('bottomSheetHandle should equal xs', () {
        expect(AppSpacing.bottomSheetHandle, AppSpacing.xs);
      });

      test('appBarHeight should be 56.0', () {
        expect(AppSpacing.appBarHeight, 56.0);
      });

      test('bottomNavHeight should equal huge', () {
        expect(AppSpacing.bottomNavHeight, AppSpacing.huge);
      });

      test('fabMargin should equal md', () {
        expect(AppSpacing.fabMargin, AppSpacing.md);
      });
    });

    group('Border Radius', () {
      test('radiusSm should equal xs', () {
        expect(AppSpacing.radiusSm, AppSpacing.xs);
      });

      test('radiusMd should equal sm', () {
        expect(AppSpacing.radiusMd, AppSpacing.sm);
      });

      test('radiusLg should equal md', () {
        expect(AppSpacing.radiusLg, AppSpacing.md);
      });

      test('radiusXl should equal lg', () {
        expect(AppSpacing.radiusXl, AppSpacing.lg);
      });

      test('radiusFull should be 999.0', () {
        expect(AppSpacing.radiusFull, 999.0);
      });
    });

    group('Scale Consistency', () {
      test('spacing scale should be in ascending order', () {
        expect(AppSpacing.xxs, lessThan(AppSpacing.xs));
        expect(AppSpacing.xs, lessThan(AppSpacing.sm));
        expect(AppSpacing.sm, lessThan(AppSpacing.md));
        expect(AppSpacing.md, lessThan(AppSpacing.ml));
        expect(AppSpacing.ml, lessThan(AppSpacing.lg));
        expect(AppSpacing.lg, lessThan(AppSpacing.xl));
        expect(AppSpacing.xl, lessThan(AppSpacing.xxl));
        expect(AppSpacing.xxl, lessThan(AppSpacing.xxxl));
        expect(AppSpacing.xxxl, lessThan(AppSpacing.huge));
      });

      test('border radius scale should be in ascending order', () {
        expect(AppSpacing.radiusSm, lessThan(AppSpacing.radiusMd));
        expect(AppSpacing.radiusMd, lessThan(AppSpacing.radiusLg));
        expect(AppSpacing.radiusLg, lessThan(AppSpacing.radiusXl));
        expect(AppSpacing.radiusXl, lessThan(AppSpacing.radiusFull));
      });
    });
  });
}
