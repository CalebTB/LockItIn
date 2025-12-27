import 'package:flutter/material.dart';

/// Bottom sheet displaying user's groups with navigation
/// Shows list of groups with emoji icons and member counts
/// Styled with Sunset Coral Dark theme
class GroupsBottomSheet extends StatelessWidget {
  // Sunset Coral Dark Theme Colors
  static const Color _rose950 = Color(0xFF4C0519);
  static const Color _rose900 = Color(0xFF881337);
  static const Color _rose500 = Color(0xFFF43F5E);
  static const Color _rose400 = Color(0xFFFB7185);
  static const Color _rose300 = Color(0xFFFDA4AF);
  static const Color _rose200 = Color(0xFFFECDD3);
  static const Color _rose50 = Color(0xFFFFF1F2);
  static const Color _orange600 = Color(0xFFEA580C);
  static const Color _orange200 = Color(0xFFFED7AA);
  static const Color _amber500 = Color(0xFFF59E0B);
  static const Color _violet500 = Color(0xFF8B5CF6);
  static const Color _purple600 = Color(0xFF9333EA);
  static const Color _pink600 = Color(0xFFDB2777);
  static const Color _slate950 = Color(0xFF020617);

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
      _GroupData(id: '1', name: 'Friendsgiving Crew', emoji: '🦃', members: 8, gradientColors: [_amber500, _orange600]),
      _GroupData(id: '2', name: 'Game Night', emoji: '🎮', members: 5, gradientColors: [_violet500, _purple600]),
      _GroupData(id: '3', name: 'Book Club', emoji: '📚', members: 6, gradientColors: [_rose500, _pink600]),
      _GroupData(id: '4', name: 'Hiking Squad', emoji: '🥾', members: 4, gradientColors: [_amber500, _orange600]),
    ];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_rose950, _rose950, _slate950],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(
          top: BorderSide(color: Color(0x33F43F5E), width: 1), // rose-500/20
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [_rose200, _orange200],
                  ).createShader(bounds),
                  child: const Text(
                    'Groups',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: _rose300),
                ),
              ],
            ),
          ),

          // Groups list
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
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
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            _rose900.withValues(alpha: 0.5),
            _rose900.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _rose500.withValues(alpha: 0.2),
          width: 1,
        ),
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Emoji container with gradient
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: group.gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: group.gradientColors[1].withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      group.emoji,
                      style: const TextStyle(fontSize: 26),
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
                          color: _rose50,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${group.members} members',
                        style: TextStyle(
                          fontSize: 14,
                          color: _rose300.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.chevron_right,
                  color: _rose400.withValues(alpha: 0.4),
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
              color: _rose500.withValues(alpha: 0.3),
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
                color: _rose300.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Text(
                'Create New Group',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _rose300.withValues(alpha: 0.6),
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
  final List<Color> gradientColors;

  const _GroupData({
    required this.id,
    required this.name,
    required this.emoji,
    required this.members,
    required this.gradientColors,
  });
}
