import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/event_model.dart';
import '../../data/models/group_model.dart';
import '../../utils/privacy_colors.dart';

/// Privacy settings sheet for configuring per-group event privacy defaults
///
/// Allows users to set default privacy level for events created in this group:
/// - Private: Events hidden from this group
/// - Shared as Busy: Groups see "busy" blocks only
/// - Shared with Details: Groups see full event information (Recommended)
///
/// Settings are stored per-group in SharedPreferences
class PrivacySettingsSheet extends StatefulWidget {
  final GroupModel group;

  const PrivacySettingsSheet({
    super.key,
    required this.group,
  });

  /// Show this sheet as a modal bottom sheet
  static Future<void> show({
    required BuildContext context,
    required GroupModel group,
  }) {
    HapticFeedback.selectionClick();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PrivacySettingsSheet(group: group),
    );
  }

  @override
  State<PrivacySettingsSheet> createState() => _PrivacySettingsSheetState();
}

class _PrivacySettingsSheetState extends State<PrivacySettingsSheet> {
  EventVisibility _selectedDefault = EventVisibility.sharedWithName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacyDefault();
  }

  /// Load saved privacy default for this group
  Future<void> _loadPrivacyDefault() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'privacy_default_${widget.group.id}';
    final savedValue = prefs.getString(key);

    setState(() {
      if (savedValue != null) {
        _selectedDefault = EventVisibility.values.firstWhere(
          (e) => e.toString() == savedValue,
          orElse: () => EventVisibility.sharedWithName,
        );
      }
      _isLoading = false;
    });
  }

  /// Save privacy default for this group
  Future<void> _savePrivacyDefault(EventVisibility visibility) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'privacy_default_${widget.group.id}';
    await prefs.setString(key, visibility.toString());

    setState(() => _selectedDefault = visibility);

    if (mounted) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Default privacy updated to "${PrivacyColors.getPrivacyLabel(visibility)}"',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
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
          // Header
          _buildHeader(colorScheme, appColors),
          // Divider
          Divider(
            height: 1,
            color: colorScheme.outline.withValues(alpha: 0.15),
          ),
          // Privacy options
          Flexible(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Explanation
                        Text(
                          'Choose the default privacy level for events you create in this group. You can always change it for individual events.',
                          style: TextStyle(
                            fontSize: 14,
                            color: appColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Privacy options
                        _buildPrivacyOption(
                          colorScheme: colorScheme,
                          appColors: appColors,
                          value: EventVisibility.sharedWithName,
                          icon: Icons.people_outline,
                          title: 'Shared with Details',
                          description: 'Group members see your event names and times',
                          isRecommended: true,
                        ),
                        const SizedBox(height: 12),

                        _buildPrivacyOption(
                          colorScheme: colorScheme,
                          appColors: appColors,
                          value: EventVisibility.busyOnly,
                          icon: Icons.visibility_outlined,
                          title: 'Shared as Busy',
                          description: 'Group members see you\'re busy, but not why',
                        ),
                        const SizedBox(height: 12),

                        _buildPrivacyOption(
                          colorScheme: colorScheme,
                          appColors: appColors,
                          value: EventVisibility.private,
                          icon: Icons.lock,
                          title: 'Private',
                          description: 'Your events are hidden from this group',
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
          // Privacy icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.memberViolet.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.visibility_rounded,
              size: 24,
              color: AppColors.memberViolet,
            ),
          ),
          const SizedBox(width: 14),
          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.group.name,
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

  Widget _buildPrivacyOption({
    required ColorScheme colorScheme,
    required AppColorsExtension appColors,
    required EventVisibility value,
    required IconData icon,
    required String title,
    required String description,
    bool isRecommended = false,
  }) {
    final isSelected = _selectedDefault == value;
    final privacyColor = PrivacyColors.getPrivacyColor(value);

    return Semantics(
      label: '$title. $description.${isRecommended ? ' Recommended.' : ''}',
      hint: isSelected ? 'Currently selected' : 'Double tap to select as default',
      button: true,
      selected: isSelected,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _savePrivacyDefault(value),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.08)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Radio indicator
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? colorScheme.primary : colorScheme.outline,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.primary,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Icon with privacy color
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: privacyColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: privacyColor,
                ),
              ),
              const SizedBox(width: 12),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (isRecommended) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Recommended',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
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
        ),
      ),
    );
  }
}
