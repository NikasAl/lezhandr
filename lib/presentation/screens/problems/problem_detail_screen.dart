import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/artifacts.dart';
import '../../providers/problems_provider.dart';
import '../../providers/solutions_provider.dart';
import '../../providers/ocr_provider.dart';
import '../../widgets/shared/persona_selector.dart';
import '../../widgets/shared/markdown_with_math.dart';
import '../../widgets/shared/image_viewer.dart';

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
  bool _showConditionImage = false;

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
                          // OCR button (only if has image but no text)
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
                          // Show image button (if has both text and image)
                          if (data.hasText && data.hasImage)
                            TextButton.icon(
                              onPressed: () {
                                setState(() => _showConditionImage = !_showConditionImage);
                              },
                              icon: Icon(
                                _showConditionImage ? Icons.text_fields : Icons.image_outlined,
                                size: 18,
                              ),
                              label: Text(_showConditionImage ? 'Текст' : 'Фото'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Content: text, image, or both
                      if (data.hasText && !_showConditionImage) ...[
                        // Show text condition
                        MarkdownWithMath(
                          text: data.conditionText!,
                          textStyle: Theme.of(context).textTheme.bodyLarge,
                        ),
                        // If also has image, show small button to view it
                        if (data.hasImage) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ImageViewerScreen(
                                    category: 'condition',
                                    entityId: widget.problemId,
                                    title: 'Условие: ${data.reference}',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.photo_outlined, size: 18),
                            label: const Text('Посмотреть фото условия'),
                          ),
                        ],
                      ] else if (data.hasImage) ...[
                        // Show image condition
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ImageViewerScreen(
                                  category: 'condition',
                                  entityId: widget.problemId,
                                  title: 'Условие: ${data.reference}',
                                ),
                              ),
                            );
                          },
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: ConditionImageThumbnail(
                                  problemId: widget.problemId,
                                  title: 'Условие: ${data.reference}',
                                  height: 250,
                                ),
                              ),
                              // Zoom indicator overlay
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.zoom_in, color: Colors.white, size: 18),
                                      SizedBox(width: 4),
                                      Text(
                                        'Увеличить',
                                        style: TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Show text toggle if also has text
                        if (data.hasText && _showConditionImage) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              setState(() => _showConditionImage = false);
                            },
                            icon: const Icon(Icons.text_fields, size: 18),
                            label: const Text('Показать текст'),
                          ),
                        ],
                      ] else if (_ocrText != null) ...[
                        // Show OCR result
                        MarkdownWithMath(
                          text: _ocrText!,
                          textStyle: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ] else ...[
                        // No content
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
                                : solution.isCompleted
                                    ? Icons.check_circle
                                    : Icons.pause_circle,
                            color: solution.isActive
                                ? Colors.green
                                : solution.isCompleted
                                    ? Colors.blue
                                    : Colors.orange,
                          ),
                          title: Text(
                            solution.statusText,
                          ),
                          subtitle: Row(
                            children: [
                              Text(
                                '${solution.totalMinutes.toStringAsFixed(0)} мин',
                              ),
                              if (solution.xpEarned != null) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.star, size: 14, color: Colors.amber[700]),
                                Text(
                                  ' ${solution.xpEarned!.toStringAsFixed(0)} XP',
                                  style: TextStyle(color: Colors.amber[700]),
                                ),
                              ],
                              if (solution.hasText) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.article, size: 14, color: Colors.grey),
                              ],
                              if (solution.hasImage) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.photo, size: 14, color: Colors.grey),
                              ],
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            if (solution.isActive) {
                              // Active solution -> go to session
                              context.push(
                                  '/session/${solution.id}?existingMinutes=${solution.totalMinutes}');
                            } else {
                              // Completed/abandoned solution -> go to detail view
                              context.push('/solutions/${solution.id}');
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
