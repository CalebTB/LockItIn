import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/data/models/friendship_model.dart';

void main() {
  group('maskEmail', () {
    test('should mask valid email addresses', () {
      expect(maskEmail('john.doe@example.com'), 'j***@example.com');
      expect(maskEmail('jane@test.org'), 'j***@test.org');
      expect(maskEmail('a@b.com'), 'a***@b.com');
    });

    test('should return invalid email as-is', () {
      expect(maskEmail('notanemail'), 'notanemail');
      expect(maskEmail('invalid'), 'invalid');
    });
  });

  group('FriendshipStatus Enum', () {
    test('should have all expected values', () {
      expect(FriendshipStatus.values.length, 3);
      expect(FriendshipStatus.values.contains(FriendshipStatus.pending), true);
      expect(FriendshipStatus.values.contains(FriendshipStatus.accepted), true);
      expect(FriendshipStatus.values.contains(FriendshipStatus.blocked), true);
    });
  });

  group('FriendshipModel', () {
    final testDate = DateTime(2025, 6, 15, 10, 0);

    FriendshipModel createTestFriendship({
      String id = 'friendship-123',
      String userId = 'user-1',
      String friendId = 'user-2',
      FriendshipStatus status = FriendshipStatus.pending,
      DateTime? createdAt,
      DateTime? acceptedAt,
      DateTime? updatedAt,
    }) {
      return FriendshipModel(
        id: id,
        userId: userId,
        friendId: friendId,
        status: status,
        createdAt: createdAt ?? testDate,
        acceptedAt: acceptedAt,
        updatedAt: updatedAt,
      );
    }

    group('Constructor', () {
      test('should create FriendshipModel with required fields', () {
        final friendship = createTestFriendship();

        expect(friendship.id, 'friendship-123');
        expect(friendship.userId, 'user-1');
        expect(friendship.friendId, 'user-2');
        expect(friendship.status, FriendshipStatus.pending);
        expect(friendship.createdAt, testDate);
      });

      test('should have null optional fields by default', () {
        final friendship = createTestFriendship();

        expect(friendship.acceptedAt, isNull);
        expect(friendship.updatedAt, isNull);
      });

      test('should accept all optional fields', () {
        final friendship = createTestFriendship(
          acceptedAt: testDate,
          updatedAt: testDate,
        );

        expect(friendship.acceptedAt, testDate);
        expect(friendship.updatedAt, testDate);
      });
    });

    group('fromJson', () {
      test('should parse complete JSON correctly', () {
        final json = {
          'id': 'friendship-123',
          'user_id': 'user-1',
          'friend_id': 'user-2',
          'status': 'accepted',
          'created_at': '2025-06-15T10:00:00.000Z',
          'accepted_at': '2025-06-15T11:00:00.000Z',
          'updated_at': '2025-06-15T12:00:00.000Z',
        };

        final friendship = FriendshipModel.fromJson(json);

        expect(friendship.id, 'friendship-123');
        expect(friendship.userId, 'user-1');
        expect(friendship.friendId, 'user-2');
        expect(friendship.status, FriendshipStatus.accepted);
        expect(friendship.acceptedAt, isNotNull);
        expect(friendship.updatedAt, isNotNull);
      });

      test('should parse all status values', () {
        final statuses = ['pending', 'accepted', 'blocked'];
        final expectedStatuses = [
          FriendshipStatus.pending,
          FriendshipStatus.accepted,
          FriendshipStatus.blocked,
        ];

        for (var i = 0; i < statuses.length; i++) {
          final json = {
            'id': 'f1',
            'user_id': 'u1',
            'friend_id': 'u2',
            'status': statuses[i],
            'created_at': '2025-06-15T10:00:00.000Z',
          };
          final friendship = FriendshipModel.fromJson(json);
          expect(friendship.status, expectedStatuses[i]);
        }
      });

      test('should default to pending for unknown status', () {
        final json = {
          'id': 'f1',
          'user_id': 'u1',
          'friend_id': 'u2',
          'status': 'unknown',
          'created_at': '2025-06-15T10:00:00.000Z',
        };
        final friendship = FriendshipModel.fromJson(json);
        expect(friendship.status, FriendshipStatus.pending);
      });
    });

    group('toJson', () {
      test('should serialize to JSON correctly', () {
        final friendship = createTestFriendship(
          status: FriendshipStatus.accepted,
          acceptedAt: testDate,
        );
        final json = friendship.toJson();

        expect(json['id'], 'friendship-123');
        expect(json['user_id'], 'user-1');
        expect(json['friend_id'], 'user-2');
        expect(json['status'], 'accepted');
        expect(json['accepted_at'], testDate.toIso8601String());
      });
    });

    group('toInsertJson', () {
      test('should return minimal fields for insert', () {
        final friendship = createTestFriendship();
        final json = friendship.toInsertJson();

        expect(json.keys.length, 2);
        expect(json['user_id'], 'user-1');
        expect(json['friend_id'], 'user-2');
        expect(json.containsKey('id'), false);
        expect(json.containsKey('status'), false);
      });
    });

    group('Helper Methods', () {
      test('isSender should return true when user is sender', () {
        final friendship = createTestFriendship();
        expect(friendship.isSender('user-1'), true);
        expect(friendship.isSender('user-2'), false);
      });

      test('isReceiver should return true when user is receiver', () {
        final friendship = createTestFriendship();
        expect(friendship.isReceiver('user-2'), true);
        expect(friendship.isReceiver('user-1'), false);
      });

      test('getOtherUserId should return the other user ID', () {
        final friendship = createTestFriendship();
        expect(friendship.getOtherUserId('user-1'), 'user-2');
        expect(friendship.getOtherUserId('user-2'), 'user-1');
      });
    });

    group('copyWith', () {
      test('should create copy with updated status', () {
        final original = createTestFriendship(status: FriendshipStatus.pending);
        final copy = original.copyWith(status: FriendshipStatus.accepted);

        expect(copy.status, FriendshipStatus.accepted);
        expect(copy.id, original.id);
      });

      test('should preserve all fields when no changes specified', () {
        final original = createTestFriendship(
          acceptedAt: testDate,
          updatedAt: testDate,
        );
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.userId, original.userId);
        expect(copy.friendId, original.friendId);
        expect(copy.status, original.status);
        expect(copy.acceptedAt, original.acceptedAt);
      });
    });

    group('Equatable', () {
      test('two friendships with same properties should be equal', () {
        final f1 = createTestFriendship();
        final f2 = createTestFriendship();
        expect(f1, equals(f2));
      });

      test('two friendships with different ids should not be equal', () {
        final f1 = createTestFriendship(id: 'f1');
        final f2 = createTestFriendship(id: 'f2');
        expect(f1, isNot(equals(f2)));
      });
    });
  });

  group('FriendProfile', () {
    final testDate = DateTime(2025, 6, 15, 10, 0);

    group('Constructor', () {
      test('should create FriendProfile with required fields', () {
        const profile = FriendProfile(
          id: 'user-123',
          email: 'test@example.com',
        );

        expect(profile.id, 'user-123');
        expect(profile.email, 'test@example.com');
        expect(profile.fullName, isNull);
        expect(profile.avatarUrl, isNull);
        expect(profile.friendshipId, isNull);
        expect(profile.friendshipSince, isNull);
      });

      test('should accept all optional fields', () {
        final profile = FriendProfile(
          id: 'user-123',
          friendshipId: 'friendship-456',
          fullName: 'John Doe',
          email: 'john@example.com',
          avatarUrl: 'https://example.com/avatar.jpg',
          friendshipSince: testDate,
        );

        expect(profile.friendshipId, 'friendship-456');
        expect(profile.fullName, 'John Doe');
        expect(profile.avatarUrl, 'https://example.com/avatar.jpg');
        expect(profile.friendshipSince, testDate);
      });
    });

    group('fromJson', () {
      test('should parse get_friends result correctly', () {
        final json = {
          'friend_id': 'user-123',
          'friendship_id': 'f-456',
          'full_name': 'John Doe',
          'email': 'john@example.com',
          'avatar_url': 'https://example.com/avatar.jpg',
          'friendship_since': '2025-06-15T10:00:00.000Z',
        };

        final profile = FriendProfile.fromJson(json);

        expect(profile.id, 'user-123');
        expect(profile.friendshipId, 'f-456');
        expect(profile.fullName, 'John Doe');
        expect(profile.email, 'john@example.com');
        expect(profile.avatarUrl, 'https://example.com/avatar.jpg');
        expect(profile.friendshipSince, isNotNull);
      });
    });

    group('fromUserJson', () {
      test('should parse users table and mask email', () {
        final json = {
          'id': 'user-123',
          'full_name': 'Jane Doe',
          'email': 'jane@example.com',
          'avatar_url': null,
        };

        final profile = FriendProfile.fromUserJson(json);

        expect(profile.id, 'user-123');
        expect(profile.fullName, 'Jane Doe');
        expect(profile.email, 'j***@example.com'); // Masked
        expect(profile.avatarUrl, isNull);
      });
    });

    group('Equatable', () {
      test('props should include all fields', () {
        const profile = FriendProfile(
          id: 'u1',
          email: 'test@example.com',
        );
        expect(profile.props.length, 6);
      });
    });
  });

  group('SentRequest', () {
    final testDate = DateTime(2025, 6, 15, 10, 0);

    group('Constructor', () {
      test('should create SentRequest with required fields', () {
        final request = SentRequest(
          requestId: 'req-123',
          recipientId: 'user-456',
          email: 'recipient@example.com',
          sentAt: testDate,
        );

        expect(request.requestId, 'req-123');
        expect(request.recipientId, 'user-456');
        expect(request.email, 'recipient@example.com');
        expect(request.sentAt, testDate);
        expect(request.fullName, isNull);
        expect(request.avatarUrl, isNull);
      });
    });

    group('fromJson', () {
      test('should parse get_sent_requests result correctly', () {
        final json = {
          'request_id': 'req-123',
          'recipient_id': 'user-456',
          'full_name': 'Jane Doe',
          'email': 'jane@example.com',
          'avatar_url': 'https://example.com/avatar.jpg',
          'sent_at': '2025-06-15T10:00:00.000Z',
        };

        final request = SentRequest.fromJson(json);

        expect(request.requestId, 'req-123');
        expect(request.recipientId, 'user-456');
        expect(request.fullName, 'Jane Doe');
        expect(request.email, 'jane@example.com');
        expect(request.avatarUrl, 'https://example.com/avatar.jpg');
      });
    });

    group('Equatable', () {
      test('props should include all fields', () {
        final request = SentRequest(
          requestId: 'r1',
          recipientId: 'u1',
          email: 'test@example.com',
          sentAt: testDate,
        );
        expect(request.props.length, 6);
      });
    });
  });

  group('FriendRequest', () {
    final testDate = DateTime(2025, 6, 15, 10, 0);

    group('Constructor', () {
      test('should create FriendRequest with required fields', () {
        final request = FriendRequest(
          requestId: 'req-123',
          requesterId: 'user-456',
          email: 'requester@example.com',
          requestedAt: testDate,
        );

        expect(request.requestId, 'req-123');
        expect(request.requesterId, 'user-456');
        expect(request.email, 'requester@example.com');
        expect(request.requestedAt, testDate);
      });
    });

    group('fromJson', () {
      test('should parse get_pending_requests result correctly', () {
        final json = {
          'request_id': 'req-123',
          'requester_id': 'user-456',
          'full_name': 'John Doe',
          'email': 'john@example.com',
          'avatar_url': 'https://example.com/avatar.jpg',
          'requested_at': '2025-06-15T10:00:00.000Z',
        };

        final request = FriendRequest.fromJson(json);

        expect(request.requestId, 'req-123');
        expect(request.requesterId, 'user-456');
        expect(request.fullName, 'John Doe');
        expect(request.email, 'john@example.com');
      });
    });
  });

  group('AvailabilityStatus Enum', () {
    test('should have all expected values', () {
      expect(AvailabilityStatus.values.length, 3);
      expect(AvailabilityStatus.values.contains(AvailabilityStatus.free), true);
      expect(AvailabilityStatus.values.contains(AvailabilityStatus.busy), true);
      expect(AvailabilityStatus.values.contains(AvailabilityStatus.unknown), true);
    });
  });

  group('FriendAvailability', () {
    final testDate = DateTime(2025, 6, 15, 12, 0);

    group('Constructor', () {
      test('should create FriendAvailability with required fields', () {
        const availability = FriendAvailability(
          friendId: 'user-123',
          status: AvailabilityStatus.free,
        );

        expect(availability.friendId, 'user-123');
        expect(availability.status, AvailabilityStatus.free);
        expect(availability.busyUntil, isNull);
      });

      test('should accept busyUntil for busy status', () {
        final availability = FriendAvailability(
          friendId: 'user-123',
          status: AvailabilityStatus.busy,
          busyUntil: testDate,
        );

        expect(availability.busyUntil, testDate);
      });
    });

    group('fromJson', () {
      test('should parse availability correctly', () {
        final json = {
          'friend_id': 'user-123',
          'status': 'busy',
          'busy_until': '2025-06-15T12:00:00.000Z',
        };

        final availability = FriendAvailability.fromJson(json);

        expect(availability.friendId, 'user-123');
        expect(availability.status, AvailabilityStatus.busy);
        expect(availability.busyUntil, isNotNull);
      });

      test('should parse all status values', () {
        final statuses = ['free', 'busy', 'unknown'];
        final expectedStatuses = [
          AvailabilityStatus.free,
          AvailabilityStatus.busy,
          AvailabilityStatus.unknown,
        ];

        for (var i = 0; i < statuses.length; i++) {
          final json = {
            'friend_id': 'u1',
            'status': statuses[i],
          };
          final availability = FriendAvailability.fromJson(json);
          expect(availability.status, expectedStatuses[i]);
        }
      });

      test('should default to unknown for invalid status', () {
        final json = {
          'friend_id': 'u1',
          'status': 'invalid',
        };
        final availability = FriendAvailability.fromJson(json);
        expect(availability.status, AvailabilityStatus.unknown);
      });
    });

    group('statusLabel', () {
      test('should return correct label for each status', () {
        const free = FriendAvailability(
          friendId: 'u1',
          status: AvailabilityStatus.free,
        );
        const busy = FriendAvailability(
          friendId: 'u1',
          status: AvailabilityStatus.busy,
        );
        const unknown = FriendAvailability(
          friendId: 'u1',
          status: AvailabilityStatus.unknown,
        );

        expect(free.statusLabel, 'Free');
        expect(busy.statusLabel, 'Busy');
        expect(unknown.statusLabel, 'Unknown');
      });
    });

    group('Equatable', () {
      test('props should include all fields', () {
        const availability = FriendAvailability(
          friendId: 'u1',
          status: AvailabilityStatus.free,
        );
        expect(availability.props.length, 3);
      });
    });
  });
}
