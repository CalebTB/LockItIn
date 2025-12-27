import 'package:flutter/material.dart';
import '../data/models/event_model.dart';

/// Helper class for getting privacy colors based on user's color palette preference
class PrivacyColors {
  /// Get privacy color for a given visibility level
  /// If useColorBlindPalette is true, returns color-blind friendly colors
  /// Otherwise returns default colors
  static Color getPrivacyColor(
    EventVisibility visibility, {
    bool useColorBlindPalette = false,
  }) {
    if (useColorBlindPalette) {
      return _getColorBlindFriendlyColor(visibility);
    } else {
      return _getDefaultColor(visibility);
    }
  }

  /// Default color palette
  /// Private = Red, Shared = Green, Busy = Orange
  static Color _getDefaultColor(EventVisibility visibility) {
    switch (visibility) {
      case EventVisibility.private:
        return const Color(0xFFEF4444); // Red
      case EventVisibility.sharedWithName:
        return const Color(0xFF10B981); // Green
      case EventVisibility.busyOnly:
        return const Color(0xFFF59E0B); // Orange
    }
  }

  /// Color-blind friendly palette
  /// Private = Rose, Shared = Cyan, Busy = Orange
  /// This palette is distinguishable for all types of color blindness
  static Color _getColorBlindFriendlyColor(EventVisibility visibility) {
    switch (visibility) {
      case EventVisibility.private:
        return const Color(0xFFE11D48); // Rose (distinct from cyan even in deuteranopia)
      case EventVisibility.sharedWithName:
        return const Color(0xFF0891B2); // Cyan (safe, distinct)
      case EventVisibility.busyOnly:
        return const Color(0xFFF59E0B); // Orange (distinct from both)
    }
  }

  /// Get privacy label text
  static String getPrivacyLabel(EventVisibility visibility) {
    switch (visibility) {
      case EventVisibility.private:
        return 'Private';
      case EventVisibility.sharedWithName:
        return 'Shared';
      case EventVisibility.busyOnly:
        return 'Busy';
    }
  }

  /// Get privacy icon
  static IconData getPrivacyIcon(EventVisibility visibility) {
    switch (visibility) {
      case EventVisibility.private:
        return Icons.lock;
      case EventVisibility.sharedWithName:
        return Icons.people;
      case EventVisibility.busyOnly:
        return Icons.remove_red_eye_outlined;
    }
  }
}
