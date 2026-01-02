import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Error banner widget for GroupDetailScreen
class ErrorBanner extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback onRetry;

  const ErrorBanner({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colorScheme.error.withValues(alpha: 0.15),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 18, color: appColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage ?? 'Error loading availability',
              style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Retry',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
