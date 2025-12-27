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
  /// Only owners and admins can add members
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
    } catch (e) {
      if (e is GroupServiceException) rethrow;
      Logger.error('Failed to add member: $e');
      throw GroupServiceException('Failed to add member: $e');
    }
  }

  /// Remove a member from a group
  ///
  /// Owners and admins can remove members
  /// Admins cannot remove owners or other admins
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

      // Check if removing self (leaving)
      final isLeavingSelf = userId == currentUserId;

      if (!isLeavingSelf) {
        // Check permission to remove others
        final currentRole = currentMembership['role'] as String;
        if (currentRole != 'owner' && currentRole != 'admin') {
          throw GroupServiceException('You do not have permission to remove members');
        }

        // Get target user's membership
        final targetMembership = await _getMembership(groupId, userId);
        if (targetMembership == null) {
          throw GroupServiceException('User is not a member of this group');
        }

        final targetRole = targetMembership['role'] as String;

        // Admins cannot remove owners or other admins
        if (currentRole == 'admin' && (targetRole == 'owner' || targetRole == 'admin')) {
          throw GroupServiceException('Admins cannot remove owners or other admins');
        }
      } else {
        // Owners cannot leave their own group
        if (currentMembership['role'] == 'owner') {
          throw GroupServiceException('Owners cannot leave. Transfer ownership or delete the group.');
        }
      }

      Logger.info('Removing member $userId from group $groupId');

      await SupabaseClientManager.client
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);

      Logger.info('Member removed successfully');
    } catch (e) {
      if (e is GroupServiceException) rethrow;
      Logger.error('Failed to remove member: $e');
      throw GroupServiceException('Failed to remove member: $e');
    }
  }

  /// Update a member's role
  ///
  /// Only owners can change roles
  Future<void> updateMemberRole({
    required String groupId,
    required String userId,
    required GroupMemberRole newRole,
  }) async {
    try {
      final currentUserId = SupabaseClientManager.currentUserId;
      if (currentUserId == null) {
        throw GroupServiceException('User not authenticated');
      }

      // Only owners can change roles
      final currentMembership = await _getMembership(groupId, currentUserId);
      if (currentMembership == null || currentMembership['role'] != 'owner') {
        throw GroupServiceException('Only the owner can change member roles');
      }

      // Cannot change own role
      if (userId == currentUserId) {
        throw GroupServiceException('You cannot change your own role');
      }

      // Cannot have multiple owners
      if (newRole == GroupMemberRole.owner) {
        throw GroupServiceException('Use transfer ownership instead');
      }

      Logger.info('Updating role for $userId in group $groupId to ${GroupMemberModel.roleToString(newRole)}');

      await SupabaseClientManager.client
          .from('group_members')
          .update({'role': GroupMemberModel.roleToString(newRole)})
          .eq('group_id', groupId)
          .eq('user_id', userId);

      Logger.info('Role updated successfully');
    } catch (e) {
      if (e is GroupServiceException) rethrow;
      Logger.error('Failed to update member role: $e');
      throw GroupServiceException('Failed to update member role: $e');
    }
  }

  /// Transfer group ownership to another member
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

      // Demote current owner to admin
      await SupabaseClientManager.client
          .from('group_members')
          .update({'role': 'admin'})
          .eq('group_id', groupId)
          .eq('user_id', currentUserId);

      Logger.info('Ownership transferred successfully');
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

      // Get groups with member count using a join
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
              updated_at
            )
          ''')
          .eq('user_id', currentUserId);

      // Get member counts for each group
      final groups = <GroupModel>[];
      for (final row in response as List) {
        final groupData = row['groups'] as Map<String, dynamic>;
        final groupId = groupData['id'] as String;

        // Get member count
        final countResponse = await SupabaseClientManager.client
            .from('group_members')
            .select()
            .eq('group_id', groupId);

        groups.add(GroupModel.fromJson(groupData).copyWith(
          memberCount: (countResponse as List).length,
        ));
      }

      Logger.info('Fetched ${groups.length} groups');
      return groups;
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

      // Sort: owner first, then admins, then members
      members.sort((a, b) {
        final roleOrder = {
          GroupMemberRole.owner: 0,
          GroupMemberRole.admin: 1,
          GroupMemberRole.member: 2,
        };
        return roleOrder[a.role]!.compareTo(roleOrder[b.role]!);
      });

      Logger.info('Fetched ${members.length} members');
      return members;
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
  // Helper Methods
  // ============================================================================

  /// Check if user can manage the group (owner or admin)
  Future<bool> _canManageGroup(String groupId, String userId) async {
    final membership = await _getMembership(groupId, userId);
    if (membership == null) return false;
    final role = membership['role'] as String;
    return role == 'owner' || role == 'admin';
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
}
