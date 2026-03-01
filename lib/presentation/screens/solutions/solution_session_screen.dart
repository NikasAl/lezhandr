import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/motivation/motivation_engine.dart';
import '../../../core/motivation/motivation_models.dart';
import '../../../data/models/artifacts.dart';
import '../../../data/models/problem.dart';
import '../../providers/solutions_provider.dart';
import '../../providers/artifacts_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/problems_provider.dart';
import '../../widgets/motivation/motivation_card.dart';
import '../../widgets/shared/markdown_with_math.dart';
import '../../widgets/shared/image_viewer.dart';
// Dialogs - extracted to separate files for better maintainability
import 'dialogs/dialogs.dart';

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

  // Motivation caching
  final MotivationEngine _motivationEngine = MotivationEngine();
  MotivationText? _cachedMotivation;
  int _lastMotivationMinute = -1;

  // Session intro hint key
  static const _sessionIntroShownKey = 'session_intro_shown';

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _startTimer();
    _showIntroIfFirstTime();
  }

  /// Show intro dialog on first visit
  Future<void> _showIntroIfFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool(_sessionIntroShownKey) ?? false;
    if (!shown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showIntroDialog();
      });
      await prefs.setBool(_sessionIntroShownKey, true);
    }
  }

  /// Show session introduction as bottom sheet
  void _showIntroDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
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
              
              // Header with icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.lightbulb_outline, size: 32, color: Colors.amber),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Время подумать',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Main message
              Text(
                'Теперь пришло время взять чистый листок бумаги и подумать над решением задачи.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              
              // Highlighted quote
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.format_quote,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Именно это время является самым ценным — происходит настоящий прогресс в знаниях и навыках.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                'Постарайтесь решить задачу целиком самостоятельно и без подсказок — это максимально ценный опыт.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              
              Text(
                'Если на это уходит много времени, можно остановить сессию и вернуться к задаче позже столько раз, сколько потребуется.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              
              // What you can do section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'На этой странице можно:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(Icons.help_outline, 'Отмечать свои вопросы', Colors.blue),
                    const SizedBox(height: 8),
                    _buildFeatureItem(Icons.lightbulb_outline, 'Фиксировать озарения', Colors.amber),
                    const SizedBox(height: 8),
                    _buildFeatureItem(Icons.tips_and_updates_outlined, 'Запросить подсказку', Colors.purple),
                    const SizedBox(height: 8),
                    _buildFeatureItem(Icons.chat_bubble_outline, 'Получить ответ на вопрос', Colors.green),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Warning section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.deepOrange.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.deepOrange, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Но не нужно спешить!',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Хорошая задача решается три дня и три ночи. Частое обращение к подсказкам помешает созреванию собственной догадки и уменьшит радость открытия.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Action button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Понятно, начинаю!'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeatureItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text),
        ),
      ],
    );
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
    showEpiphanyDialog(
      context: context,
      ref: ref,
      solutionId: widget.solutionId,
    );
  }

  void _showQuestionDialog() {
    showQuestionDialog(
      context: context,
      ref: ref,
      solutionId: widget.solutionId,
    );
  }

  /// Show question detail dialog with answer and AI option
  void _showQuestionDetailDialog(QuestionModel question) {
    showQuestionDetailDialog(
      context: context,
      ref: ref,
      question: question,
      solutionId: widget.solutionId,
      onQuestionUpdated: _showQuestionDetailDialog,
    );
  }

  void _showHintDialog() {
    showHintDialog(
      context: context,
      ref: ref,
      solutionId: widget.solutionId,
    );
  }

  /// Show hint detail dialog with full text and edit option
  void _showHintDetailDialog(HintModel hint, {bool isRegenerating = false}) {
    showHintDetailDialog(
      context: context,
      ref: ref,
      hint: hint,
      solutionId: widget.solutionId,
      isRegenerating: isRegenerating,
    );
  }

  void _finishSession() {
    setState(() => _isFinished = true);
    _timer?.cancel();

    showFinishSessionSheet(
      context: context,
      ref: ref,
      solutionId: widget.solutionId,
      elapsed: _elapsed,
      existingMinutes: widget.existingMinutes,
      startTime: _startTime,
      formatDuration: _formatDuration,
    );
  }

  @override
  Widget build(BuildContext context) {
    final solution = ref.watch(solutionProvider(widget.solutionId));

    // Get motivation for session (cached, changes once per minute)
    final motivation = _getMotivation();

    // Adaptive layout for wide screens
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Сессия'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Подсказка',
            onPressed: _showIntroDialog,
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              // TODO: Show session stats
            },
          ),
        ],
      ),
      body: solution.when(
        data: (data) {
          final bodyContent = SingleChildScrollView(
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

                // Problem info with condition preview
                // Use separate problem provider to get full problem data
                if (data.problemId != null) ...[
                  _ProblemConditionCard(
                    problemId: data.problemId!,
                    problemPreview: data.problem,
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

                // Solution photo section - show existing or add new
                if (data.hasImage) ...[
                  // Show existing solution photo
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.photo_camera_back, color: Colors.teal),
                              const SizedBox(width: 12),
                              Text(
                                'Фото решения',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () async {
                                  await context.push(
                                      '/camera?category=solution&entityId=${widget.solutionId}');
                                  // Refresh solution to get updated image
                                  ref.invalidate(solutionProvider(widget.solutionId));
                                },
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Обновить'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SolutionImageThumbnail(
                              solutionId: widget.solutionId,
                              title: 'Фото решения',
                              height: 200,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // No solution photo yet - show add button
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.camera_alt_outlined, color: Colors.teal),
                      title: const Text('Фото решения'),
                      subtitle: const Text('Зафиксировать результат'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await context.push(
                            '/camera?category=solution&entityId=${widget.solutionId}');
                        // Refresh solution to get updated image
                        ref.invalidate(solutionProvider(widget.solutionId));
                      },
                    ),
                  ),
                ],
              ],
            ),
          );

          // Wrap with constraints for wide screens
          if (isWideScreen) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: bodyContent,
              ),
            );
          }
          return bodyContent;
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
      bottomNavigationBar: Container(
        padding: isWideScreen
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 16)
            : const EdgeInsets.all(16),
        margin: isWideScreen
            ? EdgeInsets.symmetric(
                horizontal: (screenWidth - 900) / 2 > 0 ? (screenWidth - 900) / 2 : 0,
              )
            : null,
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
      title: MarkdownWithMath(
        text: epiphany.description ?? '',
        textStyle: Theme.of(context).textTheme.bodyMedium,
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
        hint.hasHint ? Icons.check_circle : Icons.warning_amber,
        size: 20,
        color: hint.hasHint ? Colors.green : Colors.orange,
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
          : Text(
              'Нажмите для генерации',
              style: TextStyle(
                color: Colors.orange[700],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
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

/// Widget that displays problem condition with full data from problemProvider
class _ProblemConditionCard extends ConsumerWidget {
  final int problemId;
  final ProblemModel? problemPreview;

  const _ProblemConditionCard({
    required this.problemId,
    this.problemPreview,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final problemAsync = ref.watch(problemProvider(problemId));

    return problemAsync.when(
      data: (problem) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  const Icon(Icons.description_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      problem.displayTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Condition preview - text or image
              if (problem.hasText) ...[
                // Text condition with LaTeX support
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: MarkdownWithMath(
                    text: problem.conditionText!,
                    textStyle: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ] else if (problem.hasImage) ...[
                // Image condition thumbnail
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImageViewerScreen(
                          category: 'condition',
                          entityId: problem.id,
                          title: 'Условие: ${problem.reference}',
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ConditionImageThumbnail(
                      problemId: problem.id,
                      title: 'Условие: ${problem.reference}',
                      height: 200,
                    ),
                  ),
                ),
              ] else ...[
                // No condition yet
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Добавьте фото или текст условия',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
      loading: () => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.description_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      problemPreview?.displayTitle ?? 'Загрузка...',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
      error: (_, __) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Ошибка загрузки условия',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ),
    );
  }
}
