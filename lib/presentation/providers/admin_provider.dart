import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/services/api_client.dart';

/// Admin repository provider
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(apiClient: ref.watch(apiClientProvider));
});

/// Tags moderation state
class TagsState {
  final List<AdminTag> tags;
  final bool isLoading;
  final String? error;
  final String statusFilter;

  TagsState({
    this.tags = const [],
    this.isLoading = false,
    this.error,
    this.statusFilter = 'pending',
  });

  TagsState copyWith({
    List<AdminTag>? tags,
    bool? isLoading,
    String? error,
    String? statusFilter,
  }) {
    return TagsState(
      tags: tags ?? this.tags,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

class TagsNotifier extends StateNotifier<TagsState> {
  final AdminRepository _repository;

  TagsNotifier(this._repository) : super(TagsState());

  Future<void> load({String? statusFilter}) async {
    state = state.copyWith(isLoading: true, error: null, statusFilter: statusFilter);
    try {
      final tags = await _repository.getTags(
        moderationStatus: statusFilter ?? state.statusFilter,
      );
      state = state.copyWith(tags: tags, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> approve(int tagId) async {
    final result = await _repository.approveTag(tagId);
    if (result != null) {
      state = state.copyWith(
        tags: state.tags.where((t) => t.id != tagId).toList(),
      );
      return true;
    }
    return false;
  }

  Future<bool> reject(int tagId) async {
    final result = await _repository.rejectTag(tagId);
    if (result != null) {
      state = state.copyWith(
        tags: state.tags.where((t) => t.id != tagId).toList(),
      );
      return true;
    }
    return false;
  }

  Future<int> approveAll() async {
    int count = 0;
    for (final tag in state.tags) {
      if (await _repository.approveTag(tag.id)) {
        count++;
      }
    }
    await load();
    return count;
  }
}

final tagsNotifierProvider = StateNotifierProvider<TagsNotifier, TagsState>((ref) {
  return TagsNotifier(ref.watch(adminRepositoryProvider));
});

/// Sources moderation state
class SourcesState {
  final List<AdminSource> sources;
  final bool isLoading;
  final String? error;

  SourcesState({
    this.sources = const [],
    this.isLoading = false,
    this.error,
  });

  SourcesState copyWith({
    List<AdminSource>? sources,
    bool? isLoading,
    String? error,
  }) {
    return SourcesState(
      sources: sources ?? this.sources,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SourcesNotifier extends StateNotifier<SourcesState> {
  final AdminRepository _repository;

  SourcesNotifier(this._repository) : super(SourcesState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final sources = await _repository.getSources();
      state = state.copyWith(sources: sources, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> approve(int sourceId) async {
    final result = await _repository.approveSource(sourceId);
    if (result != null) {
      state = state.copyWith(
        sources: state.sources.where((s) => s.id != sourceId).toList(),
      );
      return true;
    }
    return false;
  }

  Future<bool> reject(int sourceId) async {
    final result = await _repository.rejectSource(sourceId);
    if (result != null) {
      state = state.copyWith(
        sources: state.sources.where((s) => s.id != sourceId).toList(),
      );
      return true;
    }
    return false;
  }

  Future<int> approveAll() async {
    int count = 0;
    for (final source in state.sources) {
      if (await _repository.approveSource(source.id)) {
        count++;
      }
    }
    await load();
    return count;
  }
}

final sourcesNotifierProvider = StateNotifierProvider<SourcesNotifier, SourcesState>((ref) {
  return SourcesNotifier(ref.watch(adminRepositoryProvider));
});

/// Problems moderation state
class ProblemsState {
  final List<AdminProblem> problems;
  final int total;
  final bool isLoading;
  final String? error;
  final int offset;

  ProblemsState({
    this.problems = const [],
    this.total = 0,
    this.isLoading = false,
    this.error,
    this.offset = 0,
  });

  ProblemsState copyWith({
    List<AdminProblem>? problems,
    int? total,
    bool? isLoading,
    String? error,
    int? offset,
  }) {
    return ProblemsState(
      problems: problems ?? this.problems,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      offset: offset ?? this.offset,
    );
  }
}

class ProblemsNotifier extends StateNotifier<ProblemsState> {
  final AdminRepository _repository;

  ProblemsNotifier(this._repository) : super(ProblemsState());

  Future<void> load({int offset = 0}) async {
    state = state.copyWith(isLoading: true, error: null, offset: offset);
    try {
      final result = await _repository.getProblems(offset: offset);
      state = state.copyWith(
        problems: result['items'] as List<AdminProblem>,
        total: result['total'] as int,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> approve(int problemId) async {
    final result = await _repository.approveProblem(problemId);
    if (result != null) {
      state = state.copyWith(
        problems: state.problems.where((p) => p.id != problemId).toList(),
        total: state.total - 1,
      );
      return true;
    }
    return false;
  }

  Future<bool> reject(int problemId) async {
    final result = await _repository.rejectProblem(problemId);
    if (result != null) {
      state = state.copyWith(
        problems: state.problems.where((p) => p.id != problemId).toList(),
        total: state.total - 1,
      );
      return true;
    }
    return false;
  }

  Future<int> approveAll() async {
    int count = 0;
    for (final problem in List.of(state.problems)) {
      if (await _repository.approveProblem(problem.id)) {
        count++;
      }
    }
    await load();
    return count;
  }
}

final problemsNotifierProvider = StateNotifierProvider<ProblemsNotifier, ProblemsState>((ref) {
  return ProblemsNotifier(ref.watch(adminRepositoryProvider));
});

/// Solutions moderation state
class SolutionsState {
  final List<AdminSolution> solutions;
  final int total;
  final bool isLoading;
  final String? error;

  SolutionsState({
    this.solutions = const [],
    this.total = 0,
    this.isLoading = false,
    this.error,
  });

  SolutionsState copyWith({
    List<AdminSolution>? solutions,
    int? total,
    bool? isLoading,
    String? error,
  }) {
    return SolutionsState(
      solutions: solutions ?? this.solutions,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SolutionsNotifier extends StateNotifier<SolutionsState> {
  final AdminRepository _repository;

  SolutionsNotifier(this._repository) : super(SolutionsState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.getSolutions();
      state = state.copyWith(
        solutions: result['items'] as List<AdminSolution>,
        total: result['total'] as int,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> approve(int solutionId) async {
    final result = await _repository.approveSolution(solutionId);
    if (result != null) {
      state = state.copyWith(
        solutions: state.solutions.where((s) => s.id != solutionId).toList(),
        total: state.total - 1,
      );
      return true;
    }
    return false;
  }

  Future<bool> reject(int solutionId) async {
    final result = await _repository.rejectSolution(solutionId);
    if (result != null) {
      state = state.copyWith(
        solutions: state.solutions.where((s) => s.id != solutionId).toList(),
        total: state.total - 1,
      );
      return true;
    }
    return false;
  }

  Future<bool> delete(int solutionId) async {
    final result = await _repository.deleteSolution(solutionId);
    if (result != null) {
      state = state.copyWith(
        solutions: state.solutions.where((s) => s.id != solutionId).toList(),
        total: state.total - 1,
      );
      return true;
    }
    return false;
  }

  Future<int> approveAll() async {
    int count = 0;
    for (final solution in List.of(state.solutions)) {
      if (await _repository.approveSolution(solution.id)) {
        count++;
      }
    }
    await load();
    return count;
  }
}

final solutionsNotifierProvider = StateNotifierProvider<SolutionsNotifier, SolutionsState>((ref) {
  return SolutionsNotifier(ref.watch(adminRepositoryProvider));
});

/// Concepts monitoring state
class ConceptsState {
  final List<AdminConcept> concepts;
  final bool isLoading;
  final String? error;
  final bool onlyWithAliases;
  final String? search;

  ConceptsState({
    this.concepts = const [],
    this.isLoading = false,
    this.error,
    this.onlyWithAliases = false,
    this.search,
  });

  ConceptsState copyWith({
    List<AdminConcept>? concepts,
    bool? isLoading,
    String? error,
    bool? onlyWithAliases,
    String? search,
  }) {
    return ConceptsState(
      concepts: concepts ?? this.concepts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      onlyWithAliases: onlyWithAliases ?? this.onlyWithAliases,
      search: search ?? this.search,
    );
  }
}

class ConceptsNotifier extends StateNotifier<ConceptsState> {
  final AdminRepository _repository;

  ConceptsNotifier(this._repository) : super(ConceptsState());

  Future<void> load({bool onlyWithAliases = false, String? search}) async {
    state = state.copyWith(isLoading: true, error: null, onlyWithAliases: onlyWithAliases, search: search);
    try {
      final allConcepts = await _repository.getConcepts();
      // Filter to show only canonical concepts
      var concepts = allConcepts.where((c) => c.isCanonical).toList();
      
      // Filter by search
      if (search != null && search.isNotEmpty) {
        concepts = concepts.where((c) =>
            c.name.toLowerCase().contains(search.toLowerCase()) ||
            c.aliases.any((a) => a.name.toLowerCase().contains(search.toLowerCase()))
        ).toList();
      }
      
      // Filter by having aliases
      if (onlyWithAliases) {
        concepts = concepts.where((c) => c.aliases.isNotEmpty).toList();
      }
      
      state = state.copyWith(concepts: concepts, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final conceptsNotifierProvider = StateNotifierProvider<ConceptsNotifier, ConceptsState>((ref) {
  return ConceptsNotifier(ref.watch(adminRepositoryProvider));
});

/// Deduplication state
class DedupState {
  final List<DedupCandidate> candidates;
  final int total;
  final int pendingCount;
  final bool isLoading;
  final String? error;
  final String statusFilter;
  final DedupResult? lastResult;

  DedupState({
    this.candidates = const [],
    this.total = 0,
    this.pendingCount = 0,
    this.isLoading = false,
    this.error,
    this.statusFilter = 'pending',
    this.lastResult,
  });

  DedupState copyWith({
    List<DedupCandidate>? candidates,
    int? total,
    int? pendingCount,
    bool? isLoading,
    String? error,
    String? statusFilter,
    DedupResult? lastResult,
  }) {
    return DedupState(
      candidates: candidates ?? this.candidates,
      total: total ?? this.total,
      pendingCount: pendingCount ?? this.pendingCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      statusFilter: statusFilter ?? this.statusFilter,
      lastResult: lastResult ?? this.lastResult,
    );
  }
}

class DedupNotifier extends StateNotifier<DedupState> {
  final AdminRepository _repository;

  DedupNotifier(this._repository) : super(DedupState());

  Future<void> loadCandidates({String statusFilter = 'pending'}) async {
    state = state.copyWith(isLoading: true, error: null, statusFilter: statusFilter);
    try {
      final result = await _repository.getDedupCandidates(status: statusFilter);
      state = state.copyWith(
        candidates: result['items'] as List<DedupCandidate>,
        total: result['total'] as int,
        pendingCount: result['pending_count'] as int,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<DedupResult?> runDeduplication(String persona) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.runDeduplication(persona);
      state = state.copyWith(isLoading: false, lastResult: result);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<bool> approve(int candidateId, {String? newName}) async {
    final result = await _repository.approveDedupCandidate(candidateId, newCanonicalName: newName);
    if (result != null) {
      state = state.copyWith(
        candidates: state.candidates.where((c) => c.id != candidateId).toList(),
        total: state.total - 1,
      );
      return true;
    }
    return false;
  }

  Future<bool> reject(int candidateId, {String? reason}) async {
    final result = await _repository.rejectDedupCandidate(candidateId, reason: reason);
    if (result) {
      state = state.copyWith(
        candidates: state.candidates.where((c) => c.id != candidateId).toList(),
        total: state.total - 1,
      );
    }
    return result;
  }

  Future<int> applyAutoApproved() async {
    final result = await _repository.applyAutoApproved();
    if (result != null) {
      await loadCandidates();
      return result['applied_candidates'] as int? ?? 0;
    }
    return 0;
  }

  Future<int> fixCycles() async {
    return await _repository.fixCycles();
  }
}

final dedupNotifierProvider = StateNotifierProvider<DedupNotifier, DedupState>((ref) {
  return DedupNotifier(ref.watch(adminRepositoryProvider));
});

/// Stats provider for admin dashboard
final adminStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  
  // Load counts for each moderation type
  final tags = await repo.getTags();
  final sources = await repo.getSources();
  final problems = await repo.getProblems();
  final solutions = await repo.getSolutions();
  final dedup = await repo.getDedupCandidates();
  
  return {
    'tags': tags.length,
    'sources': sources.length,
    'problems': problems['total'] as int? ?? 0,
    'solutions': solutions['total'] as int? ?? 0,
    'dedup_candidates': dedup['pending_count'] as int? ?? 0,
  };
});
