import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heimdall/features/community/domain/entities/community.dart';
import 'package:heimdall/features/debate/domain/entities/debate_chat_realtime.dart';
import 'package:heimdall/features/debate/domain/repositories/debate_chat_repository.dart';
import 'package:heimdall/features/debate/presentation/providers/debate_chat_providers.dart';
import 'package:heimdall/features/debate/presentation/widgets/debate_room.dart';

void main() {
  testWidgets(
    'shows the forfeit dialog while an in-progress debate has no current turn',
    (tester) async {
      const debateId = 'debate-id';
      const detail = DebateDetail(
        id: debateId,
        communityId: 'community-id',
        status: 'IN_PROGRESS',
        rebuttalQuestionRounds: 3,
        sideASpeaker: DebateSpeaker(id: 'side-a', displayName: '찬성', score: 0),
        sideBSpeaker: DebateSpeaker(id: 'side-b', displayName: '반대', score: 0),
        viewerSide: 'SIDE_A',
        startedAt: null,
        expiresAt: null,
        judgingStartedAt: null,
      );
      final repository = _FakeDebateChatRepository(detail);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            debateChatRepositoryProvider.overrideWithValue(repository),
            debateChatEventsProvider(debateId).overrideWith(
              (ref) => Stream.value(
                const DebateChatRealtimeEvent(
                  id: 'snapshot-id',
                  debateId: debateId,
                  type: DebateChatRealtimeEventType.connectionRestored,
                  currentTurn: null,
                ),
              ),
            ),
          ],
          child: MaterialApp(
            home: DebateRoom(
              community: _community,
              debateId: debateId,
              initialDebateDetail: detail,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byTooltip('뒤로'));
      await tester.pump();

      expect(find.text('정말 기권하시겠습니까?'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

class _FakeDebateChatRepository implements DebateChatRepository {
  const _FakeDebateChatRepository(this.detail);

  final DebateDetail detail;

  @override
  Future<DebateDetail> getDebateDetail(String debateId) async => detail;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _community = Community(
  id: 'community-id',
  title: '주 4일제 토론',
  topic: '주 4일제를 도입해야 하는가',
  category: CommunityCategory.society,
  status: CommunityStatus.live,
  host: CommunityHost(name: '방장', avatarColor: 0xFF000000),
  rounds: 3,
  observerCount: 0,
  isPublic: true,
  createdAt: DateTime.utc(2026, 8, 24),
);
