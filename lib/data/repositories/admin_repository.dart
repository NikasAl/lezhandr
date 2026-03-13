import 'package:dio/dio.dart';
import '../services/api_client.dart';

/// Tag model for moderation
class AdminTag {
  final int id;
  final String name;
  final String moderationStatus;
  final AdminUserInfo? addedBy;

  AdminTag({
    required this.id,
    required this.name,
    required this.moderationStatus,
    this.addedBy,
  });

  factory AdminTag.fromJson(Map<String, dynamic> json) {
    return AdminTag(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      moderationStatus: json['moderation_status'] as String? ?? 'pending',
      addedBy: json['added_by'] != null
          ? AdminUserInfo.fromJson(json['added_by'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Source model for moderation
class AdminSource {
  final int id;
  final String name;
  final String? slug;
  final String moderationStatus;
  final AdminUserInfo? addedBy;

  AdminSource({
    required this.id,
    required this.name,
    this.slug,
    required this.moderationStatus,
    this.addedBy,
  });

  factory AdminSource.fromJson(Map<String, dynamic> json) {
    return AdminSource(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String?,
      moderationStatus: json['moderation_status'] as String? ?? 'pending',
      addedBy: json['added_by'] != null
          ? AdminUserInfo.fromJson(json['added_by'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Problem model for moderation
class AdminProblem {
  final int id;
  final String? reference;
  final String? conditionText;
  final bool hasImage;
  final String moderationStatus;
  final AdminSourceInfo? source;
  final AdminUserInfo? addedBy;

  AdminProblem({
    required this.id,
    this.reference,
    this.conditionText,
    this.hasImage = false,
    required this.moderationStatus,
    this.source,
    this.addedBy,
  });

  factory AdminProblem.fromJson(Map<String, dynamic> json) {
    return AdminProblem(
      id: json['id'] as int? ?? 0,
      reference: json['reference'] as String?,
      conditionText: json['condition_text'] as String?,
      hasImage: json['condition_img'] != null,
      moderationStatus: json['moderation_status'] as String? ?? 'pending',
      source: json['source'] != null
          ? AdminSourceInfo.fromJson(json['source'] as Map<String, dynamic>)
          : null,
      addedBy: json['added_by'] != null
          ? AdminUserInfo.fromJson(json['added_by'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Solution model for moderation
class AdminSolution {
  final int id;
  final String status;
  final String? solutionText;
  final bool hasImage;
  final String moderationStatus;
  final AdminProblemInfo? problem;
  final AdminUserInfo? addedBy;

  AdminSolution({
    required this.id,
    required this.status,
    this.solutionText,
    this.hasImage = false,
    required this.moderationStatus,
    this.problem,
    this.addedBy,
  });

  factory AdminSolution.fromJson(Map<String, dynamic> json) {
    return AdminSolution(
      id: json['id'] as int? ?? 0,
      status: json['status'] as String? ?? 'pending',
      solutionText: json['solution_text'] as String?,
      hasImage: json['solution_img_path'] != null,
      moderationStatus: json['moderation_status'] as String? ?? 'pending',
      problem: json['problem'] != null
          ? AdminProblemInfo.fromJson(json['problem'] as Map<String, dynamic>)
          : null,
      addedBy: json['added_by'] != null
          ? AdminUserInfo.fromJson(json['added_by'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Concept model with aliases
class AdminConcept {
  final int id;
  final String name;
  final String? description;
  final int? aliasOfId;
  final List<AdminConceptAlias> aliases;

  AdminConcept({
    required this.id,
    required this.name,
    this.description,
    this.aliasOfId,
    this.aliases = const [],
  });

  bool get isCanonical => aliasOfId == null;

  factory AdminConcept.fromJson(Map<String, dynamic> json) {
    return AdminConcept(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? json['utility_description'] as String?,
      aliasOfId: json['alias_of_id'] as int?,
      aliases: json['aliases'] != null
          ? (json['aliases'] as List)
              .map((a) => AdminConceptAlias.fromJson(a as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

class AdminConceptAlias {
  final int id;
  final String name;

  AdminConceptAlias({required this.id, required this.name});

  factory AdminConceptAlias.fromJson(Map<String, dynamic> json) {
    return AdminConceptAlias(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }
}

/// Deduplication candidate
class DedupCandidate {
  final int id;
  final int canonicalConceptId;
  final AdminConceptInfo canonicalConcept;
  final List<DedupAlias> proposedAliases;
  final double confidence;
  final String classification;
  final String? reason;
  final String? canonicalNameCorrection;
  final int canonicalUsageCount;
  final int aliasesUsageCount;
  final String status;

  DedupCandidate({
    required this.id,
    required this.canonicalConceptId,
    required this.canonicalConcept,
    this.proposedAliases = const [],
    required this.confidence,
    required this.classification,
    this.reason,
    this.canonicalNameCorrection,
    this.canonicalUsageCount = 0,
    this.aliasesUsageCount = 0,
    this.status = 'pending',
  });

  factory DedupCandidate.fromJson(Map<String, dynamic> json) {
    return DedupCandidate(
      id: json['id'] as int? ?? 0,
      canonicalConceptId: json['canonical_concept_id'] as int? ?? 0,
      canonicalConcept: AdminConceptInfo.fromJson(
          json['canonical_concept'] as Map<String, dynamic>? ?? {}),
      proposedAliases: json['proposed_aliases'] != null
          ? (json['proposed_aliases'] as List)
              .map((a) => DedupAlias.fromJson(a as Map<String, dynamic>))
              .toList()
          : [],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      classification: json['classification'] as String? ?? '',
      reason: json['reason'] as String?,
      canonicalNameCorrection: json['canonical_name_correction'] as String?,
      canonicalUsageCount: json['canonical_usage_count'] as int? ?? 0,
      aliasesUsageCount: json['aliases_usage_count'] as int? ?? 0,
      status: json['status'] as String? ?? 'pending',
    );
  }
}

class DedupAlias {
  final int id;
  final String name;
  final int usageCount;

  DedupAlias({required this.id, required this.name, this.usageCount = 0});

  factory DedupAlias.fromJson(Map<String, dynamic> json) {
    return DedupAlias(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      usageCount: json['usage_count'] as int? ?? 0,
    );
  }
}

/// Helper classes
class AdminUserInfo {
  final int id;
  final String? username;

  AdminUserInfo({required this.id, this.username});

  factory AdminUserInfo.fromJson(Map<String, dynamic> json) {
    return AdminUserInfo(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String?,
    );
  }

  String get displayName => username != null ? '@$username' : '#$id';
}

class AdminSourceInfo {
  final int id;
  final String name;

  AdminSourceInfo({required this.id, required this.name});

  factory AdminSourceInfo.fromJson(Map<String, dynamic> json) {
    return AdminSourceInfo(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }
}

class AdminProblemInfo {
  final int id;
  final String? reference;
  final AdminSourceInfo? source;

  AdminProblemInfo({required this.id, this.reference, this.source});

  factory AdminProblemInfo.fromJson(Map<String, dynamic> json) {
    return AdminProblemInfo(
      id: json['id'] as int? ?? 0,
      reference: json['reference'] as String?,
      source: json['source'] != null
          ? AdminSourceInfo.fromJson(json['source'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AdminConceptInfo {
  final int id;
  final String name;

  AdminConceptInfo({required this.id, required this.name});

  factory AdminConceptInfo.fromJson(Map<String, dynamic> json) {
    return AdminConceptInfo(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }
}

/// Deduplication run result
class DedupResult {
  final int totalActiveConcepts;
  final int totalMergedAliases;
  final int candidatesCreated;
  final int autoApproved;
  final int pendingReview;
  final bool canContinue;

  DedupResult({
    this.totalActiveConcepts = 0,
    this.totalMergedAliases = 0,
    this.candidatesCreated = 0,
    this.autoApproved = 0,
    this.pendingReview = 0,
    this.canContinue = false,
  });

  factory DedupResult.fromJson(Map<String, dynamic> json) {
    return DedupResult(
      totalActiveConcepts: json['total_active_concepts'] as int? ?? 0,
      totalMergedAliases: json['total_merged_aliases'] as int? ?? 0,
      candidatesCreated: json['candidates_created'] as int? ?? 0,
      autoApproved: json['auto_approved'] as int? ?? 0,
      pendingReview: json['pending_review'] as int? ?? 0,
      canContinue: json['can_continue'] as bool? ?? false,
    );
  }
}

/// Repository for admin operations
class AdminRepository {
  final ApiClient _apiClient;

  AdminRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  // ============ TAGS ============

  Future<List<AdminTag>> getTags({
    String moderationStatus = 'pending',
    int limit = 50,
    int offset = 0,
    String? search,
  }) async {
    try {
      final params = {
        'moderation_status': moderationStatus,
        'limit': limit,
        'offset': offset,
        if (search != null) 'search': search,
      };
      final response = await _apiClient.dio.get('/tags', queryParameters: params);
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((t) => AdminTag.fromJson(t as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<AdminTag?> approveTag(int tagId) async {
    try {
      final response = await _apiClient.dio.post('/tags/$tagId/approve');
      if (response.statusCode == 200) {
        return AdminTag.fromJson(response.data);
      }
    } catch (_) {}
    return null;
  }

  Future<AdminTag?> rejectTag(int tagId) async {
    try {
      final response = await _apiClient.dio.post('/tags/$tagId/reject');
      if (response.statusCode == 200) {
        return AdminTag.fromJson(response.data);
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> mergeTags(int targetTagId, List<int> sourceTagIds) async {
    try {
      final response = await _apiClient.dio.post(
        '/tags/merge',
        data: {
          'target_tag_id': targetTagId,
          'source_tag_ids': sourceTagIds,
        },
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // ============ SOURCES ============

  Future<List<AdminSource>> getSources({
    String moderationStatus = 'pending',
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.dio.get('/sources', queryParameters: {
        'moderation_status': moderationStatus,
        'limit': limit,
        'offset': offset,
      });
      if (response.statusCode == 200) {
        final data = response.data;
        final items = data is Map ? data['items'] as List? : data as List?;
        if (items != null) {
          return items
              .map((s) => AdminSource.fromJson(s as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  Future<AdminSource?> approveSource(int sourceId) async {
    try {
      final response = await _apiClient.dio.post('/sources/$sourceId/approve');
      if (response.statusCode == 200) {
        return AdminSource.fromJson(response.data);
      }
    } catch (_) {}
    return null;
  }

  Future<AdminSource?> rejectSource(int sourceId) async {
    try {
      final response = await _apiClient.dio.post('/sources/$sourceId/reject');
      if (response.statusCode == 200) {
        return AdminSource.fromJson(response.data);
      }
    } catch (_) {}
    return null;
  }

  // ============ PROBLEMS ============

  Future<Map<String, dynamic>> getProblems({
    String moderationStatus = 'pending',
    int limit = 50,
    int offset = 0,
    int? userId,
  }) async {
    try {
      final params = {
        'moderation_status': moderationStatus,
        'limit': limit,
        'offset': offset,
        if (userId != null) 'user_id': userId,
      };
      final response = await _apiClient.dio.get('/problems', queryParameters: params);
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = (data['items'] as List?)
            ?.map((p) => AdminProblem.fromJson(p as Map<String, dynamic>))
            .toList() ?? [];
        return {'items': items, 'total': data['total'] ?? items.length};
      }
    } catch (_) {}
    return {'items': <AdminProblem>[], 'total': 0};
  }

  Future<AdminProblem?> approveProblem(int problemId) async {
    try {
      final response = await _apiClient.dio.post('/problems/$problemId/approve');
      if (response.statusCode == 200) {
        return AdminProblem.fromJson(response.data);
      }
    } catch (_) {}
    return null;
  }

  Future<AdminProblem?> rejectProblem(int problemId) async {
    try {
      final response = await _apiClient.dio.post('/problems/$problemId/reject');
      if (response.statusCode == 200) {
        return AdminProblem.fromJson(response.data);
      }
    } catch (_) {}
    return null;
  }

  // ============ SOLUTIONS ============

  Future<Map<String, dynamic>> getSolutions({
    String moderationStatus = 'pending',
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.dio.get('/solutions', queryParameters: {
        'moderation_status': moderationStatus,
        'limit': limit,
        'offset': offset,
      });
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = (data['items'] as List?)
            ?.map((s) => AdminSolution.fromJson(s as Map<String, dynamic>))
            .toList() ?? [];
        return {'items': items, 'total': data['total'] ?? items.length};
      }
    } catch (_) {}
    return {'items': <AdminSolution>[], 'total': 0};
  }

  Future<AdminSolution?> approveSolution(int solutionId) async {
    try {
      final response = await _apiClient.dio.post('/solutions/$solutionId/approve');
      if (response.statusCode == 200) {
        return AdminSolution.fromJson(response.data);
      }
    } catch (_) {}
    return null;
  }

  Future<AdminSolution?> rejectSolution(int solutionId) async {
    try {
      final response = await _apiClient.dio.post('/solutions/$solutionId/reject');
      if (response.statusCode == 200) {
        return AdminSolution.fromJson(response.data);
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> deleteSolution(int solutionId) async {
    try {
      final response = await _apiClient.dio.delete('/solutions/$solutionId');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // ============ CONCEPTS ============

  Future<List<AdminConcept>> getConcepts({
    int limit = 200,
    int skip = 0,
    bool withAliases = true,
  }) async {
    try {
      final response = await _apiClient.dio.get('/concepts', queryParameters: {
        'limit': limit,
        'skip': skip,
        'with_aliases': withAliases,
      });
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((c) => AdminConcept.fromJson(c as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>?> getConceptProblems(int conceptId) async {
    try {
      final response = await _apiClient.dio.get('/concepts/$conceptId/problems');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // ============ DEDUPLICATION ============

  Future<DedupResult?> runDeduplication(String persona) async {
    try {
      final response = await _apiClient.dio.post(
        '/concepts/deduplicate',
        queryParameters: {'persona': persona},
      );
      if (response.statusCode == 200) {
        return DedupResult.fromJson(response.data);
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> getDedupCandidates({
    String status = 'pending',
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/concepts/dedup/candidates',
        queryParameters: {
          'status': status,
          'limit': limit,
          'offset': offset,
        },
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = (data['items'] as List?)
            ?.map((c) => DedupCandidate.fromJson(c as Map<String, dynamic>))
            .toList() ?? [];
        return {
          'items': items,
          'total': data['total'] ?? items.length,
          'pending_count': data['pending_count'] ?? 0,
        };
      }
    } catch (_) {}
    return {'items': <DedupCandidate>[], 'total': 0, 'pending_count': 0};
  }

  Future<Map<String, dynamic>?> approveDedupCandidate(
    int candidateId, {
    String? newCanonicalName,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/concepts/dedup/candidates/$candidateId/approve',
        data: newCanonicalName != null ? {'new_canonical_name': newCanonicalName} : null,
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> rejectDedupCandidate(int candidateId, {String? reason}) async {
    try {
      final response = await _apiClient.dio.post(
        '/concepts/dedup/candidates/$candidateId/reject',
        data: reason != null ? {'reason': reason} : null,
      );
      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }

  Future<Map<String, dynamic>?> applyAutoApproved() async {
    try {
      final response = await _apiClient.dio.post(
        '/concepts/dedup/candidates/apply-auto-approved',
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<int> fixCycles() async {
    try {
      final response = await _apiClient.dio.post('/concepts/fix-cycles');
      if (response.statusCode == 200) {
        return (response.data as Map<String, dynamic>)['cycles_broken'] as int? ?? 0;
      }
    } catch (_) {}
    return 0;
  }
}
