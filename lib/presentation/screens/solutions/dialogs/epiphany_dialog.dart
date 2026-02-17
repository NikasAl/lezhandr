import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/artifacts_provider.dart';

/// Shows epiphany creation dialog and handles the flow
/// Returns true if epiphany was created successfully
Future<bool> showEpiphanyDialog({
  required BuildContext context,
  required WidgetRef ref,
  required int solutionId,
}) async {
  final controller = TextEditingController();
  int magnitude = 1;

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lightbulb, color: Colors.amber),
            SizedBox(width: 8),
            Text('Озарение'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Опишите ваше озарение...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Сила:'),
                const SizedBox(width: 8),
                ...List.generate(3, (i) {
                  return IconButton(
                    icon: Icon(
                      Icons.star,
                      color: i < magnitude ? Colors.amber : Colors.grey,
                    ),
                    onPressed: () => setState(() => magnitude = i + 1),
                  );
                }),
              ],
            ),
          ],
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
    ),
  );

  if (result != true || controller.text.isEmpty) {
    controller.dispose();
    return false;
  }

  // Create epiphany
  final epiphany = await ref.read(epiphanyNotifierProvider.notifier).create(
    solutionId: solutionId,
    description: controller.text,
    magnitude: magnitude,
  );

  controller.dispose();

  if (!context.mounted) return false;

  // Refresh list
  ref.invalidate(epiphaniesProvider(solutionId));

  // Offer to add image
  if (epiphany?.id != null && context.mounted) {
    final addImage = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lightbulb, color: Colors.amber),
            SizedBox(width: 8),
            Text('Озарение сохранено!'),
          ],
        ),
        content: const Text('Добавить схему/рисунок?'),
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
      context.push('/camera?category=epiphany&entityId=${epiphany!.id}');
    }
  }

  return epiphany?.id != null;
}
