import 'package:flutter/material.dart';
import '../../../../data/models/problem.dart';

/// Problem header with source, reference and owner info
class ProblemHeader extends StatelessWidget {
  final ProblemModel problem;

  const ProblemHeader({
    super.key,
    required this.problem,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // First row: source + reference number
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Source name - can wrap to multiple lines
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  problem.sourceName,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Reference number - stays on right
            Text(
              problem.reference,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
        
        // Second row: user info (if exists)
        if (problem.addedBy != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                problem.addedBy!.displayName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Tags row with optional edit button
class ProblemTagsRow extends StatelessWidget {
  final List<TagModel> tags;
  final bool canEdit;
  final VoidCallback? onEdit;

  const ProblemTagsRow({
    super.key,
    required this.tags,
    this.canEdit = false,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (tags.isNotEmpty)
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: tags.map((tag) {
                return Chip(
                  label: Text(tag.name),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          )
        else
          Expanded(
            child: Text(
              'Нет тегов',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        if (canEdit) ...[
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.sell_outlined, size: 18),
            label: const Text('Теги'),
          ),
        ],
      ],
    );
  }
}
