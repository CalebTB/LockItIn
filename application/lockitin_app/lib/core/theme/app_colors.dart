import 'package:flutter/material.dart';

/// Centralized color definitions for the LockItIn app
/// Based on the Minimal theme from LOCKIT_MINIMAL_THEME.md
/// A clean, neutral theme with rose/orange accents
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // ===== Primary Brand Colors (Minimal Theme) =====
  // Rose/Orange gradient accent with neutral foundation

  /// Primary accent - Rose 500
  static const Color primary = Color(0xFFF43F5E);

  /// Secondary accent - Orange 500
  static const Color secondary = Color(0xFFF97316);

  /// Tertiary - Rose 400 (lighter accent)
  static const Color tertiary = Color(0xFFFB7185);

  // ===== Rose Palette =====
  static const Color rose50 = Color(0xFFFFF1F2);
  static const Color rose100 = Color(0xFFFFE4E6);
  static const Color rose200 = Color(0xFFFECDD3);
  static const Color rose300 = Color(0xFFFDA4AF);
  static const Color rose400 = Color(0xFFFB7185);
  static const Color rose500 = Color(0xFFF43F5E);
  static const Color rose600 = Color(0xFFE11D48);
  static const Color rose700 = Color(0xFFBE123C);
  static const Color rose800 = Color(0xFF9F1239);
  static const Color rose900 = Color(0xFF881337);
  static const Color rose950 = Color(0xFF4C0519);

  // ===== Orange Palette =====
  static const Color orange50 = Color(0xFFFFF7ED);
  static const Color orange100 = Color(0xFFFFEDD5);
  static const Color orange200 = Color(0xFFFED7AA);
  static const Color orange300 = Color(0xFFFDBA74);
  static const Color orange400 = Color(0xFFFB923C);
  static const Color orange500 = Color(0xFFF97316);
  static const Color orange600 = Color(0xFFEA580C);

  // ===== Neutral Palette (Dark Mode Foundation) =====
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFE5E5E5);
  static const Color neutral300 = Color(0xFFD4D4D4);
  static const Color neutral400 = Color(0xFFA3A3A3);
  static const Color neutral500 = Color(0xFF737373);
  static const Color neutral600 = Color(0xFF525252);
  static const Color neutral700 = Color(0xFF404040);
  static const Color neutral800 = Color(0xFF262626);
  static const Color neutral900 = Color(0xFF171717);
  static const Color neutral950 = Color(0xFF0A0A0A);

  // ===== Gray Palette (Light Mode Foundation) =====
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFE5E5E5);
  static const Color gray300 = Color(0xFFD4D4D4);
  static const Color gray400 = Color(0xFFA3A3A3);
  static const Color gray500 = Color(0xFF737373);
  static const Color gray600 = Color(0xFF525252);
  static const Color gray700 = Color(0xFF404040);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF171717);

  // ===== Semantic Colors =====

  /// Success color - Emerald
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);

  /// Error color - Rose (matches primary)
  static const Color error = Color(0xFFF43F5E);

  /// Warning color - Amber
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFCD34D);

  /// Info color - Blue
  static const Color info = Color(0xFF3B82F6);

  // ===== Member/Category Colors =====
  // Distinct colors for group members and event categories

  static const Color memberPink = Color(0xFFEC4899);
  static const Color memberAmber = Color(0xFFFB923C);
  static const Color memberViolet = Color(0xFF8B5CF6);
  static const Color memberCyan = Color(0xFF06B6D4);
  static const Color memberEmerald = Color(0xFF10B981);
  static const Color memberPurple = Color(0xFFA855F7);
  static const Color memberTeal = Color(0xFF14B8A6);

  // ===== Event Category Colors =====
  // Used for calendar event indicators and category badges

  /// Work events - Teal
  static const Color categoryWork = memberTeal;

  /// Holiday events - Orange (matches secondary)
  static const Color categoryHoliday = secondary;

  /// Friend events - Violet
  static const Color categoryFriend = memberViolet;

  /// Other events - Primary rose
  static const Color categoryOther = primary;

  // ===== Availability Heatmap Colors (5-Tier Semantic Scale) =====
  // Green → Lime → Yellow → Orange → Red
  // Provides visual distinction between perfect and poor availability

  // Emerald/Green - Perfect availability (>85%)
  static const Color availabilityPerfectBgLight = Color(0xFFD1FAE5); // emerald-100
  static const Color availabilityPerfectBgDark = Color(0xFF064E3B); // emerald-900

  // Lime/Greenish-yellow - High availability (65-85%)
  static const Color availabilityHighBgLight = Color(0xFFECFCCB); // lime-100
  static const Color availabilityHighBgDark = Color(0xFF365314); // lime-900

  // Amber/Yellow - Medium availability (50-65%)
  static const Color availabilityMediumBgLight = Color(0xFFFEF3C7); // amber-100
  static const Color availabilityMediumBgDark = Color(0xFF78350F); // amber-900

  // Orange/Reddish-yellow - Low availability (25-50%)
  static const Color availabilityLowBgLight = Color(0xFFFFEDD5); // orange-100
  static const Color availabilityLowBgDark = Color(0xFF7C2D12); // orange-900

  // Rose/Red - Poor availability (<25%)
  static const Color availabilityPoorBgLight = Color(0xFFFFE4E6); // rose-100
  static const Color availabilityPoorBgDark = Color(0xFF881337); // rose-900

  // Gray - No data or no availability
  static const Color availabilityNoneBgLight = gray100;
  static const Color availabilityNoneBgDark = neutral900;

  // Solid colors for dots/badges (5-tier)
  static const Color availabilityPerfect = Color(0xFF10B981); // emerald-500
  static const Color availabilityHigh = Color(0xFF84CC16); // lime-500
  static const Color availabilityMedium = Color(0xFFF59E0B); // amber-500
  static const Color availabilityLow = Color(0xFFF97316); // orange-500
  static const Color availabilityPoor = Color(0xFFF43F5E); // rose-500

  /// Get availability background color based on ratio and brightness
  /// Uses 5-tier scale: green → lime → yellow → orange → red
  static Color getAvailabilityColor(double ratio, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    if (ratio >= 0.85) {
      // Perfect availability - emerald/green
      return isDark ? availabilityPerfectBgDark : availabilityPerfectBgLight;
    } else if (ratio >= 0.65) {
      // High availability - lime/greenish-yellow
      return isDark ? availabilityHighBgDark : availabilityHighBgLight;
    } else if (ratio >= 0.50) {
      // Medium availability - amber/yellow
      return isDark ? availabilityMediumBgDark : availabilityMediumBgLight;
    } else if (ratio >= 0.25) {
      // Low availability - orange/reddish-yellow
      return isDark ? availabilityLowBgDark : availabilityLowBgLight;
    } else if (ratio > 0) {
      // Poor availability - rose/red
      return isDark ? availabilityPoorBgDark : availabilityPoorBgLight;
    }
    // No availability - gray
    return isDark ? availabilityNoneBgDark : availabilityNoneBgLight;
  }

  /// Get text color for availability cell (ensures contrast)
  static Color getAvailabilityTextColor(double ratio, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    if (ratio >= 0.85) {
      // Emerald background - emerald text
      return isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857); // emerald-300/700
    } else if (ratio >= 0.65) {
      // Lime background - lime text
      return isDark ? const Color(0xFFBEF264) : const Color(0xFF4D7C0F); // lime-300/700
    } else if (ratio >= 0.50) {
      // Amber background - amber text
      return isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309); // amber-300/700
    } else if (ratio >= 0.25) {
      // Orange background - orange text
      return isDark ? const Color(0xFFFDBA74) : const Color(0xFFC2410C); // orange-300/700
    } else if (ratio > 0) {
      // Rose background - rose text
      return isDark ? const Color(0xFFFDA4AF) : const Color(0xFFBE123C); // rose-300/700
    }
    // No availability - muted text
    return isDark ? neutral400 : gray400;
  }

  /// Get solid availability color for dots/badges (5-tier)
  static Color getAvailabilityDotColor(double ratio) {
    if (ratio >= 0.85) return availabilityPerfect; // emerald
    if (ratio >= 0.65) return availabilityHigh; // lime
    if (ratio >= 0.50) return availabilityMedium; // amber
    if (ratio >= 0.25) return availabilityLow; // orange
    if (ratio > 0) return availabilityPoor; // rose
    return neutral400; // gray
  }

  /// Get darker text color for availability (ensures contrast on light backgrounds)
  /// Use this for text on tinted availability backgrounds
  static Color getAvailabilityTextColorDark(double ratio) {
    if (ratio >= 0.85) return const Color(0xFF047857); // emerald-700
    if (ratio >= 0.65) return const Color(0xFF4D7C0F); // lime-700
    if (ratio >= 0.50) return const Color(0xFFB45309); // amber-700
    if (ratio >= 0.25) return const Color(0xFFC2410C); // orange-700
    if (ratio > 0) return const Color(0xFFBE123C); // rose-700
    return gray600; // gray
  }

  // ===== Avatar Colors =====
  static const Color avatarDefault = primary;

  // ===== Helper Methods =====

  /// Generate a deterministic color from a string (e.g., email)
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

  /// Get light color scheme for Material 3 theme (Minimal Light)
  static ColorScheme getLightColorScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      // Primary
      primary: rose500,
      onPrimary: Colors.white,
      primaryContainer: rose100,
      onPrimaryContainer: rose900,
      // Secondary
      secondary: orange500,
      onSecondary: Colors.white,
      secondaryContainer: orange100,
      onSecondaryContainer: orange600,
      // Tertiary
      tertiary: rose400,
      onTertiary: Colors.white,
      tertiaryContainer: rose50,
      onTertiaryContainer: rose800,
      // Error
      error: rose500,
      onError: Colors.white,
      errorContainer: rose50,
      onErrorContainer: rose900,
      // Surface - Light mode uses white/gray
      surface: Colors.white,
      onSurface: gray900,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: gray50,
      surfaceContainer: gray100,
      surfaceContainerHigh: gray200,
      surfaceContainerHighest: gray300,
      onSurfaceVariant: gray600,
      // Outline
      outline: gray200,
      outlineVariant: gray300,
      // Other
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: gray900,
      onInverseSurface: gray50,
      inversePrimary: rose300,
    );
  }

  /// Get dark color scheme for Material 3 theme (Minimal Dark)
  static ColorScheme getDarkColorScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      // Primary
      primary: rose500,
      onPrimary: Colors.white,
      primaryContainer: rose900,
      onPrimaryContainer: rose100,
      // Secondary
      secondary: orange500,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF7C2D12), // orange-900
      onSecondaryContainer: orange100,
      // Tertiary
      tertiary: rose400,
      onTertiary: Colors.white,
      tertiaryContainer: rose950,
      onTertiaryContainer: rose200,
      // Error
      error: rose400,
      onError: Colors.white,
      errorContainer: rose950,
      onErrorContainer: rose200,
      // Surface - Dark mode uses neutral blacks
      surface: neutral950,
      onSurface: Colors.white,
      surfaceContainerLowest: Colors.black,
      surfaceContainerLow: neutral950,
      surfaceContainer: neutral900,
      surfaceContainerHigh: neutral800,
      surfaceContainerHighest: neutral700,
      onSurfaceVariant: neutral400,
      // Outline
      outline: neutral800,
      outlineVariant: neutral700,
      // Other
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: neutral100,
      onInverseSurface: neutral900,
      inversePrimary: rose600,
    );
  }
}

/// Theme extension for custom app colors not covered by ColorScheme
@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.textSecondary,
    required this.textTertiary,
    required this.textMuted,
    required this.textDisabled,
    required this.success,
    required this.successBackground,
    required this.warning,
    required this.warningBackground,
    required this.info,
    required this.infoBackground,
    required this.cardBackground,
    required this.cardBorder,
    required this.divider,
  });

  final Color textSecondary;
  final Color textTertiary;
  final Color textMuted;
  final Color textDisabled;
  final Color success;
  final Color successBackground;
  final Color warning;
  final Color warningBackground;
  final Color info;
  final Color infoBackground;
  final Color cardBackground;
  final Color cardBorder;
  final Color divider;

  /// Light mode colors
  static const light = AppColorsExtension(
    textSecondary: AppColors.gray700,
    textTertiary: AppColors.gray600,
    textMuted: AppColors.gray500,
    textDisabled: AppColors.gray400,
    success: AppColors.success,
    successBackground: Color(0xFFECFDF5), // emerald-50
    warning: AppColors.warning,
    warningBackground: Color(0xFFFFFBEB), // amber-50
    info: AppColors.info,
    infoBackground: Color(0xFFEFF6FF), // blue-50
    cardBackground: Colors.white,
    cardBorder: AppColors.gray200,
    divider: AppColors.gray200,
  );

  /// Dark mode colors
  static const dark = AppColorsExtension(
    textSecondary: AppColors.neutral300,
    textTertiary: AppColors.neutral400,
    textMuted: AppColors.neutral500,
    textDisabled: AppColors.neutral600,
    success: AppColors.successLight,
    successBackground: Color(0x26059669), // emerald-500/15
    warning: AppColors.warningLight,
    warningBackground: Color(0x26D97706), // amber-500/15
    info: Color(0xFF60A5FA), // blue-400
    infoBackground: Color(0x263B82F6), // blue-500/15
    cardBackground: AppColors.neutral900,
    cardBorder: AppColors.neutral800,
    divider: AppColors.neutral800,
  );

  @override
  AppColorsExtension copyWith({
    Color? textSecondary,
    Color? textTertiary,
    Color? textMuted,
    Color? textDisabled,
    Color? success,
    Color? successBackground,
    Color? warning,
    Color? warningBackground,
    Color? info,
    Color? infoBackground,
    Color? cardBackground,
    Color? cardBorder,
    Color? divider,
  }) {
    return AppColorsExtension(
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textMuted: textMuted ?? this.textMuted,
      textDisabled: textDisabled ?? this.textDisabled,
      success: success ?? this.success,
      successBackground: successBackground ?? this.successBackground,
      warning: warning ?? this.warning,
      warningBackground: warningBackground ?? this.warningBackground,
      info: info ?? this.info,
      infoBackground: infoBackground ?? this.infoBackground,
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      divider: divider ?? this.divider,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) {
      return this;
    }
    return AppColorsExtension(
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      success: Color.lerp(success, other.success, t)!,
      successBackground: Color.lerp(successBackground, other.successBackground, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningBackground: Color.lerp(warningBackground, other.warningBackground, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoBackground: Color.lerp(infoBackground, other.infoBackground, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}

/// Extension on BuildContext for easy access to custom colors
extension AppColorsExtensionContext on BuildContext {
  AppColorsExtension get appColors =>
      Theme.of(this).extension<AppColorsExtension>() ?? AppColorsExtension.light;
}

/// Extension on ColorScheme to add common color accessors
extension AppColorSchemeExtension on ColorScheme {
  /// Default avatar color
  Color get avatarDefault => AppColors.avatarDefault;

  /// Success color
  Color get successColor => brightness == Brightness.dark
      ? AppColors.successLight
      : AppColors.success;

  /// Warning color
  Color get warningColor => brightness == Brightness.dark
      ? AppColors.warningLight
      : AppColors.warning;

  /// Info color
  Color get infoColor => brightness == Brightness.dark
      ? const Color(0xFF60A5FA) // blue-400
      : AppColors.info;
}
