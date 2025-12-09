import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Singleton class for managing Supabase client instance
class SupabaseClientManager {
  static SupabaseClient? _instance;

  /// Initialize Supabase
  ///
  /// Call this ONCE at app startup in main.dart:
  /// ```dart
  /// await SupabaseClientManager.initialize();
  /// ```
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      debug: SupabaseConfig.enableDebugLogging,
    );
    _instance = Supabase.instance.client;
  }

  /// Get the Supabase client instance
  ///
  /// Usage:
  /// ```dart
  /// final client = SupabaseClientManager.client;
  /// final data = await client.from('users').select();
  /// ```
  static SupabaseClient get client {
    if (_instance == null) {
      throw Exception(
        'SupabaseClientManager not initialized. '
        'Call SupabaseClientManager.initialize() in main.dart',
      );
    }
    return _instance!;
  }

  /// Check if user is authenticated
  static bool get isAuthenticated {
    return client.auth.currentSession != null;
  }

  /// Get current user
  static User? get currentUser {
    return client.auth.currentUser;
  }

  /// Get current user ID
  static String? get currentUserId {
    return client.auth.currentUser?.id;
  }
}
