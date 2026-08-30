import 'package:flutter_test/flutter_test.dart';
import 'package:heimdall/features/debate/domain/entities/debate_chat_realtime.dart';
import 'package:heimdall/features/debate/data/mappers/debate_response_mapper.dart';

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

  test('judge retry becomes available after 185 seconds', () {
    final judgingStartedAt = DateTime.utc(2026, 8, 11, 3);
    final debate = detail(
      status: 'JUDGING',
      judgingStartedAt: judgingStartedAt,
    );

    expect(
      debate.canRetryJudgeAt(
        judgingStartedAt.add(const Duration(seconds: 184)),
      ),
      isFalse,
    );
    expect(
      debate.canRetryJudgeAt(
        judgingStartedAt.add(const Duration(seconds: 185)),
      ),
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

  test('maps both speakers opening statements from debate detail', () {
    final detail = const DebateResponseMapper().mapDebateDetail({
      'id': 'debate',
      'communityId': 'community',
      'status': 'IN_PROGRESS',
      'rebuttalQuestionRounds': 2,
      'sideASpeaker': {
        'id': 'host',
        'displayName': '방장',
        'score': 10,
        'claim': '주 4일제를 도입해야 합니다.',
        'reasons': ['생산성이 향상됩니다.'],
      },
      'sideBSpeaker': {
        'id': 'opponent',
        'displayName': '상대',
        'score': 8,
        'claim': '주 4일제 도입은 이릅니다.',
        'reasons': ['업종별 격차가 큽니다.'],
      },
      'viewerSide': 'SIDE_A',
      'startedAt': null,
      'expiresAt': null,
      'judgingStartedAt': null,
    });

    expect(detail.sideASpeaker.claim, '주 4일제를 도입해야 합니다.');
    expect(detail.sideBSpeaker.reasons, ['업종별 격차가 큽니다.']);
  });

  test(
    'current turn reports preparation seconds until its server start time',
    () {
      final now = DateTime.utc(2026, 8, 23, 3);
      final turn = DebateChatCurrentTurn(
        phase: 'OPENING',
        round: 1,
        turnSide: 'SIDE_A',
        startedAt: now.add(const Duration(seconds: 10)),
        maxDurationSeconds: 90,
        maxTotalCharacters: 1000,
      );

      expect(turn.preparationSecondsRemainingAt(now), 10);
      expect(
        turn.preparationSecondsRemainingAt(
          now.add(const Duration(milliseconds: 9500)),
        ),
        1,
      );
      expect(
        turn.preparationSecondsRemainingAt(
          now.add(const Duration(seconds: 10)),
        ),
        0,
      );
    },
  );
}
