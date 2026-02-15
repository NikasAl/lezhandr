import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
class DeviceStorage {
  static const _deviceCredsKey = 'device_credentials';

  final FlutterSecureStorage _storage;
  final Uuid _uuid;

  DeviceStorage({FlutterSecureStorage? storage, Uuid? uuid})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
            ),
        _uuid = uuid ?? const Uuid();

  /// Get existing credentials or create new ones
  Future<DeviceCredentials> getOrCreateCredentials() async {
    final existing = await _storage.read(key: _deviceCredsKey);

    if (existing != null) {
      try {
        return DeviceCredentials.fromJson(existing);
      } catch (_) {
        // Invalid data, create new
      }
    }

    // Generate new credentials
    final deviceId = 'dev_${_uuid.v4().substring(0, 12)}';
    final secretKey = _generateSecretKey();

    final creds = DeviceCredentials(
      deviceId: deviceId,
      secretKey: secretKey,
    );

    await _storage.write(
      key: _deviceCredsKey,
      value: creds.toJson(),
    );

    return creds;
  }

  /// Generate a secure random key
  String _generateSecretKey() {
    final bytes = utf8.encode(_uuid.v4());
    final hash = sha256.convert(bytes);
    return hash.toString().substring(0, 43);
  }

  /// Clear stored credentials
  Future<void> clearCredentials() async {
    await _storage.delete(key: _deviceCredsKey);
  }

  /// Check if credentials exist
  Future<bool> hasCredentials() async {
    final creds = await _storage.read(key: _deviceCredsKey);
    return creds != null && creds.isNotEmpty;
  }
}
