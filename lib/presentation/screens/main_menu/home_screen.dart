import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/solutions_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../widgets/motivation/motivation_card.dart';
import '../../../core/motivation/motivation_engine.dart';
import '../../../core/motivation/motivation_models.dart';

/// Home screen - main dashboard
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final activeSolutions = ref.watch(activeSolutionsProvider);
    final gamification = ref.watch(gamificationMeProvider);
    final motivationEngine = MotivationEngine();
    final motivation = motivationEngine.getTextForContext(
      MotivationContext.current(
        sessionState: SessionState.idle,
        streakDays: gamification.value?.streakCurrent ?? 0,
        tasksCompletedToday: gamification.value?.solvedTasksToday ?? 0,
        totalTasksCompleted: 0,
        totalXp: gamification.value?.totalXp ?? 0,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Лежандр'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeSolutionsProvider);
          ref.invalidate(gamificationMeProvider);
          ref.read(authStateProvider.notifier).refreshUser();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting card
              _GreetingCard(
                username: user?.username ?? 'Пользователь',
                streak: gamification.value?.streakCurrent ?? 0,
                tasksToday: gamification.value?.solvedTasksToday ?? 0,
              ),
              const SizedBox(height: 16),

              // Motivation card
              if (motivation != null) ...[
                MotivationCard(
                  motivation: motivation,
                  showAuthor: true,
                  animate: true,
                ),
                const SizedBox(height: 16),
              ],

              // Quick stats
              _QuickStatsCard(
                xp: gamification.value?.totalXp ?? 0,
                hearts: gamification.value?.currentHearts ?? 5,
                maxHearts: gamification.value?.maxHearts ?? 5,
              ),
              const SizedBox(height: 16),

              // Active solutions
              _ActiveSolutionsCard(
                solutions: activeSolutions.valueOrNull ?? [],
                onContinue: (solutionId, existingMinutes) {
                  context.push('/session/$solutionId?existingMinutes=$existingMinutes');
                },
                onNewTask: () {
                  context.push('/main/library');
                },
              ),
              const SizedBox(height: 24),

              // Quick actions
              Text(
                'Быстрые действия',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.play_arrow,
                      label: 'Начать решение',
                      onTap: () => context.push('/main/library'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.psychology,
                      label: 'Анализ концепций',
                      onTap: () => context.push('/concepts'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/main/library'),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Решать'),
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  final String username;
  final int streak;
  final int tasksToday;

  const _GreetingCard({
    required this.username,
    required this.streak,
    required this.tasksToday,
  });

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Доброе утро';
    } else if (hour < 18) {
      greeting = 'Добрый день';
    } else {
      greeting = 'Добрый вечер';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting,',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    username,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 18,
                        color: streak > 0 ? Colors.orange : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Стрик: $streak дн.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.check_circle, size: 18, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        'Сегодня: $tasksToday',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  '🧮',
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStatsCard extends StatelessWidget {
  final double xp;
  final int hearts;
  final int maxHearts;

  const _QuickStatsCard({
    required this.xp,
    required this.hearts,
    required this.maxHearts,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              icon: Icons.star,
              iconColor: Colors.amber,
              label: 'XP',
              value: xp.toStringAsFixed(0),
            ),
            Container(
              height: 40,
              width: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            _StatItem(
              icon: Icons.favorite,
              iconColor: Colors.red,
              label: 'Сердца',
              value: '$hearts/$maxHearts',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _ActiveSolutionsCard extends StatelessWidget {
  final List<dynamic> solutions;
  final Function(int solutionId, double existingMinutes) onContinue;
  final VoidCallback onNewTask;

  const _ActiveSolutionsCard({
    required this.solutions,
    required this.onContinue,
    required this.onNewTask,
  });

  @override
  Widget build(BuildContext context) {
    if (solutions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'Нет активных задач',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Начните решать новую задачу',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onNewTask,
                icon: const Icon(Icons.add),
                label: const Text('Новая задача'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.play_circle_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Активные задачи',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${solutions.length}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...solutions.take(3).map((solution) {
              final problem = solution.problem;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.activeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.timer, color: AppTheme.activeColor),
                ),
                title: Text(
                  problem?.displayTitle ?? 'Задача #${solution.problemId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${solution.totalMinutes.toStringAsFixed(0)} мин',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () => onContinue(solution.id, solution.totalMinutes),
                ),
              );
            }),
            if (solutions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: onNewTask,
                  icon: const Icon(Icons.add),
                  label: const Text('Новая задача'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
