import 'package:dio/dio.dart';

import '../domain/entities/debate_chat_realtime.dart';
import '../domain/entities/debate_result.dart';
import '../domain/entities/community.dart';
import '../domain/repositories/debate_chat_repository.dart';

class HttpDebateChatRepository implements DebateChatRepository {
  const HttpDebateChatRepository(this._dio);

  final Dio _dio;

  @override
  Future<DebateDetail> getDebateDetail(String debateId) async {
    final response = await _dio.get<Map<String, dynamic>>('/debates/$debateId');
    final json = response.data;
    if (json == null) throw const FormatException('Debate 응답이 비어 있습니다.');
    return _parseDebateDetail(json);
  }

  @override
  Future<DebateDetail?> getActiveCommunityDebate(String communityId) async {
    final response = await _dio.get<Map<String, dynamic>?>(
      '/communities/$communityId/debates/active',
    );
    final json = response.data;
    return json == null ? null : _parseDebateDetail(json);
  }

  @override
  Future<void> forfeitDebate(String debateId) async {
    await _dio.post<void>('/debates/$debateId/forfeit');
  }

  @override
  Future<void> retryJudge(String debateId) async {
    await _dio.post<void>(
      '/debates/$debateId/judge/retry',
      options: Options(receiveTimeout: const Duration(minutes: 5)),
    );
  }

  @override
  Future<DebateResult> getDebateResult(String debateId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/debates/$debateId/result',
    );
    final root = response.data;
    final debate = root?['debate'];
    final judgment = root?['judgmentResult'];
    if (debate is! Map<String, dynamic> || judgment is! Map<String, dynamic>) {
      throw const FormatException('판정 결과 응답이 올바르지 않습니다.');
    }
    final viewerSide = root?['viewerSide'] as String?;
    final sideAFeedback = _requiredString(judgment, 'sideAFeedback');
    final sideBFeedback = _requiredString(judgment, 'sideBFeedback');
    return DebateResult(
      winner: switch (judgment['winner']) {
        'SIDE_B' => DebateWinner.con,
        'DRAW' => DebateWinner.draw,
        _ => DebateWinner.pro,
      },
      scores: [
        DebateScore(
          side: DebateSide.pro,
          score: _requiredInt(judgment, 'sideATotalScore'),
          summary: sideAFeedback,
        ),
        DebateScore(
          side: DebateSide.con,
          score: _requiredInt(judgment, 'sideBTotalScore'),
          summary: sideBFeedback,
        ),
      ],
      reason: _requiredString(judgment, 'overallReason'),
      strengths: const [],
      weaknesses: const [],
      factChecks: const [],
      feedback: viewerSide == 'SIDE_B' ? sideBFeedback : sideAFeedback,
    );
  }

  DebateDetail _parseDebateDetail(Map<String, dynamic> json) {
    return DebateDetail(
      id: _requiredString(json, 'id'),
      communityId: _requiredString(json, 'communityId'),
      status: _requiredString(json, 'status'),
      rebuttalQuestionRounds: _requiredInt(json, 'rebuttalQuestionRounds'),
      sideASpeaker: _speaker(json['sideASpeaker'], 'sideASpeaker'),
      sideBSpeaker: _speaker(json['sideBSpeaker'], 'sideBSpeaker'),
      viewerSide: json['viewerSide'] as String?,
      startedAt: _optionalDate(json['startedAt']),
      expiresAt: _optionalDate(json['expiresAt']),
      judgingStartedAt: _optionalDate(json['judgingStartedAt']),
    );
  }

  @override
  Future<DebateTurnCommandContext> getCurrentTurnContext(
    String debateId,
  ) async {
    final debateResponse = await _dio.get<Map<String, dynamic>>(
      '/debates/$debateId',
    );
    final debate = debateResponse.data;
    if (debate == null) {
      throw const FormatException('Debate 응답이 비어 있습니다.');
    }

    final phase = _requiredString(debate, 'currentPhase');
    final round = _requiredInt(debate, 'currentRound');
    final turnSide = _requiredString(debate, 'currentTurnSide');
    final speakerIdField = switch (turnSide) {
      'SIDE_A' => 'sideASpeakerId',
      'SIDE_B' => 'sideBSpeakerId',
      _ => throw FormatException('지원하지 않는 토론 진영입니다: $turnSide'),
    };
    final speakerId = _requiredString(debate, speakerIdField);

    return DebateTurnCommandContext(
      speakerId: speakerId,
      speakerSide: turnSide,
      phase: phase,
      round: round,
    );
  }

  @override
  Future<DebateChatCurrentTurn?> getCurrentTurn(String debateId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/debates/$debateId/chat',
    );
    final currentTurn = response.data?['currentTurn'];
    if (currentTurn == null) {
      return null;
    }
    if (currentTurn is! Map<String, dynamic>) {
      throw const FormatException('currentTurn 응답이 올바르지 않습니다.');
    }

    return DebateChatCurrentTurn(
      phase: _requiredString(currentTurn, 'phase'),
      round: _requiredInt(currentTurn, 'round'),
      turnSide: _requiredString(currentTurn, 'turnSide'),
      startedAt: DateTime.parse(_requiredString(currentTurn, 'startedAt')),
      maxDurationSeconds: _requiredInt(currentTurn, 'maxDurationSeconds'),
      maxTotalCharacters: _requiredInt(currentTurn, 'maxTotalCharacters'),
    );
  }

  @override
  Future<List<DebateFinalizedTurn>> getFinalizedTurns(String debateId) async {
    final response = await _dio.get<List<dynamic>>('/debates/$debateId/turns');
    final turns = response.data;
    if (turns == null) {
      throw const FormatException('DebateTurn 목록이 올바르지 않습니다.');
    }

    final result = turns.map((raw) {
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('DebateTurn 응답이 올바르지 않습니다.');
      }
      return DebateFinalizedTurn(
        id: _requiredString(raw, 'id'),
        speakerId: _requiredString(raw, 'speakerId'),
        speakerSide: _requiredString(raw, 'speakerSide'),
        phase: _requiredString(raw, 'phase'),
        round: _requiredInt(raw, 'round'),
        sequence: _requiredInt(raw, 'sequence'),
        content: _requiredString(raw, 'content'),
        createdAt: DateTime.parse(_requiredString(raw, 'createdAt')),
        likeCount: _requiredInt(raw, 'likeCount'),
        dislikeCount: _requiredInt(raw, 'dislikeCount'),
      );
    }).toList()..sort((left, right) => left.sequence.compareTo(right.sequence));

    return result;
  }

  @override
  Future<DebateTurnVoteSummary> setTurnVote({
    required String debateId,
    required String turnId,
    required DebateTurnVoteType type,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/debates/$debateId/turns/$turnId/vote',
      data: {'type': type == DebateTurnVoteType.like ? 'LIKE' : 'DISLIKE'},
    );
    return _parseVoteSummary(response.data);
  }

  @override
  Future<DebateTurnVoteSummary> removeTurnVote({
    required String debateId,
    required String turnId,
  }) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      '/debates/$debateId/turns/$turnId/vote',
    );
    return _parseVoteSummary(response.data);
  }

  DebateTurnVoteSummary _parseVoteSummary(Map<String, dynamic>? json) {
    if (json == null) {
      throw const FormatException('투표 응답이 비어 있습니다.');
    }
    return DebateTurnVoteSummary(
      turnId: _requiredString(json, 'turnId'),
      likeCount: _requiredInt(json, 'likeCount'),
      dislikeCount: _requiredInt(json, 'dislikeCount'),
    );
  }

  String _requiredString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$field 값이 없거나 올바르지 않습니다.');
    }
    return value;
  }

  int _requiredInt(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is! num || value.toInt() != value) {
      throw FormatException('$field 값이 없거나 올바르지 않습니다.');
    }
    return value.toInt();
  }

  DebateSpeaker _speaker(Object? raw, String field) {
    if (raw is! Map<String, dynamic>) {
      throw FormatException('$field 값이 올바르지 않습니다.');
    }
    return DebateSpeaker(
      id: _requiredString(raw, 'id'),
      displayName: _requiredString(raw, 'displayName'),
      score: _requiredInt(raw, 'score'),
      profileImageUrl: raw['profileImageUrl'] as String?,
    );
  }

  DateTime? _optionalDate(Object? value) =>
      value is String && value.isNotEmpty ? DateTime.parse(value) : null;
}
