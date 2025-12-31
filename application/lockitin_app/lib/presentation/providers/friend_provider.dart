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

  /// Friend availability status map (friend_id -> availability)
  Map<String, FriendAvailability> _friendAvailability = {};

  /// Pagination state for search
  int _searchOffset = 0;
  bool _hasMoreSearchResults = true;
  bool _isLoadingMoreSearch = false;

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

  /// Get friend availability map
  Map<String, FriendAvailability> get friendAvailability => _friendAvailability;

  /// Whether more search results are available (for pagination)
  bool get hasMoreSearchResults => _hasMoreSearchResults;

  /// Whether more search results are being loaded
  bool get isLoadingMoreSearch => _isLoadingMoreSearch;

  /// Total count of pending requests (for badge display)
  int get pendingRequestCount => _pendingRequests.length;

  /// Check if user has any friends
  bool get hasFriends => _friends.isNotEmpty;

  /// Check if there are pending requests
  bool get hasPendingRequests => _pendingRequests.isNotEmpty;

  /// Get availability status for a specific friend
  /// Returns 'unknown' if no availability data exists
  AvailabilityStatus getAvailabilityStatus(String friendId) {
    return _friendAvailability[friendId]?.status ?? AvailabilityStatus.unknown;
  }

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

    await _loadData();
    _isInitialized = true;
  }

  /// Internal method to load all friend data
  /// Used by both [initialize] and [refresh] to avoid duplication
  Future<void> _loadData() async {
    await Future.wait([
      loadFriends(),
      loadPendingRequests(),
    ]);
    // Load availability after friends are loaded
    await loadFriendsAvailability();
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
    _friendAvailability = {};

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
    // Don't notify here - reduces unnecessary rebuilds

    try {
      _friends = await _friendService.getFriends();
      Logger.info('FriendProvider', 'Loaded ${_friends.length} friends');
    } catch (e) {
      _friendsError = e.toString();
      Logger.error('FriendProvider', 'Failed to load friends: $e');
    } finally {
      _isLoadingFriends = false;
      notifyListeners(); // Single rebuild with final state
    }
  }

  /// Load pending friend requests (incoming)
  Future<void> loadPendingRequests() async {
    _isLoadingRequests = true;
    _requestsError = null;
    // Don't notify here - reduces unnecessary rebuilds

    try {
      final results = await Future.wait([
        _friendService.getPendingRequests(),
        _friendService.getSentRequests(),
      ]);

      _pendingRequests = results[0] as List<FriendRequest>;
      _sentRequests = results[1] as List<SentRequest>;

      Logger.info('FriendProvider',
        'Loaded ${_pendingRequests.length} pending requests, '
        '${_sentRequests.length} sent requests',
      );
    } catch (e) {
      _requestsError = e.toString();
      Logger.error('FriendProvider', 'Failed to load pending requests: $e');
    } finally {
      _isLoadingRequests = false;
      notifyListeners(); // Single rebuild with final state
    }
  }

  /// Refresh all friend data (force reload)
  Future<void> refresh() async {
    await _loadData();
  }

  /// Load availability status for all friends
  Future<void> loadFriendsAvailability() async {
    if (_friends.isEmpty) {
      _friendAvailability = {};
      return;
    }

    try {
      final friendIds = _friends.map((f) => f.id).toList();
      _friendAvailability = await _friendService.getFriendsAvailability(friendIds);
      Logger.info('FriendProvider', 'Loaded availability for ${_friendAvailability.length} friends');
      notifyListeners();
    } catch (e) {
      Logger.error('FriendProvider', 'Failed to load availability: $e');
      // Don't clear existing availability on error
    }
  }

  // ============================================================================
  // Search Operations
  // ============================================================================

  /// Search for users by email or name (resets pagination)
  Future<void> searchUsers(String query) async {
    _searchQuery = query;
    _searchOffset = 0;
    _hasMoreSearchResults = true;

    if (query.length < 2) {
      _searchResults = [];
      _searchError = null;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _searchError = null;
    // Don't notify here - reduces unnecessary rebuilds

    try {
      _searchResults = await _friendService.searchUsers(query);
      _hasMoreSearchResults = _searchResults.length >= FriendService.defaultSearchLimit;
      _searchOffset = _searchResults.length;
      Logger.info('FriendProvider', 'Search found ${_searchResults.length} users');
    } catch (e) {
      _searchError = e.toString();
      _searchResults = [];
      _hasMoreSearchResults = false;
      Logger.error('FriendProvider', 'Search failed: $e');
    } finally {
      _isSearching = false;
      notifyListeners(); // Single rebuild with final state
    }
  }

  /// Load more search results (pagination)
  Future<void> loadMoreSearchResults() async {
    if (_isLoadingMoreSearch || !_hasMoreSearchResults || _searchQuery.length < 2) {
      return;
    }

    _isLoadingMoreSearch = true;
    notifyListeners();

    try {
      final moreResults = await _friendService.searchUsers(
        _searchQuery,
        offset: _searchOffset,
      );

      _searchResults = [..._searchResults, ...moreResults];
      _hasMoreSearchResults = moreResults.length >= FriendService.defaultSearchLimit;
      _searchOffset += moreResults.length;
      Logger.info('FriendProvider', 'Loaded ${moreResults.length} more results (total: ${_searchResults.length})');
    } catch (e) {
      Logger.error('FriendProvider', 'Failed to load more results: $e');
      // Don't set error - keep existing results
    } finally {
      _isLoadingMoreSearch = false;
      notifyListeners();
    }
  }

  /// Clear search results
  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    _searchOffset = 0;
    _hasMoreSearchResults = true;
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
    // Don't notify here - reduces unnecessary rebuilds

    try {
      await _friendService.sendFriendRequest(friendId);
      // Reload sent requests to get the complete data with recipient info
      _sentRequests = await _friendService.getSentRequests();
      Logger.info('FriendProvider', 'Friend request sent to: $friendId');
      _isSendingRequest = false;
      notifyListeners(); // Single rebuild with final state
      return true;
    } catch (e) {
      _actionError = e.toString();
      Logger.error('FriendProvider', 'Failed to send friend request: $e');
      _isSendingRequest = false;
      notifyListeners(); // Single rebuild with error state
      return false;
    }
  }

  /// Accept a pending friend request (optimistic UI update)
  Future<bool> acceptFriendRequest(FriendRequest request) async {
    _actionError = null;

    // Optimistic update: immediately update UI
    _pendingRequests.removeWhere((r) => r.requestId == request.requestId);
    final optimisticFriend = FriendProfile(
      id: request.requesterId,
      friendshipId: null, // Will be set after server confirms
      fullName: request.fullName,
      email: request.email,
      avatarUrl: request.avatarUrl,
      friendshipSince: DateTime.now(),
    );
    _friends.add(optimisticFriend);
    notifyListeners(); // Instant feedback

    try {
      final friendship = await _friendService.acceptFriendRequest(request.requestId);

      // Update with real friendship data from server
      final index = _friends.indexWhere((f) => f.id == request.requesterId);
      if (index >= 0) {
        _friends[index] = FriendProfile(
          id: request.requesterId,
          friendshipId: friendship.id,
          fullName: request.fullName,
          email: request.email,
          avatarUrl: request.avatarUrl,
          friendshipSince: friendship.acceptedAt,
        );
      }

      Logger.info('FriendProvider', 'Accepted friend request from: ${request.requesterId}');
      notifyListeners();
      return true;
    } catch (e) {
      // Rollback on failure
      _friends.removeWhere((f) => f.id == request.requesterId);
      _pendingRequests.add(request);
      _actionError = e.toString();
      Logger.error('FriendProvider', 'Failed to accept friend request: $e');
      notifyListeners();
      return false;
    }
  }

  /// Decline a pending friend request (optimistic UI update)
  Future<bool> declineFriendRequest(FriendRequest request) async {
    _actionError = null;

    // Optimistic update: immediately remove from UI
    _pendingRequests.removeWhere((r) => r.requestId == request.requestId);
    notifyListeners(); // Instant feedback

    try {
      await _friendService.declineFriendRequest(request.requestId);
      Logger.info('FriendProvider', 'Declined friend request from: ${request.requesterId}');
      return true;
    } catch (e) {
      // Rollback on failure
      _pendingRequests.add(request);
      _actionError = e.toString();
      Logger.error('FriendProvider', 'Failed to decline friend request: $e');
      notifyListeners();
      return false;
    }
  }

  /// Cancel a sent friend request (optimistic UI update)
  Future<bool> cancelFriendRequest(SentRequest request) async {
    _actionError = null;

    // Optimistic update: immediately remove from UI
    _sentRequests.removeWhere((r) => r.requestId == request.requestId);
    notifyListeners(); // Instant feedback

    try {
      await _friendService.cancelFriendRequest(request.requestId);
      Logger.info('FriendProvider', 'Canceled friend request: ${request.requestId}');
      return true;
    } catch (e) {
      // Rollback on failure
      _sentRequests.add(request);
      _actionError = e.toString();
      Logger.error('FriendProvider', 'Failed to cancel friend request: $e');
      notifyListeners();
      return false;
    }
  }

  /// Remove a friend (optimistic UI update)
  Future<bool> removeFriend(FriendProfile friend, String friendshipId) async {
    _actionError = null;

    // Optimistic update: immediately remove from UI
    _friends.removeWhere((f) => f.id == friend.id);
    notifyListeners(); // Instant feedback

    try {
      await _friendService.removeFriend(friendshipId);
      Logger.info('FriendProvider', 'Removed friend: ${friend.id}');
      return true;
    } catch (e) {
      // Rollback on failure
      _friends.add(friend);
      _actionError = e.toString();
      Logger.error('FriendProvider', 'Failed to remove friend: $e');
      notifyListeners();
      return false;
    }
  }

  // ============================================================================
  // Block Operations
  // ============================================================================

  /// Block a user (optimistic UI update)
  Future<bool> blockUser(String userId) async {
    _actionError = null;

    // Store for rollback
    final removedFriend = _friends.cast<FriendProfile?>().firstWhere(
      (f) => f?.id == userId,
      orElse: () => null,
    );
    final removedRequest = _pendingRequests.cast<FriendRequest?>().firstWhere(
      (r) => r?.requesterId == userId,
      orElse: () => null,
    );

    // Optimistic update: immediately remove from UI
    _friends.removeWhere((f) => f.id == userId);
    _pendingRequests.removeWhere((r) => r.requesterId == userId);
    notifyListeners(); // Instant feedback

    try {
      await _friendService.blockUser(userId);
      Logger.info('FriendProvider', 'Blocked user: $userId');
      return true;
    } catch (e) {
      // Rollback on failure
      if (removedFriend != null) _friends.add(removedFriend);
      if (removedRequest != null) _pendingRequests.add(removedRequest);
      _actionError = e.toString();
      Logger.error('FriendProvider', 'Failed to block user: $e');
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
