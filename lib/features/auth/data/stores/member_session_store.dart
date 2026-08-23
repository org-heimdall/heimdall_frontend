import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/auth_member.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw StateError('SharedPreferences provider must be overridden.');
});

final memberSessionStoreProvider = Provider<MemberSessionStore>((ref) {
  return MemberSessionStore(ref.watch(sharedPreferencesProvider));
});

final authSessionEpochProvider = NotifierProvider<AuthSessionEpoch, int>(
  AuthSessionEpoch.new,
);

class AuthSessionEpoch extends Notifier<int> {
  @override
  int build() => 0;

  void invalidate() => state += 1;
}

class MemberSessionStore {
  const MemberSessionStore(this._preferences);

  static const _idKey = 'auth.member.id';
  static const _emailKey = 'auth.member.email';
  static const _displayNameKey = 'auth.member.displayName';
  static const _profileImageUrlKey = 'auth.member.profileImageUrl';
  static const _scoreKey = 'auth.member.score';

  final SharedPreferences _preferences;

  AuthMember? read() {
    final id = _preferences.getString(_idKey);
    final email = _preferences.getString(_emailKey);
    final displayName = _preferences.getString(_displayNameKey);

    if (id == null || email == null || displayName == null) {
      return null;
    }

    return AuthMember(
      id: id,
      email: email,
      displayName: displayName,
      profileImageUrl: _preferences.getString(_profileImageUrlKey),
      score: _preferences.getInt(_scoreKey) ?? 0,
    );
  }

  Future<void> save(AuthMember member) async {
    await Future.wait([
      _preferences.setString(_idKey, member.id),
      _preferences.setString(_emailKey, member.email),
      _preferences.setString(_displayNameKey, member.displayName),
      _preferences.setInt(_scoreKey, member.score),
      if (member.profileImageUrl case final profileImageUrl?)
        _preferences.setString(_profileImageUrlKey, profileImageUrl)
      else
        _preferences.remove(_profileImageUrlKey),
    ]);
  }

  Future<void> clear() async {
    await Future.wait([
      _preferences.remove(_idKey),
      _preferences.remove(_emailKey),
      _preferences.remove(_displayNameKey),
      _preferences.remove(_profileImageUrlKey),
      _preferences.remove(_scoreKey),
    ]);
  }
}
