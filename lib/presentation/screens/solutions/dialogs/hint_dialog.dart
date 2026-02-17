import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/artifacts.dart';
import '../../providers/artifacts_provider.dart';
import '../../widgets/shared/persona_selector.dart';
import 'hint_detail_dialog.dart';

/// Shows hint creation flow with multiple steps
/// 1. Get user notes
/// 2. Create draft
/// 3. Offer to add image
/// 4. Select persona and generate
/// 5. Show result
Future<bool> showHintDialog({
  required BuildContext context,
  required WidgetRef ref,
  required int solutionId,
}) async {
  final notesController = TextEditingController();

  // Step 1: Get user notes
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.lightbulb_outline),
          SizedBox(width: 8),
          Text('Запросить подсказку'),
        ],
      ),
      content: TextField(
        controller: notesController,
        decoration: const InputDecoration(
          labelText: 'В чём проблема?',
          hintText: 'Опишите, что не получается...',
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
          child: const Text('Далее'),
        ),
      ],
    ),
  );

  if (confirmed != true) {
    notesController.dispose();
    return false;
  }

  // Step 2: Create hint draft
  final hint = await ref.read(hintNotifierProvider.notifier).createDraft(
    solutionId: solutionId,
    userNotes: notesController.text,
  );

  notesController.dispose();

  // Refresh list
  ref.invalidate(hintsProvider(solutionId));

  if (hint == null || hint.id == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось создать запрос подсказки')),
      );
    }
    return false;
  }

  // Step 3: Offer to add image
  if (context.mounted) {
    final addImage = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Запрос создан'),
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
      context.push('/camera?category=hint&entityId=${hint.id}');
    }
  }

  // Step 4: Select persona
  if (context.mounted) {
    final persona = await showPersonaSheet(
      context,
      defaultPersona: PersonaId.basis,
    );

    if (persona != null) {
      // Step 5: Generate hint
      final result = await ref.read(hintNotifierProvider.notifier).generate(
        hintId: hint.id!,
        persona: persona,
      );

      // Refresh list after generation
      ref.invalidate(hintsProvider(solutionId));

      if (context.mounted) {
        // Show hint detail dialog, even if generation failed
        // This allows user to retry with different model
        showHintDetailDialog(
          context: context,
          ref: ref,
          hint: result ?? hint,
          solutionId: solutionId,
          isRegenerating: result == null || !result.hasHint,
        );
      }
    }
  }

  return true;
}
