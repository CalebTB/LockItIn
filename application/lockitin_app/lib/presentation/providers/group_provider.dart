import 'package:flutter/foundation.dart';
import '../../data/models/group_model.dart';
import '../../core/services/group_service.dart';
import '../../core/utils/logger.dart';

/// Provider for group system state management
///
/// Manages groups list, group members, and group operations
class GroupProvider extends ChangeNotifier {
  final GroupService _groupService = GroupService.instance;

  /// List of groups the user is a member of
  List<GroupModel> _groups = [];

  /// Currently selected group (for detail view)
  GroupModel? _selectedGroup;

  /// Members of the currently selected group
  List<GroupMemberProfile> _selectedGroupMembers = [];

  /// Loading states
  bool _isLoadingGroups = false;
  bool _isLoadingMembers = false;
  bool _isCreatingGroup = false;
  bool _isUpdatingGroup = false;

  /// Error states
  String? _groupsError;
  String? _membersError;
  String? _actionError;

  /// Whether initial data has been loaded
  bool _isInitialized = false;

  // ============================================================================
  // Getters
  // ============================================================================

  List<GroupModel> get groups => _groups;
  GroupModel? get selectedGroup => _selectedGroup;
  List<GroupMemberProfile> get selectedGroupMembers => _selectedGroupMembers;

  bool get isLoadingGroups => _isLoadingGroups;
  bool get isLoadingMembers => _isLoadingMembers;
  bool get isCreatingGroup => _isCreatingGroup;
  bool get isUpdatingGroup => _isUpdatingGroup;

  String? get groupsError => _groupsError;
  String? get membersError => _membersError;
  String? get actionError => _actionError;

  bool get isInitialized => _isInitialized;

  /// Total count of groups
  int get groupCount => _groups.length;

  /// Check if user has any groups
  bool get hasGroups => _groups.isNotEmpty;

  // ============================================================================
  // Initialization
  // ============================================================================

  /// Initialize the provider and load groups
  /// Skips if already initialized - use [refresh] to force reload
  Future<void> initialize() async {
    if (_isInitialized) return;

    await loadGroups();
    _isInitialized = true;
  }

  // ============================================================================
  // Data Loading
  // ============================================================================

  /// Load list of groups the user is a member of
  Future<void> loadGroups() async {
    _isLoadingGroups = true;
    _groupsError = null;
    notifyListeners();

    try {
      _groups = await _groupService.getUserGroups();
      Logger.info('Loaded ${_groups.length} groups');
    } catch (e) {
      _groupsError = e.toString();
      Logger.error('Failed to load groups: $e');
    } finally {
      _isLoadingGroups = false;
      notifyListeners();
    }
  }

  /// Refresh groups (force reload)
  Future<void> refresh() async {
    await loadGroups();
  }

  /// Select a group and load its members
  Future<void> selectGroup(String groupId) async {
    // Find the group in our list
    final group = _groups.where((g) => g.id == groupId).firstOrNull;
    if (group == null) {
      _actionError = 'Group not found';
      notifyListeners();
      return;
    }

    _selectedGroup = group;
    notifyListeners();

    await loadGroupMembers(groupId);
  }

  /// Clear the selected group
  void clearSelectedGroup() {
    _selectedGroup = null;
    _selectedGroupMembers = [];
    _membersError = null;
    notifyListeners();
  }

  /// Load members for a specific group
  Future<void> loadGroupMembers(String groupId) async {
    _isLoadingMembers = true;
    _membersError = null;
    notifyListeners();

    try {
      _selectedGroupMembers = await _groupService.getGroupMembers(groupId);
      Logger.info('Loaded ${_selectedGroupMembers.length} members');
    } catch (e) {
      _membersError = e.toString();
      Logger.error('Failed to load group members: $e');
    } finally {
      _isLoadingMembers = false;
      notifyListeners();
    }
  }

  // ============================================================================
  // Group Operations
  // ============================================================================

  /// Create a new group
  Future<GroupModel?> createGroup({
    required String name,
    required String emoji,
  }) async {
    _isCreatingGroup = true;
    _actionError = null;
    notifyListeners();

    try {
      final group = await _groupService.createGroup(name: name, emoji: emoji);

      // Add to local list
      _groups.insert(0, group);

      Logger.info('Created group: ${group.id}');
      notifyListeners();
      return group;
    } catch (e) {
      _actionError = e.toString();
      Logger.error('Failed to create group: $e');
      notifyListeners();
      return null;
    } finally {
      _isCreatingGroup = false;
      notifyListeners();
    }
  }

  /// Update a group's details
  Future<bool> updateGroup({
    required String groupId,
    String? name,
    String? emoji,
  }) async {
    _isUpdatingGroup = true;
    _actionError = null;
    notifyListeners();

    try {
      final updatedGroup = await _groupService.updateGroup(
        groupId: groupId,
        name: name,
        emoji: emoji,
      );

      // Update in local list
      final index = _groups.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        _groups[index] = updatedGroup.copyWith(
          memberCount: _groups[index].memberCount,
        );
      }

      // Update selected group if it's the same
      if (_selectedGroup?.id == groupId) {
        _selectedGroup = updatedGroup.copyWith(
          memberCount: _selectedGroup!.memberCount,
        );
      }

      Logger.info('Updated group: $groupId');
      notifyListeners();
      return true;
    } catch (e) {
      _actionError = e.toString();
      Logger.error('Failed to update group: $e');
      notifyListeners();
      return false;
    } finally {
      _isUpdatingGroup = false;
      notifyListeners();
    }
  }

  /// Delete a group
  Future<bool> deleteGroup(String groupId) async {
    _actionError = null;

    try {
      await _groupService.deleteGroup(groupId);

      // Remove from local list
      _groups.removeWhere((g) => g.id == groupId);

      // Clear selected if it was this group
      if (_selectedGroup?.id == groupId) {
        clearSelectedGroup();
      }

      Logger.info('Deleted group: $groupId');
      notifyListeners();
      return true;
    } catch (e) {
      _actionError = e.toString();
      Logger.error('Failed to delete group: $e');
      notifyListeners();
      return false;
    }
  }

  // ============================================================================
  // Member Operations
  // ============================================================================

  /// Add a member to a group
  Future<bool> addMember({
    required String groupId,
    required String userId,
    GroupMemberRole role = GroupMemberRole.member,
  }) async {
    _actionError = null;

    try {
      await _groupService.addMember(
        groupId: groupId,
        userId: userId,
        role: role,
      );

      // Update member count in local list
      final index = _groups.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        _groups[index] = _groups[index].copyWith(
          memberCount: _groups[index].memberCount + 1,
        );
      }

      // Reload members if viewing this group
      if (_selectedGroup?.id == groupId) {
        await loadGroupMembers(groupId);
      }

      Logger.info('Added member $userId to group $groupId');
      notifyListeners();
      return true;
    } catch (e) {
      _actionError = e.toString();
      Logger.error('Failed to add member: $e');
      notifyListeners();
      return false;
    }
  }

  /// Remove a member from a group
  Future<bool> removeMember({
    required String groupId,
    required String userId,
  }) async {
    _actionError = null;

    try {
      await _groupService.removeMember(groupId: groupId, userId: userId);

      // Update member count in local list
      final index = _groups.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        _groups[index] = _groups[index].copyWith(
          memberCount: _groups[index].memberCount - 1,
        );
      }

      // Remove from local members list if viewing this group
      if (_selectedGroup?.id == groupId) {
        _selectedGroupMembers.removeWhere((m) => m.userId == userId);
      }

      Logger.info('Removed member $userId from group $groupId');
      notifyListeners();
      return true;
    } catch (e) {
      _actionError = e.toString();
      Logger.error('Failed to remove member: $e');
      notifyListeners();
      return false;
    }
  }

  /// Leave a group (remove self)
  Future<bool> leaveGroup(String groupId) async {
    _actionError = null;

    try {
      // removeMember with own userId
      await _groupService.removeMember(groupId: groupId, userId: '');

      // Remove from local list (we're no longer a member)
      _groups.removeWhere((g) => g.id == groupId);

      // Clear selected if it was this group
      if (_selectedGroup?.id == groupId) {
        clearSelectedGroup();
      }

      Logger.info('Left group: $groupId');
      notifyListeners();
      return true;
    } catch (e) {
      _actionError = e.toString();
      Logger.error('Failed to leave group: $e');
      notifyListeners();
      return false;
    }
  }

  /// Update a member's role
  Future<bool> updateMemberRole({
    required String groupId,
    required String userId,
    required GroupMemberRole newRole,
  }) async {
    _actionError = null;

    try {
      await _groupService.updateMemberRole(
        groupId: groupId,
        userId: userId,
        newRole: newRole,
      );

      // Update in local members list if viewing this group
      if (_selectedGroup?.id == groupId) {
        final index = _selectedGroupMembers.indexWhere((m) => m.userId == userId);
        if (index != -1) {
          // Reload members to get updated data
          await loadGroupMembers(groupId);
        }
      }

      Logger.info('Updated role for $userId in $groupId to $newRole');
      notifyListeners();
      return true;
    } catch (e) {
      _actionError = e.toString();
      Logger.error('Failed to update member role: $e');
      notifyListeners();
      return false;
    }
  }

  /// Transfer ownership to another member
  Future<bool> transferOwnership({
    required String groupId,
    required String newOwnerId,
  }) async {
    _actionError = null;

    try {
      await _groupService.transferOwnership(
        groupId: groupId,
        newOwnerId: newOwnerId,
      );

      // Reload members to get updated roles
      if (_selectedGroup?.id == groupId) {
        await loadGroupMembers(groupId);
      }

      Logger.info('Transferred ownership of $groupId to $newOwnerId');
      notifyListeners();
      return true;
    } catch (e) {
      _actionError = e.toString();
      Logger.error('Failed to transfer ownership: $e');
      notifyListeners();
      return false;
    }
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Get a group by ID from cached list
  GroupModel? getGroupById(String groupId) {
    return _groups.where((g) => g.id == groupId).firstOrNull;
  }

  /// Check if user is a member of a group
  bool isMemberOf(String groupId) {
    return _groups.any((g) => g.id == groupId);
  }

  /// Clear action error
  void clearActionError() {
    _actionError = null;
    notifyListeners();
  }
}
