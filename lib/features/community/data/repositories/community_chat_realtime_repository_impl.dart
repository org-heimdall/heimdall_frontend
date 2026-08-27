import '../../domain/entities/community_chat.dart';
import '../../domain/repositories/community_chat_realtime_repository.dart';
import '../mappers/community_chat_response_mapper.dart';
import '../mappers/community_response_mapper.dart';
import '../realtime/community_chat_realtime_client.dart';

class CommunityChatRealtimeRepositoryImpl
    implements CommunityChatRealtimeRepository {
  const CommunityChatRealtimeRepositoryImpl(
    this.client, [
    this.mapper = const CommunityChatResponseMapper(),
  ]);

  final CommunityChatRealtimeClient client;
  final CommunityChatResponseMapper mapper;

  @override
  Stream<CommunityChatEvent> watchEvents(String communityId) {
    // client의 raw JSON stream을 화면이 이해하는 domain event로 변환한다.
    return client.subscribe(communityId).map(_parseEvent);
  }

  CommunityChatEvent _parseEvent(Map<String, Object?> raw) {
    // 서버 event type별로 필요한 payload를 골라 domain model을 만든다.
    final type = raw['type'] as String?;
    final messageValue = raw['message'];
    final messageRaw = messageValue is Map<String, Object?>
        ? messageValue
        : null;

    if (type == 'community.message.ack' && messageRaw != null) {
      return CommunityChatEvent(
        id: raw['id'] as String,
        communityId: raw['communityId'] as String,
        type: CommunityChatEventType.messageAcknowledged,
        commandId: raw['commandId'] as String,
        status: raw['status'] as String,
        message: mapper.mapMessage(Map<String, dynamic>.from(messageRaw)),
      );
    }

    if (type == 'message.created' && messageRaw != null) {
      return CommunityChatEvent(
        id: raw['id'] as String,
        communityId: raw['communityId'] as String,
        type: CommunityChatEventType.messageCreated,
        message: mapper.mapMessage(Map<String, dynamic>.from(messageRaw)),
      );
    }

    if (type == 'opinion.submitted') {
      final notice = _parseOpinionNotice(raw);
      return CommunityChatEvent(
        id: raw['id'] as String,
        communityId: raw['communityId'] as String,
        type: CommunityChatEventType.opinionSubmitted,
        message: mapper.opinionMessageFromNotice(notice),
        opinionNotice: notice,
      );
    }

    if (type == 'community.opinion.ack') {
      final notice = _parseOpinionNotice(raw);
      return CommunityChatEvent(
        id: raw['id'] as String,
        communityId: raw['communityId'] as String,
        type: CommunityChatEventType.opinionAcknowledged,
        commandId: raw['commandId'] as String,
        status: raw['status'] as String,
        message: mapper.opinionMessageFromNotice(notice),
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

    if (type == 'debate.requested') {
      final invitationRaw = raw['invitation'];
      if (invitationRaw is! Map<String, Object?>) {
        throw const FormatException('토론 초대 이벤트가 올바르지 않습니다.');
      }
      return CommunityChatEvent(
        id: raw['id'] as String,
        communityId: raw['communityId'] as String,
        type: CommunityChatEventType.debateRequested,
        debateInvitation: const CommunityResponseMapper().mapDebateInvitation(
          Map<String, dynamic>.from(invitationRaw),
        ),
      );
    }

    if (type == 'debate.request.rejected') {
      return CommunityChatEvent(
        id: raw['id'] as String,
        communityId: raw['communityId'] as String,
        type: CommunityChatEventType.debateRequestRejected,
        invitationId: raw['invitationId'] as String?,
      );
    }

    if (type == 'debate.request.expired') {
      return CommunityChatEvent(
        id: raw['id'] as String,
        communityId: raw['communityId'] as String,
        type: CommunityChatEventType.debateRequestExpired,
        invitationId: raw['invitationId'] as String?,
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

    if (type == 'community.member.debate-intent.changed') {
      final member = raw['member'] as Map<String, Object?>?;
      if (member == null) {
        throw const FormatException('커뮤니티 멤버 상태 이벤트가 올바르지 않습니다.');
      }
      return CommunityChatEvent(
        id: raw['id'] as String,
        communityId: raw['communityId'] as String,
        type: CommunityChatEventType.memberDebateIntentChanged,
        memberId: member['id'] as String,
        memberName: member['displayName'] as String,
        debateIntent: member['debateIntent'] as String,
      );
    }

    if (type == 'error') {
      return CommunityChatEvent(
        id: raw['id'] as String,
        communityId: raw['communityId'] as String,
        type: CommunityChatEventType.error,
        commandId: raw['commandId'] as String?,
        errorMessage: raw['message'] as String?,
      );
    }

    throw UnsupportedError('Unsupported community chat event: $type');
  }

  CommunityOpinionNotice _parseOpinionNotice(Map<String, Object?> raw) {
    final noticeRaw = raw['opinion'] as Map<String, Object?>? ?? raw;
    return mapper.mapOpinionNotice(
      Map<String, dynamic>.from(noticeRaw),
      communityId: raw['communityId'] as String,
    );
  }
}
