import 'user.dart';

class SourceModel {
  final int? id;
  final String name;
  final String slug;
  final String? urlTemplate;
  final int? problemCount;
  final int? addedBy;
  final String moderationStatus;

  SourceModel({
    this.id,
    required this.name,
    required this.slug,
    this.urlTemplate,
    this.problemCount,
    this.addedBy,
    this.moderationStatus = 'approved',
  });

  factory SourceModel.fromJson(Map<String, dynamic> json) {
    return SourceModel(
      id: json['id'] as int?,
      name: json['name'] as String? ?? 'Unknown',
      slug: json['slug'] as String? ?? '',
      urlTemplate: json['url_template'] as String?,
      problemCount: json['problem_count'] as int?,
      addedBy: json['added_by'] as int?,
      moderationStatus: json['moderation_status'] as String? ?? 'approved',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'url_template': urlTemplate,
        'problem_count': problemCount,
        'added_by': addedBy,
        'moderation_status': moderationStatus,
      };

  /// Check if source is pending moderation
  bool get isPending => moderationStatus == 'pending';
  
  /// Check if source is approved
  bool get isApproved => moderationStatus == 'approved';
  
  /// Check if source is rejected
  bool get isRejected => moderationStatus == 'rejected';
}

/// Source update request (owner can edit pending sources)
class SourceUpdate {
  final String? name;
  final String? urlTemplate;

  SourceUpdate({
    this.name,
    this.urlTemplate,
  });

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (urlTemplate != null) 'url_template': urlTemplate,
      };
}

/// Response wrapper for paginated sources list
class SourceListResponse {
  final List<SourceModel> items;
  final int total;
  final int limit;
  final int offset;

  SourceListResponse({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory SourceListResponse.fromJson(Map<String, dynamic> json) {
    return SourceListResponse(
      items: (json['items'] as List?)
          ?.map((s) => SourceModel.fromJson(s as Map<String, dynamic>))
          .toList() ?? [],
      total: json['total'] as int? ?? 0,
      limit: json['limit'] as int? ?? 20,
      offset: json['offset'] as int? ?? 0,
    );
  }

  /// Check if there are more items to load
  bool get hasMore => offset + items.length < total;
  
  /// Current page number (1-based)
  int get currentPage => (offset / limit).floor() + 1;
  
  /// Total pages count
  int get totalPages => (total / limit).ceil();
}

/// Filter for sources query
class SourcesFilter {
  final String? search;
  final int limit;
  final int offset;
  final String sortBy; // 'name' or 'problem_count'
  final bool withCounts;

  const SourcesFilter({
    this.search,
    this.limit = 20,
    this.offset = 0,
    this.sortBy = 'problem_count',
    this.withCounts = true,
  });

  SourcesFilter copyWith({
    String? search,
    int? limit,
    int? offset,
    String? sortBy,
    bool? withCounts,
  }) {
    return SourcesFilter(
      search: search ?? this.search,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      sortBy: sortBy ?? this.sortBy,
      withCounts: withCounts ?? this.withCounts,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SourcesFilter &&
          runtimeType == other.runtimeType &&
          search == other.search &&
          limit == other.limit &&
          offset == other.offset &&
          sortBy == other.sortBy &&
          withCounts == other.withCounts;

  @override
  int get hashCode =>
      search.hashCode ^ limit.hashCode ^ offset.hashCode ^ sortBy.hashCode ^ withCounts.hashCode;
}

class TagModel {
  final int id;
  final String name;
  final String slug;
  final int? addedBy;
  final String moderationStatus;

  TagModel({
    required this.id,
    required this.name,
    required this.slug,
    this.addedBy,
    this.moderationStatus = 'approved',
  });

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      addedBy: json['added_by'] as int?,
      moderationStatus: json['moderation_status'] as String? ?? 'approved',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'added_by': addedBy,
        'moderation_status': moderationStatus,
      };

  /// Check if tag is pending moderation
  bool get isPending => moderationStatus == 'pending';
  
  /// Check if tag is approved
  bool get isApproved => moderationStatus == 'approved';
  
  /// Check if tag is rejected
  bool get isRejected => moderationStatus == 'rejected';
}

/// Tag update request (owner can edit pending tags)
class TagUpdate {
  final String? name;

  TagUpdate({this.name});

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
      };
}

class ProblemModel {
  final int id;
  final int? sourceId;
  final String reference;
  final String? conditionText;
  final String? conditionImg;
  final DateTime? createdAt;
  final SourceModel? source;
  final List<TagModel> tags;
  final List<ProblemConceptModel>? concepts;
  final UserPublicProfile? addedBy;

  ProblemModel({
    required this.id,
    this.sourceId,
    required this.reference,
    this.conditionText,
    this.conditionImg,
    this.createdAt,
    this.source,
    this.tags = const [],
    this.concepts,
    this.addedBy,
  });

  factory ProblemModel.fromJson(Map<String, dynamic> json) {
    SourceModel? source;
    if (json['source'] != null && json['source'] is Map<String, dynamic>) {
      source = SourceModel.fromJson(json['source'] as Map<String, dynamic>);
    }

    List<TagModel> tags = [];
    if (json['tags'] != null && json['tags'] is List) {
      tags = (json['tags'] as List)
          .map((t) => TagModel.fromJson(t as Map<String, dynamic>))
          .toList();
    }

    List<ProblemConceptModel>? concepts;
    if (json['concepts'] != null && json['concepts'] is List) {
      concepts = (json['concepts'] as List)
          .map((c) => ProblemConceptModel.fromJson(c as Map<String, dynamic>))
          .toList();
    }

    UserPublicProfile? addedBy;
    if (json['added_by'] != null && json['added_by'] is Map<String, dynamic>) {
      addedBy = UserPublicProfile.fromJson(json['added_by'] as Map<String, dynamic>);
    }

    DateTime? createdAt;
    if (json['created_at'] != null) {
      try {
        createdAt = DateTime.parse(json['created_at'] as String);
      } catch (_) {}
    }

    return ProblemModel(
      id: json['id'] as int? ?? 0,
      sourceId: json['source_id'] as int?,
      reference: json['reference'] as String? ?? '',
      conditionText: json['condition_text'] as String?,
      conditionImg: json['condition_img'] as String?,
      createdAt: createdAt,
      source: source,
      tags: tags,
      concepts: concepts,
      addedBy: addedBy,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'source_id': sourceId,
        'reference': reference,
        'condition_text': conditionText,
        'condition_img': conditionImg,
        'created_at': createdAt?.toIso8601String(),
        'source': source?.toJson(),
        'tags': tags.map((t) => t.toJson()).toList(),
        'added_by': addedBy?.toJson(),
      };

  bool get hasText => conditionText != null && conditionText!.isNotEmpty;

  bool get hasImage => conditionImg != null && conditionImg!.isNotEmpty;

  String get displayTitle => source != null 
      ? '${source!.name} - $reference' 
      : reference;
  
  String get sourceName => source?.name ?? 'Unknown';
}

/// Response wrapper for paginated problems list
class ProblemListResponse {
  final List<ProblemModel> items;
  final int total;
  final int limit;
  final int offset;

  ProblemListResponse({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory ProblemListResponse.fromJson(Map<String, dynamic> json) {
    return ProblemListResponse(
      items: (json['items'] as List?)
          ?.map((p) => ProblemModel.fromJson(p as Map<String, dynamic>))
          .toList() ?? [],
      total: json['total'] as int? ?? 0,
      limit: json['limit'] as int? ?? 20,
      offset: json['offset'] as int? ?? 0,
    );
  }

  /// Check if there are more items to load
  bool get hasMore => offset + items.length < total;
  
  /// Current page number (1-based)
  int get currentPage => (offset / limit).floor() + 1;
  
  /// Total pages count
  int get totalPages => (total / limit).ceil();
}

class ProblemCreate {
  final String reference;
  final String sourceName;
  final List<String> tags;
  final String? conditionText;

  ProblemCreate({
    required this.reference,
    required this.sourceName,
    required this.tags,
    this.conditionText,
  });

  Map<String, dynamic> toJson() => {
        'reference': reference,
        'source_name': sourceName,
        'tags': tags,
        'condition_text': conditionText,
      };
}

class ProblemUpdate {
  final String? conditionText;
  final String? reference;
  final List<String>? tags;

  ProblemUpdate({
    this.conditionText,
    this.reference,
    this.tags,
  });

  Map<String, dynamic> toJson() => {
        'condition_text': conditionText,
        'reference': reference,
        'tags': tags,
      };
}

class ProblemConceptModel {
  final int? problemId;
  final int? conceptId;
  final double relevance;
  final String? explanation;
  final ConceptModel? concept;

  ProblemConceptModel({
    this.problemId,
    this.conceptId,
    required this.relevance,
    this.explanation,
    this.concept,
  });

  factory ProblemConceptModel.fromJson(Map<String, dynamic> json) {
    ConceptModel? concept;
    if (json['concept'] != null && json['concept'] is Map<String, dynamic>) {
      concept = ConceptModel.fromJson(json['concept'] as Map<String, dynamic>);
    }
    
    return ProblemConceptModel(
      problemId: json['problem_id'] as int?,
      conceptId: json['concept_id'] as int?,
      relevance: (json['relevance'] as num?)?.toDouble() ?? 0.0,
      explanation: json['explanation'] as String?,
      concept: concept,
    );
  }

  Map<String, dynamic> toJson() => {
        'problem_id': problemId,
        'concept_id': conceptId,
        'relevance': relevance,
        'explanation': explanation,
        'concept': concept?.toJson(),
      };
}

class ConceptModel {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? utilityDescription;
  final DateTime? createdAt;

  ConceptModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.utilityDescription,
    this.createdAt,
  });

  factory ConceptModel.fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    if (json['created_at'] != null) {
      try {
        createdAt = DateTime.parse(json['created_at'] as String);
      } catch (_) {}
    }
    
    return ConceptModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      utilityDescription: json['utility_description'] as String?,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'description': description,
        'utility_description': utilityDescription,
        'created_at': createdAt?.toIso8601String(),
      };
}
