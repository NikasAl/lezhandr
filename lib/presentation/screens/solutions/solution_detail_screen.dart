import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/solution.dart';
import '../../../data/models/artifacts.dart';
import '../../providers/solutions_provider.dart';
import '../../providers/artifacts_provider.dart';
import '../../providers/ocr_provider.dart';
import '../../widgets/shared/persona_selector.dart';
import '../../widgets/shared/markdown_with_math.dart';
import '../../widgets/shared/image_viewer.dart';

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

                // Solution photo section - using authorized image loading
                if (sol.hasImage) ...[
                  Card(
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
                          SolutionImageThumbnail(
                            solutionId: widget.solutionId,
                            title: 'Фото решения',
                            height: 250,
                          ),
                        ],
                      ),
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
              return _EpiphanyItem(epiphany: e);
            }).toList(),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Expandable epiphany item
class _EpiphanyItem extends StatefulWidget {
  final EpiphanyModel epiphany;

  const _EpiphanyItem({required this.epiphany});

  @override
  State<_EpiphanyItem> createState() => _EpiphanyItemState();
}

class _EpiphanyItemState extends State<_EpiphanyItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final description = widget.epiphany.description ?? '';
    final isLongText = description.length > 100;
    
    return InkWell(
      onTap: isLongText ? () => setState(() => _isExpanded = !_isExpanded) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Star icon with magnitude
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.star,
                color: Colors.amber,
                size: 16 + (widget.epiphany.magnitude ?? 1) * 4,
              ),
            ),
            const SizedBox(width: 12),
            // Description text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownWithMath(
                    text: description,
                    maxLines: _isExpanded ? null : 2,
                    overflow: _isExpanded ? null : TextOverflow.ellipsis,
                    textStyle: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (isLongText) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: Text(
                        _isExpanded ? 'Свернуть' : 'Развернуть',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
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
              return _QuestionItem(question: q);
            }).toList(),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Expandable question item
class _QuestionItem extends StatefulWidget {
  final QuestionModel question;

  const _QuestionItem({required this.question});

  @override
  State<_QuestionItem> createState() => _QuestionItemState();
}

class _QuestionItemState extends State<_QuestionItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final body = widget.question.body ?? '';
    final answer = widget.question.answer;
    final isLongText = body.length > 100 || (answer != null && answer.length > 100);
    
    return InkWell(
      onTap: isLongText ? () => setState(() => _isExpanded = !_isExpanded) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              widget.question.hasAnswer ? Icons.check_circle : Icons.help,
              color: widget.question.hasAnswer ? Colors.green : Colors.orange,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question body
                  MarkdownWithMath(
                    text: body,
                    maxLines: _isExpanded ? null : 2,
                    overflow: _isExpanded ? null : TextOverflow.ellipsis,
                    textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // Answer if exists
                  if (answer != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ответ:',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          MarkdownWithMath(
                            text: answer,
                            maxLines: _isExpanded ? null : 2,
                            overflow: _isExpanded ? null : TextOverflow.ellipsis,
                            textStyle: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    Text(
                      'Нет ответа',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  // Expand/collapse button
                  if (isLongText) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: Text(
                        _isExpanded ? 'Свернуть' : 'Развернуть',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
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
              return _HintItem(hint: h);
            }).toList(),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Expandable hint item
class _HintItem extends StatefulWidget {
  final HintModel hint;

  const _HintItem({required this.hint});

  @override
  State<_HintItem> createState() => _HintItemState();
}

class _HintItemState extends State<_HintItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final userNotes = widget.hint.userNotes ?? '';
    final hintText = widget.hint.hintText;
    final isLongText = userNotes.length > 100 || (hintText != null && hintText.length > 100);
    
    return InkWell(
      onTap: isLongText ? () => setState(() => _isExpanded = !_isExpanded) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              widget.hint.hasHint ? Icons.check_circle : Icons.hourglass_empty,
              color: widget.hint.hasHint ? Colors.green : Colors.orange,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User notes
                  if (userNotes.isNotEmpty) ...[
                    Text(
                      userNotes,
                      maxLines: _isExpanded ? null : 2,
                      overflow: _isExpanded ? null : TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Подсказка',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  // AI-generated hint text
                  if (hintText != null && hintText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.hint.aiModel != null) ...[
                            Text(
                              'AI: ${widget.hint.aiModel}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          MarkdownWithMath(
                            text: hintText,
                            maxLines: _isExpanded ? null : 3,
                            overflow: _isExpanded ? null : TextOverflow.ellipsis,
                            textStyle: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Expand/collapse button
                  if (isLongText) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: Text(
                        _isExpanded ? 'Свернуть' : 'Развернуть',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
