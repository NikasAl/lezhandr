import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/problem.dart';
import '../../../data/models/artifacts.dart';
import '../../providers/problems_provider.dart';
import '../../providers/solutions_provider.dart';
import '../../providers/ocr_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/billing_provider.dart';
import '../../widgets/shared/persona_selector.dart';
import '../../widgets/shared/adaptive_layout.dart';
import 'widgets/widgets.dart';

/// Problem detail screen
class ProblemDetailScreen extends ConsumerStatefulWidget {
  final int problemId;

  const ProblemDetailScreen({super.key, required this.problemId});

  @override
  ConsumerState<ProblemDetailScreen> createState() => _ProblemDetailScreenState();
}

class _ProblemDetailScreenState extends ConsumerState<ProblemDetailScreen> {
  bool _isLoading = false;
  final _conditionController = TextEditingController();

  @override
  void dispose() {
    _conditionController.dispose();
    super.dispose();
  }

  Future<void> _runOcr() async {
    final billing = ref.read(billingBalanceProvider);
    final persona = await showPersonaSheet(
      context,
      ref,
      defaultPersona: PersonaId.petrovich,
      freeUsesLeft: billing.value?.freeUsesLeft,
      balance: billing.value?.balance,
    );
    if (persona == null) return;

    await ref.read(ocrNotifierProvider.notifier).processProblem(
      problemId: widget.problemId,
      persona: persona,
    );
    
    if (mounted) {
      ref.invalidate(problemProvider(widget.problemId));
    }
  }

  Future<void> _saveConditionText(String text) async {
    if (text.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      await ref.read(problemNotifierProvider.notifier).updateProblem(
        widget.problemId,
        conditionText: text,
      );
      if (mounted) {
        ref.invalidate(problemProvider(widget.problemId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Текст условия сохранён')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _runConceptsAnalysis() async {
    final billing = ref.read(billingBalanceProvider);
    final persona = await showPersonaSheet(
      context,
      ref,
      defaultPersona: PersonaId.legendre,
      freeUsesLeft: billing.value?.freeUsesLeft,
      balance: billing.value?.balance,
    );
    if (persona == null) return;

    await ref.read(conceptsNotifierProvider.notifier).analyzeProblem(
      problemId: widget.problemId,
      persona: persona,
    );
    
    if (mounted) {
      ref.invalidate(problemProvider(widget.problemId));
    }
  }

  void _showEditConditionDialog(String currentText) {
    _conditionController.text = currentText;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit),
            SizedBox(width: 8),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Редактировать условие'),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: _conditionController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: r'Текст условия (поддержка LaTeX: $...$ или $$...$$)',
            ),
            maxLines: 10,
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _saveConditionText(_conditionController.text);
            },
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showConditionActions(ProblemModel data, bool isOwner) {
    final ocrState = ref.read(ocrNotifierProvider);
    final isOcrLoading = ocrState.isLoading;
    
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwner) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Редактировать текст'),
                subtitle: Text(data.hasText ? 'Изменить текущий текст' : 'Добавить текст'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showEditConditionDialog(data.conditionText ?? '');
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Загрузить фото'),
                subtitle: Text(data.hasImage ? 'Заменить текущее фото' : 'Добавить фото'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await context.push('/camera?category=condition&entityId=${widget.problemId}');
                  if (mounted) {
                    ref.invalidate(problemProvider(widget.problemId));
                    ref.invalidate(imageProvider((category: 'condition', entityId: widget.problemId)));
                  }
                },
              ),
              // OCR - always visible but disabled if no image
              ListTile(
                leading: isOcrLoading 
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.auto_awesome,
                        color: data.hasImage 
                            ? null 
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                title: const Text('Распознать текст (OCR)'),
                subtitle: Text(
                  !data.hasImage 
                      ? 'Сначала прикрепите фото условия'
                      : isOcrLoading 
                          ? '${ocrState.currentPersona?.displayName ?? "Персонаж"} думает...'
                          : 'Извлечь текст с фото',
                ),
                enabled: data.hasImage && !isOcrLoading,
                onTap: (!data.hasImage || isOcrLoading)
                    ? null
                    : () async {
                        Navigator.pop(sheetContext);
                        await _runOcr();
                      },
              ),
            ],
            if (data.hasImage)
              ListTile(
                leading: const Icon(Icons.photo_size_select_large),
                title: const Text('Открыть фото'),
                subtitle: const Text('Просмотреть в полном размере'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  // Navigate to image viewer
                },
              ),
            if (!isOwner && !data.hasImage)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Только автор задачи может редактировать условие',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final problem = ref.watch(problemProvider(widget.problemId));
    final conceptsState = ref.watch(conceptsNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Задача'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              problem.whenData((data) {
                final isOwner = currentUser?.id == data.addedBy?.id;
                _showConditionActions(data, isOwner);
              });
            },
          ),
        ],
      ),
      body: problem.when(
        data: (data) {
          final isOwner = currentUser?.id == data.addedBy?.id;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: AdaptiveLayout(
              maxWidth: 900,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Header
                ProblemHeader(problem: data),
                const SizedBox(height: 16),

                // Tags
                ProblemTagsRow(
                  tags: data.tags,
                  canEdit: isOwner,
                  onEdit: () => showTagsEditorDialog(
                    context: context,
                    currentTags: data.tags,
                    onSaved: (tags) async {
                      await ref.read(problemNotifierProvider.notifier).updateProblem(
                        widget.problemId,
                        tags: tags,
                      );
                      if (mounted) {
                        ref.invalidate(problemProvider(widget.problemId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Теги обновлены')),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Condition
                ConditionCard(
                  problem: data,
                  isOwner: isOwner,
                  onEdit: () => _showEditConditionDialog(data.conditionText ?? ''),
                  onOcr: _runOcr,
                ),
                const SizedBox(height: 16),

                // Concepts
                ProblemConceptsSection(
                  concepts: data.concepts,
                  isLoading: conceptsState.isLoading,
                  currentPersona: conceptsState.currentPersona,
                  onAnalyze: _runConceptsAnalysis,
                ),
                const SizedBox(height: 16),

                // Solutions
                Text(
                  'Решения',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SolutionsList(
                  problemId: widget.problemId,
                  currentUserId: currentUser?.id,
                ),
              ],
            ),
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
                onPressed: () => ref.invalidate(problemProvider(widget.problemId)),
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
