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
          Logger.info('Session expired, attempting refresh', 'AuthProvider');

          // Try to refresh the session
          final refreshed = await _authRepository.refreshSession();

          if (!refreshed) {
            // Refresh failed, clear session
            Logger.warning('Session refresh failed, clearing session', 'AuthProvider');
            await _authRepository.signOut();
            _currentUser = null;
            _setLoading(false);
            return;
          }
        }

        // Get current user
        _currentUser = await _authRepository.getCurrentUser();

        if (_currentUser != null) {
          Logger.success('User session restored: ${_currentUser!.email}', 'AuthProvider');
        } else {
          Logger.warning('Session exists but user profile not found', 'AuthProvider');
          await _authRepository.signOut();
        }
      } else {
        Logger.info('No active session found', 'AuthProvider');
      }

      // Set up auth state listener for automatic token refresh
      _setupAuthStateListener();
    } catch (e) {
      Logger.error('Failed to initialize auth', e);
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
      Logger.info('Auth state changed: $event', 'AuthProvider');

      // Handle different auth events
      switch (event) {
        case AuthChangeEvent.initialSession:
          Logger.info('Initial session loaded', 'AuthProvider');
          // Initial session is handled by initialize() method
          break;

        case AuthChangeEvent.signedIn:
          Logger.info('User signed in via auth state listener', 'AuthProvider');
          // User data will be fetched via signIn/signUp methods
          break;

        case AuthChangeEvent.signedOut:
          Logger.info('User signed out via auth state listener', 'AuthProvider');
          _currentUser = null;
          notifyListeners();
          break;

        case AuthChangeEvent.tokenRefreshed:
          Logger.info('Token auto-refreshed by Supabase', 'AuthProvider');
          // Supabase automatically handles token refresh, no action needed
          break;

        case AuthChangeEvent.userUpdated:
          Logger.info('User profile updated', 'AuthProvider');
          // Optionally refresh user profile data
          break;

        default:
          Logger.info('Unhandled auth event: $event', 'AuthProvider');
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
        Logger.success('Sign up successful', 'AuthProvider');
        _setLoading(false);
        return true;
      }

      _errorMessage = 'Sign up failed';
      _setLoading(false);
      return false;
    } catch (e) {
      Logger.error('Sign up error', e);
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
        Logger.success('Sign in successful', 'AuthProvider');
        _setLoading(false);
        return true;
      }

      _errorMessage = 'Invalid email or password';
      _setLoading(false);
      return false;
    } catch (e) {
      Logger.error('Sign in error', e);
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
      Logger.success('Sign out successful', 'AuthProvider');
    } catch (e) {
      Logger.error('Sign out error', e);
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
      Logger.success('Password reset email sent', 'AuthProvider');
      _setLoading(false);
      return true;
    } catch (e) {
      Logger.error('Password reset error', e);
      _errorMessage = 'Failed to send reset email';
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
