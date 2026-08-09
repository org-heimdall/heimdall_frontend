import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_environment.dart';
import '../../features/auth/data/auth_token_store.dart';
import '../../features/auth/data/member_session_store.dart';
import 'jwt_auth_interceptor.dart';

final dioProvider = Provider<Dio>((ref) {
  final sessionStore = ref.watch(memberSessionStoreProvider);
  final tokenStore = ref.watch(authTokenStoreProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: AppEnvironment.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );

  final refreshDio = Dio(
    BaseOptions(
      baseUrl: AppEnvironment.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  dio.interceptors.add(
    JwtAuthInterceptor(
      dio: dio,
      refreshDio: refreshDio,
      tokenStore: tokenStore,
      memberStore: sessionStore,
      onSessionExpired: () =>
          ref.read(authSessionEpochProvider.notifier).invalidate(),
    ),
  );
  dio.interceptors.add(
    LogInterceptor(requestHeader: false, requestBody: true, responseBody: true),
  );

  ref.onDispose(() {
    dio.close();
    refreshDio.close();
  });
  return dio;
});
