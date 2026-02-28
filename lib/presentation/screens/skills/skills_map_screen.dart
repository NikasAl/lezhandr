import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/concept_progress.dart';
import '../../providers/concepts_progress_provider.dart';
import '../../providers/providers.dart';

/// Skills Map Screen - shows user's concept mastery progress
class SkillsMapScreen extends ConsumerStatefulWidget {
  const SkillsMapScreen({super.key});

  @override
  ConsumerState<SkillsMapScreen> createState() => _SkillsMapScreenState();
}

class _SkillsMapScreenState extends ConsumerState<SkillsMapScreen> {
  ConceptSortBy _sortBy = ConceptSortBy.mastery;
  int? _tierFilter;
  int _currentPage = 0;
  final int _pageSize = 20;
  
  // Accumulated list for pagination
  List<ConceptProgressModel> _accumulatedConcepts = [];
  int _totalConcepts = 0;
  bool _hasMore = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _accumulatedConcepts = [];
    _currentPage = 0;
    _hasMore = true;
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoading) return;
    
    setState(() => _isLoading = true);

    try {
      // Call repository directly to avoid FutureProvider.family caching issues
      final repo = ref.read(conceptsProgressRepositoryProvider);
      final response = await repo.getMyConceptProgress(
        sortBy: _sortBy.value,
        filterTier: _tierFilter,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      if (mounted) {
        setState(() {
          _accumulatedConcepts.addAll(response.items);
          _totalConcepts = response.total;
          _hasMore = response.hasMore;
          _currentPage++;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    }
  }

  void _changeSort(ConceptSortBy newSort) {
    if (_sortBy != newSort) {
      setState(() {
        _sortBy = newSort;
        _accumulatedConcepts = [];
        _currentPage = 0;
        _hasMore = true;
      });
      _loadMore();
    }
  }

  void _toggleTierFilter(int? tier) {
    if (_tierFilter != tier) {
      setState(() {
        _tierFilter = tier;
        _accumulatedConcepts = [];
        _currentPage = 0;
        _hasMore = true;
      });
      _loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(conceptStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Моя карта навыков'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(conceptStatsProvider);
              ref.invalidate(conceptProgressListProvider);
              _loadData();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(conceptStatsProvider);
          ref.invalidate(conceptProgressListProvider);
          _loadData();
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: CustomScrollView(
          slivers: [
            // Stats section
            SliverToBoxAdapter(
              child: statsAsync.when(
                data: (stats) => _StatsCard(stats: stats),
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Ошибка загрузки статистики: $e'),
                ),
              ),
            ),

            // Filters and sort
            SliverToBoxAdapter(
              child: _FiltersSection(
                sortBy: _sortBy,
                tierFilter: _tierFilter,
                onSortChanged: _changeSort,
                onTierFilterChanged: _toggleTierFilter,
              ),
            ),

            // Total count
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Всего концептов: $_totalConcepts',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),

            // Concepts list
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index < _accumulatedConcepts.length) {
                    final concept = _accumulatedConcepts[index];
                    return _ConceptCard(
                      concept: concept,
                      onTap: () => _showConceptDetail(context, concept),
                    );
                  } else if (_hasMore) {
                    // Load more trigger
                    _loadMore();
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return null;
                },
                childCount: _accumulatedConcepts.length + (_hasMore ? 1 : 0),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }

  void _showConceptDetail(BuildContext context, ConceptProgressModel concept) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _ConceptDetailSheet(
          conceptId: concept.concept.id,
          conceptName: concept.concept.name,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

/// Stats card showing mastery tier distribution
class _StatsCard extends StatelessWidget {
  final ConceptStatsModel stats;

  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.school_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Уровни мастерства',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  'Всего: ${stats.totalConcepts}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Tier bars
            ...MasteryTier.values.reversed.map((tier) {
              final count = stats.getCountForTier(tier);
              final maxCount = stats.maxCount;
              final percent = maxCount > 0 ? count / maxCount : 0.0;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        tier.emoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                tier.nameRu,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                count.toString(),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percent,
                              minHeight: 8,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation(
                                _getTierColor(tier),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getTierColor(MasteryTier tier) {
    switch (tier) {
      case MasteryTier.unknown:
        return Colors.grey;
      case MasteryTier.familiar:
        return Colors.blue;
      case MasteryTier.practitioner:
        return Colors.green;
      case MasteryTier.experienced:
        return Colors.orange;
      case MasteryTier.master:
        return Colors.purple;
    }
  }
}

/// Filters and sort section
class _FiltersSection extends StatelessWidget {
  final ConceptSortBy sortBy;
  final int? tierFilter;
  final ValueChanged<ConceptSortBy> onSortChanged;
  final ValueChanged<int?> onTierFilterChanged;

  const _FiltersSection({
    required this.sortBy,
    required this.tierFilter,
    required this.onSortChanged,
    required this.onTierFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sort buttons
          Row(
            children: [
              Text(
                'Сортировка:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ConceptSortBy.values.map((sort) {
                      final isSelected = sortBy == sort;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_getSortLabel(sort)),
                          selected: isSelected,
                          onSelected: (_) => onSortChanged(sort),
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Tier filter
          Row(
            children: [
              Text(
                'Фильтр:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // "All" filter
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: const Text('Все'),
                          selected: tierFilter == null,
                          onSelected: (_) => onTierFilterChanged(null),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      // Tier filters
                      ...MasteryTier.values.map((tier) {
                        final isSelected = tierFilter == tier.value;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            avatar: Text(tier.emoji, style: const TextStyle(fontSize: 12)),
                            label: Text(tier.nameRu),
                            selected: isSelected,
                            onSelected: (_) => onTierFilterChanged(tier.value),
                            visualDensity: VisualDensity.compact,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getSortLabel(ConceptSortBy sort) {
    switch (sort) {
      case ConceptSortBy.mastery:
        return 'Мастерство';
      case ConceptSortBy.exposedCount:
        return 'Встречаемость';
      case ConceptSortBy.demonstratedCount:
        return 'Практика';
      case ConceptSortBy.name:
        return 'Имя';
    }
  }
}

/// Concept card in the list
class _ConceptCard extends StatelessWidget {
  final ConceptProgressModel concept;
  final VoidCallback onTap;

  const _ConceptCard({
    required this.concept,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tier = concept.tier;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Tier emoji
                  Text(
                    concept.masteryEmoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  // Concept name
                  Expanded(
                    child: Text(
                      concept.concept.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Arrow
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: concept.masteryLevel.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                    _getTierColor(tier),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Stats row
              Row(
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'встречал: ${concept.exposedCount}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'применял: ${concept.demonstratedCount}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    'уровень: ${concept.masteryLevel.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTierColor(MasteryTier tier) {
    switch (tier) {
      case MasteryTier.unknown:
        return Colors.grey;
      case MasteryTier.familiar:
        return Colors.blue;
      case MasteryTier.practitioner:
        return Colors.green;
      case MasteryTier.experienced:
        return Colors.orange;
      case MasteryTier.master:
        return Colors.purple;
    }
  }
}

/// Concept detail bottom sheet
class _ConceptDetailSheet extends ConsumerWidget {
  final int conceptId;
  final String conceptName;
  final ScrollController scrollController;

  const _ConceptDetailSheet({
    required this.conceptId,
    required this.conceptName,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(conceptDetailProvider(conceptId));

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    conceptName,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          
          // Content
          Expanded(
            child: detailAsync.when(
              data: (detail) => _buildDetailContent(context, detail),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Ошибка: $e'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context, ConceptDetailModel detail) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        // Exposed in problems
        if (detail.exposedIn.isNotEmpty) ...[
          Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Встречал в задачах (${detail.exposedIn.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...detail.exposedIn.map((ref) => _ProblemRefTile(
            ref: ref,
            onTap: () {
              Navigator.pop(context);
              context.push('/problems/${ref.id}');
            },
          )),
          const SizedBox(height: 16),
        ],
        
        // Demonstrated in solutions
        if (detail.demonstratedIn.isNotEmpty) ...[
          Row(
            children: [
              Icon(
                Icons.edit_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Применял в решениях (${detail.demonstratedIn.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...detail.demonstratedIn.map((ref) => _SolutionRefTile(
            ref: ref,
            onTap: () {
              Navigator.pop(context);
              context.push('/solutions/${ref.id}');
            },
          )),
        ],
        
        if (detail.exposedIn.isEmpty && detail.demonstratedIn.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Нет связанных задач или решений',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Problem reference tile
class _ProblemRefTile extends StatelessWidget {
  final ConceptProblemRef ref;
  final VoidCallback onTap;

  const _ProblemRefTile({
    required this.ref,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '#${ref.id}',
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
      title: Text(
        ref.reference,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        ref.sourceName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '${(ref.relevance * 100).toStringAsFixed(0)}%',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      onTap: onTap,
    );
  }
}

/// Solution reference tile
class _SolutionRefTile extends StatelessWidget {
  final ConceptProblemRef ref;
  final VoidCallback onTap;

  const _SolutionRefTile({
    required this.ref,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '#${ref.id}',
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ),
      title: Text(
        ref.reference,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: ref.context != null
          ? Text(
              ref.context!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}
