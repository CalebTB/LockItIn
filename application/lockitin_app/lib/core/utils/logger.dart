import 'package:flutter/foundation.dart';

/// Simple logger utility for debugging
///
/// All methods take an optional [tag] parameter first (typically the service/class name)
/// followed by the message. This ensures consistent log formatting.
///
/// Example:
/// ```dart
/// Logger.info('UserService', 'User logged in successfully');
/// Logger.error('AuthService', 'Failed to authenticate', e);
/// ```
class Logger {
  static const String _prefix = '🔵 LockItIn';

  /// Log info message
  /// [tag] - Optional service/class name for filtering (e.g., 'FriendService')
  /// [message] - The log message
  static void info(String tag, String message) {
    if (kDebugMode) {
      print('$_prefix [$tag] ℹ️  $message');
    }
  }

  /// Log error message
  /// [tag] - Service/class name for filtering
  /// [message] - The error description
  /// [error] - Optional error object
  /// [stackTrace] - Optional stack trace
  static void error(String tag, String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('$_prefix [$tag] ❌ ERROR: $message');
      if (error != null) print('   Error: $error');
      if (stackTrace != null) print('   StackTrace: $stackTrace');
    }
  }

  /// Log warning message
  static void warning(String tag, String message) {
    if (kDebugMode) {
      print('$_prefix [$tag] ⚠️  $message');
    }
  }

  /// Log success message
  static void success(String tag, String message) {
    if (kDebugMode) {
      print('$_prefix [$tag] ✅ $message');
    }
  }

  /// Log debug message
  static void debug(String tag, String message) {
    if (kDebugMode) {
      print('$_prefix [$tag] 🐛 $message');
    }
  }
}
