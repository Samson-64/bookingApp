class ApiConstants {
  static const String defaultBaseUrl = 'http://127.0.0.1:8000';

  static String get baseUrl => const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultBaseUrl,
  );
}
