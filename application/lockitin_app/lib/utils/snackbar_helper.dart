import 'package:flutter/material.dart';

/// Centralized SnackBar utility for consistent messaging across the app
class SnackBarHelper {
  /// Show a success message (green background)
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
      duration: duration,
    );
  }

  /// Show an error message (uses theme error color)
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    _showSnackBar(
      context,
      message: message,
      backgroundColor: colorScheme.error,
      icon: Icons.error,
      duration: duration,
    );
  }

  /// Show an info message (uses theme primary color)
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    _showSnackBar(
      context,
      message: message,
      backgroundColor: colorScheme.primary,
      icon: Icons.info,
      duration: duration,
    );
  }

  /// Show a warning message (orange background)
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.orange,
      icon: Icons.warning,
      duration: duration,
    );
  }

  /// Internal method to show a snackbar with consistent styling
  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Hide any currently showing snackbar
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }
}
