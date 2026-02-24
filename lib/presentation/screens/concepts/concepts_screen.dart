import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/problem.dart' show ProblemModel, ProblemListResponse, ProblemConceptModel, ConceptModel;
import '../../../data/models/solution.dart';
import '../../../data/models/artifacts.dart';
import '../../../data/repositories/concepts_repository.dart'
    show ConceptsRepository, SolutionConceptModel, ConceptModelForSolution;
import '../../../data/repositories/problems_repository.dart';
import '../../../data/repositories/solutions_repository.dart';
import '../../providers/providers.dart';
import '../../widgets/shared/persona_selector.dart';
import '../../widgets/shared/markdown_with_math.dart';

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

/// Provider for existing solution concepts
final existingSolutionConceptsProvider =
    FutureProvider.family<List<SolutionConceptModel>, int>((ref, solutionId) async {
  final repo = ref.watch(conceptsRepositoryProvider);
  return await repo.getSolutionConcepts(solutionId);
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

/// Problem Analysis Tab (Knowledge Map) with swipeable cards
class _ProblemAnalysisTab extends ConsumerStatefulWidget {
  final ConceptsAnalysisState analysisState;

  const _ProblemAnalysisTab({required this.analysisState});

  @override
  ConsumerState<_ProblemAnalysisTab> createState() => _ProblemAnalysisTabState();
}

class _ProblemAnalysisTabState extends ConsumerState<_ProblemAnalysisTab> {
  PageController? _pageController;
  int _currentPage = 0;
  List<ProblemModel> _problems = [];

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final problemsAsync = ref.watch(problemsForConceptsProvider);

    return problemsAsync.when(
      data: (problems) {
        // Initialize page controller and problems list
        if (_problems != problems) {
          _problems = problems;
          _pageController?.dispose();
          _pageController = PageController(
            initialPage: _currentPage.clamp(0, problems.length - 1),
            viewportFraction: 0.92,
          );
          
          // Select initial problem if none selected
          if (widget.analysisState.selectedProblem == null && problems.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(conceptsAnalysisProvider.notifier).selectProblem(problems.first);
            });
          }
        }

        if (problems.isEmpty) {
          return _buildEmptyState(context);
        }

        return Column(
          children: [
            // Swipeable problem cards
            SizedBox(
              height: 320,
              child: PageView.builder(
                controller: _pageController,
                itemCount: problems.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                  ref.read(conceptsAnalysisProvider.notifier).selectProblem(problems[index]);
                },
                itemBuilder: (context, index) {
                  final problem = problems[index];
                  final isSelected = widget.analysisState.selectedProblem?.id == problem.id;
                  return _ProblemSwipeCard(
                    problem: problem,
                    isSelected: isSelected,
                  );
                },
              ),
            ),
            
            // Page indicator
            if (problems.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    problems.length > 10 ? 10 : problems.length,
                    (index) {
                      final isActive = index == _currentPage;
                      final isRealIndex = problems.length <= 10 || index < problems.length - (problems.length - 10);
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    },
                  ),
                ),
              ),
            
            // Expanded content
            Expanded(
              child: _ProblemAnalysisContent(
                analysisState: widget.analysisState,
                selectedProblem: widget.analysisState.selectedProblem,
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
            Text('Ошибка: $error'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(problemsForConceptsProvider),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
            'Нет задач для анализа',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Создайте задачи в Библиотеке',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

/// Swipeable problem card with concepts preview
class _ProblemSwipeCard extends StatelessWidget {
  final ProblemModel problem;
  final bool isSelected;

  const _ProblemSwipeCard({
    required this.problem,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Use concepts from problem model directly (no separate API call)
    final concepts = problem.concepts ?? [];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      problem.hasText ? Icons.description : Icons.image,
                      size: 18,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          problem.reference,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          problem.sourceName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Tags
            if (problem.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: problem.tags.take(4).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag.name,
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            
            // Condition preview
            if (problem.hasText)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: MarkdownWithMath(
                        text: problem.conditionText!,
                        textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ),
                ),
              )
            else if (problem.hasImage)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
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
            
            // Existing concepts chips (from problem model)
            if (concepts.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Концепты: ${concepts.length}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: concepts.take(3).map((c) {
                        final name = c.concept?.name ?? '?';
                        final relevance = c.relevance;
                        final color = _getRelevanceColor(relevance);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: color.withOpacity(0.3)),
                          ),
                          child: Text(
                            name,
                            style: TextStyle(fontSize: 10, color: color),
                          ),
                        );
                      }).toList(),
                    ),
                    if (concepts.length > 3)
                      Text(
                        '  +${concepts.length - 3} ещё',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                  ],
                ),
              ),
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

/// Content area for problem analysis
class _ProblemAnalysisContent extends ConsumerWidget {
  final ConceptsAnalysisState analysisState;
  final ProblemModel? selectedProblem;

  const _ProblemAnalysisContent({
    required this.analysisState,
    required this.selectedProblem,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Persona selector
          PersonaSelector(
            selectedPersona: analysisState.selectedPersona,
            onPersonaSelected: (persona) {
              ref.read(conceptsAnalysisProvider.notifier).setPersona(persona);
            },
          ),
          const SizedBox(height: 16),

          // Analyze button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: analysisState.isLoading || selectedProblem == null
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

/// Solution Analysis Tab (Skill Trace) with swipeable solution cards
class _SolutionAnalysisTab extends ConsumerStatefulWidget {
  final ConceptsAnalysisState analysisState;

  const _SolutionAnalysisTab({required this.analysisState});

  @override
  ConsumerState<_SolutionAnalysisTab> createState() => _SolutionAnalysisTabState();
}

class _SolutionAnalysisTabState extends ConsumerState<_SolutionAnalysisTab> {
  PageController? _problemPageController;
  PageController? _solutionPageController;
  int _currentProblemPage = 0;
  int _currentSolutionPage = 0;
  List<ProblemModel> _problems = [];

  @override
  void dispose() {
    _problemPageController?.dispose();
    _solutionPageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final problemsAsync = ref.watch(problemsForConceptsProvider);

    return problemsAsync.when(
      data: (problems) {
        if (_problems != problems) {
          _problems = problems;
          _problemPageController?.dispose();
          _problemPageController = PageController(
            initialPage: _currentProblemPage.clamp(0, problems.length - 1),
            viewportFraction: 0.92,
          );
          
          // Select initial problem if none selected
          if (widget.analysisState.selectedProblem == null && problems.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(conceptsAnalysisProvider.notifier).selectProblem(problems.first);
            });
          }
        }

        if (problems.isEmpty) {
          return _buildEmptyState(context);
        }

        // Get solutions for selected problem
        final selectedProblem = widget.analysisState.selectedProblem ?? problems.first;
        final solutionsAsync = ref.watch(solutionsForProblemProvider(selectedProblem.id));

        return Column(
          children: [
            // Problem selector header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Задача',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ),
            
            // Problem cards (smaller)
            SizedBox(
              height: 140,
              child: PageView.builder(
                controller: _problemPageController,
                itemCount: problems.length,
                onPageChanged: (index) {
                  setState(() => _currentProblemPage = index);
                  ref.read(conceptsAnalysisProvider.notifier).selectProblem(problems[index]);
                },
                itemBuilder: (context, index) {
                  final problem = problems[index];
                  return _SmallProblemCard(
                    problem: problem,
                    isSelected: selectedProblem.id == problem.id,
                  );
                },
              ),
            ),
            
            // Problem page indicator
            if (problems.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    problems.length > 10 ? 10 : problems.length,
                    (index) {
                      final isActive = index == _currentProblemPage;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: isActive ? 12 : 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    },
                  ),
                ),
              ),
            
            // Solutions section
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Решение',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                ],
              ),
            ),
            
            // Solution cards
            Expanded(
              child: solutionsAsync.when(
                data: (solutions) {
                  if (solutions.isEmpty) {
                    return _buildNoSolutions(context);
                  }
                  
                  // Initialize solution page controller
                  _solutionPageController?.dispose();
                  _solutionPageController = PageController(
                    initialPage: _currentSolutionPage.clamp(0, solutions.length - 1),
                    viewportFraction: 0.92,
                  );
                  
                  // Select first solution if none selected
                  if (widget.analysisState.selectedSolution == null && solutions.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ref.read(conceptsAnalysisProvider.notifier).selectSolution(solutions.first);
                    });
                  }
                  
                  return Column(
                    children: [
                      SizedBox(
                        height: 160,
                        child: PageView.builder(
                          controller: _solutionPageController,
                          itemCount: solutions.length,
                          onPageChanged: (index) {
                            setState(() => _currentSolutionPage = index);
                            ref.read(conceptsAnalysisProvider.notifier).selectSolution(solutions[index]);
                          },
                          itemBuilder: (context, index) {
                            final solution = solutions[index];
                            final isSelected = widget.analysisState.selectedSolution?.id == solution.id;
                            return _SolutionSwipeCard(
                              solution: solution,
                              isSelected: isSelected,
                            );
                          },
                        ),
                      ),
                      
                      // Solution page indicator
                      if (solutions.length > 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              solutions.length > 10 ? 10 : solutions.length,
                              (index) {
                                final isActive = index == _currentSolutionPage;
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  width: isActive ? 12 : 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Theme.of(context).colorScheme.secondary
                                        : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      
                      // Analysis content
                      Expanded(
                        child: _SolutionAnalysisContent(
                          analysisState: widget.analysisState,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Ошибка загрузки решений')),
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
            Text('Ошибка: $error'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(problemsForConceptsProvider),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
            'Нет задач для анализа',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildNoSolutions(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hourglass_empty,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'Нет решений для этой задачи',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Решите задачу, чтобы проанализировать навыки',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

/// Small problem card for solution tab
class _SmallProblemCard extends StatelessWidget {
  final ProblemModel problem;
  final bool isSelected;

  const _SmallProblemCard({
    required this.problem,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  problem.hasText ? Icons.description : Icons.image,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      problem.reference,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      problem.sourceName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (problem.tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 4,
                          children: problem.tags.take(2).map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tag.name,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Swipeable solution card
class _SolutionSwipeCard extends ConsumerWidget {
  final SolutionModel solution;
  final bool isSelected;

  const _SolutionSwipeCard({
    required this.solution,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final existingConcepts = ref.watch(existingSolutionConceptsProvider(solution.id));
    
    final statusColor = solution.isCompleted
        ? Colors.blue
        : solution.isActive
            ? Colors.green
            : Colors.orange;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      solution.isActive
                          ? Icons.timer
                          : solution.isCompleted
                              ? Icons.check_circle
                              : Icons.pause_circle,
                      size: 18,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'ID: ${solution.id}',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                solution.statusText,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: statusColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${solution.totalMinutes.toStringAsFixed(0)} мин',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            if (solution.xpEarned != null) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.star, size: 12, color: Colors.amber[700]),
                              const SizedBox(width: 2),
                              Text(
                                '${solution.xpEarned!.toStringAsFixed(0)} XP',
                                style: TextStyle(fontSize: 11, color: Colors.amber[700]),
                              ),
                            ],
                            if (solution.hasText) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.article, size: 12, color: Colors.grey[600]),
                            ],
                            if (solution.hasImage) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.photo, size: 12, color: Colors.grey[600]),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Existing concepts
            existingConcepts.when(
              data: (concepts) {
                if (concepts.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Навыки ещё не проанализированы',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ],
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.school,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Навыки: ${concepts.length}',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: concepts.take(4).map((c) {
                          final name = c.concept?.name ?? '?';
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (concepts.length > 4)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '+${concepts.length - 4} ещё',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                    ],
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Content area for solution analysis
class _SolutionAnalysisContent extends ConsumerWidget {
  final ConceptsAnalysisState analysisState;

  const _SolutionAnalysisContent({
    required this.analysisState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Persona selector
          PersonaSelector(
            selectedPersona: analysisState.selectedPersona,
            onPersonaSelected: (persona) {
              ref.read(conceptsAnalysisProvider.notifier).setPersona(persona);
            },
          ),
          const SizedBox(height: 16),

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
                        'Навыки не найдены',
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
