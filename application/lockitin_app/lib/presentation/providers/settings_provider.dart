import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/app_settings.dart';

/// Provider for managing app-wide settings
class SettingsProvider extends ChangeNotifier {
  static const String _settingsKey = 'app_settings';

  AppSettings _settings = const AppSettings();

  AppSettings get settings => _settings;

  /// Whether to use color-blind friendly palette
  bool get useColorBlindPalette => _settings.useColorBlindPalette;

  /// Load settings from persistent storage
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);

      if (settingsJson != null) {
        final Map<String, dynamic> json = jsonDecode(settingsJson);
        _settings = AppSettings.fromJson(json);
        notifyListeners();
      }
    } catch (e) {
      // If loading fails, use default settings
      debugPrint('Failed to load settings: $e');
    }
  }

  /// Save settings to persistent storage
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(_settings.toJson());
      await prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      debugPrint('Failed to save settings: $e');
    }
  }

  /// Toggle color-blind palette setting
  Future<void> toggleColorBlindPalette() async {
    _settings = _settings.copyWith(
      useColorBlindPalette: !_settings.useColorBlindPalette,
    );
    notifyListeners();
    await _saveSettings();
  }

  /// Set color-blind palette setting
  Future<void> setColorBlindPalette(bool enabled) async {
    if (_settings.useColorBlindPalette != enabled) {
      _settings = _settings.copyWith(useColorBlindPalette: enabled);
      notifyListeners();
      await _saveSettings();
    }
  }
}
