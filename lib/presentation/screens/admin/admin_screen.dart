import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';

/// Admin panel main screen
class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final stats = ref.watch(adminStatsProvider);

    // Check admin access
    if (currentUser == null || !currentUser.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Доступ запрещён')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'У вас нет прав доступа к этой странице',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🛠 Админка'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminStatsProvider),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📊 На модерации',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    stats.when(
                      data: (data) => Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _StatChip(
                            icon: Icons.label_outline,
                            label: 'Теги',
                            count: data['tags'] ?? 0,
                            color: Colors.blue,
                          ),
                          _StatChip(
                            icon: Icons.source_outlined,
                            label: 'Источники',
                            count: data['sources'] ?? 0,
                            color: Colors.purple,
                          ),
                          _StatChip(
                            icon: Icons.description_outlined,
                            label: 'Задачи',
                            count: data['problems'] ?? 0,
                            color: Colors.orange,
                          ),
                          _StatChip(
                            icon: Icons.edit_note,
                            label: 'Решения',
                            count: data['solutions'] ?? 0,
                            color: Colors.green,
                          ),
                          _StatChip(
                            icon: Icons.merge_type,
                            label: 'Дедуп',
                            count: data['dedup_candidates'] ?? 0,
                            color: Colors.teal,
                          ),
                        ],
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Text('Ошибка загрузки статистики'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Moderation section
            Text(
              'Модерация',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            _AdminTile(
              icon: Icons.label_outline,
              title: '🏷️ Теги',
              subtitle: 'Модерация тегов',
              color: Colors.blue,
              onTap: () => context.push('/admin/tags'),
            ),
            _AdminTile(
              icon: Icons.source_outlined,
              title: '📚 Источники',
              subtitle: 'Модерация источников задач',
              color: Colors.purple,
              onTap: () => context.push('/admin/sources'),
            ),
            _AdminTile(
              icon: Icons.description_outlined,
              title: '📝 Задачи',
              subtitle: 'Модерация задач',
              color: Colors.orange,
              onTap: () => context.push('/admin/problems'),
            ),
            _AdminTile(
              icon: Icons.edit_note,
              title: '✍️ Решения',
              subtitle: 'Модерация решений',
              color: Colors.green,
              onTap: () => context.push('/admin/solutions'),
            ),
            const SizedBox(height: 24),

            // Concepts section
            Text(
              'Концепты',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            _AdminTile(
              icon: Icons.auto_fix_high,
              title: '🧹 Дедупликация',
              subtitle: 'Запуск и верификация дубликатов',
              color: Colors.teal,
              onTap: () => context.push('/admin/dedup'),
            ),
            _AdminTile(
              icon: Icons.account_tree_outlined,
              title: '📊 Мониторинг концептов',
              subtitle: 'Просмотр базы концептов с алиасами',
              color: Colors.indigo,
              onTap: () => context.push('/admin/concepts'),
            ),
            _AdminTile(
              icon: Icons.build_circle_outlined,
              title: '🔧 Исправить циклы',
              subtitle: 'Исправление циклических ссылок в алиасах',
              color: Colors.red,
              onTap: () => _fixCycles(context, ref),
            ),
            const SizedBox(height: 24),

            // Tools section
            Text(
              'Инструменты',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            _AdminTile(
              icon: Icons.merge_type,
              title: '🔗 Объединить теги',
              subtitle: 'Ручное объединение тегов',
              color: Colors.blueGrey,
              onTap: () => _showMergeTagsDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fixCycles(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Исправить циклы'),
        content: const Text('Найти и исправить циклические ссылки в алиасах концептов?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Исправить'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final dedupNotifier = ref.read(dedupNotifierProvider.notifier);
      final count = await dedupNotifier.fixCycles();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Исправлено циклов: $count')),
        );
      }
    }
  }

  Future<void> _showMergeTagsDialog(BuildContext context, WidgetRef ref) async {
    final targetController = TextEditingController();
    final sourcesController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🔗 Объединить теги'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: targetController,
              decoration: const InputDecoration(
                labelText: 'Target Tag ID',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: sourcesController,
              decoration: const InputDecoration(
                labelText: 'Source Tag IDs (через запятую)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Объединить'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      final targetId = int.tryParse(targetController.text);
      final sourceIds = sourcesController.text
          .split(',')
          .map((s) => int.tryParse(s.trim()))
          .whereType<int>()
          .toList();

      if (targetId != null && sourceIds.isNotEmpty) {
        final repo = ref.read(adminRepositoryProvider);
        final result = await repo.mergeTags(targetId, sourceIds);
        if (context.mounted) {
          if (result != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Теги успешно объединены')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ошибка объединения'), backgroundColor: Colors.red),
            );
          }
        }
      }
    }
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: $count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
