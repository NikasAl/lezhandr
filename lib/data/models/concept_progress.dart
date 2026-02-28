/// Concept model
class ConceptModel {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? utilityDescription;
  final bool isPublic;
  final int? aliasOfId;
  final DateTime createdAt;

  const ConceptModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.utilityDescription,
    this.isPublic = true,
    this.aliasOfId,
    required this.createdAt,
  });

  factory ConceptModel.fromJson(Map<String, dynamic> json) {
    return ConceptModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      utilityDescription: json['utility_description'] as String?,
      isPublic: json['is_public'] as bool? ?? true,
      aliasOfId: json['alias_of_id'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'description': description,
        'utility_description': utilityDescription,
        'is_public': isPublic,
        'alias_of_id': aliasOfId,
        'created_at': createdAt.toIso8601String(),
      };
}

/// Mastery tier enum
enum MasteryTier {
  unknown(0, 'Не знаком', '⚪'),
  familiar(1, 'Знаком', '🔵'),
  practitioner(2, 'Практик', '🟢'),
  experienced(3, 'Опытный', '🟡'),
  master(4, 'Мастер', '🟣');

  final int value;
  final String nameRu;
  final String emoji;

  const MasteryTier(this.value, this.nameRu, this.emoji);

  static MasteryTier fromValue(int value) {
    return MasteryTier.values.firstWhere(
      (t) => t.value == value,
      orElse: () => MasteryTier.unknown,
    );
  }

  static MasteryTier fromLevel(double level) {
    if (level >= 0.9) return MasteryTier.master;
    if (level >= 0.7) return MasteryTier.experienced;
    if (level >= 0.45) return MasteryTier.practitioner;
    if (level >= 0.15) return MasteryTier.familiar;
    return MasteryTier.unknown;
  }
}

/// User's progress on a concept
class ConceptProgressModel {
  final ConceptModel concept;
  final double masteryLevel;
  final int masteryTier;
  final String masteryTierName;
  final String masteryEmoji;
  final int exposedCount; // How many times seen in problems
  final int demonstratedCount; // How many times used in solutions
  final DateTime? lastPracticed;

  const ConceptProgressModel({
    required this.concept,
    required this.masteryLevel,
    required this.masteryTier,
    required this.masteryTierName,
    required this.masteryEmoji,
    required this.exposedCount,
    required this.demonstratedCount,
    this.lastPracticed,
  });

  factory ConceptProgressModel.fromJson(Map<String, dynamic> json) {
    return ConceptProgressModel(
      concept: ConceptModel.fromJson(json['concept'] as Map<String, dynamic>),
      masteryLevel: (json['mastery_level'] as num?)?.toDouble() ?? 0.0,
      masteryTier: json['mastery_tier'] as int? ?? 0,
      masteryTierName: json['mastery_tier_name'] as String? ?? 'Не знаком',
      masteryEmoji: json['mastery_emoji'] as String? ?? '⚪',
      exposedCount: json['exposed_count'] as int? ?? 0,
      demonstratedCount: json['demonstrated_count'] as int? ?? 0,
      lastPracticed: json['last_practiced'] != null
          ? DateTime.parse(json['last_practiced'] as String)
          : null,
    );
  }

  /// Get tier enum from numeric tier value
  MasteryTier get tier => MasteryTier.fromValue(masteryTier);

  /// Get progress percentage for progress bar (0-100)
  double get progressPercent {
    return (masteryLevel * 100).clamp(0.0, 100.0);
  }
}

/// Response for concept progress list with pagination
class ConceptProgressListResponse {
  final List<ConceptProgressModel> items;
  final int total;
  final int limit;
  final int offset;

  const ConceptProgressListResponse({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory ConceptProgressListResponse.fromJson(Map<String, dynamic> json) {
    return ConceptProgressListResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => ConceptProgressModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] as int? ?? 0,
      limit: json['limit'] as int? ?? 20,
      offset: json['offset'] as int? ?? 0,
    );
  }

  bool get hasMore => offset + items.length < total;
}

/// Statistics for user's concept mastery
class ConceptStatsModel {
  final int totalConcepts;
  final Map<int, int> byTier; // tier value -> count

  const ConceptStatsModel({
    required this.totalConcepts,
    required this.byTier,
  });

  factory ConceptStatsModel.fromJson(Map<String, dynamic> json) {
    final byTierRaw = json['by_tier'] as Map<String, dynamic>? ?? {};
    final byTier = <int, int>{};
    byTierRaw.forEach((key, value) {
      byTier[int.tryParse(key) ?? 0] = value as int? ?? 0;
    });
    return ConceptStatsModel(
      totalConcepts: json['total_concepts'] as int? ?? 0,
      byTier: byTier,
    );
  }

  /// Get count for a specific tier
  int getCountForTier(MasteryTier tier) => byTier[tier.value] ?? 0;

  /// Get max count across all tiers for scaling bars
  int get maxCount {
    if (byTier.isEmpty) return 1;
    return byTier.values.reduce((a, b) => a > b ? a : b);
  }
}

/// Problem or solution reference for a concept
class ConceptProblemRef {
  final int id;
  final String reference;
  final String sourceName;
  final double relevance;
  final String? context; // For solutions - usage context

  const ConceptProblemRef({
    required this.id,
    required this.reference,
    required this.sourceName,
    required this.relevance,
    this.context,
  });

  factory ConceptProblemRef.fromJson(Map<String, dynamic> json) {
    return ConceptProblemRef(
      id: json['id'] as int? ?? 0,
      reference: json['reference'] as String? ?? '',
      sourceName: json['source_name'] as String? ?? '',
      relevance: (json['relevance'] as num?)?.toDouble() ?? 0.0,
      context: json['context'] as String?,
    );
  }
}

/// Available problem reference - problems where concept exists but user hasn't solved yet
class AvailableProblemRef {
  final int id;
  final String reference;
  final String sourceName;
  final double? relevance;
  final bool hasConditionText;

  const AvailableProblemRef({
    required this.id,
    required this.reference,
    required this.sourceName,
    this.relevance,
    this.hasConditionText = false,
  });

  factory AvailableProblemRef.fromJson(Map<String, dynamic> json) {
    return AvailableProblemRef(
      id: json['id'] as int? ?? 0,
      reference: json['reference'] as String? ?? '',
      sourceName: json['source_name'] as String? ?? '',
      relevance: (json['relevance'] as num?)?.toDouble(),
      hasConditionText: json['has_condition_text'] as bool? ?? false,
    );
  }
}

/// Full details about a concept including related problems and solutions
class ConceptDetailModel {
  final ConceptModel concept;
  final List<ConceptProblemRef> exposedIn; // Problems where concept appears
  final List<ConceptProblemRef> demonstratedIn; // Solutions where concept was used
  final List<AvailableProblemRef> availableIn; // Problems where concept exists but user hasn't solved

  const ConceptDetailModel({
    required this.concept,
    required this.exposedIn,
    required this.demonstratedIn,
    this.availableIn = const [],
  });

  factory ConceptDetailModel.fromJson(Map<String, dynamic> json) {
    return ConceptDetailModel(
      concept: ConceptModel.fromJson(json['concept'] as Map<String, dynamic>),
      exposedIn: (json['exposed_in'] as List<dynamic>?)
              ?.map((e) => ConceptProblemRef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      demonstratedIn: (json['demonstrated_in'] as List<dynamic>?)
              ?.map((e) => ConceptProblemRef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      availableIn: (json['available_in'] as List<dynamic>?)
              ?.map((e) => AvailableProblemRef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
