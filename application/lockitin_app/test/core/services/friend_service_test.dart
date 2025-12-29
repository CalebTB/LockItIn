import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lockitin_app/data/models/friendship_model.dart';
import 'package:lockitin_app/core/services/friend_service.dart';

void main() {
  group('FriendService - Exception Handling', () {
    test('FriendServiceException should contain error message', () {
      final exception = FriendServiceException('Test error message');
      expect(exception.message, 'Test error message');
      expect(exception.toString(), 'FriendServiceException: Test error message');
    });

    test('FriendServiceException can have optional code', () {
      final exception = FriendServiceException('Error', code: 'AUTH_ERROR');
      expect(exception.code, 'AUTH_ERROR');
    });

    test('FriendServiceException can be created without code', () {
      final exception = FriendServiceException('Error only');
      expect(exception.code, isNull);
    });
  });

  group('FriendshipModel - JSON Serialization', () {
    test('should create FriendshipModel from JSON', () {
      final json = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'user_id': 'user-1-uuid',
        'friend_id': 'user-2-uuid',
        'status': 'pending',
        'created_at': '2025-12-27T10:30:00.000Z',
        'accepted_at': null,
        'updated_at': null,
      };

      final model = FriendshipModel.fromJson(json);

      expect(model.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(model.userId, 'user-1-uuid');
      expect(model.friendId, 'user-2-uuid');
      expect(model.status, FriendshipStatus.pending);
      expect(model.acceptedAt, isNull);
    });

    test('should handle accepted status', () {
      final json = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'user_id': 'user-1-uuid',
        'friend_id': 'user-2-uuid',
        'status': 'accepted',
        'created_at': '2025-12-27T10:30:00.000Z',
        'accepted_at': '2025-12-27T11:00:00.000Z',
        'updated_at': '2025-12-27T11:00:00.000Z',
      };

      final model = FriendshipModel.fromJson(json);

      expect(model.status, FriendshipStatus.accepted);
      expect(model.acceptedAt, isNotNull);
    });

    test('should handle blocked status', () {
      final json = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'user_id': 'user-1-uuid',
        'friend_id': 'user-2-uuid',
        'status': 'blocked',
        'created_at': '2025-12-27T10:30:00.000Z',
        'accepted_at': null,
        'updated_at': null,
      };

      final model = FriendshipModel.fromJson(json);

      expect(model.status, FriendshipStatus.blocked);
    });

    test('should convert to JSON correctly', () {
      final model = FriendshipModel(
        id: '123',
        userId: 'user-1',
        friendId: 'user-2',
        status: FriendshipStatus.pending,
        createdAt: DateTime(2025, 12, 27, 10, 30),
      );

      final json = model.toJson();

      expect(json['id'], '123');
      expect(json['user_id'], 'user-1');
      expect(json['friend_id'], 'user-2');
      expect(json['status'], 'pending');
    });

    test('should create minimal insert JSON', () {
      final model = FriendshipModel(
        id: '123',
        userId: 'user-1',
        friendId: 'user-2',
        status: FriendshipStatus.pending,
        createdAt: DateTime(2025, 12, 27, 10, 30),
      );

      final json = model.toInsertJson();

      expect(json.containsKey('user_id'), true);
      expect(json.containsKey('friend_id'), true);
      expect(json.containsKey('id'), false);
      expect(json.containsKey('status'), false);
    });
  });

  group('FriendshipModel - Helper Methods', () {
    test('isSender should correctly identify sender', () {
      final model = FriendshipModel(
        id: '123',
        userId: 'user-1',
        friendId: 'user-2',
        status: FriendshipStatus.pending,
        createdAt: DateTime.now(),
      );

      expect(model.isSender('user-1'), true);
      expect(model.isSender('user-2'), false);
    });

    test('isReceiver should correctly identify receiver', () {
      final model = FriendshipModel(
        id: '123',
        userId: 'user-1',
        friendId: 'user-2',
        status: FriendshipStatus.pending,
        createdAt: DateTime.now(),
      );

      expect(model.isReceiver('user-2'), true);
      expect(model.isReceiver('user-1'), false);
    });

    test('getOtherUserId should return correct user', () {
      final model = FriendshipModel(
        id: '123',
        userId: 'user-1',
        friendId: 'user-2',
        status: FriendshipStatus.pending,
        createdAt: DateTime.now(),
      );

      expect(model.getOtherUserId('user-1'), 'user-2');
      expect(model.getOtherUserId('user-2'), 'user-1');
    });

    test('copyWith should update specified fields', () {
      final original = FriendshipModel(
        id: '123',
        userId: 'user-1',
        friendId: 'user-2',
        status: FriendshipStatus.pending,
        createdAt: DateTime(2025, 12, 27),
      );

      final updated = original.copyWith(
        status: FriendshipStatus.accepted,
        acceptedAt: DateTime(2025, 12, 28),
      );

      expect(updated.id, '123');
      expect(updated.status, FriendshipStatus.accepted);
      expect(updated.acceptedAt, DateTime(2025, 12, 28));
      expect(updated.createdAt, original.createdAt);
    });
  });

  group('FriendProfile - JSON Serialization', () {
    test('should create FriendProfile from get_friends result', () {
      final json = {
        'friend_id': 'user-123',
        'full_name': 'John Doe',
        'email': 'john@example.com',
        'avatar_url': 'https://example.com/avatar.jpg',
        'friendship_since': '2025-12-27T10:30:00.000Z',
      };

      final profile = FriendProfile.fromJson(json);

      expect(profile.id, 'user-123');
      expect(profile.fullName, 'John Doe');
      expect(profile.email, 'john@example.com');
      expect(profile.avatarUrl, 'https://example.com/avatar.jpg');
      expect(profile.friendshipSince, isNotNull);
    });

    test('should create FriendProfile from users table', () {
      final json = {
        'id': 'user-456',
        'full_name': 'Jane Doe',
        'email': 'jane@example.com',
        'avatar_url': null,
      };

      final profile = FriendProfile.fromUserJson(json);

      expect(profile.id, 'user-456');
      expect(profile.fullName, 'Jane Doe');
      expect(profile.email, 'jane@example.com');
      expect(profile.avatarUrl, isNull);
      expect(profile.friendshipSince, isNull);
    });

    test('displayName should prefer full name over email', () {
      final profileWithName = FriendProfile(
        id: '123',
        fullName: 'John Doe',
        email: 'john@example.com',
      );

      final profileWithoutName = FriendProfile(
        id: '456',
        email: 'jane@example.com',
      );

      expect(profileWithName.displayName, 'John Doe');
      expect(profileWithoutName.displayName, 'jane@example.com');
    });

    test('initials should be calculated correctly', () {
      final profileTwoNames = FriendProfile(
        id: '123',
        fullName: 'John Doe',
        email: 'john@example.com',
      );

      final profileOneName = FriendProfile(
        id: '456',
        fullName: 'Jane',
        email: 'jane@example.com',
      );

      final profileNoName = FriendProfile(
        id: '789',
        email: 'user@example.com',
      );

      expect(profileTwoNames.initials, 'JD');
      expect(profileOneName.initials, 'J');
      expect(profileNoName.initials, 'U');
    });
  });

  group('FriendRequest - JSON Serialization', () {
    test('should create FriendRequest from get_pending_requests result', () {
      final json = {
        'request_id': 'req-123',
        'requester_id': 'user-456',
        'full_name': 'John Doe',
        'email': 'john@example.com',
        'avatar_url': 'https://example.com/avatar.jpg',
        'requested_at': '2025-12-27T10:30:00.000Z',
      };

      final request = FriendRequest.fromJson(json);

      expect(request.requestId, 'req-123');
      expect(request.requesterId, 'user-456');
      expect(request.fullName, 'John Doe');
      expect(request.email, 'john@example.com');
      expect(request.avatarUrl, 'https://example.com/avatar.jpg');
      expect(request.requestedAt, isNotNull);
    });

    test('displayName should prefer full name over email', () {
      final requestWithName = FriendRequest(
        requestId: '123',
        requesterId: '456',
        fullName: 'John Doe',
        email: 'john@example.com',
        requestedAt: DateTime.now(),
      );

      final requestWithoutName = FriendRequest(
        requestId: '789',
        requesterId: '012',
        email: 'jane@example.com',
        requestedAt: DateTime.now(),
      );

      expect(requestWithName.displayName, 'John Doe');
      expect(requestWithoutName.displayName, 'jane@example.com');
    });

    test('initials should be calculated correctly', () {
      final requestTwoNames = FriendRequest(
        requestId: '123',
        requesterId: '456',
        fullName: 'Alice Bob',
        email: 'alice@example.com',
        requestedAt: DateTime.now(),
      );

      expect(requestTwoNames.initials, 'AB');
    });
  });

  group('SentRequest - JSON Serialization', () {
    test('should create SentRequest from get_sent_requests RPC result', () {
      final json = {
        'request_id': 'req-123',
        'recipient_id': 'user-456',
        'full_name': 'Jane Doe',
        'email': 'jane@example.com',
        'avatar_url': 'https://example.com/avatar.jpg',
        'sent_at': '2025-12-27T10:30:00.000Z',
      };

      final request = SentRequest.fromJson(json);

      expect(request.requestId, 'req-123');
      expect(request.recipientId, 'user-456');
      expect(request.fullName, 'Jane Doe');
      expect(request.email, 'jane@example.com');
      expect(request.avatarUrl, 'https://example.com/avatar.jpg');
      expect(request.sentAt, isNotNull);
    });

    test('should handle null full_name and avatar_url', () {
      final json = {
        'request_id': 'req-789',
        'recipient_id': 'user-012',
        'full_name': null,
        'email': 'user@example.com',
        'avatar_url': null,
        'sent_at': '2025-12-27T11:00:00.000Z',
      };

      final request = SentRequest.fromJson(json);

      expect(request.requestId, 'req-789');
      expect(request.fullName, isNull);
      expect(request.email, 'user@example.com');
      expect(request.avatarUrl, isNull);
    });

    test('displayName should prefer full name over email', () {
      final requestWithName = SentRequest(
        requestId: '123',
        recipientId: '456',
        fullName: 'John Doe',
        email: 'john@example.com',
        sentAt: DateTime.now(),
      );

      final requestWithoutName = SentRequest(
        requestId: '789',
        recipientId: '012',
        email: 'jane@example.com',
        sentAt: DateTime.now(),
      );

      expect(requestWithName.displayName, 'John Doe');
      expect(requestWithoutName.displayName, 'jane@example.com');
    });

    test('initials should be calculated correctly', () {
      final requestTwoNames = SentRequest(
        requestId: '123',
        recipientId: '456',
        fullName: 'Bob Smith',
        email: 'bob@example.com',
        sentAt: DateTime.now(),
      );

      expect(requestTwoNames.initials, 'BS');
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

  group('FriendService - PostgrestException Handling', () {
    test('PostgrestException can be created for duplicate friendship', () {
      final exception = PostgrestException(
        message: 'duplicate key value violates unique constraint "friendships_pkey"',
        code: '23505',
      );

      expect(exception.code, '23505');
      expect(exception.message, contains('duplicate'));
    });

    test('PostgrestException can be created for user not found', () {
      final exception = PostgrestException(
        message: 'insert or update on table "friendships" violates foreign key constraint',
        code: '23503',
      );

      expect(exception.code, '23503');
      expect(exception.message, contains('foreign key'));
    });

    test('PostgrestException can be created for RLS violation', () {
      final exception = PostgrestException(
        message: 'new row violates row-level security policy for table "friendships"',
        code: '42501',
      );

      expect(exception.code, '42501');
      expect(exception.message, contains('row-level security'));
    });

    test('Friend-specific error message mappings should be correct', () {
      // Document the expected friend service error mappings
      final friendErrorMappings = {
        '23505': 'This relationship already exists',
        '23503': 'User not found',
        '42501': 'Permission denied',
        'PGRST116': 'Session expired, please log in again',
        'PGRST301': 'Record not found',
      };

      expect(friendErrorMappings['23505'], 'This relationship already exists');
      expect(friendErrorMappings['23503'], 'User not found');
      expect(friendErrorMappings['42501'], 'Permission denied');
    });
  });
}
