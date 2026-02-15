import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/gamification.dart';
import '../../data/repositories/gamification_repository.dart';
import 'providers.dart';

/// Gamification data provider
final gamificationMeProvider = FutureProvider<GamificationModel?>((ref) async {
  final repo = ref.watch(gamificationRepositoryProvider);
  try {
    return await repo.getMe();
  } catch (e) {
    return null;
  }
});

/// Activity provider
final activityProvider =
    FutureProvider.family<ActivityResponse?, int>((ref, days) async {
  final repo = ref.watch(gamificationRepositoryProvider);
  try {
    return await repo.getDailyActivity(days: days);
  } catch (e) {
    return null;
  }
});

/// Gamification notifier for refreshing
class GamificationNotifier extends StateNotifier<AsyncValue<GamificationModel?>> {
  final GamificationRepository _repo;

  GamificationNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repo.getMe();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final gamificationNotifierProvider =
    StateNotifierProvider<GamificationNotifier, AsyncValue<GamificationModel?>>(
        (ref) {
  return GamificationNotifier(ref.watch(gamificationRepositoryProvider));
});
