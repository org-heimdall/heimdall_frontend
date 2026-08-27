import '../../../../shared/domain/entities/debate_side.dart';
import '../../domain/entities/debate_chat_realtime.dart';
import '../../domain/entities/debate_result.dart';

class DebateResponseMapper {
  const DebateResponseMapper();

  DebateDetail mapDebateDetail(Map<String, dynamic> json) {
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

  DebateResult mapDebateResult(Map<String, dynamic> root) {
    final debate = root['debate'];
    final judgment = root['judgmentResult'];
    if (debate is! Map<String, dynamic> || judgment is! Map<String, dynamic>) {
      throw const FormatException('판정 결과 응답이 올바르지 않습니다.');
    }
    final viewerSide = root['viewerSide'] as String?;
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
      factChecks: mapFactChecks(root['factChecks']),
      feedback: viewerSide == 'SIDE_B' ? sideBFeedback : sideAFeedback,
    );
  }

  DebateTurnCommandContext mapTurnCommandContext(Map<String, dynamic> debate) {
    final phase = _requiredString(debate, 'currentPhase');
    final round = _requiredInt(debate, 'currentRound');
    final turnSide = _requiredString(debate, 'currentTurnSide');
    final speakerIdField = switch (turnSide) {
      'SIDE_A' => 'sideASpeakerId',
      'SIDE_B' => 'sideBSpeakerId',
      _ => throw FormatException('지원하지 않는 토론 진영입니다: $turnSide'),
    };

    return DebateTurnCommandContext(
      speakerId: _requiredString(debate, speakerIdField),
      speakerSide: turnSide,
      phase: phase,
      round: round,
    );
  }

  DebateChatCurrentTurn mapCurrentTurn(Map<String, dynamic> currentTurn) {
    return DebateChatCurrentTurn(
      phase: _requiredString(currentTurn, 'phase'),
      round: _requiredInt(currentTurn, 'round'),
      turnSide: _requiredString(currentTurn, 'turnSide'),
      startedAt: DateTime.parse(_requiredString(currentTurn, 'startedAt')),
      maxDurationSeconds: _requiredInt(currentTurn, 'maxDurationSeconds'),
      maxTotalCharacters: _requiredInt(currentTurn, 'maxTotalCharacters'),
    );
  }

  List<DebateFinalizedTurn> mapFinalizedTurns(List<dynamic> turns) {
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

  DebateTurnVoteSummary mapVoteSummary(Map<String, dynamic> json) {
    return DebateTurnVoteSummary(
      turnId: _requiredString(json, 'turnId'),
      likeCount: _requiredInt(json, 'likeCount'),
      dislikeCount: _requiredInt(json, 'dislikeCount'),
    );
  }

  List<FactCheckResult> mapFactChecks(Object? raw) {
    if (raw == null) return const [];
    if (raw is! List<dynamic>) {
      throw const FormatException('팩트체크 결과 목록이 올바르지 않습니다.');
    }

    return raw.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('팩트체크 결과가 올바르지 않습니다.');
      }
      final sourcesRaw = item['sources'];
      if (sourcesRaw is! List<dynamic>) {
        throw const FormatException('팩트체크 출처 목록이 올바르지 않습니다.');
      }

      return FactCheckResult(
        id: _requiredString(item, 'id'),
        componentId: _requiredString(item, 'componentId'),
        speakerId: item['speakerId'] as String?,
        speakerSide: item['speakerSide'] as String?,
        claim: _requiredString(item, 'statement'),
        status: FactCheckStatus.fromWireValue(_requiredString(item, 'status')),
        reason: _requiredString(item, 'reason'),
        sources: sourcesRaw.map((source) {
          if (source is! Map<String, dynamic>) {
            throw const FormatException('팩트체크 출처가 올바르지 않습니다.');
          }
          return FactCheckSource(
            title: _requiredString(source, 'title'),
            publisher: _requiredString(source, 'publisher'),
            url: _requiredString(source, 'url'),
          );
        }).toList(),
        checkedAt: DateTime.parse(_requiredString(item, 'checkedAt')),
      );
    }).toList();
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
      claim: raw['claim'] as String? ?? '',
      reasons:
          (raw['reasons'] as List<dynamic>?)?.whereType<String>().toList() ??
          const [],
    );
  }

  DateTime? _optionalDate(Object? value) =>
      value is String && value.isNotEmpty ? DateTime.parse(value) : null;
}
