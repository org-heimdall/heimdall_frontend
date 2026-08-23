enum CommunityCategory {
  all('전체'),
  politics('정치'),
  economy('경제'),
  society('사회'),
  culture('문화'),
  sports('스포츠'),
  daily('일상'),
  comedy('코미디'),
  etc('기타');

  const CommunityCategory(this.label);

  final String label;
}

enum CommunityStatus {
  waiting('준비 중'),
  live('토론 중'),
  analyzing('분석 중'),
  finished('종료'),
  canceled('취소');

  const CommunityStatus(this.label);

  final String label;
}

int debateDurationMinutesForRounds(int rounds) => rounds * 6 + 4;

class CommunityHost {
  const CommunityHost({required this.name, required this.avatarColor, this.id});

  final String? id;
  final String name;
  final int avatarColor;
}

class CommunityMemberSummary {
  const CommunityMemberSummary({
    required this.id,
    required this.displayName,
    required this.role,
    required this.debateIntent,
    required this.joinedAt,
    this.profileImageUrl,
  });

  final String id;
  final String displayName;
  final String? profileImageUrl;
  final String role;
  final String debateIntent;
  final DateTime joinedAt;

  bool get isHost => role == 'HOST';
  bool get wantsToDebate => debateIntent == 'OPEN_TO_DEBATE';
}

class Community {
  const Community({
    required this.id,
    required this.title,
    required this.topic,
    required this.category,
    required this.status,
    required this.host,
    required this.rounds,
    required this.observerCount,
    required this.isPublic,
    required this.createdAt,
    this.hostClaim = '',
    this.hostReasons = const [],
    this.isOwnedByCurrentUser = false,
    this.isJoined = false,
  });

  final String id;
  final String title;
  final String topic;
  final CommunityCategory category;
  final CommunityStatus status;
  final CommunityHost host;
  final int rounds;
  final int observerCount;
  final bool isPublic;
  final DateTime createdAt;
  final String hostClaim;
  final List<String> hostReasons;
  final bool isOwnedByCurrentUser;
  final bool isJoined;

  bool get isJoinable => status == CommunityStatus.waiting;
  int get debateDurationMinutes => debateDurationMinutesForRounds(rounds);
}
