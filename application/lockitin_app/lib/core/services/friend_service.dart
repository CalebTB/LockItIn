import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/friendship_model.dart';
import '../network/supabase_client.dart';
import '../utils/logger.dart';

/// Exception thrown when friend operations fail
class FriendServiceException implements Exception {
  final String message;
  final String? code;

  FriendServiceException(this.message, {this.code});

  @override
  String toString() => 'FriendServiceException: $message';
}

/// Service for managing friend connections with Supabase
///
/// Uses singleton pattern - access via [FriendService.instance] or constructor
class FriendService {
  // Singleton instance
  static final FriendService _instance = FriendService._internal();

  /// Access the singleton instance
  static FriendService get instance => _instance;

  /// Factory constructor returns singleton
  factory FriendService() => _instance;

  /// Private internal constructor
  FriendService._internal();

  // ============================================================================
  // Friend Request Operations
  // ============================================================================

  /// Send a friend request to another user
  ///
  /// Creates a pending friendship from current user to target user
  /// Returns the created FriendshipModel
  Future<FriendshipModel> sendFriendRequest(String friendId) async {
    try {
      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) {
        throw FriendServiceException('User not authenticated');
      }

      if (currentUserId == friendId) {
        throw FriendServiceException('Cannot send friend request to yourself');
      }

      Logger.info('Sending friend request to: $friendId');

      // Check if friendship already exists (in either direction)
      final existingCheck = await SupabaseClientManager.client
          .from('friendships')
          .select()
          .or('and(user_id.eq.$currentUserId,friend_id.eq.$friendId),and(user_id.eq.$friendId,friend_id.eq.$currentUserId)');

      if ((existingCheck as List).isNotEmpty) {
        final existing = FriendshipModel.fromJson(existingCheck[0]);
        if (existing.status == FriendshipStatus.accepted) {
          throw FriendServiceException('You are already friends with this user');
        } else if (existing.status == FriendshipStatus.pending) {
          throw FriendServiceException('A friend request already exists');
        } else if (existing.status == FriendshipStatus.blocked) {
          throw FriendServiceException('Unable to send friend request');
        }
      }

      // Create the friend request
      final response = await SupabaseClientManager.client
          .from('friendships')
          .insert({
            'user_id': currentUserId,
            'friend_id': friendId,
            'status': 'pending',
          })
          .select()
          .single();

      Logger.info('Friend request sent successfully');
      return FriendshipModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is FriendServiceException) rethrow;
      Logger.error('Failed to send friend request: $e');
      throw FriendServiceException('Failed to send friend request: $e');
    }
  }

  /// Accept a pending friend request
  ///
  /// Updates the friendship status to accepted
  Future<FriendshipModel> acceptFriendRequest(String requestId) async {
    try {
      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) {
        throw FriendServiceException('User not authenticated');
      }

      Logger.info('Accepting friend request: $requestId');

      final response = await SupabaseClientManager.client
          .from('friendships')
          .update({
            'status': 'accepted',
            'accepted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId)
          .eq('friend_id', currentUserId) // Only recipient can accept
          .eq('status', 'pending') // Only pending requests can be accepted
          .select()
          .single();

      Logger.info('Friend request accepted successfully');
      return FriendshipModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is FriendServiceException) rethrow;
      Logger.error('Failed to accept friend request: $e');
      throw FriendServiceException('Failed to accept friend request: $e');
    }
  }

  /// Decline a pending friend request
  ///
  /// Deletes the friendship record
  Future<void> declineFriendRequest(String requestId) async {
    try {
      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) {
        throw FriendServiceException('User not authenticated');
      }

      Logger.info('Declining friend request: $requestId');

      await SupabaseClientManager.client
          .from('friendships')
          .delete()
          .eq('id', requestId)
          .eq('friend_id', currentUserId) // Only recipient can decline
          .eq('status', 'pending');

      Logger.info('Friend request declined successfully');
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is FriendServiceException) rethrow;
      Logger.error('Failed to decline friend request: $e');
      throw FriendServiceException('Failed to decline friend request: $e');
    }
  }

  /// Cancel a friend request that was sent
  ///
  /// Only the sender can cancel their own request
  Future<void> cancelFriendRequest(String requestId) async {
    try {
      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) {
        throw FriendServiceException('User not authenticated');
      }

      Logger.info('Canceling friend request: $requestId');

      await SupabaseClientManager.client
          .from('friendships')
          .delete()
          .eq('id', requestId)
          .eq('user_id', currentUserId) // Only sender can cancel
          .eq('status', 'pending');

      Logger.info('Friend request canceled successfully');
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is FriendServiceException) rethrow;
      Logger.error('Failed to cancel friend request: $e');
      throw FriendServiceException('Failed to cancel friend request: $e');
    }
  }

  /// Remove a friend (unfriend)
  ///
  /// Deletes the accepted friendship record
  Future<void> removeFriend(String friendshipId) async {
    try {
      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) {
        throw FriendServiceException('User not authenticated');
      }

      Logger.info('Removing friend: $friendshipId');

      await SupabaseClientManager.client
          .from('friendships')
          .delete()
          .eq('id', friendshipId)
          .or('user_id.eq.$currentUserId,friend_id.eq.$currentUserId')
          .eq('status', 'accepted');

      Logger.info('Friend removed successfully');
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is FriendServiceException) rethrow;
      Logger.error('Failed to remove friend: $e');
      throw FriendServiceException('Failed to remove friend: $e');
    }
  }

  // ============================================================================
  // Block Operations
  // ============================================================================

  /// Block a user
  ///
  /// Updates existing friendship to blocked or creates blocked entry
  Future<void> blockUser(String userId) async {
    try {
      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) {
        throw FriendServiceException('User not authenticated');
      }

      Logger.info('Blocking user: $userId');

      // Check for existing friendship
      final existingCheck = await SupabaseClientManager.client
          .from('friendships')
          .select()
          .or('and(user_id.eq.$currentUserId,friend_id.eq.$userId),and(user_id.eq.$userId,friend_id.eq.$currentUserId)');

      if ((existingCheck as List).isNotEmpty) {
        // Update existing record
        await SupabaseClientManager.client
            .from('friendships')
            .update({'status': 'blocked'})
            .eq('id', existingCheck[0]['id']);
      } else {
        // Create new blocked record
        await SupabaseClientManager.client.from('friendships').insert({
          'user_id': currentUserId,
          'friend_id': userId,
          'status': 'blocked',
        });
      }

      Logger.info('User blocked successfully');
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is FriendServiceException) rethrow;
      Logger.error('Failed to block user: $e');
      throw FriendServiceException('Failed to block user: $e');
    }
  }

  /// Unblock a user
  ///
  /// Deletes the blocked friendship record
  Future<void> unblockUser(String friendshipId) async {
    try {
      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) {
        throw FriendServiceException('User not authenticated');
      }

      Logger.info('Unblocking user: $friendshipId');

      await SupabaseClientManager.client
          .from('friendships')
          .delete()
          .eq('id', friendshipId)
          .eq('user_id', currentUserId) // Only blocker can unblock
          .eq('status', 'blocked');

      Logger.info('User unblocked successfully');
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is FriendServiceException) rethrow;
      Logger.error('Failed to unblock user: $e');
      throw FriendServiceException('Failed to unblock user: $e');
    }
  }

  // ============================================================================
  // Query Operations
  // ============================================================================

  /// Get list of accepted friends
  ///
  /// Uses the get_friends database function
  Future<List<FriendProfile>> getFriends() async {
    try {
      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) {
        throw FriendServiceException('User not authenticated');
      }

      Logger.info('Fetching friends list');

      final response = await SupabaseClientManager.client
          .rpc('get_friends', params: {'user_uuid': currentUserId});

      final friends = (response as List)
          .map((json) => FriendProfile.fromJson(json as Map<String, dynamic>))
          .toList();

      Logger.info('Fetched ${friends.length} friends');
      return friends;
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is FriendServiceException) rethrow;
      Logger.error('Failed to fetch friends: $e');
      throw FriendServiceException('Failed to fetch friends: $e');
    }
  }

  /// Get list of pending friend requests received
  ///
  /// Uses the get_pending_requests database function
  Future<List<FriendRequest>> getPendingRequests() async {
    try {
      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) {
        throw FriendServiceException('User not authenticated');
      }

      Logger.info('Fetching pending friend requests');

      final response = await SupabaseClientManager.client
          .rpc('get_pending_requests', params: {'user_uuid': currentUserId});

      final requests = (response as List)
          .map((json) => FriendRequest.fromJson(json as Map<String, dynamic>))
          .toList();

      Logger.info('Fetched ${requests.length} pending requests');
      return requests;
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is FriendServiceException) rethrow;
      Logger.error('Failed to fetch pending requests: $e');
      throw FriendServiceException('Failed to fetch pending requests: $e');
    }
  }

  /// Get list of sent friend requests (outgoing pending) with recipient info
  ///
  /// Uses get_sent_requests RPC function for consistency with other friendship queries
  Future<List<SentRequest>> getSentRequests() async {
    try {
      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) {
        throw FriendServiceException('User not authenticated');
      }

      Logger.info('Fetching sent friend requests');

      final response = await SupabaseClientManager.client
          .rpc('get_sent_requests', params: {'user_uuid': currentUserId});

      final requests = (response as List)
          .map((json) => SentRequest.fromJson(json as Map<String, dynamic>))
          .toList();

      Logger.info('Fetched ${requests.length} sent requests');
      return requests;
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is FriendServiceException) rethrow;
      Logger.error('Failed to fetch sent requests: $e');
      throw FriendServiceException('Failed to fetch sent requests: $e');
    }
  }

  /// Get list of blocked users
  Future<List<FriendshipModel>> getBlockedUsers() async {
    try {
      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) {
        throw FriendServiceException('User not authenticated');
      }

      Logger.info('Fetching blocked users');

      final response = await SupabaseClientManager.client
          .from('friendships')
          .select()
          .eq('user_id', currentUserId)
          .eq('status', 'blocked');

      final blocked = (response as List)
          .map((json) => FriendshipModel.fromJson(json as Map<String, dynamic>))
          .toList();

      Logger.info('Fetched ${blocked.length} blocked users');
      return blocked;
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is FriendServiceException) rethrow;
      Logger.error('Failed to fetch blocked users: $e');
      throw FriendServiceException('Failed to fetch blocked users: $e');
    }
  }

  /// Search for users by email or name
  ///
  /// Returns list of user profiles matching the query
  Future<List<FriendProfile>> searchUsers(String query) async {
    try {
      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) {
        throw FriendServiceException('User not authenticated');
      }

      if (query.length < 2) {
        return [];
      }

      Logger.info('Searching users: $query');

      // Search by email or name (case-insensitive)
      final response = await SupabaseClientManager.client
          .from('users')
          .select('id, email, full_name, avatar_url')
          .or('email.ilike.%$query%,full_name.ilike.%$query%')
          .neq('id', currentUserId) // Exclude self
          .limit(20);

      final users = (response as List)
          .map((json) => FriendProfile.fromUserJson(json as Map<String, dynamic>))
          .toList();

      Logger.info('Found ${users.length} users matching query');
      return users;
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is FriendServiceException) rethrow;
      Logger.error('Failed to search users: $e');
      throw FriendServiceException('Failed to search users: $e');
    }
  }

  /// Check if two users are friends
  ///
  /// Uses the are_friends database function
  Future<bool> areFriends(String otherUserId) async {
    try {
      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) {
        return false;
      }

      final response = await SupabaseClientManager.client.rpc('are_friends',
          params: {'user1_uuid': currentUserId, 'user2_uuid': otherUserId});

      return response as bool;
    } catch (e) {
      Logger.error('Failed to check friendship: $e');
      return false;
    }
  }

  /// Get friendship status with another user
  ///
  /// Returns null if no relationship exists
  Future<FriendshipModel?> getFriendshipStatus(String otherUserId) async {
    try {
      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) {
        return null;
      }

      final response = await SupabaseClientManager.client
          .from('friendships')
          .select()
          .or('and(user_id.eq.$currentUserId,friend_id.eq.$otherUserId),and(user_id.eq.$otherUserId,friend_id.eq.$currentUserId)')
          .maybeSingle();

      if (response == null) return null;
      return FriendshipModel.fromJson(response);
    } catch (e) {
      Logger.error('Failed to get friendship status: $e');
      return null;
    }
  }

  /// Convert PostgrestException to user-friendly FriendServiceException
  FriendServiceException _handlePostgrestError(PostgrestException e) {
    Logger.error('Supabase error: ${e.code} - ${e.message}');

    switch (e.code) {
      case '23505': // unique_violation
        return FriendServiceException(
          'This relationship already exists',
          code: e.code,
        );
      case '23503': // foreign_key_violation
        return FriendServiceException(
          'User not found',
          code: e.code,
        );
      case '42501': // insufficient_privilege (RLS)
        return FriendServiceException(
          'Permission denied',
          code: e.code,
        );
      case 'PGRST116': // JWT expired
        return FriendServiceException(
          'Session expired, please log in again',
          code: e.code,
        );
      case 'PGRST301': // Row not found
        return FriendServiceException(
          'Record not found',
          code: e.code,
        );
      default:
        return FriendServiceException(
          'Database error: ${e.message}',
          code: e.code,
        );
    }
  }

  // ============================================================================
  // REAL-TIME SUBSCRIPTIONS
  // ============================================================================

  /// Subscribe to friend request updates for the current user
  /// Receives notifications when:
  /// - Someone sends a friend request to the user (INSERT with friend_id = userId)
  /// - A friend request status changes (UPDATE)
  RealtimeChannel subscribeToFriendRequests({
    required void Function(Map<String, dynamic> payload) onNewRequest,
    required void Function(Map<String, dynamic> payload) onRequestStatusChange,
  }) {
    final userId = SupabaseClientManager.currentUserId;
    if (userId == null) throw FriendServiceException('User not authenticated');

    Logger.info('FriendService', 'Subscribing to friend requests for user: $userId');

    return SupabaseClientManager.client.channel('friendships:$userId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'friendships',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'friend_id',
          value: userId,
        ),
        callback: (payload) {
          Logger.info('FriendService', 'New friend request received');
          onNewRequest(payload.newRecord);
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'friendships',
        callback: (payload) {
          // Check if this update involves the current user
          final record = payload.newRecord;
          if (record['user_id'] == userId || record['friend_id'] == userId) {
            Logger.info('FriendService', 'Friend request status changed');
            onRequestStatusChange(payload.newRecord);
          }
        },
      )
      .subscribe();
  }

  /// Subscribe to friendship deletions (unfriend events)
  RealtimeChannel subscribeToFriendshipChanges({
    required void Function(Map<String, dynamic> payload) onFriendRemoved,
  }) {
    final userId = SupabaseClientManager.currentUserId;
    if (userId == null) throw FriendServiceException('User not authenticated');

    Logger.info('FriendService', 'Subscribing to friendship changes for user: $userId');

    return SupabaseClientManager.client.channel('friendships_delete:$userId')
      .onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'friendships',
        callback: (payload) {
          // Check if this deletion involves the current user
          final record = payload.oldRecord;
          if (record['user_id'] == userId || record['friend_id'] == userId) {
            Logger.info('FriendService', 'Friend removed');
            onFriendRemoved(payload.oldRecord);
          }
        },
      )
      .subscribe();
  }

  /// Unsubscribe from a channel
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await SupabaseClientManager.client.removeChannel(channel);
    Logger.info('FriendService', 'Unsubscribed from channel');
  }
}
