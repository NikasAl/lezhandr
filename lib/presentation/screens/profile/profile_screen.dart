import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/billing_provider.dart';
import '../../../core/theme/app_theme.dart';

/// Profile screen - user settings and account
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final authState = ref.watch(authStateProvider);
    final billing = ref.watch(billingBalanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: Open settings
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(authStateProvider.notifier).refreshUser();
          ref.invalidate(billingBalanceProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          user?.username.substring(0, 1).toUpperCase() ?? '?',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.username ?? 'Пользователь',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? 'Email не привязан',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            if (user?.isAnonymous == true) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Анонимный аккаунт',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Convert account (for anonymous users)
              if (user?.isAnonymous == true) ...[
                const SizedBox(height: 16),
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Привязать Email',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Защитите свой аккаунт и сохраните прогресс',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => _showConvertDialog(context),
                          child: const Text('Привязать Email'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Balance
              Text(
                'Финансы',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Баланс',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const Spacer(),
                          Text(
                            '${billing.value?.balance.toStringAsFixed(2) ?? '0.00'} ₽',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('🐱', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(
                            'Кот Базис (бесплатно)',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const Spacer(),
                          Text(
                            '${billing.value?.freeUsesLeft ?? 0}/${billing.value?.totalDailyLimit ?? 5}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showTopUpDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Пополнить баланс'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Settings
              Text(
                'Настройки',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Тёмная тема'),
                      secondary: const Icon(Icons.dark_mode_outlined),
                      value: false,
                      onChanged: (value) {
                        // TODO: Toggle theme
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Уведомления'),
                      secondary: const Icon(Icons.notifications_outlined),
                      value: true,
                      onChanged: (value) {
                        // TODO: Toggle notifications
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Вибрация'),
                      secondary: const Icon(Icons.vibration),
                      value: true,
                      onChanged: (value) {
                        // TODO: Toggle vibration
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Logout
              Card(
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Выйти из аккаунта',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () => _showLogoutDialog(context),
                ),
              ),

              const SizedBox(height: 24),

              // App info
              Center(
                child: Column(
                  children: [
                    Text(
                      'Лежандр v1.0.0',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'MindVector Client',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConvertDialog(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final usernameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Привязать Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Имя пользователя',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Пароль',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authStateProvider.notifier).convertAccount(
                    email: emailController.text,
                    password: passwordController.text,
                    username: usernameController.text,
                  );
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showTopUpDialog(BuildContext context) {
    final amounts = [100, 250, 500, 1000];
    int? selectedAmount;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Пополнить баланс'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: amounts.map((amount) {
                  final isSelected = selectedAmount == amount;
                  return ChoiceChip(
                    label: Text('$amount ₽'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => selectedAmount = selected ? amount : null);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: selectedAmount == null
                  ? null
                  : () {
                      Navigator.pop(context);
                      // TODO: Call top-up API
                    },
              child: const Text('Оплатить'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text(
            'Вы будете автоматически авторизованы при следующем запуске.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authStateProvider.notifier).logout();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }
}
