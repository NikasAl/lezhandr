import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/problem.dart';
import '../../data/repositories/problems_repository.dart';
import 'providers.dart';

/// Sources provider
final sourcesProvider = FutureProvider<List<SourceModel>>((ref) async {
  final repo = ref.watch(problemsRepositoryProvider);
  return await repo.getSources();
});

/// Problems provider with filters
final problemsProvider =
    FutureProvider.family<List<ProblemModel>, ProblemsFilter?>(
        (ref, filter) async {
  final repo = ref.watch(problemsRepositoryProvider);
  return await repo.getProblems(
    source: filter?.source,
    search: filter?.search,
    tag: filter?.tag,
    reference: filter?.reference,
  );
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

/// Problems filter
class ProblemsFilter {
  final String? source;
  final String? search;
  final String? tag;
  final String? reference;

  const ProblemsFilter({
    this.source,
    this.search,
    this.tag,
    this.reference,
  });

  ProblemsFilter copyWith({
    String? source,
    String? search,
    String? tag,
    String? reference,
  }) {
    return ProblemsFilter(
      source: source ?? this.source,
      search: search ?? this.search,
      tag: tag ?? this.tag,
      reference: reference ?? this.reference,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProblemsFilter &&
          runtimeType == other.runtimeType &&
          source == other.source &&
          search == other.search &&
          tag == other.tag &&
          reference == other.reference;

  @override
  int get hashCode =>
      source.hashCode ^ search.hashCode ^ tag.hashCode ^ reference.hashCode;
}
