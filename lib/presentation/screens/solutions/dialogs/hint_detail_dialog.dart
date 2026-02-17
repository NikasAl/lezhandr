import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/artifacts.dart';
import '../../providers/artifacts_provider.dart';
import '../../widgets/shared/persona_selector.dart';
import '../../widgets/shared/markdown_with_math.dart';

/// Shows hint detail dialog with full text and edit option
void showHintDetailDialog({
  required BuildContext context,
  required WidgetRef ref,
  required HintModel hint,
  required int solutionId,
  bool isRegenerating = false,
}) {
  final editController = TextEditingController(text: hint.hintText ?? '');
  bool isEditing = false;
  bool isGenerating = false;

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Row(
          children: [
            Icon(
              hint.hasHint ? Icons.check_circle : Icons.hourglass_empty,
              color: hint.hasHint ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Подсказка', overflow: TextOverflow.ellipsis),
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
                // User notes
                if (hint.userNotes != null && hint.userNotes!.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.note_outlined,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ваши заметки',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(hint.userNotes!),
                  ),
                  const SizedBox(height: 16),
                ],

                // AI model info
                if (hint.aiModel != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.smart_toy_outlined,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI: ${hint.aiModel}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Hint text
                if (hint.hasHint) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: Colors.purple,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ответ AI',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  isEditing
                      ? TextField(
                          controller: editController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Текст подсказки...',
                          ),
                          maxLines: 6,
                        )
                      : Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.purple.withOpacity(0.3)),
                          ),
                          child: MarkdownWithMath(
                            text: hint.hintText!,
                            textStyle: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                ] else ...[
                  // No hint yet - show warning and retry option
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isRegenerating
                                    ? 'Недостаточно средств для генерации'
                                    : 'Подсказка ещё не сгенерирована',
                                style: TextStyle(color: Colors.orange[700]),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Попробуйте выбрать другую AI-персону или пополните баланс',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Закрыть'),
          ),
          // Retry button - always show to allow trying different model
          if (hint.id != null)
            TextButton.icon(
              onPressed: isGenerating
                  ? null
                  : () async {
                      setDialogState(() => isGenerating = true);
                      final persona = await showPersonaSheet(
                        context,
                        defaultPersona: PersonaId.basis,
                      );
                      if (persona != null && context.mounted) {
                        final result = await ref
                            .read(hintNotifierProvider.notifier)
                            .generate(
                              hintId: hint.id!,
                              persona: persona,
                            );
                        if (context.mounted) {
                          Navigator.pop(dialogContext);
                          ref.invalidate(hintsProvider(solutionId));
                          if (result != null && result.hasHint) {
                            showHintDetailDialog(
                              context: context,
                              ref: ref,
                              hint: result,
                              solutionId: solutionId,
                            );
                          } else {
                            // Show dialog again with error indication
                            showHintDetailDialog(
                              context: context,
                              ref: ref,
                              hint: hint,
                              solutionId: solutionId,
                              isRegenerating: true,
                            );
                          }
                        }
                      } else {
                        setDialogState(() => isGenerating = false);
                      }
                    },
              icon: isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(isGenerating ? 'Генерация...' : 'Запросить'),
            ),
          if (hint.hasHint)
            TextButton.icon(
              onPressed: () {
                setDialogState(() => isEditing = !isEditing);
              },
              icon: Icon(isEditing ? Icons.visibility : Icons.edit_outlined),
              label: Text(isEditing ? 'Просмотр' : 'Редактировать'),
            ),
          if (isEditing)
            FilledButton(
              onPressed: () async {
                final success = await ref
                    .read(hintNotifierProvider.notifier)
                    .updateText(hint.id!, editController.text);
                if (success && context.mounted) {
                  Navigator.pop(dialogContext);
                  ref.invalidate(hintsProvider(solutionId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Подсказка обновлена')),
                  );
                }
              },
              child: const Text('Сохранить'),
            ),
        ],
      ),
    ),
  );
}
