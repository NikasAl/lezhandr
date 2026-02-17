import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/artifacts.dart';
import '../../providers/artifacts_provider.dart';
import '../../widgets/shared/persona_selector.dart';
import '../../widgets/shared/markdown_with_math.dart';

/// Shows question detail dialog with answer and AI option
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

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
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
                          'Ответа пока нет',
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
                  onChanged: (value) {
                    setDialogState(() => hasText = value.isNotEmpty);
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Закрыть'),
          ),
          if (!question.hasAnswer || hasText)
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
                        if (result != null && context.mounted) {
                          Navigator.pop(dialogContext);
                          ref.invalidate(questionsProvider(solutionId));
                          // Show the generated answer
                          onQuestionUpdated(result);
                        }
                      }
                      if (context.mounted) {
                        setDialogState(() => isGenerating = false);
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
          FilledButton(
            onPressed: !hasText
                ? null
                : () async {
                    final success = await ref
                        .read(questionNotifierProvider.notifier)
                        .answer(question.id!, answerController.text);
                    if (success && context.mounted) {
                      Navigator.pop(dialogContext);
                      ref.invalidate(questionsProvider(solutionId));
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
