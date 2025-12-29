import 'package:flutter/foundation.dart';
import '../../data/models/friendship_model.dart';
import '../../core/services/friend_service.dart';
import '../../core/utils/logger.dart';

/// Provider for friend system state management
///
/// Manages friends list, pending requests, and friend search
class FriendProvider extends ChangeNotifier {
  final FriendService _friendService = FriendService.instance;

  /// List of accepted friends
  List<FriendProfile> _friends = [];

  /// List of pending friend requests received
  List<FriendRequest> _pendingRequests = [];

  /// List of sent friend requests (outgoing)
  List<SentRequest> _sentRequests = [];

  /// Search results for user search
  List<FriendProfile> _searchResults = [];

  /// Loading states
  bool _isLoadingFriends = false;
  bool _isLoadingRequests = false;
  bool _isSearching = false;
  bool _isSendingRequest = false;

  /// Error states
  String? _friendsError;
  String? _requestsError;
  String? _searchError;
  String? _actionError;

  /// Current search query
  String _searchQuery = '';

  /// Whether initial data has been loaded
  bool _isInitialized = false;

  // ============================================================================
  // Getters
  // ============================================================================

  List<FriendProfile> get friends => _friends;
  List<FriendRequest> get pendingRequests => _pendingRequests;
  List<SentRequest> get sentRequests => _sentRequests;
  List<FriendProfile> get searchResults => _searchResults;

  bool get isLoadingFriends => _isLoadingFriends;
  bool get isLoadingRequests => _isLoadingRequests;
  bool get isSearching => _isSearching;
  bool get isSendingRequest => _isSendingRequest;

  String? get friendsError => _friendsError;
  String? get requestsError => _requestsError;
  String? get searchError => _searchError;
  String? get actionError => _actionError;

  String get searchQuery => _searchQuery;

  /// Total count of pending requests (for badge display)
  int get pendingRequestCount => _pendingRequests.length;

  /// Check if user has any friends
  bool get hasFriends => _friends.isNotEmpty;

  /// Check if there are pending requests
  bool get hasPendingRequests => _pendingRequests.isNotEmpty;

  // ============================================================================
  // Initialization
  // ============================================================================

  /// Whether the provider has been initialized with data
  bool get isInitialized => _isInitialized;

  /// Initialize the provider and load initial data
  /// Skips if already initialized - use [refresh] to force reload
  Future<void> initialize() async {
    // Skip if already initialized to prevent duplicate API calls
    if (_isInitialized) return;

    await Future.wait([
      loadFriends(),
      loadPendingRequests(),
    ]);

    _isInitialized = true;
  }

  /// Reset all state - call this on logout to prevent data leaking between accounts
  ///
  /// CRITICAL: This must be called when user logs out to clear cached data
  /// from the previous session. Without this, a new user would see the
  /// previous user's friends, requests, and search results.
  void reset() {
    Logger.info('Resetting FriendProvider state', 'FriendProvider');

    // Clear all cached data
    _friends = [];
    _pendingRequests = [];
    _sentRequests = [];
    _searchResults = [];

    // Reset loading states
    _isLoadingFriends = false;
    _isLoadingRequests = false;
    _isSearching = false;
    _isSendingRequest = false;

    // Clear errors
    _friendsError = null;
    _requestsError = null;
    _searchError = null;
    _actionError = null;

    // Reset search
    _searchQuery = '';

    // Reset initialization flag so data reloads for new user
    _isInitialized = false;

    notifyListeners();
  }

  // ============================================================================
  // Data Loading
  // ============================================================================

  /// Load list of accepted friends
  Future<void> loadFriends() async {
    _isLoadingFriends = true;
    _friendsError = null;
    notifyListeners();

    try {
      _friends = await _friendService.getFriends();
      Logger.info('Loaded ${_friends.length} friends');
    } catch (e) {
      _friendsError = e.toString();
      Logger.error('Failed to load friends: $e');
    } finally {
      _isLoadingFriends = false;
      notifyListeners();
    }
  }

  /// Load pending friend requests (incoming)
  Future<void> loadPendingRequests() async {
    _isLoadingRequests = true;
    _requestsError = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _friendService.getPendingRequests(),
        _friendService.getSentRequests(),
      ]);

      _pendingRequests = results[0] as List<FriendRequest>;
      _sentRequests = results[1] as List<SentRequest>;

      Logger.info(
        'Loaded ${_pendingRequests.length} pending requests, '
        '${_sentRequests.length} sent requests',
      );
    } catch (e) {
      _requestsError = e.toString();
      Logger.error('Failed to load pending requests: $e');
    } finally {
      _isLoadingRequests = false;
      notifyListeners();
    }
  }

  /// Refresh all friend data (force reload)
  Future<void> refresh() async {
    await Future.wait([
      loadFriends(),
      loadPendingRequests(),
    ]);
  }

  // ============================================================================
  // Search Operations
  // ============================================================================

  /// Search for users by email or name
  Future<void> searchUsers(String query) async {
    _searchQuery = query;

    if (query.length < 2) {
      _searchResults = [];
      _searchError = null;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _searchError = null;
    notifyListeners();

    try {
      _searchResults = await _friendService.searchUsers(query);
      Logger.info('Search found ${_searchResults.length} users');
    } catch (e) {
      _searchError = e.toString();
      _searchResults = [];
      Logger.error('Search failed: $e');
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Clear search results
  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    _searchError = null;
    notifyListeners();
  }

  // ============================================================================
  // Friend Request Actions
  // ============================================================================

  /// Send a friend request to a user
  Future<bool> sendFriendRequest(String friendId) async {
    _isSendingRequest = true;
    _actionError = null;
    notifyListeners();

    try {
      await _friendService.sendFriendRequest(friendId);
      // Reload sent requests to get the complete data with recipient info
      _sentRequests = await _friendService.getSentRequests();
      Logger.info('Friend request sent to: $friendId');
      notifyListeners();
      return true;
    } catch (e) {
      _actionError = e.toString();
      Logger.error('Failed to send friend request: $e');
      notifyListeners();
      return false;
    } finally {
      _isSendingRequest = false;
      notifyListeners();
    }
  }

  /// Accept a pending friend request
  Future<bool> acceptFriendRequest(FriendRequest request) async {
    _actionError = null;

    try {
      final friendship = await _friendService.acceptFriendRequest(request.requestId);

      // Remove from pending requests
      _pendingRequests.removeWhere((r) => r.requestId == request.requestId);

      // Add to friends list with friendship ID for deletion
      _friends.add(FriendProfile(
        id: request.requesterId,
        friendshipId: friendship.id,
        fullName: request.fullName,
        email: request.email,
        avatarUrl: request.avatarUrl,
        friendshipSince: friendship.acceptedAt,
      ));

      Logger.info('Accepted friend request from: ${request.requesterId}');
      notifyListeners();
      return true;
    } catch (e) {
      _actionError = e.toString();
      Logger.error('Failed to accept friend request: $e');
      notifyListeners();
      return false;
    }
  }

  /// Decline a pending friend request
  Future<bool> declineFriendRequest(FriendRequest request) async {
    _actionError = null;

    try {
      await _friendService.declineFriendRequest(request.requestId);

      // Remove from pending requests
      _pendingRequests.removeWhere((r) => r.requestId == request.requestId);

      Logger.info('Declined friend request from: ${request.requesterId}');
      notifyListeners();
      return true;
    } catch (e) {
      _actionError = e.toString();
      Logger.error('Failed to decline friend request: $e');
      notifyListeners();
      return false;
    }
  }

  /// Cancel a sent friend request
  Future<bool> cancelFriendRequest(SentRequest request) async {
    _actionError = null;

    try {
      await _friendService.cancelFriendRequest(request.requestId);

      // Remove from sent requests
      _sentRequests.removeWhere((r) => r.requestId == request.requestId);

      Logger.info('Canceled friend request: ${request.requestId}');
      notifyListeners();
      return true;
    } catch (e) {
      _actionError = e.toString();
      Logger.error('Failed to cancel friend request: $e');
      notifyListeners();
      return false;
    }
  }

  /// Remove a friend
  Future<bool> removeFriend(FriendProfile friend, String friendshipId) async {
    _actionError = null;

    try {
      await _friendService.removeFriend(friendshipId);

      // Remove from friends list
      _friends.removeWhere((f) => f.id == friend.id);

      Logger.info('Removed friend: ${friend.id}');
      notifyListeners();
      return true;
    } catch (e) {
      _actionError = e.toString();
      Logger.error('Failed to remove friend: $e');
      notifyListeners();
      return false;
    }
  }

  // ============================================================================
  // Block Operations
  // ============================================================================

  /// Block a user
  Future<bool> blockUser(String userId) async {
    _actionError = null;

    try {
      await _friendService.blockUser(userId);

      // Remove from friends if present
      _friends.removeWhere((f) => f.id == userId);

      // Remove any pending requests from this user
      _pendingRequests.removeWhere((r) => r.requesterId == userId);

      Logger.info('Blocked user: $userId');
      notifyListeners();
      return true;
    } catch (e) {
      _actionError = e.toString();
      Logger.error('Failed to block user: $e');
      notifyListeners();
      return false;
    }
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Check if a friend request has been sent to this user
  bool hasSentRequestTo(String userId) {
    return _sentRequests.any((r) => r.recipientId == userId);
  }

  /// Check if a friend request has been received from this user
  bool hasReceivedRequestFrom(String userId) {
    return _pendingRequests.any((r) => r.requesterId == userId);
  }

  /// Check if this user is already a friend
  bool isFriend(String userId) {
    return _friends.any((f) => f.id == userId);
  }

  /// Get friendship status for a user ID
  FriendshipState getFriendshipState(String userId) {
    if (isFriend(userId)) {
      return FriendshipState.friends;
    }
    if (hasSentRequestTo(userId)) {
      return FriendshipState.requestSent;
    }
    if (hasReceivedRequestFrom(userId)) {
      return FriendshipState.requestReceived;
    }
    return FriendshipState.none;
  }

  /// Clear action error
  void clearActionError() {
    _actionError = null;
    notifyListeners();
  }
}

/// Enum representing the friendship state with another user
enum FriendshipState {
  none, // No relationship
  requestSent, // Current user sent a request
  requestReceived, // Current user received a request
  friends, // Already friends
}
