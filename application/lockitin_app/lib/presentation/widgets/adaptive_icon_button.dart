import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';

/// Platform-adaptive icon button with enforced minimum touch target size
///
/// Automatically adapts to platform conventions and enforces accessibility standards:
/// - Minimum 48×48 dp touch target (satisfies iOS 44pt and Android 48dp requirements)
/// - WCAG 2.1 Level AA compliant (Criterion 2.5.5: Target Size)
/// - Semantic labels for screen readers (VoiceOver/TalkBack)
///
/// Usage:
/// ```dart
/// AdaptiveIconButton(
///   icon: Icons.settings,
///   onPressed: () => print('Settings'),
///   tooltip: 'Open settings',
/// )
/// ```
class AdaptiveIconButton extends StatelessWidget {
  /// The icon to display
  final IconData icon;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Accessibility label and tooltip text
  final String? tooltip;

  /// Size of the icon (visual size, not touch target)
  /// Defaults to 24.0
  final double iconSize;

  /// Icon color (overrides theme default if provided)
  final Color? color;

  const AdaptiveIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.iconSize = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    // Wrap in Semantics for screen reader accessibility
    return Semantics(
      button: true,
      label: tooltip,
      enabled: onPressed != null,
      child: platform == TargetPlatform.iOS
          ? _buildCupertinoButton(context)
          : _buildMaterialButton(context),
    );
  }

  Widget _buildCupertinoButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: AppSpacing.minTouchTarget,
        minHeight: AppSpacing.minTouchTarget,
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Tooltip(
          message: tooltip ?? '',
          child: Icon(
            icon,
            size: iconSize,
            color: color ?? colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: AppSpacing.minTouchTarget,
        minHeight: AppSpacing.minTouchTarget,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(
          minWidth: AppSpacing.minTouchTarget,
          minHeight: AppSpacing.minTouchTarget,
        ),
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(
          icon,
          size: iconSize,
          color: color ?? colorScheme.onSurface,
        ),
      ),
    );
  }
}
