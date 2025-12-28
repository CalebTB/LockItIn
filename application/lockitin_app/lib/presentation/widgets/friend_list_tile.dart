import 'package:flutter/material.dart';
import '../../data/models/friendship_model.dart';

/// List tile widget for displaying a friend in the friends list
class FriendListTile extends StatelessWidget {
  final FriendProfile friend;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const FriendListTile({
    super.key,
    required this.friend,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: _FriendAvatar(friend: friend),
        title: Text(
          friend.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
          onSelected: (value) {
            if (value == 'remove' && onRemove != null) {
              onRemove!();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.person_rounded, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  const Text('View Profile'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'calendar',
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, color: colorScheme.secondary),
                  const SizedBox(width: 12),
                  const Text('View Calendar'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.person_remove_rounded, color: colorScheme.error),
                  const SizedBox(width: 12),
                  Text(
                    'Remove Friend',
                    style: TextStyle(color: colorScheme.error),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatar widget for friend display
class _FriendAvatar extends StatelessWidget {
  final FriendProfile friend;

  const _FriendAvatar({
    required this.friend,
  });

  static const double radius = 24;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CircleAvatar(
      radius: radius,
      backgroundColor: _getColorFromName(friend.displayName, colorScheme),
      child: friend.avatarUrl != null
          ? ClipOval(
              child: Image.network(
                friend.avatarUrl!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, __, _) => _buildInitials(colorScheme),
              ),
            )
          : _buildInitials(colorScheme),
    );
  }

  Widget _buildInitials(ColorScheme colorScheme) {
    return Text(
      friend.initials,
      style: TextStyle(
        fontSize: radius * 0.7,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Color _getColorFromName(String name, ColorScheme colorScheme) {
    // Generate consistent color from name
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    final hue = (hash % 360).abs().toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.5).toColor();
  }
}
