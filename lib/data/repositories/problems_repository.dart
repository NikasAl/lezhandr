import '../models/problem.dart';
import '../services/api_client.dart';

/// Repository for problems operations
class ProblemsRepository {
  final ApiClient _apiClient;

  ProblemsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get all sources
  Future<List<SourceModel>> getSources() async {
    final response = await _apiClient.dio.get('/sources');
    return (response.data as List)
        .map((json) => SourceModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get problems with pagination and optional filters
  /// Returns ProblemListResponse with items, total, limit, offset
  Future<ProblemListResponse> getProblems({
    String? source,
    String? search,
    String? tag,
    String? reference,
    int? userId,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (source != null) queryParams['source'] = source;
    if (search != null) queryParams['search'] = search;
    if (tag != null) queryParams['tag'] = tag;
    if (reference != null) queryParams['reference'] = reference;
    if (userId != null) queryParams['user_id'] = userId;

    final response = await _apiClient.dio.get(
      '/problems',
      queryParameters: queryParams,
    );

    return ProblemListResponse.fromJson(response.data);
  }

  /// Get single problem by ID
  Future<ProblemModel> getProblem(int id) async {
    final response = await _apiClient.dio.get('/problems/$id');
    return ProblemModel.fromJson(response.data);
  }

  /// Create new problem
  Future<ProblemModel> createProblem(ProblemCreate problem) async {
    final response = await _apiClient.dio.post(
      '/problems',
      data: problem.toJson(),
    );
    return ProblemModel.fromJson(response.data);
  }

  /// Update problem
  Future<ProblemModel> updateProblem(
    int id, {
    String? conditionText,
    String? reference,
    List<String>? tags,
  }) async {
    final data = <String, dynamic>{};
    if (conditionText != null) data['condition_text'] = conditionText;
    if (reference != null) data['reference'] = reference;
    if (tags != null) data['tags'] = tags;

    final response = await _apiClient.dio.patch(
      '/problems/$id',
      data: data,
    );
    return ProblemModel.fromJson(response.data);
  }

  /// Get tags with optional search
  Future<List<TagModel>> getTags({String? search}) async {
    final queryParams = <String, dynamic>{};
    if (search != null) queryParams['search'] = search;

    final response = await _apiClient.dio.get(
      '/tags',
      queryParameters: queryParams,
    );

    return (response.data as List)
        .map((json) => TagModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
