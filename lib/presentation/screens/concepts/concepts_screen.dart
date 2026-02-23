import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/problem.dart' show ProblemModel, ProblemListResponse;
import '../../../data/models/solution.dart';
import '../../../data/models/artifacts.dart';
import '../../../data/repositories/concepts_repository.dart'
    show ConceptsRepository, ProblemConceptModel, SolutionConceptModel;
import '../../../data/repositories/problems_repository.dart';
import '../../../data/repositories/solutions_repository.dart';
import '../../providers/providers.dart';
import '../../widgets/shared/persona_selector.dart';

/// Analysis mode enum
enum AnalysisMode { problem, solution }

/// State for concept analysis
class ConceptsAnalysisState {
  final AnalysisMode mode;
  final ProblemModel? selectedProblem;
  final SolutionModel? selectedSolution;
  final PersonaId selectedPersona;
  final bool isLoading;
  final List<ProblemConceptModel>? problemConcepts;
  final List<SolutionConceptModel>? solutionConcepts;
  final String? error;

  const ConceptsAnalysisState({
    this.mode = AnalysisMode.problem,
    this.selectedProblem,
    this.selectedSolution,
    this.selectedPersona = PersonaId.legendre,
    this.isLoading = false,
    this.problemConcepts,
    this.solutionConcepts,
    this.error,
  });

  ConceptsAnalysisState copyWith({
    AnalysisMode? mode,
    ProblemModel? selectedProblem,
    SolutionModel? selectedSolution,
    PersonaId? selectedPersona,
    bool? isLoading,
    List<ProblemConceptModel>? problemConcepts,
    List<SolutionConceptModel>? solutionConcepts,
    String? error,
    bool clearProblem = false,
    bool clearSolution = false,
    bool clearResults = false,
    bool clearError = false,
  }) {
    return ConceptsAnalysisState(
      mode: mode ?? this.mode,
      selectedProblem: clearProblem ? null : (selectedProblem ?? this.selectedProblem),
      selectedSolution: clearSolution ? null : (selectedSolution ?? this.selectedSolution),
      selectedPersona: selectedPersona ?? this.selectedPersona,
      isLoading: isLoading ?? this.isLoading,
      problemConcepts: clearResults ? null : (problemConcepts ?? this.problemConcepts),
      solutionConcepts: clearResults ? null : (solutionConcepts ?? this.solutionConcepts),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier for concept analysis
class ConceptsAnalysisNotifier extends StateNotifier<ConceptsAnalysisState> {
  final ConceptsRepository _conceptsRepository;
  final ProblemsRepository _problemsRepository;
  final SolutionsRepository _solutionsRepository;

  ConceptsAnalysisNotifier({
    required ConceptsRepository conceptsRepository,
    required ProblemsRepository problemsRepository,
    required SolutionsRepository solutionsRepository,
  })  : _conceptsRepository = conceptsRepository,
        _problemsRepository = problemsRepository,
        _solutionsRepository = solutionsRepository,
        super(const ConceptsAnalysisState());

  void setMode(AnalysisMode mode) {
    state = state.copyWith(
      mode: mode,
      clearSolution: true,
      clearResults: true,
      clearError: true,
    );
  }

  void selectProblem(ProblemModel? problem) {
    state = state.copyWith(
      selectedProblem: problem,
      clearSolution: true,
      clearResults: true,
      clearError: true,
    );
  }

  void selectSolution(SolutionModel? solution) {
    state = state.copyWith(
      selectedSolution: solution,
      clearResults: true,
      clearError: true,
    );
  }

  void setPersona(PersonaId persona) {
    state = state.copyWith(selectedPersona: persona);
  }

  Future<void> runAnalysis() async {
    if (state.mode == AnalysisMode.problem && state.selectedProblem == null) {
      state = state.copyWith(error: 'Выберите задачу для анализа');
      return;
    }
    if (state.mode == AnalysisMode.solution && state.selectedSolution == null) {
      state = state.copyWith(error: 'Выберите решение для анализа');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      if (state.mode == AnalysisMode.problem) {
        final concepts = await _conceptsRepository.analyzeProblem(
          problemId: state.selectedProblem!.id,
          persona: state.selectedPersona,
        );
        state = state.copyWith(
          isLoading: false,
          problemConcepts: concepts,
        );
      } else {
        final concepts = await _conceptsRepository.analyzeSolution(
          solutionId: state.selectedSolution!.id,
          persona: state.selectedPersona,
        );
        state = state.copyWith(
          isLoading: false,
          solutionConcepts: concepts,
        );
      }
    } catch (e) {
      String errorMsg = 'Ошибка анализа';
      if (e.toString().contains('402')) {
        errorMsg = 'Недостаточно средств на балансе';
      }
      state = state.copyWith(isLoading: false, error: errorMsg);
    }
  }

  void clearResults() {
    state = state.copyWith(clearResults: true, clearError: true);
  }
}

/// Provider for concepts analysis state
final conceptsAnalysisProvider =
    StateNotifierProvider<ConceptsAnalysisNotifier, ConceptsAnalysisState>((ref) {
  return ConceptsAnalysisNotifier(
    conceptsRepository: ref.watch(conceptsRepositoryProvider),
    problemsRepository: ref.watch(problemsRepositoryProvider),
    solutionsRepository: ref.watch(solutionsRepositoryProvider),
  );
});

/// Provider for problems list (for selection)
final problemsForConceptsProvider = FutureProvider<List<ProblemModel>>((ref) async {
  final repo = ref.watch(problemsRepositoryProvider);
  final result = await repo.getProblems(limit: 100);
  return result.items;
});

/// Provider for solutions list for a specific problem
final solutionsForProblemProvider =
    FutureProvider.family<List<SolutionModel>, int>((ref, problemId) async {
  final repo = ref.watch(solutionsRepositoryProvider);
  final result = await repo.getSolutions(problemId: problemId, limit: 50);
  return result.items;
});

/// Concepts Analysis Screen
class ConceptsScreen extends ConsumerStatefulWidget {
  const ConceptsScreen({super.key});

  @override
  ConsumerState<ConceptsScreen> createState() => _ConceptsScreenState();
}

class _ConceptsScreenState extends ConsumerState<ConceptsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      final analysisState = ref.read(conceptsAnalysisProvider);
      ref.read(conceptsAnalysisProvider.notifier).setMode(
            _tabController.index == 0 ? AnalysisMode.problem : AnalysisMode.solution,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysisState = ref.watch(conceptsAnalysisProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🧠 Анализ концепций'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Карта Знаний'),
            Tab(text: 'Трейс Навыков'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ProblemAnalysisTab(analysisState: analysisState),
          _SolutionAnalysisTab(analysisState: analysisState),
        ],
      ),
    );
  }
}

/// Problem Analysis Tab (Knowledge Map)
class _ProblemAnalysisTab extends ConsumerWidget {
  final ConceptsAnalysisState analysisState;

  const _ProblemAnalysisTab({required this.analysisState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Problem selector
          _ProblemSelector(
            selectedProblem: analysisState.selectedProblem,
            onProblemSelected: (problem) {
              ref.read(conceptsAnalysisProvider.notifier).selectProblem(problem);
            },
          ),
          const SizedBox(height: 16),

          // Persona selector
          PersonaSelector(
            selectedPersona: analysisState.selectedPersona,
            onPersonaSelected: (persona) {
              ref.read(conceptsAnalysisProvider.notifier).setPersona(persona);
            },
          ),
          const SizedBox(height: 24),

          // Analyze button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: analysisState.isLoading || analysisState.selectedProblem == null
                  ? null
                  : () {
                      ref.read(conceptsAnalysisProvider.notifier).runAnalysis();
                    },
              icon: analysisState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.psychology),
              label: Text(analysisState.isLoading ? 'Анализируем...' : 'Анализировать задачу'),
            ),
          ),

          // Error message
          if (analysisState.error != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Theme.of(context).colorScheme.onErrorContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        analysisState.error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Results
          if (analysisState.problemConcepts != null &&
              analysisState.problemConcepts!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _ProblemConceptsResults(concepts: analysisState.problemConcepts!),
          ] else if (analysisState.problemConcepts != null &&
              analysisState.problemConcepts!.isEmpty) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text(
                        'Концепты не найдены',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Solution Analysis Tab (Skill Trace)
class _SolutionAnalysisTab extends ConsumerWidget {
  final ConceptsAnalysisState analysisState;

  const _SolutionAnalysisTab({required this.analysisState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final solutionsAsync = analysisState.selectedProblem != null
        ? ref.watch(solutionsForProblemProvider(analysisState.selectedProblem!.id))
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Problem selector
          _ProblemSelector(
            selectedProblem: analysisState.selectedProblem,
            onProblemSelected: (problem) {
              ref.read(conceptsAnalysisProvider.notifier).selectProblem(problem);
            },
          ),
          const SizedBox(height: 16),

          // Solution selector
          if (analysisState.selectedProblem != null) ...[
            Text(
              'Решение',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            solutionsAsync?.when(
              data: (solutions) => _SolutionDropdown(
                solutions: solutions,
                selectedSolution: analysisState.selectedSolution,
                onSolutionSelected: (solution) {
                  ref.read(conceptsAnalysisProvider.notifier).selectSolution(solution);
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Ошибка загрузки решений'),
            ) ?? const SizedBox.shrink(),
            const SizedBox(height: 16),
          ],

          // Persona selector
          PersonaSelector(
            selectedPersona: analysisState.selectedPersona,
            onPersonaSelected: (persona) {
              ref.read(conceptsAnalysisProvider.notifier).setPersona(persona);
            },
          ),
          const SizedBox(height: 24),

          // Analyze button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: analysisState.isLoading || analysisState.selectedSolution == null
                  ? null
                  : () {
                      ref.read(conceptsAnalysisProvider.notifier).runAnalysis();
                    },
              icon: analysisState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.psychology),
              label: Text(analysisState.isLoading ? 'Анализируем...' : 'Анализировать решение'),
            ),
          ),

          // Error message
          if (analysisState.error != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Theme.of(context).colorScheme.onErrorContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        analysisState.error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Results
          if (analysisState.solutionConcepts != null &&
              analysisState.solutionConcepts!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SolutionConceptsResults(concepts: analysisState.solutionConcepts!),
          ] else if (analysisState.solutionConcepts != null &&
              analysisState.solutionConcepts!.isEmpty) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text(
                        'Концепты не найдены',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Problem selector widget
class _ProblemSelector extends ConsumerWidget {
  final ProblemModel? selectedProblem;
  final Function(ProblemModel?) onProblemSelected;

  const _ProblemSelector({
    required this.selectedProblem,
    required this.onProblemSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final problemsAsync = ref.watch(problemsForConceptsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Задача',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        problemsAsync.when(
          data: (problems) {
            if (problems.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Нет доступных задач'),
                ),
              );
            }
            return DropdownButtonFormField<ProblemModel>(
              value: selectedProblem,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Выберите задачу',
              ),
              items: problems.map((problem) {
                return DropdownMenuItem(
                  value: problem,
                  child: Text(
                    problem.displayTitle,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: onProblemSelected,
              isExpanded: true,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Ошибка загрузки: $error'),
            ),
          ),
        ),
      ],
    );
  }
}

/// Solution dropdown widget
class _SolutionDropdown extends StatelessWidget {
  final List<SolutionModel> solutions;
  final SolutionModel? selectedSolution;
  final Function(SolutionModel?) onSolutionSelected;

  const _SolutionDropdown({
    required this.solutions,
    required this.selectedSolution,
    required this.onSolutionSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (solutions.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Нет решений для этой задачи'),
        ),
      );
    }

    return DropdownButtonFormField<SolutionModel>(
      value: selectedSolution,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Выберите решение',
      ),
      items: solutions.map((solution) {
        final statusIcon = solution.isCompleted ? '✅' : (solution.isActive ? '⏳' : '❌');
        final textIcon = solution.hasText ? '📝' : '🖼️';
        return DropdownMenuItem(
          value: solution,
          child: Text(
            '$statusIcon $textIcon ID:${solution.id} (${solution.totalMinutes.toStringAsFixed(0)} мин)',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onSolutionSelected,
      isExpanded: true,
    );
  }
}

/// Problem concepts results widget
class _ProblemConceptsResults extends StatelessWidget {
  final List<ProblemConceptModel> concepts;

  const _ProblemConceptsResults({required this.concepts});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lightbulb,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Карта Знаний',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            Text(
              '${concepts.length} концептов',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: concepts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final concept = concepts[index];
              return _ProblemConceptTile(concept: concept);
            },
          ),
        ),
      ],
    );
  }
}

/// Problem concept tile
class _ProblemConceptTile extends StatelessWidget {
  final ProblemConceptModel concept;

  const _ProblemConceptTile({required this.concept});

  @override
  Widget build(BuildContext context) {
    final relevance = concept.relevance ?? 0.0;
    final relevancePercent = (relevance * 100).toStringAsFixed(0);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getRelevanceColor(relevance).withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '$relevancePercent%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getRelevanceColor(relevance),
              fontSize: 12,
            ),
          ),
        ),
      ),
      title: Text(
        concept.concept?.name ?? 'Unknown',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: concept.explanation != null
          ? Text(
              concept.explanation!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      trailing: concept.concept?.utilityDescription != null
          ? Tooltip(
              message: concept.concept!.utilityDescription!,
              child: const Icon(Icons.info_outline, size: 20),
            )
          : null,
    );
  }

  Color _getRelevanceColor(double relevance) {
    if (relevance >= 0.8) return Colors.green;
    if (relevance >= 0.5) return Colors.orange;
    return Colors.grey;
  }
}

/// Solution concepts results widget
class _SolutionConceptsResults extends StatelessWidget {
  final List<SolutionConceptModel> concepts;

  const _SolutionConceptsResults({required this.concepts});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.school,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Трейс Навыков',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            Text(
              '${concepts.length} навыков',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: concepts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final concept = concepts[index];
              return _SolutionConceptTile(concept: concept);
            },
          ),
        ),
      ],
    );
  }
}

/// Solution concept tile
class _SolutionConceptTile extends StatelessWidget {
  final SolutionConceptModel concept;

  const _SolutionConceptTile({required this.concept});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(Icons.school, size: 20),
        ),
      ),
      title: Text(
        concept.concept?.name ?? 'Unknown',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: concept.usageContext != null
          ? Text(
              concept.usageContext!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      children: [
        if (concept.usageContext != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Контекст использования:',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(concept.usageContext!),
                ],
              ),
            ),
          ),
        if (concept.concept?.description != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Описание концепта:',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(concept.concept!.description!),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
