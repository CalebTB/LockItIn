import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/group_model.dart';
import '../../../providers/group_provider.dart';
import '../../../theme/sunset_coral_theme.dart';

/// Member options bottom sheet for managing individual group members
class MemberOptionsSheet extends StatelessWidget {
  final GroupMemberProfile member;
  final String groupId;
  final bool isOwner;
  final bool isCoOwner;

  const MemberOptionsSheet({
    super.key,
    required this.member,
    required this.groupId,
    required this.isOwner,
    required this.isCoOwner,
  });

  /// Whether current user can manage (is owner or co-owner)
  bool get canManage => isOwner || isCoOwner;

  static const Color _rose950 = SunsetCoralTheme.rose950;
  static const Color _rose500 = SunsetCoralTheme.rose500;
  static const Color _rose400 = SunsetCoralTheme.rose400;
  static const Color _rose300 = SunsetCoralTheme.rose300;
  static const Color _rose200 = SunsetCoralTheme.rose200;
  static const Color _rose50 = SunsetCoralTheme.rose50;
  static const Color _orange400 = SunsetCoralTheme.orange400;
  static const Color _red500 = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _rose500.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Member info
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _rose500.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    member.initials,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _rose200,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.displayName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _rose50,
                      ),
                    ),
                    Text(
                      member.roleDisplayName,
                      style: TextStyle(
                        fontSize: 14,
                        color: _rose300,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Options for owners and co-owners
          if (canManage) ...[
            // Cannot manage the owner
            if (member.role != GroupMemberRole.owner) ...[
              // Promote/demote co-owner options
              if (member.role == GroupMemberRole.coOwner)
                _buildOptionTile(
                  context,
                  icon: Icons.person_outline,
                  label: 'Remove Co-Owner',
                  color: _orange400,
                  onTap: () => _demoteFromCoOwner(context),
                )
              else
                _buildOptionTile(
                  context,
                  icon: Icons.stars,
                  label: 'Make Co-Owner',
                  color: _orange400,
                  onTap: () => _promoteToCoOwner(context),
                ),
              const SizedBox(height: 8),

              // Transfer ownership (only owner can do this, only to non-owners)
              if (isOwner) ...[
                _buildOptionTile(
                  context,
                  icon: Icons.swap_horiz,
                  label: 'Transfer Ownership',
                  color: _rose400,
                  onTap: () => _confirmTransferOwnership(context),
                ),
                const SizedBox(height: 8),
              ],

              // Remove from group
              // Co-owners can only remove regular members
              if (isOwner || member.role == GroupMemberRole.member)
                _buildOptionTile(
                  context,
                  icon: Icons.person_remove,
                  label: 'Remove from Group',
                  color: _red500,
                  onTap: () => _confirmRemoveMember(context),
                ),
            ],
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _promoteToCoOwner(BuildContext context) async {
    final provider = context.read<GroupProvider>();

    Navigator.pop(context); // Close options sheet

    final success = await provider.promoteToCoOwner(
      groupId: groupId,
      userId: member.userId,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '${member.displayName} is now a co-owner'
                : provider.actionError ?? 'Failed to promote member',
          ),
          backgroundColor: success ? _rose500 : _red500,
        ),
      );
    }
  }

  void _demoteFromCoOwner(BuildContext context) async {
    final provider = context.read<GroupProvider>();

    Navigator.pop(context); // Close options sheet

    final success = await provider.demoteFromCoOwner(
      groupId: groupId,
      userId: member.userId,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '${member.displayName} is now a member'
                : provider.actionError ?? 'Failed to demote co-owner',
          ),
          backgroundColor: success ? _rose500 : _red500,
        ),
      );
    }
  }

  void _confirmTransferOwnership(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _rose950,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Transfer Ownership?',
          style: TextStyle(color: _rose50),
        ),
        content: Text(
          'Are you sure you want to make ${member.displayName} the owner? You will become a member.',
          style: TextStyle(color: _rose200),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: _rose300)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context); // Close options sheet

              final provider = context.read<GroupProvider>();
              final success = await provider.transferOwnership(
                groupId: groupId,
                newOwnerId: member.userId,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? '${member.displayName} is now the owner'
                          : provider.actionError ?? 'Failed to transfer ownership',
                    ),
                    backgroundColor: success ? _rose500 : _red500,
                  ),
                );
              }
            },
            child: Text('Transfer', style: TextStyle(color: _orange400)),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveMember(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _rose950,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Remove Member?',
          style: TextStyle(color: _rose50),
        ),
        content: Text(
          'Are you sure you want to remove ${member.displayName} from the group?',
          style: TextStyle(color: _rose200),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: _rose300)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context); // Close options sheet

              final provider = context.read<GroupProvider>();
              final success = await provider.removeMember(
                groupId: groupId,
                userId: member.userId,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? '${member.displayName} has been removed'
                          : provider.actionError ?? 'Failed to remove member',
                    ),
                    backgroundColor: success ? _rose500 : _red500,
                  ),
                );
              }
            },
            child: Text('Remove', style: TextStyle(color: _red500)),
          ),
        ],
      ),
    );
  }
}
