import 'package:dio/dio.dart';

import '../../domain/entities/debate_chat_realtime.dart';

class DebateRemoteDataSource {
  const DebateRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getDebate(String debateId) async {
    final response = await _dio.get<Map<String, dynamic>>('/debates/$debateId');
    return _requiredMap(response.data, 'Debate');
  }

  Future<Map<String, dynamic>?> getActiveCommunityDebate(
    String communityId,
  ) async {
    final response = await _dio.get<Map<String, dynamic>?>(
      '/communities/$communityId/debates/active',
    );
    return response.data;
  }

  Future<void> forfeitDebate(String debateId) async {
    await _dio.post<void>('/debates/$debateId/forfeit');
  }

  Future<void> retryJudge(String debateId) async {
    await _dio.post<void>(
      '/debates/$debateId/judge/retry',
      options: Options(receiveTimeout: const Duration(minutes: 5)),
    );
  }

  Future<Map<String, dynamic>> getDebateResult(String debateId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/debates/$debateId/result',
    );
    return _requiredMap(response.data, '판정 결과');
  }

  Future<Map<String, dynamic>?> getCurrentTurn(String debateId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/debates/$debateId/chat',
    );
    final currentTurn = response.data?['currentTurn'];
    if (currentTurn == null) return null;
    if (currentTurn is! Map<String, dynamic>) {
      throw const FormatException('currentTurn 응답이 올바르지 않습니다.');
    }
    return currentTurn;
  }

  Future<List<dynamic>> getFinalizedTurns(String debateId) async {
    final response = await _dio.get<List<dynamic>>('/debates/$debateId/turns');
    final turns = response.data;
    if (turns == null) {
      throw const FormatException('DebateTurn 목록이 올바르지 않습니다.');
    }
    return turns;
  }

  Future<Map<String, dynamic>> setTurnVote({
    required String debateId,
    required String turnId,
    required DebateTurnVoteType type,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/debates/$debateId/turns/$turnId/vote',
      data: {'type': type == DebateTurnVoteType.like ? 'LIKE' : 'DISLIKE'},
    );
    return _requiredMap(response.data, '투표');
  }

  Future<Map<String, dynamic>> removeTurnVote({
    required String debateId,
    required String turnId,
  }) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      '/debates/$debateId/turns/$turnId/vote',
    );
    return _requiredMap(response.data, '투표');
  }

  Map<String, dynamic> _requiredMap(
    Map<String, dynamic>? value,
    String responseName,
  ) {
    if (value == null) {
      throw FormatException('$responseName 응답이 비어 있습니다.');
    }
    return value;
  }
}
