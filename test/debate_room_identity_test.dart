import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heimdall/features/community/domain/entities/community.dart';
import 'package:heimdall/features/debate/domain/entities/debate_chat_realtime.dart';
import 'package:heimdall/features/debate/domain/repositories/debate_chat_repository.dart';
import 'package:heimdall/features/debate/presentation/providers/debate_chat_providers.dart';
import 'package:heimdall/features/debate/presentation/widgets/debate_room.dart';
import 'package:heimdall/shared/chat/presentation/widgets/chat_message_tile.dart';

void main() {
  testWidgets('shows the host identity as the opponent for the side B viewer', (
    tester,
  ) async {
    const debateId = 'debate-id';
    const detail = DebateDetail(
      id: debateId,
      communityId: 'community-id',
      status: 'IN_PROGRESS',
      rebuttalQuestionRounds: 3,
      sideASpeaker: DebateSpeaker(id: 'host-id', displayName: '방장', score: 10),
      sideBSpeaker: DebateSpeaker(
        id: 'challenger-id',
        displayName: '도전자',
        score: 8,
      ),
      viewerSide: 'SIDE_B',
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
              DebateChatRealtimeEvent(
                id: 'snapshot-id',
                debateId: debateId,
                type: DebateChatRealtimeEventType.connectionRestored,
                currentTurn: null,
                draftMessages: [
                  DebateChatDraftMessage(
                    id: 'message-id',
                    speakerId: 'host-id',
                    speakerSide: 'SIDE_A',
                    content: '방장의 발언',
                    createdAt: DateTime.utc(2026, 8, 25),
                  ),
                ],
              ),
            ),
          ),
        ],
        child: MaterialApp(
          home: DebateRoom(
            community: _community,
            debateId: debateId,
            initialDebateDetail: detail,
            isHost: false,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final messageTile = find.byType(ChatMessageTile);
    expect(messageTile, findsOneWidget);
    expect(
      find.descendant(of: messageTile, matching: find.text('방장')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: messageTile, matching: find.text('도전자')),
      findsNothing,
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });
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
  host: const CommunityHost(name: '방장', avatarColor: 0xFF000000),
  rounds: 3,
  observerCount: 0,
  isPublic: true,
  createdAt: DateTime.utc(2026, 8, 25),
);
