import 'package:flutter/material.dart';
import '../../../../data/models/solution.dart';
import '../../../../data/models/user.dart';

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
                      Row(
                        children: [
                          Text(
                            solution.statusText,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          // Moderation status badge
                          if (solution.isPending) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'на модерации',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ] else if (solution.isRejected) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'отклонено',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
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
                  tooltip: 'За сколько времени была решена эта задача',
                ),
                if (solution.xpEarned != null)
                  StatChip(
                    icon: Icons.star,
                    label: '${solution.xpEarned!.toStringAsFixed(0)} XP',
                    color: Colors.amber,
                    tooltip: 'Сколько XP было получено за эту задачу',
                  ),
                if (solution.personalDifficulty != null)
                  StatChip(
                    icon: Icons.fitness_center,
                    label: '${solution.personalDifficulty} / 5',
                    tooltip: 'Субъективная сложность задачи по шкале от 1 до 5',
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

/// Stat chip widget for displaying metrics with tooltip
class StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final String? tooltip;

  const StatChip({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Theme.of(context).colorScheme.primary;
    
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: chipColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: chipColor,
            ),
          ),
        ],
      ),
    );

    // If tooltip is provided, make it interactive
    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        preferBelow: false,
        verticalOffset: 0,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // Show snackbar with tooltip for better visibility
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(tooltip!),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                ),
              );
            },
            child: chip,
          ),
        ),
      );
    }

    return chip;
  }
}
