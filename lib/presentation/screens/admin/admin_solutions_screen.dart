import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/admin_provider.dart';

/// Solutions moderation screen
class AdminSolutionsScreen extends ConsumerWidget {
  const AdminSolutionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(solutionsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('✍️ Модерация решений'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(solutionsNotifierProvider.notifier).load(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Ошибка: ${state.error}'))
              : state.solutions.isEmpty
                  ? const Center(child: Text('📭 Нет решений на модерации'))
                  : Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Row(
                            children: [
                              Text('📊 Решений: ${state.total}'),
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
                            itemCount: state.solutions.length,
                            itemBuilder: (context, index) {
                              final solution = state.solutions[index];
                              return _SolutionTile(solution: solution);
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
        content: Text('Одобрить все ${ref.read(solutionsNotifierProvider).solutions.length} решений?'),
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
      final count = await ref.read(solutionsNotifierProvider.notifier).approveAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Одобрено: $count решений')),
        );
      }
    }
  }
}

class _SolutionTile extends ConsumerWidget {
  final AdminSolution solution;

  const _SolutionTile({required this.solution});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = solution.status == 'completed'
        ? Colors.green
        : solution.status == 'in_progress'
            ? Colors.blue
            : Colors.orange;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '#${solution.id}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Icons for text/image
                Icon(
                  Icons.text_snippet_outlined,
                  size: 16,
                  color: solution.solutionText != null ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.image_outlined,
                  size: 16,
                  color: solution.hasImage ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    solution.status,
                    style: TextStyle(color: statusColor, fontSize: 12),
                  ),
                ),
              ],
            ),
            
            // Problem info
            if (solution.problem != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.assignment_outlined, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${solution.problem!.source?.name ?? "???"}: ${solution.problem!.reference ?? "#${solution.problem!.id}"}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ],
            
            // Solution preview
            if (solution.solutionText != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  solution.solutionText!.length > 150
                      ? '${solution.solutionText!.substring(0, 150)}...'
                      : solution.solutionText!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
            
            // Author
            if (solution.addedBy != null) ...[
              const SizedBox(height: 4),
              Text(
                '👤 ${solution.addedBy!.displayName}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            
            // Actions
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Удалить'),
                  onPressed: () => _delete(context, ref),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.close, color: Colors.orange),
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
    final result = await ref.read(solutionsNotifierProvider.notifier).approve(solution.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ? 'Решение #${solution.id} одобрено' : 'Ошибка'),
          backgroundColor: result ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(solutionsNotifierProvider.notifier).reject(solution.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ? 'Решение #${solution.id} отклонено' : 'Ошибка'),
          backgroundColor: result ? Colors.orange : Colors.red,
        ),
      );
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить решение?'),
        content: const Text('Это действие необратимо. Будут удалены все связанные данные.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final result = await ref.read(solutionsNotifierProvider.notifier).delete(solution.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result ? 'Решение #${solution.id} удалено' : 'Ошибка'),
            backgroundColor: result ? Colors.red : Colors.grey,
          ),
        );
      }
    }
  }
}
