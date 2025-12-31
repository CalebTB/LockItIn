import 'package:flutter/material.dart';

/// Typography scale for the LockItIn app
/// Based on Material Design 3 type scale with custom weights
///
/// Usage:
/// ```dart
/// Text('Title', style: AppTypography.titleLarge(context)),
/// Text('Body', style: Theme.of(context).textTheme.bodyMedium),
/// ```
///
/// Prefer using Theme.of(context).textTheme for standard text styles.
/// Use AppTypography helpers for custom weighted variants.
class AppTypography {
  // Private constructor to prevent instantiation
  AppTypography._();

  // ============================================================================
  // Font Sizes (Material Design 3 Type Scale)
  // ============================================================================

  /// Display Large: 57pt
  static const double displayLarge = 57.0;

  /// Display Medium: 45pt
  static const double displayMedium = 45.0;

  /// Display Small: 36pt
  static const double displaySmall = 36.0;

  /// Headline Large: 32pt
  static const double headlineLarge = 32.0;

  /// Headline Medium: 28pt
  static const double headlineMedium = 28.0;

  /// Headline Small: 24pt
  static const double headlineSmall = 24.0;

  /// Title Large: 22pt
  static const double titleLarge = 22.0;

  /// Title Medium: 16pt
  static const double titleMedium = 16.0;

  /// Title Small: 14pt
  static const double titleSmall = 14.0;

  /// Body Large: 16pt
  static const double bodyLarge = 16.0;

  /// Body Medium: 14pt (default body text)
  static const double bodyMedium = 14.0;

  /// Body Small: 12pt
  static const double bodySmall = 12.0;

  /// Label Large: 14pt
  static const double labelLarge = 14.0;

  /// Label Medium: 12pt
  static const double labelMedium = 12.0;

  /// Label Small: 11pt
  static const double labelSmall = 11.0;

  // ============================================================================
  // Font Weights
  // ============================================================================

  /// Light weight (300)
  static const FontWeight light = FontWeight.w300;

  /// Regular weight (400)
  static const FontWeight regular = FontWeight.w400;

  /// Medium weight (500)
  static const FontWeight medium = FontWeight.w500;

  /// Semi-bold weight (600)
  static const FontWeight semiBold = FontWeight.w600;

  /// Bold weight (700)
  static const FontWeight bold = FontWeight.w700;

  // ============================================================================
  // Line Heights
  // ============================================================================

  /// Tight line height (1.2)
  static const double lineHeightTight = 1.2;

  /// Normal line height (1.4)
  static const double lineHeightNormal = 1.4;

  /// Relaxed line height (1.6)
  static const double lineHeightRelaxed = 1.6;

  // ============================================================================
  // Letter Spacing
  // ============================================================================

  /// Tight letter spacing (-0.5)
  static const double letterSpacingTight = -0.5;

  /// Normal letter spacing (0)
  static const double letterSpacingNormal = 0.0;

  /// Wide letter spacing (0.5)
  static const double letterSpacingWide = 0.5;

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Get the TextTheme from context
  static TextTheme of(BuildContext context) {
    return Theme.of(context).textTheme;
  }

  /// Create a custom text style based on body medium with custom weight
  static TextStyle bodyMediumWeight(BuildContext context, FontWeight weight) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: weight);
  }

  /// Create a custom text style based on title medium with custom weight
  static TextStyle titleMediumWeight(BuildContext context, FontWeight weight) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: weight);
  }
}
