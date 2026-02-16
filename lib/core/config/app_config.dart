/// Application configuration constants
class AppConfig {
  AppConfig._();

  /// Demo mode - uses mock data instead of real API
  static const bool demoMode = bool.fromEnvironment(
    'DEMO_MODE',
    defaultValue: true, // Enable demo mode by default
  );

  /// API base URL
  /// TODO: Replace with your actual API URL
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  /// API timeout in seconds
  static const int apiTimeoutSeconds = 30;

  /// App name
  static const String appName = 'Лежандр';

  /// App version
  static const String appVersion = '1.0.0';

  /// Default limits
  static const int defaultDailyFreeLimit = 5;
  static const int maxHearts = 5;

  /// Session settings
  static const int sessionIdleMinutes = 30;
  static const int sessionWarningMinutes = 45;

  /// Image settings
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1920;
  static const int imageQuality = 85;

  /// Motivation settings
  static const int motivationMinRepeatHours = 24;
  static const int motivationMaxHistory = 10;
}
