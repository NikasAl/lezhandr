import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/artifacts.dart';
import '../../../providers/artifacts_provider.dart';
import '../../../providers/billing_provider.dart';
import '../../../providers/gamification_provider.dart';
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
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => _HintDetailSheet(
      hint: hint,
      solutionId: solutionId,
      isRegenerating: isRegenerating,
      ref: ref,
    ),
  );
}

class _HintDetailSheet extends StatefulWidget {
  final HintModel hint;
  final int solutionId;
  final bool isRegenerating;
  final WidgetRef ref;

  const _HintDetailSheet({
    required this.hint,
    required this.solutionId,
    required this.isRegenerating,
    required this.ref,
  });

  @override
  State<_HintDetailSheet> createState() => _HintDetailSheetState();
}

class _HintDetailSheetState extends State<_HintDetailSheet> {
  late TextEditingController _editController;
  bool _isEditing = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.hint.hintText ?? '');
  }

  @override
  void dispose() {
    _editController.dispose();
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
                    color: (widget.hint.hasHint ? Colors.green : Colors.orange).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.hint.hasHint ? Icons.check_circle : Icons.hourglass_empty,
                    color: widget.hint.hasHint ? Colors.green : Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Подсказка',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // User notes
            if (widget.hint.userNotes != null && widget.hint.userNotes!.isNotEmpty) ...[
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
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(widget.hint.userNotes!),
              ),
              const SizedBox(height: 16),
            ],

            // AI model info
            if (widget.hint.aiModel != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.smart_toy_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI: ${widget.hint.aiModel}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Hint text or warning
            if (widget.hint.hasHint) ...[
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
              _isEditing
                  ? TextField(
                      controller: _editController,
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
                        text: widget.hint.hintText!,
                        textStyle: Theme.of(context).textTheme.bodyMedium,
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
                            widget.isRegenerating
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

            const SizedBox(height: 24),

            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Retry button
                if (widget.hint.id != null)
                  OutlinedButton.icon(
                    onPressed: _isGenerating
                        ? null
                        : () async {
                            setState(() => _isGenerating = true);
                            final billing = widget.ref.read(billingBalanceProvider);
                            final gamification = widget.ref.read(gamificationMeProvider);
                            final freeUsesLeft = billing.value?.freeUsesLeft;
                            final balance = billing.value?.balance;
                            final hearts = gamification.value?.currentHearts;
                            final persona = await showPersonaSheet(
                              context,
                              widget.ref,
                              defaultPersona: PersonaId.basis,
                              freeUsesLeft: freeUsesLeft,
                              balance: balance,
                              hearts: hearts,
                            );
                            if (persona != null && mounted) {
                              // Автоматически определяем useHearts: если сердца доступны, используем их
                              final useHearts = hearts != null && hearts >= 1;
                              final hint = await widget.ref
                                  .read(hintNotifierProvider.notifier)
                                  .generate(
                                    hintId: widget.hint.id!,
                                    persona: persona,
                                    useHearts: useHearts,
                                  );
                              if (mounted) {
                                // Обновляем геймификацию если использовали сердца
                                if (useHearts) {
                                  widget.ref.invalidate(gamificationMeProvider);
                                }
                                Navigator.of(context).pop();
                                widget.ref.invalidate(hintsProvider(widget.solutionId));
                                if (hint != null && hint.hasHint) {
                                  showHintDetailDialog(
                                    context: context,
                                    ref: widget.ref,
                                    hint: hint,
                                    solutionId: widget.solutionId,
                                  );
                                } else {
                                  showHintDetailDialog(
                                    context: context,
                                    ref: widget.ref,
                                    hint: widget.hint,
                                    solutionId: widget.solutionId,
                                    isRegenerating: true,
                                  );
                                }
                              }
                            } else {
                              if (mounted) {
                                setState(() => _isGenerating = false);
                              }
                            }
                          },
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(_isGenerating ? 'Генерация...' : 'Запросить'),
                  ),

                // Edit button
                if (widget.hint.hasHint)
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _isEditing = !_isEditing);
                    },
                    icon: Icon(_isEditing ? Icons.visibility : Icons.edit_outlined),
                    label: Text(_isEditing ? 'Просмотр' : 'Редактировать'),
                  ),
              ],
            ),

            // Save button (when editing)
            if (_isEditing) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final success = await widget.ref
                        .read(hintNotifierProvider.notifier)
                        .updateText(widget.hint.id!, _editController.text);
                    if (success && mounted) {
                      Navigator.of(context).pop();
                      widget.ref.invalidate(hintsProvider(widget.solutionId));
                      ScaffoldMessenger.of(context).showSnackBar(
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
    );
  }
}
