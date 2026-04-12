import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/artifacts.dart';
import '../../data/models/problem.dart' show ProblemConceptModel;
import '../../data/repositories/uploads_repository.dart';
import '../../data/repositories/concepts_repository.dart' show ConceptsRepository, SolutionConceptModel;
import '../../core/services/notification_service.dart';
import 'providers.dart';

// ============ IMAGE FETCHING ============

/// Image bytes provider with caching
/// Returns Uint8List? (image bytes) for a given category and entityId
final imageProvider = FutureProvider.family<Uint8List?, ({String category, int entityId})>((ref, params) async {
  final repo = ref.watch(uploadsRepositoryProvider);
  final (bytes, _) = await repo.fetchImageBytes(
    category: params.category,
    entityId: params.entityId,
  );
  return bytes;
});

/// Convenience provider for condition images
final conditionImageProvider = FutureProvider.family<Uint8List?, int>((ref, problemId) async {
  return await ref.watch(imageProvider((category: 'condition', entityId: problemId)).future);
});

/// Convenience provider for solution images
final solutionImageProvider = FutureProvider.family<Uint8List?, int>((ref, solutionId) async {
  return await ref.watch(imageProvider((category: 'solution', entityId: solutionId)).future);
});

// ============ UPLOADS ============

/// Upload notifier for image uploads
final uploadNotifierProvider =
    StateNotifierProvider<UploadNotifier, AsyncValue<UploadResult?>>((ref) {
  return UploadNotifier(ref.watch(uploadsRepositoryProvider));
});

class UploadNotifier extends StateNotifier<AsyncValue<UploadResult?>> {
  final UploadsRepository _repo;

  UploadNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<UploadResult> uploadImage({
    required String category,
    required int entityId,
    required String filePath,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.uploadImage(
        category: category,
        entityId: entityId,
        filePath: filePath,
      );
      state = AsyncValue.data(result);
      return result;
    } catch (e) {
      final result = UploadResult.error(e.toString());
      state = AsyncValue.data(result);
      return result;
    }
  }
}

// ============ OCR ============

/// OCR state with persona tracking for "thinking" UI
class OcrState {
  final bool isLoading;
  final String? text;
  final String? error;
  final PersonaId? currentPersona;

  OcrState({
    this.isLoading = false,
    this.text,
    this.error,
    this.currentPersona,
  });

  OcrState copyWith({
    bool? isLoading,
    String? text,
    String? error,
    PersonaId? currentPersona,
    bool clearError = false,
    bool clearText = false,
  }) {
    return OcrState(
      isLoading: isLoading ?? this.isLoading,
      text: clearText ? null : (text ?? this.text),
      error: clearError ? null : (error ?? this.error),
      currentPersona: currentPersona ?? this.currentPersona,
    );
  }
}

/// OCR notifier with extended timeout support and notifications
final ocrNotifierProvider =
    StateNotifierProvider<OcrNotifier, OcrState>((ref) {
  return OcrNotifier(
    ref.watch(ocrRepositoryProvider),
    ref,
  );
});

class OcrNotifier extends StateNotifier<OcrState> {
  final OcrRepository _repo;
  final Ref _ref;

  OcrNotifier(this._repo, this._ref) : super(OcrState());

  Future<OcrResult> processProblem({
    required int problemId,
    PersonaId persona = PersonaId.petrovich,
  }) async {
    state = state.copyWith(isLoading: true, currentPersona: persona, clearError: true, clearText: true);
    
    try {
      final result = await _repo.processProblemImage(
        problemId: problemId,
        persona: persona,
      );
      
      state = state.copyWith(
        isLoading: false,
        text: result.text,
        error: result.error,
      );
      
      // Refresh billing balance after AI request
      _ref.invalidate(billingBalanceProvider);
      
      // Show notification even if user navigated away
      if (result.success && result.text != null) {
        NotificationService.showAiResult(
          title: '${persona.displayName} завершил распознавание',
          details: 'Текст условия успешно извлечён',
          success: true,
        );
      } else if (result.error != null) {
        NotificationService.showAiResult(
          title: 'Ошибка распознавания',
          details: result.error!,
          success: false,
        );
      }
      
      return result;
    } catch (e) {
      final result = OcrResult.error(e.toString());
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
      
      // Refresh billing balance even on error (might have failed after billing)
      _ref.invalidate(billingBalanceProvider);
      
      NotificationService.showError('OCR: ${result.error}');
      return result;
    }
  }

  Future<OcrResult> processSolution({
    required int solutionId,
    PersonaId persona = PersonaId.petrovich,
  }) async {
    state = state.copyWith(isLoading: true, currentPersona: persona, clearError: true, clearText: true);
    
    try {
      final result = await _repo.processSolutionImage(
        solutionId: solutionId,
        persona: persona,
      );
      
      state = state.copyWith(
        isLoading: false,
        text: result.text,
        error: result.error,
      );
      
      // Refresh billing balance after AI request
      _ref.invalidate(billingBalanceProvider);
      
      // Show notification even if user navigated away
      if (result.success && result.text != null) {
        NotificationService.showAiResult(
          title: '${persona.displayName} завершил распознавание',
          details: 'Текст решения успешно извлечён',
          success: true,
        );
      } else if (result.error != null) {
        NotificationService.showAiResult(
          title: 'Ошибка распознавания',
          details: result.error!,
          success: false,
        );
      }
      
      return result;
    } catch (e) {
      final result = OcrResult.error(e.toString());
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
      
      // Refresh billing balance even on error
      _ref.invalidate(billingBalanceProvider);
      
      NotificationService.showError('OCR: ${result.error}');
      return result;
    }
  }

  void clear() {
    state = OcrState();
  }
}

// ============ CONCEPTS ============

/// Solution concepts (Skill Trace) - fetches existing concepts without analysis
final solutionConceptsProvider =
    FutureProvider.family<List<SolutionConceptModel>, int>((ref, solutionId) {
  final repo = ref.watch(conceptsRepositoryProvider);
  return repo.getSolutionConcepts(solutionId);
});

/// Concepts analysis state with persona tracking
class ConceptsAnalysisState {
  final bool isLoading;
  final PersonaId? currentPersona;
  final String? error;

  ConceptsAnalysisState({
    this.isLoading = false,
    this.currentPersona,
    this.error,
  });

  ConceptsAnalysisState copyWith({
    bool? isLoading,
    PersonaId? currentPersona,
    String? error,
    bool clearError = false,
  }) {
    return ConceptsAnalysisState(
      isLoading: isLoading ?? this.isLoading,
      currentPersona: currentPersona ?? this.currentPersona,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Concepts analysis notifier with notifications
final conceptsNotifierProvider =
    StateNotifierProvider<ConceptsNotifier, ConceptsAnalysisState>((ref) {
  return ConceptsNotifier(
    ref.watch(conceptsRepositoryProvider),
    ref,
  );
});

class ConceptsNotifier extends StateNotifier<ConceptsAnalysisState> {
  final ConceptsRepository _repo;
  final Ref _ref;

  ConceptsNotifier(this._repo, this._ref) : super(ConceptsAnalysisState());

  Future<List<ProblemConceptModel>> analyzeProblem({
    required int problemId,
    PersonaId persona = PersonaId.legendre,
  }) async {
    state = state.copyWith(isLoading: true, currentPersona: persona, clearError: true);
    
    try {
      final result = await _repo.analyzeProblem(
        problemId: problemId,
        persona: persona,
      );
      
      state = state.copyWith(isLoading: false);
      
      // Refresh billing balance after AI request
      _ref.invalidate(billingBalanceProvider);
      
      // Show notification even if user navigated away
      if (result.isNotEmpty) {
        NotificationService.showAiResult(
          title: '${persona.displayName} завершил анализ',
          details: 'Найдено ${result.length} концептов',
          success: true,
        );
      } else {
        NotificationService.showInfo(
          '${persona.displayName}: Концепты не найдены',
        );
      }
      
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      
      // Refresh billing balance even on error
      _ref.invalidate(billingBalanceProvider);
      
      String errorMsg = 'Ошибка анализа';
      if (e.toString().contains('402')) {
        errorMsg = 'Недостаточно средств на балансе';
      }
      
      NotificationService.showAiResult(
        title: 'Ошибка анализа концептов',
        details: errorMsg,
        success: false,
      );
      return [];
    }
  }

  Future<List<SolutionConceptModel>> analyzeSolution({
    required int solutionId,
    PersonaId persona = PersonaId.legendre,
  }) async {
    state = state.copyWith(isLoading: true, currentPersona: persona, clearError: true);
    
    try {
      final result = await _repo.analyzeSolution(
        solutionId: solutionId,
        persona: persona,
      );
      
      state = state.copyWith(isLoading: false);
      
      // Refresh billing balance after AI request
      _ref.invalidate(billingBalanceProvider);
      
      // Show notification even if user navigated away
      if (result.isNotEmpty) {
        NotificationService.showAiResult(
          title: '${persona.displayName} завершил анализ',
          details: 'Найдено ${result.length} навыков',
          success: true,
        );
      } else {
        NotificationService.showInfo(
          '${persona.displayName}: Навыки не найдены',
        );
      }
      
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      
      // Refresh billing balance even on error
      _ref.invalidate(billingBalanceProvider);
      
      String errorMsg = 'Ошибка анализа';
      if (e.toString().contains('402')) {
        errorMsg = 'Недостаточно средств на балансе';
      }
      
      NotificationService.showAiResult(
        title: 'Ошибка анализа навыков',
        details: errorMsg,
        success: false,
      );
      return [];
    }
  }
  
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
