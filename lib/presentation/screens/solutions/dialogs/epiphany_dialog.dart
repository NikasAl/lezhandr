import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/artifacts_provider.dart';

/// Result data from epiphany sheet
class _EpiphanyResult {
  final bool confirmed;
  final String? description;
  final int magnitude;

  _EpiphanyResult({required this.confirmed, this.description, this.magnitude = 1});
}

/// Shows epiphany creation bottom sheet and handles the flow
/// Returns true if epiphany was created successfully
Future<bool> showEpiphanyDialog({
  required BuildContext context,
  required WidgetRef ref,
  required int solutionId,
}) async {
  // Step 1: Get user input
  final result = await showModalBottomSheet<_EpiphanyResult>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => const _EpiphanySheetContent(),
  );

  if (result == null || !result.confirmed || result.description == null || result.description!.isEmpty) {
    return false;
  }

  // Create epiphany
  final epiphany = await ref.read(epiphanyNotifierProvider.notifier).create(
    solutionId: solutionId,
    description: result.description!,
    magnitude: result.magnitude,
  );

  if (!context.mounted) return false;

  // Refresh list
  ref.invalidate(epiphaniesProvider(solutionId));

  // Offer to add image
  if (epiphany?.id != null && context.mounted) {
    final addImage = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _SuccessSheet(
        title: 'Озарение сохранено!',
        subtitle: 'Добавить схему или рисунок?',
      ),
    );

    if (addImage == true && context.mounted) {
      context.push('/camera?category=epiphany&entityId=${epiphany!.id}');
    }
  }

  return epiphany?.id != null;
}

/// Epiphany sheet content - manages its own controller
class _EpiphanySheetContent extends StatefulWidget {
  const _EpiphanySheetContent();

  @override
  State<_EpiphanySheetContent> createState() => _EpiphanySheetContentState();
}

class _EpiphanySheetContentState extends State<_EpiphanySheetContent> {
  late final TextEditingController _controller;
  int _magnitude = 1;

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
    Navigator.of(context).pop(_EpiphanyResult(
      confirmed: true,
      description: _controller.text,
      magnitude: _magnitude,
    ));
  }

  void _cancel() {
    Navigator.of(context).pop(_EpiphanyResult(confirmed: false));
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
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Озарение',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Description input
            TextField(
              controller: _controller,
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
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 12),
                ...List.generate(3, (i) {
                  return GestureDetector(
                    onTap: () => setState(() => _magnitude = i + 1),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.star,
                        size: 32,
                        color: i < _magnitude ? Colors.amber : Colors.grey.shade400,
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
