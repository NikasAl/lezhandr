import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/concepts_repository.dart';
import '../../../../data/models/artifacts.dart';
import '../../providers/solutions_provider.dart';
import '../../providers/ocr_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/billing_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../widgets/shared/persona_selector.dart';
import '../../widgets/shared/adaptive_layout.dart';
import '../../widgets/shared/error_display.dart';
import 'widgets/widgets.dart';

/// Solution detail screen for viewing completed or active solution
class SolutionDetailScreen extends ConsumerStatefulWidget {
  final int solutionId;

  const SolutionDetailScreen({super.key, required this.solutionId});

  @override
  ConsumerState<SolutionDetailScreen> createState() => _SolutionDetailScreenState();
}

class _SolutionDetailScreenState extends ConsumerState<SolutionDetailScreen> {
  bool _isEditing = false;
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Force refresh solution data when entering screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(solutionProvider(widget.solutionId));
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

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
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.check_circle_outline, size: 32, color: Colors.green),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Страница решения',
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
                'Здесь можно просмотреть и отредактировать результаты вашей работы над задачей.',
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
                    _buildHelpItem(Icons.info_outline, 'Просмотреть статус и время решения', Colors.green),
                    const SizedBox(height: 8),
                    _buildHelpItem(Icons.description_outlined, 'Условие задачи', Colors.indigo),
                    const SizedBox(height: 8),
                    _buildHelpItem(Icons.psychology_outlined, 'Анализ примененных навыков', Colors.orange),
                    const SizedBox(height: 8),
                    _buildHelpItem(Icons.edit_outlined, 'Написать или отредактировать текст решения', Colors.blue),
                    const SizedBox(height: 8),
                    _buildHelpItem(Icons.camera_alt_outlined, 'Загрузить фото решения', Colors.teal),
                    const SizedBox(height: 8),
                    _buildHelpItem(Icons.auto_awesome, 'Распознать текст решения из фото (OCR). Совет: вызывайте более мощных персонажей для распознавания рукописного текста - это даст более хороший результат.', Colors.purple),
                    const SizedBox(height: 8),
                    _buildHelpItem(Icons.lightbulb_outline, 'Просмотреть зафиксированные озарения', Colors.amber),
                    const SizedBox(height: 8),
                    _buildHelpItem(Icons.help_outline, 'Просмотреть вопросы и ответы', Colors.cyan),
                    const SizedBox(height: 8),
                    _buildHelpItem(Icons.tips_and_updates_outlined, 'Просмотреть полученные подсказки', Colors.pink),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tip section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Фото решения поможет сохранить вашу работу и позже распознать текст.',
                        style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                          color: Colors.blue[700],
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
    final gamification = ref.read(gamificationMeProvider);
    final freeUsesLeft = billing.value?.freeUsesLeft;
    final balance = billing.value?.balance;
    final hearts = gamification.value?.currentHearts;
    final result = await showPersonaSheet(
      context,
      ref,
      defaultPersona: PersonaId.petrovich,
      freeUsesLeft: freeUsesLeft,
      balance: balance,
      hearts: hearts,
    );
    if (result == null) return;

    // OCR runs in background with notification on completion
    await ref.read(ocrNotifierProvider.notifier).processSolution(
      solutionId: widget.solutionId,
      persona: result.persona,
    );
    
    // Refresh solution to get updated text
    if (mounted) {
      ref.invalidate(solutionProvider(widget.solutionId));
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

  Future<void> _runConceptsAnalysis() async {
    final billing = ref.read(billingBalanceProvider);
    final gamification = ref.read(gamificationMeProvider);
    final freeUsesLeft = billing.value?.freeUsesLeft;
    final balance = billing.value?.balance;
    final hearts = gamification.value?.currentHearts;
    final result = await showPersonaSheet(
      context,
      ref,
      defaultPersona: PersonaId.legendre,
      freeUsesLeft: freeUsesLeft,
      balance: balance,
      hearts: hearts,
    );
    if (result == null) return;

    // Analysis runs in background with notification on completion
    await ref.read(conceptsNotifierProvider.notifier).analyzeSolution(
      solutionId: widget.solutionId,
      persona: result.persona,
    );
    
    // Refresh concepts
    if (mounted) {
      ref.invalidate(solutionConceptsProvider(widget.solutionId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final solution = ref.watch(solutionProvider(widget.solutionId));
    final ocrState = ref.watch(ocrNotifierProvider);
    final conceptsState = ref.watch(conceptsNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Решение #${widget.solutionId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Подсказка',
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: solution.when(
        data: (sol) {
          final isOwner = currentUser?.id == sol.addedBy?.id;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: AdaptiveLayout(
              maxWidth: 900,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Status card with added_by
                SolutionStatusCard(solution: sol, addedBy: sol.addedBy),
                const SizedBox(height: 16),

                // Problem condition card
                if (sol.problemId != null) ...[
                  ProblemConditionCard(problemId: sol.problemId!),
                  const SizedBox(height: 16),
                ],

                // Concepts section
                SolutionSkillsSection(
                  solutionId: widget.solutionId,
                  isLoading: conceptsState.isLoading,
                  currentPersona: conceptsState.currentPersona,
                  onAnalyze: _runConceptsAnalysis,
                ),
                const SizedBox(height: 16),

                // Solution text section
                SolutionTextSection(
                  solution: sol,
                  isEditing: _isEditing,
                  controller: _textController,
                  onSave: _saveSolutionText,
                  onToggleEdit: () {
                    setState(() {
                      _isEditing = !_isEditing;
                      if (_isEditing) {
                        _textController.text = sol.solutionText ?? '';
                      }
                    });
                  },
                  onClear: () {
                    _textController.clear();
                  },
                  onOcr: _runOcr,
                  isOcrLoading: ocrState.isLoading,
                  ocrPersona: ocrState.currentPersona,
                  isOwner: isOwner,
                ),
                const SizedBox(height: 16),

                // Solution photo section
                SolutionPhotoCard(
                  solutionId: widget.solutionId,
                  hasImage: sol.hasImage,
                  isOwner: isOwner,
                  onImageUpdated: () {
                    ref.invalidate(solutionProvider(widget.solutionId));
                    ref.invalidate(imageProvider((category: 'solution', entityId: widget.solutionId)));
                  },
                ),
                const SizedBox(height: 16),

                // Artifacts sections
                EpiphaniesSection(solutionId: widget.solutionId),
                const SizedBox(height: 8),
                QuestionsSection(solutionId: widget.solutionId),
                const SizedBox(height: 8),
                HintsSection(solutionId: widget.solutionId),
              ],
            ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorDisplay(
          error: error,
          onRetry: () => ref.invalidate(solutionProvider(widget.solutionId)),
        ),
      ),
    );
  }
}
