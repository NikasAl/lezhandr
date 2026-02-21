import 'package:dio/dio.dart';
import '../models/artifacts.dart';
import '../services/api_client.dart';

/// Concept model for knowledge analysis
class ConceptModel {
  final int? id;
  final String? name;
  final String? slug;
  final String? description;
  final String? utilityDescription;

  ConceptModel({
    this.id,
    this.name,
    this.slug,
    this.description,
    this.utilityDescription,
  });

  factory ConceptModel.fromJson(Map<String, dynamic> json) {
    return ConceptModel(
      id: json['id'] as int?,
      name: json['name'] as String?,
      slug: json['slug'] as String?,
      description: json['description'] as String?,
      utilityDescription: json['utility_description'] as String?,
    );
  }
}

/// Problem concept (knowledge map)
class ProblemConceptModel {
  final int? problemId;
  final int? conceptId;
  final double? relevance;
  final String? explanation;
  final ConceptModel? concept;

  ProblemConceptModel({
    this.problemId,
    this.conceptId,
    this.relevance,
    this.explanation,
    this.concept,
  });

  factory ProblemConceptModel.fromJson(Map<String, dynamic> json) {
    ConceptModel? concept;
    if (json['concept'] != null) {
      concept = ConceptModel.fromJson(json['concept'] as Map<String, dynamic>);
    }

    return ProblemConceptModel(
      problemId: json['problem_id'] as int?,
      conceptId: json['concept_id'] as int?,
      relevance: (json['relevance'] as num?)?.toDouble(),
      explanation: json['explanation'] as String?,
      concept: concept,
    );
  }
}

/// Solution concept (skill trace)
class SolutionConceptModel {
  final int? solutionId;
  final int? conceptId;
  final String? usageContext;
  final ConceptModel? concept;

  SolutionConceptModel({
    this.solutionId,
    this.conceptId,
    this.usageContext,
    this.concept,
  });

  factory SolutionConceptModel.fromJson(Map<String, dynamic> json) {
    ConceptModel? concept;
    if (json['concept'] != null) {
      concept = ConceptModel.fromJson(json['concept'] as Map<String, dynamic>);
    }

    return SolutionConceptModel(
      solutionId: json['solution_id'] as int?,
      conceptId: json['concept_id'] as int?,
      usageContext: json['usage_context'] as String?,
      concept: concept,
    );
  }
}

/// Repository for concept analysis
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
  Future<List<ProblemConceptModel>> analyzeProblem({
    required int problemId,
    PersonaId persona = PersonaId.legendre,
  }) async {
    try {
      final response = await _apiClient.dio.post(
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
    } catch (_) {}
    return [];
  }

  /// Analyze solution concepts (Skill Trace)
  Future<List<SolutionConceptModel>> analyzeSolution({
    required int solutionId,
    PersonaId persona = PersonaId.legendre,
  }) async {
    try {
      final response = await _apiClient.dio.post(
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
    } catch (_) {}
    return [];
  }
}
