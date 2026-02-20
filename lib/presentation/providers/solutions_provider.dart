import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/solution.dart';
import '../../data/repositories/solutions_repository.dart';
import 'providers.dart';

/// Active solutions provider
final activeSolutionsProvider = FutureProvider<List<SolutionModel>>((ref) async {
  final repo = ref.watch(solutionsRepositoryProvider);
  return await repo.getActiveSolutions();
});

/// Solutions for a problem with pagination
/// Returns full SolutionListResponse with items, total, limit, offset
final solutionsListProvider =
    FutureProvider.family<SolutionListResponse, SolutionsFilter>((ref, filter) async {
  final repo = ref.watch(solutionsRepositoryProvider);
  return await repo.getSolutions(
    problemId: filter.problemId,
    status: filter.status,
    userId: filter.userId,
    limit: filter.limit,
    offset: filter.offset,
  );
});

/// Solutions for a problem (legacy - returns just items list)
final problemSolutionsProvider =
    FutureProvider.family<List<SolutionModel>, int>((ref, problemId) async {
  final repo = ref.watch(solutionsRepositoryProvider);
  final response = await repo.getSolutions(problemId: problemId, limit: 100);
  return response.items;
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

/// Solutions filter with pagination support
class SolutionsFilter {
  final int? problemId;
  final SolutionStatus? status;
  final int? userId;
  final int limit;
  final int offset;

  const SolutionsFilter({
    this.problemId,
    this.status,
    this.userId,
    this.limit = 20,
    this.offset = 0,
  });

  SolutionsFilter copyWith({
    int? problemId,
    SolutionStatus? status,
    int? userId,
    int? limit,
    int? offset,
  }) {
    return SolutionsFilter(
      problemId: problemId ?? this.problemId,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  /// Create filter for next page
  SolutionsFilter nextPage() {
    return copyWith(offset: offset + limit);
  }

  /// Check if this is the first page
  bool get isFirstPage => offset == 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SolutionsFilter &&
          runtimeType == other.runtimeType &&
          problemId == other.problemId &&
          status == other.status &&
          userId == other.userId &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode =>
      problemId.hashCode ^
      status.hashCode ^
      userId.hashCode ^
      limit.hashCode ^
      offset.hashCode;
}
