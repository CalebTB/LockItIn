import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/presentation/widgets/group_members_section.dart';
import 'package:lockitin_app/core/theme/app_colors.dart';

void main() {
  group('GroupMembersSection', () {
    group('getMemberColor', () {
      test('should return pink for index 0', () {
        expect(GroupMembersSection.getMemberColor(0), AppColors.memberPink);
      });

      test('should return amber for index 1', () {
        expect(GroupMembersSection.getMemberColor(1), AppColors.memberAmber);
      });

      test('should return violet for index 2', () {
        expect(GroupMembersSection.getMemberColor(2), AppColors.memberViolet);
      });

      test('should return cyan for index 3', () {
        expect(GroupMembersSection.getMemberColor(3), AppColors.memberCyan);
      });

      test('should return emerald for index 4', () {
        expect(GroupMembersSection.getMemberColor(4), AppColors.memberEmerald);
      });

      test('should return purple for index 5', () {
        expect(GroupMembersSection.getMemberColor(5), AppColors.memberPurple);
      });

      test('should return teal for index 6', () {
        expect(GroupMembersSection.getMemberColor(6), AppColors.memberTeal);
      });

      test('should wrap around for index 7 (back to pink)', () {
        expect(GroupMembersSection.getMemberColor(7), AppColors.memberPink);
      });

      test('should wrap around correctly for larger indices', () {
        // Index 14 should be same as index 0 (14 % 7 = 0)
        expect(GroupMembersSection.getMemberColor(14), AppColors.memberPink);
        
        // Index 10 should be same as index 3 (10 % 7 = 3)
        expect(GroupMembersSection.getMemberColor(10), AppColors.memberCyan);
      });
    });
  });
}
