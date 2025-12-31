import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/group_model.dart';
import '../../../providers/group_provider.dart';
import 'member_options_sheet.dart';

/// Full members list bottom sheet with role-based management
/// Uses Minimal theme color system
class MembersBottomSheet extends StatelessWidget {
  final GroupModel group;

  const MembersBottomSheet({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Consumer<GroupProvider>(
        builder: (context, provider, _) {
          final canManage = provider.canManageMembers;
          final isOwner = provider.isOwner;

          return Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 8, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Members (${group.memberCount})',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (canManage)
                          Text(
                            'Tap member to manage',
                            style: TextStyle(
                              fontSize: 12,
                              color: appColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),

              // Members list
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (provider.isLoadingMembers) {
                      return Center(
                        child: CircularProgressIndicator(color: colorScheme.primary),
                      );
                    }

                    final members = provider.selectedGroupMembers;

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index];

                        return GestureDetector(
                          onTap: canManage
                              ? () => _showMemberOptions(context, member, provider)
                              : null,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: colorScheme.outline.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Avatar
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: member.role == GroupMemberRole.owner
                                        ? colorScheme.primary
                                        : colorScheme.surfaceContainerHighest,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      member.initials,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: member.role == GroupMemberRole.owner
                                            ? colorScheme.onPrimary
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Name and role
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        member.displayName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      Text(
                                        member.roleDisplayName,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: member.role == GroupMemberRole.owner
                                              ? colorScheme.primary
                                              : appColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Role badge
                                // Owner badge
                                if (member.role == GroupMemberRole.owner)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Owner',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onPrimary,
                                      ),
                                    ),
                                  )
                                // Co-Owner badge
                                else if (member.role == GroupMemberRole.coOwner)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.secondary.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Co-Owner',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.secondary,
                                      ),
                                    ),
                                  ),

                                // Chevron for manageable members (owners can manage everyone)
                                if (canManage)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Icon(
                                      Icons.chevron_right,
                                      size: 20,
                                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Leave group button (for non-owners)
              if (!isOwner && provider.currentUserRole != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmLeaveGroup(context, provider),
                      icon: const Icon(Icons.exit_to_app, size: 18),
                      label: const Text('Leave Group'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showMemberOptions(
    BuildContext context,
    GroupMemberProfile member,
    GroupProvider provider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    // Only owners and co-owners can manage members
    if (!provider.canManageMembers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Only owners and co-owners can manage members'),
          backgroundColor: colorScheme.primary,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MemberOptionsSheet(
        member: member,
        groupId: group.id,
        isOwner: provider.isOwner,
        isCoOwner: provider.isCoOwner,
      ),
    );
  }

  void _confirmLeaveGroup(BuildContext context, GroupProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Leave Group?',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: Text(
          'Are you sure you want to leave "${group.name}"? You will need to be invited again to rejoin.',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close members sheet

              final success = await provider.leaveGroup(group.id);

              if (context.mounted) {
                if (success) {
                  Navigator.pop(context); // Close group detail screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Left ${group.name}'),
                      backgroundColor: colorScheme.primary,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.actionError ?? 'Failed to leave group'),
                      backgroundColor: colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: Text('Leave', style: TextStyle(color: colorScheme.error)),
          ),
        ],
      ),
    );
  }
}
