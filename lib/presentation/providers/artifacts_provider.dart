import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/artifacts.dart';
import '../../data/repositories/artifacts_repository.dart';
import 'providers.dart';

// ============ EPIPHANIES ============

/// Epiphanies for a solution
final epiphaniesProvider =
    FutureProvider.family<List<EpiphanyModel>, int>((ref, solutionId) async {
  final repo = ref.watch(artifactsRepositoryProvider);
  return await repo.getEpiphanies(solutionId);
});

/// Epiphanies notifier for CRUD operations
final epiphanyNotifierProvider =
    StateNotifierProvider<EpiphanyNotifier, AsyncValue<void>>((ref) {
  return EpiphanyNotifier(ref.watch(artifactsRepositoryProvider));
});

class EpiphanyNotifier extends StateNotifier<AsyncValue<void>> {
  final ArtifactsRepository _repo;

  EpiphanyNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<EpiphanyModel?> create({
    required int solutionId,
    required String description,
    int magnitude = 1,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.createEpiphany(
        EpiphanyCreate(
          solutionId: solutionId,
          description: description,
          magnitude: magnitude,
        ),
      );
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

// ============ QUESTIONS ============

/// Questions for a solution
final questionsProvider =
    FutureProvider.family<List<QuestionModel>, int>((ref, solutionId) async {
  final repo = ref.watch(artifactsRepositoryProvider);
  return await repo.getQuestions(solutionId);
});

/// Single question
final questionProvider =
    FutureProvider.family<QuestionModel?, int>((ref, questionId) async {
  final repo = ref.watch(artifactsRepositoryProvider);
  return await repo.getQuestion(questionId);
});

/// Questions notifier for CRUD operations
final questionNotifierProvider =
    StateNotifierProvider<QuestionNotifier, AsyncValue<void>>((ref) {
  return QuestionNotifier(ref.watch(artifactsRepositoryProvider));
});

class QuestionNotifier extends StateNotifier<AsyncValue<void>> {
  final ArtifactsRepository _repo;

  QuestionNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<QuestionModel?> create({
    required int solutionId,
    required String body,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.createQuestion(
        QuestionCreate(solutionId: solutionId, body: body),
      );
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> answer(int questionId, String answer) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.updateQuestion(
        questionId,
        QuestionUpdate(answer: answer),
      );
      state = const AsyncValue.data(null);
      return result != null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<QuestionModel?> generateAnswer({
    required int questionId,
    PersonaId persona = PersonaId.basis,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.generateQuestionAnswer(
        questionId: questionId,
        persona: persona,
      );
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> delete(int questionId) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.deleteQuestion(questionId);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

// ============ HINTS ============

/// Hints for a solution
final hintsProvider =
    FutureProvider.family<List<HintModel>, int>((ref, solutionId) async {
  final repo = ref.watch(artifactsRepositoryProvider);
  return await repo.getHints(solutionId);
});

/// Hints notifier for CRUD operations
final hintNotifierProvider =
    StateNotifierProvider<HintNotifier, AsyncValue<void>>((ref) {
  return HintNotifier(ref.watch(artifactsRepositoryProvider));
});

class HintNotifier extends StateNotifier<AsyncValue<void>> {
  final ArtifactsRepository _repo;

  HintNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<HintModel?> createDraft({
    required int solutionId,
    String? userNotes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.createHintDraft(
        HintCreateDraft(solutionId: solutionId, userNotes: userNotes),
      );
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<HintModel?> generate({
    required int hintId,
    PersonaId persona = PersonaId.basis,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.generateHint(
        hintId: hintId,
        persona: persona,
      );
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> updateText(int hintId, String hintText) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.updateHint(
        hintId,
        HintUpdate(hintText: hintText),
      );
      state = const AsyncValue.data(null);
      return result != null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
