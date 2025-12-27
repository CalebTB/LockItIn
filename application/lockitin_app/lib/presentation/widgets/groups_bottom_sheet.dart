import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/group_model.dart';
import '../providers/group_provider.dart';

/// Bottom sheet displaying user's groups with navigation
/// Shows list of groups with emoji icons and member counts
/// Includes invites tab for pending group invitations
/// Styled with Sunset Coral Dark theme
class GroupsBottomSheet extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback? onCreateGroup;

  const GroupsBottomSheet({
    super.key,
    required this.onClose,
    this.onCreateGroup,
  });

  @override
  State<GroupsBottomSheet> createState() => _GroupsBottomSheetState();
}

class _GroupsBottomSheetState extends State<GroupsBottomSheet> {
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
  static const Color _emerald500 = Color(0xFF10B981);
  static const Color _cyan500 = Color(0xFF06B6D4);
  static const Color _slate950 = Color(0xFF020617);

  // Tab selection: 0 = Groups, 1 = Invites
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    // Load groups when bottom sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProvider>().initialize();
    });
  }

  /// Get gradient colors based on group index for visual variety
  List<Color> _getGradientColors(int index) {
    final gradients = [
      [_amber500, _orange600],
      [_violet500, _purple600],
      [_rose500, _pink600],
      [_emerald500, _cyan500],
      [_rose400, _rose500],
    ];
    return gradients[index % gradients.length];
  }

  @override
  Widget build(BuildContext context) {
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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
        minHeight: MediaQuery.of(context).size.height * 0.6,
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

          // Header with close button
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
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, color: _rose300),
                ),
              ],
            ),
          ),

          // Tab selector
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Consumer<GroupProvider>(
              builder: (context, provider, _) => Row(
                children: [
                  _buildTabButton(
                    label: 'My Groups',
                    isSelected: _selectedTab == 0,
                    onTap: () => setState(() => _selectedTab = 0),
                    badge: null,
                  ),
                  const SizedBox(width: 8),
                  _buildTabButton(
                    label: 'Invites',
                    isSelected: _selectedTab == 1,
                    onTap: () => setState(() => _selectedTab = 1),
                    badge: provider.pendingInviteCount > 0
                        ? provider.pendingInviteCount
                        : null,
                  ),
                ],
              ),
            ),
          ),

          // Content based on selected tab
          Expanded(
            child: _selectedTab == 0 ? _buildGroupsTab() : _buildInvitesTab(),
          ),

          // Create group button fixed at bottom (only on Groups tab)
          if (_selectedTab == 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: _buildCreateGroupButton(),
            ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    int? badge,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? _rose500.withValues(alpha: 0.2)
                : _rose900.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? _rose400 : _rose500.withValues(alpha: 0.2),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? _rose50 : _rose300.withValues(alpha: 0.7),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _rose500,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge.toString(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupsTab() {
    return Consumer<GroupProvider>(
      builder: (context, groupProvider, child) {
        if (groupProvider.isLoadingGroups) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: CircularProgressIndicator(
                color: _rose400,
              ),
            ),
          );
        }

        if (groupProvider.groupsError != null) {
          return _buildErrorState(groupProvider.groupsError!, isGroups: true);
        }

        if (groupProvider.groups.isEmpty) {
          return _buildEmptyState();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            children: [
              ...groupProvider.groups.asMap().entries.map(
                  (entry) => _buildGroupTile(context, entry.value, entry.key)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInvitesTab() {
    return Consumer<GroupProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingInvites) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: CircularProgressIndicator(
                color: _rose400,
              ),
            ),
          );
        }

        if (provider.invitesError != null) {
          return _buildErrorState(provider.invitesError!, isGroups: false);
        }

        if (provider.pendingInvites.isEmpty) {
          return _buildEmptyInvitesState();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Column(
            children: provider.pendingInvites
                .asMap()
                .entries
                .map((entry) => _buildInviteTile(context, entry.value, entry.key))
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _rose900.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.group_outlined,
                size: 48,
                color: _rose300.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Groups Yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _rose200,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create a group to start planning events together',
              style: TextStyle(
                fontSize: 14,
                color: _rose300.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyInvitesState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _rose900.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mail_outline_rounded,
              size: 48,
              color: _rose300.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Pending Invites',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _rose200,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'When someone invites you to a group, it will appear here',
            style: TextStyle(
              fontSize: 14,
              color: _rose300.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, {required bool isGroups}) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: _rose400,
          ),
          const SizedBox(height: 16),
          Text(
            isGroups ? 'Failed to load groups' : 'Failed to load invites',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _rose200,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              if (isGroups) {
                context.read<GroupProvider>().refresh();
              } else {
                context.read<GroupProvider>().loadPendingInvites();
              }
            },
            child: Text(
              'Try Again',
              style: TextStyle(color: _rose400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTile(BuildContext context, GroupModel group, int index) {
    final gradientColors = _getGradientColors(index);

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
            widget.onClose();
            // TODO: Navigate to group detail screen
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
                      colors: gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[1].withValues(alpha: 0.3),
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
                        '${group.memberCount} member${group.memberCount == 1 ? '' : 's'}',
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

  Widget _buildInviteTile(BuildContext context, GroupInvite invite, int index) {
    final gradientColors = _getGradientColors(index);

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Emoji container with gradient
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[1].withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      invite.groupEmoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Invite info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invite.groupName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _rose50,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Invited by ${invite.inviterName}',
                        style: TextStyle(
                          fontSize: 14,
                          color: _rose300.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleDeclineInvite(context, invite),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _rose300,
                      side: BorderSide(color: _rose500.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAcceptInvite(context, invite),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _emerald500,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAcceptInvite(
      BuildContext context, GroupInvite invite) async {
    final provider = context.read<GroupProvider>();
    final success = await provider.acceptInvite(invite.id);

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Joined "${invite.groupName}"'),
            backgroundColor: _emerald500,
          ),
        );
        // Switch to groups tab to show new group
        setState(() => _selectedTab = 0);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.actionError ?? 'Failed to accept invite'),
            backgroundColor: _rose500,
          ),
        );
      }
    }
  }

  Future<void> _handleDeclineInvite(
      BuildContext context, GroupInvite invite) async {
    final provider = context.read<GroupProvider>();
    final success = await provider.declineInvite(invite.id);

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Declined invite to "${invite.groupName}"'),
            backgroundColor: _rose400,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.actionError ?? 'Failed to decline invite'),
            backgroundColor: _rose500,
          ),
        );
      }
    }
  }

  Widget _buildCreateGroupButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          widget.onClose();
          _showCreateGroupDialog(context);
        },
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

  void _showCreateGroupDialog(BuildContext context) {
    final nameController = TextEditingController();
    String selectedEmoji = '👥';

    final emojis = [
      '👥',
      '🎉',
      '🎮',
      '📚',
      '🏃',
      '🍕',
      '🎵',
      '⚽',
      '🎬',
      '✈️',
      '🎂',
      '🦃'
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _rose950,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: _rose500.withValues(alpha: 0.2)),
          ),
          title: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [_rose200, _orange200],
            ).createShader(bounds),
            child: const Text(
              'Create Group',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji selector
              Text(
                'Choose an emoji',
                style: TextStyle(
                  fontSize: 12,
                  color: _rose300.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: emojis
                    .map((emoji) => GestureDetector(
                          onTap: () =>
                              setDialogState(() => selectedEmoji = emoji),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: selectedEmoji == emoji
                                  ? _rose500.withValues(alpha: 0.3)
                                  : _rose900.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedEmoji == emoji
                                    ? _rose400
                                    : _rose500.withValues(alpha: 0.2),
                                width: selectedEmoji == emoji ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child:
                                  Text(emoji, style: const TextStyle(fontSize: 24)),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              // Name field
              Text(
                'Group name',
                style: TextStyle(
                  fontSize: 12,
                  color: _rose300.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                style: const TextStyle(color: _rose50),
                decoration: InputDecoration(
                  hintText: 'e.g., Weekend Warriors',
                  hintStyle: TextStyle(color: _rose300.withValues(alpha: 0.4)),
                  filled: true,
                  fillColor: _rose900.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: _rose500.withValues(alpha: 0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: _rose500.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _rose400, width: 1),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: _rose300),
              ),
            ),
            Consumer<GroupProvider>(
              builder: (context, provider, _) => ElevatedButton(
                onPressed: provider.isCreatingGroup
                    ? null
                    : () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Please enter a group name'),
                              backgroundColor: _rose500,
                            ),
                          );
                          return;
                        }

                        final group = await provider.createGroup(
                          name: name,
                          emoji: selectedEmoji,
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                          if (group != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Created "$name"'),
                                backgroundColor: _emerald500,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    provider.actionError ?? 'Failed to create group'),
                                backgroundColor: _rose500,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _rose500,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: provider.isCreatingGroup
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
