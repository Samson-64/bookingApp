import 'package:flutter/foundation.dart';

/// Runtime/config-safe API constants.
///
/// The production backend URL defaults to the deployed backend so the app
/// works out of the box in every build mode (debug included). It can be
/// overridden at build time via `--dart-define-from-file=config.json` (or
/// `--dart-define=API_BASE_URL=...`).
///
/// Build commands:
///   flutter run --dart-define-from-file=config.json
///   flutter build apk --dart-define-from-file=config.json
class ApiConstants {
  static const String _envOverride = String.fromEnvironment('API_BASE_URL');

  /// The deployed production backend. Used in all build modes unless
  /// overridden by a build-time flag.
  static const String productionBaseUrl = 'https://backend-fnks.onrender.com';

  /// Base URL used for all API requests.
  ///
  /// Resolution order:
  /// 1. `--dart-define=API_BASE_URL=...` (build-time injection)
  /// 2. The deployed production backend.
  static String get baseUrl {
    if (_envOverride.isNotEmpty) return _envOverride;
    return productionBaseUrl;
  }

  /// The correct loopback address for local development on the current
  /// platform. Android emulators reach the host machine via `10.0.2.2`.
  /// Only useful when running a local FastAPI backend on port 8000.
  static String get localDevBaseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }
}