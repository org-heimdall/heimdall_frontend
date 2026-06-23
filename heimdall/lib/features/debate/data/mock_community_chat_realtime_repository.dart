import '../domain/entities/community_chat.dart';
import '../domain/repositories/community_chat_realtime_repository.dart';
import 'community_chat_realtime_client.dart';

class MockCommunityChatRealtimeRepository
    implements CommunityChatRealtimeRepository {
  const MockCommunityChatRealtimeRepository(this.client);

  final CommunityChatRealtimeClient client;

  @override
  Stream<CommunityChatEvent> watchEvents(String communityId) {
    // client의 raw JSON stream을 화면이 이해하는 domain event로 변환한다.
    return client.subscribe(communityId).map(_parseEvent);
  }

  CommunityChatEvent _parseEvent(Map<String, Object?> raw) {
    // 서버 event type별로 필요한 payload를 골라 domain model을 만든다.
    final type = raw['type'] as String?;
    final messageRaw = raw['message'] as Map<String, Object?>?;

    if (type == 'message.created' && messageRaw != null) {
      return CommunityChatEvent(
        id: raw['id'] as String,
        communityId: raw['communityId'] as String,
        type: CommunityChatEventType.messageCreated,
        message: _parseMessage(messageRaw),
      );
    }

    if (type == 'opening_statement.created') {
      final notice = _parseOpeningStatementNotice(raw);
      return CommunityChatEvent(
        id: raw['id'] as String,
        communityId: raw['communityId'] as String,
        type: CommunityChatEventType.openingStatementCreated,
        message: CommunityChatMessage(
          id: notice.id,
          communityId: notice.communityId,
          authorId: 'system',
          authorName: 'System',
          text: '${notice.authorName} 님이 기조 발언을 작성했습니다.',
          relatedUserId: notice.authorId,
          type: CommunityChatMessageType.openingStatementNotice,
          createdAt: notice.createdAt,
        ),
        openingStatementNotice: notice,
      );
    }

    throw UnsupportedError('Unsupported community chat event: $type');
  }

  CommunityChatMessage _parseMessage(Map<String, Object?> raw) {
    // message.created/updated payload를 채팅 말풍선 모델로 변환한다.
    return CommunityChatMessage(
      id: raw['id'] as String,
      communityId: raw['communityId'] as String,
      clientMessageId: raw['clientMessageId'] as String?,
      authorId: raw['authorId'] as String,
      authorName: raw['authorName'] as String,
      text: raw['text'] as String,
      createdAt: DateTime.parse(raw['createdAt'] as String),
    );
  }

  CommunityOpeningStatementNotice _parseOpeningStatementNotice(
    Map<String, Object?> raw,
  ) {
    // 기조발언 이벤트는 채팅 사이에 들어가는 시스템 메시지의 원본 데이터다.
    final noticeRaw = raw['notice'] as Map<String, Object?>? ?? raw;

    return CommunityOpeningStatementNotice(
      id: raw['id'] as String,
      communityId: raw['communityId'] as String,
      authorId: noticeRaw['authorId'] as String,
      authorName: noticeRaw['authorName'] as String,
      createdAt: DateTime.parse(noticeRaw['createdAt'] as String),
    );
  }
}
