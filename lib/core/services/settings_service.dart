import '../../shared/models/user_model.dart';
import '../../shared/models/user_settings_model.dart';
import '../network/api_client.dart';
import '../storage/token_storage.dart';

/// Reads and writes the account's saved preferences, plus the profile and
/// security actions that live behind the same Settings screen.
class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  ApiClient get _api => ApiClient.instance;

  Future<UserSettings> fetch() async {
    final res = await _api.get<Map<String, dynamic>>('/api/settings');
    return UserSettings.fromMap(Map<String, dynamic>.from(res.data ?? {}));
  }

  /// Sends only the fields the caller changed. The backend distinguishes an
  /// omitted field from an explicit null, which is how a parking-floor
  /// preference is cleared.
  Future<UserSettings> update(Map<String, dynamic> patch) async {
    final res = await _api.patch<Map<String, dynamic>>(
      '/api/settings',
      data: patch,
    );
    return UserSettings.fromMap(Map<String, dynamic>.from(res.data ?? {}));
  }

  /// Updates the profile and re-caches it locally so the shell reflects the new
  /// name without another fetch.
  Future<AppUser> updateProfile({
    required String name,
    required String email,
  }) async {
    final res = await _api.patch<Map<String, dynamic>>(
      '/api/settings/profile',
      data: {'name': name, 'email': email},
    );
    final user = AppUser.fromMap(Map<String, dynamic>.from(res.data ?? {}));
    final token = await TokenStorage.instance.readToken();
    if (token != null) {
      await TokenStorage.instance.save(token: token, user: user);
    }
    return user;
  }

  /// Changes the password. Every session is revoked by the backend, this one
  /// included, so the caller must sign the user out afterwards.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.post(
      '/api/settings/profile/password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  /// Revokes every session on every device, including the current one.
  Future<void> logoutEverywhere() async {
    await _api.post('/api/auth/logout-all');
  }
}
