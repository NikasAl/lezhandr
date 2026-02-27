import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/problem.dart';
import '../../../data/models/solution.dart';
import '../../providers/solutions_provider.dart';

/// List of solutions for a problem
class SolutionsList extends ConsumerWidget {
  final int problemId;
  final int? currentUserId;

  const SolutionsList({
    super.key,
    required this.problemId,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final solutions = ref.watch(problemSolutionsProvider(problemId));
    
    return solutions.when(
      data: (solutionList) {
        if (solutionList.isEmpty) {
          return _EmptySolutionsCard();
        }
        return Column(
          children: solutionList.map((solution) {
            return _SolutionCard(
              solution: solution,
              isOwner: currentUserId == solution.addedBy?.id,
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox(),
    );
  }
}

/// Individual solution card
class _SolutionCard extends StatelessWidget {
  final SolutionModel solution;
  final bool isOwner;

  const _SolutionCard({
    required this.solution,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    final isBlockedActive = solution.isActive && !isOwner;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _StatusIcon(solution: solution),
        title: _SolutionTitle(solution: solution),
        subtitle: _SolutionSubtitle(solution: solution),
        trailing: isBlockedActive
            ? Tooltip(
                message: 'Другой пользователь решает',
                child: Icon(
                  Icons.lock_outline,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            : const Icon(Icons.chevron_right),
        onTap: isBlockedActive
            ? () => _showBlockedMessage(context)
            : () => _navigateToSolution(context),
      ),
    );
  }

  void _showBlockedMessage(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🔒 ${solution.addedBy?.displayName ?? "Другой пользователь"} '
          'еще решает эту задачу. Решение пока не готово для просмотра.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToSolution(BuildContext context) {
    if (solution.isActive) {
      context.push('/session/${solution.id}?existingMinutes=${solution.totalMinutes}');
    } else {
      context.push('/solutions/${solution.id}');
    }
  }
}

/// Solution status icon
class _StatusIcon extends StatelessWidget {
  final SolutionModel solution;

  const _StatusIcon({required this.solution});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData iconData;
    
    if (solution.isActive) {
      color = Colors.green;
      iconData = Icons.timer;
    } else if (solution.isCompleted) {
      color = Colors.blue;
      iconData = Icons.check_circle;
    } else {
      color = Colors.orange;
      iconData = Icons.pause_circle;
    }
    
    return Icon(iconData, color: color);
  }
}

/// Solution title with owner name
class _SolutionTitle extends StatelessWidget {
  final SolutionModel solution;

  const _SolutionTitle({required this.solution});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(solution.statusText),
        if (solution.addedBy != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '• ${solution.addedBy!.displayName}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

/// Solution subtitle with stats
class _SolutionSubtitle extends StatelessWidget {
  final SolutionModel solution;

  const _SolutionSubtitle({required this.solution});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('${solution.totalMinutes.toStringAsFixed(0)} мин'),
        if (solution.xpEarned != null) ...[
          const SizedBox(width: 8),
          Icon(Icons.star, size: 14, color: Colors.amber[700]),
          Text(
            ' ${solution.xpEarned!.toStringAsFixed(0)} XP',
            style: TextStyle(color: Colors.amber[700]),
          ),
        ],
        if (solution.hasText) ...[
          const SizedBox(width: 8),
          const Icon(Icons.article, size: 14, color: Colors.grey),
        ],
        if (solution.hasImage) ...[
          const SizedBox(width: 8),
          const Icon(Icons.photo, size: 14, color: Colors.grey),
        ],
      ],
    );
  }
}

/// Empty state when no solutions
class _EmptySolutionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                'Нет решений',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
