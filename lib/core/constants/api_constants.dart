import 'api_constants_io.dart'
    if (dart.library.html) 'api_constants_web.dart' as platform;

class ApiConstants {
  static const String productionBaseUrl = 'https://backend-fnks.onrender.com';

  static const String _envOverride = String.fromEnvironment('API_BASE_URL');

  /// Base URL used for all API requests. Priority:
  /// 1. `--dart-define=API_BASE_URL=...` (build-time override)
  /// 2. The deployed backend, reachable from any real device or virtual device.
  static String get baseUrl {
    if (_envOverride.isNotEmpty) return _envOverride;
    return productionBaseUrl;
  }

  /// The correct loopback address for local development on the current
  /// platform. Android emulators reach the host machine via `10.0.2.2`.
  static String get localDevBaseUrl => platform.ApiConstantsImpl.localDevBaseUrl;
}