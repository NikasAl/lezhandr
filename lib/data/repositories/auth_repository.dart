import '../models/user.dart';
import '../services/api_client.dart';
import '../storage/token_storage.dart';
import '../storage/device_storage.dart';

/// Repository for authentication operations
class AuthRepository {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;
  final DeviceStorage _deviceStorage;

  AuthRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
    required DeviceStorage deviceStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage,
        _deviceStorage = deviceStorage;

  /// Check if device has credentials stored
  Future<bool> hasDeviceCredentials() async {
    return await _deviceStorage.hasCredentials();
  }

  /// Authenticate using existing device credentials (no new account creation)
  /// Returns null if no credentials exist
  Future<AuthResponse?> deviceLoginExisting() async {
    final creds = await _deviceStorage.getCredentials();
    if (creds == null) {
      return null;
    }

    final response = await _apiClient.dio.post(
      '/auth/device-register',
      data: {
        'device_id': creds.deviceId,
        'secret_key': creds.secretKey,
      },
    );

    final authResponse = AuthResponse.fromJson(response.data);
    await _tokenStorage.saveToken(authResponse.accessToken);

    return authResponse;
  }

  /// Create new account with new device credentials
  Future<AuthResponse> deviceLoginCreateNew() async {
    final creds = await _deviceStorage.getOrCreateCredentials();

    final response = await _apiClient.dio.post(
      '/auth/device-register',
      data: {
        'device_id': creds.deviceId,
        'secret_key': creds.secretKey,
      },
    );

    final authResponse = AuthResponse.fromJson(response.data);
    await _tokenStorage.saveToken(authResponse.accessToken);

    return authResponse;
  }

  /// Authenticate using device credentials (legacy - creates new if not exist)
  Future<AuthResponse> deviceLogin() async {
    return await deviceLoginCreateNew();
  }

  /// Login with email and password
  /// Sends local device credentials to link them with account
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    // Get or create local device credentials to link with account
    final localCreds = await _deviceStorage.getOrCreateCredentials();

    final response = await _apiClient.dio.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
        'device_id': localCreds.deviceId,
        'secret_key': localCreds.secretKey,
      },
    );

    final authResponse = AuthResponse.fromJson(response.data);
    await _tokenStorage.saveToken(authResponse.accessToken);

    // Credentials already saved locally (in getOrCreateCredentials above)
    // Server should update user.device_id to match

    return authResponse;
  }

  /// Get current user profile
  Future<UserModel> getMe() async {
    final response = await _apiClient.dio.get('/users/me');
    return UserModel.fromJson(response.data);
  }

  /// Convert anonymous account to full account
  Future<UserModel> convertAccount({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await _apiClient.dio.patch(
      '/users/me/convert',
      data: {
        'email': email,
        'password': password,
        'username': username,
      },
    );

    return UserModel.fromJson(response.data);
  }

  /// Logout user
  Future<void> logout() async {
    await _tokenStorage.deleteToken();
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await _tokenStorage.hasToken();
  }
}
