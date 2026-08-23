import 'package:dio/dio.dart';

import '../../domain/auth_member.dart';

class AuthRepository {
  const AuthRepository(this._dio);

  final Dio _dio;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return _parseSession(response.data);
  }

  Future<AuthSession> signUp({
    required String email,
    required String password,
    required String displayName,
    required String? gender,
    required int? age,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/signup',
      data: {
        'email': email,
        'password': password,
        'displayName': displayName,
        'gender': ?gender,
        'age': ?age,
      },
    );
    return _parseSession(response.data);
  }

  Future<void> logout(String refreshToken) async {
    await _dio.post<void>('/auth/logout', data: {'refreshToken': refreshToken});
  }

  AuthSession _parseSession(Map<String, dynamic>? json) {
    if (json == null) {
      throw const FormatException('회원 응답이 비어 있습니다.');
    }
    return AuthSession.fromJson(json);
  }
}
