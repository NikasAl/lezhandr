import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/artifacts_provider.dart';

/// Shows epiphany creation bottom sheet and handles the flow
/// Returns true if epiphany was created successfully
Future<bool> showEpiphanyDialog({
  required BuildContext context,
  required WidgetRef ref,
  required int solutionId,
}) async {
  final controller = TextEditingController();
  int magnitude = 1;

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => StatefulBuilder(
      builder: (stateContext, setState) => Padding(
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
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Озарение',
                      style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Description input
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Опишите ваше озарение',
                  hintText: 'Что вдруг стало понятным?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                autofocus: true,
              ),
              const SizedBox(height: 20),
              
              // Magnitude selector
              Row(
                children: [
                  Text(
                    'Сила озарения:',
                    style: Theme.of(sheetContext).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 12),
                  ...List.generate(3, (i) {
                    return GestureDetector(
                      onTap: () => setState(() => magnitude = i + 1),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.star,
                          size: 32,
                          color: i < magnitude ? Colors.amber : Colors.grey.shade400,
                        ),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(false),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(sheetContext).pop(true),
                      icon: const Icon(Icons.save),
                      label: const Text('Сохранить'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  // Always dispose controller after sheet is closed
  controller.dispose();

  if (result != true) {
    return false;
  }
  
  if (controller.text.isEmpty) {
    return false;
  }

  // Create epiphany
  final epiphany = await ref.read(epiphanyNotifierProvider.notifier).create(
    solutionId: solutionId,
    description: controller.text,
    magnitude: magnitude,
  );

  if (!context.mounted) return false;

  // Refresh list
  ref.invalidate(epiphaniesProvider(solutionId));

  // Offer to add image
  if (epiphany?.id != null && context.mounted) {
    final addImage = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
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
              'Озарение сохранено!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Добавить схему или рисунок?',
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
      ),
    );

    if (addImage == true && context.mounted) {
      context.push('/camera?category=epiphany&entityId=${epiphany!.id}');
    }
  }

  return epiphany?.id != null;
}
