import 'package:flutter/material.dart';
import '../../data/models/friendship_model.dart';

/// List tile widget for displaying a pending friend request
class FriendRequestTile extends StatelessWidget {
  final FriendRequest request;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const FriendRequestTile({
    super.key,
    required this.request,
    this.onAccept,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar
            _RequestAvatar(request: request),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimeAgo(request.requestedAt),
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Decline button
                IconButton(
                  onPressed: onDecline,
                  icon: Icon(
                    Icons.close_rounded,
                    color: colorScheme.error,
                  ),
                  tooltip: 'Decline',
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(width: 8),
                // Accept button
                IconButton(
                  onPressed: onAccept,
                  icon: Icon(
                    Icons.check_rounded,
                    color: colorScheme.primary,
                  ),
                  tooltip: 'Accept',
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.primaryContainer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 30) {
      final months = (diff.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
    if (diff.inDays > 0) {
      return '${diff.inDays} ${diff.inDays == 1 ? 'day' : 'days'} ago';
    }
    if (diff.inHours > 0) {
      return '${diff.inHours} ${diff.inHours == 1 ? 'hour' : 'hours'} ago';
    }
    if (diff.inMinutes > 0) {
      return '${diff.inMinutes} ${diff.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    }
    return 'Just now';
  }
}

/// Avatar widget for request display
class _RequestAvatar extends StatelessWidget {
  final FriendRequest request;

  const _RequestAvatar({
    required this.request,
  });

  static const double radius = 28;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CircleAvatar(
      radius: radius,
      backgroundColor: _getColorFromName(request.displayName, colorScheme),
      child: request.avatarUrl != null
          ? ClipOval(
              child: Image.network(
                request.avatarUrl!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, __, _) => _buildInitials(),
              ),
            )
          : _buildInitials(),
    );
  }

  Widget _buildInitials() {
    return Text(
      request.initials,
      style: TextStyle(
        fontSize: radius * 0.65,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Color _getColorFromName(String name, ColorScheme colorScheme) {
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    final hue = (hash % 360).abs().toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.5).toColor();
  }
}
