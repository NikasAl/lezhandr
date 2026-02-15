import 'package:dio/dio.dart';
import '../models/artifacts.dart';
import '../services/api_client.dart';

/// Repository for session artifacts (epiphanies, questions, hints)
class ArtifactsRepository {
  final ApiClient _apiClient;

  ArtifactsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  // ============ EPIPHANIES ============

  /// Create epiphany
  Future<EpiphanyModel?> createEpiphany(EpiphanyCreate epiphany) async {
    try {
      final response = await _apiClient.dio.post(
        '/epiphanies',
        data: epiphany.toJson(),
      );
      if (response.statusCode == 201) {
        return EpiphanyModel.fromJson(response.data);
      }
    } catch (_) {}
    return null;
  }

  /// Get epiphanies for solution
  Future<List<EpiphanyModel>> getEpiphanies(int solutionId) async {
    try {
      final response = await _apiClient.dio
          .get('/epiphanies/by-solution/$solutionId');
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((e) => EpiphanyModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  // ============ QUESTIONS ============

  /// Create question
  Future<QuestionModel?> createQuestion(QuestionCreate question) async {
    try {
      final response = await _apiClient.dio.post(
        '/questions',
        data: question.toJson(),
      );
      if (response.statusCode == 201) {
        return QuestionModel.fromJson(response.data);
      }
    } catch (_) {}
    return null;
  }

  /// Get questions for solution
  Future<List<QuestionModel>> getQuestions(int solutionId) async {
    try {
      final response = await _apiClient.dio
          .get('/questions/by-solution/$solutionId');
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Get single question
  Future<QuestionModel?> getQuestion(int questionId) async {
    try {
      final response = await _apiClient.dio.get('/questions/$questionId');
      if (response.statusCode == 200) {
        return QuestionModel.fromJson(response.data);
      }
    } catch (_) {}
    return null;
  }

  /// Update question (add answer)
  Future<QuestionModel?> updateQuestion(
    int questionId,
    QuestionUpdate update,
  ) async {
    try {
      final response = await _apiClient.dio.patch(
        '/questions/$questionId',
        data: update.toJson(),
      );
      if (response.statusCode == 200) {
        return QuestionModel.fromJson(response.data);
      }
    } catch (_) {}
    return null;
  }

  /// Delete question
  Future<bool> deleteQuestion(int questionId) async {
    try {
      final response = await _apiClient.dio.delete('/questions/$questionId');
      return response.statusCode == 204;
    } catch (_) {}
    return false;
  }

  /// Generate AI answer for question
  Future<QuestionModel?> generateQuestionAnswer({
    required int questionId,
    PersonaId persona = PersonaId.basis,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/questions/$questionId/generate',
        queryParameters: {'persona': persona.name},
      );
      if (response.statusCode == 200) {
        return QuestionModel.fromJson(response.data);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 402) {
        // Payment required
        rethrow;
      }
    } catch (_) {}
    return null;
  }

  // ============ HINTS ============

  /// Create hint draft
  Future<HintModel?> createHintDraft(HintCreateDraft hint) async {
    try {
      final response = await _apiClient.dio.post(
        '/hints/draft',
        data: hint.toJson(),
      );
      if (response.statusCode == 201) {
        return HintModel.fromJson(response.data);
      }
    } catch (_) {}
    return null;
  }

  /// Get hints for solution
  Future<List<HintModel>> getHints(int solutionId) async {
    try {
      final response =
          await _apiClient.dio.get('/hints/by-solution/$solutionId');
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((h) => HintModel.fromJson(h as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Update hint text
  Future<HintModel?> updateHint(int hintId, HintUpdate update) async {
    try {
      final response = await _apiClient.dio.patch(
        '/hints/$hintId',
        data: update.toJson(),
      );
      if (response.statusCode == 200) {
        return HintModel.fromJson(response.data);
      }
    } catch (_) {}
    return null;
  }

  /// Generate AI hint
  Future<HintModel?> generateHint({
    required int hintId,
    PersonaId persona = PersonaId.basis,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/hints/$hintId/generate',
        queryParameters: {'persona': persona.name},
      );
      if (response.statusCode == 200) {
        return HintModel.fromJson(response.data);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 402) {
        rethrow;
      }
    } catch (_) {}
    return null;
  }
}
