import 'package:flutter/foundation.dart';

/// Runtime/config-safe API constants.
///
/// The production backend URL is NOT hardcoded here. It is injected at build
/// time via `--dart-define-from-file=config.json` (or
/// `--dart-define=API_BASE_URL=...`), keeping it out of source control.
///
/// Build commands:
///   flutter run --dart-define-from-file=config.json
///   flutter build apk --dart-define-from-file=config.json
class ApiConstants {
  static const String _envOverride = String.fromEnvironment('API_BASE_URL');

  /// Base URL used for all API requests.
  ///
  /// Resolution order:
  /// 1. `--dart-define=API_BASE_URL=...` (build-time injection)
  /// 2. A debug-only localhost fallback so developers can run without config.
  ///
  /// In release builds a missing/invalid URL throws instead of silently
  /// pointing at an unintended endpoint.
  static String get baseUrl {
    if (_envOverride.isNotEmpty) return _envOverride;
    if (kDebugMode) return localDevBaseUrl;

    throw StateError(
      'API_BASE_URL was not provided at build time. '
      'Use: flutter build ... --dart-define-from-file=config.json',
    );
  }

  /// The correct loopback address for local development on the current
  /// platform. Android emulators reach the host machine via `10.0.2.2`.
  static String get localDevBaseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }
}