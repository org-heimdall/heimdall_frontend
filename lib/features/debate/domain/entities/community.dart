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

enum DebateSide {
  pro('찬성'),
  con('반대');

  const DebateSide(this.label);

  final String label;
}

class Debater {
  const Debater({
    required this.name,
    required this.side,
    required this.avatarColor,
  });

  final String name;
  final DebateSide side;
  final int avatarColor;
}

class CommunityHost {
  const CommunityHost({required this.name, required this.avatarColor});

  final String name;
  final int avatarColor;
}

class Community {
  const Community({
    required this.id,
    required this.title,
    required this.topic,
    required this.category,
    required this.status,
    required this.host,
    required this.activeDebaters,
    required this.rounds,
    required this.elapsedMinutes,
    required this.observerCount,
    required this.isPublic,
    required this.createdAt,
    this.hostClaim = '',
    this.hostReasons = const [],
    this.isOwnedByCurrentUser = false,
  });

  final String id;
  final String title;
  final String topic;
  final CommunityCategory category;
  final CommunityStatus status;
  final CommunityHost host;
  final List<Debater> activeDebaters;
  final int rounds;
  final int elapsedMinutes;
  final int observerCount;
  final bool isPublic;
  final DateTime createdAt;
  final String hostClaim;
  final List<String> hostReasons;
  final bool isOwnedByCurrentUser;

  bool get isJoinable =>
      status == CommunityStatus.waiting && activeDebaters.length < 2;
}
