/// AI Persona types for hints, questions, OCR
enum PersonaId { basis, petrovich, legendre }

extension PersonaIdExtension on PersonaId {
  String get name {
    switch (this) {
      case PersonaId.basis:
        return 'basis';
      case PersonaId.petrovich:
        return 'petrovich';
      case PersonaId.legendre:
        return 'legendre';
    }
  }

  String get displayName {
    switch (this) {
      case PersonaId.basis:
        return '🐱 Кот Базис';
      case PersonaId.petrovich:
        return '🧹 Петрович';
      case PersonaId.legendre:
        return '🧐 Лежандр';
    }
  }

  String get description {
    switch (this) {
      case PersonaId.basis:
        return 'Бесплатно, может лениться';
      case PersonaId.petrovich:
        return '2 ₽, быстро, Gemini Flash';
      case PersonaId.legendre:
        return '10 ₽, точно, Gemini Pro';
    }
  }

  double get cost {
    switch (this) {
      case PersonaId.basis:
        return 0;
      case PersonaId.petrovich:
        return 2;
      case PersonaId.legendre:
        return 10;
    }
  }

  static PersonaId fromString(String value) {
    switch (value.toLowerCase()) {
      case 'basis':
        return PersonaId.basis;
      case 'petrovich':
        return PersonaId.petrovich;
      case 'legendre':
        return PersonaId.legendre;
      default:
        return PersonaId.basis;
    }
  }
}

/// Epiphany (озарение) model
class EpiphanyModel {
  final int? id;
  final int? solutionId;
  final String? description;
  final int? magnitude;
  final DateTime? createdAt;

  EpiphanyModel({
    this.id,
    this.solutionId,
    this.description,
    this.magnitude,
    this.createdAt,
  });

  factory EpiphanyModel.fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    if (json['created_at'] != null) {
      try {
        createdAt = DateTime.parse(json['created_at'] as String);
      } catch (_) {}
    }

    return EpiphanyModel(
      id: json['id'] as int?,
      solutionId: json['solution_id'] as int?,
      description: json['description'] as String?,
      magnitude: json['magnitude'] as int?,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'solution_id': solutionId,
        'description': description,
        'magnitude': magnitude,
        'created_at': createdAt?.toIso8601String(),
      };
}

/// Epiphany create request
class EpiphanyCreate {
  final int solutionId;
  final String description;
  final int magnitude;

  EpiphanyCreate({
    required this.solutionId,
    required this.description,
    this.magnitude = 1,
  });

  Map<String, dynamic> toJson() => {
        'solution_id': solutionId,
        'description': description,
        'magnitude': magnitude,
      };
}

/// Question model
class QuestionModel {
  final int? id;
  final int? solutionId;
  final String? body;
  final String? answer;
  final bool? isAnswered;
  final DateTime? createdAt;

  QuestionModel({
    this.id,
    this.solutionId,
    this.body,
    this.answer,
    this.isAnswered,
    this.createdAt,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    if (json['created_at'] != null) {
      try {
        createdAt = DateTime.parse(json['created_at'] as String);
      } catch (_) {}
    }

    return QuestionModel(
      id: json['id'] as int?,
      solutionId: json['solution_id'] as int?,
      body: json['body'] as String?,
      answer: json['answer'] as String?,
      isAnswered: json['is_answered'] as bool?,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'solution_id': solutionId,
        'body': body,
        'answer': answer,
        'is_answered': isAnswered,
        'created_at': createdAt?.toIso8601String(),
      };

  bool get hasAnswer => answer != null && answer!.isNotEmpty;
}

/// Question create request
class QuestionCreate {
  final int solutionId;
  final String body;

  QuestionCreate({
    required this.solutionId,
    required this.body,
  });

  Map<String, dynamic> toJson() => {
        'solution_id': solutionId,
        'body': body,
      };
}

/// Question update request
class QuestionUpdate {
  final String? answer;

  QuestionUpdate({this.answer});

  Map<String, dynamic> toJson() => {'answer': answer};
}

/// Hint model
class HintModel {
  final int? id;
  final int? solutionId;
  final String? userNotes;
  final String? hintText;
  final String? status;
  final String? aiModel;
  final DateTime? createdAt;

  HintModel({
    this.id,
    this.solutionId,
    this.userNotes,
    this.hintText,
    this.status,
    this.aiModel,
    this.createdAt,
  });

  factory HintModel.fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    if (json['created_at'] != null) {
      try {
        createdAt = DateTime.parse(json['created_at'] as String);
      } catch (_) {}
    }

    return HintModel(
      id: json['id'] as int?,
      solutionId: json['solution_id'] as int?,
      userNotes: json['user_notes'] as String?,
      hintText: json['hint_text'] as String?,
      status: json['status'] as String?,
      aiModel: json['ai_model'] as String?,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'solution_id': solutionId,
        'user_notes': userNotes,
        'hint_text': hintText,
        'status': status,
        'ai_model': aiModel,
        'created_at': createdAt?.toIso8601String(),
      };

  bool get hasHint => hintText != null && hintText!.isNotEmpty;
  bool get isCompleted => status == 'completed';
}

/// Hint create draft request
class HintCreateDraft {
  final int solutionId;
  final String? userNotes;

  HintCreateDraft({
    required this.solutionId,
    this.userNotes,
  });

  Map<String, dynamic> toJson() => {
        'solution_id': solutionId,
        'user_notes': userNotes,
      };
}

/// Hint update request
class HintUpdate {
  final String? hintText;

  HintUpdate({this.hintText});

  Map<String, dynamic> toJson() => {'hint_text': hintText};
}

/// OCR result model
class OcrResult {
  final String? text;
  final bool success;
  final String? error;

  OcrResult({
    this.text,
    this.success = false,
    this.error,
  });

  factory OcrResult.fromJson(Map<String, dynamic> json) {
    return OcrResult(
      text: json['text'] as String?,
      success: true,
    );
  }

  factory OcrResult.error(String message) {
    return OcrResult(success: false, error: message);
  }
}

/// Upload result model
class UploadResult {
  final bool success;
  final String? path;
  final String? error;

  UploadResult({
    this.success = false,
    this.path,
    this.error,
  });

  factory UploadResult.success([String? path]) {
    return UploadResult(success: true, path: path);
  }

  factory UploadResult.error(String message) {
    return UploadResult(success: false, error: message);
  }
}
