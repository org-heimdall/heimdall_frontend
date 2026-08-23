import 'package:flutter_test/flutter_test.dart';
import 'package:heimdall/features/community/data/realtime/community_chat_realtime_client.dart';
import 'package:heimdall/features/community/data/repositories/community_chat_realtime_repository_impl.dart';
import 'package:heimdall/features/community/domain/entities/community_chat.dart';

void main() {
  test('maps a stored message ACK to an acknowledged chat event', () async {
    final client = _FakeCommunityChatRealtimeClient([
      {
        'id': 'event-1',
        'type': 'community.message.ack',
        'communityId': 'community-1',
        'commandId': 'command-1',
        'clientMessageId': 'client-1',
        'status': 'STORED',
        'message': {
          'id': 'message-1',
          'communityId': 'community-1',
          'clientMessageId': 'client-1',
          'authorId': 'member-1',
          'authorName': '회원',
          'text': '저장된 메시지',
          'createdAt': '2026-08-23T08:00:00.000Z',
        },
      },
    ]);

    final event = await CommunityChatRealtimeRepositoryImpl(
      client,
    ).watchEvents('community-1').first;

    expect(event.type, CommunityChatEventType.messageAcknowledged);
    expect(event.commandId, 'command-1');
    expect(event.status, 'STORED');
    expect(event.message?.id, 'message-1');
    expect(event.message?.clientMessageId, 'client-1');
  });

  test('maps a command failure without terminating event parsing', () async {
    final client = _FakeCommunityChatRealtimeClient([
      {
        'id': 'event-2',
        'type': 'error',
        'communityId': 'community-1',
        'commandId': 'command-2',
        'message': '저장하지 못했습니다.',
      },
    ]);

    final event = await CommunityChatRealtimeRepositoryImpl(
      client,
    ).watchEvents('community-1').first;

    expect(event.type, CommunityChatEventType.error);
    expect(event.commandId, 'command-2');
    expect(event.errorMessage, '저장하지 못했습니다.');
  });

  test(
    'maps a debate result notification to a community result message',
    () async {
      final client = _FakeCommunityChatRealtimeClient([
        {
          'id': 'event-3',
          'type': 'message.created',
          'communityId': 'community-1',
          'message': {
            'id': 'result-message',
            'communityId': 'community-1',
            'clientMessageId': 'result-client',
            'authorId': 'system',
            'authorName': '헤임달',
            'text': '토론이 종료되었습니다.',
            'messageType': 'DEBATE_RESULT',
            'debateId': 'debate-1',
            'createdAt': '2026-08-23T08:00:00.000Z',
          },
        },
      ]);

      final event = await CommunityChatRealtimeRepositoryImpl(
        client,
      ).watchEvents('community-1').first;

      expect(event.message, isA<CommunityDebateResultMessage>());
      expect(
        (event.message as CommunityDebateResultMessage).debateId,
        'debate-1',
      );
    },
  );
}

class _FakeCommunityChatRealtimeClient implements CommunityChatRealtimeClient {
  const _FakeCommunityChatRealtimeClient(this.events);

  final List<Map<String, Object?>> events;

  @override
  Stream<Map<String, Object?>> subscribe(String communityId) {
    return Stream.fromIterable(events);
  }

  @override
  Future<Map<String, Object?>> send(CommunityChatCommand command) {
    throw UnimplementedError();
  }
}
