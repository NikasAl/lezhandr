import '../models/gamification.dart';
import '../services/api_client.dart';

/// Repository for gamification operations
class GamificationRepository {
  final ApiClient _apiClient;

  GamificationRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  /// Get current user's gamification data
  Future<GamificationModel> getMe() async {
    final response = await _apiClient.dio.get('/gamification/me');
    return GamificationModel.fromJson(response.data);
  }

  /// Get daily activity for last N days
  Future<ActivityResponse> getDailyActivity({int days = 7}) async {
    final response = await _apiClient.dio.get(
      '/gamification/activity/daily',
      queryParameters: {'last_days': days},
    );
    return ActivityResponse.fromJson(response.data);
  }
}
