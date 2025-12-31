import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A standardized bottom sheet component with consistent styling
///
/// Features:
/// - 24px corner radius (standardized)
/// - Standard drag handle (40px x 4px)
/// - Dismiss by swipe down or tap outside
/// - Optional title with close button
/// - Consistent padding and spacing
class AdaptiveBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final bool showHandle;
  final bool showCloseButton;
  final double maxHeightFactor;
  final EdgeInsets padding;
  final bool isScrollable;

  const AdaptiveBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.showHandle = true,
    this.showCloseButton = false,
    this.maxHeightFactor = 0.9,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 16),
    this.isScrollable = true,
  });

  /// Standard corner radius for all bottom sheets
  static const double cornerRadius = 24.0;

  /// Standard handle dimensions
  static const double handleWidth = 40.0;
  static const double handleHeight = 4.0;

  /// Show a modal bottom sheet with this component
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool showHandle = true,
    bool showCloseButton = false,
    double maxHeightFactor = 0.9,
    EdgeInsets padding = const EdgeInsets.fromLTRB(16, 0, 16, 16),
    bool isScrollable = true,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: (context) => AdaptiveBottomSheet(
        title: title,
        showHandle: showHandle,
        showCloseButton: showCloseButton,
        maxHeightFactor: maxHeightFactor,
        padding: padding,
        isScrollable: isScrollable,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final mediaQuery = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * maxHeightFactor,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(cornerRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            if (showHandle) _buildHandle(appColors),

            // Title row (if provided)
            if (title != null) _buildTitleRow(context, colorScheme),

            // Content
            if (isScrollable)
              Flexible(
                child: SingleChildScrollView(
                  padding: padding,
                  child: child,
                ),
              )
            else
              Padding(
                padding: padding,
                child: child,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle(AppColorsExtension appColors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          width: handleWidth,
          height: handleHeight,
          decoration: BoxDecoration(
            color: appColors.textMuted.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(handleHeight / 2),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleRow(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title!,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          if (showCloseButton)
            IconButton(
              icon: Icon(
                Icons.close,
                color: colorScheme.onSurfaceVariant,
              ),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Close',
            ),
        ],
      ),
    );
  }
}

/// A bottom sheet for displaying a list of items
class AdaptiveListBottomSheet<T> extends StatelessWidget {
  final String? title;
  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final void Function(T item)? onItemTap;
  final Widget? emptyWidget;

  const AdaptiveListBottomSheet({
    super.key,
    this.title,
    required this.items,
    required this.itemBuilder,
    this.onItemTap,
    this.emptyWidget,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required List<T> items,
    required Widget Function(BuildContext context, T item) itemBuilder,
    void Function(T item)? onItemTap,
    Widget? emptyWidget,
  }) {
    return AdaptiveBottomSheet.show<T>(
      context: context,
      title: title,
      showCloseButton: true,
      child: AdaptiveListBottomSheet<T>(
        items: items,
        itemBuilder: itemBuilder,
        onItemTap: onItemTap,
        emptyWidget: emptyWidget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && emptyWidget != null) {
      return emptyWidget!;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: items.map((item) {
        final itemWidget = itemBuilder(context, item);
        if (onItemTap != null) {
          return InkWell(
            onTap: () => onItemTap!(item),
            child: itemWidget,
          );
        }
        return itemWidget;
      }).toList(),
    );
  }
}

/// A confirmation bottom sheet with action buttons
class AdaptiveConfirmBottomSheet extends StatelessWidget {
  final String title;
  final String? message;
  final String confirmLabel;
  final String cancelLabel;
  final Color? confirmColor;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isDanger;

  const AdaptiveConfirmBottomSheet({
    super.key,
    required this.title,
    this.message,
    required this.confirmLabel,
    this.cancelLabel = 'Cancel',
    this.confirmColor,
    required this.onConfirm,
    this.onCancel,
    this.isDanger = false,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    String? message,
    required String confirmLabel,
    String cancelLabel = 'Cancel',
    Color? confirmColor,
    bool isDanger = false,
  }) async {
    return await AdaptiveBottomSheet.show<bool>(
      context: context,
      isScrollable: false,
      child: Builder(
        builder: (ctx) => AdaptiveConfirmBottomSheet(
          title: title,
          message: message,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          confirmColor: confirmColor,
          isDanger: isDanger,
          onConfirm: () => Navigator.of(ctx).pop(true),
          onCancel: () => Navigator.of(ctx).pop(false),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final effectiveConfirmColor = confirmColor ??
        (isDanger ? colorScheme.error : colorScheme.primary);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),

        // Message
        if (message != null) ...[
          const SizedBox(height: 8),
          Text(
            message!,
            style: TextStyle(
              fontSize: 14,
              color: appColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],

        const SizedBox(height: 24),

        // Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCancel ?? () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                ),
                child: Text(cancelLabel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: effectiveConfirmColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                ),
                child: Text(confirmLabel),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
