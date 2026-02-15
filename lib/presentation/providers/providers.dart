import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/api_client.dart';
import '../../data/storage/token_storage.dart';
import '../../data/storage/device_storage.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/problems_repository.dart';
import '../../data/repositories/solutions_repository.dart';
import '../../data/repositories/gamification_repository.dart';
import '../../data/repositories/billing_repository.dart';
import '../../data/repositories/uploads_repository.dart';
import '../../data/repositories/artifacts_repository.dart';
import '../../data/repositories/concepts_repository.dart';

// Storage providers
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

final deviceStorageProvider = Provider<DeviceStorage>((ref) {
  return DeviceStorage();
});

// API Client provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    tokenStorage: ref.watch(tokenStorageProvider),
    deviceStorage: ref.watch(deviceStorageProvider),
  );
});

// Repository providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    deviceStorage: ref.watch(deviceStorageProvider),
  );
});

final problemsRepositoryProvider = Provider<ProblemsRepository>((ref) {
  return ProblemsRepository(apiClient: ref.watch(apiClientProvider));
});

final solutionsRepositoryProvider = Provider<SolutionsRepository>((ref) {
  return SolutionsRepository(apiClient: ref.watch(apiClientProvider));
});

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  return GamificationRepository(apiClient: ref.watch(apiClientProvider));
});

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepository(apiClient: ref.watch(apiClientProvider));
});

// New repository providers
final uploadsRepositoryProvider = Provider<UploadsRepository>((ref) {
  return UploadsRepository(apiClient: ref.watch(apiClientProvider));
});

final artifactsRepositoryProvider = Provider<ArtifactsRepository>((ref) {
  return ArtifactsRepository(apiClient: ref.watch(apiClientProvider));
});

final conceptsRepositoryProvider = Provider<ConceptsRepository>((ref) {
  return ConceptsRepository(apiClient: ref.watch(apiClientProvider));
});

final ocrRepositoryProvider = Provider<OcrRepository>((ref) {
  return OcrRepository(apiClient: ref.watch(apiClientProvider));
});
