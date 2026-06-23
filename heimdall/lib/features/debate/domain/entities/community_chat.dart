class CommunityChatMessage {
  const CommunityChatMessage({
    required this.id,
    required this.communityId,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.createdAt,
    this.relatedUserId,
    this.clientMessageId,
    this.type = CommunityChatMessageType.text,
    this.deliveryStatus = CommunityChatMessageDeliveryStatus.sent,
    this.accentAvatar = false,
  });

  final String id;
  final String communityId;
  final String? clientMessageId;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime createdAt;
  final String? relatedUserId;
  final CommunityChatMessageType type;
  final CommunityChatMessageDeliveryStatus deliveryStatus;
  final bool accentAvatar;

  CommunityChatMessage copyWith({
    String? id,
    String? communityId,
    String? clientMessageId,
    String? authorId,
    String? authorName,
    String? text,
    DateTime? createdAt,
    String? relatedUserId,
    CommunityChatMessageType? type,
    CommunityChatMessageDeliveryStatus? deliveryStatus,
    bool? accentAvatar,
  }) {
    return CommunityChatMessage(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      clientMessageId: clientMessageId ?? this.clientMessageId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      relatedUserId: relatedUserId ?? this.relatedUserId,
      type: type ?? this.type,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      accentAvatar: accentAvatar ?? this.accentAvatar,
    );
  }
}

class CommunityOpeningStatementNotice {
  const CommunityOpeningStatementNotice({
    required this.id,
    required this.communityId,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
  });

  final String id;
  final String communityId;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
}

class CommunityChatEvent {
  const CommunityChatEvent({
    required this.id,
    required this.communityId,
    required this.type,
    this.message,
    this.openingStatementNotice,
  });

  final String id;
  final String communityId;
  final CommunityChatEventType type;
  final CommunityChatMessage? message;
  final CommunityOpeningStatementNotice? openingStatementNotice;
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

enum CommunityChatMessageType { text, system, openingStatementNotice }

enum CommunityChatMessageDeliveryStatus { pending, sent, failed }

enum CommunityChatEventType {
  messageCreated,
  messageUpdated,
  messageDeleted,
  openingStatementCreated,
  connectionRestored,
}

enum CommunityChatCommandType {
  messageSend('message.send'),
  typingStarted('typing.started'),
  typingStopped('typing.stopped'),
  openingStatementSubmit('opening_statement.submit');

  const CommunityChatCommandType(this.wireName);

  final String wireName;
}

class SendCommunityChatMessageRequest {
  const SendCommunityChatMessageRequest({
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
