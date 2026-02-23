import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';

/// Account key storage - single key for account authentication
/// This is the "password" for the account, stored securely
class AccountStorage {
  static const _accountKeyKey = 'account_key';

  final SharedPreferences? _sharedPrefs;
  final Uuid _uuid;
  
  /// Lazy-initialized secure storage for mobile platforms
  FlutterSecureStorage? _secureStorage;

  AccountStorage({
    FlutterSecureStorage? storage,
    SharedPreferences? sharedPrefs,
    Uuid? uuid,
  })  : _sharedPrefs = sharedPrefs,
        _uuid = uuid ?? const Uuid() {
    // Если storage передан - используем его
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
  Future<String?> _read() async {
    try {
      if (_useSharedPreferences || _sharedPrefs != null) {
        final prefs = _sharedPrefs ?? await SharedPreferences.getInstance();
        return prefs.getString(_accountKeyKey);
      } else {
        final storage = _getOrCreateSecureStorage();
        return await storage.read(key: _accountKeyKey);
      }
    } catch (e) {
      debugPrint('[AccountStorage] _read error: $e');
      return null;
    }
  }

  /// Write to storage
  Future<void> _write(String value) async {
    try {
      if (_useSharedPreferences || _sharedPrefs != null) {
        final prefs = _sharedPrefs ?? await SharedPreferences.getInstance();
        await prefs.setString(_accountKeyKey, value);
      } else {
        final storage = _getOrCreateSecureStorage();
        await storage.write(key: _accountKeyKey, value: value);
      }
    } catch (e) {
      debugPrint('[AccountStorage] _write error: $e');
    }
  }

  /// Check if account key exists
  Future<bool> hasAccountKey() async {
    final key = await _read();
    debugPrint('[AccountStorage] hasAccountKey: ${key != null && key.isNotEmpty}');
    return key != null && key.isNotEmpty;
  }

  /// Get existing account key (returns null if not exist)
  Future<String?> getAccountKey() async {
    final key = await _read();
    debugPrint('[AccountStorage] getAccountKey: exists = ${key != null}');
    if (key != null && key.length > 10) {
      debugPrint('[AccountStorage] getAccountKey: ${key.substring(0, 10)}...');
    }
    return key;
  }

  /// Get existing key or create new one
  Future<String> getOrCreateAccountKey() async {
    final existing = await getAccountKey();
    if (existing != null) {
      debugPrint('[AccountStorage] getOrCreateAccountKey: returning existing');
      return existing;
    }

    debugPrint('[AccountStorage] getOrCreateAccountKey: creating new...');
    return await _createNewAccountKey();
  }

  /// Save account key from server (after email/login auth)
  Future<void> setAccountKey(String key) async {
    if (key.length > 10) {
      debugPrint('[AccountStorage] setAccountKey: ${key.substring(0, 10)}...');
    }
    await _write(key);
  }

  /// Create new account key
  Future<String> _createNewAccountKey() async {
    // acc_ + 24 random bytes in base64url = ~32 chars, ~192 bits entropy
    final bytes = utf8.encode('${_uuid.v4()}${_uuid.v4()}');
    final hash = sha256.convert(bytes);
    final accountKey = 'acc_${hash.toString().substring(0, 32)}';
    
    debugPrint('[AccountStorage] _createNewAccountKey: ${accountKey.substring(0, 10)}...');
    
    await _write(accountKey);
    
    debugPrint('[AccountStorage] _createNewAccountKey: saved to storage');

    return accountKey;
  }

  /// Clear stored account key (use with caution - will lose account access!)
  Future<void> clearAccountKey() async {
    if (_useSharedPreferences || _sharedPrefs != null) {
      final prefs = _sharedPrefs ?? await SharedPreferences.getInstance();
      await prefs.remove(_accountKeyKey);
    } else {
      final storage = _getOrCreateSecureStorage();
      await storage.delete(key: _accountKeyKey);
    }
  }
}
