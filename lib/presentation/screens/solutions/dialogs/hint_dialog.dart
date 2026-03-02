import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/artifacts.dart';
import '../../../providers/artifacts_provider.dart';
import '../../../providers/billing_provider.dart';
import '../../../widgets/shared/persona_selector.dart';
import 'hint_detail_dialog.dart';

/// Shows hint creation flow with multiple steps as bottom sheets
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
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => _HintSheetContent(
      controller: notesController,
    ),
  );

  // Always dispose controller after sheet is closed
  notesController.dispose();

  if (confirmed != true) {
    return false;
  }

  // Step 2: Create hint draft
  final hint = await ref.read(hintNotifierProvider.notifier).createDraft(
    solutionId: solutionId,
    userNotes: notesController.text,
  );

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
    final addImage = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SuccessSheet(
        title: 'Запрос создан',
        subtitle: 'Добавить фото контекста?',
      ),
    );

    if (addImage == true && context.mounted) {
      context.push('/camera?category=hint&entityId=${hint.id}');
    }
  }

  // Step 4: Select persona
  if (context.mounted) {
    final billing = ref.read(billingBalanceProvider);
    final freeUsesLeft = billing.value?.freeUsesLeft;
    final balance = billing.value?.balance;

    final persona = await showPersonaSheet(
      context,
      ref,
      defaultPersona: PersonaId.basis,
      freeUsesLeft: freeUsesLeft,
      balance: balance,
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

/// Hint sheet content as StatefulWidget to properly manage state
class _HintSheetContent extends StatefulWidget {
  final TextEditingController controller;

  const _HintSheetContent({required this.controller});

  @override
  State<_HintSheetContent> createState() => _HintSheetContentState();
}

class _HintSheetContentState extends State<_HintSheetContent> {
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
                    color: Colors.purple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tips_and_updates_outlined, color: Colors.purple, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Запросить подсказку',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Notes input
            TextField(
              controller: widget.controller,
              decoration: const InputDecoration(
                labelText: 'В чём проблема?',
                hintText: 'Опишите, что не получается...',
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
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Далее'),
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

/// Simple success sheet without StatefulBuilder
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
