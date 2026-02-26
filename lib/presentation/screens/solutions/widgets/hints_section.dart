import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/artifacts.dart';
import '../../providers/artifacts_provider.dart';
import '../../widgets/shared/markdown_with_math.dart';

/// Hints section widget
class HintsSection extends ConsumerWidget {
  final int solutionId;

  const HintsSection({
    super.key,
    required this.solutionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hints = ref.watch(hintsProvider(solutionId));

    return hints.when(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();

        return Card(
          child: ExpansionTile(
            leading: Icon(
              Icons.lightbulb_outline,
              color: Theme.of(context).colorScheme.secondary,
            ),
            title: Text('Подсказки (${list.length})'),
            children: list.map((h) {
              return HintItem(hint: h);
            }).toList(),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Expandable hint item
class HintItem extends StatefulWidget {
  final HintModel hint;

  const HintItem({
    super.key,
    required this.hint,
  });

  @override
  State<HintItem> createState() => _HintItemState();
}

class _HintItemState extends State<HintItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final userNotes = widget.hint.userNotes ?? '';
    final hintText = widget.hint.hintText;
    final isLongText = userNotes.length > 100 || (hintText != null && hintText.length > 100);
    
    return InkWell(
      onTap: isLongText ? () => setState(() => _isExpanded = !_isExpanded) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              widget.hint.hasHint ? Icons.check_circle : Icons.hourglass_empty,
              color: widget.hint.hasHint ? Colors.green : Colors.orange,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User notes
                  if (userNotes.isNotEmpty) ...[
                    Text(
                      userNotes,
                      maxLines: _isExpanded ? null : 2,
                      overflow: _isExpanded ? null : TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Подсказка',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  // AI-generated hint text
                  if (hintText != null && hintText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.hint.aiModel != null) ...[
                            Text(
                              'AI: ${widget.hint.aiModel}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          MarkdownWithMath(
                            text: hintText,
                            maxLines: _isExpanded ? null : 3,
                            overflow: _isExpanded ? null : TextOverflow.ellipsis,
                            textStyle: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Expand/collapse button
                  if (isLongText) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: Text(
                        _isExpanded ? 'Свернуть' : 'Развернуть',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
