import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage for sensitive data (auth tokens, user credentials)
class SecureStorage {
  static const _storage = FlutterSecureStorage();

  // Storage Keys
  static const _keyAuthToken = 'auth_token';
  static const _keyUserId = 'user_id';
  static const _keyUserEmail = 'user_email';

  /// Save authentication token
  static Future<void> saveAuthToken(String token) async {
    await _storage.write(key: _keyAuthToken, value: token);
  }

  /// Get authentication token
  static Future<String?> getAuthToken() async {
    return await _storage.read(key: _keyAuthToken);
  }

  /// Save user ID
  static Future<void> saveUserId(String userId) async {
    await _storage.write(key: _keyUserId, value: userId);
  }

  /// Get user ID
  static Future<String?> getUserId() async {
    return await _storage.read(key: _keyUserId);
  }

  /// Save user email
  static Future<void> saveUserEmail(String email) async {
    await _storage.write(key: _keyUserEmail, value: email);
  }

  /// Get user email
  static Future<String?> getUserEmail() async {
    return await _storage.read(key: _keyUserEmail);
  }

  /// Clear all stored data (use on logout)
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Clear specific key
  static Future<void> clearKey(String key) async {
    await _storage.delete(key: key);
  }
}
