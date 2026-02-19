/// Application configuration constants
class AppConfig {
  AppConfig._();

  /// Demo mode - uses mock data instead of real API
  static const bool demoMode = bool.fromEnvironment(
    'DEMO_MODE',
    defaultValue: true, // Enable demo mode by default
  );

  /// Environment name (dev, stage)
  static const String _env = String.fromEnvironment('env', defaultValue: 'stage');

  /// API base URL - selected by environment
  /// Usage: flutter run --dart-define=env=dev
  static const String apiUrl = _env == 'dev'
      ? 'http://192.168.1.7:8001/mv/api/v1'
      : 'https://kreagenium.ru/mv/api/v1';

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
