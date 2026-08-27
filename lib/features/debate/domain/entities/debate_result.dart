import '../../../../shared/domain/entities/debate_side.dart';

enum DebateWinner {
  pro('찬성'),
  con('반대'),
  draw('무승부');

  const DebateWinner(this.label);
  final String label;
}

class DebateScore {
  const DebateScore({
    required this.side,
    required this.score,
    required this.summary,
  });

  final DebateSide side;
  final int score;
  final String summary;
}

enum FactCheckStatus {
  supported('SUPPORTED', '근거 있음'),
  contradicted('CONTRADICTED', '사실과 다름'),
  partiallySupported('PARTIALLY_SUPPORTED', '일부 근거 있음'),
  insufficientEvidence('INSUFFICIENT_EVIDENCE', '근거 부족'),
  notVerifiable('NOT_VERIFIABLE', '검증 불가'),
  outdatedOrTimeSensitive('OUTDATED_OR_TIME_SENSITIVE', '시점 확인 필요'),
  unknown('UNKNOWN', '확인 필요');

  const FactCheckStatus(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static FactCheckStatus fromWireValue(String value) {
    return FactCheckStatus.values.firstWhere(
      (status) => status.wireValue == value,
      orElse: () => FactCheckStatus.unknown,
    );
  }
}

class FactCheckSource {
  const FactCheckSource({
    required this.title,
    required this.publisher,
    required this.url,
  });

  final String title;
  final String publisher;
  final String url;
}

class FactCheckResult {
  const FactCheckResult({
    required this.id,
    required this.componentId,
    this.speakerId,
    this.speakerSide,
    required this.claim,
    required this.status,
    required this.reason,
    required this.sources,
    required this.checkedAt,
  });

  final String id;
  final String componentId;
  final String? speakerId;
  final String? speakerSide;
  final String claim;
  final FactCheckStatus status;
  final String reason;
  final List<FactCheckSource> sources;
  final DateTime checkedAt;
}

class DebateResult {
  const DebateResult({
    required this.winner,
    required this.scores,
    required this.reason,
    required this.strengths,
    required this.weaknesses,
    required this.factChecks,
    required this.feedback,
  });

  final DebateWinner winner;
  final List<DebateScore> scores;
  final String reason;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<FactCheckResult> factChecks;
  final String feedback;
}
