/// App-wide settings model
class AppSettings {
  /// Whether to use color-blind friendly palette for privacy indicators
  /// Default palette: Red (Private), Green (Shared), Orange (Busy)
  /// Color-blind palette: Rose (Private), Cyan (Shared), Orange (Busy)
  final bool useColorBlindPalette;

  const AppSettings({
    this.useColorBlindPalette = false,
  });

  /// Create a copy with updated fields
  AppSettings copyWith({
    bool? useColorBlindPalette,
  }) {
    return AppSettings(
      useColorBlindPalette: useColorBlindPalette ?? this.useColorBlindPalette,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'useColorBlindPalette': useColorBlindPalette,
    };
  }

  /// Create from JSON
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      useColorBlindPalette: json['useColorBlindPalette'] as bool? ?? false,
    );
  }
}
