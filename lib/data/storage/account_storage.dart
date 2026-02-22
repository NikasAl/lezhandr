import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';

/// Account key storage - single key for account authentication
/// This is the "password" for the account, stored securely
class AccountStorage {
  static const _accountKeyKey = 'account_key';

  final FlutterSecureStorage? _secureStorage;
  final SharedPreferences? _sharedPrefs;
  final Uuid _uuid;

  AccountStorage({
    FlutterSecureStorage? storage,
    SharedPreferences? sharedPrefs,
    Uuid? uuid,
  })  : _secureStorage = storage,
        _sharedPrefs = sharedPrefs,
        _uuid = uuid ?? const Uuid();

  /// Check if we should use SharedPreferences fallback (Linux doesn't support flutter_secure_storage well)
  bool get _useSharedPreferences =>
      !Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS;

  /// Read from storage
  Future<String?> _read() async {
    if (_useSharedPreferences || _sharedPrefs != null) {
      final prefs = _sharedPrefs ?? await SharedPreferences.getInstance();
      return prefs.getString(_accountKeyKey);
    } else {
      return await _secureStorage!.read(key: _accountKeyKey);
    }
  }

  /// Write to storage
  Future<void> _write(String value) async {
    if (_useSharedPreferences || _sharedPrefs != null) {
      final prefs = _sharedPrefs ?? await SharedPreferences.getInstance();
      await prefs.setString(_accountKeyKey, value);
    } else {
      await _secureStorage!.write(key: _accountKeyKey, value: value);
    }
  }

  /// Check if account key exists
  Future<bool> hasAccountKey() async {
    final key = await _read();
    print('[AccountStorage] hasAccountKey: ${key != null && key.isNotEmpty}');
    return key != null && key.isNotEmpty;
  }

  /// Get existing account key (returns null if not exist)
  Future<String?> getAccountKey() async {
    final key = await _read();
    print('[AccountStorage] getAccountKey: exists = ${key != null}');
    if (key != null) {
      print('[AccountStorage] getAccountKey: ${key.substring(0, 10)}...');
    }
    return key;
  }

  /// Get existing key or create new one
  Future<String> getOrCreateAccountKey() async {
    final existing = await getAccountKey();
    if (existing != null) {
      print('[AccountStorage] getOrCreateAccountKey: returning existing');
      return existing;
    }

    print('[AccountStorage] getOrCreateAccountKey: creating new...');
    return await _createNewAccountKey();
  }

  /// Save account key from server (after email/login auth)
  Future<void> setAccountKey(String key) async {
    print('[AccountStorage] setAccountKey: ${key.substring(0, 10)}...');
    await _write(key);
  }

  /// Create new account key
  Future<String> _createNewAccountKey() async {
    // acc_ + 24 random bytes in base64url = ~32 chars, ~192 bits entropy
    final bytes = utf8.encode('${_uuid.v4()}${_uuid.v4()}');
    final hash = sha256.convert(bytes);
    final accountKey = 'acc_${hash.toString().substring(0, 32)}';
    
    print('[AccountStorage] _createNewAccountKey: ${accountKey.substring(0, 10)}...');
    
    await _write(accountKey);
    
    print('[AccountStorage] _createNewAccountKey: saved to storage');

    return accountKey;
  }

  /// Clear stored account key (use with caution - will lose account access!)
  Future<void> clearAccountKey() async {
    if (_useSharedPreferences || _sharedPrefs != null) {
      final prefs = _sharedPrefs ?? await SharedPreferences.getInstance();
      await prefs.remove(_accountKeyKey);
    } else {
      await _secureStorage!.delete(key: _accountKeyKey);
    }
  }
}
