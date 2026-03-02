import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/artifacts.dart';
import '../../../providers/artifacts_provider.dart';
import '../../../providers/billing_provider.dart';
import '../../../widgets/shared/persona_selector.dart';
import '../../../widgets/shared/markdown_with_math.dart';

/// Shows hint detail as bottom sheet with full text and edit option
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
                      color: (hint.hasHint ? Colors.green : Colors.orange).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      hint.hasHint ? Icons.check_circle : Icons.hourglass_empty,
                      color: hint.hasHint ? Colors.green : Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Подсказка',
                      style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

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
                      style: Theme.of(sheetContext).textTheme.labelMedium?.copyWith(
                        color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(sheetContext).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
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
                      style: Theme.of(sheetContext).textTheme.labelSmall?.copyWith(
                        color: Theme.of(sheetContext).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Hint text or warning
              if (hint.hasHint) ...[
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 18, color: Colors.purple),
                    const SizedBox(width: 8),
                    Text(
                      'Ответ AI',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
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
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple.withOpacity(0.3)),
                        ),
                        child: MarkdownWithMath(
                          text: hint.hintText!,
                          textStyle: Theme.of(sheetContext).textTheme.bodyMedium,
                        ),
                      ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
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
                        style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                          color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Action buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Retry button
                  if (hint.id != null)
                    OutlinedButton.icon(
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
                              if (persona != null && sheetContext.mounted) {
                                final result = await ref
                                    .read(hintNotifierProvider.notifier)
                                    .generate(
                                      hintId: hint.id!,
                                      persona: persona,
                                    );
                                if (sheetContext.mounted) {
                                  Navigator.of(sheetContext).pop();
                                  ref.invalidate(hintsProvider(solutionId));
                                  if (result != null && result.hasHint) {
                                    showHintDetailDialog(
                                      context: sheetContext,
                                      ref: ref,
                                      hint: result,
                                      solutionId: solutionId,
                                    );
                                  } else {
                                    showHintDetailDialog(
                                      context: sheetContext,
                                      ref: ref,
                                      hint: hint,
                                      solutionId: solutionId,
                                      isRegenerating: true,
                                    );
                                  }
                                }
                              } else {
                                setSheetState(() => isGenerating = false);
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
                    
                  // Edit button
                  if (hint.hasHint)
                    OutlinedButton.icon(
                      onPressed: () {
                        setSheetState(() => isEditing = !isEditing);
                      },
                      icon: Icon(isEditing ? Icons.visibility : Icons.edit_outlined),
                      label: Text(isEditing ? 'Просмотр' : 'Редактировать'),
                    ),
                ],
              ),
              
              // Save button (when editing)
              if (isEditing) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final success = await ref
                          .read(hintNotifierProvider.notifier)
                          .updateText(hint.id!, editController.text);
                      if (success && sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                        ref.invalidate(hintsProvider(solutionId));
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          const SnackBar(content: Text('Подсказка обновлена')),
                        );
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Сохранить'),
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
