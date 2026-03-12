import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_provider.dart';
import '../../../data/repositories/admin_repository.dart';

/// Problems moderation screen
class AdminProblemsScreen extends ConsumerWidget {
  const AdminProblemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(problemsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('📝 Модерация задач'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(problemsNotifierProvider.notifier).load(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Ошибка: ${state.error}'))
              : state.problems.isEmpty
                  ? const Center(child: Text('📭 Нет задач на модерации'))
                  : Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Row(
                            children: [
                              Text('📊 Задач: ${state.total}'),
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
                            itemCount: state.problems.length,
                            itemBuilder: (context, index) {
                              final problem = state.problems[index];
                              return _ProblemTile(problem: problem);
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
        content: Text('Одобрить все ${ref.read(problemsNotifierProvider).problems.length} задач?'),
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
      final count = await ref.read(problemsNotifierProvider.notifier).approveAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Одобрено: $count задач')),
        );
      }
    }
  }
}

class _ProblemTile extends ConsumerWidget {
  final AdminProblem problem;

  const _ProblemTile({required this.problem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '#${problem.id}',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Icons for text/image
                Icon(
                  Icons.text_snippet_outlined,
                  size: 16,
                  color: problem.conditionText != null ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.image_outlined,
                  size: 16,
                  color: problem.hasImage ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    problem.source?.name ?? 'Без источника',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                if (problem.reference != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      problem.reference!,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            ),
            
            // Condition preview
            if (problem.conditionText != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  problem.conditionText!.length > 150
                      ? '${problem.conditionText!.substring(0, 150)}...'
                      : problem.conditionText!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
            
            // Author
            if (problem.addedBy != null) ...[
              const SizedBox(height: 4),
              Text(
                '👤 ${problem.addedBy!.displayName}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            
            // Actions
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
    final result = await ref.read(problemsNotifierProvider.notifier).approve(problem.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ? 'Задача #${problem.id} одобрена' : 'Ошибка'),
          backgroundColor: result ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(problemsNotifierProvider.notifier).reject(problem.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ? 'Задача #${problem.id} отклонена' : 'Ошибка'),
          backgroundColor: result ? Colors.orange : Colors.red,
        ),
      );
    }
  }
}
