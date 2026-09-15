import '../../../shared/models/user_model.dart';
import '../../core/errors/api_exception.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  ApiClient get _api => ApiClient.instance;
  TokenStorage get _storage => TokenStorage.instance;

  Future<AppUser?> get currentUser => _storage.readUser();

  Future<AppUser> signInWithPassword(String email, String password) {
    return _authenticate(
      path: '/api/auth/login',
      body: {'email': email, 'password': password},
    );
  }

  /// Registers a CLIENT and stores the returned session (FastAPI signs the
  /// user in immediately — no email confirmation step).
  Future<AppUser> registerClient({
    required String name,
    required String email,
    required String password,
  }) {
    return _authenticate(
      path: '/api/auth/register',
      body: {'name': name, 'email': email, 'password': password},
    );
  }

  /// Registers a SPECIALIST (creates the linked `people` row) and stores the
  /// returned session.
  Future<AppUser> registerProvider({
    required String name,
    required String position,
    required String email,
    required String password,
  }) {
    return _authenticate(
      path: '/api/auth/register-specialist',
      body: {
        'name': name,
        'position': position,
        'email': email,
        'password': password,
      },
    );
  }

  Future<void> signOut() => _storage.clear();

  /// Returns the signed-in user profile. Prefers the locally cached profile
  /// and falls back to the backend when no cached copy exists.
  Future<AppUser?> fetchProfile() async {
    final cached = await _storage.readUser();
    if (cached != null) return cached;

    final token = await _storage.readToken();
    if (token == null) return null;

    final res = await _api.get<Map<String, dynamic>>('/api/auth/me');
    final data = Map<String, dynamic>.from(res.data ?? {});
    final user = AppUser.fromMap(data);
    await _storage.save(token: token, user: user);
    return user;
  }

  Future<AppUser> _authenticate({
    required String path,
    required Map<String, dynamic> body,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(path, data: body);
    final data = Map<String, dynamic>.from(res.data ?? {});
    final token = data['access_token']?.toString();
    if (token == null || token.isEmpty) {
      throw const ApiException(message: 'Invalid response from server.');
    }
    final user = AppUser.fromMap(
      Map<String, dynamic>.from(data['user'] as Map? ?? const {}),
    );
    await _storage.save(token: token, user: user);
    return user;
  }
}