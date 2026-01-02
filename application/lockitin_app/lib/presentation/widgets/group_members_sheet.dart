import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/group_model.dart';
import 'add_group_members_sheet.dart';
import 'group_members_section.dart';

/// Bottom sheet showing all group members
/// Uses Minimal theme color system
///
/// Displays:
/// - Drag handle for dismissal
/// - Header with member count
/// - Scrollable list of all members with role badges
/// - Color-coded avatars matching GroupMembersSection
class GroupMembersSheet extends StatelessWidget {
  final GroupModel group;
  final List<GroupMemberProfile> members;
  final String? currentUserId;
  final VoidCallback? onMembersChanged;

  const GroupMembersSheet({
    super.key,
    required this.group,
    required this.members,
    this.currentUserId,
    this.onMembersChanged,
  });

  /// Check if current user is owner or co-owner (can add members)
  bool get _isOwnerOrCoOwner {
    if (currentUserId == null) return false;
    final currentMember = members
        .where((m) => m.userId == currentUserId)
        .toList();
    if (currentMember.isEmpty) return false;
    return currentMember.first.role == GroupMemberRole.owner ||
        currentMember.first.role == GroupMemberRole.coOwner;
  }

  /// Show this sheet as a modal bottom sheet
  static Future<void> show({
    required BuildContext context,
    required GroupModel group,
    required List<GroupMemberProfile> members,
    String? currentUserId,
    VoidCallback? onMembersChanged,
  }) {
    HapticFeedback.selectionClick();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GroupMembersSheet(
        group: group,
        members: members,
        currentUserId: currentUserId,
        onMembersChanged: onMembersChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    // Sort members: owners first, then by name
    final sortedMembers = List<GroupMemberProfile>.from(members)
      ..sort((a, b) {
        // Owners first
        if (a.role == GroupMemberRole.owner &&
            b.role != GroupMemberRole.owner) {
          return -1;
        }
        if (b.role == GroupMemberRole.owner &&
            a.role != GroupMemberRole.owner) {
          return 1;
        }
        // Co-owners second
        if (a.role == GroupMemberRole.coOwner &&
            b.role == GroupMemberRole.member) {
          return -1;
        }
        if (b.role == GroupMemberRole.coOwner &&
            a.role == GroupMemberRole.member) {
          return 1;
        }
        // Then alphabetically
        return a.displayName.compareTo(b.displayName);
      });

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
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
          // Drag handle
          _buildHandle(colorScheme),
          // Header
          _buildHeader(context, colorScheme, appColors),
          // Divider
          Divider(
            height: 1,
            color: colorScheme.outline.withValues(alpha: 0.15),
          ),
          // Member list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: sortedMembers.length,
              itemBuilder: (context, index) {
                return _buildMemberTile(
                  sortedMembers[index],
                  index,
                  colorScheme,
                  appColors,
                );
              },
            ),
          ),
          // Safe area
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

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(
        children: [
          // Group emoji
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                group.emoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Title and count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Members',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${members.length} ${members.length == 1 ? 'person' : 'people'} in ${group.name}',
                  style: TextStyle(
                    fontSize: 13,
                    color: appColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Invite member button (only for owners/co-owners)
          if (_isOwnerOrCoOwner)
            IconButton(
              onPressed: () => _showAddMembersSheet(context),
              icon: Icon(
                Icons.person_add_rounded,
                color: colorScheme.primary,
              ),
              tooltip: 'Invite members',
            ),
        ],
      ),
    );
  }

  /// Show the add members sheet
  Future<void> _showAddMembersSheet(BuildContext context) async {
    final result = await AddGroupMembersSheet.show(
      context: context,
      groupId: group.id,
      existingMembers: members,
    );

    if (result == true) {
      // Members were added, notify parent to refresh
      onMembersChanged?.call();
    }
  }

  Widget _buildMemberTile(
    GroupMemberProfile member,
    int index,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    final isCurrentUser = member.userId == currentUserId;
    final memberColor = GroupMembersSection.getMemberColor(index);
    final isOwner = member.role == GroupMemberRole.owner ||
        member.role == GroupMemberRole.coOwner;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? colorScheme.primary.withValues(alpha: 0.08)
            : colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: isCurrentUser
            ? Border.all(
                color: colorScheme.primary.withValues(alpha: 0.2),
              )
            : null,
      ),
      child: Row(
        children: [
          // Avatar with color
          Stack(
            clipBehavior: Clip.none,
            children: [
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
                    member.initials,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Crown for owner/co-owner
              if (isOwner)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCurrentUser
                            ? colorScheme.primary.withValues(alpha: 0.08)
                            : colorScheme.surfaceContainer,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // Name and email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.displayName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'You',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  member.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: appColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _getRoleBadgeColor(member.role, colorScheme),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              member.roleDisplayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _getRoleBadgeTextColor(member.role, colorScheme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleBadgeColor(GroupMemberRole role, ColorScheme colorScheme) {
    switch (role) {
      case GroupMemberRole.owner:
        return AppColors.warning.withValues(alpha: 0.15);
      case GroupMemberRole.coOwner:
        return AppColors.warning.withValues(alpha: 0.1);
      case GroupMemberRole.member:
        return colorScheme.surfaceContainerHigh;
    }
  }

  Color _getRoleBadgeTextColor(GroupMemberRole role, ColorScheme colorScheme) {
    switch (role) {
      case GroupMemberRole.owner:
        return AppColors.warning;
      case GroupMemberRole.coOwner:
        return AppColors.warning;
      case GroupMemberRole.member:
        return colorScheme.onSurfaceVariant;
    }
  }
}
