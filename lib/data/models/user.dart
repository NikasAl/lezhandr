enum UserRole { admin, moderator, user }

class UserModel {
  final int? id;
  final String? email;
  final String username;
  final bool isAnonymous;
  final String? deviceId;
  final UserRole role;
  final DateTime? createdAt;

  UserModel({
    this.id,
    this.email,
    this.username = 'Пользователь',
    this.isAnonymous = true,
    this.deviceId,
    this.role = UserRole.user,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    UserRole role = UserRole.user;
    if (json['role'] != null) {
      final roleStr = json['role'] as String;
      switch (roleStr) {
        case 'admin':
          role = UserRole.admin;
          break;
        case 'moderator':
          role = UserRole.moderator;
          break;
        default:
          role = UserRole.user;
      }
    }

    DateTime? createdAt;
    if (json['created_at'] != null) {
      try {
        createdAt = DateTime.parse(json['created_at'] as String);
      } catch (_) {}
    }

    return UserModel(
      id: json['id'] as int?,
      email: json['email'] as String?,
      username: json['username'] as String? ?? 'Пользователь',
      isAnonymous: json['is_anonymous'] as bool? ?? true,
      deviceId: json['device_id'] as String?,
      role: role,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'is_anonymous': isAnonymous,
        'device_id': deviceId,
        'role': role.name,
        'created_at': createdAt?.toIso8601String(),
      };

  String get displayName => username;

  bool get isAdmin => role == UserRole.admin;

  bool get isModerator => role == UserRole.moderator || isAdmin;
}

class AuthResponse {
  final String accessToken;
  final String tokenType;
  final UserModel? user;

  AuthResponse({
    this.accessToken = '',
    this.tokenType = 'bearer',
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String? ?? '',
      tokenType: json['token_type'] as String? ?? 'bearer',
      user: json['user'] != null && json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'token_type': tokenType,
        'user': user?.toJson(),
      };
}

class DeviceLoginRequest {
  final String deviceId;
  final String secretKey;

  DeviceLoginRequest({
    required this.deviceId,
    required this.secretKey,
  });

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'secret_key': secretKey,
      };
}

class ConvertAccountRequest {
  final String email;
  final String password;
  final String? username;

  ConvertAccountRequest({
    required this.email,
    required this.password,
    this.username,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'username': username,
      };
}
