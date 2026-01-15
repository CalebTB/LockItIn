import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/core/theme/app_colors.dart';
import 'package:lockitin_app/core/utils/rsvp_status_utils.dart';

void main() {
  group('RSVPStatusUtils', () {
    group('getIcon', () {
      test('returns check_circle for accepted status', () {
        expect(RSVPStatusUtils.getIcon('accepted'), Icons.check_circle);
      });

      test('returns help_outline for maybe status', () {
        expect(RSVPStatusUtils.getIcon('maybe'), Icons.help_outline);
      });

      test('returns cancel_outlined for declined status', () {
        expect(RSVPStatusUtils.getIcon('declined'), Icons.cancel_outlined);
      });

      test('returns event_available for pending status', () {
        expect(RSVPStatusUtils.getIcon('pending'), Icons.event_available);
      });

      test('returns event_available for unknown status', () {
        expect(RSVPStatusUtils.getIcon('unknown'), Icons.event_available);
      });
    });

    group('getSmallIcon', () {
      test('returns check for accepted status', () {
        expect(RSVPStatusUtils.getSmallIcon('accepted'), Icons.check);
      });

      test('returns question_mark for maybe status', () {
        expect(RSVPStatusUtils.getSmallIcon('maybe'), Icons.question_mark);
      });

      test('returns close for declined status', () {
        expect(RSVPStatusUtils.getSmallIcon('declined'), Icons.close);
      });

      test('returns schedule for pending status', () {
        expect(RSVPStatusUtils.getSmallIcon('pending'), Icons.schedule);
      });

      test('returns schedule for unknown status', () {
        expect(RSVPStatusUtils.getSmallIcon('unknown'), Icons.schedule);
      });
    });

    group('getColor', () {
      late ColorScheme colorScheme;
      late AppColorsExtension appColors;

      setUp(() {
        // Create test color scheme
        colorScheme = const ColorScheme.light(
          primary: Color(0xFFF43F5E),
          error: Color(0xFFEF4444),
        );

        // Create test app colors
        appColors = AppColorsExtension.light;
      });

      test('returns success color for accepted status', () {
        final color = RSVPStatusUtils.getColor('accepted', colorScheme, appColors);
        expect(color, appColors.success);
      });

      test('returns warning color for maybe status', () {
        final color = RSVPStatusUtils.getColor('maybe', colorScheme, appColors);
        expect(color, appColors.warning);
      });

      test('returns error color for declined status', () {
        final color = RSVPStatusUtils.getColor('declined', colorScheme, appColors);
        expect(color, colorScheme.error);
      });

      test('returns disabled color for pending status', () {
        final color = RSVPStatusUtils.getColor('pending', colorScheme, appColors);
        expect(color, appColors.textDisabled);
      });

      test('returns disabled color for unknown status', () {
        final color = RSVPStatusUtils.getColor('unknown', colorScheme, appColors);
        expect(color, appColors.textDisabled);
      });
    });

    group('getLabel', () {
      test('returns "Going" for accepted status', () {
        expect(RSVPStatusUtils.getLabel('accepted'), 'Going');
      });

      test('returns "Maybe" for maybe status', () {
        expect(RSVPStatusUtils.getLabel('maybe'), 'Maybe');
      });

      test('returns "Can\'t Go" for declined status', () {
        expect(RSVPStatusUtils.getLabel('declined'), "Can't Go");
      });

      test('returns "No Response" for pending status', () {
        expect(RSVPStatusUtils.getLabel('pending'), 'No Response');
      });

      test('returns "No Response" for unknown status', () {
        expect(RSVPStatusUtils.getLabel('unknown'), 'No Response');
      });
    });

    group('getButtonLabel', () {
      test('returns "You\'re Going" for accepted status', () {
        expect(RSVPStatusUtils.getButtonLabel('accepted'), "You're Going");
      });

      test('returns "You\'re Maybe" for maybe status', () {
        expect(RSVPStatusUtils.getButtonLabel('maybe'), "You're Maybe");
      });

      test('returns "You Can\'t Go" for declined status', () {
        expect(RSVPStatusUtils.getButtonLabel('declined'), "You Can't Go");
      });

      test('returns "RSVP to Event" for pending status', () {
        expect(RSVPStatusUtils.getButtonLabel('pending'), 'RSVP to Event');
      });

      test('returns "RSVP to Event" for unknown status', () {
        expect(RSVPStatusUtils.getButtonLabel('unknown'), 'RSVP to Event');
      });
    });
  });
}
