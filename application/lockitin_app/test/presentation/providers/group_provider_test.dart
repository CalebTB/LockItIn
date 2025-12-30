import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/presentation/providers/group_provider.dart';
import 'package:lockitin_app/data/models/group_model.dart';

void main() {
  group('GroupProvider - Initial State', () {
    test('should have empty groups list on creation', () {
      final provider = GroupProvider();

      expect(provider.groups, isEmpty);
    });

    test('should have no selected group on creation', () {
      final provider = GroupProvider();

      expect(provider.selectedGroup, isNull);
    });

    test('should have empty members list on creation', () {
      final provider = GroupProvider();

      expect(provider.selectedGroupMembers, isEmpty);
    });

    test('should have no current user role on creation', () {
      final provider = GroupProvider();

      expect(provider.currentUserRole, isNull);
    });

    test('should have empty pending invites on creation', () {
      final provider = GroupProvider();

      expect(provider.pendingInvites, isEmpty);
    });

    test('should have loading states as false initially', () {
      final provider = GroupProvider();

      expect(provider.isLoadingGroups, false);
      expect(provider.isLoadingMembers, false);
      expect(provider.isLoadingInvites, false);
      expect(provider.isCreatingGroup, false);
      expect(provider.isUpdatingGroup, false);
    });

    test('should have no errors initially', () {
      final provider = GroupProvider();

      expect(provider.groupsError, isNull);
      expect(provider.membersError, isNull);
      expect(provider.invitesError, isNull);
      expect(provider.actionError, isNull);
    });

    test('should not be initialized on creation', () {
      final provider = GroupProvider();

      expect(provider.isInitialized, false);
    });
  });

  group('GroupProvider - Computed Properties', () {
    test('groupCount should reflect groups length', () {
      final provider = GroupProvider();

      expect(provider.groupCount, 0);
    });

    test('pendingInviteCount should reflect pending invites length', () {
      final provider = GroupProvider();

      expect(provider.pendingInviteCount, 0);
    });

    test('hasGroups should return false when no groups', () {
      final provider = GroupProvider();

      expect(provider.hasGroups, false);
    });

    test('hasPendingInvites should return false when no invites', () {
      final provider = GroupProvider();

      expect(provider.hasPendingInvites, false);
    });

    test('isOwner should return false when no role', () {
      final provider = GroupProvider();

      expect(provider.isOwner, false);
    });

    test('isCoOwner should return false when no role', () {
      final provider = GroupProvider();

      expect(provider.isCoOwner, false);
    });

    test('isOwnerOrCoOwner should return false when no role', () {
      final provider = GroupProvider();

      expect(provider.isOwnerOrCoOwner, false);
    });

    test('canManageMembers should return false when no role', () {
      final provider = GroupProvider();

      expect(provider.canManageMembers, false);
    });

    test('canInviteMembers should return false when no role', () {
      final provider = GroupProvider();

      expect(provider.canInviteMembers, false);
    });
  });

  group('GroupProvider - Reset (Critical for Logout)', () {
    test('reset should clear all groups', () {
      final provider = GroupProvider();

      provider.reset();

      expect(provider.groups, isEmpty);
    });

    test('reset should clear selected group', () {
      final provider = GroupProvider();

      provider.reset();

      expect(provider.selectedGroup, isNull);
    });

    test('reset should clear selected group members', () {
      final provider = GroupProvider();

      provider.reset();

      expect(provider.selectedGroupMembers, isEmpty);
    });

    test('reset should clear current user role', () {
      final provider = GroupProvider();

      provider.reset();

      expect(provider.currentUserRole, isNull);
    });

    test('reset should clear pending invites', () {
      final provider = GroupProvider();

      provider.reset();

      expect(provider.pendingInvites, isEmpty);
    });

    test('reset should reset all loading states to false', () {
      final provider = GroupProvider();

      provider.reset();

      expect(provider.isLoadingGroups, false);
      expect(provider.isLoadingMembers, false);
      expect(provider.isLoadingInvites, false);
      expect(provider.isCreatingGroup, false);
      expect(provider.isUpdatingGroup, false);
    });

    test('reset should clear all errors', () {
      final provider = GroupProvider();

      provider.reset();

      expect(provider.groupsError, isNull);
      expect(provider.membersError, isNull);
      expect(provider.invitesError, isNull);
      expect(provider.actionError, isNull);
    });

    test('reset should set isInitialized to false', () {
      final provider = GroupProvider();

      provider.reset();

      expect(provider.isInitialized, false);
    });

    test('reset should notify listeners', () {
      final provider = GroupProvider();
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.reset();

      expect(notifyCount, 1);
    });
  });

  group('GroupProvider - Clear Selected Group', () {
    test('clearSelectedGroup should clear selected group', () {
      final provider = GroupProvider();

      provider.clearSelectedGroup();

      expect(provider.selectedGroup, isNull);
    });

    test('clearSelectedGroup should clear selected group members', () {
      final provider = GroupProvider();

      provider.clearSelectedGroup();

      expect(provider.selectedGroupMembers, isEmpty);
    });

    test('clearSelectedGroup should clear current user role', () {
      final provider = GroupProvider();

      provider.clearSelectedGroup();

      expect(provider.currentUserRole, isNull);
    });

    test('clearSelectedGroup should clear members error', () {
      final provider = GroupProvider();

      provider.clearSelectedGroup();

      expect(provider.membersError, isNull);
    });

    test('clearSelectedGroup should notify listeners', () {
      final provider = GroupProvider();
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.clearSelectedGroup();

      expect(notifyCount, 1);
    });
  });

  group('GroupProvider - Listener Notification Pattern', () {
    test('should only notify once on reset', () {
      final provider = GroupProvider();
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.reset();

      expect(notifyCount, 1);
    });

    test('should only notify once on clearSelectedGroup', () {
      final provider = GroupProvider();
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.clearSelectedGroup();

      expect(notifyCount, 1);
    });
  });

  group('GroupProvider - Edge Cases', () {
    test('should handle multiple consecutive resets', () {
      final provider = GroupProvider();

      // Multiple resets should not throw
      provider.reset();
      provider.reset();
      provider.reset();

      expect(provider.isInitialized, false);
      expect(provider.groups, isEmpty);
    });

    test('should handle clearSelectedGroup when already empty', () {
      final provider = GroupProvider();

      // Clear when already empty
      provider.clearSelectedGroup();

      expect(provider.selectedGroup, isNull);
      expect(provider.selectedGroupMembers, isEmpty);
    });

    test('should handle multiple clearSelectedGroup calls', () {
      final provider = GroupProvider();

      provider.clearSelectedGroup();
      provider.clearSelectedGroup();

      expect(provider.selectedGroup, isNull);
    });
  });

  group('GroupModel - Model Tests', () {
    test('should create GroupModel with required fields', () {
      final group = GroupModel(
        id: 'group-123',
        name: 'Test Group',
        emoji: '🎉',
        createdBy: 'user-456',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );

      expect(group.id, 'group-123');
      expect(group.name, 'Test Group');
      expect(group.emoji, '🎉');
      expect(group.createdBy, 'user-456');
    });

    test('should have default memberCount of 0', () {
      final group = GroupModel(
        id: 'group-123',
        name: 'Test Group',
        emoji: '🎉',
        createdBy: 'user-456',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(group.memberCount, 0);
    });

    test('should have default membersCanInvite as true', () {
      final group = GroupModel(
        id: 'group-123',
        name: 'Test Group',
        emoji: '🎉',
        createdBy: 'user-456',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(group.membersCanInvite, true);
    });

    test('copyWith should update specified fields', () {
      final original = GroupModel(
        id: 'group-123',
        name: 'Original Name',
        emoji: '🎉',
        createdBy: 'user-456',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        memberCount: 5,
      );

      final updated = original.copyWith(
        name: 'Updated Name',
        memberCount: 10,
      );

      expect(updated.id, 'group-123'); // unchanged
      expect(updated.name, 'Updated Name'); // changed
      expect(updated.emoji, '🎉'); // unchanged
      expect(updated.memberCount, 10); // changed
    });

    test('fromJson should parse group data correctly', () {
      final json = {
        'id': 'group-123',
        'name': 'Test Group',
        'emoji': '🎉',
        'created_by': 'user-456',
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-01T00:00:00.000Z',
        'members_can_invite': true,
      };

      final group = GroupModel.fromJson(json);

      expect(group.id, 'group-123');
      expect(group.name, 'Test Group');
      expect(group.emoji, '🎉');
      expect(group.createdBy, 'user-456');
      expect(group.membersCanInvite, true);
    });
  });

  group('GroupMemberRole Enum', () {
    test('should have all expected values', () {
      expect(GroupMemberRole.values.length, 3);
      expect(GroupMemberRole.values.contains(GroupMemberRole.owner), true);
      expect(GroupMemberRole.values.contains(GroupMemberRole.coOwner), true);
      expect(GroupMemberRole.values.contains(GroupMemberRole.member), true);
    });
  });

  group('GroupMemberProfile - Model Tests', () {
    test('should create GroupMemberProfile with required fields', () {
      final member = GroupMemberProfile(
        memberId: 'membership-123',
        userId: 'user-789',
        role: GroupMemberRole.member,
        joinedAt: DateTime(2025, 1, 1),
        email: 'test@example.com',
      );

      expect(member.memberId, 'membership-123');
      expect(member.userId, 'user-789');
      expect(member.role, GroupMemberRole.member);
      expect(member.email, 'test@example.com');
    });

    test('displayName should prefer fullName over email', () {
      final withName = GroupMemberProfile(
        memberId: '1',
        userId: 'u1',
        role: GroupMemberRole.member,
        joinedAt: DateTime.now(),
        fullName: 'John Doe',
        email: 'john@example.com',
      );

      final withoutName = GroupMemberProfile(
        memberId: '2',
        userId: 'u2',
        role: GroupMemberRole.member,
        joinedAt: DateTime.now(),
        email: 'jane@example.com',
      );

      expect(withName.displayName, 'John Doe');
      expect(withoutName.displayName, 'jane@example.com');
    });

    test('initials should be calculated correctly', () {
      final member = GroupMemberProfile(
        memberId: '1',
        userId: 'u1',
        role: GroupMemberRole.member,
        joinedAt: DateTime.now(),
        fullName: 'Alice Bob',
        email: 'alice@example.com',
      );

      expect(member.initials, 'AB');
    });

    test('roleDisplayName should return correct string for owner', () {
      final owner = GroupMemberProfile(
        memberId: '1',
        userId: 'u1',
        role: GroupMemberRole.owner,
        joinedAt: DateTime.now(),
        email: 'owner@example.com',
      );

      expect(owner.roleDisplayName, 'Owner');
    });

    test('roleDisplayName should return correct string for co-owner', () {
      final coOwner = GroupMemberProfile(
        memberId: '1',
        userId: 'u1',
        role: GroupMemberRole.coOwner,
        joinedAt: DateTime.now(),
        email: 'coowner@example.com',
      );

      expect(coOwner.roleDisplayName, 'Co-Owner');
    });

    test('roleDisplayName should return correct string for member', () {
      final member = GroupMemberProfile(
        memberId: '1',
        userId: 'u1',
        role: GroupMemberRole.member,
        joinedAt: DateTime.now(),
        email: 'member@example.com',
      );

      expect(member.roleDisplayName, 'Member');
    });
  });

  group('GroupInvite - Model Tests', () {
    test('should create GroupInvite with required fields', () {
      final invite = GroupInvite(
        id: 'invite-123',
        groupId: 'group-456',
        groupName: 'Test Group',
        groupEmoji: '🎉',
        invitedBy: 'user-789',
        inviterName: 'John Doe',
        invitedAt: DateTime(2025, 1, 1),
      );

      expect(invite.id, 'invite-123');
      expect(invite.groupId, 'group-456');
      expect(invite.groupName, 'Test Group');
      expect(invite.groupEmoji, '🎉');
      expect(invite.invitedBy, 'user-789');
      expect(invite.inviterName, 'John Doe');
      expect(invite.invitedAt, DateTime(2025, 1, 1));
    });

    test('fromJson should parse invite data correctly', () {
      final json = {
        'invite_id': 'invite-123',
        'group_id': 'group-456',
        'group_name': 'Test Group',
        'group_emoji': '🎉',
        'invited_by': 'user-789',
        'inviter_name': 'John Doe',
        'invited_at': '2025-01-01T00:00:00.000Z',
      };

      final invite = GroupInvite.fromJson(json);

      expect(invite.id, 'invite-123');
      expect(invite.groupId, 'group-456');
      expect(invite.groupName, 'Test Group');
      expect(invite.groupEmoji, '🎉');
      expect(invite.invitedBy, 'user-789');
      expect(invite.inviterName, 'John Doe');
    });

    test('fromJson should handle null group_emoji with default', () {
      final json = {
        'invite_id': 'invite-123',
        'group_id': 'group-456',
        'group_name': 'Test Group',
        'group_emoji': null,
        'invited_by': 'user-789',
        'inviter_name': 'John Doe',
        'invited_at': '2025-01-01T00:00:00.000Z',
      };

      final invite = GroupInvite.fromJson(json);

      expect(invite.groupEmoji, '👥'); // default emoji
    });

    test('fromJson should handle null inviter_name with default', () {
      final json = {
        'invite_id': 'invite-123',
        'group_id': 'group-456',
        'group_name': 'Test Group',
        'group_emoji': '🎉',
        'invited_by': 'user-789',
        'inviter_name': null,
        'invited_at': '2025-01-01T00:00:00.000Z',
      };

      final invite = GroupInvite.fromJson(json);

      expect(invite.inviterName, 'Someone'); // default name
    });
  });
}
