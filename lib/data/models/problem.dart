import 'package:json_annotation/json_annotation.dart';

class SourceModel {
  final int id;
  final String name;
  final String slug;
  final String? urlTemplate;

  SourceModel({
    required this.id,
    required this.name,
    required this.slug,
    this.urlTemplate,
  });

  factory SourceModel.fromJson(Map<String, dynamic> json) {
    return SourceModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown',
      slug: json['slug'] as String? ?? '',
      urlTemplate: json['url_template'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'url_template': urlTemplate,
      };
}

class TagModel {
  final int id;
  final String name;
  final String slug;

  TagModel({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
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
      };

  bool get hasText => conditionText != null && conditionText!.isNotEmpty;

  bool get hasImage => conditionImg != null && conditionImg!.isNotEmpty;

  String get displayTitle => source != null 
      ? '${source!.name} - $reference' 
      : reference;
  
  String get sourceName => source?.name ?? 'Unknown';
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
