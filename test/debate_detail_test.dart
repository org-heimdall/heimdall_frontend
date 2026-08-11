import 'package:flutter_test/flutter_test.dart';
import 'package:heimdall/features/debate/domain/entities/debate_chat_realtime.dart';

void main() {
  const speaker = DebateSpeaker(id: 'member', displayName: 'Member', score: 0);

  DebateDetail detail({
    required String status,
    required DateTime? judgingStartedAt,
  }) {
    return DebateDetail(
      id: 'debate',
      communityId: 'community',
      status: status,
      rebuttalQuestionRounds: 3,
      sideASpeaker: speaker,
      sideBSpeaker: speaker,
      viewerSide: 'SIDE_A',
      startedAt: null,
      expiresAt: null,
      judgingStartedAt: judgingStartedAt,
    );
  }

  test('judge retry becomes available after five stale minutes', () {
    final judgingStartedAt = DateTime.utc(2026, 8, 11, 3);
    final debate = detail(
      status: 'JUDGING',
      judgingStartedAt: judgingStartedAt,
    );

    expect(
      debate.canRetryJudgeAt(
        judgingStartedAt.add(const Duration(minutes: 4, seconds: 59)),
      ),
      isFalse,
    );
    expect(
      debate.canRetryJudgeAt(judgingStartedAt.add(const Duration(minutes: 5))),
      isTrue,
    );
  });

  test('judge retry is unavailable outside judging state', () {
    final judgingStartedAt = DateTime.utc(2026, 8, 11, 3);
    final debate = detail(
      status: 'COMPLETED',
      judgingStartedAt: judgingStartedAt,
    );

    expect(
      debate.canRetryJudgeAt(judgingStartedAt.add(const Duration(minutes: 10))),
      isFalse,
    );
  });
}
