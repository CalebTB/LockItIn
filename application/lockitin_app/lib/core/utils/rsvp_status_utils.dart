import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Utility class for RSVP status icons, colors, and labels
///
/// Centralizes all status mapping to eliminate code duplication across
/// - surprise_party_dashboard_screen.dart
/// - event_detail_screen.dart
/// - rsvp_response_sheet.dart
class RSVPStatusUtils {
  /// Get icon for RSVP status
  static IconData getIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.check_circle;
      case 'maybe':
        return Icons.help_outline;
      case 'declined':
        return Icons.cancel_outlined;
      case 'pending':
      default:
        return Icons.event_available;
    }
  }

  /// Get small icon for RSVP status (for badges/chips)
  static IconData getSmallIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.check;
      case 'maybe':
        return Icons.question_mark;
      case 'declined':
        return Icons.close;
      case 'pending':
      default:
        return Icons.schedule;
    }
  }

  /// Get color for RSVP status
  static Color getColor(String status, ColorScheme colorScheme, AppColorsExtension appColors) {
    switch (status) {
      case 'accepted':
        return appColors.success;
      case 'maybe':
        return appColors.warning;
      case 'declined':
        return colorScheme.error;
      case 'pending':
      default:
        return appColors.textDisabled;
    }
  }

  /// Get label for RSVP status (simple version)
  static String getLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'Going';
      case 'maybe':
        return 'Maybe';
      case 'declined':
        return "Can't Go";
      case 'pending':
      default:
        return 'No Response';
    }
  }

  /// Get button label for RSVP status (with "You're" prefix)
  static String getButtonLabel(String status) {
    switch (status) {
      case 'accepted':
        return "You're Going";
      case 'maybe':
        return "You're Maybe";
      case 'declined':
        return "You Can't Go";
      case 'pending':
      default:
        return 'RSVP to Event';
    }
  }
}
