import 'package:flutter/material.dart';

/// Centralized color definitions for the LockItIn app
/// All colors should be referenced from this file to maintain consistency
/// and enable easy theme changes across the entire application.
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // ===== Primary Brand Colors =====

  /// Main brand color - used for primary actions, headers, and key UI elements
  /// Originally: Color.fromARGB(255, 88, 169, 255) (iOS Blue)
  /// You can change this single value to update the primary color throughout the app
  static const Color primary = Color(0xFF5AA9FF); // Light Blue

  /// Alternative primary colors you can swap in:
  // static const Color primary = Color(0xFF6366F1); // Indigo
  // static const Color primary = Color(0xFF8B5CF6); // Purple
  // static const Color primary = Color(0xFF10B981); // Green
  // static const Color primary = Color(0xFFEF4444); // Red
  // static const Color primary = Color(0xFFF59E0B); // Amber

  /// Secondary brand color - used for accents and secondary actions
  static const Color secondary = Color(0xFF818CF8); // Light Purple

  /// Tertiary brand color - used for additional accents
  static const Color tertiary = Color(0xFFF472B6); // Pink

  // ===== Avatar Colors =====

  /// Default avatar background color when no image is set
  /// This is used for the "logged in as" section and profile avatars
  static const Color avatarDefault = primary;

  // ===== Semantic Colors =====

  /// Success color - for positive feedback, confirmations
  static const Color success = Color(0xFF10B981); // Green

  /// Error color - for errors, destructive actions, validation failures
  static const Color error = Color(0xFFEF4444); // Red

  /// Warning color - for warnings and caution states
  static const Color warning = Color(0xFFF59E0B); // Amber

  /// Info color - for informational messages
  static const Color info = Color(0xFF3B82F6); // Blue

  // ===== Neutral Colors =====

  /// Grey shades for text, borders, and backgrounds
  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);

  // ===== Helper Methods =====

  /// Generate a deterministic color from a string (e.g., email)
  /// Used for user avatars when no image is set
  /// Note: This is now centralized but can be overridden by using avatarDefault instead
  static Color generateAvatarColor(String text, {bool useDefault = false}) {
    if (useDefault) {
      return avatarDefault;
    }

    // Generate a deterministic color from text
    int hash = 0;
    for (int i = 0; i < text.length; i++) {
      hash = text.codeUnitAt(i) + ((hash << 5) - hash);
    }

    // Use HSL to generate vibrant colors
    final hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.7, 0.6).toColor();
  }

  /// Get color scheme for Material 3 theme
  static ColorScheme getLightColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      error: error,
    );
  }

  /// Get color scheme for Material 3 dark theme
  static ColorScheme getDarkColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      error: error,
    );
  }
}

/// Extension on ColorScheme to add custom colors
/// Access these via Theme.of(context).colorScheme.avatarDefault
extension AppColorSchemeExtension on ColorScheme {
  /// Default avatar color for when no image is set
  Color get avatarDefault => AppColors.avatarDefault;

  /// Success color
  Color get successColor => AppColors.success;

  /// Warning color
  Color get warningColor => AppColors.warning;

  /// Info color
  Color get infoColor => AppColors.info;
}
