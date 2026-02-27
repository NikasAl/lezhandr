import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/problem.dart';
import '../../providers/problems_provider.dart';

/// Source selector with search and pagination
/// Shows a modal dialog for selecting a source from a list with search
class SourceSelectorDialog extends ConsumerStatefulWidget {
  final String? selectedSource;
  final ValueChanged<String?> onSourceSelected;

  const SourceSelectorDialog({
    super.key,
    this.selectedSource,
    required this.onSourceSelected,
  });

  /// Show the dialog and return the selected source
  static Future<String?> show(
    BuildContext context, {
    String? selectedSource,
  }) async {
    String? result;
    await showDialog(
      context: context,
      builder: (context) => SourceSelectorDialog(
        selectedSource: selectedSource,
        onSourceSelected: (source) {
          result = source;
          Navigator.pop(context);
        },
      ),
    );
    return result;
  }

  @override
  ConsumerState<SourceSelectorDialog> createState() => _SourceSelectorDialogState();
}

class _SourceSelectorDialogState extends ConsumerState<SourceSelectorDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final List<SourceModel> _accumulatedSources = [];
  int _totalSources = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _resetAndSearch(String query) {
    setState(() {
      _searchQuery = query;
      _accumulatedSources.clear();
      _totalSources = 0;
      _hasMore = true;
      _isLoadingMore = false;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final filter = SourcesFilter(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        limit: 20,
        offset: _accumulatedSources.length,
        sortBy: 'problem_count',
        withCounts: true,
      );

      final response = await ref.read(sourcesListProvider(filter).future);

      if (mounted) {
        setState(() {
          // Avoid duplicates
          final existingIds = _accumulatedSources.map((s) => s.id).toSet();
          final newItems = response.items.where((s) => !existingIds.contains(s.id)).toList();
          _accumulatedSources.addAll(newItems);
          _totalSources = response.total;
          _hasMore = response.hasMore;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = SourcesFilter(
      search: _searchQuery.isEmpty ? null : _searchQuery,
      limit: 20,
      offset: 0,
      sortBy: 'problem_count',
      withCounts: true,
    );

    final sourcesAsync = ref.watch(sourcesListProvider(filter));

    // Update accumulated list when initial data arrives
    sourcesAsync.whenData((response) {
      if (_accumulatedSources.isEmpty || _searchQuery != _lastSearchQuery) {
        _lastSearchQuery = _searchQuery;
        _accumulatedSources.clear();
        _accumulatedSources.addAll(response.items);
        _totalSources = response.total;
        _hasMore = response.hasMore;
      }
    });

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.folder_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Выбрать источник',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Поиск источника...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                onChanged: (value) {
                  // Debounce search
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (_searchController.text == value && mounted) {
                      _resetAndSearch(value);
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 8),

            // "All sources" option
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: widget.selectedSource == null
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                child: ListTile(
                  leading: Icon(
                    Icons.select_all,
                    color: widget.selectedSource == null
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : null,
                  ),
                  title: Text(
                    'Все источники',
                    style: TextStyle(
                      fontWeight: widget.selectedSource == null
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: widget.selectedSource == null
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : null,
                    ),
                  ),
                  trailing: widget.selectedSource == null
                      ? Icon(
                          Icons.check,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        )
                      : null,
                  onTap: () => widget.onSourceSelected(null),
                ),
              ),
            ),

            // Divider with count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Всего: $_totalSources',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
            ),

            // Sources list
            Expanded(
              child: sourcesAsync.when(
                data: (_) => _buildSourcesList(),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 8),
                      Text('Ошибка: $error'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => ref.invalidate(sourcesListProvider),
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _lastSearchQuery;

  Widget _buildSourcesList() {
    if (_accumulatedSources.isEmpty && !_isLoadingMore) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'Источники не найдены',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _accumulatedSources.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _accumulatedSources.length && _hasMore) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final source = _accumulatedSources[index];
        final isSelected = widget.selectedSource == source.name;

        return Card(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              Icons.folder_outlined,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : null,
            ),
            title: Text(
              source.name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (source.problemCount != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.2)
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${source.problemCount}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
              ],
            ),
            onTap: () => widget.onSourceSelected(source.name),
          ),
        );
      },
    );
  }
}

/// Compact source selector chip that opens dialog on tap
class SourceSelectorChip extends StatelessWidget {
  final String? selectedSource;
  final ValueChanged<String?> onSourceSelected;
  final int? totalSources;

  const SourceSelectorChip({
    super.key,
    this.selectedSource,
    required this.onSourceSelected,
    this.totalSources,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(
        selectedSource == null ? Icons.select_all : Icons.folder_outlined,
        size: 18,
      ),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            selectedSource ?? 'Все',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, size: 18),
        ],
      ),
      onPressed: () async {
        final result = await SourceSelectorDialog.show(
          context,
          selectedSource: selectedSource,
        );
        if (result != selectedSource) {
          onSourceSelected(result);
        }
      },
    );
  }
}
