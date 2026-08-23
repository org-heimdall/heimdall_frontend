import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/stores/auth_token_store.dart';
import '../../data/stores/member_session_store.dart';
import '../../domain/auth_member.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthMember?>(AuthController.new);

final currentMemberProvider = Provider<AuthMember?>((ref) {
  return ref.watch(authControllerProvider).value;
});

class AuthController extends AsyncNotifier<AuthMember?> {
  @override
  Future<AuthMember?> build() async {
    ref.watch(authSessionEpochProvider);
    final member = ref.watch(memberSessionStoreProvider).read();
    final tokens = await ref.watch(authTokenStoreProvider).read();
    if (member == null || tokens == null) return null;
    return member;
  }

  Future<void> login({required String email, required String password}) async {
    await _authenticate(
      () => ref
          .read(authRepositoryProvider)
          .login(email: email.trim(), password: password),
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    required String? gender,
    required int? age,
  }) async {
    await _authenticate(
      () => ref
          .read(authRepositoryProvider)
          .signUp(
            email: email.trim(),
            password: password,
            displayName: displayName.trim(),
            gender: gender,
            age: age,
          ),
    );
  }

  Future<void> logout() async {
    final tokenStore = ref.read(authTokenStoreProvider);
    final refreshToken = (await tokenStore.read())?.refreshToken;
    try {
      if (refreshToken != null) {
        await ref.read(authRepositoryProvider).logout(refreshToken);
      }
    } on DioException {
      // 서버 로그아웃은 현재 무상태이므로 로컬 세션 삭제를 우선한다.
    }
    await Future.wait([
      ref.read(memberSessionStoreProvider).clear(),
      tokenStore.clear(),
    ]);
    state = const AsyncData(null);
  }

  Future<void> _authenticate(Future<AuthSession> Function() request) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await request();
      await Future.wait([
        ref.read(memberSessionStoreProvider).save(session.member),
        ref.read(authTokenStoreProvider).save(session.tokens),
      ]);
      return session.member;
    });
  }
}
