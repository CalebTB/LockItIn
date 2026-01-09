/// Centralized spacing constants for the LockItIn app
/// Based on an 8px grid system for visual consistency
///
/// Usage:
/// ```dart
/// padding: EdgeInsets.all(AppSpacing.md),
/// SizedBox(height: AppSpacing.lg),
/// ```
class AppSpacing {
  // Private constructor to prevent instantiation
  AppSpacing._();

  // ============================================================================
  // Base Unit
  // ============================================================================

  /// Base spacing unit (8px)
  static const double unit = 8.0;

  // ============================================================================
  // Spacing Scale (8px increments)
  // ============================================================================

  /// 4px - Extra extra small (half unit)
  static const double xxs = 4.0;

  /// 8px - Extra small (1 unit)
  static const double xs = 8.0;

  /// 12px - Small (1.5 units)
  static const double sm = 12.0;

  /// 16px - Medium (2 units) - default padding
  static const double md = 16.0;

  /// 20px - Medium-large (2.5 units)
  static const double ml = 20.0;

  /// 24px - Large (3 units)
  static const double lg = 24.0;

  /// 32px - Extra large (4 units)
  static const double xl = 32.0;

  /// 40px - Extra extra large (5 units)
  static const double xxl = 40.0;

  /// 48px - Extra extra extra large (6 units)
  static const double xxxl = 48.0;

  /// 64px - Huge (8 units)
  static const double huge = 64.0;

  // ============================================================================
  // Semantic Spacing
  // ============================================================================

  /// Screen edge padding (16px)
  static const double screenPadding = md;

  /// Card internal padding (16px)
  static const double cardPadding = md;

  /// Section spacing between major UI sections (24px)
  static const double sectionSpacing = lg;

  /// Item spacing within a list (12px)
  static const double itemSpacing = sm;

  /// Icon-to-text spacing (8px)
  static const double iconTextSpacing = xs;

  /// Button padding horizontal (16px)
  static const double buttonPaddingH = md;

  /// Button padding vertical (12px)
  static const double buttonPaddingV = sm;

  /// Form field spacing (16px)
  static const double formFieldSpacing = md;

  /// Bottom sheet handle spacing (8px)
  static const double bottomSheetHandle = xs;

  /// App bar height (56px, close to 7 units)
  static const double appBarHeight = 56.0;

  /// Bottom nav height (64px, 8 units)
  static const double bottomNavHeight = huge;

  /// FAB margin from edge (16px)
  static const double fabMargin = md;

  // ============================================================================
  // Touch Target Sizes (Accessibility)
  // ============================================================================

  /// Minimum touch target for iOS (44pt) - Apple HIG requirement
  static const double minTouchTargetIOS = 44.0;

  /// Minimum touch target for Android (48dp) - Material Design requirement
  static const double minTouchTargetAndroid = 48.0;

  /// Cross-platform minimum touch target (48dp)
  /// Use this for all interactive elements to satisfy both iOS (44pt) and Android (48dp)
  /// Complies with WCAG 2.1 Level AA (Criterion 2.5.5: 44×44px minimum)
  static const double minTouchTarget = 48.0;

  // ============================================================================
  // Border Radius (matching spacing scale)
  // ============================================================================

  /// Small border radius (8px)
  static const double radiusSm = xs;

  /// Medium border radius (12px)
  static const double radiusMd = sm;

  /// Large border radius (16px)
  static const double radiusLg = md;

  /// Extra large border radius (24px)
  static const double radiusXl = lg;

  /// Full/pill border radius (999px)
  static const double radiusFull = 999.0;
}
