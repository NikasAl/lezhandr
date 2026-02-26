import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/artifacts.dart';
import '../../providers/artifacts_provider.dart';
import '../../widgets/shared/markdown_with_math.dart';

/// Epiphanies section widget
class EpiphaniesSection extends ConsumerWidget {
  final int solutionId;

  const EpiphaniesSection({
    super.key,
    required this.solutionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final epiphanies = ref.watch(epiphaniesProvider(solutionId));

    return epiphanies.when(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();

        return Card(
          child: ExpansionTile(
            leading: const Icon(Icons.lightbulb_outline, color: Colors.amber),
            title: Text('Озарения (${list.length})'),
            children: list.map((e) {
              return EpiphanyItem(epiphany: e);
            }).toList(),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Expandable epiphany item
class EpiphanyItem extends StatefulWidget {
  final EpiphanyModel epiphany;

  const EpiphanyItem({
    super.key,
    required this.epiphany,
  });

  @override
  State<EpiphanyItem> createState() => _EpiphanyItemState();
}

class _EpiphanyItemState extends State<EpiphanyItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final description = widget.epiphany.description ?? '';
    final isLongText = description.length > 100;
    
    return InkWell(
      onTap: isLongText ? () => setState(() => _isExpanded = !_isExpanded) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Star icon with magnitude
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.star,
                color: Colors.amber,
                size: 16 + (widget.epiphany.magnitude ?? 1) * 4,
              ),
            ),
            const SizedBox(width: 12),
            // Description text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownWithMath(
                    text: description,
                    maxLines: _isExpanded ? null : 2,
                    overflow: _isExpanded ? null : TextOverflow.ellipsis,
                    textStyle: Theme.of(context).textTheme.bodyMedium,
                  ),
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
