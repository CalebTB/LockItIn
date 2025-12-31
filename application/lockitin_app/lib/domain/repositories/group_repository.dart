import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/group_model.dart';

/// Repository interface for group operations
/// Abstracts the data source (Supabase) from the domain layer
abstract class IGroupRepository {
  /// Create a new group
  Future<GroupModel> createGroup({
    required String name,
    required String emoji,
  });

  /// Update a group
  Future<void> updateGroup({
    required String groupId,
    String? name,
    String? emoji,
    bool? membersCanInvite,
  });

  /// Delete a group
  Future<void> deleteGroup(String groupId);

  /// Get user's groups
  Future<List<GroupModel>> getGroups();

  /// Get a single group with details
  Future<GroupModel?> getGroup(String groupId);

  /// Get group members
  Future<List<GroupMemberModel>> getGroupMembers(String groupId);

  /// Add a member to a group
  Future<void> addMember({
    required String groupId,
    required String userId,
    required String role,
  });

  /// Remove a member from a group
  Future<void> removeMember({
    required String groupId,
    required String userId,
  });

  /// Promote a member to co-owner
  Future<void> promoteMember({
    required String groupId,
    required String userId,
  });

  /// Demote a co-owner to member
  Future<void> demoteMember({
    required String groupId,
    required String userId,
  });

  /// Transfer ownership
  Future<void> transferOwnership({
    required String groupId,
    required String newOwnerId,
  });

  /// Invite a user to a group
  Future<void> inviteUser({
    required String groupId,
    required String userId,
  });

  /// Accept a group invite
  Future<void> acceptInvite(String inviteId);

  /// Decline a group invite
  Future<void> declineInvite(String inviteId);

  /// Cancel a group invite
  Future<void> cancelInvite(String inviteId);

  /// Get pending invites for current user
  Future<List<Map<String, dynamic>>> getPendingInvites();

  /// Get user's role in a group
  Future<String?> getUserRole(String groupId);

  /// Subscribe to group invites
  RealtimeChannel subscribeToGroupInvites({
    required void Function(Map<String, dynamic> payload) onNewInvite,
    required void Function(Map<String, dynamic> payload) onInviteStatusChange,
  });

  /// Subscribe to group member changes
  RealtimeChannel subscribeToGroupMembers({
    required String groupId,
    required void Function(Map<String, dynamic> payload) onMemberJoined,
    required void Function(Map<String, dynamic> payload) onMemberLeft,
  });

  /// Subscribe to group updates
  RealtimeChannel subscribeToGroupUpdates({
    required String groupId,
    required void Function(Map<String, dynamic> payload) onGroupUpdated,
  });

  /// Unsubscribe from a channel
  Future<void> unsubscribe(RealtimeChannel channel);
}
