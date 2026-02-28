import '../models/concept_progress.dart';
import '../services/api_client.dart';

/// Repository for concept progress operations
class ConceptsProgressRepository {
  final ApiClient _apiClient;

  ConceptsProgressRepository({required ApiClient apiClient}) : _apiClient = apiClient;

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
      queryParams['min_tier'] = filterTier.toString();
    }

    final response = await _apiClient.dio.get(
      '/concepts/progress/me',
      queryParameters: queryParams,
    );

    return ConceptProgressListResponse.fromJson(response.data);
  }

  /// Get concept progress statistics
  Future<ConceptStatsModel> getMyConceptStats() async {
    final response = await _apiClient.dio.get('/concepts/progress/me/stats');
    return ConceptStatsModel.fromJson(response.data);
  }

  /// Get detailed info about a concept including problems/solutions
  Future<ConceptDetailModel> getConceptDetail(int conceptId) async {
    final response = await _apiClient.dio.get('/concepts/$conceptId/problems');
    return ConceptDetailModel.fromJson(response.data);
  }
}
