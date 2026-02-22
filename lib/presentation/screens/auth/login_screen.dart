import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/solutions_provider.dart';
import '../../providers/gamification_provider.dart';

/// Login screen with splash-like design
/// Main button starts account login, expandable forms for existing account
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _showEmailForm = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Main action button - login with existing account_key or create new account
  Future<void> _startButtonPressed() async {
    setState(() => _isLoading = true);

    final authState = ref.read(authStateProvider);
    print('[LoginScreen] hasAccountKey = ${authState.hasAccountKey}');
    bool success;

    if (authState.hasAccountKey) {
      // Already has account_key - try to login with it
      print('[LoginScreen] Calling loginWithAccountKey()');
      success = await ref.read(authStateProvider.notifier).loginWithAccountKey();
    } else {
      // No account_key - create new account
      print('[LoginScreen] Calling createNewAccount()');
      success = await ref.read(authStateProvider.notifier).createNewAccount();
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _onLoginSuccess();
    }
  }

  /// Email/password login for existing account
  Future<void> _emailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await ref.read(authStateProvider.notifier).login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _onLoginSuccess();
    }
  }

  void _onLoginSuccess() {
    ref.invalidate(gamificationMeProvider);
    ref.invalidate(activeSolutionsProvider);
    context.go('/main/home');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero image / Splash area
                  _buildHeroSection(context),
                  
                  const SizedBox(height: 40),

                  // Main Start button
                  _buildStartButton(context),

                  const SizedBox(height: 24),

                  // Error message
                  if (authState.error != null) ...[
                    _buildErrorMessage(context),
                    const SizedBox(height: 16),
                  ],

                  // Expandable email/password form
                  _buildEmailPasswordSection(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Column(
      children: [
        // Hero image - horizontal image in vertical app
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/lezhandr.webp',
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),
          ),
        ),
        
        const SizedBox(height: 24),

        // App name
        Text(
          'Лежандр',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),

        // Tagline
        Text(
          'Твой спутник в мире математики',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStartButton(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final buttonText = authState.hasAccountKey ? 'Войти' : 'Начать';

    return FilledButton(
      onPressed: _isLoading ? null : _startButtonPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: _isLoading && !_showEmailForm
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  authState.hasAccountKey 
                      ? Icons.login_rounded 
                      : Icons.play_arrow_rounded, 
                  size: 28
                ),
                const SizedBox(width: 8),
                Text(
                  buttonText,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Ошибка входа. Проверьте данные.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailPasswordSection(BuildContext context) {
    return Column(
      children: [
        // Toggle button
        InkWell(
          onTap: () => setState(() => _showEmailForm = !_showEmailForm),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Или войти через email',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _showEmailForm 
                      ? Icons.keyboard_arrow_up 
                      : Icons.keyboard_arrow_down,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),

        // Animated form
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _buildEmailLoginForm(context),
          crossFadeState: _showEmailForm 
              ? CrossFadeState.showSecond 
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }

  Widget _buildEmailLoginForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),

          // Email field
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email или имя пользователя',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Введите email или имя пользователя';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 12),

          // Password field
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Пароль',
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _emailLogin(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Введите пароль';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),

          // Login button
          OutlinedButton(
            onPressed: _isLoading ? null : _emailLogin,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading && _showEmailForm
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Войти'),
          ),
        ],
      ),
    );
  }
}
