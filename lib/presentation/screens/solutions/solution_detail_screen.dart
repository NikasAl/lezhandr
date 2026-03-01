import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/concepts_repository.dart';
import '../../../../data/models/artifacts.dart';
import '../../providers/solutions_provider.dart';
import '../../providers/ocr_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/billing_provider.dart';
import '../../widgets/shared/persona_selector.dart';
import '../../widgets/shared/adaptive_layout.dart';
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

  Future<void> _runOcr() async {
    final billing = ref.read(billingBalanceProvider);
    final freeUsesLeft = billing.value?.freeUsesLeft;
    final balance = billing.value?.balance;
    final persona = await showPersonaSheet(
      context,
      ref,
      defaultPersona: PersonaId.petrovich,
      freeUsesLeft: freeUsesLeft,
      balance: balance,
    );
    if (persona == null) return;

    // OCR runs in background with notification on completion
    await ref.read(ocrNotifierProvider.notifier).processSolution(
      solutionId: widget.solutionId,
      persona: persona,
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
    final freeUsesLeft = billing.value?.freeUsesLeft;
    final balance = billing.value?.balance;
    final persona = await showPersonaSheet(
      context,
      ref,
      defaultPersona: PersonaId.legendre,
      freeUsesLeft: freeUsesLeft,
      balance: balance,
    );
    if (persona == null) return;

    // Analysis runs in background with notification on completion
    await ref.read(conceptsNotifierProvider.notifier).analyzeSolution(
      solutionId: widget.solutionId,
      persona: persona,
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
