import 'problem.dart';
import 'user.dart';

enum SolutionStatus { active, completed, abandoned }

class SolutionModel {
  final int id;
  final int? problemId;
  final int? userId;
  final SolutionStatus status;
  final int? personalDifficulty;
  final double? qualityScore;
  final double? xpEarned;
  final String? userNotes;
  final String? solutionImgPath;
  final String? solutionText;
  final double totalMinutes;
  final DateTime? createdAt;
  final ProblemModel? problem;
  final UserPublicProfile? addedBy;

  SolutionModel({
    required this.id,
    this.problemId,
    this.userId,
    required this.status,
    this.personalDifficulty,
    this.qualityScore,
    this.xpEarned,
    this.userNotes,
    this.solutionImgPath,
    this.solutionText,
    this.totalMinutes = 0,
    this.createdAt,
    this.problem,
    this.addedBy,
  });

  factory SolutionModel.fromJson(Map<String, dynamic> json) {
    SolutionStatus status = SolutionStatus.active;
    if (json['status'] != null) {
      final statusStr = json['status'] as String;
      switch (statusStr) {
        case 'completed':
          status = SolutionStatus.completed;
          break;
        case 'abandoned':
          status = SolutionStatus.abandoned;
          break;
        default:
          status = SolutionStatus.active;
      }
    }

    ProblemModel? problem;
    if (json['problem'] != null && json['problem'] is Map<String, dynamic>) {
      problem = ProblemModel.fromJson(json['problem'] as Map<String, dynamic>);
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

    return SolutionModel(
      id: json['id'] as int? ?? 0,
      problemId: json['problem_id'] as int?,
      userId: json['user_id'] as int?,
      status: status,
      personalDifficulty: json['personal_difficulty'] as int?,
      qualityScore: (json['quality_score'] as num?)?.toDouble(),
      xpEarned: (json['xp_earned'] as num?)?.toDouble(),
      userNotes: json['user_notes'] as String?,
      solutionImgPath: json['solution_img_path'] as String?,
      solutionText: json['solution_text'] as String?,
      totalMinutes: (json['total_minutes'] as num?)?.toDouble() ?? 0,
      createdAt: createdAt,
      problem: problem,
      addedBy: addedBy,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'problem_id': problemId,
        'user_id': userId,
        'status': status.name,
        'personal_difficulty': personalDifficulty,
        'quality_score': qualityScore,
        'xp_earned': xpEarned,
        'user_notes': userNotes,
        'solution_img_path': solutionImgPath,
        'solution_text': solutionText,
        'total_minutes': totalMinutes,
        'created_at': createdAt?.toIso8601String(),
        'added_by': addedBy?.toJson(),
      };

  bool get hasText => solutionText != null && solutionText!.isNotEmpty;

  bool get hasImage => solutionImgPath != null && solutionImgPath!.isNotEmpty;

  bool get isActive => status == SolutionStatus.active;

  bool get isCompleted => status == SolutionStatus.completed;

  String get statusText {
    switch (status) {
      case SolutionStatus.active:
        return 'В процессе';
      case SolutionStatus.completed:
        return 'Завершено';
      case SolutionStatus.abandoned:
        return 'Отложено';
    }
  }
}

/// Response wrapper for paginated solutions list
class SolutionListResponse {
  final List<SolutionModel> items;
  final int total;
  final int limit;
  final int offset;

  SolutionListResponse({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory SolutionListResponse.fromJson(Map<String, dynamic> json) {
    return SolutionListResponse(
      items: (json['items'] as List?)
          ?.map((s) => SolutionModel.fromJson(s as Map<String, dynamic>))
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

class SolutionCreate {
  final int problemId;

  SolutionCreate({required this.problemId});

  Map<String, dynamic> toJson() => {'problem_id': problemId};
}

class SolutionFinish {
  final String status;
  final int? personalDifficulty;
  final double? qualityScore;
  final String? userNotes;

  SolutionFinish({
    required this.status,
    this.personalDifficulty,
    this.qualityScore,
    this.userNotes,
  });

  Map<String, dynamic> toJson() => {
        'status': status,
        'personal_difficulty': personalDifficulty,
        'quality_score': qualityScore,
        'user_notes': userNotes,
      };
}

class SessionModel {
  final int? id;
  final int? solutionId;
  final DateTime? startTime;
  final DateTime? endTime;
  final double? durationMinutes;
  final String? notes;

  SessionModel({
    this.id,
    this.solutionId,
    this.startTime,
    this.endTime,
    this.durationMinutes,
    this.notes,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    DateTime? startTime;
    if (json['start_time'] != null) {
      try {
        startTime = DateTime.parse(json['start_time'] as String);
      } catch (_) {}
    }

    DateTime? endTime;
    if (json['end_time'] != null) {
      try {
        endTime = DateTime.parse(json['end_time'] as String);
      } catch (_) {}
    }

    return SessionModel(
      id: json['id'] as int?,
      solutionId: json['solution_id'] as int?,
      startTime: startTime,
      endTime: endTime,
      durationMinutes: (json['duration_minutes'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'solution_id': solutionId,
        'start_time': startTime?.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'duration_minutes': durationMinutes,
        'notes': notes,
      };
}

class SessionCreate {
  final int solutionId;
  final DateTime startTime;
  final DateTime endTime;
  final double duration;

  SessionCreate({
    required this.solutionId,
    required this.startTime,
    required this.endTime,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
        'solution_id': solutionId,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'duration': duration,
      };
}
