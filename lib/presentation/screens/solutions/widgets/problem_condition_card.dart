import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/artifacts.dart';
import '../../../providers/problems_provider.dart';
import '../../../widgets/shared/markdown_with_math.dart';
import '../../../widgets/shared/image_viewer.dart';

/// Problem condition card - loads full problem data
class ProblemConditionCard extends ConsumerWidget {
  final int problemId;

  const ProblemConditionCard({
    super.key,
    required this.problemId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final problem = ref.watch(problemProvider(problemId));

    return problem.when(
      data: (prob) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.description_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Условие задачи',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      prob.displayTitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (prob.hasText)
                MarkdownWithMath(
                  text: prob.conditionText!,
                  textStyle: Theme.of(context).textTheme.bodyLarge,
                )
              else if (prob.hasImage)
                ConditionImageThumbnail(
                  problemId: problemId,
                  title: 'Условие: ${prob.reference}',
                  height: 200,
                )
              else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Условие не добавлено',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      loading: () => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.description_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Условие задачи',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
      error: (_, __) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.description_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Условие задачи',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Ошибка загрузки условия',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
