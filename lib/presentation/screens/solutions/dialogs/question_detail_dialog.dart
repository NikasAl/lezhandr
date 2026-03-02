import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/artifacts.dart';
import '../../../providers/artifacts_provider.dart';
import '../../../providers/billing_provider.dart';
import '../../../widgets/shared/persona_selector.dart';
import '../../../widgets/shared/markdown_with_math.dart';

/// Shows question detail as bottom sheet with answer and AI option
void showQuestionDetailDialog({
  required BuildContext context,
  required WidgetRef ref,
  required QuestionModel question,
  required int solutionId,
  required void Function(QuestionModel) onQuestionUpdated,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => _QuestionDetailSheet(
      question: question,
      solutionId: solutionId,
      ref: ref,
      onQuestionUpdated: onQuestionUpdated,
    ),
  );
}

class _QuestionDetailSheet extends StatefulWidget {
  final QuestionModel question;
  final int solutionId;
  final WidgetRef ref;
  final void Function(QuestionModel) onQuestionUpdated;

  const _QuestionDetailSheet({
    required this.question,
    required this.solutionId,
    required this.ref,
    required this.onQuestionUpdated,
  });

  @override
  State<_QuestionDetailSheet> createState() => _QuestionDetailSheetState();
}

class _QuestionDetailSheetState extends State<_QuestionDetailSheet> {
  late TextEditingController _answerController;
  bool _isGenerating = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _answerController = TextEditingController(text: widget.question.answer ?? '');
    _hasText = _answerController.text.isNotEmpty;
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (widget.question.hasAnswer ? Colors.green : Colors.blue).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.question.hasAnswer ? Icons.check_circle : Icons.help_outline,
                    color: widget.question.hasAnswer ? Colors.green : Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Вопрос',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Question text
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: MarkdownWithMath(
                text: widget.question.body ?? '',
                textStyle: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 20),

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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Current answer or placeholder
            if (widget.question.hasAnswer)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: MarkdownWithMath(
                  text: widget.question.answer!,
                  textStyle: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Ответа пока нет',
                      style: TextStyle(color: Colors.orange[700]),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Manual answer input
            TextField(
              controller: _answerController,
              decoration: const InputDecoration(
                labelText: 'Ваш ответ',
                hintText: 'Введите ответ вручную...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) {
                setState(() => _hasText = value.isNotEmpty);
              },
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Закрыть'),
                  ),
                ),
                const SizedBox(width: 8),

                // AI button
                if (!widget.question.hasAnswer || _hasText)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isGenerating
                          ? null
                          : () async {
                              setState(() => _isGenerating = true);
                              final billing = widget.ref.read(billingBalanceProvider);
                              final freeUsesLeft = billing.value?.freeUsesLeft;
                              final balance = billing.value?.balance;
                              final persona = await showPersonaSheet(
                                context,
                                widget.ref,
                                defaultPersona: PersonaId.basis,
                                freeUsesLeft: freeUsesLeft,
                                balance: balance,
                              );
                              if (persona != null && widget.question.id != null) {
                                final result = await widget.ref
                                    .read(questionNotifierProvider.notifier)
                                    .generateAnswer(
                                      questionId: widget.question.id!,
                                      persona: persona,
                                    );
                                if (result != null && mounted) {
                                  Navigator.of(context).pop();
                                  widget.ref.invalidate(questionsProvider(widget.solutionId));
                                  // Show the generated answer
                                  widget.onQuestionUpdated(result);
                                }
                              }
                              if (mounted) {
                                setState(() => _isGenerating = false);
                              }
                            },
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(_isGenerating ? 'Генерация...' : 'Спросить AI'),
                    ),
                  ),
              ],
            ),

            // Save button
            if (_hasText) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final success = await widget.ref
                        .read(questionNotifierProvider.notifier)
                        .answer(widget.question.id!, _answerController.text);
                    if (success && mounted) {
                      Navigator.of(context).pop();
                      widget.ref.invalidate(questionsProvider(widget.solutionId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ответ сохранён')),
                      );
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Сохранить ответ'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
