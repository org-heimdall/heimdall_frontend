import 'package:dio/dio.dart';

import '../../features/auth/data/auth_token_store.dart';
import '../../features/auth/data/member_session_store.dart';
import '../../features/auth/domain/auth_member.dart';

class JwtAuthInterceptor extends Interceptor {
  JwtAuthInterceptor({
    required Dio dio,
    required Dio refreshDio,
    required AuthTokenStore tokenStore,
    required MemberSessionStore memberStore,
    required void Function() onSessionExpired,
  }) : _dio = dio,
       _refreshDio = refreshDio,
       _tokenStore = tokenStore,
       _memberStore = memberStore,
       _onSessionExpired = onSessionExpired;

  static const _retriedKey = 'jwtAuthRetried';

  final Dio _dio;
  final Dio _refreshDio;
  final AuthTokenStore _tokenStore;
  final MemberSessionStore _memberStore;
  final void Function() _onSessionExpired;
  Future<AuthTokens?>? _refreshing;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _attachAccessToken(options, handler);
  }

  Future<void> _attachAccessToken(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final tokens = await _tokenStore.read();
    if (tokens != null && !_isPublicAuthPath(options.path)) {
      options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _handleUnauthorized(err, handler);
  }

  Future<void> _handleUnauthorized(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final request = error.requestOptions;
    final canRefresh =
        error.response?.statusCode == 401 &&
        request.extra[_retriedKey] != true &&
        !_isPublicAuthPath(request.path);
    if (!canRefresh) {
      handler.next(error);
      return;
    }

    final tokens = await _refreshOnce();
    if (tokens == null) {
      handler.next(error);
      return;
    }

    try {
      request.extra[_retriedKey] = true;
      request.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      handler.resolve(await _dio.fetch<dynamic>(request));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<AuthTokens?> _refreshOnce() async {
    final current = _refreshing;
    if (current != null) return current;

    final refresh = _refresh();
    _refreshing = refresh;
    try {
      return await refresh;
    } finally {
      if (identical(_refreshing, refresh)) _refreshing = null;
    }
  }

  Future<AuthTokens?> _refresh() async {
    final current = await _tokenStore.read();
    if (current == null) return null;

    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': current.refreshToken},
      );
      final json = response.data;
      if (json == null) throw const FormatException('토큰 갱신 응답이 비어 있습니다.');
      final session = AuthSession.fromJson(json);
      await Future.wait([
        _tokenStore.save(session.tokens),
        _memberStore.save(session.member),
      ]);
      return session.tokens;
    } on Object {
      await Future.wait([_tokenStore.clear(), _memberStore.clear()]);
      _onSessionExpired();
      return null;
    }
  }

  bool _isPublicAuthPath(String path) {
    return path == '/auth/login' ||
        path == '/auth/signup' ||
        path == '/auth/refresh';
  }
}
