import '../../../../shared/chat/domain/chat_message.dart';

class CommunityOpinionMessage extends ChatMessage {
  const CommunityOpinionMessage({
    required super.id,
    required super.scopeId,
    required super.authorId,
    required super.authorName,
    required super.text,
    required super.createdAt,
    required this.claim,
    required this.reasons,
  });

  final String claim;
  final List<String> reasons;
}

class CommunityDebateResultMessage extends ChatMessage {
  const CommunityDebateResultMessage({
    required super.id,
    required super.scopeId,
    required super.authorId,
    required super.authorName,
    required super.text,
    required super.createdAt,
    required this.debateId,
    super.clientMessageId,
  });

  final String debateId;
}

class CommunityDebateForfeitMessage extends ChatMessage {
  const CommunityDebateForfeitMessage({
    required super.id,
    required super.scopeId,
    required super.authorId,
    required super.authorName,
    required super.text,
    required super.createdAt,
    super.clientMessageId,
  });
}

class CommunityOpinionNotice {
  const CommunityOpinionNotice({
    required this.id,
    required this.communityId,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.claim,
    required this.reasons,
  });

  final String id;
  final String communityId;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final String claim;
  final List<String> reasons;
}

class CommunityChatEvent {
  const CommunityChatEvent({
    required this.id,
    required this.communityId,
    required this.type,
    this.message,
    this.opinionNotice,
    this.debateId,
    this.sideASpeakerId,
    this.sideBSpeakerId,
    this.commandId,
    this.status,
    this.errorMessage,
  });

  final String id;
  final String communityId;
  final CommunityChatEventType type;
  final ChatMessage? message;
  final CommunityOpinionNotice? opinionNotice;
  final String? debateId;
  final String? sideASpeakerId;
  final String? sideBSpeakerId;
  final String? commandId;
  final String? status;
  final String? errorMessage;
}

class CommunityChatCommand {
  const CommunityChatCommand({
    required this.id,
    required this.communityId,
    required this.type,
    required this.sentAt,
    this.clientMessageId,
    this.payload = const {},
  });

  final String id;
  final String communityId;
  final CommunityChatCommandType type;
  final DateTime sentAt;
  final String? clientMessageId;
  final Map<String, Object?> payload;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'type': type.wireName,
      'communityId': communityId,
      if (clientMessageId != null) 'clientMessageId': clientMessageId,
      'payload': payload,
      'sentAt': sentAt.toIso8601String(),
    };
  }
}

enum CommunityChatViewerRole {
  host,
  debater,
  member;

  bool get canWatchDebate => this == CommunityChatViewerRole.member;
}

enum CommunityChatEventType {
  messageAcknowledged,
  messageCreated,
  messageUpdated,
  messageDeleted,
  opinionSubmitted,
  opinionAcknowledged,
  connectionRestored,
  debateStarted,
  debateEnded,
  error,
}

enum CommunityChatCommandType {
  messageSend('message.send'),
  typingStarted('typing.started'),
  typingStopped('typing.stopped'),
  opinionSubmit('opinion.submit');

  const CommunityChatCommandType(this.wireName);

  final String wireName;
}

class SendChatMessageRequest {
  const SendChatMessageRequest({
    required this.communityId,
    required this.authorId,
    required this.text,
    required this.clientMessageId,
  });

  final String communityId;
  final String authorId;
  final String text;
  final String clientMessageId;
}

class SaveCommunityOpinionRequest {
  const SaveCommunityOpinionRequest({
    required this.communityId,
    required this.claim,
    required this.reasons,
  });

  final String communityId;
  final String claim;
  final List<String> reasons;
}
