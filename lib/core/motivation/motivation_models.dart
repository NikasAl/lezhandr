/// Motivation text category
enum MotivationCategory {
  thinking, // Про развитие мышления
  practical, // Про практическую пользу
  satisfaction, // Про удовлетворение от решения
  career, // Про будущее и карьеру
  perseverance, // Про преодоление трудностей
  energetic, // Короткие и энергичные
  quotes, // Цитаты великих людей
  session, // Во время сессии
  streak, // Про стрик
  achievements, // При достижениях
}

/// Motivation text model
class MotivationText {
  final String id;
  final String text;
  final String? author;
  final List<String> tags;
  final MotivationCategory category;
  final String? trigger; // When to show
  final String? condition; // Show condition (e.g., streak_7)

  // Runtime fields
  final DateTime? lastShownAt;
  final int shownCount;

  const MotivationText({
    required this.id,
    required this.text,
    this.author,
    required this.tags,
    required this.category,
    this.trigger,
    this.condition,
    this.lastShownAt,
    this.shownCount = 0,
  });

  MotivationText copyWith({
    DateTime? lastShownAt,
    int? shownCount,
  }) {
    return MotivationText(
      id: id,
      text: text,
      author: author,
      tags: tags,
      category: category,
      trigger: trigger,
      condition: condition,
      lastShownAt: lastShownAt ?? this.lastShownAt,
      shownCount: shownCount ?? this.shownCount,
    );
  }
}

/// Time of day for contextual motivation
enum TimeOfDay { morning, afternoon, evening, night }

/// Session state for contextual motivation
enum SessionState {
  idle,
  starting,
  inProgress,
  stuck, // Long time on one task
  hintUsed,
  finishing,
}

/// Context for motivation selection
class MotivationContext {
  final TimeOfDay timeOfDay;
  final SessionState sessionState;
  final int streakDays;
  final int tasksCompletedToday;
  final int totalTasksCompleted;
  final double totalXp;
  final int sessionDurationMinutes;
  final bool streakAtRisk;
  final bool justBrokeStreak;
  final bool isNewUser;
  final int daysSinceLastActivity;

  // Special conditions
  final bool firstEpiphany;
  final int sourcesUsed;
  final bool milestoneReached;
  final String? milestoneType; // 'tasks_100', 'xp_1000', etc.

  const MotivationContext({
    required this.timeOfDay,
    required this.sessionState,
    this.streakDays = 0,
    this.tasksCompletedToday = 0,
    this.totalTasksCompleted = 0,
    this.totalXp = 0,
    this.sessionDurationMinutes = 0,
    this.streakAtRisk = false,
    this.justBrokeStreak = false,
    this.isNewUser = false,
    this.daysSinceLastActivity = 0,
    this.firstEpiphany = false,
    this.sourcesUsed = 0,
    this.milestoneReached = false,
    this.milestoneType,
  });

  factory MotivationContext.current({
    required SessionState sessionState,
    required int streakDays,
    required int tasksCompletedToday,
    required int totalTasksCompleted,
    required double totalXp,
    int sessionDurationMinutes = 0,
    bool streakAtRisk = false,
    bool justBrokeStreak = false,
    bool isNewUser = false,
    int daysSinceLastActivity = 0,
    bool firstEpiphany = false,
    int sourcesUsed = 0,
    bool milestoneReached = false,
    String? milestoneType,
  }) {
    final hour = DateTime.now().hour;
    TimeOfDay timeOfDay;

    if (hour >= 6 && hour < 12) {
      timeOfDay = TimeOfDay.morning;
    } else if (hour >= 12 && hour < 18) {
      timeOfDay = TimeOfDay.afternoon;
    } else if (hour >= 18 && hour < 24) {
      timeOfDay = TimeOfDay.evening;
    } else {
      timeOfDay = TimeOfDay.night;
    }

    return MotivationContext(
      timeOfDay: timeOfDay,
      sessionState: sessionState,
      streakDays: streakDays,
      tasksCompletedToday: tasksCompletedToday,
      totalTasksCompleted: totalTasksCompleted,
      totalXp: totalXp,
      sessionDurationMinutes: sessionDurationMinutes,
      streakAtRisk: streakAtRisk,
      justBrokeStreak: justBrokeStreak,
      isNewUser: isNewUser,
      daysSinceLastActivity: daysSinceLastActivity,
      firstEpiphany: firstEpiphany,
      sourcesUsed: sourcesUsed,
      milestoneReached: milestoneReached,
      milestoneType: milestoneType,
    );
  }
}
