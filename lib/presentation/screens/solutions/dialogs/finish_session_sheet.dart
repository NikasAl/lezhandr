import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/solution.dart';
import '../../../providers/solutions_provider.dart';
import '../../../providers/gamification_provider.dart';

/// Shows finish session bottom sheet with options to pause or complete
void showFinishSessionSheet({
  required BuildContext context,
  required WidgetRef ref,
  required int solutionId,
  required Duration elapsed,
  required double existingMinutes,
  required DateTime startTime,
  required String Function(Duration) formatDuration,
}) {
  int difficulty = 3;
  double quality = 1.0;
  final notesController = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setModalState) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Text(
                'Завершение сессии',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Время сессии: ${formatDuration(elapsed)}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              if (existingMinutes > 0)
                Text(
                  'Ранее: ${existingMinutes.toStringAsFixed(0)} мин',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              const SizedBox(height: 24),

              // Pause option
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        // Just save session time, keep active
                        await ref
                            .read(solutionNotifierProvider.notifier)
                            .createSession(
                              SessionCreate(
                                solutionId: solutionId,
                                startTime: startTime,
                                endTime: DateTime.now(),
                                duration: elapsed.inMinutes.toDouble(),
                              ),
                            );
                        if (context.mounted) {
                          // Get problemId from solution for cache invalidation
                          final solutionAsync = ref.read(solutionProvider(solutionId));
                          final problemId = solutionAsync.valueOrNull?.problemId;
                          _refreshHomeData(ref, problemId: problemId);
                          Navigator.pop(sheetContext);
                          context.go('/main/home');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Сессия сохранена. Задача осталась активной.'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.pause),
                      label: const Text('Продолжить позже'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Finalize option
              ExpansionTile(
                title: const Text('Завершить задачу'),
                subtitle: const Text('Указать сложность и качество'),
                childrenPadding: const EdgeInsets.only(top: 8, bottom: 16),
                children: [
                  // Difficulty
                  Row(
                    children: [
                      const Text('Сложность: '),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: List.generate(5, (i) {
                            final value = i + 1;
                            return GestureDetector(
                              onTap: () => setModalState(() => difficulty = value),
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  Icons.star,
                                  size: 32,
                                  color: difficulty >= value ? Colors.amber : Colors.grey,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Quality
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Качество:',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: quality,
                          min: 0.1,
                          max: 1.0,
                          divisions: 9,
                          label: quality.toStringAsFixed(1),
                          onChanged: (value) => setModalState(() => quality = value),
                        ),
                      ),
                      SizedBox(
                        width: 32,
                        child: Text(
                          quality.toStringAsFixed(1),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Notes
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Заметки',
                      hintText: 'Ваши мысли о задаче...',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Finalize button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        // Create session record
                        await ref
                            .read(solutionNotifierProvider.notifier)
                            .createSession(
                              SessionCreate(
                                solutionId: solutionId,
                                startTime: startTime,
                                endTime: DateTime.now(),
                                duration: elapsed.inMinutes.toDouble(),
                              ),
                            );

                        // Finish solution
                        final result = await ref
                            .read(solutionNotifierProvider.notifier)
                            .finishSolution(
                              solutionId,
                              status: 'completed',
                              difficulty: difficulty,
                              quality: quality,
                              notes: notesController.text,
                            );

                        if (context.mounted) {
                          _refreshHomeData(ref, problemId: result?.problemId);
                          Navigator.pop(sheetContext);
                          context.go('/main/home');
                          if (result != null && result.xpEarned != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('🏆 Задача выполнена! XP: ${result.xpEarned}'),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.flag),
                      label: const Text('Завершить задачу'),
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
}

/// Helper to refresh home screen data
void _refreshHomeData(WidgetRef ref, {int? problemId}) {
  ref.invalidate(activeSolutionsProvider);
  ref.invalidate(gamificationMeProvider);
  if (problemId != null) {
    ref.invalidate(problemSolutionsProvider(problemId));
  }
}
