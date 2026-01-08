import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Platform-adaptive button that uses CupertinoButton on iOS and Material buttons on Android
///
/// Automatically adapts to platform conventions:
/// - iOS: CupertinoButton.filled (primary), CupertinoButton (secondary/text)
/// - Android: ElevatedButton (primary), OutlinedButton (secondary), TextButton (text)
///
/// Usage:
/// ```dart
/// AdaptiveButton(
///   onPressed: () => print('Pressed'),
///   child: Text('Save'),
/// )
/// ```
class AdaptiveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonType type;
  final bool isDestructive;
  final EdgeInsetsGeometry? padding;
  final double? minWidth;

  const AdaptiveButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.type = ButtonType.primary,
    this.isDestructive = false,
    this.padding,
    this.minWidth,
  });

  /// Primary button (filled background)
  const AdaptiveButton.primary({
    super.key,
    required this.onPressed,
    required this.child,
    this.isDestructive = false,
    this.padding,
    this.minWidth,
  }) : type = ButtonType.primary;

  /// Secondary button (outlined)
  const AdaptiveButton.secondary({
    super.key,
    required this.onPressed,
    required this.child,
    this.isDestructive = false,
    this.padding,
    this.minWidth,
  }) : type = ButtonType.secondary;

  /// Text button (no background)
  const AdaptiveButton.text({
    super.key,
    required this.onPressed,
    required this.child,
    this.isDestructive = false,
    this.padding,
    this.minWidth,
  }) : type = ButtonType.text;

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    return platform == TargetPlatform.iOS
        ? _buildCupertinoButton(context)
        : _buildMaterialButton(context);
  }

  Widget _buildCupertinoButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (type) {
      case ButtonType.primary:
        return CupertinoButton.filled(
          onPressed: onPressed,
          padding: padding,
          minimumSize: minWidth != null ? Size(minWidth!, 44) : null,
          disabledColor: CupertinoColors.quaternarySystemFill,
          child: child,
        );

      case ButtonType.secondary:
        return CupertinoButton(
          onPressed: onPressed,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: minWidth != null ? Size(minWidth!, 44) : null,
          color: isDestructive ? CupertinoColors.destructiveRed : colorScheme.primary,
          disabledColor: CupertinoColors.quaternarySystemFill,
          child: child,
        );

      case ButtonType.text:
        return CupertinoButton(
          onPressed: onPressed,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: minWidth != null ? Size(minWidth!, 44) : null,
          child: DefaultTextStyle(
            style: TextStyle(
              color: isDestructive
                  ? CupertinoColors.destructiveRed
                  : colorScheme.primary,
            ),
            child: child,
          ),
        );
    }
  }

  Widget _buildMaterialButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (type) {
      case ButtonType.primary:
        return ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDestructive ? colorScheme.error : null,
            padding: padding,
            minimumSize: minWidth != null ? Size(minWidth!, 0) : null,
          ),
          child: child,
        );

      case ButtonType.secondary:
        return OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: isDestructive ? colorScheme.error : null,
            padding: padding,
            minimumSize: minWidth != null ? Size(minWidth!, 0) : null,
          ),
          child: child,
        );

      case ButtonType.text:
        return TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: isDestructive ? colorScheme.error : null,
            padding: padding,
            minimumSize: minWidth != null ? Size(minWidth!, 0) : null,
          ),
          child: child,
        );
    }
  }
}

/// Button type enum
enum ButtonType {
  /// Filled button with background color (primary action)
  primary,

  /// Outlined button (secondary action)
  secondary,

  /// Text-only button (tertiary action)
  text,
}
