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

  // ===== Availability Heatmap Colors (Minimal Theme) =====
  // Per LOCKIT_MINIMAL_THEME.md: Emerald for available, grayscale for busy
  // Only functional color is emerald - everything else is grayscale

  /// All members available (100%) - Emerald (dark mode)
  static const Color availabilityFullDark = Color(0xFF34D399); // emerald-400

  /// All members available (100%) - Emerald (light mode)
  static const Color availabilityFullLight = Color(0xFF10B981); // emerald-500

  /// Most members available (75-99%) - Light emerald tint
  static const Color availabilityHighDark = Color(0xFF34D399); // emerald-400
  static const Color availabilityHighLight = Color(0xFF10B981); // emerald-500

  /// Some members available (50-74%) - Neutral gray
  static const Color availabilityMediumDark = neutral600;
  static const Color availabilityMediumLight = gray400;

  /// Few members available (25-49%) - Darker gray
  static const Color availabilityLowDark = neutral700;
  static const Color availabilityLowLight = gray300;

  /// Very few available (1-24%) - Dark gray
  static const Color availabilityVeryLowDark = neutral800;
  static const Color availabilityVeryLowLight = gray200;

  /// No members available (0%) - Darkest/lightest
  static const Color availabilityNoneDark = neutral900;
  static const Color availabilityNoneLight = gray100;

  /// Get availability color based on ratio and brightness
  static Color getAvailabilityColor(double ratio, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    if (ratio >= 0.75) {
      // High availability - emerald (the only accent color)
      return isDark ? availabilityHighDark : availabilityHighLight;
    } else if (ratio >= 0.50) {
      return isDark ? availabilityMediumDark : availabilityMediumLight;
    } else if (ratio >= 0.25) {
      return isDark ? availabilityLowDark : availabilityLowLight;
    } else if (ratio > 0) {
      return isDark ? availabilityVeryLowDark : availabilityVeryLowLight;
    }
    return isDark ? availabilityNoneDark : availabilityNoneLight;
  }

  /// Get text color for availability cell (ensures contrast)
  static Color getAvailabilityTextColor(double ratio, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    if (ratio >= 0.75) {
      // Emerald background - dark text for contrast
      return isDark ? neutral900 : gray900;
    } else if (ratio >= 0.50) {
      // Medium gray - white/dark text
      return isDark ? Colors.white : gray900;
    } else {
      // Low availability grays - appropriate contrast
      return isDark ? neutral300 : gray700;
    }
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
