class DebateTurnCommandContext {
  const DebateTurnCommandContext({
    required this.speakerId,
    required this.speakerSide,
    required this.phase,
    required this.round,
  });

  final String speakerId;
  final String speakerSide;
  final String phase;
  final int round;
}

class DebateChatCurrentTurn {
  const DebateChatCurrentTurn({
    required this.phase,
    required this.round,
    required this.turnSide,
    required this.startedAt,
    required this.maxDurationSeconds,
    required this.maxTotalCharacters,
  });

  final String phase;
  final int round;
  final String turnSide;
  final DateTime startedAt;
  final int maxDurationSeconds;
  final int maxTotalCharacters;

  int preparationSecondsRemainingAt(DateTime now) {
    final remainingMilliseconds = startedAt.difference(now).inMilliseconds;
    if (remainingMilliseconds <= 0) return 0;
    return (remainingMilliseconds + 999) ~/ 1000;
  }
}

class DebateChatDraftMessage {
  const DebateChatDraftMessage({
    required this.id,
    required this.speakerId,
    required this.speakerSide,
    required this.content,
    required this.createdAt,
    this.clientMessageId,
  });

  final String id;
  final String? clientMessageId;
  final String speakerId;
  final String speakerSide;
  final String content;
  final DateTime createdAt;
}

class DebateFinalizedTurn {
  const DebateFinalizedTurn({
    required this.id,
    required this.speakerId,
    required this.speakerSide,
    required this.phase,
    required this.round,
    required this.sequence,
    required this.content,
    required this.createdAt,
    required this.likeCount,
    required this.dislikeCount,
  });

  final String id;
  final String speakerId;
  final String speakerSide;
  final String phase;
  final int round;
  final int sequence;
  final String content;
  final DateTime createdAt;
  final int likeCount;
  final int dislikeCount;
}

enum DebateTurnVoteType { like, dislike }

class DebateTurnVoteSummary {
  const DebateTurnVoteSummary({
    required this.turnId,
    required this.likeCount,
    required this.dislikeCount,
  });

  final String turnId;
  final int likeCount;
  final int dislikeCount;
}

class DebateSpeaker {
  const DebateSpeaker({
    required this.id,
    required this.displayName,
    required this.score,
    this.profileImageUrl,
    this.claim = '',
    this.reasons = const [],
  });

  final String id;
  final String displayName;
  final int score;
  final String? profileImageUrl;
  final String claim;
  final List<String> reasons;
}

class DebateDetail {
  const DebateDetail({
    required this.id,
    required this.communityId,
    required this.status,
    required this.rebuttalQuestionRounds,
    required this.sideASpeaker,
    required this.sideBSpeaker,
    required this.viewerSide,
    required this.startedAt,
    required this.expiresAt,
    required this.judgingStartedAt,
  });

  static const judgeRetryStaleDuration = Duration(seconds: 185);

  final String id;
  final String communityId;
  final String status;
  final int rebuttalQuestionRounds;
  final DebateSpeaker sideASpeaker;
  final DebateSpeaker sideBSpeaker;
  final String? viewerSide;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final DateTime? judgingStartedAt;

  bool canRetryJudgeAt(DateTime now) {
    final startedAt = judgingStartedAt;
    return status == 'JUDGING' &&
        startedAt != null &&
        !now.isBefore(startedAt.add(judgeRetryStaleDuration));
  }
}

enum DebateChatRealtimeEventType {
  connectionRestored,
  messageAcknowledged,
  messageCreated,
  turnFinalized,
  debateEnded,
  error,
}

class DebateChatRealtimeEvent {
  const DebateChatRealtimeEvent({
    required this.id,
    required this.debateId,
    required this.type,
    this.commandId,
    this.clientMessageId,
    this.currentTurn,
    this.message,
    this.draftMessages = const [],
    this.errorMessage,
    this.endReason,
    this.status,
  });

  final String id;
  final String debateId;
  final DebateChatRealtimeEventType type;
  final String? commandId;
  final String? clientMessageId;
  final DebateChatCurrentTurn? currentTurn;
  final DebateChatDraftMessage? message;
  final List<DebateChatDraftMessage> draftMessages;
  final String? errorMessage;
  final String? endReason;
  final String? status;
}
