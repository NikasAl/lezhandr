import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure storage for authentication tokens
class TokenStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  /// Lazy-initialized secure storage for mobile platforms
  FlutterSecureStorage? _secureStorage;

  TokenStorage({FlutterSecureStorage? storage}) {
    if (storage != null) {
      _secureStorage = storage;
    }
  }

  /// Check if we should use SharedPreferences fallback (Linux doesn't support flutter_secure_storage well)
  bool get _useSharedPreferences =>
      !Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS;

  /// Get or create secure storage instance
  FlutterSecureStorage _getOrCreateSecureStorage() {
    if (_secureStorage == null) {
      _secureStorage = const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock,
        ),
      );
    }
    return _secureStorage!;
  }

  /// Read from storage
  Future<String?> _read(String key) async {
    try {
      if (_useSharedPreferences) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(key);
      } else {
        final storage = _getOrCreateSecureStorage();
        return await storage.read(key: key);
      }
    } catch (e) {
      debugPrint('[TokenStorage] _read error: $e');
      return null;
    }
  }

  /// Write to storage
  Future<void> _write(String key, String value) async {
    try {
      if (_useSharedPreferences) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(key, value);
      } else {
        final storage = _getOrCreateSecureStorage();
        await storage.write(key: key, value: value);
      }
    } catch (e) {
      debugPrint('[TokenStorage] _write error: $e');
    }
  }

  /// Delete from storage
  Future<void> _delete(String key) async {
    try {
      if (_useSharedPreferences) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(key);
      } else {
        final storage = _getOrCreateSecureStorage();
        await storage.delete(key: key);
      }
    } catch (e) {
      debugPrint('[TokenStorage] _delete error: $e');
    }
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
