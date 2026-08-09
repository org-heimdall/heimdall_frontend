import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/auth_member.dart';

final authTokenStoreProvider = Provider<AuthTokenStore>((ref) {
  return SecureAuthTokenStore(const FlutterSecureStorage());
});

abstract interface class AuthTokenStore {
  Future<AuthTokens?> read();

  Future<void> save(AuthTokens tokens);

  Future<void> clear();
}

class SecureAuthTokenStore implements AuthTokenStore {
  const SecureAuthTokenStore(this._storage);

  static const _accessTokenKey = 'auth.accessToken';
  static const _refreshTokenKey = 'auth.refreshToken';

  final FlutterSecureStorage _storage;

  @override
  Future<AuthTokens?> read() async {
    final values = await _storage.readAll();
    final accessToken = values[_accessTokenKey];
    final refreshToken = values[_refreshTokenKey];
    if (accessToken == null || refreshToken == null) return null;
    return AuthTokens(accessToken: accessToken, refreshToken: refreshToken);
  }

  @override
  Future<void> save(AuthTokens tokens) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: tokens.accessToken),
      _storage.write(key: _refreshTokenKey, value: tokens.refreshToken),
    ]);
  }

  @override
  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }
}

class MemoryAuthTokenStore implements AuthTokenStore {
  MemoryAuthTokenStore([this.tokens]);

  AuthTokens? tokens;

  @override
  Future<AuthTokens?> read() async => tokens;

  @override
  Future<void> save(AuthTokens tokens) async => this.tokens = tokens;

  @override
  Future<void> clear() async => tokens = null;
}
