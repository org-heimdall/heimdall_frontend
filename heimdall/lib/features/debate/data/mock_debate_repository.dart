import '../domain/entities/debate_result.dart';
import '../domain/entities/debate_room.dart';
import '../domain/entities/debate_turn.dart';

class MockDebateRepository {
  final List<DebateRoom> _rooms = [
    DebateRoom(
      id: 'room-1',
      title: '국밥 티어 순대국 VS 뼈해장국',
      topic: '한국식 국밥 메뉴 중 더 완성도 높은 한 끼는 무엇인가?',
      category: DebateCategory.daily,
      status: DebateStatus.live,
      participants: const [
        DebateParticipant(
          name: '현우',
          side: DebateSide.pro,
          avatarColor: 0xFFC6F9FF,
        ),
        DebateParticipant(
          name: '민서',
          side: DebateSide.con,
          avatarColor: 0xFFFF5D5D,
        ),
      ],
      rounds: 3,
      elapsedMinutes: 18,
      audienceCount: 4,
      isPublic: true,
      createdAt: DateTime(2026, 6, 17, 20, 10),
    ),
    DebateRoom(
      id: 'room-2',
      title: '토마토맛 토 VS 토맛 토마토',
      topic: '언어 유희형 선택지에서 더 납득 가능한 선택은 무엇인가?',
      category: DebateCategory.comedy,
      status: DebateStatus.live,
      participants: const [
        DebateParticipant(
          name: '지안',
          side: DebateSide.pro,
          avatarColor: 0xFFC6F9FF,
        ),
        DebateParticipant(
          name: '도윤',
          side: DebateSide.con,
          avatarColor: 0xFF1FC7FF,
        ),
      ],
      rounds: 2,
      elapsedMinutes: 18,
      audienceCount: 12,
      isPublic: true,
      createdAt: DateTime(2026, 6, 17, 19, 50),
    ),
    DebateRoom(
      id: 'room-3',
      title: '축구 VS 농구 무엇이 더 힘든가?',
      topic: '지구력, 순발력, 전술 복잡도를 기준으로 비교한다.',
      category: DebateCategory.sports,
      status: DebateStatus.waiting,
      participants: const [
        DebateParticipant(
          name: '서준',
          side: DebateSide.pro,
          avatarColor: 0xFF818E99,
        ),
      ],
      rounds: 3,
      elapsedMinutes: 0,
      audienceCount: 1,
      isPublic: true,
      createdAt: DateTime(2026, 6, 17, 19, 30),
    ),
    DebateRoom(
      id: 'room-4',
      title: '매트릭스 빨간약을 먹을 것인가 파란약을 먹을 것인가',
      topic: '불편한 진실과 안정적인 환상 중 무엇을 택해야 하는가?',
      category: DebateCategory.culture,
      status: DebateStatus.waiting,
      participants: const [
        DebateParticipant(
          name: '유나',
          side: DebateSide.con,
          avatarColor: 0xFF818E99,
        ),
      ],
      rounds: 2,
      elapsedMinutes: 0,
      audienceCount: 1,
      isPublic: true,
      createdAt: DateTime(2026, 6, 17, 18, 40),
    ),
    DebateRoom(
      id: 'room-5',
      title: '남사친 여사친은 존재하는가',
      topic: '친밀한 이성 친구 관계는 안정적으로 지속될 수 있는가?',
      category: DebateCategory.society,
      status: DebateStatus.live,
      participants: const [
        DebateParticipant(
          name: '태오',
          side: DebateSide.pro,
          avatarColor: 0xFFC6F9FF,
        ),
        DebateParticipant(
          name: '하린',
          side: DebateSide.con,
          avatarColor: 0xFF2E6BFF,
        ),
      ],
      rounds: 3,
      elapsedMinutes: 18,
      audienceCount: 8,
      isPublic: true,
      createdAt: DateTime(2026, 6, 17, 18, 10),
    ),
  ];

  List<DebateRoom> getRooms({
    DebateCategory category = DebateCategory.all,
    String query = '',
  }) {
    return _rooms.where((room) {
      final matchesCategory =
          category == DebateCategory.all || room.category == category;
      final normalizedQuery = query.trim().toLowerCase();
      final matchesQuery =
          normalizedQuery.isEmpty ||
          room.title.toLowerCase().contains(normalizedQuery) ||
          room.topic.toLowerCase().contains(normalizedQuery);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  DebateRoom? getRoomById(String id) {
    for (final room in _rooms) {
      if (room.id == id) {
        return room;
      }
    }
    return null;
  }

  DebateRoom createRoom({
    required String title,
    required String topic,
    required DebateCategory category,
    required DebateSide side,
    required int rounds,
    required bool isPublic,
  }) {
    final room = DebateRoom(
      id: 'room-${_rooms.length + 1}',
      title: title,
      topic: topic,
      category: category,
      status: DebateStatus.waiting,
      participants: [
        DebateParticipant(name: '나', side: side, avatarColor: 0xFF5659FF),
      ],
      rounds: rounds,
      elapsedMinutes: 0,
      audienceCount: 1,
      isPublic: isPublic,
      createdAt: DateTime.now(),
    );
    _rooms.insert(0, room);
    return room;
  }

  List<DebateTurn> getTurns(DebateRoom room) {
    final pro = room.participants.firstWhere(
      (participant) => participant.side == DebateSide.pro,
      orElse: () => const DebateParticipant(
        name: '찬성측',
        side: DebateSide.pro,
        avatarColor: 0xFF5659FF,
      ),
    );
    final con = room.participants.firstWhere(
      (participant) => participant.side == DebateSide.con,
      orElse: () => const DebateParticipant(
        name: '반대측',
        side: DebateSide.con,
        avatarColor: 0xFFFF7B72,
      ),
    );

    return [
      DebateTurn(
        stage: DebateStage.opening,
        side: DebateSide.pro,
        speaker: pro.name,
        content: '핵심 기준은 지속 가능성입니다. 이 선택지는 더 넓은 상황에서 일관된 만족을 제공합니다.',
        remainingSeconds: 0,
      ),
      DebateTurn(
        stage: DebateStage.opening,
        side: DebateSide.con,
        speaker: con.name,
        content: '반대합니다. 단기 만족보다 실제 비용과 검증 가능한 근거를 우선해야 합니다.',
        remainingSeconds: 0,
      ),
      DebateTurn(
        stage: DebateStage.rebuttalQuestion,
        side: DebateSide.pro,
        speaker: pro.name,
        content: '상대 주장은 비용을 강조하지만, 사용자의 체감 가치와 반복 선택 가능성을 설명하지 못합니다.',
        remainingSeconds: 114,
      ),
    ];
  }

  DebateResult getResult(DebateRoom room) {
    return const DebateResult(
      winner: DebateSide.pro,
      scores: [
        DebateScore(
          side: DebateSide.pro,
          score: 87,
          summary: '주장과 근거의 연결이 안정적입니다.',
        ),
        DebateScore(
          side: DebateSide.con,
          score: 78,
          summary: '반박은 명확하지만 대안 제시가 부족합니다.',
        ),
      ],
      reason: '찬성 측은 핵심 기준을 먼저 정의하고 이후 발언에서 같은 기준으로 상대 주장을 반박했습니다.',
      strengths: ['논점 이탈 없이 기준을 유지했습니다.', '상대 발언의 약한 전제를 직접 반박했습니다.'],
      weaknesses: ['일부 근거는 수치나 사례가 부족했습니다.', '질문 이후 재반박이 더 구체적일 필요가 있습니다.'],
      factChecks: [
        FactCheckResult(
          claim: '장기 만족도가 더 높다',
          verdict: '검증 필요: 출처가 제시되지 않았습니다.',
        ),
      ],
      feedback: '다음 토론에서는 핵심 주장마다 하나 이상의 구체적 사례나 수치를 붙이면 설득력이 올라갑니다.',
    );
  }
}
