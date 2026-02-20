import '../models/solution.dart';
import '../services/api_client.dart';

/// Repository for solutions operations
class SolutionsRepository {
  final ApiClient _apiClient;

  SolutionsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get solutions with pagination and optional filters
  /// Returns SolutionListResponse with items, total, limit, offset
  Future<SolutionListResponse> getSolutions({
    int? problemId,
    SolutionStatus? status,
    int? userId,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (problemId != null) queryParams['problem_id'] = problemId;
    if (status != null) queryParams['status'] = status.name;
    if (userId != null) queryParams['user_id'] = userId;

    final response = await _apiClient.dio.get(
      '/solutions',
      queryParameters: queryParams,
    );

    return SolutionListResponse.fromJson(response.data);
  }

  /// Get active solutions (convenience method)
  Future<List<SolutionModel>> getActiveSolutions() async {
    final response = await getSolutions(status: SolutionStatus.active, limit: 100);
    return response.items;
  }

  /// Get single solution by ID
  Future<SolutionModel> getSolution(int id) async {
    final response = await _apiClient.dio.get('/solutions/$id');
    return SolutionModel.fromJson(response.data);
  }

  /// Create new solution for a problem
  Future<SolutionModel> createSolution(int problemId) async {
    final response = await _apiClient.dio.post(
      '/solutions',
      data: {'problem_id': problemId},
    );
    return SolutionModel.fromJson(response.data);
  }

  /// Finish solution with ratings
  Future<SolutionModel> finishSolution(
    int id, {
    required String status,
    int? difficulty,
    double? quality,
    String? notes,
  }) async {
    final response = await _apiClient.dio.patch(
      '/solutions/$id',
      data: {
        'status': status,
        'personal_difficulty': difficulty,
        'quality_score': quality,
        'user_notes': notes,
      },
    );
    return SolutionModel.fromJson(response.data);
  }

  /// Update solution text
  Future<SolutionModel> updateSolutionText(int id, String text) async {
    final response = await _apiClient.dio.patch(
      '/solutions/$id',
      data: {'solution_text': text},
    );
    return SolutionModel.fromJson(response.data);
  }

  /// Create session record
  Future<SessionModel> createSession(SessionCreate session) async {
    final response = await _apiClient.dio.post(
      '/sessions',
      data: session.toJson(),
    );
    return SessionModel.fromJson(response.data);
  }
}
