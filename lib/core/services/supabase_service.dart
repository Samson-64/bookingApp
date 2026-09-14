import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/user_model.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signInWithPassword(String email, String password) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp(String email, String password) {
    return _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();

  /// Reads the public `users` profile row for the signed-in user.
  Future<AppUser?> fetchProfile() async {
    final session = _client.auth.currentSession;
    final user = session?.user;
    if (user == null) return null;

    final rows = await _client
        .from('users')
        .select()
        .eq('email', user.email ?? '')
        .limit(1);
    final list = rows as List<dynamic>;
    if (list.isEmpty) return null;
    return AppUser.fromMap(Map<String, dynamic>.from(list.first));
  }

  /// Registers a CLIENT: Supabase Auth account + `users` row (role CLIENT).
  /// Returns the id of the created auth user, or null when not returned
  /// (e.g. email confirmation is required).
  Future<String?> registerClient({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signUp(email: email, password: password);
    final userId = res.user?.id;
    if (userId != null) {
      await _client.from('users').insert({
        'id': userId,
        'name': name,
        'email': email,
        'role': 'CLIENT',
      });
    }
    return userId;
  }

  /// Registers a SPECIALIST: creates a `people` row, then links the user
  /// via `person_id`, and creates the `users` row (role SPECIALIST).
  /// Returns the id of the created auth user, or null when not returned.
  Future<String?> registerProvider({
    required String name,
    required String position,
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signUp(email: email, password: password);
    final userId = res.user?.id;
    if (userId == null) return null;

    final peopleResp = await _client.from('people').insert({
      'name': name,
      'position': position,
    }).select('id').single();

    await _client.from('users').insert({
      'id': userId,
      'name': name,
      'email': email,
      'role': 'SPECIALIST',
      'person_id': peopleResp['id'],
    });
    return userId;
  }
}