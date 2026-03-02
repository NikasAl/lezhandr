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
    enableDrag: true,
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
  bool _isGenerating = false;

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

            // Header with edit button
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
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Редактировать вопрос',
                  onPressed: () => _editQuestion(context),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Question text - full width
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

            // Answer section header with edit button
            Row(
              children: [
                Icon(
                  Icons.reply,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ответ',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (widget.question.hasAnswer)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: 'Редактировать ответ',
                    onPressed: () => _editAnswer(context),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Current answer or placeholder - full width
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
                    Expanded(
                      child: Text(
                        'Ответа пока нет',
                        style: TextStyle(color: Colors.orange[700]),
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Добавить'),
                      onPressed: () => _editAnswer(context),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // AI button
            if (widget.question.id != null)
              SizedBox(
                width: double.infinity,
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
      ),
    );
  }

  /// Show dialog to edit question body
  Future<void> _editQuestion(BuildContext context) async {
    final result = await showModalBottomSheet<_EditResult>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EditFieldSheet(
        title: 'Редактировать вопрос',
        initialValue: widget.question.body ?? '',
        maxLength: 500,
      ),
    );

    if (result != null && result.confirmed && widget.question.id != null) {
      final updated = await widget.ref
          .read(questionNotifierProvider.notifier)
          .update(
            questionId: widget.question.id!,
            body: result.value,
          );
      if (updated != null && mounted) {
        widget.ref.invalidate(questionsProvider(widget.solutionId));
        widget.onQuestionUpdated(updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Вопрос обновлён')),
          );
        }
      }
    }
  }

  /// Show dialog to edit answer
  Future<void> _editAnswer(BuildContext context) async {
    final result = await showModalBottomSheet<_EditResult>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EditFieldSheet(
        title: 'Редактировать ответ',
        initialValue: widget.question.answer ?? '',
        maxLength: 2000,
      ),
    );

    if (result != null && result.confirmed && widget.question.id != null) {
      final updated = await widget.ref
          .read(questionNotifierProvider.notifier)
          .update(
            questionId: widget.question.id!,
            answer: result.value,
          );
      if (updated != null && mounted) {
        widget.ref.invalidate(questionsProvider(widget.solutionId));
        widget.onQuestionUpdated(updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ответ обновлён')),
          );
        }
      }
    }
  }
}

/// Result from edit dialog
class _EditResult {
  final bool confirmed;
  final String value;

  _EditResult({required this.confirmed, required this.value});
}

/// Edit field bottom sheet
class _EditFieldSheet extends StatefulWidget {
  final String title;
  final String initialValue;
  final int? maxLength;

  const _EditFieldSheet({
    required this.title,
    required this.initialValue,
    this.maxLength,
  });

  @override
  State<_EditFieldSheet> createState() => _EditFieldSheetState();
}

class _EditFieldSheetState extends State<_EditFieldSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_EditResult(confirmed: true, value: _controller.text));
  }

  void _cancel() {
    Navigator.of(context).pop(_EditResult(confirmed: false, value: ''));
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
                    color: Colors.blue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.edit_outlined, color: Colors.blue, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _cancel,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Text field
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                counterText: widget.maxLength != null
                    ? '${_controller.text.length}/${widget.maxLength}'
                    : null,
              ),
              maxLines: 5,
              maxLength: widget.maxLength,
              autofocus: true,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancel,
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.save),
                    label: const Text('Сохранить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
