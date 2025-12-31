import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/utils/privacy_colors.dart';
import 'package:lockitin_app/data/models/event_model.dart';

void main() {
  group('PrivacyColors', () {
    group('getPrivacyColor', () {
      group('default palette', () {
        test('should return red for private visibility', () {
          final color = PrivacyColors.getPrivacyColor(EventVisibility.private);
          expect(color, const Color(0xFFEF4444));
        });

        test('should return green for sharedWithName visibility', () {
          final color = PrivacyColors.getPrivacyColor(EventVisibility.sharedWithName);
          expect(color, const Color(0xFF10B981));
        });

        test('should return orange for busyOnly visibility', () {
          final color = PrivacyColors.getPrivacyColor(EventVisibility.busyOnly);
          expect(color, const Color(0xFFF59E0B));
        });
      });

      group('color-blind friendly palette', () {
        test('should return rose for private visibility', () {
          final color = PrivacyColors.getPrivacyColor(
            EventVisibility.private,
            useColorBlindPalette: true,
          );
          expect(color, const Color(0xFFE11D48));
        });

        test('should return cyan for sharedWithName visibility', () {
          final color = PrivacyColors.getPrivacyColor(
            EventVisibility.sharedWithName,
            useColorBlindPalette: true,
          );
          expect(color, const Color(0xFF0891B2));
        });

        test('should return orange for busyOnly visibility', () {
          final color = PrivacyColors.getPrivacyColor(
            EventVisibility.busyOnly,
            useColorBlindPalette: true,
          );
          expect(color, const Color(0xFFF59E0B));
        });
      });
    });

    group('getPrivacyLabel', () {
      test('should return "Private" for private visibility', () {
        expect(
          PrivacyColors.getPrivacyLabel(EventVisibility.private),
          'Private',
        );
      });

      test('should return "Shared" for sharedWithName visibility', () {
        expect(
          PrivacyColors.getPrivacyLabel(EventVisibility.sharedWithName),
          'Shared',
        );
      });

      test('should return "Busy" for busyOnly visibility', () {
        expect(
          PrivacyColors.getPrivacyLabel(EventVisibility.busyOnly),
          'Busy',
        );
      });
    });

    group('getPrivacyIcon', () {
      test('should return lock icon for private visibility', () {
        expect(
          PrivacyColors.getPrivacyIcon(EventVisibility.private),
          Icons.lock,
        );
      });

      test('should return people icon for sharedWithName visibility', () {
        expect(
          PrivacyColors.getPrivacyIcon(EventVisibility.sharedWithName),
          Icons.people,
        );
      });

      test('should return eye icon for busyOnly visibility', () {
        expect(
          PrivacyColors.getPrivacyIcon(EventVisibility.busyOnly),
          Icons.remove_red_eye_outlined,
        );
      });
    });

    group('getPrivacyBackgroundColor', () {
      test('should return red shade for private visibility', () {
        final color = PrivacyColors.getPrivacyBackgroundColor(EventVisibility.private);
        expect(color, Colors.red.shade100);
      });

      test('should return green shade for sharedWithName visibility', () {
        final color = PrivacyColors.getPrivacyBackgroundColor(EventVisibility.sharedWithName);
        expect(color, Colors.green.shade100);
      });

      test('should return orange shade for busyOnly visibility', () {
        final color = PrivacyColors.getPrivacyBackgroundColor(EventVisibility.busyOnly);
        expect(color, Colors.orange.shade100);
      });
    });
  });
}
