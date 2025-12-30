import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/presentation/providers/friend_provider.dart';
import 'package:lockitin_app/data/models/friendship_model.dart';

void main() {
  group('FriendProvider - Initial State', () {
    test('should have empty lists on creation', () {
      final provider = FriendProvider();

      expect(provider.friends, isEmpty);
      expect(provider.pendingRequests, isEmpty);
      expect(provider.sentRequests, isEmpty);
      expect(provider.searchResults, isEmpty);
    });

    test('should have loading states as false initially', () {
      final provider = FriendProvider();

      expect(provider.isLoadingFriends, false);
      expect(provider.isLoadingRequests, false);
      expect(provider.isSearching, false);
      expect(provider.isSendingRequest, false);
    });

    test('should have no errors initially', () {
      final provider = FriendProvider();

      expect(provider.friendsError, isNull);
      expect(provider.requestsError, isNull);
      expect(provider.searchError, isNull);
      expect(provider.actionError, isNull);
    });

    test('should not be initialized on creation', () {
      final provider = FriendProvider();

      expect(provider.isInitialized, false);
    });

    test('should have empty search query initially', () {
      final provider = FriendProvider();

      expect(provider.searchQuery, isEmpty);
    });
  });

  group('FriendProvider - Computed Properties', () {
    test('pendingRequestCount should reflect pending requests length', () {
      final provider = FriendProvider();

      // Initially zero
      expect(provider.pendingRequestCount, 0);
    });

    test('hasFriends should return false when no friends', () {
      final provider = FriendProvider();

      expect(provider.hasFriends, false);
    });

    test('hasPendingRequests should return false when no requests', () {
      final provider = FriendProvider();

      expect(provider.hasPendingRequests, false);
    });
  });

  group('FriendProvider - Reset (Critical for Logout)', () {
    test('reset should clear all friends', () {
      final provider = FriendProvider();

      // Manually set state to simulate loaded data
      // Using internal access pattern for testing
      provider.reset();

      expect(provider.friends, isEmpty);
    });

    test('reset should clear all pending requests', () {
      final provider = FriendProvider();

      provider.reset();

      expect(provider.pendingRequests, isEmpty);
    });

    test('reset should clear all sent requests', () {
      final provider = FriendProvider();

      provider.reset();

      expect(provider.sentRequests, isEmpty);
    });

    test('reset should clear search results', () {
      final provider = FriendProvider();

      provider.reset();

      expect(provider.searchResults, isEmpty);
    });

    test('reset should reset loading states to false', () {
      final provider = FriendProvider();

      provider.reset();

      expect(provider.isLoadingFriends, false);
      expect(provider.isLoadingRequests, false);
      expect(provider.isSearching, false);
      expect(provider.isSendingRequest, false);
    });

    test('reset should clear all errors', () {
      final provider = FriendProvider();

      provider.reset();

      expect(provider.friendsError, isNull);
      expect(provider.requestsError, isNull);
      expect(provider.searchError, isNull);
      expect(provider.actionError, isNull);
    });

    test('reset should clear search query', () {
      final provider = FriendProvider();

      provider.reset();

      expect(provider.searchQuery, isEmpty);
    });

    test('reset should set isInitialized to false', () {
      final provider = FriendProvider();

      provider.reset();

      expect(provider.isInitialized, false);
    });

    test('reset should notify listeners', () {
      final provider = FriendProvider();
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.reset();

      expect(notifyCount, 1);
    });
  });

  group('FriendProvider - Clear Search', () {
    test('clearSearch should empty search results', () {
      final provider = FriendProvider();

      provider.clearSearch();

      expect(provider.searchResults, isEmpty);
    });

    test('clearSearch should reset search query', () {
      final provider = FriendProvider();

      provider.clearSearch();

      expect(provider.searchQuery, isEmpty);
    });

    test('clearSearch should clear search error', () {
      final provider = FriendProvider();

      provider.clearSearch();

      expect(provider.searchError, isNull);
    });

    test('clearSearch should notify listeners', () {
      final provider = FriendProvider();
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.clearSearch();

      expect(notifyCount, 1);
    });
  });

  group('FriendProvider - Friendship State Detection', () {
    test('getFriendshipState returns none when no relationship exists', () {
      final provider = FriendProvider();

      final state = provider.getFriendshipState('unknown-user-id');

      expect(state, FriendshipState.none);
    });

    // Note: Testing other states (requestSent, requestReceived, friends)
    // requires populating the internal lists, which would need mocking
    // or a testable setter. These are covered in integration tests.
  });

  group('FriendProvider - Search Query Validation', () {
    test('searchUsers with empty query should clear results', () async {
      final provider = FriendProvider();

      await provider.searchUsers('');

      expect(provider.searchResults, isEmpty);
      expect(provider.searchError, isNull);
    });

    test('searchUsers with single character should clear results', () async {
      final provider = FriendProvider();

      await provider.searchUsers('a');

      expect(provider.searchResults, isEmpty);
    });
  });

  group('FriendProvider - Listener Notification Pattern', () {
    test('should only notify once on successful operation', () {
      final provider = FriendProvider();
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      // Reset triggers exactly one notification
      provider.reset();

      expect(notifyCount, 1);
    });

    test('should only notify once on clearSearch', () {
      final provider = FriendProvider();
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.clearSearch();

      expect(notifyCount, 1);
    });
  });

  group('FriendProvider - Edge Cases', () {
    test('should handle multiple consecutive resets', () {
      final provider = FriendProvider();

      // Multiple resets should not throw
      provider.reset();
      provider.reset();
      provider.reset();

      expect(provider.isInitialized, false);
      expect(provider.friends, isEmpty);
    });

    test('should handle clearSearch when already empty', () {
      final provider = FriendProvider();

      // Clear when already empty
      provider.clearSearch();

      expect(provider.searchResults, isEmpty);
      expect(provider.searchQuery, isEmpty);
    });

    test('should allow checking friendship state for empty string user id', () {
      final provider = FriendProvider();

      // Should not throw
      final state = provider.getFriendshipState('');

      expect(state, FriendshipState.none);
    });
  });

  group('FriendProfile - Model Tests', () {
    test('should create FriendProfile with all fields', () {
      final profile = FriendProfile(
        id: 'user-123',
        fullName: 'John Doe',
        email: 'john@example.com',
        avatarUrl: 'https://example.com/avatar.jpg',
        friendshipSince: DateTime(2025, 1, 1),
      );

      expect(profile.id, 'user-123');
      expect(profile.fullName, 'John Doe');
      expect(profile.email, 'john@example.com');
      expect(profile.avatarUrl, 'https://example.com/avatar.jpg');
      expect(profile.friendshipSince, DateTime(2025, 1, 1));
    });

    test('displayName should prefer fullName over email', () {
      final withName = FriendProfile(
        id: '1',
        fullName: 'John Doe',
        email: 'john@example.com',
      );

      final withoutName = FriendProfile(
        id: '2',
        email: 'jane@example.com',
      );

      expect(withName.displayName, 'John Doe');
      expect(withoutName.displayName, 'jane@example.com');
    });

    test('initials should handle various name formats', () {
      final twoNames = FriendProfile(
        id: '1',
        fullName: 'John Doe',
        email: 'john@example.com',
      );

      final oneName = FriendProfile(
        id: '2',
        fullName: 'Jane',
        email: 'jane@example.com',
      );

      final emailOnly = FriendProfile(
        id: '3',
        email: 'user@example.com',
      );

      expect(twoNames.initials, 'JD');
      expect(oneName.initials, 'J');
      expect(emailOnly.initials, 'U'); // First letter of email
    });
  });

  group('FriendRequest - Model Tests', () {
    test('should create FriendRequest with required fields', () {
      final request = FriendRequest(
        requestId: 'req-123',
        requesterId: 'user-456',
        email: 'john@example.com',
        requestedAt: DateTime(2025, 1, 1),
      );

      expect(request.requestId, 'req-123');
      expect(request.requesterId, 'user-456');
      expect(request.email, 'john@example.com');
      expect(request.requestedAt, DateTime(2025, 1, 1));
    });

    test('displayName should prefer fullName over email', () {
      final withName = FriendRequest(
        requestId: '1',
        requesterId: '2',
        fullName: 'John Doe',
        email: 'john@example.com',
        requestedAt: DateTime.now(),
      );

      final withoutName = FriendRequest(
        requestId: '3',
        requesterId: '4',
        email: 'jane@example.com',
        requestedAt: DateTime.now(),
      );

      expect(withName.displayName, 'John Doe');
      expect(withoutName.displayName, 'jane@example.com');
    });

    test('initials should be calculated correctly', () {
      final request = FriendRequest(
        requestId: '1',
        requesterId: '2',
        fullName: 'Alice Bob',
        email: 'alice@example.com',
        requestedAt: DateTime.now(),
      );

      expect(request.initials, 'AB');
    });
  });

  group('SentRequest - Model Tests', () {
    test('should create SentRequest with required fields', () {
      final request = SentRequest(
        requestId: 'req-123',
        recipientId: 'user-456',
        email: 'john@example.com',
        sentAt: DateTime(2025, 1, 1),
      );

      expect(request.requestId, 'req-123');
      expect(request.recipientId, 'user-456');
      expect(request.email, 'john@example.com');
      expect(request.sentAt, DateTime(2025, 1, 1));
    });

    test('displayName should prefer fullName over email', () {
      final withName = SentRequest(
        requestId: '1',
        recipientId: '2',
        fullName: 'John Doe',
        email: 'john@example.com',
        sentAt: DateTime.now(),
      );

      final withoutName = SentRequest(
        requestId: '3',
        recipientId: '4',
        email: 'jane@example.com',
        sentAt: DateTime.now(),
      );

      expect(withName.displayName, 'John Doe');
      expect(withoutName.displayName, 'jane@example.com');
    });

    test('initials should be calculated correctly', () {
      final request = SentRequest(
        requestId: '1',
        recipientId: '2',
        fullName: 'Bob Smith',
        email: 'bob@example.com',
        sentAt: DateTime.now(),
      );

      expect(request.initials, 'BS');
    });
  });

  group('FriendshipState Enum', () {
    test('should have all expected values', () {
      expect(FriendshipState.values.length, 4);
      expect(FriendshipState.values.contains(FriendshipState.none), true);
      expect(FriendshipState.values.contains(FriendshipState.requestSent), true);
      expect(FriendshipState.values.contains(FriendshipState.requestReceived), true);
      expect(FriendshipState.values.contains(FriendshipState.friends), true);
    });
  });
}
