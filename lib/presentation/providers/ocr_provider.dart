import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/artifacts.dart';
import '../../data/repositories/uploads_repository.dart';
import '../../data/repositories/concepts_repository.dart';
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

/// OCR state
class OcrState {
  final bool isLoading;
  final String? text;
  final String? error;
  final PersonaId? lastPersona;

  OcrState({
    this.isLoading = false,
    this.text,
    this.error,
    this.lastPersona,
  });

  OcrState copyWith({
    bool? isLoading,
    String? text,
    String? error,
    PersonaId? lastPersona,
  }) {
    return OcrState(
      isLoading: isLoading ?? this.isLoading,
      text: text ?? this.text,
      error: error ?? this.error,
      lastPersona: lastPersona ?? this.lastPersona,
    );
  }
}

/// OCR notifier
final ocrNotifierProvider =
    StateNotifierProvider<OcrNotifier, OcrState>((ref) {
  return OcrNotifier(ref.watch(ocrRepositoryProvider));
});

class OcrNotifier extends StateNotifier<OcrState> {
  final OcrRepository _repo;

  OcrNotifier(this._repo) : super(OcrState());

  Future<OcrResult> processProblem({
    required int problemId,
    PersonaId persona = PersonaId.petrovich,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repo.processProblemImage(
        problemId: problemId,
        persona: persona,
      );
      state = state.copyWith(
        isLoading: false,
        text: result.text,
        error: result.error,
        lastPersona: persona,
      );
      return result;
    } catch (e) {
      final result = OcrResult.error(e.toString());
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
      return result;
    }
  }

  Future<OcrResult> processSolution({
    required int solutionId,
    PersonaId persona = PersonaId.petrovich,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repo.processSolutionImage(
        solutionId: solutionId,
        persona: persona,
      );
      state = state.copyWith(
        isLoading: false,
        text: result.text,
        error: result.error,
        lastPersona: persona,
      );
      return result;
    } catch (e) {
      final result = OcrResult.error(e.toString());
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
      return result;
    }
  }

  void clear() {
    state = OcrState();
  }
}

// ============ CONCEPTS ============

/// Problem concepts (Knowledge Map)
final problemConceptsProvider =
    FutureProvider.family<List<ProblemConceptModel>, int>((ref, problemId) {
  final repo = ref.watch(conceptsRepositoryProvider);
  return repo.analyzeProblem(problemId: problemId);
});

/// Solution concepts (Skill Trace)
final solutionConceptsProvider =
    FutureProvider.family<List<SolutionConceptModel>, int>((ref, solutionId) {
  final repo = ref.watch(conceptsRepositoryProvider);
  return repo.analyzeSolution(solutionId: solutionId);
});

/// Concepts analysis notifier
final conceptsNotifierProvider =
    StateNotifierProvider<ConceptsNotifier, AsyncValue<void>>((ref) {
  return ConceptsNotifier(ref.watch(conceptsRepositoryProvider));
});

class ConceptsNotifier extends StateNotifier<AsyncValue<void>> {
  final ConceptsRepository _repo;

  ConceptsNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<List<ProblemConceptModel>> analyzeProblem({
    required int problemId,
    PersonaId persona = PersonaId.legendre,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.analyzeProblem(
        problemId: problemId,
        persona: persona,
      );
      state = const AsyncValue.data(null);
      return result;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return [];
    }
  }

  Future<List<SolutionConceptModel>> analyzeSolution({
    required int solutionId,
    PersonaId persona = PersonaId.legendre,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.analyzeSolution(
        solutionId: solutionId,
        persona: persona,
      );
      state = const AsyncValue.data(null);
      return result;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return [];
    }
  }
}
