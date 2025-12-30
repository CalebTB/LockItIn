import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:lockitin_app/presentation/screens/friends_screen.dart';
import 'package:lockitin_app/presentation/providers/friend_provider.dart';
import 'package:lockitin_app/data/models/friendship_model.dart';

/// Mock FriendProvider for testing purposes
class MockFriendProvider extends ChangeNotifier implements FriendProvider {
  List<FriendProfile> _friends = [];
  List<FriendRequest> _pendingRequests = [];
  List<SentRequest> _sentRequests = [];
  List<FriendProfile> _searchResults = [];
  bool _isLoadingFriends = false;
  bool _isLoadingRequests = false;
  bool _isSearching = false;
  bool _isSendingRequest = false;
  String? _friendsError;
  String? _requestsError;
  String? _searchError;
  String? _actionError;
  String _searchQuery = '';
  bool _isInitialized = false;

  @override
  List<FriendProfile> get friends => _friends;

  @override
  List<FriendRequest> get pendingRequests => _pendingRequests;

  @override
  List<SentRequest> get sentRequests => _sentRequests;

  @override
  List<FriendProfile> get searchResults => _searchResults;

  @override
  bool get isLoadingFriends => _isLoadingFriends;

  @override
  bool get isLoadingRequests => _isLoadingRequests;

  @override
  bool get isSearching => _isSearching;

  @override
  bool get isSendingRequest => _isSendingRequest;

  @override
  String? get friendsError => _friendsError;

  @override
  String? get requestsError => _requestsError;

  @override
  String? get searchError => _searchError;

  @override
  String? get actionError => _actionError;

  @override
  String get searchQuery => _searchQuery;

  @override
  int get pendingRequestCount => _pendingRequests.length;

  @override
  bool get hasFriends => _friends.isNotEmpty;

  @override
  bool get hasPendingRequests => _pendingRequests.isNotEmpty;

  @override
  bool get isInitialized => _isInitialized;

  // Setters for testing
  void setFriends(List<FriendProfile> friends) {
    _friends = friends;
    notifyListeners();
  }

  void setPendingRequests(List<FriendRequest> requests) {
    _pendingRequests = requests;
    notifyListeners();
  }

  void setSentRequests(List<SentRequest> requests) {
    _sentRequests = requests;
    notifyListeners();
  }

  void setLoadingFriends(bool loading) {
    _isLoadingFriends = loading;
    notifyListeners();
  }

  void setLoadingRequests(bool loading) {
    _isLoadingRequests = loading;
    notifyListeners();
  }

  void setFriendsError(String? error) {
    _friendsError = error;
    notifyListeners();
  }

  void setRequestsError(String? error) {
    _requestsError = error;
    notifyListeners();
  }

  @override
  Future<void> initialize() async {
    _isInitialized = true;
    notifyListeners();
  }

  @override
  void reset() {
    _friends = [];
    _pendingRequests = [];
    _sentRequests = [];
    _searchResults = [];
    _isLoadingFriends = false;
    _isLoadingRequests = false;
    _isSearching = false;
    _isSendingRequest = false;
    _friendsError = null;
    _requestsError = null;
    _searchError = null;
    _actionError = null;
    _searchQuery = '';
    _isInitialized = false;
    notifyListeners();
  }

  @override
  Future<void> loadFriends() async {
    // Mock implementation
  }

  @override
  Future<void> loadPendingRequests() async {
    // Mock implementation
  }

  @override
  Future<void> refresh() async {
    // Mock implementation
  }

  @override
  Future<void> searchUsers(String query) async {
    _searchQuery = query;
    notifyListeners();
  }

  @override
  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    _searchError = null;
    notifyListeners();
  }

  @override
  Future<bool> sendFriendRequest(String friendId) async => true;

  @override
  Future<bool> acceptFriendRequest(FriendRequest request) async => true;

  @override
  Future<bool> declineFriendRequest(FriendRequest request) async => true;

  @override
  Future<bool> cancelFriendRequest(SentRequest request) async => true;

  @override
  Future<bool> removeFriend(FriendProfile friend, String friendshipId) async => true;

  @override
  Future<bool> blockUser(String userId) async => true;

  @override
  bool hasSentRequestTo(String userId) => false;

  @override
  bool hasReceivedRequestFrom(String userId) => false;

  @override
  bool isFriend(String userId) => _friends.any((f) => f.id == userId);

  @override
  FriendshipState getFriendshipState(String userId) => FriendshipState.none;

  @override
  void clearActionError() {
    _actionError = null;
    notifyListeners();
  }
}

void main() {
  late MockFriendProvider mockProvider;

  setUp(() {
    mockProvider = MockFriendProvider();
  });

  Widget createTestWidget({Widget? child}) {
    return MaterialApp(
      home: ChangeNotifierProvider<FriendProvider>.value(
        value: mockProvider,
        child: child ?? const FriendsScreen(),
      ),
    );
  }

  group('FriendsScreen - Basic Structure', () {
    testWidgets('should display app bar with title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Friends'), findsWidgets);
    });

    testWidgets('should display tab bar with Friends and Requests tabs', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Friends'), findsWidgets);
      expect(find.text('Requests'), findsOneWidget);
    });

    testWidgets('should display add friend FAB', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Add Friend'), findsOneWidget);
      expect(find.byIcon(Icons.person_add_rounded), findsWidgets);
    });

    testWidgets('should display add friend icon button in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byTooltip('Add Friend'), findsOneWidget);
    });
  });

  group('FriendsScreen - Loading States', () {
    testWidgets('should show loading indicator when loading friends', (tester) async {
      mockProvider.setLoadingFriends(true);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show loading indicator when loading requests', (tester) async {
      mockProvider.setLoadingRequests(true);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Switch to Requests tab - use pump() instead of pumpAndSettle()
      // because CircularProgressIndicator animates forever
      await tester.tap(find.text('Requests'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300)); // Allow tab animation

      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });
  });

  group('FriendsScreen - Friends Tab', () {
    testWidgets('should show empty state when no friends', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No Friends Yet'), findsOneWidget);
      expect(find.text('Add friends to start planning events together!'), findsOneWidget);
      expect(find.text('Find Friends'), findsOneWidget);
    });

    testWidgets('should show friends list when friends exist', (tester) async {
      mockProvider.setFriends([
        FriendProfile(
          id: 'friend-1',
          fullName: 'John Doe',
          email: 'john@example.com',
          friendshipSince: DateTime(2025, 1, 1),
        ),
        FriendProfile(
          id: 'friend-2',
          fullName: 'Jane Smith',
          email: 'jane@example.com',
          friendshipSince: DateTime(2025, 1, 2),
        ),
      ]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
    });

    testWidgets('should show error state with retry button', (tester) async {
      mockProvider.setFriendsError('Network error occurred');

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Network error occurred'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });
  });

  group('FriendsScreen - Requests Tab', () {
    testWidgets('should show empty requests state', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to Requests tab
      await tester.tap(find.text('Requests'));
      await tester.pumpAndSettle();

      expect(find.text('No Pending Requests'), findsOneWidget);
    });

    testWidgets('should show pending request count badge', (tester) async {
      mockProvider.setPendingRequests([
        FriendRequest(
          requestId: 'req-1',
          requesterId: 'user-1',
          email: 'requester@example.com',
          fullName: 'Test Requester',
          requestedAt: DateTime.now(),
        ),
        FriendRequest(
          requestId: 'req-2',
          requesterId: 'user-2',
          email: 'requester2@example.com',
          fullName: 'Another Requester',
          requestedAt: DateTime.now(),
        ),
      ]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Badge showing count
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('should show incoming requests section', (tester) async {
      mockProvider.setPendingRequests([
        FriendRequest(
          requestId: 'req-1',
          requesterId: 'user-1',
          email: 'requester@example.com',
          fullName: 'Test Requester',
          requestedAt: DateTime.now(),
        ),
      ]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to Requests tab
      await tester.tap(find.text('Requests'));
      await tester.pumpAndSettle();

      expect(find.text('Incoming Requests'), findsOneWidget);
      expect(find.text('Test Requester'), findsOneWidget);
    });

    testWidgets('should show sent requests section', (tester) async {
      mockProvider.setSentRequests([
        SentRequest(
          requestId: 'sent-1',
          recipientId: 'user-1',
          email: 'recipient@example.com',
          fullName: 'Test Recipient',
          sentAt: DateTime.now(),
        ),
      ]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to Requests tab
      await tester.tap(find.text('Requests'));
      await tester.pumpAndSettle();

      expect(find.text('Sent Requests'), findsOneWidget);
      expect(find.text('Test Recipient'), findsOneWidget);
    });
  });

  group('FriendsScreen - Tab Navigation', () {
    testWidgets('should switch between tabs', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially on Friends tab - shows empty friends state
      expect(find.text('No Friends Yet'), findsOneWidget);

      // Switch to Requests tab
      await tester.tap(find.text('Requests'));
      await tester.pumpAndSettle();

      // Now shows empty requests state
      expect(find.text('No Pending Requests'), findsOneWidget);

      // Switch back to Friends tab by tapping the icon in tab (more reliable than text)
      final friendsTabFinder = find.byIcon(Icons.people_rounded);
      await tester.tap(friendsTabFinder.first);
      await tester.pumpAndSettle();

      // Back to friends empty state
      expect(find.text('No Friends Yet'), findsOneWidget);
    });
  });

  group('FriendsScreen - Interactions', () {
    testWidgets('should show friend profile sheet on tap', (tester) async {
      mockProvider.setFriends([
        FriendProfile(
          id: 'friend-1',
          fullName: 'John Doe',
          email: 'john@example.com',
          friendshipSince: DateTime(2025, 1, 15),
        ),
      ]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap on friend tile (find by the FriendListTile or ListTile)
      await tester.tap(find.text('John Doe'));
      await tester.pumpAndSettle();

      // Bottom sheet should appear with profile info
      expect(find.text('View Calendar'), findsOneWidget);
      expect(find.text('Plan Event'), findsOneWidget);
    });
  });

  group('FriendsScreen - Pull to Refresh', () {
    testWidgets('should have RefreshIndicator in friends list', (tester) async {
      mockProvider.setFriends([
        FriendProfile(
          id: 'friend-1',
          fullName: 'John Doe',
          email: 'john@example.com',
        ),
      ]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });
}
