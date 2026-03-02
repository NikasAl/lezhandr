import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/artifacts_provider.dart';

/// Result data from question sheet
class _QuestionResult {
  final bool confirmed;
  final String? body;

  _QuestionResult({required this.confirmed, this.body});
}

/// Shows question creation bottom sheet and handles the flow
/// Returns true if question was created successfully
Future<bool> showQuestionDialog({
  required BuildContext context,
  required WidgetRef ref,
  required int solutionId,
}) async {
  // Step 1: Get user input
  final result = await showModalBottomSheet<_QuestionResult>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => const _QuestionSheetContent(),
  );

  if (result == null || !result.confirmed || result.body == null || result.body!.isEmpty) {
    return false;
  }

  // Create question
  final question = await ref.read(questionNotifierProvider.notifier).create(
    solutionId: solutionId,
    body: result.body!,
  );

  if (!context.mounted) return false;

  // Refresh list
  ref.invalidate(questionsProvider(solutionId));

  // Offer to add image
  if (question?.id != null && context.mounted) {
    final addImage = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _SuccessSheet(
        title: 'Вопрос сохранён!',
        subtitle: 'Добавить фото контекста?',
      ),
    );

    if (addImage == true && context.mounted) {
      context.push('/camera?category=question&entityId=${question!.id}');
    }
  }

  return question?.id != null;
}

/// Question sheet content - manages its own controller
class _QuestionSheetContent extends StatefulWidget {
  const _QuestionSheetContent();

  @override
  State<_QuestionSheetContent> createState() => _QuestionSheetContentState();
}

class _QuestionSheetContentState extends State<_QuestionSheetContent> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_QuestionResult(
      confirmed: true,
      body: _controller.text,
    ));
  }

  void _cancel() {
    Navigator.of(context).pop(_QuestionResult(confirmed: false));
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
                  child: const Icon(Icons.help_outline, color: Colors.blue, size: 24),
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

            // Question input
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Ваш вопрос',
                hintText: 'Введите ваш вопрос...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
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

/// Simple success sheet without state
class _SuccessSheet extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SuccessSheet({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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

          // Success icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.green, size: 32),
          ),
          const SizedBox(height: 16),

          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Нет'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Добавить фото'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
