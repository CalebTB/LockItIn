import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/group_model.dart';
import '../network/supabase_client.dart';
import '../utils/logger.dart';

/// Exception thrown when group operations fail
class GroupServiceException implements Exception {
  final String message;
  final String? code;

  GroupServiceException(this.message, {this.code});

  @override
  String toString() => 'GroupServiceException: $message';
}

/// Service for managing groups with Supabase
///
/// Uses singleton pattern - access via [GroupService.instance] or constructor
class GroupService {
  // Singleton instance
  static final GroupService _instance = GroupService._internal();

  /// Access the singleton instance
  static GroupService get instance => _instance;

  /// Factory constructor returns singleton
  factory GroupService() => _instance;

  /// Private internal constructor
  GroupService._internal();

  // ============================================================================
  // Group CRUD Operations
  // ============================================================================

  /// Create a new group
  ///
  /// Creates the group and adds the creator as owner
  Future<GroupModel> createGroup({
    required String name,
    required String emoji,
  }) async {
    try {
      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) {
        throw GroupServiceException('User not authenticated');
      }

      if (name.trim().isEmpty) {
        throw GroupServiceException('Group name cannot be empty');
      }

      Logger.info('Creating group: $name');

      // Create the group
      final groupResponse = await SupabaseClientManager.client
          .from('groups')
          .insert({
            'name': name.trim(),
            'emoji': emoji,
            'created_by': currentUserId,
          })
          .select()
          .single();

      final groupId = groupResponse['id'] as String;

      // Add creator as owner
      await SupabaseClientManager.client.from('group_members').insert({
        'group_id': groupId,
        'user_id': currentUserId,
        'role': 'owner',
      });

      Logger.info('Group created successfully: $groupId');

      return GroupModel.fromJson(groupResponse).copyWith(memberCount: 1);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is GroupServiceException) rethrow;
      Logger.error('Failed to create group: $e');
      throw GroupServiceException('Failed to create group: $e');
    }
  }

  /// Update a group's details
  Future<GroupModel> updateGroup({
    required String groupId,
    String? name,
    String? emoji,
  }) async {
    try {
      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) {
        throw GroupServiceException('User not authenticated');
      }

      // Check if user has permission to update
      final canUpdate = await _canManageGroup(groupId, currentUserId);
      if (!canUpdate) {
        throw GroupServiceException('You do not have permission to update this group');
      }

      Logger.info('Updating group: $groupId');

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (name != null) updates['name'] = name.trim();
      if (emoji != null) updates['emoji'] = emoji;

      final response = await SupabaseClientManager.client
          .from('groups')
          .update(updates)
          .eq('id', groupId)
          .select()
          .single();

      Logger.info('Group updated successfully');
      return GroupModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is GroupServiceException) rethrow;
      Logger.error('Failed to update group: $e');
      throw GroupServiceException('Failed to update group: $e');
    }
  }

  /// Delete a group
  ///
  /// Only the owner can delete a group
  Future<void> deleteGroup(String groupId) async {
    try {
      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) {
        throw GroupServiceException('User not authenticated');
      }

      // Check if user is owner
      final membership = await _getMembership(groupId, currentUserId);
      if (membership == null || membership['role'] != 'owner') {
        throw GroupServiceException('Only the owner can delete this group');
      }

      Logger.info('Deleting group: $groupId');

      // Delete all members first (cascade should handle this, but explicit is safer)
      await SupabaseClientManager.client
          .from('group_members')
          .delete()
          .eq('group_id', groupId);

      // Delete the group
      await SupabaseClientManager.client
          .from('groups')
          .delete()
          .eq('id', groupId);

      Logger.info('Group deleted successfully');
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is GroupServiceException) rethrow;
      Logger.error('Failed to delete group: $e');
      throw GroupServiceException('Failed to delete group: $e');
    }
  }

  // ============================================================================
  // Member Operations
  // ============================================================================

  /// Add a member to a group
  ///
  /// Only owners can add members directly
  Future<GroupMemberModel> addMember({
    required String groupId,
    required String userId,
    GroupMemberRole role = GroupMemberRole.member,
  }) async {
    try {
      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) {
        throw GroupServiceException('User not authenticated');
      }

      // Check permission
      final canManage = await _canManageGroup(groupId, currentUserId);
      if (!canManage) {
        throw GroupServiceException('You do not have permission to add members');
      }

      // Check if user is already a member
      final existing = await _getMembership(groupId, userId);
      if (existing != null) {
        throw GroupServiceException('User is already a member of this group');
      }

      Logger.info('Adding member $userId to group $groupId');

      final response = await SupabaseClientManager.client
          .from('group_members')
          .insert({
            'group_id': groupId,
            'user_id': userId,
            'role': GroupMemberModel.roleToString(role),
          })
          .select()
          .single();

      Logger.info('Member added successfully');
      return GroupMemberModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is GroupServiceException) rethrow;
      Logger.error('Failed to add member: $e');
      throw GroupServiceException('Failed to add member: $e');
    }
  }

  /// Remove a member from a group
  ///
  /// Owners and co-owners can remove members
  /// Members can remove themselves (leave)
  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) {
        throw GroupServiceException('User not authenticated');
      }

      // Get current user's membership
      final currentMembership = await _getMembership(groupId, currentUserId);
      if (currentMembership == null) {
        throw GroupServiceException('You are not a member of this group');
      }

      final currentRole = currentMembership['role'] as String;

      // Check if removing self (leaving)
      final isLeavingSelf = userId == currentUserId;

      if (!isLeavingSelf) {
        // Only owner or co-owner can remove others
        if (currentRole != 'owner' && currentRole != 'co_owner') {
          throw GroupServiceException('Only owners and co-owners can remove members');
        }

        // Get target user's membership
        final targetMembership = await _getMembership(groupId, userId);
        if (targetMembership == null) {
          throw GroupServiceException('User is not a member of this group');
        }

        final targetRole = targetMembership['role'] as String;

        // Cannot remove the owner
        if (targetRole == 'owner') {
          throw GroupServiceException('Cannot remove the group owner');
        }

        // Co-owners can only remove regular members, not other co-owners
        if (currentRole == 'co_owner' && targetRole == 'co_owner') {
          throw GroupServiceException('Co-owners cannot remove other co-owners');
        }
      } else {
        // Owners cannot leave their own group
        if (currentRole == 'owner') {
          throw GroupServiceException('Owners cannot leave. Transfer ownership or delete the group.');
        }
        // Co-owners can leave (they become a member first conceptually)
      }

      Logger.info('Removing member $userId from group $groupId');

      await SupabaseClientManager.client
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);

      Logger.info('Member removed successfully');
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is GroupServiceException) rethrow;
      Logger.error('Failed to remove member: $e');
      throw GroupServiceException('Failed to remove member: $e');
    }
  }

  /// Promote a member to co-owner
  ///
  /// Owner or co-owners can promote members to co-owner
  Future<void> promoteToCoOwner({
    required String groupId,
    required String userId,
  }) async {
    try {
      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) {
        throw GroupServiceException('User not authenticated');
      }

      // Only owner or co-owners can promote
      final currentMembership = await _getMembership(groupId, currentUserId);
      final currentRole = currentMembership?['role'] as String?;
      if (currentRole != 'owner' && currentRole != 'co_owner') {
        throw GroupServiceException('Only owners and co-owners can promote members');
      }

      // Cannot promote self
      if (userId == currentUserId) {
        throw GroupServiceException('You cannot promote yourself');
      }

      // Verify target is a member
      final targetMembership = await _getMembership(groupId, userId);
      if (targetMembership == null) {
        throw GroupServiceException('User is not a member of this group');
      }

      final targetRole = targetMembership['role'] as String;
      // Check if already owner or co-owner
      if (targetRole == 'owner') {
        throw GroupServiceException('Cannot change the owner role');
      }
      if (targetRole == 'co_owner') {
        throw GroupServiceException('User is already a co-owner');
      }

      Logger.info('Promoting $userId to co-owner in group $groupId');

      await SupabaseClientManager.client
          .from('group_members')
          .update({'role': 'co_owner'})
          .eq('group_id', groupId)
          .eq('user_id', userId);

      Logger.info('Member promoted to co-owner successfully');
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is GroupServiceException) rethrow;
      Logger.error('Failed to promote member: $e');
      throw GroupServiceException('Failed to promote member: $e');
    }
  }

  /// Demote a co-owner to member
  ///
  /// Owner or co-owners can demote co-owners
  Future<void> demoteFromCoOwner({
    required String groupId,
    required String userId,
  }) async {
    try {
      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) {
        throw GroupServiceException('User not authenticated');
      }

      // Only owner or co-owners can demote
      final currentMembership = await _getMembership(groupId, currentUserId);
      final currentRole = currentMembership?['role'] as String?;
      if (currentRole != 'owner' && currentRole != 'co_owner') {
        throw GroupServiceException('Only owners and co-owners can demote');
      }

      // Cannot demote self
      if (userId == currentUserId) {
        throw GroupServiceException('You cannot demote yourself');
      }

      // Verify target is a co-owner
      final targetMembership = await _getMembership(groupId, userId);
      if (targetMembership == null) {
        throw GroupServiceException('User is not a member of this group');
      }

      final targetRole = targetMembership['role'] as String;
      if (targetRole == 'owner') {
        throw GroupServiceException('Cannot demote the owner');
      }
      if (targetRole != 'co_owner') {
        throw GroupServiceException('User is not a co-owner');
      }

      Logger.info('Demoting $userId from co-owner in group $groupId');

      await SupabaseClientManager.client
          .from('group_members')
          .update({'role': 'member'})
          .eq('group_id', groupId)
          .eq('user_id', userId);

      Logger.info('Co-owner demoted to member successfully');
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is GroupServiceException) rethrow;
      Logger.error('Failed to demote co-owner: $e');
      throw GroupServiceException('Failed to demote co-owner: $e');
    }
  }

  /// Transfer group ownership to another member
  ///
  /// Current owner is demoted to member after transfer
  Future<void> transferOwnership({
    required String groupId,
    required String newOwnerId,
  }) async {
    try {
      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) {
        throw GroupServiceException('User not authenticated');
      }

      // Verify current user is owner
      final currentMembership = await _getMembership(groupId, currentUserId);
      if (currentMembership == null || currentMembership['role'] != 'owner') {
        throw GroupServiceException('Only the owner can transfer ownership');
      }

      // Verify new owner is a member
      final newOwnerMembership = await _getMembership(groupId, newOwnerId);
      if (newOwnerMembership == null) {
        throw GroupServiceException('New owner must be a member of the group');
      }

      Logger.info('Transferring ownership of $groupId to $newOwnerId');

      // Update new owner's role to owner
      await SupabaseClientManager.client
          .from('group_members')
          .update({'role': 'owner'})
          .eq('group_id', groupId)
          .eq('user_id', newOwnerId);

      // Demote current owner to member
      await SupabaseClientManager.client
          .from('group_members')
          .update({'role': 'member'})
          .eq('group_id', groupId)
          .eq('user_id', currentUserId);

      Logger.info('Ownership transferred successfully');
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is GroupServiceException) rethrow;
      Logger.error('Failed to transfer ownership: $e');
      throw GroupServiceException('Failed to transfer ownership: $e');
    }
  }

  // ============================================================================
  // Query Operations
  // ============================================================================

  /// Get all groups the current user is a member of
  Future<List<GroupModel>> getUserGroups() async {
    try {
      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) {
        throw GroupServiceException('User not authenticated');
      }

      Logger.info('Fetching groups for user');

      // Get groups with member count using a join and count aggregation
      final response = await SupabaseClientManager.client
          .from('group_members')
          .select('''
            group_id,
            groups!inner (
              id,
              name,
              emoji,
              created_by,
              created_at,
              updated_at,
              members_can_invite
            )
          ''')
          .eq('user_id', currentUserId);

      // Collect all group IDs for batch member count query
      final groupIds = <String>[];
      final groupDataMap = <String, Map<String, dynamic>>{};

      for (final row in response as List) {
        final groupData = row['groups'] as Map<String, dynamic>;
        final groupId = groupData['id'] as String;
        groupIds.add(groupId);
        groupDataMap[groupId] = groupData;
      }

      // Batch query for member counts - single query for all groups
      final memberCounts = <String, int>{};
      if (groupIds.isNotEmpty) {
        final countResponse = await SupabaseClientManager.client
            .from('group_members')
            .select('group_id')
            .inFilter('group_id', groupIds);

        // Count members per group
        for (final row in countResponse as List) {
          final gid = row['group_id'] as String;
          memberCounts[gid] = (memberCounts[gid] ?? 0) + 1;
        }
      }

      // Build group models with counts
      final groups = groupIds.map((groupId) {
        return GroupModel.fromJson(groupDataMap[groupId]!).copyWith(
          memberCount: memberCounts[groupId] ?? 0,
        );
      }).toList();

      Logger.info('Fetched ${groups.length} groups');
      return groups;
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is GroupServiceException) rethrow;
      Logger.error('Failed to fetch groups: $e');
      throw GroupServiceException('Failed to fetch groups: $e');
    }
  }

  /// Get a single group by ID
  Future<GroupModel?> getGroup(String groupId) async {
    try {
      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) {
        throw GroupServiceException('User not authenticated');
      }

      // Verify user is a member
      final membership = await _getMembership(groupId, currentUserId);
      if (membership == null) {
        return null;
      }

      final response = await SupabaseClientManager.client
          .from('groups')
          .select()
          .eq('id', groupId)
          .maybeSingle();

      if (response == null) return null;

      // Get member count
      final countResponse = await SupabaseClientManager.client
          .from('group_members')
          .select()
          .eq('group_id', groupId);

      return GroupModel.fromJson(response).copyWith(
        memberCount: (countResponse as List).length,
      );
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is GroupServiceException) rethrow;
      Logger.error('Failed to fetch group: $e');
      throw GroupServiceException('Failed to fetch group: $e');
    }
  }

  /// Get all members of a group with their profiles
  Future<List<GroupMemberProfile>> getGroupMembers(String groupId) async {
    try {
      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) {
        throw GroupServiceException('User not authenticated');
      }

      // Verify user is a member
      final membership = await _getMembership(groupId, currentUserId);
      if (membership == null) {
        throw GroupServiceException('You are not a member of this group');
      }

      Logger.info('Fetching members for group: $groupId');

      final response = await SupabaseClientManager.client
          .from('group_members')
          .select('''
            id,
            user_id,
            role,
            joined_at,
            users!group_members_user_id_fkey (
              id,
              email,
              full_name,
              avatar_url
            )
          ''')
          .eq('group_id', groupId);

      final members = (response as List).map((row) {
        final userData = row['users'] as Map<String, dynamic>?;
        return GroupMemberProfile(
          memberId: row['id'] as String,
          userId: row['user_id'] as String,
          fullName: userData?['full_name'] as String?,
          email: userData?['email'] as String? ?? 'Unknown',
          avatarUrl: userData?['avatar_url'] as String?,
          role: GroupMemberModel.roleFromString(row['role'] as String),
          joinedAt: DateTime.parse(row['joined_at'] as String),
        );
      }).toList();

      // Sort: owner first, then co-owners, then members by join date
      members.sort((a, b) {
        final roleOrder = {
          GroupMemberRole.owner: 0,
          GroupMemberRole.coOwner: 1,
          GroupMemberRole.member: 2,
        };
        final roleCompare = roleOrder[a.role]!.compareTo(roleOrder[b.role]!);
        if (roleCompare != 0) return roleCompare;
        // Same role - sort by join date
        return a.joinedAt.compareTo(b.joinedAt);
      });

      Logger.info('Fetched ${members.length} members');
      return members;
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is GroupServiceException) rethrow;
      Logger.error('Failed to fetch group members: $e');
      throw GroupServiceException('Failed to fetch group members: $e');
    }
  }

  /// Get current user's role in a group
  Future<GroupMemberRole?> getUserRole(String groupId) async {
    try {
      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) return null;

      final membership = await _getMembership(groupId, currentUserId);
      if (membership == null) return null;

      return GroupMemberModel.roleFromString(membership['role'] as String);
    } catch (e) {
      Logger.error('Failed to get user role: $e');
      return null;
    }
  }

  // ============================================================================
  // Invite Operations
  // ============================================================================

  /// Invite a user to a group
  ///
  /// Owners can always invite. Members can invite if the group allows it.
  Future<void> inviteUser({
    required String groupId,
    required String userId,
  }) async {
    try {
      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) {
        throw GroupServiceException('User not authenticated');
      }

      // Check permission to invite
      final canInvite = await _canInviteToGroup(groupId, currentUserId);
      if (!canInvite) {
        throw GroupServiceException('You do not have permission to invite users');
      }

      // Check if user is already a member
      final existingMember = await _getMembership(groupId, userId);
      if (existingMember != null) {
        throw GroupServiceException('User is already a member of this group');
      }

      // Check if invite already exists
      final existingInvite = await SupabaseClientManager.client
          .from('group_invites')
          .select()
          .eq('group_id', groupId)
          .eq('invited_user_id', userId)
          .maybeSingle();

      if (existingInvite != null) {
        throw GroupServiceException('User has already been invited');
      }

      Logger.info('Inviting user $userId to group $groupId');

      await SupabaseClientManager.client.from('group_invites').insert({
        'group_id': groupId,
        'invited_user_id': userId,
        'invited_by': currentUserId,
      });

      Logger.info('Invite sent successfully');
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is GroupServiceException) rethrow;
      Logger.error('Failed to invite user: $e');
      throw GroupServiceException('Failed to invite user: $e');
    }
  }

  /// Accept a group invite
  ///
  /// Adds the user as a member and deletes the invite
  Future<GroupMemberModel> acceptInvite(String inviteId) async {
    try {
      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) {
        throw GroupServiceException('User not authenticated');
      }

      Logger.info('Accepting invite: $inviteId');

      // Get the invite
      final invite = await SupabaseClientManager.client
          .from('group_invites')
          .select()
          .eq('id', inviteId)
          .eq('invited_user_id', currentUserId)
          .maybeSingle();

      if (invite == null) {
        throw GroupServiceException('Invite not found or not for you');
      }

      final groupId = invite['group_id'] as String;

      // Add user as member
      final memberResponse = await SupabaseClientManager.client
          .from('group_members')
          .insert({
            'group_id': groupId,
            'user_id': currentUserId,
            'role': 'member',
          })
          .select()
          .single();

      // Delete the invite
      await SupabaseClientManager.client
          .from('group_invites')
          .delete()
          .eq('id', inviteId);

      Logger.info('Invite accepted, now a member of group $groupId');
      return GroupMemberModel.fromJson(memberResponse);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is GroupServiceException) rethrow;
      Logger.error('Failed to accept invite: $e');
      throw GroupServiceException('Failed to accept invite: $e');
    }
  }

  /// Decline a group invite
  Future<void> declineInvite(String inviteId) async {
    try {
      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) {
        throw GroupServiceException('User not authenticated');
      }

      Logger.info('Declining invite: $inviteId');

      await SupabaseClientManager.client
          .from('group_invites')
          .delete()
          .eq('id', inviteId)
          .eq('invited_user_id', currentUserId);

      Logger.info('Invite declined');
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is GroupServiceException) rethrow;
      Logger.error('Failed to decline invite: $e');
      throw GroupServiceException('Failed to decline invite: $e');
    }
  }

  /// Cancel a pending invite (for admins/owners)
  Future<void> cancelInvite(String inviteId) async {
    try {
      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) {
        throw GroupServiceException('User not authenticated');
      }

      // Get the invite to check permission
      final invite = await SupabaseClientManager.client
          .from('group_invites')
          .select()
          .eq('id', inviteId)
          .maybeSingle();

      if (invite == null) {
        throw GroupServiceException('Invite not found');
      }

      final groupId = invite['group_id'] as String;

      // Check permission
      final canManage = await _canManageGroup(groupId, currentUserId);
      if (!canManage) {
        throw GroupServiceException('You do not have permission to cancel invites');
      }

      Logger.info('Canceling invite: $inviteId');

      await SupabaseClientManager.client
          .from('group_invites')
          .delete()
          .eq('id', inviteId);

      Logger.info('Invite canceled');
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is GroupServiceException) rethrow;
      Logger.error('Failed to cancel invite: $e');
      throw GroupServiceException('Failed to cancel invite: $e');
    }
  }

  /// Get all pending invites for the current user
  Future<List<GroupInvite>> getPendingInvites() async {
    try {
      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) {
        throw GroupServiceException('User not authenticated');
      }

      Logger.info('Fetching pending group invites');

      final response = await SupabaseClientManager.client
          .rpc('get_pending_group_invites', params: {'user_uuid': currentUserId});

      final invites = (response as List)
          .map((json) => GroupInvite.fromJson(json as Map<String, dynamic>))
          .toList();

      Logger.info('Fetched ${invites.length} pending invites');
      return invites;
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is GroupServiceException) rethrow;
      Logger.error('Failed to fetch pending invites: $e');
      throw GroupServiceException('Failed to fetch pending invites: $e');
    }
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Check if user can manage the group (owner or co-owner)
  Future<bool> _canManageGroup(String groupId, String userId) async {
    final membership = await _getMembership(groupId, userId);
    if (membership == null) return false;
    final role = membership['role'] as String;
    return role == 'owner' || role == 'co_owner';
  }

  /// Check if user can invite to the group
  ///
  /// Owner/co-owner can always invite. Members can invite if group allows it.
  Future<bool> _canInviteToGroup(String groupId, String userId) async {
    final membership = await _getMembership(groupId, userId);
    if (membership == null) return false;

    final role = membership['role'] as String;
    if (role == 'owner' || role == 'co_owner') return true;

    // Check if group allows member invites
    final group = await SupabaseClientManager.client
        .from('groups')
        .select('members_can_invite')
        .eq('id', groupId)
        .maybeSingle();

    return group?['members_can_invite'] as bool? ?? true;
  }

  /// Get a user's membership in a group
  Future<Map<String, dynamic>?> _getMembership(String groupId, String userId) async {
    final response = await SupabaseClientManager.client
        .from('group_members')
        .select()
        .eq('group_id', groupId)
        .eq('user_id', userId)
        .maybeSingle();

    return response;
  }

  /// Convert PostgrestException to user-friendly GroupServiceException
  GroupServiceException _handlePostgrestError(PostgrestException e) {
    Logger.error('Supabase error: ${e.code} - ${e.message}');

    switch (e.code) {
      case '23505': // unique_violation
        return GroupServiceException(
          'This already exists',
          code: e.code,
        );
      case '23503': // foreign_key_violation
        return GroupServiceException(
          'Referenced record not found',
          code: e.code,
        );
      case '42501': // insufficient_privilege (RLS)
        return GroupServiceException(
          'Permission denied',
          code: e.code,
        );
      case 'PGRST116': // JWT expired
        return GroupServiceException(
          'Session expired, please log in again',
          code: e.code,
        );
      case 'PGRST301': // Row not found
        return GroupServiceException(
          'Record not found',
          code: e.code,
        );
      default:
        return GroupServiceException(
          'Database error: ${e.message}',
          code: e.code,
        );
    }
  }
}
