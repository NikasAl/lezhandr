import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/problem.dart';
import '../../providers/problems_provider.dart';
import '../../providers/providers.dart';
import '../../providers/solutions_provider.dart';

/// Library screen - browse sources and problems
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String? _selectedSource;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final sources = ref.watch(sourcesProvider);
    final problems = ref.watch(problemsProvider(
      ProblemsFilter(source: _selectedSource, search: _searchQuery.isEmpty ? null : _searchQuery),
    ));
    final activeSolutions = ref.watch(activeSolutionsProvider);

    // Get active problem IDs
    final activeProblemIds = activeSolutions.valueOrNull
            ?.map((s) => s.problemId)
            .toSet() ??
        {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Библиотека'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Show search
            },
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
                    onSelected: (_) => setState(() => _selectedSource = null),
                  ),
                  const SizedBox(width: 8),
                  ...data.map((source) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(source.name),
                          selected: _selectedSource == source.name,
                          onSelected: (_) =>
                              setState(() => _selectedSource = source.name),
                        ),
                      )),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
            ),
          ),
          const Divider(),

          // Problems list
          Expanded(
            child: problems.when(
              data: (data) {
                if (data.isEmpty) {
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

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final problem = data[index];
                    final isActive = activeProblemIds.contains(problem.id);

                    return _ProblemCard(
                      problem: problem,
                      isActive: isActive,
                      onTap: () => context.push('/problems/${problem.id}'),
                    );
                  },
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
                      onPressed: () => ref.invalidate(sourcesProvider),
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

  /// Show dialog to create a new problem
  void _showCreateProblemDialog(BuildContext context, List<SourceModel> existingSources) {
    final refController = TextEditingController();
    final conditionController = TextEditingController();
    String? selectedSource = _selectedSource;
    List<String> selectedTags = [];
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add_task),
              SizedBox(width: 8),
              Text('Новая задача'),
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
                          ref.invalidate(problemsProvider);

                          // Ask if user wants to add photo
                          final addPhoto = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('Задача создана!'),
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

                          if (addPhoto == true && context.mounted) {
                            context.push('/camera?category=condition&entityId=${problem.id}');
                          } else if (context.mounted) {
                            // Navigate to problem detail
                            context.push('/problems/${problem.id}');
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

class _ProblemCard extends StatelessWidget {
  final ProblemModel problem;
  final bool isActive;
  final VoidCallback onTap;

  const _ProblemCard({
    required this.problem,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.withOpacity(0.1)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    problem.hasText ? Icons.description : Icons.image,
                    color: isActive
                        ? Colors.green
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            problem.reference,
                            style: Theme.of(context).textTheme.titleMedium,
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
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      problem.sourceName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    if (problem.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: problem.tags.take(3).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
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
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
