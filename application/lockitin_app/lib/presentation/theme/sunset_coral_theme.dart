import 'package:flutter/material.dart';

/// Sunset Coral Dark Theme Colors
///
/// A warm, dark theme palette using rose and orange gradients.
/// Used primarily in group-related screens for availability heatmaps.
class SunsetCoralTheme {
  // Rose color palette (dark to light)
  static const Color rose950 = Color(0xFF4C0519);
  static const Color rose900 = Color(0xFF881337);
  static const Color rose800 = Color(0xFF9F1239);
  static const Color rose700 = Color(0xFFBE123C);
  static const Color rose600 = Color(0xFFE11D48);
  static const Color rose500 = Color(0xFFF43F5E);
  static const Color rose400 = Color(0xFFFB7185);
  static const Color rose300 = Color(0xFFFDA4AF);
  static const Color rose200 = Color(0xFFFECDD3);
  static const Color rose50 = Color(0xFFFFF1F2);

  // Orange accent colors
  static const Color orange400 = Color(0xFFFB923C);
  static const Color orange500 = Color(0xFFF97316);
  static const Color orange600 = Color(0xFFEA580C);

  // Additional accent colors
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color emerald500 = Color(0xFF10B981);

  // Background colors
  static const Color slate950 = Color(0xFF020617);

  /// Background gradient for screens
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [rose950, slate950],
  );

  /// Gradient for fully available cells (100% availability)
  static const LinearGradient availableGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [rose400, orange400],
  );

  /// Heatmap color scale for availability (less to more)
  /// Used to show gradient of availability levels
  static const List<Color> heatmapScale = [
    rose950,  // 0% available (dark)
    rose900,
    rose800,
    rose700,
    rose600,
    rose500,  // ~50%
    // rose400 to orange400 gradient for 100%
  ];

  /// Get heatmap color based on availability ratio
  static Color getHeatmapColor(int available, int total) {
    if (total == 0) return rose950;

    final ratio = available / total;

    if (ratio >= 1.0) {
      // Use gradient effect color for full availability
      return rose400;
    }

    // Map ratio to heatmap scale
    final index = (ratio * (heatmapScale.length - 1)).floor();
    return heatmapScale[index.clamp(0, heatmapScale.length - 1)];
  }

  /// Standard text color for heatmap cells (always white for readability)
  static Color getHeatmapTextColor(int available, int total) {
    return Colors.white;
  }
}
