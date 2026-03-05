import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/main_menu/main_shell.dart';
import '../../presentation/screens/main_menu/home_screen.dart';
import '../../presentation/screens/library/library_screen.dart';
import '../../presentation/screens/statistics/statistics_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/problems/problem_detail_screen.dart';
import '../../presentation/screens/solutions/solution_session_screen.dart';
import '../../presentation/screens/solutions/solution_detail_screen.dart';
import '../../presentation/screens/camera/camera_screen.dart';
import '../../presentation/screens/billing/transactions_screen.dart';
import '../../presentation/screens/concepts/concepts_screen.dart';
import '../../presentation/screens/skills/skills_map_screen.dart';
import '../../presentation/screens/about/about_screen.dart';
import '../../presentation/screens/legal/privacy_policy_screen.dart';
import '../../presentation/providers/auth_provider.dart';

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  // Only watch fields that affect routing decisions, not user data
  // This prevents router rebuild on user refresh (which was causing redirect to home)
  final isAuthenticated = ref.watch(authStateProvider.select((s) => s.isAuthenticated));
  final showLoginScreen = ref.watch(authStateProvider.select((s) => s.showLoginScreen));
  final isLoading = ref.watch(authStateProvider.select((s) => s.isLoading));

  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/',

    // Redirect based on auth state
    redirect: (context, state) {
      
      final isSplash = state.matchedLocation == '/';
      final isLogin = state.matchedLocation == '/login';

      // Still loading - stay on splash
      if (isLoading && !isAuthenticated && !showLoginScreen) {
        return isSplash ? null : '/';
      }

      // Not authenticated and should show login
      if (!isAuthenticated && showLoginScreen) {
        return isLogin ? null : '/login';
      }

      // Authenticated - redirect away from splash/login
      if (isAuthenticated) {
        if (isSplash || isLogin) {
          return '/main/home';
        }
      }

      return null;
    },

    routes: [
      // Splash Screen
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Login Screen
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Main Shell with Bottom Navigation
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          // Home
          GoRoute(
            path: '/main/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),

          // Library
          GoRoute(
            path: '/main/library',
            name: 'library',
            builder: (context, state) => const LibraryScreen(),
          ),

          // Statistics
          GoRoute(
            path: '/main/statistics',
            name: 'statistics',
            builder: (context, state) => const StatisticsScreen(),
          ),

          // Profile
          GoRoute(
            path: '/main/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Problem Detail
      GoRoute(
        path: '/problems/:id',
        name: 'problem-detail',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ProblemDetailScreen(problemId: id);
        },
      ),

      // Solution Session
      GoRoute(
        path: '/session/:id',
        name: 'session',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final existingMinutes = state.uri.queryParameters['existingMinutes'];
          return SolutionSessionScreen(
            solutionId: id,
            existingMinutes: existingMinutes != null
                ? double.tryParse(existingMinutes) ?? 0.0
                : 0.0,
          );
        },
      ),

      // Solution Detail
      GoRoute(
        path: '/solutions/:id',
        name: 'solution-detail',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return SolutionDetailScreen(solutionId: id);
        },
      ),

      // Camera
      GoRoute(
        path: '/camera',
        name: 'camera',
        builder: (context, state) {
          final category = state.uri.queryParameters['category'] ?? 'condition';
          final entityId = int.parse(state.uri.queryParameters['entityId'] ?? '0');
          return CameraScreen(
            category: category,
            entityId: entityId,
          );
        },
      ),

      // Transactions
      GoRoute(
        path: '/transactions',
        name: 'transactions',
        builder: (context, state) => const TransactionsScreen(),
      ),

      // Concepts Analysis
      GoRoute(
        path: '/concepts',
        name: 'concepts',
        builder: (context, state) => const ConceptsScreen(),
      ),

      // Skills Map (My Skills)
      GoRoute(
        path: '/skills-map',
        name: 'skills-map',
        builder: (context, state) => const SkillsMapScreen(),
      ),

      // About screen
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) {
          final isFirstLaunch = state.uri.queryParameters['firstLaunch'] == 'true';
          return AboutScreen(isFirstLaunch: isFirstLaunch);
        },
      ),

      // Privacy Policy
      GoRoute(
        path: '/privacy',
        name: 'privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Ошибка')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Страница не найдена',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(state.error?.toString() ?? 'Unknown error'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/main/home'),
              child: const Text('На главную'),
            ),
          ],
        ),
      ),
    ),
  );
});
