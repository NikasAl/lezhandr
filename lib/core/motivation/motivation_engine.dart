import 'dart:math';
import 'motivation_models.dart';
import 'motivation_texts.dart';

/// Engine for selecting appropriate motivation texts
class MotivationEngine {
  final Random _random = Random();
  final Map<String, DateTime> _recentlyShown = {};

  // Minimum time between showing the same text (in hours)
  static const int _minRepeatHours = 24;

  // Maximum number of texts in recent history
  static const int _maxRecentHistory = 10;

  /// Get appropriate text for given context
  MotivationText? getTextForContext(MotivationContext context) {
    final candidates = <MotivationText>[];

    // 1. Check milestone achievements
    if (context.milestoneReached && context.milestoneType != null) {
      candidates.addAll(_getTextsByCondition(context.milestoneType!));
    }

    // 2. Check streak
    if (context.streakAtRisk) {
      candidates.addAll(_getTextsByTrigger('streak_risk'));
    }
    if (context.justBrokeStreak) {
      candidates.addAll(_getTextsByTrigger('streak_broken'));
    }
    if (context.streakDays >= 100) {
      candidates.addAll(_getTextsByCondition('streak_100'));
    } else if (context.streakDays >= 30) {
      candidates.addAll(_getTextsByCondition('streak_30'));
    } else if (context.streakDays >= 7) {
      candidates.addAll(_getTextsByCondition('streak_7'));
    }

    // 3. Check session state
    if (context.sessionState == SessionState.stuck) {
      candidates.addAll(_getTextsByTrigger('stuck_15min'));
    }
    if (context.sessionDurationMinutes >= 30) {
      candidates.addAll(_getTextsByTrigger('session_30min'));
    }
    if (context.sessionDurationMinutes >= 60) {
      candidates.addAll(_getTextsByTrigger('session_very_long'));
    }
    if (context.sessionState == SessionState.hintUsed) {
      candidates.addAll(_getTextsByTrigger('hint_requested'));
    }

    // 4. If no candidates, select by time of day
    if (candidates.isEmpty) {
      candidates.addAll(_getTextsForTimeOfDay(context.timeOfDay));
    }

    // Filter recently shown
    final available =
        candidates.where((t) => !_wasRecentlyShown(t.id)).toList();

    if (available.isEmpty) {
      // If all were recently shown, take one with lowest count
      candidates.sort((a, b) => a.shownCount.compareTo(b.shownCount));
      return candidates.isNotEmpty ? candidates.first : null;
    }

    // Select random from available
    return available[_random.nextInt(available.length)];
  }

  List<MotivationText> _getTextsByCondition(String condition) {
    return MotivationTexts.all
        .where((t) => t.condition == condition)
        .toList();
  }

  List<MotivationText> _getTextsByTrigger(String trigger) {
    return MotivationTexts.all.where((t) => t.trigger == trigger).toList();
  }

  List<MotivationText> _getTextsForTimeOfDay(TimeOfDay timeOfDay) {
    List<MotivationCategory> preferredCategories;

    switch (timeOfDay) {
      case TimeOfDay.morning:
        preferredCategories = [
          MotivationCategory.energetic,
          MotivationCategory.career,
          MotivationCategory.thinking,
        ];
        break;
      case TimeOfDay.afternoon:
        preferredCategories = [
          MotivationCategory.practical,
          MotivationCategory.perseverance,
          MotivationCategory.thinking,
        ];
        break;
      case TimeOfDay.evening:
        preferredCategories = [
          MotivationCategory.satisfaction,
          MotivationCategory.quotes,
          MotivationCategory.thinking,
        ];
        break;
      case TimeOfDay.night:
        preferredCategories = [
          MotivationCategory.session,
          MotivationCategory.quotes,
        ];
        break;
    }

    return MotivationTexts.all
        .where((t) => preferredCategories.contains(t.category))
        .toList();
  }

  bool _wasRecentlyShown(String id) {
    final lastShown = _recentlyShown[id];
    if (lastShown == null) return false;

    final hoursSinceShown = DateTime.now().difference(lastShown).inHours;
    return hoursSinceShown < _minRepeatHours;
  }

  void markAsShown(String id) {
    _recentlyShown[id] = DateTime.now();

    // Clean old records
    if (_recentlyShown.length > _maxRecentHistory) {
      final sortedKeys = _recentlyShown.keys.toList()
        ..sort((a, b) => _recentlyShown[a]!.compareTo(_recentlyShown[b]!));

      for (int i = 0; i < sortedKeys.length - _maxRecentHistory; i++) {
        _recentlyShown.remove(sortedKeys[i]);
      }
    }
  }

  // Special methods for specific situations

  MotivationText? getOnboardingText() {
    final texts = MotivationTexts.all
        .where((t) => t.category == MotivationCategory.thinking)
        .toList();
    return texts.isNotEmpty ? texts[_random.nextInt(texts.length)] : null;
  }

  MotivationText? getSessionStartText({bool isDifficult = false}) {
    if (isDifficult) {
      final texts = MotivationTexts.all
          .where((t) => t.category == MotivationCategory.perseverance)
          .toList();
      return texts.isNotEmpty ? texts[_random.nextInt(texts.length)] : null;
    }

    final texts = MotivationTexts.all
        .where((t) =>
            t.category == MotivationCategory.energetic ||
            t.category == MotivationCategory.thinking)
        .toList();
    return texts.isNotEmpty ? texts[_random.nextInt(texts.length)] : null;
  }

  MotivationText? getCompletionText({int difficulty = 3}) {
    late MotivationCategory category;

    if (difficulty >= 4) {
      category = MotivationCategory.satisfaction;
    } else {
      category = MotivationCategory.energetic;
    }

    final texts = MotivationTexts.all
        .where((t) => t.category == category)
        .toList();
    return texts.isNotEmpty ? texts[_random.nextInt(texts.length)] : null;
  }

  MotivationText? getStreakText(int days, {bool atRisk = false}) {
    if (atRisk) {
      return _getTextsByTrigger('streak_risk').firstOrNull;
    }

    if (days >= 100) {
      return _getTextsByCondition('streak_100').firstOrNull;
    } else if (days >= 30) {
      return _getTextsByCondition('streak_30').firstOrNull;
    } else if (days >= 7) {
      return _getTextsByCondition('streak_7').firstOrNull;
    }

    // General text for active streak
    final text = _getTextsByTrigger('streak_active').firstOrNull;
    if (text != null) {
      return MotivationText(
        id: text.id,
        text: text.text.replaceAll('{days}', days.toString()),
        author: text.author,
        tags: text.tags,
        category: text.category,
      );
    }

    return null;
  }
}
