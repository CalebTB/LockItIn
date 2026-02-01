import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Badge widget to display group name and emoji for events
///
/// Shows a compact badge with group emoji and name.
/// Displays grayed "[Deleted]" when group has been deleted (null groupName).
class GroupBadge extends StatelessWidget {
  final String? groupId;
  final String? groupName;
  final String? groupEmoji;

  const GroupBadge({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.groupEmoji,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    // Don't show badge if no group is associated
    if (groupId == null) {
      return const SizedBox.shrink();
    }

    final isDeleted = groupName == null;
    final displayEmoji = isDeleted ? '' : (groupEmoji ?? '👥');
    final displayName = isDeleted ? '[Deleted]' : groupName!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDeleted
            ? appColors.cardBackground
            : colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDeleted ? appColors.cardBorder : colorScheme.outline,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (displayEmoji.isNotEmpty) ...[
            Text(
              displayEmoji,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDeleted
                    ? appColors.textMuted
                    : colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
