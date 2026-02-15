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

/// Billing notifier for actions
class BillingNotifier extends StateNotifier<AsyncValue<BillingBalanceModel?>> {
  final BillingRepository _repo;

  BillingNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<String?> createTopUp(double amount) async {
    try {
      final response = await _repo.createTopUp(amount);
      return response.paymentUrl;
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
