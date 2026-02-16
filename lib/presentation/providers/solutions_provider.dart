import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/solution.dart';
import '../../data/repositories/solutions_repository.dart';
import 'providers.dart';

/// Active solutions provider
final activeSolutionsProvider = FutureProvider<List<SolutionModel>>((ref) async {
  final repo = ref.watch(solutionsRepositoryProvider);
  return await repo.getActiveSolutions();
});

/// Solutions for a problem
final problemSolutionsProvider =
    FutureProvider.family<List<SolutionModel>, int>((ref, problemId) async {
  final repo = ref.watch(solutionsRepositoryProvider);
  return await repo.getSolutions(problemId: problemId);
});

/// Single solution provider
final solutionProvider =
    FutureProvider.family<SolutionModel, int>((ref, id) async {
  final repo = ref.watch(solutionsRepositoryProvider);
  return await repo.getSolution(id);
});

/// Solution notifier for mutations
class SolutionNotifier extends StateNotifier<AsyncValue<SolutionModel?>> {
  final SolutionsRepository _repo;

  SolutionNotifier(this._repo) : super(const AsyncValue.data(null));

  /// Create new solution
  Future<SolutionModel?> createSolution(int problemId) async {
    state = const AsyncValue.loading();
    try {
      final solution = await _repo.createSolution(problemId);
      state = AsyncValue.data(solution);
      return solution;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Finish solution
  Future<SolutionModel?> finishSolution(
    int solutionId, {
    required String status,
    int? difficulty,
    double? quality,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final solution = await _repo.finishSolution(
        solutionId,
        status: status,
        difficulty: difficulty,
        quality: quality,
        notes: notes,
      );
      state = AsyncValue.data(solution);
      return solution;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Update solution text
  Future<bool> updateSolutionText(int solutionId, String text) async {
    try {
      final solution = await _repo.updateSolutionText(solutionId, text);
      state = AsyncValue.data(solution);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Create session
  Future<bool> createSession(SessionCreate session) async {
    try {
      await _repo.createSession(session);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Solution notifier provider
final solutionNotifierProvider =
    StateNotifierProvider<SolutionNotifier, AsyncValue<SolutionModel?>>((ref) {
  return SolutionNotifier(ref.watch(solutionsRepositoryProvider));
});
