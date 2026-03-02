import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/problem.dart';
import '../../../core/motivation/motivation_engine.dart';
import '../../providers/auth_provider.dart';
import '../../providers/problems_provider.dart';
import '../../providers/providers.dart';
import '../../providers/solutions_provider.dart';
import '../../widgets/shared/markdown_with_math.dart';
import '../../widgets/shared/source_selector.dart';
import '../../widgets/shared/adaptive_layout.dart';
import '../../widgets/motivation/motivation_card.dart';

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
                'На этой странице собраны задачи из разных источников для вашего обучения.',
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
                  _FilterChip(
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
                            return _LoadMoreCard(
                              isLoading: _isLoadingMore,
                              onLoadMore: _loadMore,
                              remainingCount: _totalProblems - problems.length,
                            );
                          }
                          
                          final problem = problems[index];
                          final isActive = activeProblemIds.contains(problem.id);

                          return _ProblemCard(
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
  void _showCreateProblemDialog(BuildContext context, List<SourceModel> existingSources) {
    final refController = TextEditingController();
    final conditionController = TextEditingController();
    
    // Remove duplicate sources by name
    final uniqueSources = <String, SourceModel>{};
    for (final s in existingSources) {
      uniqueSources.putIfAbsent(s.name, () => s);
    }
    
    // Create mutable list of source names
    final sourceNames = <String>[...uniqueSources.keys]..sort();
    
    // Ensure selectedSource exists in the list, otherwise null
    String? selectedSource = _selectedSource;
    if (selectedSource != null && !sourceNames.contains(selectedSource)) {
      selectedSource = null;
    }
    
    List<String> selectedTags = [];
    bool isLoading = false;
    
    // Save outer context for navigation after dialog closes
    final outerContext = context;

    showConstrainedDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add_task),
              SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('Новая задача'),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source selection
                  Text(
                    'Источник',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedSource,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Выберите или введите новый',
                    ),
                    items: sourceNames.map((name) => DropdownMenuItem(
                      value: name,
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    )).toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedSource = value);
                    },
                  ),
                  // Custom source input hint
                  TextButton.icon(
                    onPressed: () {
                      // Show input for new source
                      final newSourceController = TextEditingController();
                      showConstrainedDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Новый источник'),
                          content: TextField(
                            controller: newSourceController,
                            decoration: const InputDecoration(
                              labelText: 'Название источника',
                              hintText: 'Например: Книга "Алгебра 10 класс"',
                            ),
                            autofocus: true,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Отмена'),
                            ),
                            FilledButton(
                              onPressed: () {
                                final newName = newSourceController.text.trim();
                                if (newName.isNotEmpty) {
                                  setDialogState(() {
                                    // Add to list if not exists
                                    if (!sourceNames.contains(newName)) {
                                      sourceNames.add(newName);
                                      sourceNames.sort();
                                    }
                                    selectedSource = newName;
                                  });
                                  Navigator.pop(ctx);
                                }
                              },
                              child: const Text('Добавить'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Новый источник'),
                  ),
                  const SizedBox(height: 16),

                  // Reference (number/name)
                  Text(
                    'Номер/Название',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: refController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Например: 1.23 или Задача №5',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tags
                  Text(
                    'Теги',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  _TagsSelector(
                    selectedTags: selectedTags,
                    onTagsChanged: (tags) {
                      setDialogState(() => selectedTags = tags);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Condition text
                  Text(
                    'Условие (опционально)',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: conditionController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Текст условия задачи...',
                    ),
                    maxLines: 4,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Отмена'),
            ),
            FilledButton.icon(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (refController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Введите номер/название задачи')),
                        );
                        return;
                      }
                      if (selectedSource == null || selectedSource!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Выберите или создайте источник')),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      try {
                        final repo = ref.read(problemsRepositoryProvider);
                        final problem = await repo.createProblem(
                          ProblemCreate(
                            reference: refController.text,
                            sourceName: selectedSource!,
                            tags: selectedTags,
                            conditionText: conditionController.text.isEmpty
                                ? null
                                : conditionController.text,
                          ),
                        );

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);

                          // Refresh problems list
                          ref.invalidate(problemsListProvider);
                          _resetPagination();

                          // Ask if user wants to add photo - use outerContext for navigation
                          final addPhoto = await showConstrainedDialog<bool>(
                            context: outerContext,
                            builder: (ctx) => AlertDialog(
                              title: const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text('Задача создана!'),
                                    ),
                                  ),
                                ],
                              ),
                              content: Text('ID: ${problem.id}\n\nДобавить фото условия?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Позже'),
                                ),
                                FilledButton.icon(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Добавить фото'),
                                ),
                              ],
                            ),
                          );

                          // Use outerContext for navigation after dialogs are closed
                          if (addPhoto == true && outerContext.mounted) {
                            await outerContext.push('/camera?category=condition&entityId=${problem.id}');
                            // Refresh after returning from camera
                            ref.invalidate(problemsListProvider);
                            _resetPagination();
                          } else if (outerContext.mounted) {
                            // Navigate to problem detail
                            await outerContext.push('/problems/${problem.id}');
                            // Refresh after returning from problem detail
                            ref.invalidate(problemsListProvider);
                            _resetPagination();
                          }
                        }
                      } catch (e) {
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Ошибка: $e')),
                          );
                        }
                      } finally {
                        if (dialogContext.mounted) {
                          setDialogState(() => isLoading = false);
                        }
                      }
                    },
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(isLoading ? 'Создание...' : 'Создать'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Load more card widget
class _LoadMoreCard extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onLoadMore;
  final int remainingCount;

  const _LoadMoreCard({
    required this.isLoading,
    required this.onLoadMore,
    required this.remainingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isLoading ? null : onLoadMore,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: isLoading
                ? const CircularProgressIndicator()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.expand_more),
                      const SizedBox(width: 8),
                      Text(
                        'Загрузить ещё ($remainingCount осталось)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Widget for selecting tags
class _TagsSelector extends ConsumerStatefulWidget {
  final List<String> selectedTags;
  final ValueChanged<List<String>> onTagsChanged;

  const _TagsSelector({
    required this.selectedTags,
    required this.onTagsChanged,
  });

  @override
  ConsumerState<_TagsSelector> createState() => _TagsSelectorState();
}

class _TagsSelectorState extends ConsumerState<_TagsSelector> {
  final _tagController = TextEditingController();
  bool _showSuggestions = false;

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = _tagController.text.isNotEmpty
        ? ref.watch(tagsProvider(_tagController.text))
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected tags chips
        if (widget.selectedTags.isNotEmpty) ...[
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: widget.selectedTags.map((tag) => Chip(
              label: Text(tag, style: const TextStyle(fontSize: 12)),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () {
                final newTags = List<String>.from(widget.selectedTags)..remove(tag);
                widget.onTagsChanged(newTags);
              },
              visualDensity: VisualDensity.compact,
            )).toList(),
          ),
          const SizedBox(height: 8),
        ],

        // Tag input
        TextField(
          controller: _tagController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'Поиск или создание тега',
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                if (_tagController.text.isNotEmpty) {
                  final newTag = _tagController.text.trim();
                  if (!widget.selectedTags.contains(newTag)) {
                    widget.onTagsChanged([...widget.selectedTags, newTag]);
                  }
                  _tagController.clear();
                  setState(() => _showSuggestions = false);
                }
              },
            ),
          ),
          onChanged: (value) {
            setState(() => _showSuggestions = value.isNotEmpty);
          },
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              final newTag = value.trim();
              if (!widget.selectedTags.contains(newTag)) {
                widget.onTagsChanged([...widget.selectedTags, newTag]);
              }
              _tagController.clear();
              setState(() => _showSuggestions = false);
            }
          },
        ),

        // Tag suggestions
        if (_showSuggestions && tagsAsync != null)
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            child: tagsAsync.when(
              data: (tags) {
                // Filter out already selected tags
                final availableTags = tags
                    .where((t) => !widget.selectedTags.contains(t.name))
                    .take(5)
                    .toList();

                if (availableTags.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Нет предложений. Нажмите + для создания.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  );
                }

                return Card(
                  margin: const EdgeInsets.only(top: 4),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableTags.length,
                    itemBuilder: (context, index) {
                      final tag = availableTags[index];
                      return ListTile(
                        dense: true,
                        title: Text(tag.name),
                        trailing: const Icon(Icons.add, size: 18),
                        onTap: () {
                          widget.onTagsChanged([...widget.selectedTags, tag.name]);
                          _tagController.clear();
                          setState(() => _showSuggestions = false);
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, __) => const SizedBox(),
            ),
          ),
      ],
    );
  }
}

/// Safe math preview widget with error handling for LaTeX rendering
class _SafeMathPreview extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const _SafeMathPreview({
    required this.text,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    // Try to render with LaTeX, fall back to plain text on error
    try {
      return MarkdownWithMath(
        text: text,
        textStyle: style,
        // No maxLines - let content take as much space as needed
      );
    } catch (e) {
      // Fallback: show plain text without $ symbols
      return Text(
        text.replaceAll(RegExp(r'\$+'), ''),  // Remove $ symbols
        style: style,
        // No maxLines - let content take as much space as needed
      );
    }
  }
}

class _ProblemCard extends StatelessWidget {
  final ProblemModel problem;
  final bool isActive;
  final VoidCallback onTap;

  const _ProblemCard({
    required this.problem,
    required this.isActive,
    required this.onTap,
  });

  /// Get preview text from condition, respecting LaTeX formulas
  /// Returns full text without truncation - card height adjusts automatically
  String? get _previewText {
    if (problem.conditionText == null || problem.conditionText!.isEmpty) {
      return null;
    }
    return problem.conditionText!;
  }

  @override
  Widget build(BuildContext context) {
    final previewText = _previewText;
    final hasPreview = previewText != null || problem.hasImage;
    final addedBy = problem.addedBy;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with icon, title and status
              Row(
                children: [
                  // Status icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.green.withOpacity(0.1)
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        problem.hasText ? Icons.description : Icons.image,
                        size: 20,
                        color: isActive
                            ? Colors.green
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title and source
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                problem.reference,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isActive) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Активно',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                problem.sourceName,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            // Show added_by user
                            if (addedBy != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '•',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.person_outline,
                                size: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  addedBy.displayName,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
              
              // Preview section (text with LaTeX or image indicator)
              if (hasPreview) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: previewText != null
                      ? _SafeMathPreview(
                          text: previewText,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        )
                      : Row(
                          children: [
                            Icon(
                              Icons.photo_camera_outlined,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Есть фото условия',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
              
              // Tags row
              if (problem.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: problem.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag.name,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              
              // Concepts row (if any)
              if (problem.concepts != null && problem.concepts!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: problem.concepts!.take(3).map((concept) {
                    final conceptName = concept.concept?.name;
                    if (conceptName == null) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .secondaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 10,
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              conceptName,
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom filter chip for "My problems" toggle
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Material(
      color: selected 
          ? colorScheme.primaryContainer 
          : colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onSelected(!selected),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected 
                    ? colorScheme.onPrimaryContainer 
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected 
                      ? colorScheme.onPrimaryContainer 
                      : colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
