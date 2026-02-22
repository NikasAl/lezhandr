import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';
import 'providers.dart';

/// Auth state
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final bool showLoginScreen; // True when need to show login screen
  final bool hasAccountKey; // True if device has stored account key
  final UserModel? user;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.showLoginScreen = false,
    this.hasAccountKey = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    bool? showLoginScreen,
    bool? hasAccountKey,
    UserModel? user,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      showLoginScreen: showLoginScreen ?? this.showLoginScreen,
      hasAccountKey: hasAccountKey ?? this.hasAccountKey,
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
      final hasKey = await _authRepository.hasAccountKey();
      final isAuth = await _authRepository.isAuthenticated();
      print('[AuthProvider] checkAuth: hasAccountKey=$hasKey, isAuth=$isAuth');

      if (isAuth) {
        // Try to get user profile with existing token
        try {
          final user = await _authRepository.getMe();
          state = AuthState(
            isAuthenticated: true,
            hasAccountKey: hasKey,
            user: user,
          );
          return;
        } catch (e) {
          // Token expired - try to refresh via account key if we have it
          if (hasKey) {
            try {
              await _authRepository.loginWithAccountKey();
              final user = await _authRepository.getMe();
              state = AuthState(
                isAuthenticated: true,
                hasAccountKey: true,
                user: user,
              );
              return;
            } catch (_) {}
          }
        }
      }

      // No valid token - try account key if we have it
      if (hasKey) {
        try {
          await _authRepository.loginWithAccountKey();
          final user = await _authRepository.getMe();
          state = AuthState(
            isAuthenticated: true,
            hasAccountKey: true,
            user: user,
          );
          return;
        } catch (_) {}
      }

      // No account key - show login screen
      state = AuthState(
        showLoginScreen: true,
        hasAccountKey: false,
      );
    } catch (e) {
      state = AuthState(
        showLoginScreen: true,
        error: e.toString(),
      );
    }
  }

  /// Create new account
  Future<bool> createNewAccount() async {
    print('[AuthProvider] createNewAccount: starting...');
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _authRepository.createNewAccount();

      // Get user profile
      UserModel? user;
      try {
        user = await _authRepository.getMe();
      } catch (_) {}

      final hasKey = await _authRepository.hasAccountKey();
      print('[AuthProvider] createNewAccount: success, hasAccountKey = $hasKey');
      
      state = AuthState(
        isAuthenticated: true,
        hasAccountKey: true,
        user: user,
      );

      return true;
    } catch (e) {
      print('[AuthProvider] createNewAccount: error = $e');
      state = AuthState(
        showLoginScreen: true,
        hasAccountKey: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Login with existing account key
  Future<bool> loginWithAccountKey() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _authRepository.loginWithAccountKey();

      // Get user profile
      UserModel? user;
      try {
        user = await _authRepository.getMe();
      } catch (_) {}

      state = AuthState(
        isAuthenticated: true,
        hasAccountKey: true,
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
        hasAccountKey: true,
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

  /// Logout - clear token but keep account key
  Future<void> logout() async {
    await _authRepository.logout();
    
    // Check if we have account key
    final hasKey = await _authRepository.hasAccountKey();
    print('[AuthProvider] logout: hasAccountKey = $hasKey');
    
    state = AuthState(
      showLoginScreen: true,
      hasAccountKey: hasKey,
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
