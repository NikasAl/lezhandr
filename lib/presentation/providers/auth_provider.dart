import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';
import 'providers.dart';

/// Auth state
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final bool showLoginScreen; // New: indicate if login screen should be shown
  final UserModel? user;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.showLoginScreen = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    bool? showLoginScreen,
    UserModel? user,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      showLoginScreen: showLoginScreen ?? this.showLoginScreen,
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
  Future<void> checkAuth() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final isAuth = await _authRepository.isAuthenticated();

      if (isAuth) {
        // Try to get user profile with existing token
        try {
          final user = await _authRepository.getMe();
          state = AuthState(
            isAuthenticated: true,
            user: user,
          );
        } catch (e) {
          // Token expired or invalid - try to refresh via device login
          try {
            await _authRepository.deviceLogin();
            final user = await _authRepository.getMe();
            state = AuthState(
              isAuthenticated: true,
              user: user,
            );
          } catch (refreshError) {
            // Refresh failed - show login screen
            state = const AuthState(showLoginScreen: true);
          }
        }
      } else {
        // No token - try device login first
        try {
          await _authRepository.deviceLogin();
          final user = await _authRepository.getMe();
          state = AuthState(
            isAuthenticated: true,
            user: user,
          );
        } catch (e) {
          // Device login failed - show login screen
          state = const AuthState(showLoginScreen: true);
        }
      }
    } catch (e) {
      state = AuthState(
        showLoginScreen: true,
        error: e.toString(),
      );
    }
  }

  /// Device login (create new anonymous account)
  Future<bool> deviceLogin() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _authRepository.deviceLogin();

      // Get user profile
      UserModel? user;
      try {
        user = await _authRepository.getMe();
      } catch (_) {}

      state = AuthState(
        isAuthenticated: true,
        user: user,
      );

      return true;
    } catch (e) {
      state = AuthState(
        showLoginScreen: true,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Login with email/username and password
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

  /// Logout
  Future<void> logout() async {
    await _authRepository.logout();
    state = const AuthState(showLoginScreen: true);
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
