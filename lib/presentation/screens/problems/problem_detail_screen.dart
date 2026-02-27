import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/artifacts.dart';
import '../../../data/models/problem.dart';
import '../../providers/problems_provider.dart';
import '../../providers/solutions_provider.dart';
import '../../providers/ocr_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/billing_provider.dart';
import '../../widgets/shared/persona_selector.dart';
import '../../widgets/shared/markdown_with_math.dart';
import '../../widgets/shared/image_viewer.dart';
import '../../widgets/shared/thinking_indicator.dart';

/// Problem detail screen
class ProblemDetailScreen extends ConsumerStatefulWidget {
  final int problemId;

  const ProblemDetailScreen({super.key, required this.problemId});

  @override
  ConsumerState<ProblemDetailScreen> createState() => _ProblemDetailScreenState();
}

class _ProblemDetailScreenState extends ConsumerState<ProblemDetailScreen> {
  bool _isLoading = false;
  String? _ocrText;
  bool _showConditionImage = false;
  final _conditionController = TextEditingController();

  @override
  void dispose() {
    _conditionController.dispose();
    super.dispose();
  }

  Future<void> _runOcr() async {
    final billing = ref.read(billingBalanceProvider);
    final freeUsesLeft = billing.value?.freeUsesLeft;
    final balance = billing.value?.balance;
    final persona = await showPersonaSheet(
      context,
      ref,
      defaultPersona: PersonaId.petrovich,
      freeUsesLeft: freeUsesLeft,
      balance: balance,
    );
    if (persona == null) return;

    // OCR runs in background with notification on completion
    await ref.read(ocrNotifierProvider.notifier).processProblem(
      problemId: widget.problemId,
      persona: persona,
    );
    
    // Refresh problem to get updated text
    if (mounted) {
      ref.invalidate(problemProvider(widget.problemId));
    }
  }

  Future<void> _saveConditionText(String text) async {
    if (text.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      await ref.read(problemNotifierProvider.notifier).updateProblem(
        widget.problemId,
        conditionText: text,
      );
      if (mounted) {
        ref.invalidate(problemProvider(widget.problemId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Текст условия сохранён')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _runConceptsAnalysis() async {
    final billing = ref.read(billingBalanceProvider);
    final freeUsesLeft = billing.value?.freeUsesLeft;
    final balance = billing.value?.balance;
    final persona = await showPersonaSheet(
      context,
      ref,
      defaultPersona: PersonaId.legendre,
      freeUsesLeft: freeUsesLeft,
      balance: balance,
    );
    if (persona == null) return;

    // Analysis runs in background with notification on completion
    await ref.read(conceptsNotifierProvider.notifier).analyzeProblem(
      problemId: widget.problemId,
      persona: persona,
    );
    
    // Refresh problem to get updated concepts
    if (mounted) {
      ref.invalidate(problemProvider(widget.problemId));
    }
  }

  void _showEditConditionDialog(String currentText) {
    _conditionController.text = currentText;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit),
            SizedBox(width: 8),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Редактировать условие'),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: _conditionController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: r'Текст условия (поддержка LaTeX: $...$ или $$...$$)',
            ),
            maxLines: 10,
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _saveConditionText(_conditionController.text);
            },
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showEditTagsDialog(List<TagModel> currentTags) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.sell),
            SizedBox(width: 8),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Редактировать теги'),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: _TagsEditor(
            initialTags: currentTags.map((t) => t.name).toList(),
            onSaved: (tags) async {
              Navigator.pop(dialogContext);
              await ref.read(problemNotifierProvider.notifier).updateProblem(
                widget.problemId,
                tags: tags,
              );
              if (mounted) {
                ref.invalidate(problemProvider(widget.problemId));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Теги обновлены')),
                );
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  void _showConditionActions(ProblemModel data, bool isOwner) {
    final ocrState = ref.read(ocrNotifierProvider);
    final isOcrLoading = ocrState.isLoading;
    
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Owner-only actions
            if (isOwner) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Редактировать текст'),
                subtitle: Text(data.hasText ? 'Изменить текущий текст' : 'Добавить текст'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showEditConditionDialog(data.conditionText ?? '');
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Загрузить фото'),
                subtitle: Text(data.hasImage ? 'Заменить текущее фото' : 'Добавить фото'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await context.push('/camera?category=condition&entityId=${widget.problemId}');
                  if (mounted) {
                    ref.invalidate(problemProvider(widget.problemId));
                    ref.invalidate(imageProvider((category: 'condition', entityId: widget.problemId)));
                  }
                },
              ),
              if (data.hasImage)
                ListTile(
                  leading: isOcrLoading 
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  title: const Text('Распознать текст (OCR)'),
                  subtitle: isOcrLoading 
                      ? Text('${ocrState.currentPersona?.displayName ?? "Персонаж"} думает...')
                      : const Text('Извлечь текст с фото'),
                  enabled: !isOcrLoading,
                  onTap: isOcrLoading
                      ? null
                      : () async {
                          Navigator.pop(sheetContext);
                          await _runOcr();
                        },
                ),
            ],
            // Always available: view photo
            if (data.hasImage)
              ListTile(
                leading: const Icon(Icons.photo_size_select_large),
                title: const Text('Открыть фото'),
                subtitle: const Text('Просмотреть в полном размере'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ImageViewerScreen(
                        category: 'condition',
                        entityId: widget.problemId,
                        title: 'Условие: ${data.reference}',
                      ),
                    ),
                  );
                },
              ),
            // Info for non-owners
            if (!isOwner && !data.hasImage)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Только автор задачи может редактировать условие',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final problem = ref.watch(problemProvider(widget.problemId));
    final solutions = ref.watch(problemSolutionsProvider(widget.problemId));
    final ocrState = ref.watch(ocrNotifierProvider);
    final conceptsState = ref.watch(conceptsNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Задача'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              problem.whenData((data) {
                final isOwner = currentUser?.id == data.addedBy?.id;
                _showConditionActions(data, isOwner);
              });
            },
          ),
        ],
      ),
      body: problem.when(
        data: (data) {
          final isOwner = currentUser?.id == data.addedBy?.id;
          
          return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Source and reference with added_by
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        data.sourceName,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.reference,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (data.addedBy != null) ...[
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
                                data.addedBy!.displayName,
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

              const SizedBox(height: 16),

              // Tags with edit button (owner only)
              Row(
                children: [
                  if (data.tags.isNotEmpty)
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: data.tags.map((tag) {
                          return Chip(
                            label: Text(tag.name),
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    )
                  else
                    Expanded(
                      child: Text(
                        'Нет тегов',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  if (isOwner) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _showEditTagsDialog(data.tags),
                      icon: const Icon(Icons.sell_outlined, size: 18),
                      label: const Text('Теги'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Condition card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.description_outlined, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Условие',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          // Owner-only buttons
                          if (isOwner) ...[
                            // OCR button (shows spinner while loading)
                            if (data.hasImage)
                              ocrState.isLoading
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: ThinkingIndicator(persona: ocrState.currentPersona ?? PersonaId.petrovich),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.auto_awesome, size: 20),
                                      onPressed: _runOcr,
                                      tooltip: 'Распознать текст (OCR)',
                                    ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => _showEditConditionDialog(data.conditionText ?? ''),
                              tooltip: 'Редактировать текст',
                            ),
                          ],
                          if (data.hasImage && data.hasText)
                            TextButton.icon(
                              onPressed: () {
                                setState(() => _showConditionImage = !_showConditionImage);
                              },
                              icon: Icon(
                                _showConditionImage ? Icons.text_fields : Icons.image_outlined,
                                size: 18,
                              ),
                              label: Text(_showConditionImage ? 'Текст' : 'Фото'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Content: text, image, or both
                      if (data.hasText && !_showConditionImage) ...[
                        MarkdownWithMath(
                          text: data.conditionText!,
                          textStyle: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ] else if (data.hasImage) ...[
                        ConditionImageThumbnail(
                          problemId: widget.problemId,
                          title: 'Условие: ${data.reference}',
                          height: 250,
                        ),
                      ] else if (_ocrText != null) ...[
                        MarkdownWithMath(
                          text: _ocrText!,
                          textStyle: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ] else ...[
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 48,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isOwner 
                                    ? 'Нажмите ⋮ для добавления условия'
                                    : 'Условие не добавлено',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Concepts card
              _ConceptsSection(
                concepts: data.concepts,
                isLoading: conceptsState.isLoading,
                currentPersona: conceptsState.currentPersona,
                onAnalyze: _runConceptsAnalysis,
              ),

              const SizedBox(height: 16),

              // Solutions
              Text(
                'Решения',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              solutions.when(
                data: (solutionList) {
                  if (solutionList.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 48,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
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

                  return Column(
                    children: solutionList.map((solution) {
                      final isSolutionOwner = currentUser?.id == solution.addedBy?.id;
                      final canStartSession = solution.isActive && isSolutionOwner;
                      final isBlockedActive = solution.isActive && !isSolutionOwner;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            solution.isActive
                                ? Icons.timer
                                : solution.isCompleted
                                    ? Icons.check_circle
                                    : Icons.pause_circle,
                            color: solution.isActive
                                ? Colors.green
                                : solution.isCompleted
                                    ? Colors.blue
                                    : Colors.orange,
                          ),
                          title: Row(
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
                          ),
                          subtitle: Row(
                            children: [
                              Text(
                                '${solution.totalMinutes.toStringAsFixed(0)} мин',
                              ),
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
                          ),
                          trailing: isBlockedActive 
                              ? Tooltip(
                                  message: 'Другой пользователь решает',
                                  child: Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                )
                              : const Icon(Icons.chevron_right),
                          onTap: isBlockedActive
                              ? () {
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '🔒 ${solution.addedBy?.displayName ?? "Другой пользователь"} еще решает эту задачу. Решение пока не готово для просмотра.',
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              : () {
                                  if (solution.isActive) {
                                    context.push(
                                        '/session/${solution.id}?existingMinutes=${solution.totalMinutes}');
                                  } else {
                                    context.push('/solutions/${solution.id}');
                                  }
                                },
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox(),
              ),
            ],
          ),
        );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(problemProvider(widget.problemId)),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading
            ? null
            : () async {
                setState(() => _isLoading = true);
                try {
                  final solution = await ref
                      .read(solutionNotifierProvider.notifier)
                      .createSolution(widget.problemId);
                  if (solution != null && mounted) {
                    context.push('/session/${solution.id}');
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_arrow),
        label: Text(_isLoading ? 'Создание...' : 'Решать'),
      ),
    );
  }
}

/// Widget for editing tags with search suggestions
class _TagsEditor extends ConsumerStatefulWidget {
  final List<String> initialTags;
  final Function(List<String>) onSaved;

  const _TagsEditor({
    required this.initialTags,
    required this.onSaved,
  });

  @override
  ConsumerState<_TagsEditor> createState() => _TagsEditorState();
}

class _TagsEditorState extends ConsumerState<_TagsEditor> {
  late List<String> _selectedTags;
  final _tagController = TextEditingController();
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _selectedTags = List.from(widget.initialTags);
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    if (!_selectedTags.contains(tag)) {
      setState(() => _selectedTags.add(tag));
    }
    _tagController.clear();
    setState(() => _showSuggestions = false);
  }

  void _removeTag(String tag) {
    setState(() => _selectedTags.remove(tag));
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = _tagController.text.isNotEmpty
        ? ref.watch(tagsProvider(_tagController.text))
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected tags chips
        if (_selectedTags.isNotEmpty) ...[
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: _selectedTags.map((tag) => Chip(
              label: Text(tag, style: const TextStyle(fontSize: 12)),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => _removeTag(tag),
              visualDensity: VisualDensity.compact,
            )).toList(),
          ),
          const SizedBox(height: 8),
        ],

        // Tag input with search
        TextField(
          controller: _tagController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'Поиск или создание тега',
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                if (_tagController.text.isNotEmpty) {
                  _addTag(_tagController.text.trim());
                }
              },
            ),
          ),
          onChanged: (value) {
            setState(() => _showSuggestions = value.isNotEmpty);
          },
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              _addTag(value.trim());
            }
          },
        ),

        // Tag suggestions dropdown
        if (_showSuggestions && tagsAsync != null)
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            child: tagsAsync.when(
              data: (tags) {
                // Filter out already selected tags
                final availableTags = tags
                    .where((t) => !_selectedTags.contains(t.name))
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
                        onTap: () => _addTag(tag.name),
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

        const SizedBox(height: 16),

        // Save button
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => widget.onSaved(_selectedTags),
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Сохранить теги'),
          ),
        ),
      ],
    );
  }
}

/// Concepts section widget for problem detail with inline expansion
class _ConceptsSection extends StatefulWidget {
  final List<ProblemConceptModel>? concepts;
  final bool isLoading;
  final PersonaId? currentPersona;
  final VoidCallback onAnalyze;

  const _ConceptsSection({
    required this.concepts,
    required this.isLoading,
    this.currentPersona,
    required this.onAnalyze,
  });

  @override
  State<_ConceptsSection> createState() => _ConceptsSectionState();
}

class _ConceptsSectionState extends State<_ConceptsSection> {
  int? _expandedConceptIndex;

  @override
  Widget build(BuildContext context) {
    final hasConcepts = widget.concepts != null && widget.concepts!.isNotEmpty;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Концепты',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (!widget.isLoading)
                  TextButton.icon(
                    onPressed: widget.onAnalyze,
                    icon: const Icon(Icons.psychology, size: 18),
                    label: Text(hasConcepts ? 'Обновить' : 'Анализ'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Show thinking indicator when loading
            if (widget.isLoading)
              ThinkingIndicator(persona: widget.currentPersona ?? PersonaId.legendre)
            else if (hasConcepts) ...[
              // List of concepts with inline expansion
              ...widget.concepts!.asMap().entries.map((entry) {
                final index = entry.key;
                final concept = entry.value;
                final isExpanded = _expandedConceptIndex == index;
                final relevance = concept.relevance ?? 0.0;
                final relevancePercent = (relevance * 100).toStringAsFixed(0);
                final color = _getRelevanceColor(relevance);
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Concept chip - clickable to expand/collapse
                    InkWell(
                      onTap: () {
                        setState(() {
                          _expandedConceptIndex = isExpanded ? null : index;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isExpanded 
                                ? color 
                                : color.withOpacity(0.3),
                            width: isExpanded ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 18,
                              color: color,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                concept.concept?.name ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$relevancePercent%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              isExpanded 
                                  ? Icons.keyboard_arrow_up 
                                  : Icons.keyboard_arrow_down,
                              color: color,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Expanded details panel
                    if (isExpanded) ...[
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            if (concept.explanation != null && concept.explanation!.isNotEmpty) ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.forum_outlined,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Объяснение',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              MarkdownWithMath(
                                text: concept.explanation!,
                                textStyle: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (concept.concept?.description != null && concept.concept!.description!.isNotEmpty) ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Описание концепта',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              MarkdownWithMath(
                                text: concept.concept!.description!,
                                textStyle: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (concept.concept?.utilityDescription != null && concept.concept!.utilityDescription!.isNotEmpty) ...[
                              Row(
                                children: [
                                  const Icon(
                                    Icons.tips_and_updates_outlined,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Практическое применение',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              MarkdownWithMath(
                                text: concept.concept!.utilityDescription!,
                                textStyle: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ],
                        ),
                    ],
                    
                    // Spacing between concepts
                    if (index < widget.concepts!.length - 1)
                      const SizedBox(height: 8),
                  ],
                );
              }),
            ] else ...[
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.psychology_outlined,
                      size: 40,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Нажмите "Анализ" для определения концептов',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getRelevanceColor(double relevance) {
    if (relevance >= 0.8) return Colors.green;
    if (relevance >= 0.5) return Colors.orange;
    return Colors.grey;
  }
}
