import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/problem.dart';
import '../../providers/problems_provider.dart';
import '../../providers/providers.dart';
import '../../providers/solutions_provider.dart';
import '../../widgets/shared/markdown_with_math.dart';

/// Library screen - browse sources and problems with pagination
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String? _selectedSource;
  String _searchQuery = '';
  int _currentOffset = 0;
  final int _pageSize = 20;
  
  // Accumulated problems list for infinite scroll
  List<ProblemModel> _accumulatedProblems = [];
  int _totalProblems = 0;
  bool _hasMore = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset when source changes
    _resetPagination();
  }
  
  void _resetPagination() {
    _currentOffset = 0;
    _accumulatedProblems = [];
    _totalProblems = 0;
    _hasMore = true;
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

    // Current filter
    final filter = ProblemsFilter(
      source: _selectedSource,
      search: _searchQuery.isEmpty ? null : _searchQuery,
      limit: _pageSize,
      offset: _currentOffset,
    );

    // Watch problems list with current filter
    final problemsListAsync = ref.watch(problemsListProvider(filter));

    // Update accumulated list when new data arrives
    problemsListAsync.whenData((response) {
      if (_currentOffset == 0) {
        _accumulatedProblems = response.items;
      } else if (_accumulatedProblems.length < _currentOffset + response.items.length) {
        // Avoid duplicates
        final existingIds = _accumulatedProblems.map((p) => p.id).toSet();
        final newItems = response.items.where((p) => !existingIds.contains(p.id)).toList();
        _accumulatedProblems = [..._accumulatedProblems, ...newItems];
      }
      _totalProblems = response.total;
      _hasMore = response.hasMore;
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Библиотека'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Source chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: sources.when(
              data: (data) => ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  FilterChip(
                    label: const Text('Все'),
                    selected: _selectedSource == null,
                    onSelected: (_) {
                      setState(() {
                        _selectedSource = null;
                        _resetPagination();
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ...data.map((source) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(source.name),
                          selected: _selectedSource == source.name,
                          onSelected: (_) {
                            setState(() {
                              _selectedSource = source.name;
                              _resetPagination();
                            });
                          },
                        ),
                      )),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
            ),
          ),
          const Divider(),

          // Problems list with pagination
          Expanded(
            child: problemsListAsync.when(
              data: (response) {
                final problems = _accumulatedProblems;
                
                if (problems.isEmpty && _currentOffset == 0) {
                  return Center(
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
                          'Выберите другой источник или создайте задачу',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
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
                        padding: const EdgeInsets.all(16),
                        itemCount: problems.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Load more button
                          if (index == problems.length && _hasMore) {
                            return _LoadMoreCard(
                              isLoading: problemsListAsync.isLoading,
                              onLoadMore: () {
                                if (!problemsListAsync.isLoading) {
                                  setState(() {
                                    _currentOffset += _pageSize;
                                  });
                                }
                              },
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
                              // Refresh after returning from problem detail
                              ref.invalidate(problemsListProvider);
                              _resetPagination();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () {
                if (_accumulatedProblems.isNotEmpty) {
                  // Show existing data while loading more
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _accumulatedProblems.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _accumulatedProblems.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      
                      final problem = _accumulatedProblems[index];
                      final isActive = activeProblemIds.contains(problem.id);

                      return _ProblemCard(
                        problem: problem,
                        isActive: isActive,
                        onTap: () async {
                          await context.push('/problems/${problem.id}');
                          ref.invalidate(problemsListProvider);
                          _resetPagination();
                        },
                      );
                    },
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
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
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поиск задач'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Введите текст для поиска...',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
          onSubmitted: (value) {
            Navigator.pop(context);
            setState(() {
              _searchQuery = value;
              _resetPagination();
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _searchQuery = '';
                _resetPagination();
              });
            },
            child: const Text('Сбросить'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _searchQuery = searchController.text;
                _resetPagination();
              });
            },
            child: const Text('Найти'),
          ),
        ],
      ),
    );
  }

  /// Show dialog to create a new problem
  void _showCreateProblemDialog(BuildContext context, List<SourceModel> existingSources) {
    final refController = TextEditingController();
    final conditionController = TextEditingController();
    String? selectedSource = _selectedSource;
    List<String> selectedTags = [];
    bool isLoading = false;
    
    // Save outer context for navigation after dialog closes
    final outerContext = context;

    showDialog(
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
                    items: [
                      ...existingSources.map((s) => DropdownMenuItem(
                        value: s.name,
                        child: Text(
                          s.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      )),
                    ],
                    onChanged: (value) {
                      setDialogState(() => selectedSource = value);
                    },
                  ),
                  // Custom source input hint
                  TextButton.icon(
                    onPressed: () {
                      // Show input for new source
                      final newSourceController = TextEditingController();
                      showDialog(
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
                                if (newSourceController.text.isNotEmpty) {
                                  setDialogState(() {
                                    selectedSource = newSourceController.text;
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
                          final addPhoto = await showDialog<bool>(
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
        maxLines: 12,
        overflow: TextOverflow.ellipsis,
      );
    } catch (e) {
      // Fallback: show plain text with ellipsis
      return Text(
        text.replaceAll(RegExp(r'\$+'), ''),  // Remove $ symbols
        style: style,
        maxLines: 12,
        overflow: TextOverflow.ellipsis,
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
  /// Will not cut inside $...$ or $$...$$ blocks
  String? get _previewText {
    if (problem.conditionText == null || problem.conditionText!.isEmpty) {
      return null;
    }
    final text = problem.conditionText!;
    
    // If text is short enough, return as-is
    if (text.length <= 300) return text;
    
    // Find a safe cut point that doesn't break LaTeX
    final cutPoint = _findSafeCutPoint(text, 300);
    if (cutPoint < text.length) {
      return '${text.substring(0, cutPoint)}...';
    }
    return text;
  }
  
  /// Find a safe point to cut text without breaking LaTeX formulas
  int _findSafeCutPoint(String text, int targetLength) {
    // Track if we're inside math mode
    bool inDisplayMath = false;
    bool inInlineMath = false;
    int lastSafePoint = targetLength;
    
    // Don't go beyond text length
    if (targetLength >= text.length) return text.length;
    
    // Scan through text up to a bit beyond target
    final scanLimit = min(targetLength + 50, text.length);
    
    for (int i = 0; i < scanLimit; i++) {
      final char = text[i];
      
      // Check for $$ (display math)
      if (i < text.length - 1 && text[i] == '\$' && text[i + 1] == '\$') {
        if (inDisplayMath) {
          // End of display math - this is a safe point after $$
          if (i + 2 <= targetLength) {
            lastSafePoint = i + 2;
          }
        }
        inDisplayMath = !inDisplayMath;
        i++; // Skip next $
        continue;
      }
      
      // Check for $ (inline math) - only if not in display math
      if (!inDisplayMath && char == '\$') {
        if (inInlineMath) {
          // End of inline math - this is a safe point after $
          if (i + 1 <= targetLength) {
            lastSafePoint = i + 1;
          }
        }
        inInlineMath = !inInlineMath;
        continue;
      }
      
      // If we're not in any math mode and we hit target, this is a good cut point
      if (!inDisplayMath && !inInlineMath && i >= targetLength - 10) {
        // Look for a space or punctuation for cleaner cut
        if (char == ' ' || char == '\n' || char == ',' || char == '.') {
          return i;
        }
      }
    }
    
    // If we're still in math mode at target length, use last safe point
    if (inDisplayMath || inInlineMath) {
      return lastSafePoint;
    }
    
    // Find word boundary near target
    for (int i = targetLength; i >= max(0, targetLength - 30); i--) {
      if (i < text.length && (text[i] == ' ' || text[i] == '\n')) {
        return i;
      }
    }
    
    return targetLength;
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
                            Text(
                              problem.sourceName,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                              Text(
                                addedBy.displayName,
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
                          Text(
                            conceptName,
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
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
