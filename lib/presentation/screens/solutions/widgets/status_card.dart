import 'package:flutter/material.dart';
import '../../../data/models/solution.dart';
import '../../../data/models/user.dart';

/// Status card showing solution status and stats
class SolutionStatusCard extends StatelessWidget {
  final SolutionModel solution;
  final UserPublicProfile? addedBy;

  const SolutionStatusCard({
    super.key,
    required this.solution,
    this.addedBy,
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
                Icon(
                  solution.isCompleted
                      ? Icons.check_circle
                      : solution.isActive
                          ? Icons.timer
                          : Icons.pause_circle,
                  color: solution.isCompleted
                      ? Colors.green
                      : solution.isActive
                          ? Colors.blue
                          : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        solution.statusText,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (addedBy != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              addedBy!.displayName,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatChip(
                  icon: Icons.timer_outlined,
                  label: '${solution.totalMinutes.toStringAsFixed(0)} мин',
                ),
                if (solution.xpEarned != null)
                  StatChip(
                    icon: Icons.star,
                    label: '${solution.xpEarned!.toStringAsFixed(0)} XP',
                    color: Colors.amber,
                  ),
                if (solution.personalDifficulty != null)
                  StatChip(
                    icon: Icons.fitness_center,
                    label: 'Сложность: ${solution.personalDifficulty}',
                  ),
              ],
            ),
            if (solution.userNotes != null && solution.userNotes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Заметки: ${solution.userNotes}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Stat chip widget for displaying metrics
class StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const StatChip({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? Theme.of(context).colorScheme.primary).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ?? Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
