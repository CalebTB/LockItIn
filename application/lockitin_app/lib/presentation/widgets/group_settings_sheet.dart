import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/group_model.dart';

/// Bottom sheet for group settings
/// Replaces the popup menu with a more accessible bottom sheet
///
/// Displays:
/// - Group header with emoji and name
/// - Settings options (rename, notifications, privacy)
/// - Share group option
/// - Danger zone (leave group)
class GroupSettingsSheet extends StatelessWidget {
  final GroupModel group;
  final VoidCallback? onRename;
  final VoidCallback? onNotifications;
  final VoidCallback? onPrivacy;
  final VoidCallback? onShare;
  final VoidCallback? onLeave;

  const GroupSettingsSheet({
    super.key,
    required this.group,
    this.onRename,
    this.onNotifications,
    this.onPrivacy,
    this.onShare,
    this.onLeave,
  });

  /// Show this sheet as a modal bottom sheet
  static Future<void> show({
    required BuildContext context,
    required GroupModel group,
    VoidCallback? onRename,
    VoidCallback? onNotifications,
    VoidCallback? onPrivacy,
    VoidCallback? onShare,
    VoidCallback? onLeave,
  }) {
    HapticFeedback.selectionClick();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GroupSettingsSheet(
        group: group,
        onRename: onRename,
        onNotifications: onNotifications,
        onPrivacy: onPrivacy,
        onShare: onShare,
        onLeave: onLeave,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          _buildHandle(colorScheme),
          // Group header
          _buildHeader(colorScheme, appColors),
          // Divider
          Divider(
            height: 1,
            color: colorScheme.outline.withValues(alpha: 0.15),
          ),
          // Settings options
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // General settings section
                  _buildSectionLabel('SETTINGS', appColors),
                  _buildSettingsTile(
                    icon: Icons.edit_rounded,
                    iconColor: colorScheme.primary,
                    title: 'Rename group',
                    subtitle: 'Change the group name and emoji',
                    colorScheme: colorScheme,
                    appColors: appColors,
                    onTap: () {
                      Navigator.pop(context);
                      onRename?.call();
                    },
                  ),
                  _buildSettingsTile(
                    icon: Icons.notifications_rounded,
                    iconColor: AppColors.warning,
                    title: 'Notifications',
                    subtitle: 'Manage how you receive updates',
                    colorScheme: colorScheme,
                    appColors: appColors,
                    onTap: () {
                      Navigator.pop(context);
                      onNotifications?.call();
                    },
                  ),
                  _buildSettingsTile(
                    icon: Icons.visibility_rounded,
                    iconColor: AppColors.memberViolet,
                    title: 'Privacy settings',
                    subtitle: 'Control what others see about you',
                    colorScheme: colorScheme,
                    appColors: appColors,
                    onTap: () {
                      Navigator.pop(context);
                      onPrivacy?.call();
                    },
                  ),

                  const SizedBox(height: 8),
                  // Share section
                  _buildSectionLabel('SHARE', appColors),
                  _buildSettingsTile(
                    icon: Icons.share_rounded,
                    iconColor: AppColors.memberCyan,
                    title: 'Share group',
                    subtitle: 'Invite friends with a link',
                    colorScheme: colorScheme,
                    appColors: appColors,
                    onTap: () {
                      Navigator.pop(context);
                      onShare?.call();
                    },
                  ),

                  const SizedBox(height: 8),
                  // Danger zone
                  _buildSectionLabel('DANGER ZONE', appColors, isDestructive: true),
                  _buildSettingsTile(
                    icon: Icons.exit_to_app_rounded,
                    iconColor: colorScheme.error,
                    title: 'Leave group',
                    subtitle: 'You will no longer receive updates',
                    colorScheme: colorScheme,
                    appColors: appColors,
                    isDestructive: true,
                    onTap: () {
                      Navigator.pop(context);
                      onLeave?.call();
                    },
                  ),
                ],
              ),
            ),
          ),
          // Safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildHandle(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: colorScheme.outline.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, AppColorsExtension appColors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(
        children: [
          // Group emoji
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                group.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Group Settings',
                  style: TextStyle(
                    fontSize: 13,
                    color: appColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(
    String label,
    AppColorsExtension appColors, {
    bool isDestructive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: isDestructive ? AppColors.error : appColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required ColorScheme colorScheme,
    required AppColorsExtension appColors,
    required VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap?.call();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 14),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDestructive
                              ? colorScheme.error
                              : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: appColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Chevron
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: appColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
