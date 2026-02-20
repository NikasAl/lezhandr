import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/problem.dart';
import '../../data/repositories/problems_repository.dart';
import 'providers.dart';

/// Sources provider
final sourcesProvider = FutureProvider<List<SourceModel>>((ref) async {
  final repo = ref.watch(problemsRepositoryProvider);
  return await repo.getSources();
});

/// Problems list response provider with pagination and filters
/// Returns full ProblemListResponse with items, total, limit, offset
final problemsListProvider =
    FutureProvider.family<ProblemListResponse, ProblemsFilter>((ref, filter) async {
  final repo = ref.watch(problemsRepositoryProvider);
  return await repo.getProblems(
    source: filter.source,
    search: filter.search,
    tag: filter.tag,
    reference: filter.reference,
    userId: filter.userId,
    limit: filter.limit,
    offset: filter.offset,
  );
});

/// Legacy provider for backward compatibility - returns just the items list
final problemsProvider =
    FutureProvider.family<List<ProblemModel>, ProblemsFilter?>(
        (ref, filter) async {
  final repo = ref.watch(problemsRepositoryProvider);
  final response = await repo.getProblems(
    source: filter?.source,
    search: filter?.search,
    tag: filter?.tag,
    reference: filter?.reference,
    userId: filter?.userId,
    limit: filter?.limit ?? 20,
    offset: filter?.offset ?? 0,
  );
  return response.items;
});

/// Single problem provider
final problemProvider =
    FutureProvider.family<ProblemModel, int>((ref, id) async {
  final repo = ref.watch(problemsRepositoryProvider);
  return await repo.getProblem(id);
});

/// Tags provider
final tagsProvider =
    FutureProvider.family<List<TagModel>, String?>((ref, search) async {
  final repo = ref.watch(problemsRepositoryProvider);
  return await repo.getTags(search: search);
});

/// Problems notifier for CRUD operations
final problemNotifierProvider =
    StateNotifierProvider<ProblemNotifier, AsyncValue<void>>((ref) {
  return ProblemNotifier(ref.watch(problemsRepositoryProvider));
});

class ProblemNotifier extends StateNotifier<AsyncValue<void>> {
  final ProblemsRepository _repo;

  ProblemNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<ProblemModel?> createProblem(ProblemCreate problem) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.createProblem(problem);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<ProblemModel?> updateProblem(
    int id, {
    String? conditionText,
    String? reference,
    List<String>? tags,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.updateProblem(
        id,
        conditionText: conditionText,
        reference: reference,
        tags: tags,
      );
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

/// Problems filter with pagination support
class ProblemsFilter {
  final String? source;
  final String? search;
  final String? tag;
  final String? reference;
  final int? userId;
  final int limit;
  final int offset;

  const ProblemsFilter({
    this.source,
    this.search,
    this.tag,
    this.reference,
    this.userId,
    this.limit = 20,
    this.offset = 0,
  });

  ProblemsFilter copyWith({
    String? source,
    String? search,
    String? tag,
    String? reference,
    int? userId,
    int? limit,
    int? offset,
  }) {
    return ProblemsFilter(
      source: source ?? this.source,
      search: search ?? this.search,
      tag: tag ?? this.tag,
      reference: reference ?? this.reference,
      userId: userId ?? this.userId,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  /// Create filter for next page
  ProblemsFilter nextPage() {
    return copyWith(offset: offset + limit);
  }

  /// Create filter for previous page
  ProblemsFilter previousPage() {
    return copyWith(offset: offset - limit < 0 ? 0 : offset - limit);
  }

  /// Check if this is the first page
  bool get isFirstPage => offset == 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProblemsFilter &&
          runtimeType == other.runtimeType &&
          source == other.source &&
          search == other.search &&
          tag == other.tag &&
          reference == other.reference &&
          userId == other.userId &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode =>
      source.hashCode ^ 
      search.hashCode ^ 
      tag.hashCode ^ 
      reference.hashCode ^
      userId.hashCode ^
      limit.hashCode ^
      offset.hashCode;
}
