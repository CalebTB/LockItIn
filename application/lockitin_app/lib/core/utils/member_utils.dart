import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MemberUtils {
  /// Get member color by user ID (hash-based)
  static Color getColorById(String userId) {
    final hash = userId.hashCode.abs();
    const colors = [
      AppColors.memberPink,
      AppColors.memberAmber,
      AppColors.memberViolet,
      AppColors.memberCyan,
      AppColors.memberEmerald,
      AppColors.memberPurple,
      AppColors.memberTeal,
    ];
    return colors[hash % colors.length];
  }

  /// Get member color by index (for ordered lists)
  static Color getColorByIndex(int index) {
    const colors = [
      AppColors.memberPink,
      AppColors.memberAmber,
      AppColors.memberViolet,
      AppColors.memberCyan,
      AppColors.memberEmerald,
      AppColors.memberPurple,
      AppColors.memberTeal,
    ];
    return colors[index % colors.length];
  }

  /// Extract initials from display name
  static String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }
}
