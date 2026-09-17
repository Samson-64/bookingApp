import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../shared/models/user_model.dart';

class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  final _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'pulsebook.token';
  static const String _refreshKey = 'pulsebook.refresh';
  static const String _userKey = 'pulsebook.user';

  Future<void> save({required String token, String? refreshToken, AppUser? user}) async {
    await _storage.write(key: _tokenKey, value: token);
    if (refreshToken != null) {
      await _storage.write(key: _refreshKey, value: refreshToken);
    }
    if (user != null) {
      await _storage.write(key: _userKey, value: jsonEncode(user.toMap()));
    }
  }

  Future<String?> readToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<String?> readRefreshToken() async {
    return _storage.read(key: _refreshKey);
  }

  Future<AppUser?> readUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    return AppUser.fromMap(jsonDecode(raw));
  }

  Future<bool> hasToken() async {
    final t = await _storage.read(key: _tokenKey);
    return t != null && t.isNotEmpty;
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}
