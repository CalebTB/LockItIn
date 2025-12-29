import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/group_model.dart';
import '../../../providers/group_provider.dart';
import '../../../theme/sunset_coral_theme.dart';
import 'member_options_sheet.dart';

/// Full members list bottom sheet with role-based management
class MembersBottomSheet extends StatelessWidget {
  final GroupModel group;

  const MembersBottomSheet({super.key, required this.group});

  static const Color _rose950 = SunsetCoralTheme.rose950;
  static const Color _rose900 = SunsetCoralTheme.rose900;
  static const Color _rose500 = SunsetCoralTheme.rose500;
  static const Color _rose400 = SunsetCoralTheme.rose400;
  static const Color _rose300 = SunsetCoralTheme.rose300;
  static const Color _rose200 = SunsetCoralTheme.rose200;
  static const Color _rose50 = SunsetCoralTheme.rose50;
  static const Color _orange400 = SunsetCoralTheme.orange400;
  static const Color _slate950 = SunsetCoralTheme.slate950;
  static const Color _red500 = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_rose950, _slate950],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: _rose500.withValues(alpha: 0.4),
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
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [_rose200, Color(0xFFFED7AA)],
                          ).createShader(bounds),
                          child: Text(
                            'Members (${group.memberCount})',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (canManage)
                          Text(
                            'Tap member to manage',
                            style: TextStyle(
                              fontSize: 12,
                              color: _rose300.withValues(alpha: 0.6),
                            ),
                          ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: _rose300,
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
                        child: CircularProgressIndicator(color: _rose400),
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
                              color: _rose900.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _rose500.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Avatar
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: member.role == GroupMemberRole.owner
                                        ? const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [_rose400, _orange400],
                                          )
                                        : null,
                                    color: member.role == GroupMemberRole.owner ? null : _rose900,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      member.initials,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: member.role == GroupMemberRole.owner
                                            ? Colors.white
                                            : _rose200,
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
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: _rose50,
                                        ),
                                      ),
                                      Text(
                                        member.roleDisplayName,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: member.role == GroupMemberRole.owner
                                              ? _orange400
                                              : _rose300.withValues(alpha: 0.6),
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
                                      gradient: const LinearGradient(
                                        colors: [_rose500, _orange400],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Owner',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
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
                                      color: _rose500.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Co-Owner',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _rose300,
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
                                      color: _rose400.withValues(alpha: 0.5),
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
                        foregroundColor: _red500,
                        side: BorderSide(color: _red500.withValues(alpha: 0.5)),
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
    // Only owners and co-owners can manage members
    if (!provider.canManageMembers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Only owners and co-owners can manage members'),
          backgroundColor: _rose500,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: _rose950,
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _rose950,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Leave Group?',
          style: TextStyle(color: _rose50),
        ),
        content: Text(
          'Are you sure you want to leave "${group.name}"? You will need to be invited again to rejoin.',
          style: TextStyle(color: _rose200),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: _rose300)),
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
                      backgroundColor: _rose500,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.actionError ?? 'Failed to leave group'),
                      backgroundColor: _red500,
                    ),
                  );
                }
              }
            },
            child: Text('Leave', style: TextStyle(color: _red500)),
          ),
        ],
      ),
    );
  }
}
