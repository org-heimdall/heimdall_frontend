enum DebateCategory {
  all('전체'),
  politics('정치'),
  economy('경제'),
  society('사회'),
  culture('문화'),
  sports('스포츠'),
  daily('일상'),
  comedy('코미디'),
  etc('기타');

  const DebateCategory(this.label);

  final String label;
}

enum DebateStatus {
  waiting('준비 중'),
  live('토론 중'),
  analyzing('분석 중'),
  finished('종료'),
  canceled('취소');

  const DebateStatus(this.label);

  final String label;
}

enum DebateSide {
  pro('찬성'),
  con('반대');

  const DebateSide(this.label);

  final String label;
}

class DebateParticipant {
  const DebateParticipant({
    required this.name,
    required this.side,
    required this.avatarColor,
  });

  final String name;
  final DebateSide side;
  final int avatarColor;
}

class DebateRoom {
  const DebateRoom({
    required this.id,
    required this.title,
    required this.topic,
    required this.category,
    required this.status,
    required this.participants,
    required this.rounds,
    required this.elapsedMinutes,
    required this.audienceCount,
    required this.isPublic,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String topic;
  final DebateCategory category;
  final DebateStatus status;
  final List<DebateParticipant> participants;
  final int rounds;
  final int elapsedMinutes;
  final int audienceCount;
  final bool isPublic;
  final DateTime createdAt;

  bool get isJoinable =>
      status == DebateStatus.waiting && participants.length < 2;
}
