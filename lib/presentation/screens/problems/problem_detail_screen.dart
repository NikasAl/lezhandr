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
import '../../widgets/shared/error_display.dart';
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

  /// Show help dialog as bottom sheet
  void _showHelpDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
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
                      color: Colors.indigo.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.assignment_outlined, size: 32, color: Colors.indigo),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Страница задачи',
                      style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Main description
              Text(
                'Здесь вы можете изучить условие задачи и подготовиться к её решению.',
                style: Theme.of(sheetContext).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),

              // Features section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(sheetContext).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Возможности:',
                      style: Theme.of(sheetContext).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildHelpItem(Icons.description_outlined, 'Просмотреть условие задачи', Colors.indigo),
                    const SizedBox(height: 8),
                    _buildHelpItem(Icons.edit_outlined, 'Редактировать текст условия', Colors.blue),
                    const SizedBox(height: 8),
                    _buildHelpItem(Icons.camera_alt_outlined, 'Загрузить фото условия', Colors.teal),
                    const SizedBox(height: 8),
                    _buildHelpItem(Icons.auto_awesome, 'Распознать текст с фото (OCR)', Colors.purple),
                    const SizedBox(height: 8),
                    _buildHelpItem(Icons.psychology_outlined, 'Анализ концепций для решения', Colors.orange),
                    const SizedBox(height: 8),
                    _buildHelpItem(Icons.local_offer_outlined, 'Управлять тегами задачи', Colors.amber),
                    const SizedBox(height: 8),
                    _buildHelpItem(Icons.history, 'Просмотреть историю решений', Colors.green),
                    const SizedBox(height: 8),
                    _buildHelpItem(Icons.play_arrow, 'Начать новую сессию решения', Colors.red),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tip section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.orange[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Анализ концепций поможет понять, какие знания понадобятся для решения задачи. Осторожно, Спойлер! - изучение конепций перед решением задачи может раскрыть идею задачи раньше, чем вы сами догадаетесь об этом.',
                        style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                          color: Colors.orange[700],
                        ),
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
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  icon: const Icon(Icons.check),
                  label: const Text('Понятно!'),
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

  Widget _buildHelpItem(IconData icon, String text, Color color) {
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

  Future<void> _runOcr() async {
    final billing = ref.read(billingBalanceProvider);
    // OCR оплачивается только деньгами, не сердцами
    final persona = await showPersonaSheet(
      context,
      ref,
      defaultPersona: PersonaId.petrovich,
      freeUsesLeft: billing.value?.freeUsesLeft,
      balance: billing.value?.balance,
      hearts: null, // OCR не поддерживает оплату сердцами
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
    // Анализ концепций оплачивается только деньгами, не сердцами
    final persona = await showPersonaSheet(
      context,
      ref,
      defaultPersona: PersonaId.legendre,
      freeUsesLeft: billing.value?.freeUsesLeft,
      balance: billing.value?.balance,
      hearts: null, // Анализ концепций не поддерживает оплату сердцами
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

  void _showEditConditionDialog(String currentText, bool isApproved) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _EditConditionSheet(
        initialText: currentText,
        isApproved: isApproved,
        onSave: (text) {
          Navigator.of(sheetContext).pop();
          _saveConditionText(text);
        },
      ),
    );
  }

  void _showConditionActions(ProblemModel data, bool isOwner) {
    final ocrState = ref.read(ocrNotifierProvider);
    final isOcrLoading = ocrState.isLoading;
    // Owner can edit any problem - approved problems will be reset to pending
    final canEdit = isOwner;
    
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canEdit) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Редактировать текст'),
                subtitle: Text(data.hasText ? 'Изменить текущий текст' : 'Добавить текст'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showEditConditionDialog(data.conditionText ?? '', data.isApproved);
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
            if (isOwner && data.isRejected)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Задача отклонена и не может быть изменена',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (!isOwner && !data.hasImage && data.isPending)
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
            icon: const Icon(Icons.help_outline),
            tooltip: 'Подсказка',
            onPressed: _showHelpDialog,
          ),
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
                  canEdit: isOwner && !data.isRejected,
                  onEdit: () => _showEditConditionDialog(data.conditionText ?? '', data.isApproved),
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
        error: (error, _) => ErrorDisplay(
          error: error,
          onRetry: () => ref.invalidate(problemProvider(widget.problemId)),
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

/// Bottom sheet for editing problem condition
class _EditConditionSheet extends StatefulWidget {
  final String initialText;
  final bool isApproved;
  final ValueChanged<String> onSave;

  const _EditConditionSheet({
    required this.initialText,
    required this.isApproved,
    required this.onSave,
  });

  @override
  State<_EditConditionSheet> createState() => _EditConditionSheetState();
}

class _EditConditionSheetState extends State<_EditConditionSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
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
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit, color: Colors.indigo, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Редактировать условие',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Text field
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: r'Текст условия (поддержка LaTeX: $...$ или $$...$$)',
                ),
                maxLines: 6,
                autofocus: true,
              ),
              
              // Moderation warning
              if (widget.isApproved) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[700], size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'При редактировании задача вернётся на модерацию',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => widget.onSave(_controller.text),
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('Сохранить'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
