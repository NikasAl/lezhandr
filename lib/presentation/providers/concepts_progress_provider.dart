import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/concept_progress.dart';
import '../../data/repositories/concepts_progress_repository.dart';
import 'providers.dart';

/// Sort options for concept progress
enum ConceptSortBy {
  mastery('mastery'),
  exposedCount('exposed_count'),
  demonstratedCount('demonstrated_count'),
  name('name');

  final String value;
  const ConceptSortBy(this.value);
}

/// Filter for concept progress list
class ConceptProgressFilter {
  final ConceptSortBy sortBy;
  final int? tierFilter; // null means all tiers
  final int limit;
  final int offset;

  const ConceptProgressFilter({
    this.sortBy = ConceptSortBy.mastery,
    this.tierFilter,
    this.limit = 50,
    this.offset = 0,
  });

  ConceptProgressFilter copyWith({
    ConceptSortBy? sortBy,
    int? tierFilter,
    bool clearTierFilter = false,
    int? limit,
    int? offset,
  }) {
    return ConceptProgressFilter(
      sortBy: sortBy ?? this.sortBy,
      tierFilter: clearTierFilter ? null : (tierFilter ?? this.tierFilter),
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConceptProgressFilter &&
          runtimeType == other.runtimeType &&
          sortBy == other.sortBy &&
          tierFilter == other.tierFilter &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode =>
      sortBy.hashCode ^ tierFilter.hashCode ^ limit.hashCode ^ offset.hashCode;
}

/// Provider for concept progress list
final conceptProgressListProvider = FutureProvider.family<
    ConceptProgressListResponse, ConceptProgressFilter>((ref, filter) async {
  final repo = ref.watch(conceptsProgressRepositoryProvider);
  return await repo.getMyConceptProgress(
    sortBy: filter.sortBy.value,
    filterTier: filter.tierFilter,
    limit: filter.limit,
    offset: filter.offset,
  );
});

/// Provider for concept stats
final conceptStatsProvider = FutureProvider<ConceptStatsModel>((ref) async {
  final repo = ref.watch(conceptsProgressRepositoryProvider);
  return await repo.getMyConceptStats();
});

/// Provider for concept detail
final conceptDetailProvider =
    FutureProvider.family<ConceptDetailModel, int>((ref, conceptId) async {
  final repo = ref.watch(conceptsProgressRepositoryProvider);
  return await repo.getConceptDetail(conceptId);
});
