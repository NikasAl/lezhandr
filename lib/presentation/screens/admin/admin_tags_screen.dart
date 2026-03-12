import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/admin_provider.dart';

/// Tags moderation screen
class AdminTagsScreen extends ConsumerWidget {
  const AdminTagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tagsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🏷️ Модерация тегов'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(tagsNotifierProvider.notifier).load(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Ожидают'),
                  selected: state.statusFilter == 'pending',
                  onSelected: (_) =>
                      ref.read(tagsNotifierProvider.notifier).load(statusFilter: 'pending'),
                ),
                FilterChip(
                  label: const Text('Одобрены'),
                  selected: state.statusFilter == 'approved',
                  onSelected: (_) =>
                      ref.read(tagsNotifierProvider.notifier).load(statusFilter: 'approved'),
                ),
                FilterChip(
                  label: const Text('Отклонены'),
                  selected: state.statusFilter == 'rejected',
                  onSelected: (_) =>
                      ref.read(tagsNotifierProvider.notifier).load(statusFilter: 'rejected'),
                ),
              ],
            ),
          ),
          
          // Stats
          if (state.tags.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Text('📊 Тегов: ${state.tags.length}'),
                  const Spacer(),
                  if (state.statusFilter == 'pending')
                    TextButton.icon(
                      icon: const Icon(Icons.done_all),
                      label: const Text('Одобрить все'),
                      onPressed: () => _approveAll(context, ref),
                    ),
                ],
              ),
            ),

          // List
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(child: Text('Ошибка: ${state.error}'))
                    : state.tags.isEmpty
                        ? const Center(child: Text('📭 Нет тегов'))
                        : ListView.builder(
                            itemCount: state.tags.length,
                            itemBuilder: (context, index) {
                              final tag = state.tags[index];
                              return _TagTile(tag: tag);
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
        content: Text('Одобрить все ${ref.read(tagsNotifierProvider).tags.length} тегов?'),
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
      final count = await ref.read(tagsNotifierProvider.notifier).approveAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Одобрено: $count тегов')),
        );
      }
    }
  }
}

class _TagTile extends ConsumerWidget {
  final AdminTag tag;

  const _TagTile({required this.tag});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = tag.moderationStatus == 'approved'
        ? Colors.green
        : tag.moderationStatus == 'rejected'
            ? Colors.red
            : Colors.orange;

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
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '#${tag.id}',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tag.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    tag.moderationStatus,
                    style: TextStyle(color: statusColor, fontSize: 12),
                  ),
                ),
              ],
            ),
            if (tag.addedBy != null) ...[
              const SizedBox(height: 4),
              Text(
                '👤 ${tag.addedBy!.displayName}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (tag.moderationStatus == 'pending') ...[
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
          ],
        ),
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(tagsNotifierProvider.notifier).approve(tag.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ? 'Тег "${tag.name}" одобрен' : 'Ошибка'),
          backgroundColor: result ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(tagsNotifierProvider.notifier).reject(tag.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ? 'Тег "${tag.name}" отклонён' : 'Ошибка'),
          backgroundColor: result ? Colors.orange : Colors.red,
        ),
      );
    }
  }
}
