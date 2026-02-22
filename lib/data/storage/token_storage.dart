import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure storage for authentication tokens
class TokenStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage? _secureStorage;

  TokenStorage({FlutterSecureStorage? storage}) : _secureStorage = storage;

  /// Check if we should use SharedPreferences fallback (Linux doesn't support flutter_secure_storage well)
  bool get _useSharedPreferences =>
      !Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS;

  /// Read from storage
  Future<String?> _read(String key) async {
    if (_useSharedPreferences) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } else {
      _ensureSecureStorage();
      return await _secureStorage!.read(key: key);
    }
  }

  /// Write to storage
  Future<void> _write(String key, String value) async {
    if (_useSharedPreferences) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } else {
      _ensureSecureStorage();
      await _secureStorage!.write(key: key, value: value);
    }
  }

  /// Delete from storage
  Future<void> _delete(String key) async {
    if (_useSharedPreferences) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } else {
      _ensureSecureStorage();
      await _secureStorage!.delete(key: key);
    }
  }

  void _ensureSecureStorage() {
    // Lazy initialization not needed since we use late initialization in constructor
  }

  /// Save access token
  Future<void> saveToken(String token) async {
    await _write(_accessTokenKey, token);
  }

  /// Get access token
  Future<String?> getToken() async {
    return await _read(_accessTokenKey);
  }

  /// Delete access token
  Future<void> deleteToken() async {
    await _delete(_accessTokenKey);
  }

  /// Check if token exists
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Save refresh token (for future use)
  Future<void> saveRefreshToken(String token) async {
    await _write(_refreshTokenKey, token);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _read(_refreshTokenKey);
  }

  /// Clear all tokens
  Future<void> clearAll() async {
    await _delete(_accessTokenKey);
    await _delete(_refreshTokenKey);
  }
}
