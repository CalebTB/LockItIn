import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/group_model.dart';
import '../providers/group_provider.dart';

/// Section widget showing group members with stacked avatars
/// Uses Minimal theme color system with distinct member colors
///
/// Displays:
/// - Stacked avatar circles with distinct colors per member
/// - Role indicator (crown) for owner/co-owner
/// - Total member count with "View all" action
/// - Invite button with haptic feedback
class GroupMembersSection extends StatelessWidget {
  final GroupModel group;
  final VoidCallback onInvite;
  final VoidCallback? onViewAllMembers;

  const GroupMembersSection({
    super.key,
    required this.group,
    required this.onInvite,
    this.onViewAllMembers,
  });

  /// Get distinct color for member based on their index
  /// Uses the member color palette from AppColors
  static Color getMemberColor(int index) {
    const colors = [
      AppColors.memberPink,
      AppColors.memberAmber,
      AppColors.memberViolet,
      AppColors.memberCyan,
      AppColors.memberEmerald,
      AppColors.memberPurple,
      AppColors.memberTeal,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Consumer<GroupProvider>(
      builder: (context, provider, _) {
        final members = provider.selectedGroupMembers;

        return GestureDetector(
          onTap: onViewAllMembers != null
              ? () {
                  HapticFeedback.selectionClick();
                  onViewAllMembers!();
                }
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer.withValues(alpha: 0.5),
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.15),
                ),
                bottom: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.15),
                ),
              ),
            ),
            child: Row(
              children: [
                // Member avatars (stacked)
                if (provider.isLoadingMembers)
                  _buildLoadingState(colorScheme)
                else
                  _buildAvatarStack(members, colorScheme),

                // Overflow count
                if (members.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '+${members.length - 5}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: appColors.textSecondary,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(width: 10),

                // Member count and view action
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${group.memberCount} ${group.memberCount == 1 ? 'member' : 'members'}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (onViewAllMembers != null)
                        Text(
                          'Tap to view all',
                          style: TextStyle(
                            fontSize: 11,
                            color: appColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),

                // Invite button (compact pill)
                _buildInviteButton(colorScheme, appColors),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarStack(
    List<GroupMemberProfile> members,
    ColorScheme colorScheme,
  ) {
    final displayMembers = members.take(5).toList();
    final avatarSize = 32.0;
    final overlapOffset = 22.0;

    return SizedBox(
      width: (displayMembers.length * overlapOffset) +
          (avatarSize - overlapOffset),
      height: avatarSize,
      child: Stack(
        children: displayMembers.asMap().entries.map((entry) {
          final index = entry.key;
          final member = entry.value;
          final isOwner = member.role == GroupMemberRole.owner ||
              member.role == GroupMemberRole.coOwner;
          final memberColor = getMemberColor(index);

          return Positioned(
            left: index * overlapOffset,
            child: _buildAvatar(
              member: member,
              color: memberColor,
              size: avatarSize,
              showCrown: isOwner,
              colorScheme: colorScheme,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAvatar({
    required GroupMemberProfile member,
    required Color color,
    required double size,
    required bool showCrown,
    required ColorScheme colorScheme,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.surface,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              member.initials,
              style: TextStyle(
                fontSize: size * 0.35,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        // Crown indicator for owner/co-owner
        if (showCrown)
          Positioned(
            top: -4,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.warning,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.surface,
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.star_rounded,
                size: 8,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInviteButton(
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onInvite();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_add_rounded,
              size: 16,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'Invite',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
