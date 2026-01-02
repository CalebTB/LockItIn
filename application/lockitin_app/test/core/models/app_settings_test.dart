import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/core/models/app_settings.dart';

void main() {
  group('AppSettings', () {
    group('Constructor', () {
      test('should create with default values', () {
        const settings = AppSettings();
        expect(settings.useColorBlindPalette, false);
      });

      test('should create with custom values', () {
        const settings = AppSettings(useColorBlindPalette: true);
        expect(settings.useColorBlindPalette, true);
      });
    });

    group('copyWith', () {
      test('should create copy with updated useColorBlindPalette', () {
        const original = AppSettings(useColorBlindPalette: false);
        final copy = original.copyWith(useColorBlindPalette: true);

        expect(copy.useColorBlindPalette, true);
      });

      test('should preserve values when no changes specified', () {
        const original = AppSettings(useColorBlindPalette: true);
        final copy = original.copyWith();

        expect(copy.useColorBlindPalette, true);
      });
    });

    group('toJson', () {
      test('should serialize to JSON correctly', () {
        const settings = AppSettings(useColorBlindPalette: true);
        final json = settings.toJson();

        expect(json['useColorBlindPalette'], true);
      });

      test('should serialize default values correctly', () {
        const settings = AppSettings();
        final json = settings.toJson();

        expect(json['useColorBlindPalette'], false);
      });
    });

    group('fromJson', () {
      test('should parse JSON correctly', () {
        final json = {'useColorBlindPalette': true};
        final settings = AppSettings.fromJson(json);

        expect(settings.useColorBlindPalette, true);
      });

      test('should use default value for missing keys', () {
        final json = <String, dynamic>{};
        final settings = AppSettings.fromJson(json);

        expect(settings.useColorBlindPalette, false);
      });

      test('should handle null value for useColorBlindPalette', () {
        final json = {'useColorBlindPalette': null};
        final settings = AppSettings.fromJson(json);

        expect(settings.useColorBlindPalette, false);
      });
    });

    group('JSON Round Trip', () {
      test('should survive serialization and deserialization', () {
        const original = AppSettings(useColorBlindPalette: true);
        final json = original.toJson();
        final restored = AppSettings.fromJson(json);

        expect(restored.useColorBlindPalette, original.useColorBlindPalette);
      });
    });
  });
}
