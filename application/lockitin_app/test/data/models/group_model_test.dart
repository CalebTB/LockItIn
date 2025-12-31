import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/data/models/group_model.dart';

void main() {
  group('GroupMemberRole Enum', () {
    test('should have all expected values', () {
      expect(GroupMemberRole.values.length, 3);
      expect(GroupMemberRole.values.contains(GroupMemberRole.owner), true);
      expect(GroupMemberRole.values.contains(GroupMemberRole.coOwner), true);
      expect(GroupMemberRole.values.contains(GroupMemberRole.member), true);
    });
  });

  group('GroupModel', () {
    final testDate = DateTime(2025, 6, 15, 10, 0);

    GroupModel createTestGroup({
      String id = 'group-123',
      String name = 'Test Group',
      String emoji = '👥',
      String createdBy = 'user-456',
      DateTime? createdAt,
      DateTime? updatedAt,
      int memberCount = 0,
      bool membersCanInvite = true,
    }) {
      return GroupModel(
        id: id,
        name: name,
        emoji: emoji,
        createdBy: createdBy,
        createdAt: createdAt ?? testDate,
        updatedAt: updatedAt,
        memberCount: memberCount,
        membersCanInvite: membersCanInvite,
      );
    }

    group('Constructor', () {
      test('should create GroupModel with required fields', () {
        final group = createTestGroup();

        expect(group.id, 'group-123');
        expect(group.name, 'Test Group');
        expect(group.emoji, '👥');
        expect(group.createdBy, 'user-456');
        expect(group.createdAt, testDate);
      });

      test('should have default values for optional fields', () {
        final group = createTestGroup();

        expect(group.updatedAt, isNull);
        expect(group.memberCount, 0);
        expect(group.membersCanInvite, true);
      });

      test('should accept all optional fields', () {
        final group = createTestGroup(
          updatedAt: testDate,
          memberCount: 5,
          membersCanInvite: false,
        );

        expect(group.updatedAt, testDate);
        expect(group.memberCount, 5);
        expect(group.membersCanInvite, false);
      });
    });

    group('fromJson', () {
      test('should parse complete JSON correctly', () {
        final json = {
          'id': 'group-123',
          'name': 'Team Lunch',
          'emoji': '🍕',
          'created_by': 'user-456',
          'created_at': '2025-06-15T10:00:00.000Z',
          'updated_at': '2025-06-15T12:00:00.000Z',
          'member_count': 8,
          'members_can_invite': false,
        };

        final group = GroupModel.fromJson(json);

        expect(group.id, 'group-123');
        expect(group.name, 'Team Lunch');
        expect(group.emoji, '🍕');
        expect(group.createdBy, 'user-456');
        expect(group.memberCount, 8);
        expect(group.membersCanInvite, false);
      });

      test('should handle null optional fields', () {
        final json = {
          'id': 'g1',
          'name': 'Group',
          'emoji': null,
          'created_by': 'u1',
          'created_at': '2025-06-15T10:00:00.000Z',
          'updated_at': null,
          'member_count': null,
          'members_can_invite': null,
        };

        final group = GroupModel.fromJson(json);

        expect(group.emoji, '👥'); // Default emoji
        expect(group.updatedAt, isNull);
        expect(group.memberCount, 0); // Default count
        expect(group.membersCanInvite, true); // Default value
      });
    });

    group('fromRpcJson', () {
      test('should parse get_user_groups result correctly', () {
        final json = {
          'group_id': 'group-123',
          'name': 'Friends',
          'emoji': '🎉',
          'created_by': 'user-456',
          'created_at': '2025-06-15T10:00:00.000Z',
          'member_count': 5,
          'members_can_invite': true,
        };

        final group = GroupModel.fromRpcJson(json);

        expect(group.id, 'group-123');
        expect(group.name, 'Friends');
        expect(group.emoji, '🎉');
        expect(group.memberCount, 5);
      });
    });

    group('toInsertJson', () {
      test('should return fields needed for insert', () {
        final group = createTestGroup(
          name: 'New Group',
          emoji: '🎯',
          createdBy: 'creator-123',
          membersCanInvite: false,
        );
        final json = group.toInsertJson();

        expect(json['name'], 'New Group');
        expect(json['emoji'], '🎯');
        expect(json['created_by'], 'creator-123');
        expect(json['members_can_invite'], false);
        expect(json.containsKey('id'), false);
        expect(json.containsKey('created_at'), false);
      });
    });

    group('toUpdateJson', () {
      test('should return fields needed for update', () {
        final group = createTestGroup(
          name: 'Updated Name',
          emoji: '🔥',
          membersCanInvite: true,
        );
        final json = group.toUpdateJson();

        expect(json['name'], 'Updated Name');
        expect(json['emoji'], '🔥');
        expect(json['members_can_invite'], true);
        expect(json['updated_at'], isNotNull);
        expect(json.containsKey('id'), false);
        expect(json.containsKey('created_by'), false);
      });
    });

    group('copyWith', () {
      test('should create copy with updated name', () {
        final original = createTestGroup(name: 'Original');
        final copy = original.copyWith(name: 'New Name');

        expect(copy.name, 'New Name');
        expect(copy.id, original.id);
        expect(copy.emoji, original.emoji);
      });

      test('should create copy with updated member count', () {
        final original = createTestGroup(memberCount: 5);
        final copy = original.copyWith(memberCount: 10);

        expect(copy.memberCount, 10);
        expect(original.memberCount, 5);
      });

      test('should preserve all fields when no changes specified', () {
        final original = createTestGroup(
          name: 'Group',
          emoji: '🎯',
          memberCount: 8,
          membersCanInvite: false,
        );
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.name, original.name);
        expect(copy.emoji, original.emoji);
        expect(copy.memberCount, original.memberCount);
        expect(copy.membersCanInvite, original.membersCanInvite);
      });
    });

    group('Equatable', () {
      test('two groups with same properties should be equal', () {
        final g1 = createTestGroup();
        final g2 = createTestGroup();
        expect(g1, equals(g2));
      });

      test('two groups with different ids should not be equal', () {
        final g1 = createTestGroup(id: 'g1');
        final g2 = createTestGroup(id: 'g2');
        expect(g1, isNot(equals(g2)));
      });

      test('props should include all fields', () {
        final group = createTestGroup();
        expect(group.props.length, 8);
      });
    });
  });

  group('GroupMemberModel', () {
    final testDate = DateTime(2025, 6, 15, 10, 0);

    group('Constructor', () {
      test('should create GroupMemberModel with required fields', () {
        final member = GroupMemberModel(
          id: 'member-123',
          groupId: 'group-456',
          userId: 'user-789',
          role: GroupMemberRole.member,
          joinedAt: testDate,
        );

        expect(member.id, 'member-123');
        expect(member.groupId, 'group-456');
        expect(member.userId, 'user-789');
        expect(member.role, GroupMemberRole.member);
        expect(member.joinedAt, testDate);
      });
    });

    group('fromJson', () {
      test('should parse JSON correctly', () {
        final json = {
          'id': 'member-123',
          'group_id': 'group-456',
          'user_id': 'user-789',
          'role': 'owner',
          'joined_at': '2025-06-15T10:00:00.000Z',
        };

        final member = GroupMemberModel.fromJson(json);

        expect(member.id, 'member-123');
        expect(member.groupId, 'group-456');
        expect(member.userId, 'user-789');
        expect(member.role, GroupMemberRole.owner);
      });
    });

    group('Role Conversion', () {
      test('roleToString should convert roles correctly', () {
        expect(GroupMemberModel.roleToString(GroupMemberRole.owner), 'owner');
        expect(GroupMemberModel.roleToString(GroupMemberRole.coOwner), 'co_owner');
        expect(GroupMemberModel.roleToString(GroupMemberRole.member), 'member');
      });

      test('roleFromString should parse roles correctly', () {
        expect(GroupMemberModel.roleFromString('owner'), GroupMemberRole.owner);
        expect(GroupMemberModel.roleFromString('co_owner'), GroupMemberRole.coOwner);
        expect(GroupMemberModel.roleFromString('coowner'), GroupMemberRole.coOwner);
        expect(GroupMemberModel.roleFromString('member'), GroupMemberRole.member);
      });

      test('roleFromString should default to member for unknown', () {
        expect(GroupMemberModel.roleFromString('unknown'), GroupMemberRole.member);
        expect(GroupMemberModel.roleFromString('admin'), GroupMemberRole.member);
      });
    });

    group('toInsertJson', () {
      test('should return fields needed for insert', () {
        final member = GroupMemberModel(
          id: 'member-123',
          groupId: 'group-456',
          userId: 'user-789',
          role: GroupMemberRole.coOwner,
          joinedAt: testDate,
        );
        final json = member.toInsertJson();

        expect(json['group_id'], 'group-456');
        expect(json['user_id'], 'user-789');
        expect(json['role'], 'co_owner');
        expect(json.containsKey('id'), false);
        expect(json.containsKey('joined_at'), false);
      });
    });

    group('Permission Properties', () {
      test('canManageMembers should be true for owner and co-owner', () {
        final owner = GroupMemberModel(
          id: 'm1',
          groupId: 'g1',
          userId: 'u1',
          role: GroupMemberRole.owner,
          joinedAt: testDate,
        );
        final coOwner = GroupMemberModel(
          id: 'm2',
          groupId: 'g1',
          userId: 'u2',
          role: GroupMemberRole.coOwner,
          joinedAt: testDate,
        );
        final member = GroupMemberModel(
          id: 'm3',
          groupId: 'g1',
          userId: 'u3',
          role: GroupMemberRole.member,
          joinedAt: testDate,
        );

        expect(owner.canManageMembers, true);
        expect(coOwner.canManageMembers, true);
        expect(member.canManageMembers, false);
      });

      test('canDeleteGroup should be true only for owner', () {
        final owner = GroupMemberModel(
          id: 'm1',
          groupId: 'g1',
          userId: 'u1',
          role: GroupMemberRole.owner,
          joinedAt: testDate,
        );
        final coOwner = GroupMemberModel(
          id: 'm2',
          groupId: 'g1',
          userId: 'u2',
          role: GroupMemberRole.coOwner,
          joinedAt: testDate,
        );

        expect(owner.canDeleteGroup, true);
        expect(coOwner.canDeleteGroup, false);
      });
    });

    group('Equatable', () {
      test('props should include all fields', () {
        final member = GroupMemberModel(
          id: 'm1',
          groupId: 'g1',
          userId: 'u1',
          role: GroupMemberRole.member,
          joinedAt: testDate,
        );
        expect(member.props.length, 5);
      });
    });
  });

  group('GroupMemberProfile', () {
    final testDate = DateTime(2025, 6, 15, 10, 0);

    group('Constructor', () {
      test('should create GroupMemberProfile with required fields', () {
        final profile = GroupMemberProfile(
          memberId: 'member-123',
          userId: 'user-456',
          email: 'test@example.com',
          role: GroupMemberRole.member,
          joinedAt: testDate,
        );

        expect(profile.memberId, 'member-123');
        expect(profile.userId, 'user-456');
        expect(profile.email, 'test@example.com');
        expect(profile.role, GroupMemberRole.member);
        expect(profile.fullName, isNull);
        expect(profile.avatarUrl, isNull);
      });
    });

    group('fromJson', () {
      test('should parse get_group_members result correctly', () {
        final json = {
          'member_id': 'member-123',
          'user_id': 'user-456',
          'full_name': 'John Doe',
          'email': 'john@example.com',
          'avatar_url': 'https://example.com/avatar.jpg',
          'role': 'co_owner',
          'joined_at': '2025-06-15T10:00:00.000Z',
        };

        final profile = GroupMemberProfile.fromJson(json);

        expect(profile.memberId, 'member-123');
        expect(profile.userId, 'user-456');
        expect(profile.fullName, 'John Doe');
        expect(profile.email, 'john@example.com');
        expect(profile.avatarUrl, 'https://example.com/avatar.jpg');
        expect(profile.role, GroupMemberRole.coOwner);
      });
    });

    group('roleDisplayName', () {
      test('should return correct display name for each role', () {
        final owner = GroupMemberProfile(
          memberId: 'm1',
          userId: 'u1',
          email: 'owner@example.com',
          role: GroupMemberRole.owner,
          joinedAt: testDate,
        );
        final coOwner = GroupMemberProfile(
          memberId: 'm2',
          userId: 'u2',
          email: 'coowner@example.com',
          role: GroupMemberRole.coOwner,
          joinedAt: testDate,
        );
        final member = GroupMemberProfile(
          memberId: 'm3',
          userId: 'u3',
          email: 'member@example.com',
          role: GroupMemberRole.member,
          joinedAt: testDate,
        );

        expect(owner.roleDisplayName, 'Owner');
        expect(coOwner.roleDisplayName, 'Co-Owner');
        expect(member.roleDisplayName, 'Member');
      });
    });

    group('Equatable', () {
      test('props should include all fields', () {
        final profile = GroupMemberProfile(
          memberId: 'm1',
          userId: 'u1',
          email: 'test@example.com',
          role: GroupMemberRole.member,
          joinedAt: testDate,
        );
        expect(profile.props.length, 7);
      });
    });
  });

  group('GroupInvite', () {
    final testDate = DateTime(2025, 6, 15, 10, 0);

    group('Constructor', () {
      test('should create GroupInvite with required fields', () {
        final invite = GroupInvite(
          id: 'invite-123',
          groupId: 'group-456',
          groupName: 'Team Lunch',
          groupEmoji: '🍕',
          invitedBy: 'user-789',
          inviterName: 'John Doe',
          invitedAt: testDate,
        );

        expect(invite.id, 'invite-123');
        expect(invite.groupId, 'group-456');
        expect(invite.groupName, 'Team Lunch');
        expect(invite.groupEmoji, '🍕');
        expect(invite.invitedBy, 'user-789');
        expect(invite.inviterName, 'John Doe');
        expect(invite.invitedAt, testDate);
      });
    });

    group('fromJson', () {
      test('should parse get_pending_group_invites result correctly', () {
        final json = {
          'invite_id': 'invite-123',
          'group_id': 'group-456',
          'group_name': 'Friends',
          'group_emoji': '🎉',
          'invited_by': 'user-789',
          'inviter_name': 'Jane Doe',
          'invited_at': '2025-06-15T10:00:00.000Z',
        };

        final invite = GroupInvite.fromJson(json);

        expect(invite.id, 'invite-123');
        expect(invite.groupId, 'group-456');
        expect(invite.groupName, 'Friends');
        expect(invite.groupEmoji, '🎉');
        expect(invite.invitedBy, 'user-789');
        expect(invite.inviterName, 'Jane Doe');
      });

      test('should handle null optional fields with defaults', () {
        final json = {
          'invite_id': 'i1',
          'group_id': 'g1',
          'group_name': 'Group',
          'group_emoji': null,
          'invited_by': 'u1',
          'inviter_name': null,
          'invited_at': '2025-06-15T10:00:00.000Z',
        };

        final invite = GroupInvite.fromJson(json);

        expect(invite.groupEmoji, '👥'); // Default emoji
        expect(invite.inviterName, 'Someone'); // Default name
      });
    });

    group('Equatable', () {
      test('props should include all fields', () {
        final invite = GroupInvite(
          id: 'i1',
          groupId: 'g1',
          groupName: 'Group',
          groupEmoji: '👥',
          invitedBy: 'u1',
          inviterName: 'John',
          invitedAt: testDate,
        );
        expect(invite.props.length, 7);
      });

      test('two invites with same properties should be equal', () {
        final i1 = GroupInvite(
          id: 'i1',
          groupId: 'g1',
          groupName: 'Group',
          groupEmoji: '👥',
          invitedBy: 'u1',
          inviterName: 'John',
          invitedAt: testDate,
        );
        final i2 = GroupInvite(
          id: 'i1',
          groupId: 'g1',
          groupName: 'Group',
          groupEmoji: '👥',
          invitedBy: 'u1',
          inviterName: 'John',
          invitedAt: testDate,
        );
        expect(i1, equals(i2));
      });
    });
  });
}
