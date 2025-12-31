import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/network/supabase_client.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/utils/logger.dart';
import '../models/user_model.dart';

/// Exception thrown when authentication operations fail
class AuthRepositoryException implements Exception {
  final String message;
  final String? code;

  AuthRepositoryException(this.message, {this.code});

  @override
  String toString() => 'AuthRepositoryException: $message';
}

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
      Logger.info('AuthRepository', 'Signing up user: $email');

      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
        },
      );

      if (response.user != null) {
        Logger.success('AuthRepository', 'Sign up successful');

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
    } on AuthException catch (e) {
      throw _handleAuthError(e);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e, stackTrace) {
      Logger.error('AuthRepository', 'Sign up failed', e, stackTrace);
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      Logger.info('AuthRepository', 'Signing in user: $email');

      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        Logger.success('AuthRepository', 'Sign in successful');

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
    } on AuthException catch (e) {
      throw _handleAuthError(e);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e, stackTrace) {
      Logger.error('AuthRepository', 'Sign in failed', e, stackTrace);
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      Logger.info('AuthRepository', 'Signing out user');
      await _client.auth.signOut();
      await SecureStorage.clearAll();
      Logger.success('AuthRepository', 'Sign out successful');
    } on AuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e, stackTrace) {
      Logger.error('AuthRepository', 'Sign out failed', e, stackTrace);
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
    } on PostgrestException catch (e) {
      Logger.error('AuthRepository', 'Get current user failed: ${e.code} - ${e.message}');
      return null;
    } catch (e, stackTrace) {
      Logger.error('AuthRepository', 'Get current user failed', e, stackTrace);
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
      Logger.info('AuthRepository', 'Refreshing session token');

      final session = await _client.auth.refreshSession();

      if (session.session != null) {
        Logger.success('AuthRepository', 'Session refreshed successfully');
        return true;
      }

      Logger.warning('AuthRepository', 'Session refresh returned null');
      return false;
    } on AuthException catch (e) {
      Logger.error('AuthRepository', 'Session refresh failed: ${e.statusCode} - ${e.message}');
      return false;
    } catch (e, stackTrace) {
      Logger.error('AuthRepository', 'Session refresh failed', e, stackTrace);
      return false;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      Logger.info('AuthRepository', 'Sending password reset email to: $email');
      await _client.auth.resetPasswordForEmail(email);
      Logger.success('AuthRepository', 'Password reset email sent');
    } on AuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e, stackTrace) {
      Logger.error('AuthRepository', 'Password reset failed', e, stackTrace);
      rethrow;
    }
  }

  /// Update user profile
  Future<UserModel?> updateProfile({
    required String userId,
    String? fullName,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      Logger.info('AuthRepository', 'Updating profile for user: $userId');

      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (bio != null) updates['bio'] = bio;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      final response = await _client
          .from('users')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      Logger.success('AuthRepository', 'Profile updated successfully');
      return UserModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } on AuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e, stackTrace) {
      Logger.error('AuthRepository', 'Profile update failed', e, stackTrace);
      rethrow;
    }
  }

  /// Convert AuthException to user-friendly AuthRepositoryException
  AuthRepositoryException _handleAuthError(AuthException e) {
    Logger.error('AuthRepository', 'Auth error: ${e.statusCode} - ${e.message}');

    // Handle common auth error messages
    final message = e.message.toLowerCase();

    if (message.contains('invalid login credentials')) {
      return AuthRepositoryException(
        'Invalid email or password',
        code: e.statusCode,
      );
    }
    if (message.contains('email not confirmed')) {
      return AuthRepositoryException(
        'Please confirm your email address',
        code: e.statusCode,
      );
    }
    if (message.contains('user already registered')) {
      return AuthRepositoryException(
        'An account with this email already exists',
        code: e.statusCode,
      );
    }
    if (message.contains('password')) {
      return AuthRepositoryException(
        'Password must be at least 6 characters',
        code: e.statusCode,
      );
    }
    if (message.contains('email')) {
      return AuthRepositoryException(
        'Please enter a valid email address',
        code: e.statusCode,
      );
    }
    if (message.contains('rate limit') || message.contains('too many')) {
      return AuthRepositoryException(
        'Too many attempts. Please try again later.',
        code: e.statusCode,
      );
    }

    return AuthRepositoryException(
      e.message,
      code: e.statusCode,
    );
  }

  /// Convert PostgrestException to user-friendly AuthRepositoryException
  AuthRepositoryException _handlePostgrestError(PostgrestException e) {
    Logger.error('AuthRepository', 'Database error: ${e.code} - ${e.message}');

    switch (e.code) {
      case '23505': // unique_violation
        return AuthRepositoryException(
          'This record already exists',
          code: e.code,
        );
      case '42501': // insufficient_privilege (RLS)
        return AuthRepositoryException(
          'Permission denied',
          code: e.code,
        );
      case 'PGRST116': // JWT expired
        return AuthRepositoryException(
          'Session expired, please log in again',
          code: e.code,
        );
      case 'PGRST301': // Row not found
        return AuthRepositoryException(
          'User not found',
          code: e.code,
        );
      default:
        return AuthRepositoryException(
          'Database error: ${e.message}',
          code: e.code,
        );
    }
  }
}
