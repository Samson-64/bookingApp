import 'package:flutter/foundation.dart';

import '../../shared/models/user_settings_model.dart';
import 'settings_service.dart';

/// App-wide cache of the user's saved preferences.
///
/// Screens read [settings] for booking defaults without refetching, and the
/// Settings screen writes through [save] so the rest of the app sees changes
/// immediately.
///
/// This app has no theme, so this is not a styling source.
class SettingsController extends ChangeNotifier {
  SettingsController._();
  static final SettingsController instance = SettingsController._();

  SettingsService get _service => SettingsService.instance;

  UserSettings? _settings;
  bool _loading = false;
  String? _error;
  bool _loaded = false;

  UserSettings? get settings => _settings;
  bool get loading => _loading;
  String? get error => _error;

  /// True once a fetch has completed, successfully or not. Used to avoid a
  /// second request on every rebuild.
  bool get loaded => _loaded;

  int get defaultDurationMinutes => _settings?.defaultDurationMinutes ?? 60;
  String? get preferredParkingFloor => _settings?.preferredParkingFloor;

  Future<UserSettings?> load({bool force = false}) async {
    if (_loaded && !force) return _settings;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _settings = await _service.fetch();
      return _settings;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _loading = false;
      _loaded = true;
      notifyListeners();
    }
  }

  /// Applies a partial update and replaces the cache with the server response.
  Future<UserSettings> save(Map<String, dynamic> patch) async {
    final next = await _service.update(patch);
    _settings = next;
    _error = null;
    notifyListeners();
    return next;
  }

  /// Clears state on sign-out so the next account does not briefly see the
  /// previous user's preferences.
  void reset() {
    _settings = null;
    _error = null;
    _loaded = false;
    notifyListeners();
  }
}
