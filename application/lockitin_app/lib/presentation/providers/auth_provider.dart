import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/network/supabase_client.dart';
import '../../core/utils/logger.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

/// Provider for authentication state management
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  StreamSubscription<AuthState>? _authStateSubscription;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  /// Initialize auth state (check if user is already logged in)
  Future<void> initialize() async {
    _setLoading(true);
    try {
      if (_authRepository.isAuthenticated()) {
        // Check if session is expired
        if (_authRepository.isSessionExpired()) {
          Logger.info('AuthProvider', 'Session expired, attempting refresh');

          // Try to refresh the session
          final refreshed = await _authRepository.refreshSession();

          if (!refreshed) {
            // Refresh failed, clear session
            Logger.warning('AuthProvider', 'Session refresh failed, clearing session');
            await _authRepository.signOut();
            _currentUser = null;
            _setLoading(false);
            return;
          }
        }

        // Get current user
        _currentUser = await _authRepository.getCurrentUser();

        if (_currentUser != null) {
          Logger.success('AuthProvider', 'User session restored: ${_currentUser!.email}');
        } else {
          Logger.warning('AuthProvider', 'Session exists but user profile not found');
          await _authRepository.signOut();
        }
      } else {
        Logger.info('AuthProvider', 'No active session found');
      }

      // Set up auth state listener for automatic token refresh
      _setupAuthStateListener();
    } catch (e) {
      Logger.error('AuthProvider', 'Failed to initialize auth', e);
      _errorMessage = 'Failed to restore session';
      // Clear potentially corrupted session
      try {
        await _authRepository.signOut();
      } catch (_) {}
      _currentUser = null;
    } finally {
      _setLoading(false);
    }
  }

  /// Set up auth state listener for automatic session management
  void _setupAuthStateListener() {
    final client = SupabaseClientManager.client;

    _authStateSubscription?.cancel();
    _authStateSubscription = client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      Logger.info('AuthProvider', 'Auth state changed: $event');

      // Handle different auth events
      switch (event) {
        case AuthChangeEvent.initialSession:
          Logger.info('AuthProvider', 'Initial session loaded');
          // Initial session is handled by initialize() method
          break;

        case AuthChangeEvent.signedIn:
          Logger.info('AuthProvider', 'User signed in via auth state listener');
          // User data will be fetched via signIn/signUp methods
          break;

        case AuthChangeEvent.signedOut:
          Logger.info('AuthProvider', 'User signed out via auth state listener');
          _currentUser = null;
          notifyListeners();
          break;

        case AuthChangeEvent.tokenRefreshed:
          Logger.info('AuthProvider', 'Token auto-refreshed by Supabase');
          // Supabase automatically handles token refresh, no action needed
          break;

        case AuthChangeEvent.userUpdated:
          Logger.info('AuthProvider', 'User profile updated');
          // Optionally refresh user profile data
          break;

        default:
          Logger.info('AuthProvider', 'Unhandled auth event: $event');
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  /// Sign up
  Future<bool> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _authRepository.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (_currentUser != null) {
        Logger.success('AuthProvider', 'Sign up successful');
        _setLoading(false);
        return true;
      }

      _errorMessage = 'Sign up failed';
      _setLoading(false);
      return false;
    } catch (e) {
      Logger.error('AuthProvider', 'Sign up error', e);
      _errorMessage = _getErrorMessage(e);
      _setLoading(false);
      return false;
    }
  }

  /// Sign in
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _authRepository.signIn(
        email: email,
        password: password,
      );

      if (_currentUser != null) {
        Logger.success('AuthProvider', 'Sign in successful');
        _setLoading(false);
        return true;
      }

      _errorMessage = 'Invalid email or password';
      _setLoading(false);
      return false;
    } catch (e) {
      Logger.error('AuthProvider', 'Sign in error', e);
      _errorMessage = _getErrorMessage(e);
      _setLoading(false);
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authRepository.signOut();
      _currentUser = null;
      Logger.success('AuthProvider', 'Sign out successful');
    } catch (e) {
      Logger.error('AuthProvider', 'Sign out error', e);
      _errorMessage = 'Failed to sign out';
    } finally {
      _setLoading(false);
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authRepository.resetPassword(email);
      Logger.success('AuthProvider', 'Password reset email sent');
      _setLoading(false);
      return true;
    } catch (e) {
      Logger.error('AuthProvider', 'Password reset error', e);
      _errorMessage = 'Failed to send reset email';
      _setLoading(false);
      return false;
    }
  }

  /// Update profile
  Future<bool> updateProfile({
    String? fullName,
    String? bio,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) {
      _errorMessage = 'No user logged in';
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final updatedUser = await _authRepository.updateProfile(
        userId: _currentUser!.id,
        fullName: fullName,
        bio: bio,
        avatarUrl: avatarUrl,
      );

      if (updatedUser != null) {
        _currentUser = updatedUser;
        Logger.success('AuthProvider', 'Profile updated successfully');
        _setLoading(false);
        return true;
      }

      _errorMessage = 'Profile update failed';
      _setLoading(false);
      return false;
    } catch (e) {
      Logger.error('AuthProvider', 'Profile update error', e);
      _errorMessage = 'Failed to update profile';
      _setLoading(false);
      return false;
    }
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('invalid login credentials')) {
      return 'Invalid email or password';
    } else if (errorString.contains('email already registered')) {
      return 'This email is already registered';
    } else if (errorString.contains('network')) {
      return 'Network error. Check your connection.';
    } else {
      return 'Something went wrong. Please try again.';
    }
  }
}
