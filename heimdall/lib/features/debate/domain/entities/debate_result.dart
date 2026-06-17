import 'debate_room.dart';

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

class FactCheckResult {
  const FactCheckResult({required this.claim, required this.verdict});

  final String claim;
  final String verdict;
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

  final DebateSide winner;
  final List<DebateScore> scores;
  final String reason;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<FactCheckResult> factChecks;
  final String feedback;
}
