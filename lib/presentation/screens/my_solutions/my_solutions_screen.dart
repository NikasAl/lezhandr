import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/solution.dart';
import '../../../core/utils/russian_plural.dart';
import '../../providers/providers.dart';
import '../../providers/solutions_provider.dart';
import '../../widgets/shared/error_display.dart';
import '../../widgets/shared/adaptive_layout.dart';
import '../../widgets/motivation/motivation_card.dart';
import '../../../core/motivation/motivation_engine.dart';
import '../../../core/motivation/motivation_models.dart';
import '../library/widgets/load_more_card.dart';

/// My Solutions screen - shows user's solution history
class MySolutionsScreen extends ConsumerStatefulWidget {
  const MySolutionsScreen({super.key});

  @override
  ConsumerState<MySolutionsScreen> createState() => _MySolutionsScreenState();
}

class _MySolutionsScreenState extends ConsumerState<MySolutionsScreen> {
  SolutionStatus? _selectedStatus;
  
  // Track solutions being deleted to show loading state
  final Set<int> _deletingSolutions = {};
  
  // Accumulated solutions list for infinite scroll
  List<SolutionModel> _accumulatedSolutions = [];
  int _totalSolutions = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  final ScrollController _scrollController = ScrollController(keepScrollOffset: true);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _resetPagination() {
    _accumulatedSolutions = [];
    _totalSolutions = 0;
    _hasMore = true;
    _isLoadingMore = false;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final filter = MySolutionsFilter(
        status: _selectedStatus,
        limit: 20,
        offset: _accumulatedSolutions.length,
      );

      final repo = ref.read(solutionsRepositoryProvider);
      final response = await repo.getSolutions(
        status: _selectedStatus,
        mineOnly: true,
        limit: 20,
        offset: _accumulatedSolutions.length,
      );

      if (mounted) {
        setState(() {
          final existingIds = _accumulatedSolutions.map((s) => s.id).toSet();
          final newItems = response.items.where((s) => !existingIds.contains(s.id)).toList();
          _accumulatedSolutions = [..._accumulatedSolutions, ...newItems];
          _totalSolutions = response.total;
          _hasMore = response.hasMore;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseFilter = MySolutionsFilter(
      status: _selectedStatus,
      limit: 20,
      offset: 0,
    );

    final solutionsAsync = ref.watch(mySolutionsProvider(baseFilter));

    // Update accumulated list when initial data arrives
    solutionsAsync.whenData((response) {
      if (_accumulatedSolutions.isEmpty) {
        _accumulatedSolutions = response.items;
        _totalSolutions = response.total;
        _hasMore = response.hasMore;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои решения'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Фильтр',
          ),
        ],
      ),
      body: AdaptiveLayout(
        maxWidth: 900,
        child: Column(
          children: [
            // Status filter chips
            _buildFilterChips(),
            
            // Active filter indicator
            if (_selectedStatus != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_alt,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Фильтр: ${_getStatusText(_selectedStatus!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedStatus = null;
                          _resetPagination();
                          ref.invalidate(mySolutionsProvider);
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            const Divider(height: 1),

            // Solutions list
            Expanded(
              child: solutionsAsync.when(
                data: (response) {
                  final solutions = _accumulatedSolutions;

                  if (solutions.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Group solutions by problem
                  final groupedSolutions = _groupSolutionsByProblem(solutions);

                  return Column(
                    children: [
                      // Stats summary
                      _buildStatsSummary(solutions),

                      // Hint about long press to delete
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.touch_app_outlined,
                              size: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Долгое нажатие — удалить решение',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Solutions list
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: groupedSolutions.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == groupedSolutions.length && _hasMore) {
                              return LoadMoreCard(
                                isLoading: _isLoadingMore,
                                onLoadMore: _loadMore,
                                remainingCount: _totalSolutions - solutions.length,
                              );
                            }

                            final group = groupedSolutions[index];
                            return _ProblemSolutionGroup(
                              problemId: group.problemId,
                              problemReference: group.problemReference,
                              sourceName: group.sourceName,
                              solutions: group.solutions,
                              deletingSolutions: _deletingSolutions,
                              onDelete: _deleteSolution,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ErrorDisplay(
                  error: error,
                  onRetry: () {
                    ref.invalidate(mySolutionsProvider);
                    _resetPagination();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _StatusFilterChip(
              label: 'Все',
              selected: _selectedStatus == null,
              onTap: () {
                setState(() {
                  _selectedStatus = null;
                  _resetPagination();
                  ref.invalidate(mySolutionsProvider);
                });
              },
            ),
            const SizedBox(width: 8),
            _StatusFilterChip(
              label: 'В процессе',
              icon: Icons.play_circle_outline,
              color: Colors.blue,
              selected: _selectedStatus == SolutionStatus.active,
              onTap: () {
                setState(() {
                  _selectedStatus = SolutionStatus.active;
                  _resetPagination();
                  ref.invalidate(mySolutionsProvider);
                });
              },
            ),
            const SizedBox(width: 8),
            _StatusFilterChip(
              label: 'Завершено',
              icon: Icons.check_circle_outline,
              color: Colors.green,
              selected: _selectedStatus == SolutionStatus.completed,
              onTap: () {
                setState(() {
                  _selectedStatus = SolutionStatus.completed;
                  _resetPagination();
                  ref.invalidate(mySolutionsProvider);
                });
              },
            ),
            const SizedBox(width: 8),
            _StatusFilterChip(
              label: 'Отложено',
              icon: Icons.pause_circle_outline,
              color: Colors.orange,
              selected: _selectedStatus == SolutionStatus.abandoned,
              onTap: () {
                setState(() {
                  _selectedStatus = SolutionStatus.abandoned;
                  _resetPagination();
                  ref.invalidate(mySolutionsProvider);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSummary(List<SolutionModel> solutions) {
    final completedSolutions = solutions.where((s) => s.isCompleted).toList();
    final totalXp = completedSolutions.fold<double>(0, (sum, s) => sum + (s.xpEarned ?? 0));
    final totalTime = solutions.fold<double>(0, (sum, s) => sum + s.totalMinutes);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.star,
            iconColor: Colors.amber,
            label: 'XP заработано',
            value: totalXp.toStringAsFixed(0),
          ),
          Container(
            height: 32,
            width: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          _StatItem(
            icon: Icons.timer_outlined,
            iconColor: Colors.blue,
            label: 'Время решения',
            value: _formatTotalTime(totalTime),
          ),
          Container(
            height: 32,
            width: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          _StatItem(
            icon: Icons.check_circle,
            iconColor: Colors.green,
            label: 'Решено',
            value: '${completedSolutions.length}',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final motivationEngine = MotivationEngine();
    final motivation = motivationEngine.getTextForContext(
      MotivationContext.current(
        sessionState: SessionState.idle,
        streakDays: 0,
        tasksCompletedToday: 0,
        totalTasksCompleted: 0,
        totalXp: 0,
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'История пуста',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Здесь будут отображаться ваши решённые задачи с подробной статистикой',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (motivation != null) ...[
            MotivationCard(
              motivation: motivation,
              showAuthor: false,
              animate: false,
            ),
            const SizedBox(height: 24),
          ],
          FilledButton.icon(
            onPressed: () => context.go('/main/library'),
            icon: const Icon(Icons.add_task),
            label: const Text('Начать решать'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: context.isWideScreen ? 500 : double.infinity,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Фильтр по статусу',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterOption(
                    label: 'Все решения',
                    selected: _selectedStatus == null,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedStatus = null;
                        _resetPagination();
                        ref.invalidate(mySolutionsProvider);
                      });
                    },
                  ),
                  _FilterOption(
                    label: 'В процессе',
                    selected: _selectedStatus == SolutionStatus.active,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedStatus = SolutionStatus.active;
                        _resetPagination();
                        ref.invalidate(mySolutionsProvider);
                      });
                    },
                  ),
                  _FilterOption(
                    label: 'Завершено',
                    selected: _selectedStatus == SolutionStatus.completed,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedStatus = SolutionStatus.completed;
                        _resetPagination();
                        ref.invalidate(mySolutionsProvider);
                      });
                    },
                  ),
                  _FilterOption(
                    label: 'Отложено',
                    selected: _selectedStatus == SolutionStatus.abandoned,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedStatus = SolutionStatus.abandoned;
                        _resetPagination();
                        ref.invalidate(mySolutionsProvider);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_ProblemGroup> _groupSolutionsByProblem(List<SolutionModel> solutions) {
    final groups = <int, _ProblemGroup>{};

    for (final solution in solutions) {
      final problemId = solution.problemId ?? 0;
      
      if (!groups.containsKey(problemId)) {
        groups[problemId] = _ProblemGroup(
          problemId: problemId,
          problemReference: solution.problem?.reference ?? 'Задача #$problemId',
          sourceName: solution.problem?.sourceName,
          solutions: [],
        );
      }
      
      groups[problemId]!.solutions.add(solution);
    }

    // Sort solutions within each group by date (newest first)
    for (final group in groups.values) {
      group.solutions.sort((a, b) {
        final dateA = a.createdAt ?? DateTime(1970);
        final dateB = b.createdAt ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });
    }

    return groups.values.toList();
  }

  String _getStatusText(SolutionStatus status) {
    switch (status) {
      case SolutionStatus.active:
        return 'В процессе';
      case SolutionStatus.completed:
        return 'Завершено';
      case SolutionStatus.abandoned:
        return 'Отложено';
    }
  }

  String _formatTotalTime(double minutes) {
    if (minutes < 60) {
      return '${minutes.toStringAsFixed(0)} мин';
    }
    final hours = (minutes / 60).floor();
    final mins = (minutes % 60).round();
    return '$hours ч $mins мин';
  }

  /// Delete a solution with confirmation
  Future<void> _deleteSolution(SolutionModel solution) async {
    final confirmed = await showConstrainedDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить решение?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Это действие нельзя отменить.'),
            const SizedBox(height: 12),
            Text(
              'Будут удалены:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text('• Сессии решения'),
            Text('• Озарения и вопросы'),
            Text('• Подсказки'),
            if (solution.isCompleted && solution.xpEarned != null && solution.xpEarned! > 0)
              Text('• XP за это решение'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _deletingSolutions.add(solution.id);
    });

    try {
      final repo = ref.read(solutionsRepositoryProvider);
      final result = await repo.deleteSolution(solution.id);

      if (mounted) {
        // Remove from local list
        setState(() {
          _accumulatedSolutions.removeWhere((s) => s.id == solution.id);
          _deletingSolutions.remove(solution.id);
        });

        // Show result
        final stats = result['stats'] as Map<String, dynamic>?;
        final deletedImages = stats?['deleted_images'] ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Решение удалено'),
            backgroundColor: Colors.green,
          ),
        );

        // Invalidate providers to refresh
        ref.invalidate(mySolutionsProvider);
        ref.invalidate(activeSolutionsProvider);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _deletingSolutions.remove(solution.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка удаления: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _ProblemGroup {
  final int problemId;
  final String problemReference;
  final String? sourceName;
  final List<SolutionModel> solutions;

  _ProblemGroup({
    required this.problemId,
    required this.problemReference,
    this.sourceName,
    required this.solutions,
  });
}

class _ProblemSolutionGroup extends StatelessWidget {
  final int problemId;
  final String problemReference;
  final String? sourceName;
  final List<SolutionModel> solutions;
  final Set<int> deletingSolutions;
  final Function(SolutionModel) onDelete;

  const _ProblemSolutionGroup({
    required this.problemId,
    required this.problemReference,
    this.sourceName,
    required this.solutions,
    required this.deletingSolutions,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Problem header
          InkWell(
            onTap: () => context.push('/problems/$problemId'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.assignment_outlined,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          problemReference,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (sourceName != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            sourceName!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          
          const Divider(height: 1),
          
          // Solutions list
          ...solutions.asMap().entries.map((entry) {
            final index = entry.key;
            final solution = entry.value;
            return _SolutionTile(
              solution: solution,
              showProblemTitle: false,
              isFirst: index == 0,
              isLast: index == solutions.length - 1,
              isDeleting: deletingSolutions.contains(solution.id),
              onDelete: () => onDelete(solution),
            );
          }),
        ],
      ),
    );
  }
}

class _SolutionTile extends StatelessWidget {
  final SolutionModel solution;
  final bool showProblemTitle;
  final bool isFirst;
  final bool isLast;
  final bool isDeleting;
  final VoidCallback? onDelete;

  const _SolutionTile({
    required this.solution,
    this.showProblemTitle = true,
    this.isFirst = false,
    this.isLast = false,
    this.isDeleting = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(solution.status);
    
    return InkWell(
      onTap: isDeleting ? null : () => context.push('/solutions/${solution.id}'),
      onLongPress: isDeleting ? null : onDelete,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, isFirst ? 12 : 8, 16, isLast ? 12 : 8),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            
            // Date and status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        solution.statusText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (solution.createdAt != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• ${_formatDate(solution.createdAt!)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Time spent
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        RussianPlural.formatMinutes(solution.totalMinutes.toInt()),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      
                      // XP earned (if completed)
                      if (solution.isCompleted && solution.xpEarned != null) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+${solution.xpEarned!.toStringAsFixed(0)} XP',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.amber,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      
                      // Difficulty (if set)
                      if (solution.personalDifficulty != null) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.fitness_center,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ': ${solution.personalDifficulty} / 5',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Loading indicator when deleting
            if (isDeleting)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(SolutionStatus status) {
    switch (status) {
      case SolutionStatus.active:
        return Colors.blue;
      case SolutionStatus.completed:
        return Colors.green;
      case SolutionStatus.abandoned:
        return Colors.orange;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'сегодня';
    } else if (difference.inDays == 1) {
      return 'вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  const _StatusFilterChip({
    required this.label,
    this.icon,
    this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? (color ?? Theme.of(context).colorScheme.primary).withOpacity(0.15)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? (color ?? Theme.of(context).colorScheme.primary)
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: selected
                      ? (color ?? Theme.of(context).colorScheme.primary)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected
                      ? (color ?? Theme.of(context).colorScheme.primary)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
