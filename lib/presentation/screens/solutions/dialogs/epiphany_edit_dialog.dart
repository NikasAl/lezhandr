import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/artifacts.dart';
import '../../../providers/artifacts_provider.dart';

/// Result from epiphany edit dialog
class _EpiphanyEditResult {
  final bool confirmed;
  final String? description;
  final int magnitude;

  _EpiphanyEditResult({
    required this.confirmed,
    this.description,
    this.magnitude = 1,
  });
}

/// Shows epiphany edit bottom sheet
/// Returns true if epiphany was updated successfully
Future<bool> showEpiphanyEditDialog({
  required BuildContext context,
  required WidgetRef ref,
  required EpiphanyModel epiphany,
  required int solutionId,
}) async {
  final result = await showModalBottomSheet<_EpiphanyEditResult>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => _EpiphanyEditSheetContent(
      epiphany: epiphany,
    ),
  );

  if (result == null || !result.confirmed) {
    return false;
  }

  // Update epiphany
  final updated = await ref.read(epiphanyNotifierProvider.notifier).update(
    epiphanyId: epiphany.id!,
    description: result.description,
    magnitude: result.magnitude,
  );

  if (updated != null) {
    ref.invalidate(epiphaniesProvider(solutionId));
    return true;
  }

  return false;
}

/// Shows epiphany delete confirmation
Future<bool> showEpiphanyDeleteDialog({
  required BuildContext context,
  required WidgetRef ref,
  required EpiphanyModel epiphany,
  required int solutionId,
}) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _DeleteConfirmSheet(
      title: 'Удалить озарение?',
      subtitle: 'Это действие нельзя отменить.',
    ),
  );

  if (confirmed == true) {
    final success = await ref.read(epiphanyNotifierProvider.notifier).delete(epiphany.id!);
    if (success) {
      ref.invalidate(epiphaniesProvider(solutionId));
      return true;
    }
  }

  return false;
}

/// Epiphany edit sheet content
class _EpiphanyEditSheetContent extends StatefulWidget {
  final EpiphanyModel epiphany;

  const _EpiphanyEditSheetContent({required this.epiphany});

  @override
  State<_EpiphanyEditSheetContent> createState() => _EpiphanyEditSheetContentState();
}

class _EpiphanyEditSheetContentState extends State<_EpiphanyEditSheetContent> {
  late final TextEditingController _controller;
  late int _magnitude;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.epiphany.description ?? '');
    _magnitude = widget.epiphany.magnitude ?? 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_EpiphanyEditResult(
      confirmed: true,
      description: _controller.text,
      magnitude: _magnitude,
    ));
  }

  void _cancel() {
    Navigator.of(context).pop(_EpiphanyEditResult(confirmed: false));
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
                  child: const Icon(Icons.edit_outlined, color: Colors.amber, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Редактировать озарение',
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
                labelText: 'Описание',
                hintText: 'Опишите ваше озарение',
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

/// Delete confirmation sheet
class _DeleteConfirmSheet extends StatelessWidget {
  final String title;
  final String subtitle;

  const _DeleteConfirmSheet({
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

          // Warning icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.delete_outline, color: Colors.red, size: 32),
          ),
          const SizedBox(height: 16),

          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

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
                  icon: const Icon(Icons.delete),
                  label: const Text('Удалить'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
