import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/billing.dart';
import '../../data/repositories/billing_repository.dart';
import 'providers.dart';

/// Billing balance provider
final billingBalanceProvider = FutureProvider<BillingBalanceModel?>((ref) async {
  final repo = ref.watch(billingRepositoryProvider);
  try {
    return await repo.getBalance();
  } catch (e) {
    return null;
  }
});

/// Transactions filter for pagination
class TransactionsFilter {
  final int limit;
  final int offset;

  const TransactionsFilter({
    this.limit = 20,
    this.offset = 0,
  });

  TransactionsFilter copyWith({
    int? limit,
    int? offset,
  }) {
    return TransactionsFilter(
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionsFilter &&
          runtimeType == other.runtimeType &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode => limit.hashCode ^ offset.hashCode;
}

/// Transactions list provider with pagination
final transactionsListProvider =
    FutureProvider.family<TransactionListResponse, TransactionsFilter>(
        (ref, filter) async {
  final repo = ref.watch(billingRepositoryProvider);
  return await repo.getTransactions(
    limit: filter.limit,
    offset: filter.offset,
  );
});

/// Billing notifier for actions
class BillingNotifier extends StateNotifier<AsyncValue<BillingBalanceModel?>> {
  final BillingRepository _repo;

  BillingNotifier(this._repo) : super(const AsyncValue.data(null));

  /// Create top-up payment and return payment URL
  Future<TopUpResponse?> createTopUp(double amount) async {
    try {
      final response = await _repo.createTopUp(amount);
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repo.getBalance();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final billingNotifierProvider =
    StateNotifierProvider<BillingNotifier, AsyncValue<BillingBalanceModel?>>(
        (ref) {
  return BillingNotifier(ref.watch(billingRepositoryProvider));
});
