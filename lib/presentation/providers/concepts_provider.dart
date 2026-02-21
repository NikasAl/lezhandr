import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/artifacts.dart';
import '../../data/repositories/concepts_repository.dart';
import 'providers.dart';

/// Provider for solution concepts (existing ones)
final solutionConceptsProvider = FutureProvider.family<List<SolutionConceptModel>, int>((ref, solutionId) async {
  final repo = ref.watch(conceptsRepositoryProvider);
  return repo.getSolutionConcepts(solutionId);
});

/// Notifier for running concept analysis
class ConceptsAnalysisNotifier extends StateNotifier<AsyncValue<void>> {
  final ConceptsRepository _conceptsRepository;
  
  ConceptsAnalysisNotifier(this._conceptsRepository) : super(const AsyncValue.data(null));

  Future<List<ProblemConceptModel>?> analyzeProblem({
    required int problemId,
    required PersonaId persona,
  }) async {
    state = const AsyncValue.loading();
    try {
      final concepts = await _conceptsRepository.analyzeProblem(
        problemId: problemId,
        persona: persona,
      );
      state = const AsyncValue.data(null);
      return concepts;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return null;
    }
  }

  Future<List<SolutionConceptModel>?> analyzeSolution({
    required int solutionId,
    required PersonaId persona,
  }) async {
    state = const AsyncValue.loading();
    try {
      final concepts = await _conceptsRepository.analyzeSolution(
        solutionId: solutionId,
        persona: persona,
      );
      state = const AsyncValue.data(null);
      return concepts;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return null;
    }
  }
}

final conceptsAnalysisNotifierProvider = StateNotifierProvider<ConceptsAnalysisNotifier, AsyncValue<void>>((ref) {
  return ConceptsAnalysisNotifier(ref.watch(conceptsRepositoryProvider));
});
