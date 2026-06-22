class CommunityChatMessage {
  const CommunityChatMessage({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.text,
    this.accentAvatar = false,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String text;
  final bool accentAvatar;
}

class CommunityOpeningStatementNotice {
  const CommunityOpeningStatementNotice({
    required this.authorId,
    required this.authorName,
  });

  final String authorId;
  final String authorName;
}

enum CommunityChatViewerRole {
  host,
  debater,
  member;

  bool get canWatchDebate => this == CommunityChatViewerRole.member;
}
