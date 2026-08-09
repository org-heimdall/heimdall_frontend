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

    if (type == 'opinion.submitted') {
      final notice = _parseOpinionNotice(raw);
      return CommunityChatEvent(
        id: raw['id'] as String,
        communityId: raw['communityId'] as String,
        type: CommunityChatEventType.opinionSubmitted,
        message: CommunityChatMessage(
          id: notice.id,
          communityId: notice.communityId,
          authorId: notice.authorId,
          authorName: notice.authorName,
          text: '${notice.authorName} 님이 기조 발언을 작성했습니다.',
          relatedUserId: notice.authorId,
          opinionClaim: notice.claim,
          opinionReasons: notice.reasons,
          type: CommunityChatMessageType.opinionNotice,
          createdAt: notice.createdAt,
        ),
        opinionNotice: notice,
      );
    }

    if (type == 'debate.started') {
      final sideA = raw['sideASpeaker'] as Map<String, Object?>?;
      final sideB = raw['sideBSpeaker'] as Map<String, Object?>?;
      return CommunityChatEvent(
        id: raw['id'] as String,
        communityId: raw['communityId'] as String,
        type: CommunityChatEventType.debateStarted,
        debateId: raw['debateId'] as String,
        sideASpeakerId: sideA?['id'] as String?,
        sideBSpeakerId: sideB?['id'] as String?,
      );
    }

    if (type == 'debate.ended') {
      return CommunityChatEvent(
        id: raw['id'] as String,
        communityId: raw['communityId'] as String,
        type: CommunityChatEventType.debateEnded,
        debateId: raw['debateId'] as String,
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

  CommunityOpinionNotice _parseOpinionNotice(Map<String, Object?> raw) {
    final noticeRaw = raw['opinion'] as Map<String, Object?>? ?? raw;

    return CommunityOpinionNotice(
      id: noticeRaw['id'] as String,
      communityId: raw['communityId'] as String,
      authorId: noticeRaw['authorId'] as String,
      authorName: noticeRaw['authorName'] as String,
      createdAt: DateTime.parse(noticeRaw['createdAt'] as String),
      claim: noticeRaw['claim'] as String,
      reasons:
          (noticeRaw['reasons'] as List<Object?>?)
              ?.whereType<String>()
              .toList() ??
          const [],
    );
  }
}
