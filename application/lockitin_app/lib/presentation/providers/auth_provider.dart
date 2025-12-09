import 'package:flutter/foundation.dart';
import '../../core/utils/logger.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

/// Provider for authentication state management
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

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
        _currentUser = await _authRepository.getCurrentUser();
        Logger.success('User already authenticated', 'AuthProvider');
      }
    } catch (e) {
      Logger.error('Failed to initialize auth', e);
      _errorMessage = 'Failed to restore session';
    } finally {
      _setLoading(false);
    }
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
