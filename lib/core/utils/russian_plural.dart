/// Russian plural forms utility
/// 
/// Russian language has 3 plural forms:
/// - Form 1: 1, 21, 31, 41... (numbers ending in 1, except 11)
/// - Form 2: 2-4, 22-24, 32-34... (numbers ending in 2-4, except 12-14)
/// - Form 3: 0, 5-20, 25-30, 35-40... (all others)
class RussianPlural {
  /// Select the correct plural form based on number
  /// 
  /// Usage:
  /// ```dart
  /// plural(1, 'день', 'дня', 'дней') // 'день'
  /// plural(2, 'день', 'дня', 'дней') // 'дня'
  /// plural(5, 'день', 'дня', 'дней') // 'дней'
  /// plural(21, 'день', 'дня', 'дней') // 'день'
  /// ```
  static String plural(int n, String form1, String form2, String form3) {
    final absN = n.abs();
    final lastTwo = absN % 100;
    final lastOne = absN % 10;

    // 11-14 use form 3
    if (lastTwo >= 11 && lastTwo <= 14) {
      return form3;
    }

    // 1 uses form 1
    if (lastOne == 1) {
      return form1;
    }

    // 2-4 use form 2
    if (lastOne >= 2 && lastOne <= 4) {
      return form2;
    }

    // All others use form 3
    return form3;
  }

  /// Format number with proper plural form
  /// 
  /// Usage:
  /// ```dart
  /// formatWithPlural(1, 'день', 'дня', 'дней') // '1 день'
  /// formatWithPlural(2, 'день', 'дня', 'дней') // '2 дня'
  /// formatWithPlural(5, 'день', 'дня', 'дней') // '5 дней'
  /// ```
  static String formatWithPlural(int n, String form1, String form2, String form3) {
    return '$n ${plural(n, form1, form2, form3)}';
  }

  // Common word forms for convenience

  /// День/дня/дней
  static String days(int n) => plural(n, 'день', 'дня', 'дней');
  
  /// Format: "1 день", "2 дня", "5 дней"
  static String formatDays(int n) => formatWithPlural(n, 'день', 'дня', 'дней');

  /// Неделя/недели/недель
  static String weeks(int n) => plural(n, 'неделя', 'недели', 'недель');
  static String formatWeeks(int n) => formatWithPlural(n, 'неделя', 'недели', 'недель');

  /// Час/часа/часов
  static String hours(int n) => plural(n, 'час', 'часа', 'часов');
  static String formatHours(int n) => formatWithPlural(n, 'час', 'часа', 'часов');

  /// Минута/минуты/минут
  static String minutes(int n) => plural(n, 'минута', 'минуты', 'минут');
  static String formatMinutes(int n) => formatWithPlural(n, 'минута', 'минуты', 'минут');

  /// Задача/задачи/задач
  static String tasks(int n) => plural(n, 'задача', 'задачи', 'задач');
  static String formatTasks(int n) => formatWithPlural(n, 'задача', 'задачи', 'задач');

  /// Решение/решения/решений
  static String solutions(int n) => plural(n, 'решение', 'решения', 'решений');
  static String formatSolutions(int n) => formatWithPlural(n, 'решение', 'решения', 'решений');

  /// Раз/раза/раз
  static String times(int n) => plural(n, 'раз', 'раза', 'раз');
  static String formatTimes(int n) => formatWithPlural(n, 'раз', 'раза', 'раз');

  /// Навык/навыка/навыков
  static String skills(int n) => plural(n, 'навык', 'навыка', 'навыков');
  static String formatSkills(int n) => formatWithPlural(n, 'навык', 'навыка', 'навыков');

  /// Концепт/концепта/концептов
  static String concepts(int n) => plural(n, 'концепт', 'концепта', 'концептов');
  static String formatConcepts(int n) => formatWithPlural(n, 'концепт', 'концепта', 'концептов');

  /// Балл/балла/баллов
  static String points(int n) => plural(n, 'балл', 'балла', 'баллов');
  static String formatPoints(int n) => formatWithPlural(n, 'балл', 'балла', 'баллов');

  /// Месяц/месяца/месяцев
  static String months(int n) => plural(n, 'месяц', 'месяца', 'месяцев');
  static String formatMonths(int n) => formatWithPlural(n, 'месяц', 'месяца', 'месяцев');
}
