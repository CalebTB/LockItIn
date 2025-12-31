import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/data/models/notification_model.dart';

void main() {
  group('NotificationType Enum', () {
    test('should have all expected values', () {
      expect(NotificationType.values.length, 19);
      // Proposal notifications
      expect(NotificationType.values.contains(NotificationType.proposalCreated), true);
      expect(NotificationType.values.contains(NotificationType.proposalVoteCast), true);
      expect(NotificationType.values.contains(NotificationType.proposalConfirmed), true);
      expect(NotificationType.values.contains(NotificationType.proposalCancelled), true);
      expect(NotificationType.values.contains(NotificationType.proposalExpired), true);
      expect(NotificationType.values.contains(NotificationType.votingReminder), true);
      // Group notifications
      expect(NotificationType.values.contains(NotificationType.groupInvite), true);
      expect(NotificationType.values.contains(NotificationType.groupInviteAccepted), true);
      expect(NotificationType.values.contains(NotificationType.memberJoined), true);
      expect(NotificationType.values.contains(NotificationType.memberLeft), true);
      expect(NotificationType.values.contains(NotificationType.memberRemoved), true);
      expect(NotificationType.values.contains(NotificationType.roleChanged), true);
      // Friend notifications
      expect(NotificationType.values.contains(NotificationType.friendRequest), true);
      expect(NotificationType.values.contains(NotificationType.friendAccepted), true);
      // Event notifications
      expect(NotificationType.values.contains(NotificationType.eventCreated), true);
      expect(NotificationType.values.contains(NotificationType.eventUpdated), true);
      expect(NotificationType.values.contains(NotificationType.eventCancelled), true);
      expect(NotificationType.values.contains(NotificationType.eventReminder), true);
      // System notifications
      expect(NotificationType.values.contains(NotificationType.systemAnnouncement), true);
    });

    group('fromString', () {
      test('should parse camelCase values', () {
        expect(NotificationType.fromString('proposalCreated'), NotificationType.proposalCreated);
        expect(NotificationType.fromString('groupInvite'), NotificationType.groupInvite);
        expect(NotificationType.fromString('friendRequest'), NotificationType.friendRequest);
      });

      test('should parse snake_case values', () {
        expect(NotificationType.fromString('proposal_created'), NotificationType.proposalCreated);
        expect(NotificationType.fromString('group_invite'), NotificationType.groupInvite);
        expect(NotificationType.fromString('friend_request'), NotificationType.friendRequest);
        expect(NotificationType.fromString('voting_reminder'), NotificationType.votingReminder);
      });

      test('should return systemAnnouncement for unknown values', () {
        expect(NotificationType.fromString('unknown'), NotificationType.systemAnnouncement);
        expect(NotificationType.fromString('invalid_type'), NotificationType.systemAnnouncement);
      });
    });

    group('category', () {
      test('should return Proposals for proposal types', () {
        expect(NotificationType.proposalCreated.category, 'Proposals');
        expect(NotificationType.proposalVoteCast.category, 'Proposals');
        expect(NotificationType.proposalConfirmed.category, 'Proposals');
        expect(NotificationType.proposalCancelled.category, 'Proposals');
        expect(NotificationType.proposalExpired.category, 'Proposals');
        expect(NotificationType.votingReminder.category, 'Proposals');
      });

      test('should return Groups for group types', () {
        expect(NotificationType.groupInvite.category, 'Groups');
        expect(NotificationType.groupInviteAccepted.category, 'Groups');
        expect(NotificationType.memberJoined.category, 'Groups');
        expect(NotificationType.memberLeft.category, 'Groups');
        expect(NotificationType.memberRemoved.category, 'Groups');
        expect(NotificationType.roleChanged.category, 'Groups');
      });

      test('should return Friends for friend types', () {
        expect(NotificationType.friendRequest.category, 'Friends');
        expect(NotificationType.friendAccepted.category, 'Friends');
      });

      test('should return Events for event types', () {
        expect(NotificationType.eventCreated.category, 'Events');
        expect(NotificationType.eventUpdated.category, 'Events');
        expect(NotificationType.eventCancelled.category, 'Events');
        expect(NotificationType.eventReminder.category, 'Events');
      });

      test('should return System for system types', () {
        expect(NotificationType.systemAnnouncement.category, 'System');
      });
    });

    group('requiresAction', () {
      test('should return true for actionable types', () {
        expect(NotificationType.proposalCreated.requiresAction, true);
        expect(NotificationType.votingReminder.requiresAction, true);
        expect(NotificationType.groupInvite.requiresAction, true);
        expect(NotificationType.friendRequest.requiresAction, true);
      });

      test('should return false for non-actionable types', () {
        expect(NotificationType.proposalVoteCast.requiresAction, false);
        expect(NotificationType.proposalConfirmed.requiresAction, false);
        expect(NotificationType.groupInviteAccepted.requiresAction, false);
        expect(NotificationType.friendAccepted.requiresAction, false);
        expect(NotificationType.systemAnnouncement.requiresAction, false);
      });
    });
  });

  group('NotificationModel', () {
    final testDate = DateTime(2025, 6, 15, 10, 0);

    NotificationModel createTestNotification({
      String id = 'notif-123',
      String userId = 'user-456',
      NotificationType type = NotificationType.proposalCreated,
      String title = 'Test Notification',
      String? body,
      Map<String, dynamic> data = const {},
      DateTime? readAt,
      DateTime? actionedAt,
      DateTime? dismissedAt,
      DateTime? createdAt,
      DateTime? expiresAt,
      bool isExpired = false,
    }) {
      return NotificationModel(
        id: id,
        userId: userId,
        type: type,
        title: title,
        body: body,
        data: data,
        readAt: readAt,
        actionedAt: actionedAt,
        dismissedAt: dismissedAt,
        createdAt: createdAt ?? testDate,
        expiresAt: expiresAt,
        isExpired: isExpired,
      );
    }

    group('Constructor', () {
      test('should create NotificationModel with required fields', () {
        final notification = createTestNotification();

        expect(notification.id, 'notif-123');
        expect(notification.userId, 'user-456');
        expect(notification.type, NotificationType.proposalCreated);
        expect(notification.title, 'Test Notification');
        expect(notification.createdAt, testDate);
      });

      test('should have default values for optional fields', () {
        final notification = createTestNotification();

        expect(notification.body, isNull);
        expect(notification.data, isEmpty);
        expect(notification.readAt, isNull);
        expect(notification.actionedAt, isNull);
        expect(notification.dismissedAt, isNull);
        expect(notification.expiresAt, isNull);
        expect(notification.isExpired, false);
      });

      test('should accept all optional fields', () {
        final notification = createTestNotification(
          body: 'Test body',
          data: {'proposal_id': 'prop-123'},
          readAt: testDate,
          actionedAt: testDate,
          dismissedAt: testDate,
          expiresAt: testDate.add(const Duration(days: 7)),
          isExpired: true,
        );

        expect(notification.body, 'Test body');
        expect(notification.data['proposal_id'], 'prop-123');
        expect(notification.readAt, testDate);
        expect(notification.actionedAt, testDate);
        expect(notification.dismissedAt, testDate);
        expect(notification.expiresAt, testDate.add(const Duration(days: 7)));
        expect(notification.isExpired, true);
      });
    });

    group('State Getters', () {
      test('isRead should be true when readAt is set', () {
        final unread = createTestNotification();
        final read = createTestNotification(readAt: testDate);

        expect(unread.isRead, false);
        expect(read.isRead, true);
      });

      test('isActioned should be true when actionedAt is set', () {
        final notActioned = createTestNotification();
        final actioned = createTestNotification(actionedAt: testDate);

        expect(notActioned.isActioned, false);
        expect(actioned.isActioned, true);
      });

      test('isDismissed should be true when dismissedAt is set', () {
        final notDismissed = createTestNotification();
        final dismissed = createTestNotification(dismissedAt: testDate);

        expect(notDismissed.isDismissed, false);
        expect(dismissed.isDismissed, true);
      });
    });

    group('Data Getters', () {
      test('proposalId should extract from data', () {
        final notification = createTestNotification(
          data: {'proposal_id': 'prop-123'},
        );
        expect(notification.proposalId, 'prop-123');
      });

      test('groupId should extract from data', () {
        final notification = createTestNotification(
          data: {'group_id': 'group-123'},
        );
        expect(notification.groupId, 'group-123');
      });

      test('relatedUserId should check multiple keys', () {
        final withSenderId = createTestNotification(
          data: {'sender_id': 'sender-123'},
        );
        final withFriendId = createTestNotification(
          data: {'friend_id': 'friend-123'},
        );
        final withCreatedBy = createTestNotification(
          data: {'created_by': 'creator-123'},
        );
        final withInvitedBy = createTestNotification(
          data: {'invited_by': 'inviter-123'},
        );

        expect(withSenderId.relatedUserId, 'sender-123');
        expect(withFriendId.relatedUserId, 'friend-123');
        expect(withCreatedBy.relatedUserId, 'creator-123');
        expect(withInvitedBy.relatedUserId, 'inviter-123');
      });

      test('relatedUserId should prioritize sender_id', () {
        final notification = createTestNotification(
          data: {
            'sender_id': 'sender-123',
            'friend_id': 'friend-123',
          },
        );
        expect(notification.relatedUserId, 'sender-123');
      });
    });

    group('fromJson', () {
      test('should parse complete JSON correctly', () {
        final json = {
          'id': 'notif-123',
          'user_id': 'user-456',
          'type': 'proposal_created',
          'title': 'New Proposal',
          'body': 'Check out this proposal',
          'data': {'proposal_id': 'prop-123'},
          'read_at': '2025-06-15T10:00:00.000Z',
          'actioned_at': '2025-06-15T11:00:00.000Z',
          'dismissed_at': null,
          'created_at': '2025-06-15T09:00:00.000Z',
          'expires_at': '2025-06-22T09:00:00.000Z',
          'is_expired': false,
        };

        final notification = NotificationModel.fromJson(json);

        expect(notification.id, 'notif-123');
        expect(notification.userId, 'user-456');
        expect(notification.type, NotificationType.proposalCreated);
        expect(notification.title, 'New Proposal');
        expect(notification.body, 'Check out this proposal');
        expect(notification.proposalId, 'prop-123');
        expect(notification.isRead, true);
        expect(notification.isActioned, true);
        expect(notification.isDismissed, false);
        expect(notification.isExpired, false);
      });

      test('should handle null optional fields', () {
        final json = {
          'id': 'notif-123',
          'user_id': null,
          'type': 'friend_request',
          'title': 'Friend Request',
          'body': null,
          'data': null,
          'read_at': null,
          'actioned_at': null,
          'dismissed_at': null,
          'created_at': '2025-06-15T09:00:00.000Z',
          'expires_at': null,
          'is_expired': null,
        };

        final notification = NotificationModel.fromJson(json);

        expect(notification.userId, '');
        expect(notification.body, isNull);
        expect(notification.data, isEmpty);
        expect(notification.readAt, isNull);
        expect(notification.isExpired, false);
      });

      test('should parse all notification types', () {
        final types = [
          'proposal_created',
          'proposal_vote_cast',
          'group_invite',
          'friend_request',
          'event_created',
        ];

        for (final typeStr in types) {
          final json = {
            'id': 'n1',
            'type': typeStr,
            'title': 'T',
            'created_at': '2025-06-15T09:00:00.000Z',
          };
          final notification = NotificationModel.fromJson(json);
          expect(notification.type, isNotNull);
        }
      });
    });

    group('copyWith', () {
      test('should create copy with updated title', () {
        final original = createTestNotification();
        final copy = original.copyWith(title: 'New Title');

        expect(copy.title, 'New Title');
        expect(copy.id, original.id);
        expect(copy.type, original.type);
      });

      test('should create copy with updated read status', () {
        final original = createTestNotification();
        final copy = original.copyWith(readAt: testDate);

        expect(copy.isRead, true);
        expect(original.isRead, false);
      });

      test('should preserve all fields when no changes specified', () {
        final original = createTestNotification(
          body: 'Body',
          data: {'key': 'value'},
          readAt: testDate,
        );
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.body, original.body);
        expect(copy.data, original.data);
        expect(copy.readAt, original.readAt);
      });
    });

    group('Equality', () {
      test('two notifications with same id should be equal', () {
        final notif1 = createTestNotification(id: 'notif-1');
        final notif2 = createTestNotification(id: 'notif-1', title: 'Different');

        expect(notif1, equals(notif2));
      });

      test('two notifications with different ids should not be equal', () {
        final notif1 = createTestNotification(id: 'notif-1');
        final notif2 = createTestNotification(id: 'notif-2');

        expect(notif1, isNot(equals(notif2)));
      });

      test('hashCode should be based on id', () {
        final notif1 = createTestNotification(id: 'notif-1');
        final notif2 = createTestNotification(id: 'notif-1');

        expect(notif1.hashCode, equals(notif2.hashCode));
      });
    });

    group('toString', () {
      test('should return readable string representation', () {
        final notification = createTestNotification();
        final str = notification.toString();

        expect(str, contains('NotificationModel'));
        expect(str, contains('notif-123'));
        expect(str, contains('proposalCreated'));
        expect(str, contains('Test Notification'));
      });
    });
  });
}
