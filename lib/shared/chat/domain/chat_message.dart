class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.scopeId,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.createdAt,
    this.clientMessageId,
    this.deliveryStatus = ChatMessageDeliveryStatus.sent,
    this.accentAvatar = false,
  });

  final String id;
  final String scopeId;
  final String? clientMessageId;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime createdAt;
  final ChatMessageDeliveryStatus deliveryStatus;
  final bool accentAvatar;

  ChatMessage copyWith({
    String? id,
    String? scopeId,
    String? clientMessageId,
    String? authorId,
    String? authorName,
    String? text,
    DateTime? createdAt,
    ChatMessageDeliveryStatus? deliveryStatus,
    bool? accentAvatar,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      scopeId: scopeId ?? this.scopeId,
      clientMessageId: clientMessageId ?? this.clientMessageId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      accentAvatar: accentAvatar ?? this.accentAvatar,
    );
  }
}

enum ChatMessageDeliveryStatus { pending, sent, failed }
