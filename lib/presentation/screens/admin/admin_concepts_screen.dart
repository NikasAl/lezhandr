import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_provider.dart';
import '../../../data/repositories/admin_repository.dart';

/// Concepts monitoring screen with aliases grouping
class AdminConceptsScreen extends ConsumerStatefulWidget {
  const AdminConceptsScreen({super.key});

  @override
  ConsumerState<AdminConceptsScreen> createState() => _AdminConceptsScreenState();
}

class _AdminConceptsScreenState extends ConsumerState<AdminConceptsScreen> {
  final _searchController = TextEditingController();
  bool _onlyWithAliases = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conceptsNotifierProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conceptsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Мониторинг концептов'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(conceptsNotifierProvider.notifier).load(
                  onlyWithAliases: _onlyWithAliases,
                  search: _searchController.text,
                ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filters
          Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '🔍 Поиск концептов...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _applyFilters();
                      },
                    ),
                  ),
                  onSubmitted: (_) => _applyFilters(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('Все канонические'),
                      selected: !_onlyWithAliases,
                      onSelected: (_) {
                        setState(() => _onlyWithAliases = false);
                        _applyFilters();
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Только с алиасами'),
                      selected: _onlyWithAliases,
                      onSelected: (_) {
                        setState(() => _onlyWithAliases = true);
                        _applyFilters();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Text('📊 Концептов: ${state.concepts.length}'),
                const SizedBox(width: 16),
                Text(
                  'Алиасов: ${state.concepts.fold(0, (sum, c) => sum + c.aliases.length)}',
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(child: Text('Ошибка: ${state.error}'))
                    : state.concepts.isEmpty
                        ? const Center(child: Text('📭 Концепты не найдены'))
                        : ListView.builder(
                            itemCount: state.concepts.length,
                            itemBuilder: (context, index) {
                              final concept = state.concepts[index];
                              return _ConceptGroup(concept: concept);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  void _applyFilters() {
    ref.read(conceptsNotifierProvider.notifier).load(
          onlyWithAliases: _onlyWithAliases,
          search: _searchController.text,
        );
  }
}

class _ConceptGroup extends StatelessWidget {
  final AdminConcept concept;

  const _ConceptGroup({required this.concept});

  @override
  Widget build(BuildContext context) {
    final hasAliases = concept.aliases.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Canonical concept
            Row(
              children: [
                Icon(
                  hasAliases ? Icons.star : Icons.article_outlined,
                  size: 18,
                  color: hasAliases ? Colors.amber : Colors.grey,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '#${concept.id}',
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    concept.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (hasAliases)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${concept.aliases.length}',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            // Description
            if (concept.description != null && concept.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 26),
                child: Text(
                  concept.description!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],

            // Aliases
            if (hasAliases) ...[
              const SizedBox(height: 4),
              ...concept.aliases.map((alias) => Padding(
                    padding: const EdgeInsets.only(left: 26, top: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.link, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '#${alias.id}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          alias.name,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  )),
            ],

            // Actions
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.assignment_outlined, size: 18),
                    label: const Text('Задачи'),
                    onPressed: () => _showConceptProblems(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConceptProblems(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (ctx, scrollController) => _ConceptProblemsSheet(
          conceptId: concept.id,
          conceptName: concept.name,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

class _ConceptProblemsSheet extends ConsumerWidget {
  final int conceptId;
  final String conceptName;
  final ScrollController scrollController;

  const _ConceptProblemsSheet({
    required this.conceptId,
    required this.conceptName,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final problemsAsync = ref.watch(conceptProblemsProvider(conceptId));

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.account_tree_outlined, color: Colors.indigo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    conceptName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24),

          // Content
          Expanded(
            child: problemsAsync.when(
              data: (data) {
                final exposedIn = data?['exposed_in'] as List? ?? [];
                final demonstratedIn = data?['demonstrated_in'] as List? ?? [];

                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Exposed in problems
                    Text(
                      '📖 Встречается в задачах (${exposedIn.length})',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (exposedIn.isEmpty)
                      const Text('  Пока нет данных')
                    else
                      ...exposedIn.map((p) => _ProblemItem(data: p as Map<String, dynamic>)),

                    const SizedBox(height: 24),

                    // Demonstrated in solutions
                    Text(
                      '✍️ Применяется в решениях (${demonstratedIn.length})',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (demonstratedIn.isEmpty)
                      const Text('  Пока нет данных')
                    else
                      ...demonstratedIn.map((s) => _SolutionItem(data: s as Map<String, dynamic>)),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Ошибка: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProblemItem extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ProblemItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.description_outlined, size: 20),
        title: Text('[${data['id']}] ${data['reference'] ?? ''}'),
        subtitle: Text(data['source_name'] ?? ''),
      ),
    );
  }
}

class _SolutionItem extends StatelessWidget {
  final Map<String, dynamic> data;

  const _SolutionItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.edit_note, size: 20),
        title: Text('[${data['id']}] ${data['problem_reference'] ?? ''}'),
        subtitle: Text('Статус: ${data['status'] ?? ''}'),
      ),
    );
  }
}

/// Provider for concept problems
final conceptProblemsProvider = FutureProvider.family<Map<String, dynamic>?, int>((ref, conceptId) async {
  final repo = ref.watch(adminRepositoryProvider);
  return await repo.getConceptProblems(conceptId);
});
