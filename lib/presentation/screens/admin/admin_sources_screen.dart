import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/admin_provider.dart';

/// Sources moderation screen
class AdminSourcesScreen extends ConsumerWidget {
  const AdminSourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sourcesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 Модерация источников'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(sourcesNotifierProvider.notifier).load(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Ошибка: ${state.error}'))
              : state.sources.isEmpty
                  ? const Center(child: Text('📭 Нет источников на модерации'))
                  : Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Row(
                            children: [
                              Text('📊 Источников: ${state.sources.length}'),
                              const Spacer(),
                              TextButton.icon(
                                icon: const Icon(Icons.done_all),
                                label: const Text('Одобрить все'),
                                onPressed: () => _approveAll(context, ref),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: state.sources.length,
                            itemBuilder: (context, index) {
                              final source = state.sources[index];
                              return _SourceTile(source: source);
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }

  Future<void> _approveAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Одобрить все?'),
        content: Text('Одобрить все ${ref.read(sourcesNotifierProvider).sources.length} источников?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Одобрить'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final count = await ref.read(sourcesNotifierProvider.notifier).approveAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Одобрено: $count источников')),
        );
      }
    }
  }
}

class _SourceTile extends ConsumerWidget {
  final AdminSource source;

  const _SourceTile({required this.source});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '#${source.id}',
                    style: const TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        source.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (source.slug != null)
                        Text(
                          source.slug!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (source.addedBy != null) ...[
              const SizedBox(height: 4),
              Text(
                '👤 ${source.addedBy!.displayName}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text('Отклонить'),
                  onPressed: () => _reject(context, ref),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Одобрить'),
                  onPressed: () => _approve(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(sourcesNotifierProvider.notifier).approve(source.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ? '"${source.name}" одобрен' : 'Ошибка'),
          backgroundColor: result ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(sourcesNotifierProvider.notifier).reject(source.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ? '"${source.name}" отклонён' : 'Ошибка'),
          backgroundColor: result ? Colors.orange : Colors.red,
        ),
      );
    }
  }
}
