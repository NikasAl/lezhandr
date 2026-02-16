import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/motivation/motivation_engine.dart';
import '../../../core/motivation/motivation_models.dart';
import '../../../data/models/solution.dart';
import '../../../data/models/artifacts.dart';
import '../../providers/solutions_provider.dart';
import '../../providers/artifacts_provider.dart';
import '../../providers/ocr_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../widgets/motivation/motivation_card.dart';
import '../../widgets/shared/persona_selector.dart';
import '../../widgets/shared/markdown_with_math.dart';

/// Solution session screen - interactive solving session
class SolutionSessionScreen extends ConsumerStatefulWidget {
  final int solutionId;
  final double existingMinutes;

  const SolutionSessionScreen({
    super.key,
    required this.solutionId,
    this.existingMinutes = 0.0,
  });

  @override
  ConsumerState<SolutionSessionScreen> createState() =>
      _SolutionSessionScreenState();
}

class _SolutionSessionScreenState extends ConsumerState<SolutionSessionScreen> {
  late DateTime _startTime;
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _isFinished = false;

  int _difficulty = 3;
  double _quality = 1.0;
  final _notesController = TextEditingController();

  // Motivation caching
  final MotivationEngine _motivationEngine = MotivationEngine();
  MotivationText? _cachedMotivation;
  int _lastMotivationMinute = -1;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_isFinished) {
        setState(() {
          _elapsed = DateTime.now().difference(_startTime);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes;
    if (hours > 0) {
      final mins = minutes.remainder(60);
      return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
    }
    return '$minutes мин';
  }

  MotivationText? _getMotivation() {
    final currentMinute = _elapsed.inMinutes;
    if (_cachedMotivation == null || currentMinute != _lastMotivationMinute) {
      _cachedMotivation = _motivationEngine.getSessionStartText();
      _lastMotivationMinute = currentMinute;
    }
    return _cachedMotivation;
  }

  void _showEpiphanyDialog() {
    final controller = TextEditingController();
    int magnitude = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber),
              SizedBox(width: 8),
              Text('Озарение'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Опишите ваше озарение...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Сила:'),
                  const SizedBox(width: 8),
                  ...List.generate(3, (i) {
                    return IconButton(
                      icon: Icon(
                        Icons.star,
                        color: i < magnitude ? Colors.amber : Colors.grey,
                      ),
                      onPressed: () => setState(() => magnitude = i + 1),
                    );
                  }),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  final epiphany = await ref.read(epiphanyNotifierProvider.notifier).create(
                    solutionId: widget.solutionId,
                    description: controller.text,
                    magnitude: magnitude,
                  );

                  if (!mounted) return;
                  Navigator.pop(context);

                  // Refresh list
                  ref.invalidate(epiphaniesProvider(widget.solutionId));

                  // Offer to add image
                  if (epiphany?.id != null) {
                    final addImage = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Row(
                          children: [
                            Icon(Icons.lightbulb, color: Colors.amber),
                            SizedBox(width: 8),
                            Text('Озарение сохранено!'),
                          ],
                        ),
                        content: const Text('Добавить схему/рисунок?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Нет'),
                          ),
                          FilledButton.icon(
                            onPressed: () => Navigator.pop(context, true),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Добавить фото'),
                          ),
                        ],
                      ),
                    );

                    if (addImage == true && mounted) {
                      context.push('/camera?category=epiphany&entityId=${epiphany!.id}');
                    }
                  }
                } else {
                  Navigator.pop(context);
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuestionDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline),
            SizedBox(width: 8),
            Text('Вопрос'),
          ],
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Введите ваш вопрос...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final question = await ref.read(questionNotifierProvider.notifier).create(
                  solutionId: widget.solutionId,
                  body: controller.text,
                );
                if (!mounted) return;
                Navigator.pop(context);

                // Refresh list
                ref.invalidate(questionsProvider(widget.solutionId));

                // Offer to add image
                if (question?.id != null && mounted) {
                  final addImage = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Вопрос сохранён!'),
                      content: const Text('Добавить фото контекста?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Нет'),
                        ),
                        FilledButton.icon(
                          onPressed: () => Navigator.pop(context, true),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Добавить фото'),
                        ),
                      ],
                    ),
                  );

                  if (addImage == true && mounted) {
                    context.push('/camera?category=question&entityId=${question!.id}');
                  }
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  /// Show question detail dialog with answer and AI option
  void _showQuestionDetailDialog(QuestionModel question) {
    final answerController = TextEditingController(text: question.answer ?? '');
    bool isGenerating = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                question.hasAnswer ? Icons.check_circle : Icons.help,
                color: question.hasAnswer ? Colors.green : Colors.blue,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Вопрос', overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: MarkdownWithMath(
                      text: question.body ?? '',
                      textStyle: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Answer section
                  Row(
                    children: [
                      Icon(
                        Icons.reply,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ответ',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (question.hasAnswer)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: MarkdownWithMath(
                        text: question.answer!,
                        textStyle: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Ответ пока нет',
                            style: TextStyle(color: Colors.orange[700]),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Manual answer input
                  TextField(
                    controller: answerController,
                    decoration: const InputDecoration(
                      labelText: 'Ваш ответ',
                      hintText: 'Введите ответ вручную...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть'),
            ),
            if (!question.hasAnswer || answerController.text.isNotEmpty)
              TextButton.icon(
                onPressed: isGenerating
                    ? null
                    : () async {
                        setDialogState(() => isGenerating = true);
                        final persona = await showPersonaSheet(
                          context,
                          defaultPersona: PersonaId.basis,
                        );
                        if (persona != null && question.id != null) {
                          final result = await ref
                              .read(questionNotifierProvider.notifier)
                              .generateAnswer(
                                questionId: question.id!,
                                persona: persona,
                              );
                          if (result != null && mounted) {
                            Navigator.pop(context);
                            ref.invalidate(questionsProvider(widget.solutionId));
                            // Show the generated answer
                            _showQuestionDetailDialog(result);
                          }
                        }
                        setDialogState(() => isGenerating = false);
                      },
                icon: isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(isGenerating ? 'Генерация...' : 'Спросить AI'),
              ),
            FilledButton(
              onPressed: answerController.text.isEmpty
                  ? null
                  : () async {
                      final success = await ref
                          .read(questionNotifierProvider.notifier)
                          .answer(question.id!, answerController.text);
                      if (success && mounted) {
                        Navigator.pop(context);
                        ref.invalidate(questionsProvider(widget.solutionId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ответ сохранён')),
                        );
                      }
                    },
              child: const Text('Сохранить ответ'),
            ),
          ],
        ),
      ),
    );
  }

  void _showHintDialog() async {
    final notesController = TextEditingController();

    // First dialog: get user notes
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lightbulb_outline),
            SizedBox(width: 8),
            Text('Запросить подсказку'),
          ],
        ),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            labelText: 'В чём проблема?',
            hintText: 'Опишите, что не получается...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Далее'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Create hint draft
    final hint = await ref.read(hintNotifierProvider.notifier).createDraft(
          solutionId: widget.solutionId,
          userNotes: notesController.text,
        );

    // Refresh list
    ref.invalidate(hintsProvider(widget.solutionId));

    if (hint == null || hint.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось создать запрос подсказки')),
        );
      }
      return;
    }

    // Offer to add image
    if (mounted) {
      final addImage = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Запрос создан'),
          content: const Text('Добавить фото контекста?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Нет'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Добавить фото'),
            ),
          ],
        ),
      );

      if (addImage == true && mounted) {
        context.push('/camera?category=hint&entityId=${hint.id}');
      }
    }

    // Second dialog: select persona
    if (mounted) {
      final persona = await showPersonaSheet(
        context,
        defaultPersona: PersonaId.basis,
      );

      if (persona != null) {
        // Generate hint with selected persona
        final result = await ref.read(hintNotifierProvider.notifier).generate(
              hintId: hint.id!,
              persona: persona,
            );

        // Refresh list after generation
        ref.invalidate(hintsProvider(widget.solutionId));

        if (mounted) {
          if (result != null && result.hintText != null) {
            _showHintDetailDialog(result);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Не удалось получить подсказку. Проверьте баланс.')),
            );
          }
        }
      }
    }
  }

  /// Show hint detail dialog with full text and edit option
  void _showHintDetailDialog(HintModel hint) {
    final editController = TextEditingController(text: hint.hintText ?? '');
    bool isEditing = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                hint.isCompleted ? Icons.check_circle : Icons.hourglass_empty,
                color: hint.isCompleted ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Подсказка', overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User notes
                  if (hint.userNotes != null && hint.userNotes!.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.note_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ваши заметки',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(hint.userNotes!),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // AI model info
                  if (hint.aiModel != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.smart_toy_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI: ${hint.aiModel}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Hint text
                  if (hint.hasHint) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 18,
                          color: Colors.purple,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ответ AI',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    isEditing
                        ? TextField(
                            controller: editController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Текст подсказки...',
                            ),
                            maxLines: 6,
                          )
                        : Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.purple.withOpacity(0.3)),
                            ),
                            child: MarkdownWithMath(
                              text: hint.hintText!,
                              textStyle: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                  ] else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.hourglass_empty, color: Colors.orange[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Подсказка ещё не сгенерирована',
                            style: TextStyle(color: Colors.orange[700]),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть'),
            ),
            if (hint.hasHint)
              TextButton.icon(
                onPressed: () {
                  setDialogState(() => isEditing = !isEditing);
                },
                icon: Icon(isEditing ? Icons.visibility : Icons.edit_outlined),
                label: Text(isEditing ? 'Просмотр' : 'Редактировать'),
              ),
            if (isEditing)
              FilledButton(
                onPressed: () async {
                  final success = await ref
                      .read(hintNotifierProvider.notifier)
                      .updateText(hint.id!, editController.text);
                  if (success && mounted) {
                    Navigator.pop(context);
                    ref.invalidate(hintsProvider(widget.solutionId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Подсказка обновлена')),
                    );
                  }
                },
                child: const Text('Сохранить'),
              ),
          ],
        ),
      ),
    );
  }

  void _refreshHomeData({int? problemId}) {
    // Invalidate providers to refresh home screen data
    ref.invalidate(activeSolutionsProvider);
    ref.invalidate(gamificationMeProvider);
    // Invalidate solutions for the problem to refresh problem detail screen
    if (problemId != null) {
      ref.invalidate(problemSolutionsProvider(problemId));
    }
  }

  void _finishSession() {
    setState(() => _isFinished = true);
    _timer?.cancel();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Завершение сессии',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Время сессии: ${_formatDuration(_elapsed)}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                if (widget.existingMinutes > 0)
                  Text(
                    'Ранее: ${widget.existingMinutes.toStringAsFixed(0)} мин',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                const SizedBox(height: 24),

                // Two options
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          // Just save session time, keep active
                          await ref
                              .read(solutionNotifierProvider.notifier)
                              .createSession(
                                SessionCreate(
                                  solutionId: widget.solutionId,
                                  startTime: _startTime,
                                  endTime: DateTime.now(),
                                  duration: _elapsed.inMinutes.toDouble(),
                                ),
                              );
                          if (mounted) {
                            // Get problemId from solution for cache invalidation
                            final solutionAsync = ref.read(solutionProvider(widget.solutionId));
                            final problemId = solutionAsync.valueOrNull?.problemId;
                            _refreshHomeData(problemId: problemId);
                            Navigator.pop(context);
                            context.go('/main/home');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Сессия сохранена. Задача осталась активной.')),
                            );
                          }
                        },
                        icon: const Icon(Icons.pause),
                        label: const Text('Продолжить позже'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Finalize option
                ExpansionTile(
                  title: const Text('Завершить задачу'),
                  subtitle: const Text('Указать сложность и качество'),
                  childrenPadding: const EdgeInsets.only(top: 8, bottom: 16),
                  children: [
                    // Difficulty
                    Row(
                      children: [
                        const Text('Сложность: '),
                        ...List.generate(5, (i) {
                          final value = i + 1;
                          return IconButton(
                            icon: Icon(
                              Icons.star,
                              color: _difficulty >= value ? Colors.amber : Colors.grey,
                            ),
                            onPressed: () => setModalState(() => _difficulty = value),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quality
                    Row(
                      children: [
                        const Text('Качество:'),
                        Expanded(
                          child: Slider(
                            value: _quality,
                            min: 0.1,
                            max: 1.0,
                            divisions: 9,
                            label: _quality.toStringAsFixed(1),
                            onChanged: (value) => setModalState(() => _quality = value),
                          ),
                        ),
                        Text(_quality.toStringAsFixed(1)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Notes
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Заметки',
                        hintText: 'Ваши мысли о задаче...',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // Finalize button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          // Create session record
                          await ref
                              .read(solutionNotifierProvider.notifier)
                              .createSession(
                                SessionCreate(
                                  solutionId: widget.solutionId,
                                  startTime: _startTime,
                                  endTime: DateTime.now(),
                                  duration: _elapsed.inMinutes.toDouble(),
                                ),
                              );

                          // Finish solution
                          final result = await ref
                              .read(solutionNotifierProvider.notifier)
                              .finishSolution(
                                widget.solutionId,
                                status: 'completed',
                                difficulty: _difficulty,
                                quality: _quality,
                                notes: _notesController.text,
                              );

                          if (mounted) {
                            _refreshHomeData(problemId: result?.problemId);
                            Navigator.pop(context);
                            context.go('/main/home');
                            if (result != null && result.xpEarned != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('🏆 Задача выполнена! XP: ${result.xpEarned}')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.flag),
                        label: const Text('Завершить задачу'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final solution = ref.watch(solutionProvider(widget.solutionId));

    // Get motivation for session (cached, changes once per minute)
    final motivation = _getMotivation();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Сессия'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              // TODO: Show session stats
            },
          ),
        ],
      ),
      body: solution.when(
        data: (data) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timer card
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          _formatDuration(_elapsed),
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ранее: ${widget.existingMinutes.toStringAsFixed(1)} мин',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                    .withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Problem info
              if (data?.problem != null) ...[
                Card(
                  child: InkWell(
                    onTap: () {
                      context.push('/problems/${data!.problem!.id}');
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.description_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data!.problem!.displayTitle,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  'Нажмите для просмотра условия',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Motivation
              if (motivation != null) ...[
                MotivationCard(
                  motivation: motivation,
                  showAuthor: false,
                ),
                const SizedBox(height: 16),
              ],

              // Existing artifacts sections
              _EpiphaniesSection(
                solutionId: widget.solutionId,
                onAdd: _showEpiphanyDialog,
              ),
              const SizedBox(height: 8),
              _QuestionsSection(
                solutionId: widget.solutionId,
                onAdd: _showQuestionDialog,
                onQuestionTap: _showQuestionDetailDialog,
              ),
              const SizedBox(height: 8),
              _HintsSection(
                solutionId: widget.solutionId,
                onAdd: _showHintDialog,
                onHintTap: _showHintDetailDialog,
              ),
              const SizedBox(height: 16),

              // Photo for solution
              Card(
                child: ListTile(
                  leading: const Icon(Icons.camera_alt_outlined, color: Colors.teal),
                  title: const Text('Фото решения'),
                  subtitle: const Text('Зафиксировать результат'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push(
                        '/camera?category=solution&entityId=${widget.solutionId}');
                  },
                ),
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
                    ref.invalidate(solutionProvider(widget.solutionId)),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: FilledButton.icon(
            onPressed: _finishSession,
            icon: const Icon(Icons.flag),
            label: const Text('Завершить сессию'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ),
    );
  }
}

// ============ EPIPHANIES SECTION ============

class _EpiphaniesSection extends ConsumerWidget {
  final int solutionId;
  final VoidCallback onAdd;

  const _EpiphaniesSection({
    required this.solutionId,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final epiphanies = ref.watch(epiphaniesProvider(solutionId));

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.lightbulb_outline, color: Colors.amber),
            title: const Text('Озарения'),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: onAdd,
            ),
          ),
          epiphanies.when(
            data: (list) {
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Пока нет озарений',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                );
              }
              return Column(
                children: list
                    .map((e) => _EpiphanyTile(
                          epiphany: e,
                          solutionId: solutionId,
                        ))
                    .toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _EpiphanyTile extends StatelessWidget {
  final EpiphanyModel epiphany;
  final int solutionId;

  const _EpiphanyTile({
    required this.epiphany,
    required this.solutionId,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(
              epiphany.magnitude ?? 1,
              (i) => const Icon(Icons.star, size: 14, color: Colors.amber)),
        ],
      ),
      title: Text(
        epiphany.description ?? '',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.camera_alt_outlined, size: 20),
        tooltip: 'Добавить фото',
        onPressed: () {
          context.push('/camera?category=epiphany&entityId=${epiphany.id}');
        },
      ),
    );
  }
}

// ============ QUESTIONS SECTION ============

class _QuestionsSection extends ConsumerWidget {
  final int solutionId;
  final VoidCallback onAdd;
  final void Function(QuestionModel) onQuestionTap;

  const _QuestionsSection({
    required this.solutionId,
    required this.onAdd,
    required this.onQuestionTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questions = ref.watch(questionsProvider(solutionId));

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.blue),
            title: const Text('Вопросы'),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: onAdd,
            ),
          ),
          questions.when(
            data: (list) {
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Пока нет вопросов',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                );
              }
              return Column(
                children: list
                    .map((q) => _QuestionTile(
                          question: q,
                          solutionId: solutionId,
                          onTap: () => onQuestionTap(q),
                        ))
                    .toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  final QuestionModel question;
  final int solutionId;
  final VoidCallback onTap;

  const _QuestionTile({
    required this.question,
    required this.solutionId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(
        question.hasAnswer ? Icons.check_circle : Icons.help,
        size: 20,
        color: question.hasAnswer ? Colors.green : Colors.grey,
      ),
      title: Text(
        question.body ?? '',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: question.hasAnswer
          ? Text(
              '${question.answer!.length > 40 ? question.answer!.substring(0, 40) + '...' : question.answer!}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.green[700],
                fontSize: 12,
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, size: 20),
            tooltip: 'Добавить фото',
            onPressed: () {
              context.push('/camera?category=question&entityId=${question.id}');
            },
          ),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }
}

// ============ HINTS SECTION ============

class _HintsSection extends ConsumerWidget {
  final int solutionId;
  final VoidCallback onAdd;
  final void Function(HintModel) onHintTap;

  const _HintsSection({
    required this.solutionId,
    required this.onAdd,
    required this.onHintTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hints = ref.watch(hintsProvider(solutionId));

    return Card(
      child: Column(
        children: [
          ListTile(
            leading:
                const Icon(Icons.tips_and_updates_outlined, color: Colors.purple),
            title: const Text('Подсказки'),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: onAdd,
            ),
          ),
          hints.when(
            data: (list) {
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Пока нет подсказок',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                );
              }
              return Column(
                children: list
                    .map((h) => _HintTile(
                          hint: h,
                          solutionId: solutionId,
                          onTap: () => onHintTap(h),
                        ))
                    .toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _HintTile extends StatelessWidget {
  final HintModel hint;
  final int solutionId;
  final VoidCallback onTap;

  const _HintTile({
    required this.hint,
    required this.solutionId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(
        hint.isCompleted ? Icons.check_circle : Icons.hourglass_empty,
        size: 20,
        color: hint.isCompleted ? Colors.green : Colors.grey,
      ),
      title: Text(
        hint.userNotes ?? 'Подсказка',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: hint.hasHint
          ? Text(
              '${hint.hintText!.length > 40 ? hint.hintText!.substring(0, 40) + '...' : hint.hintText!}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.purple[700],
                fontSize: 12,
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, size: 20),
            tooltip: 'Добавить фото',
            onPressed: () {
              context.push('/camera?category=hint&entityId=${hint.id}');
            },
          ),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }
}
