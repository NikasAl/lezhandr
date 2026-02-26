import 'package:flutter/material.dart';
import '../../../../data/models/solution.dart';
import '../../../../data/models/artifacts.dart';
import '../../../widgets/shared/persona_selector.dart';
import '../../../widgets/shared/markdown_with_math.dart';
import '../../../widgets/shared/thinking_indicator.dart';

/// Solution text section with edit and OCR capability
class SolutionTextSection extends StatelessWidget {
  final SolutionModel solution;
  final bool isEditing;
  final TextEditingController controller;
  final VoidCallback onSave;
  final VoidCallback onToggleEdit;
  final VoidCallback onClear;
  final VoidCallback onOcr;
  final bool isOcrLoading;
  final PersonaId? ocrPersona;
  final bool isOwner;

  const SolutionTextSection({
    super.key,
    required this.solution,
    required this.isEditing,
    required this.controller,
    required this.onSave,
    required this.onToggleEdit,
    required this.onClear,
    required this.onOcr,
    required this.isOcrLoading,
    this.ocrPersona,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.article_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Текст решения',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                // Action buttons for owner
                if (isOwner) ...[
                  // OCR button
                  if (!isEditing)
                    IconButton(
                      icon: isOcrLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      onPressed: isOcrLoading ? null : onOcr,
                      tooltip: isOcrLoading 
                          ? '${ocrPersona?.displayName ?? "Персонаж"} думает...'
                          : 'OCR',
                      iconSize: 20,
                      visualDensity: VisualDensity.compact,
                    ),
                  // Edit/View toggle button
                  IconButton(
                    icon: Icon(isEditing ? Icons.visibility : Icons.edit),
                    onPressed: onToggleEdit,
                    tooltip: isEditing ? 'Просмотр' : 'Редактировать',
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // Show thinking indicator when OCR is loading
            if (isOcrLoading)
              ThinkingIndicator(persona: ocrPersona ?? PersonaId.petrovich)
            else if (isEditing)
              Column(
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Введите текст решения...',
                    ),
                    maxLines: 8,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Clear button (icon only)
                      IconButton(
                        onPressed: onClear,
                        icon: const Icon(Icons.clear),
                        tooltip: 'Очистить',
                        iconSize: 20,
                        visualDensity: VisualDensity.compact,
                      ),
                      // Reset button
                      TextButton(
                        onPressed: () {
                          controller.text = solution.solutionText ?? '';
                        },
                        child: const Text('Сбросить'),
                      ),
                      // Save button
                      FilledButton.icon(
                        onPressed: onSave,
                        icon: const Icon(Icons.save, size: 18),
                        label: const Text('Сохранить'),
                      ),
                    ],
                  ),
                ],
              )
            else if (solution.hasText)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: MarkdownWithMath(
                  text: solution.solutionText!,
                  textStyle: Theme.of(context).textTheme.bodyLarge,
                ),
              )
            else
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.edit_note,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Текст решения отсутствует',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    if (solution.hasImage)
                      Text(
                        'Используйте OCR для распознавания',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
