import 'package:dio/dio.dart';

class CommunityRemoteDataSource {
  const CommunityRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<dynamic>> fetchCommunities() async {
    final response = await _dio.get<List<dynamic>>('/communities');
    return _requiredList(response.data, '커뮤니티 목록');
  }

  Future<Map<String, dynamic>> fetchCommunity(String communityId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/communities/$communityId',
    );
    return _requiredMap(response.data, '커뮤니티 상세');
  }

  Future<Map<String, dynamic>> createCommunity(
    Map<String, Object?> request,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/communities',
      data: request,
    );
    return _requiredMap(response.data, '커뮤니티 생성');
  }

  Future<Map<String, dynamic>> startDebate({
    required String communityId,
    required String opponentMemberId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/communities/$communityId/debates/start',
      data: {'opponentMemberId': opponentMemberId},
    );
    return _requiredMap(response.data, '토론 생성');
  }

  Future<void> joinCommunity(String communityId) async {
    await _dio.post<void>('/communities/$communityId/members/me');
  }

  Future<void> leaveCommunity(String communityId) async {
    await _dio.delete<void>('/communities/$communityId/members/me');
  }

  Future<List<dynamic>> fetchCommunityMembers(String communityId) async {
    final response = await _dio.get<List<dynamic>>(
      '/communities/$communityId/members',
    );
    return _requiredList(response.data, '커뮤니티 멤버 목록');
  }

  Future<void> updateDebateIntent({
    required String communityId,
    required bool wantsToDebate,
  }) async {
    await _dio.put<void>(
      '/communities/$communityId/members/me/debate-intent',
      data: {'debateIntent': wantsToDebate ? 'OPEN_TO_DEBATE' : 'PREPARING'},
    );
  }

  Map<String, dynamic> _requiredMap(
    Map<String, dynamic>? value,
    String responseName,
  ) {
    if (value == null) throw FormatException('$responseName 응답이 비어 있습니다.');
    return value;
  }

  List<dynamic> _requiredList(List<dynamic>? value, String responseName) {
    if (value == null) throw FormatException('$responseName 응답이 비어 있습니다.');
    return value;
  }
}
