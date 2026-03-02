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
  final answerController = TextEditingController(text: question.answer ?? '');
  bool isGenerating = false;
  bool hasText = answerController.text.isNotEmpty;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => StatefulBuilder(
      builder: (stateContext, setSheetState) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
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
                      color: (question.hasAnswer ? Colors.green : Colors.blue).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      question.hasAnswer ? Icons.check_circle : Icons.help_outline,
                      color: question.hasAnswer ? Colors.green : Colors.blue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Вопрос',
                      style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
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
                  color: Theme.of(sheetContext).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: MarkdownWithMath(
                  text: question.body ?? '',
                  textStyle: Theme.of(sheetContext).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 20),

              // Answer section
              Row(
                children: [
                  Icon(
                    Icons.reply,
                    size: 20,
                    color: Theme.of(sheetContext).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ответ',
                    style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Current answer or placeholder
              if (question.hasAnswer)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: MarkdownWithMath(
                    text: question.answer!,
                    textStyle: Theme.of(sheetContext).textTheme.bodyMedium,
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
                controller: answerController,
                decoration: const InputDecoration(
                  labelText: 'Ваш ответ',
                  hintText: 'Введите ответ вручную...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) {
                  setSheetState(() => hasText = value.isNotEmpty);
                },
              ),
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: const Text('Закрыть'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // AI button
                  if (!question.hasAnswer || hasText)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isGenerating
                            ? null
                            : () async {
                                setSheetState(() => isGenerating = true);
                                final billing = ref.read(billingBalanceProvider);
                                final freeUsesLeft = billing.value?.freeUsesLeft;
                                final balance = billing.value?.balance;
                                final persona = await showPersonaSheet(
                                  sheetContext,
                                  ref,
                                  defaultPersona: PersonaId.basis,
                                  freeUsesLeft: freeUsesLeft,
                                  balance: balance,
                                );
                                if (persona != null && question.id != null) {
                                  final result = await ref
                                      .read(questionNotifierProvider.notifier)
                                      .generateAnswer(
                                        questionId: question.id!,
                                        persona: persona,
                                      );
                                  if (result != null && sheetContext.mounted) {
                                    Navigator.of(sheetContext).pop();
                                    ref.invalidate(questionsProvider(solutionId));
                                    // Show the generated answer
                                    onQuestionUpdated(result);
                                  }
                                }
                                if (sheetContext.mounted) {
                                  setSheetState(() => isGenerating = false);
                                }
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
                  ),
                ],
              ),
              
              // Save button
              if (hasText) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final success = await ref
                          .read(questionNotifierProvider.notifier)
                          .answer(question.id!, answerController.text);
                      if (success && sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                        ref.invalidate(questionsProvider(solutionId));
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
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
      ),
    ),
  );
}
