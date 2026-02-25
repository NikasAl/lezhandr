import 'package:dio/dio.dart';
import '../models/problem.dart' show ProblemConceptModel;
import '../models/artifacts.dart';
import '../services/api_client.dart';

/// Solution concept (skill trace)
class SolutionConceptModel {
  final int? solutionId;
  final int? conceptId;
  final String? usageContext;
  final ConceptModelForSolution? concept;

  SolutionConceptModel({
    this.solutionId,
    this.conceptId,
    this.usageContext,
    this.concept,
  });

  factory SolutionConceptModel.fromJson(Map<String, dynamic> json) {
    ConceptModelForSolution? concept;
    if (json['concept'] != null) {
      concept = ConceptModelForSolution.fromJson(json['concept'] as Map<String, dynamic>);
    }

    return SolutionConceptModel(
      solutionId: json['solution_id'] as int?,
      conceptId: json['concept_id'] as int?,
      usageContext: json['usage_context'] as String?,
      concept: concept,
    );
  }
}

/// Concept model for solution (simplified version for solution concepts)
class ConceptModelForSolution {
  final int? id;
  final String? name;
  final String? slug;
  final String? description;
  final String? utilityDescription;

  ConceptModelForSolution({
    this.id,
    this.name,
    this.slug,
    this.description,
    this.utilityDescription,
  });

  factory ConceptModelForSolution.fromJson(Map<String, dynamic> json) {
    return ConceptModelForSolution(
      id: json['id'] as int?,
      name: json['name'] as String?,
      slug: json['slug'] as String?,
      description: json['description'] as String?,
      utilityDescription: json['utility_description'] as String?,
    );
  }
}

/// Repository for concept analysis (uses long polling for AI requests)
class ConceptsRepository {
  final ApiClient _apiClient;

  ConceptsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get existing concepts for a solution
  Future<List<SolutionConceptModel>> getSolutionConcepts(int solutionId) async {
    try {
      final response = await _apiClient.dio.get(
        '/concepts/by-solution/$solutionId',
      );
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((c) =>
                SolutionConceptModel.fromJson(c as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Analyze problem concepts (Knowledge Map)
  /// Uses extended timeout for AI processing
  Future<List<ProblemConceptModel>> analyzeProblem({
    required int problemId,
    PersonaId persona = PersonaId.legendre,
  }) async {
    try {
      // Use longPollDio for extended timeout (5 minutes)
      final response = await _apiClient.longPollDio.post(
        '/concepts/analyze/problem/$problemId',
        queryParameters: {'persona': persona.name},
      );
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((c) =>
                ProblemConceptModel.fromJson(c as Map<String, dynamic>))
            .toList();
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 402) {
        rethrow;
      }
      // Log but don't crash on timeout
      print('⚠️ Concept analysis timeout or error: ${e.message}');
    } catch (e) {
      print('⚠️ Concept analysis error: $e');
    }
    return [];
  }

  /// Analyze solution concepts (Skill Trace)
  /// Uses extended timeout for AI processing
  Future<List<SolutionConceptModel>> analyzeSolution({
    required int solutionId,
    PersonaId persona = PersonaId.legendre,
  }) async {
    try {
      // Use longPollDio for extended timeout (5 minutes)
      final response = await _apiClient.longPollDio.post(
        '/concepts/analyze/solution/$solutionId',
        queryParameters: {'persona': persona.name},
      );
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((c) =>
                SolutionConceptModel.fromJson(c as Map<String, dynamic>))
            .toList();
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 402) {
        rethrow;
      }
      print('⚠️ Solution analysis timeout or error: ${e.message}');
    } catch (e) {
      print('⚠️ Solution analysis error: $e');
    }
    return [];
  }
}
