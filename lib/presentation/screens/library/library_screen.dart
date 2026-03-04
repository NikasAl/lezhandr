import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/problem.dart';
import '../../../core/motivation/motivation_engine.dart';
import '../../providers/auth_provider.dart';
import '../../providers/problems_provider.dart';
import '../../providers/providers.dart';
import '../../providers/solutions_provider.dart';
import '../../widgets/shared/source_selector.dart';
import '../../widgets/shared/adaptive_layout.dart';
import '../../widgets/motivation/motivation_card.dart';
import 'widgets/widgets.dart';

/// Library screen - browse sources and problems with pagination
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String? _selectedSource;
  String _searchQuery = '';
  bool _searchByReference = false; // Search mode: false = by text, true = by reference
  bool _showMyOnly = false;

  // Accumulated problems list for infinite scroll
  List<ProblemModel> _accumulatedProblems = [];
  int _totalProblems = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // Scroll controller to preserve scroll position
  final ScrollController _scrollController = ScrollController(keepScrollOffset: true);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Show help dialog as bottom sheet
  void _showHelpDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
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

              // Header with icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.library_books_outlined, size: 32, color: Colors.teal),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Библиотека задач',
                      style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Main description
              Text(
                'На этой странице для вас собраны задачи из разных источников.',
                style: Theme.of(sheetContext).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),

              // Features section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(sheetContext).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Возможности:',
                      style: Theme.of(sheetContext).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildHelpItem(Icons.folder_outlined, 'Выбрать источник задач', Colors.teal),
                    const SizedBox(height: 8),
                    _buildHelpItem(Icons.local_offer_outlined, 'Задать теги для классификации', Colors.orange),
                    const SizedBox(height: 8),
                    _buildHelpItem(Icons.search, 'Найти по содержанию или номеру', Colors.blue),
                    const SizedBox(height: 8),
                    _buildHelpItem(Icons.add_task, 'Добавить новые задачи', Colors.green),
                    const SizedBox(height: 8),
                    _buildHelpItem(Icons.camera_alt_outlined, 'Сфотографировать условие', Colors.purple),
                    const SizedBox(height: 8),
                    _buildHelpItem(Icons.functions, 'Перевести в LaTeX для анализа', Colors.indigo),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tip section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Нажмите на задачу, чтобы посмотреть условие и начать решение.',
                        style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  icon: const Icon(Icons.check),
                  label: const Text('Понятно!'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text),
        ),
      ],
    );
  }

  void _resetPagination() {
    _accumulatedProblems = [];
    _totalProblems = 0;
    _hasMore = true;
    _isLoadingMore = false;
    // Reset scroll position when filter changes
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  /// Load more problems
  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      final userId = _showMyOnly ? currentUser?.id : null;

      final repo = ref.read(problemsRepositoryProvider);
      final response = await repo.getProblems(
        source: _selectedSource,
        search: _searchQuery.isEmpty || _searchByReference ? null : _searchQuery,
        reference: _searchQuery.isEmpty || !_searchByReference ? null : _searchQuery,
        userId: userId,
        limit: 20,
        offset: _accumulatedProblems.length,
      );

      if (mounted) {
        setState(() {
          // Avoid duplicates
          final existingIds = _accumulatedProblems.map((p) => p.id).toSet();
          final newItems = response.items.where((p) => !existingIds.contains(p.id)).toList();
          _accumulatedProblems = [..._accumulatedProblems, ...newItems];
          _totalProblems = response.total;
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

  /// Update a single problem in the list without resetting pagination
  Future<void> _updateSingleProblem(int problemId) async {
    try {
      // Invalidate the single problem provider to get fresh data
      ref.invalidate(problemProvider(problemId));

      // Fetch updated problem
      final updatedProblem = await ref.read(problemProvider(problemId).future);

      if (mounted && updatedProblem != null) {
        setState(() {
          // Find and replace the problem in the accumulated list
          final index = _accumulatedProblems.indexWhere((p) => p.id == problemId);
          if (index != -1) {
            _accumulatedProblems[index] = updatedProblem;
          }
        });
      }
    } catch (e) {
      // Silently fail - the problem might have been deleted or other issue
      debugPrint('Failed to update problem $problemId: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sources = ref.watch(sourcesProvider);
    final activeSolutions = ref.watch(activeSolutionsProvider);

    // Get active problem IDs
    final activeProblemIds = activeSolutions.valueOrNull
            ?.map((s) => s.problemId)
            .toSet() ??
        {};

    // Get current user for "My problems" filter
    final currentUser = ref.watch(currentUserProvider);
    final userId = _showMyOnly ? currentUser?.id : null;

    // Base filter for initial load (always offset 0)
    final baseFilter = ProblemsFilter(
      source: _selectedSource,
      search: _searchQuery.isEmpty || _searchByReference ? null : _searchQuery,
      reference: _searchQuery.isEmpty || !_searchByReference ? null : _searchQuery,
      userId: userId,
      limit: 20,
      offset: 0,
    );

    // Watch only the base filter for initial data
    final problemsListAsync = ref.watch(problemsListProvider(baseFilter));

    // Update accumulated list when initial data arrives
    problemsListAsync.whenData((response) {
      if (_accumulatedProblems.isEmpty) {
        _accumulatedProblems = response.items;
        _totalProblems = response.total;
        _hasMore = response.hasMore;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Библиотека'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Подсказка',
            onPressed: _showHelpDialog,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters row
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                // Source selector
                const Icon(Icons.folder_outlined, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Источник:',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: SourceSelectorChip(
                    selectedSource: _selectedSource,
                    onSourceSelected: (source) {
                      setState(() {
                        _selectedSource = source;
                        _resetPagination();
                        ref.invalidate(problemsListProvider);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // "My problems" filter
                if (currentUser != null)
                  LibraryFilterChip(
                    label: 'Мои',
                    icon: Icons.person_outline,
                    selected: _showMyOnly,
                    onSelected: (selected) {
                      setState(() {
                        _showMyOnly = selected;
                        _resetPagination();
                        ref.invalidate(problemsListProvider);
                      });
                    },
                  ),
              ],
            ),
          ),
          // Active search indicator
          if (_searchQuery.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              child: Row(
                children: [
                  Icon(
                    _searchByReference ? Icons.numbers : Icons.text_fields,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _searchByReference
                          ? 'Поиск по номеру: "$_searchQuery"'
                          : 'Поиск по тексту: "$_searchQuery"',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _searchQuery = '';
                        _searchByReference = false;
                        _resetPagination();
                        ref.invalidate(problemsListProvider);
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

          // Problems list with pagination
          Expanded(
            child: problemsListAsync.when(
              data: (response) {
                final problems = _accumulatedProblems;

                if (problems.isEmpty) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Нет задач',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'По вашему запросу ничего не найдено'
                              : 'Выберите другой источник или создайте задачу',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),

                        // Show motivation when no results
                        const SizedBox(height: 24),
                        Builder(
                          builder: (context) {
                            final motivationEngine = MotivationEngine();
                            final motivation = motivationEngine.getOnboardingText();
                            if (motivation != null) {
                              return MotivationCard(
                                motivation: motivation,
                                showAuthor: false,
                                animate: false,
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Total count indicator
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      child: Text(
                        'Всего задач: $_totalProblems',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),

                    // Problems list
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: problems.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Load more button
                          if (index == problems.length && _hasMore) {
                            return LoadMoreCard(
                              isLoading: _isLoadingMore,
                              onLoadMore: _loadMore,
                              remainingCount: _totalProblems - problems.length,
                            );
                          }

                          final problem = problems[index];
                          final isActive = activeProblemIds.contains(problem.id);

                          return ProblemCard(
                            problem: problem,
                            isActive: isActive,
                            onTap: () async {
                              await context.push('/problems/${problem.id}');
                              // Update only this problem in the list without resetting pagination
                              _updateSingleProblem(problem.id);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Ошибка загрузки: $error'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        ref.invalidate(sourcesProvider);
                        ref.invalidate(problemsListProvider);
                        _resetPagination();
                      },
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateProblemDialog(context, sources.valueOrNull ?? []),
        icon: const Icon(Icons.add),
        label: const Text('Новая задача'),
      ),
    );
  }

  /// Show search dialog
  void _showSearchDialog(BuildContext context) {
    final searchController = TextEditingController(text: _searchQuery);
    bool searchByReference = _searchByReference;

    showConstrainedDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Поиск задач'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: searchByReference
                      ? 'Введите номер/название...'
                      : 'Введите текст условия...',
                  prefixIcon: const Icon(Icons.search),
                ),
                autofocus: true,
                onSubmitted: (value) {
                  Navigator.pop(dialogContext);
                  setState(() {
                    _searchQuery = value;
                    _searchByReference = searchByReference;
                    _resetPagination();
                    ref.invalidate(problemsListProvider);
                  });
                },
              ),
              const SizedBox(height: 8),
              // Search mode toggle
              InkWell(
                onTap: () {
                  setDialogState(() {
                    searchByReference = !searchByReference;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    children: [
                      Icon(
                        searchByReference
                            ? Icons.numbers
                            : Icons.text_fields,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          searchByReference
                              ? 'По номеру/названию'
                              : 'По тексту условия',
                          style: Theme.of(context).textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: searchByReference,
                        onChanged: (value) {
                          setDialogState(() {
                            searchByReference = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                setState(() {
                  _searchQuery = '';
                  _searchByReference = false;
                  _resetPagination();
                  ref.invalidate(problemsListProvider);
                });
              },
              child: const Text('Сбросить'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                setState(() {
                  _searchQuery = searchController.text;
                  _searchByReference = searchByReference;
                  _resetPagination();
                  ref.invalidate(problemsListProvider);
                });
              },
              child: const Text('Найти'),
            ),
          ],
        ),
      ),
    );
  }

  /// Show dialog to create a new problem
  Future<void> _showCreateProblemDialog(BuildContext context, List<SourceModel> existingSources) async {
    // Remove duplicate sources by name
    final uniqueSources = <String, SourceModel>{};
    for (final s in existingSources) {
      uniqueSources.putIfAbsent(s.name, () => s);
    }

    // Create sorted list of SourceModel
    final sourceList = uniqueSources.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    // Ensure selectedSource exists in the list, otherwise null
    String? selectedSource = _selectedSource;
    if (selectedSource != null && !uniqueSources.containsKey(selectedSource)) {
      selectedSource = null;
    }

    final problem = await showModalBottomSheet<ProblemModel>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => CreateProblemSheet(
        sources: sourceList,
        selectedSource: selectedSource,
        ref: ref,
      ),
    );

    // Handle result after sheet is closed
    if (problem != null && mounted) {
      // Refresh the list
      ref.invalidate(problemsListProvider);
      _resetPagination();

      // Ask if user wants to add photo
      final addPhoto = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => ConfirmPhotoSheet(problemId: problem.id!),
      );

      if (addPhoto == true && mounted) {
        await context.push('/camera?category=condition&entityId=${problem.id}');
        ref.invalidate(problemsListProvider);
        _resetPagination();
      } else if (mounted) {
        await context.push('/problems/${problem.id}');
        ref.invalidate(problemsListProvider);
        _resetPagination();
      }
    }
  }
}
