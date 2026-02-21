import '../models/billing.dart';
import '../services/api_client.dart';

/// Repository for billing operations
class BillingRepository {
  final ApiClient _apiClient;

  BillingRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get current balance
  Future<BillingBalanceModel> getBalance() async {
    final response = await _apiClient.dio.get('/billing/balance');
    return BillingBalanceModel.fromJson(response.data);
  }

  /// Create top-up payment
  Future<TopUpResponse> createTopUp(double amount) async {
    final response = await _apiClient.dio.post(
      '/billing/top-up',
      queryParameters: {'amount': amount},
    );
    return TopUpResponse.fromJson(response.data);
  }

  /// Get transactions with pagination
  Future<TransactionListResponse> getTransactions({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _apiClient.dio.get(
      '/billing/transactions',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );
    return TransactionListResponse.fromJson(response.data);
  }
}
