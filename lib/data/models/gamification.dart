class GamificationModel {
  final int? userId;
  final double totalXp;
  final int currentLevel;
  final int currentHearts;
  final int maxHearts;
  final int streakCurrent;
  final int streakBest;
  final int solvedTasksToday;
  final DateTime? lastActivityDate;
  
  // Поля уровня (вычисляются сервером из total_xp)
  final int level;
  final double levelProgress;  // Прогресс до следующего уровня (0.0-1.0)
  final double xpCurrent;      // XP на текущем уровне
  final double xpToNext;       // XP до следующего уровня

  GamificationModel({
    this.userId,
    this.totalXp = 0,
    this.currentLevel = 1,
    this.currentHearts = 5,
    this.maxHearts = 5,
    this.streakCurrent = 0,
    this.streakBest = 0,
    this.solvedTasksToday = 0,
    this.lastActivityDate,
    this.level = 1,
    this.levelProgress = 0.0,
    this.xpCurrent = 0.0,
    this.xpToNext = 100.0,
  });

  factory GamificationModel.fromJson(Map<String, dynamic> json) {
    DateTime? lastActivityDate;
    if (json['last_activity_date'] != null) {
      try {
        lastActivityDate = DateTime.parse(json['last_activity_date'] as String);
      } catch (_) {}
    }
    
    return GamificationModel(
      userId: json['user_id'] as int?,
      totalXp: (json['total_xp'] as num?)?.toDouble() ?? 0,
      currentLevel: json['current_level'] as int? ?? 1,
      currentHearts: json['current_hearts'] as int? ?? 5,
      maxHearts: json['max_hearts'] as int? ?? 5,
      streakCurrent: json['streak_current'] as int? ?? 0,
      streakBest: json['streak_best'] as int? ?? 0,
      solvedTasksToday: json['solved_tasks_today'] as int? ?? 0,
      lastActivityDate: lastActivityDate,
      // Новые поля уровня от сервера
      level: json['level'] as int? ?? json['current_level'] as int? ?? 1,
      levelProgress: (json['level_progress'] as num?)?.toDouble() ?? 0.0,
      xpCurrent: (json['xp_current'] as num?)?.toDouble() ?? 0.0,
      xpToNext: (json['xp_to_next'] as num?)?.toDouble() ?? 100.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'total_xp': totalXp,
        'current_level': currentLevel,
        'current_hearts': currentHearts,
        'max_hearts': maxHearts,
        'streak_current': streakCurrent,
        'streak_best': streakBest,
        'solved_tasks_today': solvedTasksToday,
        'last_activity_date': lastActivityDate?.toIso8601String(),
        'level': level,
        'level_progress': levelProgress,
        'xp_current': xpCurrent,
        'xp_to_next': xpToNext,
      };

  /// Прогресс до следующего уровня (использует данные сервера)
  double get xpProgress => levelProgress;

  double get heartsProgress => maxHearts > 0 ? currentHearts / maxHearts : 1.0;

  bool get streakAtRisk => streakCurrent > 0 && solvedTasksToday == 0;
  
  /// Форматированный XP для отображения
  String get xpDisplay => '${totalXp.toStringAsFixed(0)} XP';
  
  /// Прогресс бар уровня в процентах
  int get levelProgressPercent => (levelProgress * 100).round();
}

class DailyActivityModel {
  final String date;
  final double xp;
  final double timeMinutes;
  final int tasksCount;

  DailyActivityModel({
    this.date = '',
    this.xp = 0,
    this.timeMinutes = 0,
    this.tasksCount = 0,
  });

  factory DailyActivityModel.fromJson(Map<String, dynamic> json) {
    return DailyActivityModel(
      date: json['date'] as String? ?? '',
      xp: (json['xp'] as num?)?.toDouble() ?? 0,
      timeMinutes: (json['time_minutes'] as num?)?.toDouble() ?? 0,
      tasksCount: json['tasks_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'xp': xp,
        'time_minutes': timeMinutes,
        'tasks_count': tasksCount,
      };
}

class ActivityResponse {
  final List<DailyActivityModel> items;
  final double totalXp;
  final double totalTimeMinutes;
  final int totalTasks;

  ActivityResponse({
    this.items = const [],
    this.totalXp = 0,
    this.totalTimeMinutes = 0,
    this.totalTasks = 0,
  });

  factory ActivityResponse.fromJson(Map<String, dynamic> json) {
    List<DailyActivityModel> items = [];
    if (json['items'] != null && json['items'] is List) {
      items = (json['items'] as List)
          .map((i) => DailyActivityModel.fromJson(i as Map<String, dynamic>))
          .toList();
    }
    
    return ActivityResponse(
      items: items,
      totalXp: (json['total_xp'] as num?)?.toDouble() ?? 0,
      totalTimeMinutes: (json['total_time_minutes'] as num?)?.toDouble() ?? 0,
      totalTasks: json['total_tasks'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'items': items.map((i) => i.toJson()).toList(),
        'total_xp': totalXp,
        'total_time_minutes': totalTimeMinutes,
        'total_tasks': totalTasks,
      };
}
