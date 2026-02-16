import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../data/models/solution.dart';
import '../../../data/models/artifacts.dart';
import '../../providers/solutions_provider.dart';
import '../../providers/artifacts_provider.dart';
import '../../providers/ocr_provider.dart';
import '../../widgets/shared/persona_selector.dart';
import '../../widgets/shared/markdown_with_math.dart';

/// Solution detail screen for viewing completed or active solution
class SolutionDetailScreen extends ConsumerStatefulWidget {
  final int solutionId;

  const SolutionDetailScreen({super.key, required this.solutionId});

  @override
  ConsumerState<SolutionDetailScreen> createState() => _SolutionDetailScreenState();
}

class _SolutionDetailScreenState extends ConsumerState<SolutionDetailScreen> {
  bool _ocrLoading = false;
  bool _isEditing = false;
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String _getImageUrl(String category, int entityId) {
    return '${AppConfig.apiUrl}/images/$category/$entityId';
  }

  Future<void> _runOcr() async {
    final persona = await showPersonaSheet(
      context,
      defaultPersona: PersonaId.petrovich,
    );
    if (persona == null) return;

    setState(() => _ocrLoading = true);
    try {
      final result = await ref.read(ocrNotifierProvider.notifier).processSolution(
        solutionId: widget.solutionId,
        persona: persona,
      );
      if (result.success && result.text != null) {
        // Refresh solution to get updated text
        ref.invalidate(solutionProvider(widget.solutionId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OCR завершён! Текст распознан.')),
          );
        }
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

  Future<void> _saveSolutionText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final success = await ref
        .read(solutionNotifierProvider.notifier)
        .updateSolutionText(widget.solutionId, text);

    if (success && mounted) {
      setState(() => _isEditing = false);
      ref.invalidate(solutionProvider(widget.solutionId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Текст решения сохранён')),
      );
    }
  }

  void _openFullScreenImage(String url, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenImageView(
          imageUrl: url,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final solution = ref.watch(solutionProvider(widget.solutionId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Решение #${widget.solutionId}'),
        actions: [
          // OCR button
          IconButton(
            icon: _ocrLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            onPressed: _ocrLoading ? null : _runOcr,
            tooltip: 'OCR',
          ),
          // Edit button
          IconButton(
            icon: Icon(_isEditing ? Icons.visibility : Icons.edit),
            onPressed: () {
              setState(() => _isEditing = !_isEditing);
              if (_isEditing) {
                final sol = solution.valueOrNull;
                _textController.text = sol?.solutionText ?? '';
              }
            },
            tooltip: _isEditing ? 'Просмотр' : 'Редактировать',
          ),
        ],
      ),
      body: solution.when(
        data: (sol) {
          if (sol == null) {
            return const Center(child: Text('Решение не найдено'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status card
                _StatusCard(solution: sol),
                const SizedBox(height: 16),

                // Problem reference
                if (sol.problem != null) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(sol.problem!.displayTitle),
                      subtitle: Text(sol.problem!.sourceName),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/problems/${sol.problem!.id}'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Solution text section
                _SolutionTextSection(
                  solution: sol,
                  isEditing: _isEditing,
                  controller: _textController,
                  onSave: _saveSolutionText,
                ),
                const SizedBox(height: 16),

                // Solution photo section
                if (sol.hasImage) ...[
                  _SolutionPhotoSection(
                    solution: sol,
                    imageUrl: _getImageUrl('solution', widget.solutionId),
                    onTap: () => _openFullScreenImage(
                      _getImageUrl('solution', widget.solutionId),
                      'Фото решения',
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Artifacts sections
                _EpiphaniesSection(solutionId: widget.solutionId),
                const SizedBox(height: 8),
                _QuestionsSection(solutionId: widget.solutionId),
                const SizedBox(height: 8),
                _HintsSection(solutionId: widget.solutionId),
              ],
            ),
          );
        },
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
                    ref.invalidate(solutionProvider(widget.solutionId)),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Status card showing solution status and stats
class _StatusCard extends StatelessWidget {
  final SolutionModel solution;

  const _StatusCard({required this.solution});

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
                Icon(
                  solution.isCompleted
                      ? Icons.check_circle
                      : solution.isActive
                          ? Icons.timer
                          : Icons.pause_circle,
                  color: solution.isCompleted
                      ? Colors.green
                      : solution.isActive
                          ? Colors.blue
                          : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  solution.statusText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatChip(
                  icon: Icons.timer_outlined,
                  label: '${solution.totalMinutes.toStringAsFixed(0)} мин',
                ),
                const SizedBox(width: 12),
                if (solution.xpEarned != null)
                  _StatChip(
                    icon: Icons.star,
                    label: '${solution.xpEarned!.toStringAsFixed(0)} XP',
                    color: Colors.amber,
                  ),
                if (solution.personalDifficulty != null) ...[
                  const SizedBox(width: 12),
                  _StatChip(
                    icon: Icons.fitness_center,
                    label: 'Сложность: ${solution.personalDifficulty}',
                  ),
                ],
              ],
            ),
            if (solution.userNotes != null && solution.userNotes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Заметки: ${solution.userNotes}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Stat chip widget
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _StatChip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? Theme.of(context).colorScheme.primary).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ?? Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Solution text section with edit capability
class _SolutionTextSection extends StatelessWidget {
  final SolutionModel solution;
  final bool isEditing;
  final TextEditingController controller;
  final VoidCallback onSave;

  const _SolutionTextSection({
    required this.solution,
    required this.isEditing,
    required this.controller,
    required this.onSave,
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
                const Icon(Icons.article_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Текст решения',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (!solution.hasText && solution.hasImage)
                  Text(
                    'Нет текста',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (isEditing)
              Column(
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Введите текст решения...',
                    ),
                    maxLines: 8,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          controller.text = solution.solutionText ?? '';
                        },
                        child: const Text('Сбросить'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: onSave,
                        icon: const Icon(Icons.save, size: 18),
                        label: const Text('Сохранить'),
                      ),
                    ],
                  ),
                ],
              )
            else if (solution.hasText)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: MarkdownWithMath(
                  text: solution.solutionText!,
                  textStyle: Theme.of(context).textTheme.bodyLarge,
                ),
              )
            else
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.edit_note,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Текст решения отсутствует',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    if (solution.hasImage)
                      Text(
                        'Используйте OCR для распознавания',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Solution photo section
class _SolutionPhotoSection extends StatelessWidget {
  final SolutionModel solution;
  final String imageUrl;
  final VoidCallback onTap;

  const _SolutionPhotoSection({
    required this.solution,
    required this.imageUrl,
    required this.onTap,
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
                const Icon(Icons.photo_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Фото решения',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 48,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ошибка загрузки',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.fullscreen),
                label: const Text('Открыть на весь экран'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Epiphanies section widget
class _EpiphaniesSection extends ConsumerWidget {
  final int solutionId;

  const _EpiphaniesSection({required this.solutionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final epiphanies = ref.watch(epiphaniesProvider(solutionId));

    return epiphanies.when(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();

        return Card(
          child: ExpansionTile(
            leading: const Icon(Icons.lightbulb_outline, color: Colors.amber),
            title: Text('Озарения (${list.length})'),
            children: list.map((e) {
              return ListTile(
                leading: Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 16 + (e.magnitude ?? 1) * 4,
                ),
                title: Text(
                  e.description ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Questions section widget
class _QuestionsSection extends ConsumerWidget {
  final int solutionId;

  const _QuestionsSection({required this.solutionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questions = ref.watch(questionsProvider(solutionId));

    return questions.when(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();

        return Card(
          child: ExpansionTile(
            leading: Icon(
              Icons.help_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text('Вопросы (${list.length})'),
            children: list.map((q) {
              return ListTile(
                leading: Icon(
                  q.hasAnswer ? Icons.check_circle : Icons.help,
                  color: q.hasAnswer ? Colors.green : Colors.orange,
                  size: 20,
                ),
                title: Text(
                  q.body ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: q.hasAnswer
                    ? Text(
                        q.answer!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : const Text('Нет ответа'),
              );
            }).toList(),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Hints section widget
class _HintsSection extends ConsumerWidget {
  final int solutionId;

  const _HintsSection({required this.solutionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hints = ref.watch(hintsProvider(solutionId));

    return hints.when(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();

        return Card(
          child: ExpansionTile(
            leading: Icon(
              Icons.lightbulb_outline,
              color: Theme.of(context).colorScheme.secondary,
            ),
            title: Text('Подсказки (${list.length})'),
            children: list.map((h) {
              return ListTile(
                leading: Icon(
                  h.hasHint ? Icons.check_circle : Icons.hourglass_empty,
                  color: h.hasHint ? Colors.green : Colors.orange,
                  size: 20,
                ),
                title: Text(
                  h.userNotes ?? 'Подсказка',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: h.aiModel != null ? Text('AI: ${h.aiModel}') : null,
              );
            }).toList(),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Full screen image viewer
class _FullScreenImageView extends StatelessWidget {
  final String imageUrl;
  final String title;

  const _FullScreenImageView({
    required this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ошибка загрузки изображения',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
