import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';

/// Device credentials for anonymous authentication
class DeviceCredentials {
  final String deviceId;
  final String secretKey;

  DeviceCredentials({
    required this.deviceId,
    required this.secretKey,
  });

  Map<String, dynamic> toMap() => {
        'device_id': deviceId,
        'secret': secretKey,
      };

  factory DeviceCredentials.fromMap(Map<String, dynamic> map) =>
      DeviceCredentials(
        deviceId: map['device_id'] as String,
        secretKey: map['secret'] as String,
      );

  String toJson() => json.encode(toMap());

  factory DeviceCredentials.fromJson(String source) =>
      DeviceCredentials.fromMap(json.decode(source) as Map<String, dynamic>);
}

/// Secure storage for device credentials
/// NOTE: device_id is actually an account secret key, not a device identifier
/// It's used to authenticate and restore the same account across devices
class DeviceStorage {
  static const _deviceCredsKey = 'device_credentials';

  final FlutterSecureStorage? _secureStorage;
  final SharedPreferences? _sharedPrefs;
  final Uuid _uuid;

  DeviceStorage({
    FlutterSecureStorage? storage,
    SharedPreferences? sharedPrefs,
    Uuid? uuid,
  })  : _secureStorage = storage,
        _sharedPrefs = sharedPrefs,
        _uuid = uuid ?? const Uuid();

  /// Check if we should use SharedPreferences fallback (Linux doesn't support flutter_secure_storage well)
  bool get _useSharedPreferences => 
      !Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS;

  /// Read credentials from storage
  Future<String?> _read() async {
    if (_useSharedPreferences || _sharedPrefs != null) {
      final prefs = _sharedPrefs ?? await SharedPreferences.getInstance();
      return prefs.getString(_deviceCredsKey);
    } else {
      return await _secureStorage!.read(key: _deviceCredsKey);
    }
  }

  /// Write credentials to storage
  Future<void> _write(String value) async {
    if (_useSharedPreferences || _sharedPrefs != null) {
      final prefs = _sharedPrefs ?? await SharedPreferences.getInstance();
      await prefs.setString(_deviceCredsKey, value);
    } else {
      await _secureStorage!.write(key: _deviceCredsKey, value: value);
    }
  }

  /// Check if credentials exist
  Future<bool> hasCredentials() async {
    final creds = await _read();
    print('[DeviceStorage] hasCredentials: ${creds != null && creds.isNotEmpty}');
    return creds != null && creds.isNotEmpty;
  }

  /// Get existing credentials (returns null if not exist)
  Future<DeviceCredentials?> getCredentials() async {
    final existing = await _read();
    print('[DeviceStorage] getCredentials: raw data exists = ${existing != null}');

    if (existing != null) {
      try {
        final creds = DeviceCredentials.fromJson(existing);
        print('[DeviceStorage] getCredentials: deviceId = ${creds.deviceId}');
        return creds;
      } catch (e) {
        print('[DeviceStorage] getCredentials: parse error = $e');
      }
    }
    return null;
  }

  /// Get existing credentials or create new ones
  /// Use this only when you explicitly want to create new account
  Future<DeviceCredentials> getOrCreateCredentials() async {
    final existing = await getCredentials();
    if (existing != null) {
      print('[DeviceStorage] getOrCreateCredentials: returning existing deviceId = ${existing.deviceId}');
      return existing;
    }

    // Generate new credentials for new account
    print('[DeviceStorage] getOrCreateCredentials: no existing, creating new...');
    return await _createNewCredentials();
  }

  /// Set credentials from server (after email/login auth)
  Future<void> setCredentials(DeviceCredentials creds) async {
    print('[DeviceStorage] setCredentials: deviceId = ${creds.deviceId}');
    await _write(creds.toJson());
  }

  /// Create new credentials for new account
  Future<DeviceCredentials> _createNewCredentials() async {
    final deviceId = 'dev_${_uuid.v4().substring(0, 12)}';
    final secretKey = _generateSecretKey();

    final creds = DeviceCredentials(
      deviceId: deviceId,
      secretKey: secretKey,
    );

    print('[DeviceStorage] _createNewCredentials: created deviceId = $deviceId');
    
    await _write(creds.toJson());
    
    print('[DeviceStorage] _createNewCredentials: saved to storage');

    return creds;
  }

  /// Generate a secure random key
  String _generateSecretKey() {
    final bytes = utf8.encode(_uuid.v4());
    final hash = sha256.convert(bytes);
    return hash.toString().substring(0, 43);
  }

  /// Clear stored credentials (use with caution - will lose account access!)
  Future<void> clearCredentials() async {
    if (_useSharedPreferences || _sharedPrefs != null) {
      final prefs = _sharedPrefs ?? await SharedPreferences.getInstance();
      await prefs.remove(_deviceCredsKey);
    } else {
      await _secureStorage!.delete(key: _deviceCredsKey);
    }
  }
}
