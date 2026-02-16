import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/artifacts.dart';
import '../../providers/problems_provider.dart';
import '../../providers/solutions_provider.dart';
import '../../providers/ocr_provider.dart';
import '../../widgets/shared/persona_selector.dart';
import '../../widgets/shared/markdown_with_math.dart';

/// Problem detail screen
class ProblemDetailScreen extends ConsumerStatefulWidget {
  final int problemId;

  const ProblemDetailScreen({super.key, required this.problemId});

  @override
  ConsumerState<ProblemDetailScreen> createState() => _ProblemDetailScreenState();
}

class _ProblemDetailScreenState extends ConsumerState<ProblemDetailScreen> {
  bool _isLoading = false;
  bool _ocrLoading = false;
  String? _ocrText;

  Future<void> _runOcr() async {
    final persona = await showPersonaSheet(
      context,
      defaultPersona: PersonaId.petrovich,
    );
    if (persona == null) return;

    setState(() => _ocrLoading = true);
    try {
      final result = await ref.read(ocrNotifierProvider.notifier).processProblem(
        problemId: widget.problemId,
        persona: persona,
      );
      if (result.success && result.text != null) {
        setState(() => _ocrText = result.text);
        // Refresh problem to get updated text
        ref.invalidate(problemProvider(widget.problemId));
      } else if (result.error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка OCR: ${result.error}')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _ocrLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final problem = ref.watch(problemProvider(widget.problemId));
    final solutions = ref.watch(problemSolutionsProvider(widget.problemId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Задача'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            onPressed: () {
              context.push('/camera?category=condition&entityId=${widget.problemId}');
            },
          ),
        ],
      ),
      body: problem.when(
        data: (data) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Source and reference
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      data.sourceName,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    data.reference,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Tags
              if (data.tags.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: data.tags.map((tag) {
                    return Chip(
                      label: Text(tag.name),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Condition
              Card(
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
                            'Условие',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          if (data.hasImage && !data.hasText)
                            TextButton.icon(
                              onPressed: _ocrLoading
                                  ? null
                                  : _runOcr,
                              icon: _ocrLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.auto_awesome, size: 18),
                              label: Text(_ocrLoading ? 'OCR...' : 'OCR'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (data.hasText)
                        MarkdownWithMath(
                          text: data.conditionText!,
                          textStyle: Theme.of(context).textTheme.bodyLarge,
                        )
                      else if (_ocrText != null)
                        MarkdownWithMath(
                          text: _ocrText!,
                          textStyle: Theme.of(context).textTheme.bodyLarge,
                        )
                      else if (data.hasImage)
                        GestureDetector(
                          onTap: () {
                            // TODO: Open fullscreen image
                          },
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(Icons.image, size: 48),
                            ),
                          ),
                        )
                      else
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.image_not_supported_outlined,
                                size: 48,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Добавьте фото или текст условия',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Solutions
              Text(
                'Решения',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              solutions.when(
                data: (solutionList) {
                  if (solutionList.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 48,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Нет решений',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: solutionList.map((solution) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            solution.isActive
                                ? Icons.timer
                                : Icons.check_circle,
                            color: solution.isActive
                                ? Colors.green
                                : Colors.blue,
                          ),
                          title: Text(
                            solution.statusText,
                          ),
                          subtitle: Text(
                            '${solution.totalMinutes.toStringAsFixed(0)} мин • ${solution.xpEarned?.toStringAsFixed(0) ?? 0} XP',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            if (solution.isActive) {
                              context.push(
                                  '/session/${solution.id}?existingMinutes=${solution.totalMinutes}');
                            }
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox(),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(problemProvider(widget.problemId)),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading
            ? null
            : () async {
                setState(() => _isLoading = true);
                try {
                  final solution = await ref
                      .read(solutionNotifierProvider.notifier)
                      .createSolution(widget.problemId);
                  if (solution != null && mounted) {
                    context.push('/session/${solution.id}');
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_arrow),
        label: Text(_isLoading ? 'Создание...' : 'Решать'),
      ),
    );
  }
}
