import 'package:flutter/material.dart';

/// Bottom sheet displaying user's groups with navigation
/// Shows list of groups with emoji icons and member counts
class GroupsBottomSheet extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback? onCreateGroup;

  const GroupsBottomSheet({
    super.key,
    required this.onClose,
    this.onCreateGroup,
  });

  @override
  Widget build(BuildContext context) {
    // Placeholder groups - will be replaced with real data from GroupProvider
    final groups = [
      _GroupData(id: '1', name: 'Friendsgiving Crew', emoji: '🦃', members: 8, color: const Color(0xFFF97316)),
      _GroupData(id: '2', name: 'Game Night', emoji: '🎮', members: 5, color: const Color(0xFF8B5CF6)),
      _GroupData(id: '3', name: 'Book Club', emoji: '📚', members: 6, color: const Color(0xFF3B82F6)),
      _GroupData(id: '4', name: 'Hiking Squad', emoji: '🥾', members: 4, color: const Color(0xFF22C55E)),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Groups',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: Icon(Icons.close, color: Colors.grey[500]),
                ),
              ],
            ),
          ),

          // Groups list
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                children: [
                  ...groups.map((group) => _buildGroupTile(context, group)),
                  const SizedBox(height: 12),
                  _buildCreateGroupButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTile(BuildContext context, _GroupData group) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigate to group detail
            onClose();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Emoji container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: group.color,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: group.color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      group.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Group info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${group.members} members',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateGroupButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onCreateGroup,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey[300]!,
              width: 2,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_rounded,
                size: 20,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 8),
              Text(
                'Create New Group',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupData {
  final String id;
  final String name;
  final String emoji;
  final int members;
  final Color color;

  const _GroupData({
    required this.id,
    required this.name,
    required this.emoji,
    required this.members,
    required this.color,
  });
}
