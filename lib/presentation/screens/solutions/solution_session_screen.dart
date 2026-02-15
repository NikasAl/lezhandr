import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/motivation/motivation_engine.dart';
import '../../../data/models/solution.dart';
import '../../../data/models/artifacts.dart';
import '../../providers/solutions_provider.dart';
import '../../providers/artifacts_provider.dart';
import '../../providers/ocr_provider.dart';
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
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
                  await ref.read(epiphanyNotifierProvider.notifier).create(
                    solutionId: widget.solutionId,
                    description: controller.text,
                    magnitude: magnitude,
                  );
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Озарение сохранено!')),
                );
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
                await ref.read(questionNotifierProvider.notifier).create(
                  solutionId: widget.solutionId,
                  body: controller.text,
                );
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Вопрос сохранён!')),
              );
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
    
    if (hint == null || hint.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось создать запрос подсказки')),
        );
      }
      return;
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

  void _finishSession() {
    setState(() => _isFinished = true);
    _timer?.cancel();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
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
                'Общее время: ${_formatDuration(_elapsed)}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),

              // Difficulty
              Text(
                'Сложность',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (i) {
                  final value = i + 1;
                  return ChoiceChip(
                    label: Text('$value'),
                    selected: _difficulty == value,
                    onSelected: (selected) {
                      if (selected) setState(() => _difficulty = value);
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Quality
              Text(
                'Качество решения',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Slider(
                value: _quality,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                label: _quality.toStringAsFixed(1),
                onChanged: (value) => setState(() => _quality = value),
              ),
              const SizedBox(height: 16),

              // Notes
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Заметки',
                  hintText: 'Ваши мысли о задаче...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Finish button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final totalMinutes = widget.existingMinutes +
                        _elapsed.inMinutes +
                        _elapsed.inSeconds / 60;

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
                    await ref.read(solutionNotifierProvider.notifier).finishSolution(
                          widget.solutionId,
                          status: 'completed',
                          difficulty: _difficulty,
                          quality: _quality,
                          notes: _notesController.text,
                        );

                    if (mounted) {
                      Navigator.pop(context);
                      context.go('/main/home');
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Завершить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final solution = ref.watch(solutionProvider(widget.solutionId));
    final motivationEngine = MotivationEngine();

    // Get motivation for session
    final motivation = motivationEngine.getSessionStartText();

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

              // Quick actions
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.lightbulb_outline,
                      label: 'Озарение',
                      color: Colors.amber,
                      onTap: _showEpiphanyDialog,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.help_outline,
                      label: 'Вопрос',
                      color: Colors.blue,
                      onTap: _showQuestionDialog,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.tips_and_updates_outlined,
                      label: 'Подсказка',
                      color: Colors.purple,
                      onTap: _showHintDialog,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.camera_alt_outlined,
                      label: 'Фото решения',
                      color: Colors.teal,
                      onTap: () {
                        context.push(
                            '/camera?category=solution&entityId=${widget.solutionId}');
                      },
                    ),
                  ),
                ],
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
