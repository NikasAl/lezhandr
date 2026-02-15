import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/gamification_provider.dart';

/// Statistics screen - show progress and activity
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamification = ref.watch(gamificationMeProvider);
    final activity = ref.watch(activityProvider(7));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(gamificationMeProvider);
              ref.invalidate(activityProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(gamificationMeProvider);
          ref.invalidate(activityProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // XP Card
              _XpCard(
                xp: gamification.value?.totalXp ?? 0,
                level: gamification.value?.currentLevel ?? 1,
                progress: gamification.value?.xpProgress ?? 0,
              ),
              const SizedBox(height: 16),

              // Hearts & Streak
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.favorite,
                      iconColor: Colors.red,
                      title: 'Сердца',
                      value:
                          '${gamification.value?.currentHearts ?? 5}/${gamification.value?.maxHearts ?? 5}',
                      progress:
                          gamification.value?.heartsProgress ?? 1.0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.local_fire_department,
                      iconColor: Colors.orange,
                      title: 'Стрик',
                      value: '${gamification.value?.streakCurrent ?? 0} дн.',
                      subtitle: gamification.value?.streakCurrent == 0
                          ? null
                          : 'Макс: ${gamification.value?.streakMax ?? 0}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Activity chart
              Text(
                'Активность (7 дней)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              activity.when(
                data: (data) => _ActivityChart(items: data?.items ?? []),
                loading: () => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox(
                  height: 200,
                  child: Center(child: Text('Ошибка загрузки')),
                ),
              ),
              const SizedBox(height: 24),

              // Quick stats
              Text(
                'Детальная статистика',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    _StatRow(
                      icon: Icons.check_circle,
                      label: 'Задач сегодня',
                      value:
                          '${gamification.value?.solvedTasksToday ?? 0}',
                    ),
                    const Divider(height: 1),
                    _StatRow(
                      icon: Icons.star,
                      label: 'Всего XP',
                      value:
                          '${(gamification.value?.totalXp ?? 0).toStringAsFixed(0)}',
                    ),
                    const Divider(height: 1),
                    _StatRow(
                      icon: Icons.trending_up,
                      label: 'Текущий уровень',
                      value:
                          '${gamification.value?.currentLevel ?? 1}',
                    ),
                    const Divider(height: 1),
                    _StatRow(
                      icon: Icons.emoji_events,
                      label: 'Максимальный стрик',
                      value:
                          '${gamification.value?.streakMax ?? 0} дней',
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
}

class _XpCard extends StatelessWidget {
  final double xp;
  final int level;
  final double progress;

  const _XpCard({
    required this.xp,
    required this.level,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  '${xp.toStringAsFixed(0)} XP',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Уровень $level',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String? subtitle;
  final double? progress;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    this.subtitle,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            if (progress != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActivityChart extends StatelessWidget {
  final List<dynamic> items;

  const _ActivityChart({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.bar_chart,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  'Нет данных об активности',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Find max XP for scaling
    double maxXp = 0;
    for (final item in items) {
      if (item.xp > maxXp) maxXp = item.xp;
    }
    if (maxXp == 0) maxXp = 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Simple bar chart
            SizedBox(
              height: 150,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: items.map((item) {
                  final height = (item.xp / maxXp) * 100;
                  final date = DateTime.parse(item.date);
                  final today = DateTime.now();
                  final isToday = date.day == today.day &&
                      date.month == today.month &&
                      date.year == today.year;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            item.xp.toStringAsFixed(0),
                            style:
                                Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: height + 20,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getDayName(date.weekday),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: isToday
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primary
                                      : null,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Пн';
      case 2:
        return 'Вт';
      case 3:
        return 'Ср';
      case 4:
        return 'Чт';
      case 5:
        return 'Пт';
      case 6:
        return 'Сб';
      case 7:
        return 'Вс';
      default:
        return '';
    }
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
