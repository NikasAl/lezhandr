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
            _showHintResultDialog(result.hintText!);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Не удалось получить подсказку. Проверьте баланс.')),
            );
          }
        }
      }
    }
  }
  
  void _showHintResultDialog(String hintText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.purple),
            SizedBox(width: 8),
            Text('Подсказка'),
          ],
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            hintText,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _refreshHomeData() {
    // Invalidate providers to refresh home screen data
    ref.invalidate(activeSolutionsProvider);
    ref.invalidate(gamificationMeProvider);
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
                          await ref.read(solutionNotifierProvider.notifier).createSession(
                                SessionCreate(
                                  solutionId: widget.solutionId,
                                  startTime: _startTime,
                                  endTime: DateTime.now(),
                                  duration: _elapsed.inMinutes.toDouble(),
                                ),
                              );
                          if (mounted) {
                            _refreshHomeData();
                            Navigator.pop(context);
                            context.go('/main/home');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Сессия сохранена. Задача осталась активной.')),
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
                          await ref.read(solutionNotifierProvider.notifier).createSession(
                                SessionCreate(
                                  solutionId: widget.solutionId,
                                  startTime: _startTime,
                                  endTime: DateTime.now(),
                                  duration: _elapsed.inMinutes.toDouble(),
                                ),
                              );

                          // Finish solution
                          final result = await ref.read(solutionNotifierProvider.notifier).finishSolution(
                                widget.solutionId,
                                status: 'completed',
                                difficulty: _difficulty,
                                quality: _quality,
                                notes: _notesController.text,
                              );

                          if (mounted) {
                            _refreshHomeData();
                            Navigator.pop(context);
                            context.go('/main/home');
                            if (result != null && result.xpEarned != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('🏆 Задача выполнена! XP: ${result.xpEarned}')),
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
                                style:
                                    Theme.of(context).textTheme.titleMedium,
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
              ),
              const SizedBox(height: 8),
              _HintsSection(
                solutionId: widget.solutionId,
                onAdd: _showHintDialog,
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
                    context.push('/camera?category=solution&entityId=${widget.solutionId}');
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

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
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
                children: list.map((e) => _EpiphanyTile(
                  epiphany: e,
                  solutionId: solutionId,
                )).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
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
          ...List.generate(epiphany.magnitude ?? 1, (i) =>
            const Icon(Icons.star, size: 14, color: Colors.amber),
          ),
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

  const _QuestionsSection({
    required this.solutionId,
    required this.onAdd,
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
                children: list.map((q) => _QuestionTile(
                  question: q,
                  solutionId: solutionId,
                )).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
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

  const _QuestionTile({
    required this.question,
    required this.solutionId,
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
      trailing: IconButton(
        icon: const Icon(Icons.camera_alt_outlined, size: 20),
        tooltip: 'Добавить фото',
        onPressed: () {
          context.push('/camera?category=question&entityId=${question.id}');
        },
      ),
    );
  }
}

// ============ HINTS SECTION ============

class _HintsSection extends ConsumerWidget {
  final int solutionId;
  final VoidCallback onAdd;

  const _HintsSection({
    required this.solutionId,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hints = ref.watch(hintsProvider(solutionId));

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.tips_and_updates_outlined, color: Colors.purple),
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
                children: list.map((h) => _HintTile(
                  hint: h,
                  solutionId: solutionId,
                )).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
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

  const _HintTile({
    required this.hint,
    required this.solutionId,
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
      trailing: IconButton(
        icon: const Icon(Icons.camera_alt_outlined, size: 20),
        tooltip: 'Добавить фото',
        onPressed: () {
          context.push('/camera?category=hint&entityId=${hint.id}');
        },
      ),
    );
  }
}
