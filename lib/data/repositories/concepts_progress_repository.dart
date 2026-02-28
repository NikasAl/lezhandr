import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/concept_progress.dart';
import 'providers.dart';

/// Repository for concept progress operations
class ConceptsProgressRepository {
  final ApiClient _apiClient;

  ConceptsProgressRepository(this._apiClient);

  /// Get user's concept progress with pagination
  Future<ConceptProgressListResponse> getMyConceptProgress({
    String? sortBy,
    int? filterTier,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    
    if (sortBy != null) {
      queryParams['sort_by'] = sortBy;
    }
    if (filterTier != null) {
      queryParams['tier'] = filterTier.toString();
    }

    final response = await _apiClient.get(
      '/concepts/progress/me',
      queryParameters: queryParams,
    );

    return ConceptProgressListResponse.fromJson(response.data);
  }

  /// Get concept progress statistics
  Future<ConceptStatsModel> getMyConceptStats() async {
    final response = await _apiClient.get('/concepts/progress/me/stats');
    return ConceptStatsModel.fromJson(response.data);
  }

  /// Get detailed info about a concept including problems/solutions
  Future<ConceptDetailModel> getConceptDetail(int conceptId) async {
    final response = await _apiClient.get('/concepts/$conceptId/problems');
    return ConceptDetailModel.fromJson(response.data);
  }
}

/// Provider for concepts progress repository
final conceptsProgressRepositoryProvider = Provider<ConceptsProgressRepository>((ref) {
  return ConceptsProgressRepository(ref.watch(apiClientProvider));
});
