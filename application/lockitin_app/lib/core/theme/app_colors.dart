import 'package:flutter/material.dart';

/// Centralized color definitions for the LockItIn app
/// All colors should be referenced from this file to maintain consistency
/// and enable easy theme changes across the entire application.
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // ===== Primary Brand Colors =====
  // Option 1: Trust & Privacy Color Scheme
  // Deep Blue + Purple + Coral for trustworthy, friendly, sophisticated brand

  /// Main brand color - used for primary actions, headers, and key UI elements
  /// Deep Blue conveys trust, reliability, and privacy (perfect for Shadow Calendar)
  static const Color primary = Color(0xFF2563EB); // Deep Blue

  /// Secondary brand color - used for accents and secondary actions
  /// Purple adds social warmth and differentiates from corporate blues
  static const Color secondary = Color(0xFF8B5CF6); // Purple

  /// Tertiary brand color - used for celebration, confirmations, and warm moments
  /// Warm Coral for joy and celebration (event confirmations, success states)
  static const Color tertiary = Color(0xFFFB923C); // Warm Coral

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
  static const Color info = Color(0xFF2563EB); // Deep Blue (matches primary)

  // ===== Event Category Colors =====

  /// Work events - Teal (professional, productive, bridges blue → green)
  /// Derived from primary Deep Blue while maintaining "work" semantics
  static const Color categoryWork = Color(0xFF14B8A6); // Teal-500

  /// Holiday events - Warm Coral (celebration, matches brand tertiary)
  /// Uses brand tertiary color directly - perfect semantic fit
  static const Color categoryHoliday = Color(0xFFFB923C); // Warm Coral (tertiary)

  /// Friend events - Purple (social, matches brand secondary)
  /// Uses brand secondary color directly - already perfect
  static const Color categoryFriend = Color(0xFF8B5CF6); // Purple (secondary)

  /// Other events - Slate Blue (neutral, derived from primary)
  /// Cooler, more premium than yellow - cohesive with Deep Blue brand
  static const Color categoryOther = Color(0xFF64748B); // Slate-500

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
