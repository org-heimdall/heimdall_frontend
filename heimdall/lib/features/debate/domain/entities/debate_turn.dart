import 'community.dart';

enum DebateStage {
  opening('입론', 60),
  rebuttalQuestion('반론 및 질문', 180),
  closing('최종 발언', 60);

  const DebateStage(this.label, this.limitSeconds);

  final String label;
  final int limitSeconds;
}

class DebateTurn {
  const DebateTurn({
    required this.stage,
    required this.side,
    required this.speaker,
    required this.content,
    required this.remainingSeconds,
  });

  final DebateStage stage;
  final DebateSide side;
  final String speaker;
  final String content;
  final int remainingSeconds;
}
