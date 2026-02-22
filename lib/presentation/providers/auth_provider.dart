import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';
import 'providers.dart';

/// Auth state
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final bool showLoginScreen; // True when need to show login screen
  final bool hasDeviceCredentials; // True if device has stored credentials
  final UserModel? user;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.showLoginScreen = false,
    this.hasDeviceCredentials = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    bool? showLoginScreen,
    bool? hasDeviceCredentials,
    UserModel? user,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      showLoginScreen: showLoginScreen ?? this.showLoginScreen,
      hasDeviceCredentials: hasDeviceCredentials ?? this.hasDeviceCredentials,
      user: clearUser ? null : (user ?? this.user),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(const AuthState()) {
    checkAuth();
  }

  /// Check if user is authenticated
  /// Logic:
  /// 1. If has valid token -> authenticated
  /// 2. If token expired but has device_id -> try device login
  /// 3. If no token and has device_id -> try device login
  /// 4. If no device_id -> show login screen
  Future<void> checkAuth() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final hasDeviceCreds = await _authRepository.hasDeviceCredentials();
      final isAuth = await _authRepository.isAuthenticated();

      if (isAuth) {
        // Try to get user profile with existing token
        try {
          final user = await _authRepository.getMe();
          state = AuthState(
            isAuthenticated: true,
            hasDeviceCredentials: hasDeviceCreds,
            user: user,
          );
          return;
        } catch (e) {
          // Token expired - try to refresh via device login if we have credentials
          if (hasDeviceCreds) {
            try {
              await _authRepository.deviceLoginExisting();
              final user = await _authRepository.getMe();
              state = AuthState(
                isAuthenticated: true,
                hasDeviceCredentials: true,
                user: user,
              );
              return;
            } catch (_) {}
          }
        }
      }

      // No valid token - try device login if we have credentials
      if (hasDeviceCreds) {
        try {
          await _authRepository.deviceLoginExisting();
          final user = await _authRepository.getMe();
          state = AuthState(
            isAuthenticated: true,
            hasDeviceCredentials: true,
            user: user,
          );
          return;
        } catch (_) {}
      }

      // No device credentials - show login screen
      state = AuthState(
        showLoginScreen: true,
        hasDeviceCredentials: false,
      );
    } catch (e) {
      state = AuthState(
        showLoginScreen: true,
        error: e.toString(),
      );
    }
  }

  /// Device login - create new account
  /// Only called when user explicitly taps "Start" button on login screen
  Future<bool> createNewAccount() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _authRepository.deviceLoginCreateNew();

      // Get user profile
      UserModel? user;
      try {
        user = await _authRepository.getMe();
      } catch (_) {}

      state = AuthState(
        isAuthenticated: true,
        hasDeviceCredentials: true,
        user: user,
      );

      return true;
    } catch (e) {
      state = AuthState(
        showLoginScreen: true,
        hasDeviceCredentials: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Login with existing device credentials
  /// Used when user has credentials but logged out
  Future<bool> loginWithDeviceCredentials() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _authRepository.deviceLoginExisting();

      // Get user profile
      UserModel? user;
      try {
        user = await _authRepository.getMe();
      } catch (_) {}

      state = AuthState(
        isAuthenticated: true,
        hasDeviceCredentials: true,
        user: user,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        showLoginScreen: true,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Login with email/username and password
  /// Server returns device_id which is saved locally
  Future<bool> login(String emailOrUsername, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _authRepository.login(
        email: emailOrUsername,
        password: password,
      );

      // Get user profile
      UserModel? user;
      try {
        user = await _authRepository.getMe();
      } catch (_) {}

      state = AuthState(
        isAuthenticated: true,
        hasDeviceCredentials: true,
        user: user,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        showLoginScreen: true,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Convert anonymous account
  Future<bool> convertAccount({
    required String email,
    required String password,
    required String username,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final user = await _authRepository.convertAccount(
        email: email,
        password: password,
        username: username,
      );

      state = state.copyWith(user: user);

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Logout - clear token but keep device_id
  Future<void> logout() async {
    await _authRepository.logout();
    
    // Check if we have device credentials
    final hasDeviceCreds = await _authRepository.hasDeviceCredentials();
    
    state = AuthState(
      showLoginScreen: true,
      hasDeviceCredentials: hasDeviceCreds,
    );
  }

  /// Refresh user data
  Future<void> refreshUser() async {
    try {
      final user = await _authRepository.getMe();
      state = state.copyWith(user: user);
    } catch (_) {}
  }
  
  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Auth state provider
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

/// Current user provider
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authStateProvider).user;
});
