import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Storage for theme preference
class ThemeStorage {
  static const _themeModeKey = 'theme_mode';

  final SharedPreferences? _sharedPrefs;

  ThemeStorage({SharedPreferences? sharedPrefs}) : _sharedPrefs = sharedPrefs;

  /// Get saved theme mode, defaults to system
  Future<ThemeMode> getThemeMode() async {
    try {
      final prefs = _sharedPrefs ?? await SharedPreferences.getInstance();
      final modeString = prefs.getString(_themeModeKey);
      
      switch (modeString) {
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
        case 'system':
        default:
          return ThemeMode.system;
      }
    } catch (e) {
      return ThemeMode.system;
    }
  }

  /// Save theme mode preference
  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      final prefs = _sharedPrefs ?? await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode.name);
    } catch (e) {
      debugPrint('[ThemeStorage] setThemeMode error: $e');
    }
  }
}
