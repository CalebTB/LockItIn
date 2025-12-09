import 'package:flutter/foundation.dart';

/// Simple logger utility for debugging
class Logger {
  static const String _prefix = '🔵 LockItIn';

  /// Log info message
  static void info(String message, [String? tag]) {
    if (kDebugMode) {
      print('$_prefix ${tag != null ? '[$tag]' : ''} ℹ️  $message');
    }
  }

  /// Log error message
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('$_prefix ❌ ERROR: $message');
      if (error != null) print('   Error: $error');
      if (stackTrace != null) print('   StackTrace: $stackTrace');
    }
  }

  /// Log warning message
  static void warning(String message, [String? tag]) {
    if (kDebugMode) {
      print('$_prefix ${tag != null ? '[$tag]' : ''} ⚠️  $message');
    }
  }

  /// Log success message
  static void success(String message, [String? tag]) {
    if (kDebugMode) {
      print('$_prefix ${tag != null ? '[$tag]' : ''} ✅ $message');
    }
  }

  /// Log debug message
  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      print('$_prefix ${tag != null ? '[$tag]' : ''} 🐛 $message');
    }
  }
}
