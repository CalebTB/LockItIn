import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/presentation/widgets/group_best_days_section.dart';
import 'package:lockitin_app/data/models/group_model.dart';

void main() {
  group('BestDayInfo', () {
    group('Constructor', () {
      test('should create with required parameters', () {
        const info = BestDayInfo(
          day: 15,
          availableCount: 5,
          totalMembers: 8,
        );

        expect(info.day, equals(15));
        expect(info.availableCount, equals(5));
        expect(info.totalMembers, equals(8));
      });

      test('should have default empty unavailableMembers', () {
        const info = BestDayInfo(
          day: 15,
          availableCount: 5,
          totalMembers: 8,
        );

        expect(info.unavailableMembers, isEmpty);
      });

      test('should have default null timeSlot', () {
        const info = BestDayInfo(
          day: 15,
          availableCount: 5,
          totalMembers: 8,
        );

        expect(info.timeSlot, isNull);
      });

      test('should accept optional parameters', () {
        final member = GroupMemberProfile(
          memberId: 'mem-1',
          userId: 'user-1',
          fullName: 'John Doe',
          email: 'john@example.com',
          role: GroupMemberRole.member,
          joinedAt: DateTime(2025, 1, 1),
        );

        final info = BestDayInfo(
          day: 15,
          availableCount: 5,
          totalMembers: 8,
          unavailableMembers: [member],
          timeSlot: '9am-5pm',
        );

        expect(info.unavailableMembers.length, equals(1));
        expect(info.timeSlot, equals('9am-5pm'));
      });
    });

    group('isFullAvailability', () {
      test('should be true when all members available', () {
        const info = BestDayInfo(
          day: 15,
          availableCount: 8,
          totalMembers: 8,
        );

        expect(info.isFullAvailability, isTrue);
      });

      test('should be false when not all members available', () {
        const info = BestDayInfo(
          day: 15,
          availableCount: 5,
          totalMembers: 8,
        );

        expect(info.isFullAvailability, isFalse);
      });

      test('should be false when totalMembers is 0', () {
        const info = BestDayInfo(
          day: 15,
          availableCount: 0,
          totalMembers: 0,
        );

        expect(info.isFullAvailability, isFalse);
      });

      test('should be false when no one available', () {
        const info = BestDayInfo(
          day: 15,
          availableCount: 0,
          totalMembers: 8,
        );

        expect(info.isFullAvailability, isFalse);
      });
    });

    group('ratio', () {
      test('should return correct ratio', () {
        const info = BestDayInfo(
          day: 15,
          availableCount: 4,
          totalMembers: 8,
        );

        expect(info.ratio, equals(0.5));
      });

      test('should return 1.0 when all available', () {
        const info = BestDayInfo(
          day: 15,
          availableCount: 8,
          totalMembers: 8,
        );

        expect(info.ratio, equals(1.0));
      });

      test('should return 0.0 when none available', () {
        const info = BestDayInfo(
          day: 15,
          availableCount: 0,
          totalMembers: 8,
        );

        expect(info.ratio, equals(0.0));
      });

      test('should return 0.0 when totalMembers is 0', () {
        const info = BestDayInfo(
          day: 15,
          availableCount: 0,
          totalMembers: 0,
        );

        expect(info.ratio, equals(0.0));
      });

      test('should handle fractional ratios', () {
        const info = BestDayInfo(
          day: 15,
          availableCount: 3,
          totalMembers: 8,
        );

        expect(info.ratio, equals(0.375));
      });
    });

    group('Edge Cases', () {
      test('should handle day 1', () {
        const info = BestDayInfo(
          day: 1,
          availableCount: 8,
          totalMembers: 8,
        );

        expect(info.day, equals(1));
      });

      test('should handle day 31', () {
        const info = BestDayInfo(
          day: 31,
          availableCount: 8,
          totalMembers: 8,
        );

        expect(info.day, equals(31));
      });

      test('should handle large member counts', () {
        const info = BestDayInfo(
          day: 15,
          availableCount: 50,
          totalMembers: 50,
        );

        expect(info.ratio, equals(1.0));
        expect(info.isFullAvailability, isTrue);
      });
    });
  });
}
