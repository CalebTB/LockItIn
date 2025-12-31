import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/group_model.dart';
import '../../providers/group_provider.dart';
import '../../widgets/empty_state.dart';
import '../group_detail/group_detail_screen.dart';

/// Groups tab showing full screen list of user's groups
/// Features:
/// - Pull to refresh
/// - Group avatars with emoji and member counts
/// - FAB to create new group
/// - Tap group to navigate to GroupDetailScreen
class GroupsTab extends StatefulWidget {
  const GroupsTab({super.key});

  @override
  State<GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<GroupsTab> {
  @override
  void initState() {
    super.initState();
    // Initialize provider if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProvider>().initialize();
    });
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    String selectedEmoji = '👥';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final colorScheme = Theme.of(context).colorScheme;

            return AlertDialog(
              title: const Text('Create Group'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Emoji picker
                  Text('Emoji:', style: TextStyle(color: colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    children: ['👥', '🏀', '🎮', '🍕', '🎉', '💼'].map((emoji) {
                      final isSelected = selectedEmoji == emoji;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedEmoji = emoji),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primaryContainer
                                : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Name field
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Group Name',
                      hintText: 'e.g., Weekend Warriors',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;

                    Navigator.pop(context);
                    final provider = context.read<GroupProvider>();
                    final group = await provider.createGroup(
                      name: nameController.text.trim(),
                      emoji: selectedEmoji,
                    );

                    if (group != null && context.mounted) {
                      // Navigate to the new group
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => GroupDetailScreen(group: group),
                        ),
                      );
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final provider = context.watch<GroupProvider>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, colorScheme, appColors),

            // Content
            Expanded(
              child: provider.isLoadingGroups && provider.groups.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : provider.groups.isEmpty
                      ? _buildEmptyState(context, colorScheme, appColors)
                      : _buildGroupsList(context, colorScheme, appColors, provider),
            ),
          ],
        ),
      ),
      // Only show FAB when groups exist (empty state has its own create button)
      floatingActionButton: provider.groups.isNotEmpty
          ? Semantics(
              button: true,
              label: 'Create new group',
              child: FloatingActionButton(
                heroTag: 'groups_fab',
                onPressed: _showCreateGroupDialog,
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                tooltip: 'Create new group',
                child: const Icon(Icons.add_rounded),
              ),
            )
          : null,
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    final provider = context.watch<GroupProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.group_rounded,
            color: colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Groups',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '${provider.groupCount} group${provider.groupCount == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 13,
                  color: appColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    return EmptyState(
      type: EmptyStateType.noGroups,
      onCreateGroup: _showCreateGroupDialog,
    );
  }

  Widget _buildGroupsList(
    BuildContext context,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
    GroupProvider provider,
  ) {
    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: provider.groups.length,
        itemBuilder: (context, index) {
          final group = provider.groups[index];
          return _buildGroupTile(context, colorScheme, appColors, group);
        },
      ),
    );
  }

  Widget _buildGroupTile(
    BuildContext context,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
    GroupModel group,
  ) {
    return ListTile(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => GroupDetailScreen(group: group),
          ),
        );
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          group.emoji,
          style: const TextStyle(fontSize: 24),
        ),
      ),
      title: Text(
        group.name,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        '${group.memberCount} member${group.memberCount == 1 ? '' : 's'}',
        style: TextStyle(
          fontSize: 13,
          color: appColors.textMuted,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: appColors.textMuted,
      ),
    );
  }
}
