import '../models/user.dart';
import '../services/api_client.dart';
import '../storage/token_storage.dart';
import '../storage/account_storage.dart';

/// Repository for authentication operations
class AuthRepository {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;
  final AccountStorage _accountStorage;

  AuthRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
    required AccountStorage accountStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage,
        _accountStorage = accountStorage;

  /// Check if account key exists locally
  Future<bool> hasAccountKey() async {
    return await _accountStorage.hasAccountKey();
  }

  /// Login with existing account key
  /// Returns null if no key exists
  Future<AuthResponse?> loginWithAccountKey() async {
    final accountKey = await _accountStorage.getAccountKey();
    if (accountKey == null) {
      print('[AUTH] loginWithAccountKey: No account key found');
      return null;
    }

    print('[AUTH] loginWithAccountKey: Using key ${accountKey.substring(0, 10)}...');

    final response = await _apiClient.dio.post(
      '/auth/account-login',
      data: {
        'account_key': accountKey,
      },
    );

    final authResponse = AuthResponse.fromJson(response.data);
    await _tokenStorage.saveToken(authResponse.accessToken);

    return authResponse;
  }

  /// Create new account with new account key
  Future<AuthResponse> createNewAccount() async {
    final accountKey = await _accountStorage.getOrCreateAccountKey();
    print('[AUTH] createNewAccount: Using key ${accountKey.substring(0, 10)}...');

    final response = await _apiClient.dio.post(
      '/auth/account-login',
      data: {
        'account_key': accountKey,
      },
    );

    final authResponse = AuthResponse.fromJson(response.data);
    await _tokenStorage.saveToken(authResponse.accessToken);

    return authResponse;
  }

  /// Login with email and password
  /// Server returns account_key which is saved locally
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    print('[AUTH] Login with email: $email');

    final response = await _apiClient.dio.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    final authResponse = AuthResponse.fromJson(response.data);
    await _tokenStorage.saveToken(authResponse.accessToken);
    
    print('[AUTH] Login response account_key: ${authResponse.accountKey?.substring(0, 10)}...');

    // Save account key from server
    // This allows subsequent logins via account_key
    if (authResponse.accountKey != null) {
      await _accountStorage.setAccountKey(authResponse.accountKey!);
      print('[AUTH] Saved server account_key to local storage');
    }

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
