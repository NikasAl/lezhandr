import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';
import 'providers.dart';

/// Auth state
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserModel? user;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserModel? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error,
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
    state = state.copyWith(isLoading: true);

    try {
      final isAuth = await _authRepository.isAuthenticated();

      if (isAuth) {
        final user = await _authRepository.getMe();
        state = AuthState(
          isAuthenticated: true,
          user: user,
        );
      } else {
        // Try device login
        await deviceLogin();
      }
    } catch (e) {
      // Try device login on error
      await deviceLogin();
    }
  }

  /// Device login
  Future<bool> deviceLogin() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _authRepository.deviceLogin();

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
        error: e.toString(),
      );
      return false;
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _authRepository.login(
        email: email,
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
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _authRepository.convertAccount(
        email: email,
        password: password,
        username: username,
      );

      state = state.copyWith(
        user: user,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
      );
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _authRepository.logout();
    state = const AuthState();
  }

  /// Refresh user data
  Future<void> refreshUser() async {
    try {
      final user = await _authRepository.getMe();
      state = state.copyWith(user: user);
    } catch (_) {}
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
