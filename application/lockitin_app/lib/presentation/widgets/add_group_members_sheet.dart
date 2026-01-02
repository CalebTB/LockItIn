import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/friendship_model.dart';
import '../../data/models/group_model.dart';
import '../providers/friend_provider.dart';
import '../providers/group_provider.dart';
import 'group_members_section.dart';

/// Bottom sheet for selecting friends to add to a group
/// Supports multi-select with search filtering
/// Uses Minimal theme color system
class AddGroupMembersSheet extends StatefulWidget {
  final String groupId;
  final List<GroupMemberProfile> existingMembers;

  const AddGroupMembersSheet({
    super.key,
    required this.groupId,
    required this.existingMembers,
  });

  /// Show this sheet as a modal bottom sheet
  static Future<bool?> show({
    required BuildContext context,
    required String groupId,
    required List<GroupMemberProfile> existingMembers,
  }) {
    HapticFeedback.selectionClick();
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddGroupMembersSheet(
        groupId: groupId,
        existingMembers: existingMembers,
      ),
    );
  }

  @override
  State<AddGroupMembersSheet> createState() => _AddGroupMembersSheetState();
}

class _AddGroupMembersSheetState extends State<AddGroupMembersSheet> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedFriendIds = {};
  String _searchQuery = '';
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    // Ensure friends are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Get friends that are NOT already group members
  List<FriendProfile> _getAvailableFriends(List<FriendProfile> allFriends) {
    final existingUserIds =
        widget.existingMembers.map((m) => m.userId).toSet();
    return allFriends.where((f) => !existingUserIds.contains(f.id)).toList();
  }

  /// Filter friends by search query
  List<FriendProfile> _filterFriends(List<FriendProfile> friends) {
    if (_searchQuery.isEmpty) return friends;
    final query = _searchQuery.toLowerCase();
    return friends
        .where((f) =>
            f.displayName.toLowerCase().contains(query) ||
            f.email.toLowerCase().contains(query))
        .toList();
  }

  void _toggleSelection(String friendId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedFriendIds.contains(friendId)) {
        _selectedFriendIds.remove(friendId);
      } else {
        _selectedFriendIds.add(friendId);
      }
    });
  }

  Future<void> _inviteSelectedMembers() async {
    if (_selectedFriendIds.isEmpty) return;

    setState(() => _isAdding = true);

    final groupProvider = context.read<GroupProvider>();
    int successCount = 0;
    int failCount = 0;

    for (final friendId in _selectedFriendIds) {
      final success = await groupProvider.inviteUser(
        groupId: widget.groupId,
        userId: friendId,
      );
      if (success) {
        successCount++;
      } else {
        failCount++;
      }
    }

    if (mounted) {
      Navigator.pop(context, successCount > 0);
      _showResultSnackBar(successCount, failCount);
    }
  }

  void _showResultSnackBar(int successCount, int failCount) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    String message;
    Color backgroundColor;

    if (failCount == 0) {
      message =
          'Invited $successCount ${successCount == 1 ? 'friend' : 'friends'}';
      backgroundColor = appColors.success;
    } else if (successCount == 0) {
      message = 'Failed to send invites';
      backgroundColor = colorScheme.error;
    } else {
      message = 'Invited $successCount, $failCount failed';
      backgroundColor = appColors.warning;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(colorScheme),
          _buildHeader(colorScheme, appColors),
          _buildSearchField(colorScheme, appColors),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            color: colorScheme.outline.withValues(alpha: 0.15),
          ),
          _buildFriendsList(colorScheme, appColors),
          _buildInviteButton(colorScheme),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildHandle(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, AppColorsExtension appColors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person_add_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invite Members',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Friends will need to accept the invite',
                  style: TextStyle(
                    fontSize: 13,
                    color: appColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Close button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close_rounded,
              color: appColors.textMuted,
            ),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(
      ColorScheme colorScheme, AppColorsExtension appColors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: TextStyle(
          fontSize: 15,
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: 'Search friends...',
          hintStyle: TextStyle(
            color: appColors.textMuted,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: appColors.textMuted,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: Icon(
                    Icons.clear_rounded,
                    color: appColors.textMuted,
                    size: 20,
                  ),
                )
              : null,
          filled: true,
          fillColor: colorScheme.surfaceContainerHigh,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsList(
      ColorScheme colorScheme, AppColorsExtension appColors) {
    return Consumer<FriendProvider>(
      builder: (context, friendProvider, child) {
        if (friendProvider.isLoadingFriends) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            ),
          );
        }

        final availableFriends = _getAvailableFriends(friendProvider.friends);
        final filteredFriends = _filterFriends(availableFriends);

        if (availableFriends.isEmpty) {
          return _buildEmptyState(
            colorScheme,
            appColors,
            icon: Icons.group_off_rounded,
            title: 'No friends to add',
            subtitle: 'All your friends are already in this group',
          );
        }

        if (filteredFriends.isEmpty) {
          return _buildEmptyState(
            colorScheme,
            appColors,
            icon: Icons.search_off_rounded,
            title: 'No matches',
            subtitle: 'Try a different search term',
          );
        }

        return Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filteredFriends.length,
            itemBuilder: (context, index) {
              final friend = filteredFriends[index];
              final isSelected = _selectedFriendIds.contains(friend.id);
              return _buildFriendTile(
                friend,
                index,
                isSelected,
                colorScheme,
                appColors,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
    ColorScheme colorScheme,
    AppColorsExtension appColors, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 48,
            color: appColors.textDisabled,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: appColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFriendTile(
    FriendProfile friend,
    int index,
    bool isSelected,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    final memberColor = GroupMembersSection.getMemberColor(index);

    return InkWell(
      onTap: () => _toggleSelection(friend.id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.08)
              : colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: colorScheme.primary.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: memberColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: memberColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  friend.initials,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Name and email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.displayName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    friend.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: appColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Selection indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHigh,
                shape: BoxShape.circle,
                border: isSelected
                    ? null
                    : Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                      ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteButton(ColorScheme colorScheme) {
    final count = _selectedFriendIds.length;
    final isEnabled = count > 0 && !_isAdding;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isEnabled ? _inviteSelectedMembers : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            disabledBackgroundColor: colorScheme.surfaceContainerHigh,
            disabledForegroundColor: colorScheme.onSurfaceVariant,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isAdding
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  count == 0
                      ? 'Select Friends'
                      : 'Invite $count ${count == 1 ? 'Friend' : 'Friends'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
