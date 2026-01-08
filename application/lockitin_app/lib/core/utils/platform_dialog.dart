import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Utility for showing platform-appropriate dialogs
///
/// Uses CupertinoAlertDialog on iOS and AlertDialog on Android
/// for a native look and feel on each platform

/// Show a platform-appropriate confirmation dialog
///
/// Returns true if user confirms, false if cancelled
Future<bool> showPlatformConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  bool isDestructive = false,
}) async {
  final platform = Theme.of(context).platform;
  if (platform == TargetPlatform.iOS) {
    return await showCupertinoDialog<bool>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(cancelText),
              ),
              CupertinoDialogAction(
                isDestructiveAction: isDestructive,
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(confirmText),
              ),
            ],
          ),
        ) ??
        false;
  } else {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(cancelText),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: isDestructive
                    ? TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      )
                    : null,
                child: Text(confirmText),
              ),
            ],
          ),
        ) ??
        false;
  }
}

/// Show a platform-appropriate alert dialog (single action)
///
/// For informational messages that just need an "OK" button
Future<void> showPlatformAlertDialog({
  required BuildContext context,
  required String title,
  required String message,
  String buttonText = 'OK',
}) async {
  final platform = Theme.of(context).platform;
  if (platform == TargetPlatform.iOS) {
    await showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  } else {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}

/// Show a platform-appropriate action sheet (iOS) or bottom sheet (Android)
///
/// For presenting multiple action options to the user
Future<T?> showPlatformActionSheet<T>({
  required BuildContext context,
  required String title,
  String? message,
  required List<PlatformActionSheetAction<T>> actions,
  PlatformActionSheetAction<T>? cancelAction,
}) async {
  final platform = Theme.of(context).platform;
  if (platform == TargetPlatform.iOS) {
    return await showCupertinoModalPopup<T>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(title),
        message: message != null ? Text(message) : null,
        actions: actions.map((action) {
          return CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(action.value),
            isDestructiveAction: action.isDestructive,
            child: Text(action.label),
          );
        }).toList(),
        cancelButton: cancelAction != null
            ? CupertinoActionSheetAction(
                onPressed: () => Navigator.of(context).pop(cancelAction.value),
                child: Text(cancelAction.label),
              )
            : CupertinoActionSheetAction(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
      ),
    );
  } else {
    return await showModalBottomSheet<T>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            const Divider(height: 1),
            ...actions.map((action) {
              return ListTile(
                onTap: () => Navigator.of(context).pop(action.value),
                title: Text(
                  action.label,
                  style: TextStyle(
                    color: action.isDestructive
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Action for platform action sheet
class PlatformActionSheetAction<T> {
  final String label;
  final T value;
  final bool isDestructive;

  const PlatformActionSheetAction({
    required this.label,
    required this.value,
    this.isDestructive = false,
  });
}
