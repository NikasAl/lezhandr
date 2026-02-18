import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/artifacts_provider.dart';

/// Shows question creation dialog and handles the flow
/// Returns true if question was created successfully
Future<bool> showQuestionDialog({
  required BuildContext context,
  required WidgetRef ref,
  required int solutionId,
}) async {
  final controller = TextEditingController();

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.help_outline),
          SizedBox(width: 8),
          Expanded(
            child: Text('Вопрос', overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: 'Введите ваш вопрос...',
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Сохранить'),
        ),
      ],
    ),
  );

  if (result != true || controller.text.isEmpty) {
    controller.dispose();
    return false;
  }

  // Create question
  final question = await ref.read(questionNotifierProvider.notifier).create(
    solutionId: solutionId,
    body: controller.text,
  );

  controller.dispose();

  if (!context.mounted) return false;

  // Refresh list
  ref.invalidate(questionsProvider(solutionId));

  // Offer to add image
  if (question?.id != null && context.mounted) {
    final addImage = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Вопрос сохранён!'),
        content: const Text('Добавить фото контекста?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Нет'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Добавить фото'),
          ),
        ],
      ),
    );

    if (addImage == true && context.mounted) {
      context.push('/camera?category=question&entityId=${question!.id}');
    }
  }

  return question?.id != null;
}
