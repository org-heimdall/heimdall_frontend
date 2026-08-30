import '../../../../shared/chat/domain/chat_message.dart';
import '../../domain/entities/community_chat.dart';

class CommunityChatResponseMapper {
  const CommunityChatResponseMapper();

  ChatMessage mapMessage(Map<String, dynamic> json) {
    final common = (
      id: json['id'] as String,
      scopeId: json['communityId'] as String,
      clientMessageId: json['clientMessageId'] as String?,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

    return switch (json['messageType']) {
      'DEBATE_STARTED' => CommunityDebateStartedMessage(
        id: common.id,
        scopeId: common.scopeId,
        clientMessageId: common.clientMessageId,
        authorId: common.authorId,
        authorName: common.authorName,
        text: common.text,
        createdAt: common.createdAt,
      ),
      'DEBATE_RESULT' => CommunityDebateResultMessage(
        id: common.id,
        scopeId: common.scopeId,
        clientMessageId: common.clientMessageId,
        authorId: common.authorId,
        authorName: common.authorName,
        text: common.text,
        debateId: json['debateId'] as String,
        createdAt: common.createdAt,
      ),
      'DEBATE_FORFEIT' => CommunityDebateForfeitMessage(
        id: common.id,
        scopeId: common.scopeId,
        clientMessageId: common.clientMessageId,
        authorId: common.authorId,
        authorName: common.authorName,
        text: common.text,
        createdAt: common.createdAt,
      ),
      'DEBATE_TIMEOUT' => CommunityDebateTimeoutMessage(
        id: common.id,
        scopeId: common.scopeId,
        clientMessageId: common.clientMessageId,
        authorId: common.authorId,
        authorName: common.authorName,
        text: common.text,
        createdAt: common.createdAt,
      ),
      _ => ChatMessage(
        id: common.id,
        scopeId: common.scopeId,
        clientMessageId: common.clientMessageId,
        authorId: common.authorId,
        authorName: common.authorName,
        text: common.text,
        createdAt: common.createdAt,
      ),
    };
  }

  CommunityOpinionNotice mapOpinionNotice(
    Map<String, dynamic> json, {
    String? communityId,
  }) {
    return CommunityOpinionNotice(
      id: json['id'] as String,
      communityId: communityId ?? json['communityId'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      claim: json['claim'] as String,
      reasons:
          (json['reasons'] as List<dynamic>?)?.whereType<String>().toList() ??
          const [],
      action:
          json['action'] as String? ??
          _opinionAction(json['createdAt'], json['updatedAt']),
      updatedAt: json['updatedAt'] is String
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  String _opinionAction(Object? createdAt, Object? updatedAt) {
    if (createdAt is! String || updatedAt is! String) return 'CREATED';
    final created = DateTime.tryParse(createdAt);
    final updated = DateTime.tryParse(updatedAt);
    if (created == null || updated == null) return 'CREATED';
    return updated.difference(created).abs() > const Duration(seconds: 1)
        ? 'UPDATED'
        : 'CREATED';
  }

  CommunityOpinionMessage mapOpinionMessage(
    Map<String, dynamic> json, {
    String? communityId,
  }) {
    return opinionMessageFromNotice(
      mapOpinionNotice(json, communityId: communityId),
    );
  }

  CommunityOpinionMessage opinionMessageFromNotice(
    CommunityOpinionNotice notice,
  ) {
    return CommunityOpinionMessage(
      id: notice.id,
      scopeId: notice.communityId,
      authorId: notice.authorId,
      authorName: notice.authorName,
      text: notice.action == 'UPDATED'
          ? '${notice.authorName}님이 기조 발언을 수정했습니다.'
          : '${notice.authorName}님이 기조 발언을 작성했습니다.',
      claim: notice.claim,
      reasons: notice.reasons,
      createdAt: notice.action == 'UPDATED'
          ? (notice.updatedAt ?? notice.createdAt)
          : notice.createdAt,
    );
  }

  List<ChatMessage> mapMessages(List<dynamic> response) {
    return response.whereType<Map<String, dynamic>>().map(mapMessage).toList();
  }

  List<ChatMessage> mapOpinions(List<dynamic> response) {
    return response
        .whereType<Map<String, dynamic>>()
        .map(mapOpinionMessage)
        .toList();
  }
}
