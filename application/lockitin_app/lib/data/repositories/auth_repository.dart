import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/network/supabase_client.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/utils/logger.dart';
import '../models/user_model.dart';

/// Repository for authentication operations
class AuthRepository {
  final SupabaseClient _client = SupabaseClientManager.client;

  /// Sign up with email and password
  Future<UserModel?> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      Logger.info('Signing up user: $email', 'AuthRepository');

      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
        },
      );

      if (response.user != null) {
        Logger.success('Sign up successful', 'AuthRepository');

        // Save credentials
        await SecureStorage.saveUserId(response.user!.id);
        await SecureStorage.saveUserEmail(email);

        // User profile is automatically created by database trigger
        // Fetch the created profile
        final userData = await _client
            .from('users')
            .select()
            .eq('id', response.user!.id)
            .single();

        return UserModel.fromJson(userData);
      }

      return null;
    } catch (e, stackTrace) {
      Logger.error('Sign up failed', e, stackTrace);
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      Logger.info('Signing in user: $email', 'AuthRepository');

      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        Logger.success('Sign in successful', 'AuthRepository');

        // Save credentials
        await SecureStorage.saveUserId(response.user!.id);
        await SecureStorage.saveUserEmail(email);

        // Fetch user profile
        final userData = await _client
            .from('users')
            .select()
            .eq('id', response.user!.id)
            .single();

        return UserModel.fromJson(userData);
      }

      return null;
    } catch (e, stackTrace) {
      Logger.error('Sign in failed', e, stackTrace);
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      Logger.info('Signing out user', 'AuthRepository');
      await _client.auth.signOut();
      await SecureStorage.clearAll();
      Logger.success('Sign out successful', 'AuthRepository');
    } catch (e, stackTrace) {
      Logger.error('Sign out failed', e, stackTrace);
      rethrow;
    }
  }

  /// Get current user
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final userData =
          await _client.from('users').select().eq('id', user.id).single();

      return UserModel.fromJson(userData);
    } catch (e, stackTrace) {
      Logger.error('Get current user failed', e, stackTrace);
      return null;
    }
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _client.auth.currentSession != null;
  }

  /// Check if session is expired
  bool isSessionExpired() {
    final session = _client.auth.currentSession;
    if (session == null) return true;

    final expiresAt = session.expiresAt;
    if (expiresAt == null) return false;

    // Check if session expires in the next 5 minutes
    final expiryTime = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
    final now = DateTime.now();
    return expiryTime.isBefore(now.add(const Duration(minutes: 5)));
  }

  /// Refresh session token
  Future<bool> refreshSession() async {
    try {
      Logger.info('Refreshing session token', 'AuthRepository');

      final session = await _client.auth.refreshSession();

      if (session.session != null) {
        Logger.success('Session refreshed successfully', 'AuthRepository');
        return true;
      }

      Logger.warning('Session refresh returned null', 'AuthRepository');
      return false;
    } catch (e, stackTrace) {
      Logger.error('Session refresh failed', e, stackTrace);
      return false;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      Logger.info('Sending password reset email to: $email', 'AuthRepository');
      await _client.auth.resetPasswordForEmail(email);
      Logger.success('Password reset email sent', 'AuthRepository');
    } catch (e, stackTrace) {
      Logger.error('Password reset failed', e, stackTrace);
      rethrow;
    }
  }
}
