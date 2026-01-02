import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/data/models/user_model.dart';

void main() {
  group('UserModel', () {
    final testDate = DateTime(2025, 6, 15, 10, 0);

    UserModel createTestUser({
      String id = 'user-123',
      String email = 'test@example.com',
      String? fullName,
      String? avatarUrl,
      String? bio,
      DateTime? createdAt,
      DateTime? updatedAt,
    }) {
      return UserModel(
        id: id,
        email: email,
        fullName: fullName,
        avatarUrl: avatarUrl,
        bio: bio,
        createdAt: createdAt ?? testDate,
        updatedAt: updatedAt,
      );
    }

    group('Constructor', () {
      test('should create UserModel with required fields', () {
        final user = createTestUser();

        expect(user.id, 'user-123');
        expect(user.email, 'test@example.com');
        expect(user.createdAt, testDate);
      });

      test('should have null optional fields by default', () {
        final user = createTestUser();

        expect(user.fullName, isNull);
        expect(user.avatarUrl, isNull);
        expect(user.bio, isNull);
        expect(user.updatedAt, isNull);
      });

      test('should accept all optional fields', () {
        final user = createTestUser(
          fullName: 'John Doe',
          avatarUrl: 'https://example.com/avatar.jpg',
          bio: 'Test bio',
          updatedAt: testDate,
        );

        expect(user.fullName, 'John Doe');
        expect(user.avatarUrl, 'https://example.com/avatar.jpg');
        expect(user.bio, 'Test bio');
        expect(user.updatedAt, testDate);
      });
    });

    group('fromJson', () {
      test('should parse complete JSON correctly', () {
        final json = {
          'id': 'user-123',
          'email': 'test@example.com',
          'full_name': 'John Doe',
          'avatar_url': 'https://example.com/avatar.jpg',
          'bio': 'Test bio',
          'created_at': '2025-06-15T10:00:00.000Z',
          'updated_at': '2025-06-15T11:00:00.000Z',
        };

        final user = UserModel.fromJson(json);

        expect(user.id, 'user-123');
        expect(user.email, 'test@example.com');
        expect(user.fullName, 'John Doe');
        expect(user.avatarUrl, 'https://example.com/avatar.jpg');
        expect(user.bio, 'Test bio');
        expect(user.updatedAt, isNotNull);
      });

      test('should handle null optional fields', () {
        final json = {
          'id': 'user-123',
          'email': 'test@example.com',
          'full_name': null,
          'avatar_url': null,
          'bio': null,
          'created_at': '2025-06-15T10:00:00.000Z',
          'updated_at': null,
        };

        final user = UserModel.fromJson(json);

        expect(user.fullName, isNull);
        expect(user.avatarUrl, isNull);
        expect(user.bio, isNull);
        expect(user.updatedAt, isNull);
      });

      test('should parse dates correctly', () {
        final json = {
          'id': 'u1',
          'email': 'test@example.com',
          'created_at': '2025-06-15T10:00:00.000Z',
          'updated_at': '2025-06-15T12:30:45.123Z',
        };

        final user = UserModel.fromJson(json);

        expect(user.createdAt.year, 2025);
        expect(user.createdAt.month, 6);
        expect(user.createdAt.day, 15);
        expect(user.updatedAt!.hour, 12);
        expect(user.updatedAt!.minute, 30);
      });
    });

    group('toJson', () {
      test('should serialize to JSON correctly', () {
        final user = createTestUser(
          fullName: 'John Doe',
          avatarUrl: 'https://example.com/avatar.jpg',
          bio: 'Test bio',
          updatedAt: testDate,
        );

        final json = user.toJson();

        expect(json['id'], 'user-123');
        expect(json['email'], 'test@example.com');
        expect(json['full_name'], 'John Doe');
        expect(json['avatar_url'], 'https://example.com/avatar.jpg');
        expect(json['bio'], 'Test bio');
        expect(json['created_at'], testDate.toIso8601String());
        expect(json['updated_at'], testDate.toIso8601String());
      });

      test('should include null for unset optional fields', () {
        final user = createTestUser();
        final json = user.toJson();

        expect(json['full_name'], isNull);
        expect(json['avatar_url'], isNull);
        expect(json['bio'], isNull);
        expect(json['updated_at'], isNull);
      });
    });

    group('copyWith', () {
      test('should create copy with updated email', () {
        final original = createTestUser();
        final copy = original.copyWith(email: 'new@example.com');

        expect(copy.email, 'new@example.com');
        expect(copy.id, original.id);
      });

      test('should create copy with updated fullName', () {
        final original = createTestUser();
        final copy = original.copyWith(fullName: 'Jane Doe');

        expect(copy.fullName, 'Jane Doe');
        expect(original.fullName, isNull);
      });

      test('should create copy with updated avatarUrl', () {
        final original = createTestUser();
        final copy = original.copyWith(avatarUrl: 'https://example.com/new.jpg');

        expect(copy.avatarUrl, 'https://example.com/new.jpg');
      });

      test('should create copy with updated bio', () {
        final original = createTestUser();
        final copy = original.copyWith(bio: 'New bio');

        expect(copy.bio, 'New bio');
      });

      test('should preserve all fields when no changes specified', () {
        final original = createTestUser(
          fullName: 'John Doe',
          avatarUrl: 'https://example.com/avatar.jpg',
          bio: 'Bio',
          updatedAt: testDate,
        );
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.email, original.email);
        expect(copy.fullName, original.fullName);
        expect(copy.avatarUrl, original.avatarUrl);
        expect(copy.bio, original.bio);
        expect(copy.createdAt, original.createdAt);
        expect(copy.updatedAt, original.updatedAt);
      });
    });

    group('Equatable', () {
      test('two users with same properties should be equal', () {
        final user1 = createTestUser();
        final user2 = createTestUser();

        expect(user1, equals(user2));
      });

      test('two users with different ids should not be equal', () {
        final user1 = createTestUser(id: 'user-1');
        final user2 = createTestUser(id: 'user-2');

        expect(user1, isNot(equals(user2)));
      });

      test('two users with different emails should not be equal', () {
        final user1 = createTestUser(email: 'user1@example.com');
        final user2 = createTestUser(email: 'user2@example.com');

        expect(user1, isNot(equals(user2)));
      });

      test('two users with different optional fields should not be equal', () {
        final user1 = createTestUser(fullName: 'John');
        final user2 = createTestUser(fullName: 'Jane');

        expect(user1, isNot(equals(user2)));
      });

      test('props should include all fields', () {
        final user = createTestUser();

        expect(user.props.length, 7);
        expect(user.props.contains(user.id), true);
        expect(user.props.contains(user.email), true);
        expect(user.props.contains(user.fullName), true);
        expect(user.props.contains(user.avatarUrl), true);
        expect(user.props.contains(user.bio), true);
        expect(user.props.contains(user.createdAt), true);
        expect(user.props.contains(user.updatedAt), true);
      });

      test('hashCode should be consistent for equal users', () {
        final user1 = createTestUser();
        final user2 = createTestUser();

        expect(user1.hashCode, equals(user2.hashCode));
      });
    });

    group('JSON Round Trip', () {
      test('should survive JSON serialization and deserialization', () {
        final original = createTestUser(
          fullName: 'John Doe',
          avatarUrl: 'https://example.com/avatar.jpg',
          bio: 'Test bio',
          updatedAt: testDate,
        );

        final json = original.toJson();
        final restored = UserModel.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.email, original.email);
        expect(restored.fullName, original.fullName);
        expect(restored.avatarUrl, original.avatarUrl);
        expect(restored.bio, original.bio);
      });

      test('should preserve null values in round trip', () {
        final original = createTestUser();

        final json = original.toJson();
        final restored = UserModel.fromJson(json);

        expect(restored.fullName, isNull);
        expect(restored.avatarUrl, isNull);
        expect(restored.bio, isNull);
        expect(restored.updatedAt, isNull);
      });
    });
  });
}
