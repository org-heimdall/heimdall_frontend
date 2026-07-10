import '../domain/entities/community_user_profile.dart';

class MockCommunityUserProfileRepository {
  final Map<String, CommunityUserProfile> _profiles = const {
    'user-1': CommunityUserProfile(
      userId: 'user-1',
      userName: 'Username',
      score: 123,
      claim: '토맛 토마토가 토마토의 본질에 더 가깝다.',
      reasons: [
        '원재료의 맛과 향을 그대로 판단할 수 있다.',
        '토마토맛 토는 설명만으로도 정체성이 불분명하다.',
        '맛의 기준은 가공된 느낌보다 직접적인 식감에 있다.',
      ],
    ),
    'user-2': CommunityUserProfile(
      userId: 'user-2',
      userName: 'Username2',
      score: 128,
      claim: '토마토맛 토는 음식으로 설득력이 없다.',
      reasons: [
        '맛의 방향이 너무 작위적이라 호불호가 크게 갈린다.',
        '토마토의 산미와 토의 질감은 조화되기 어렵다.',
        '대중적인 선택으로 보기에는 진입장벽이 높다.',
      ],
    ),
    'user-3': CommunityUserProfile(
      userId: 'user-3',
      userName: 'Username3',
      score: 131,
      claim: '토맛 토마토는 토마토라는 이름에 더 충실한 선택이다.',
      reasons: [
        '토마토의 원래 맛을 기준으로 삼을 수 있어 판단이 명확하다.',
        '토마토맛 토는 음식과 맛의 경계가 모호해 설득력이 낮다.',
        '토론 상대도 반박할 수 있는 기준점이 토맛 토마토 쪽에 더 많다.',
      ],
    ),
    'me': CommunityUserProfile(
      userId: 'me',
      userName: '나',
      score: 120,
      claim: '토마토맛 토와 토맛 토마토를 기준에 따라 비교해야 한다.',
      reasons: [
        '맛, 재료, 경험을 분리하면 판단 기준이 명확해진다.',
        '선호보다 설득 가능한 근거를 먼저 봐야 한다.',
        '상대 주장에 맞춰 기준을 바꾸면 토론이 흐려진다.',
      ],
    ),
  };

  Future<CommunityUserProfile> getUserProfile(String userId) async {
    final profile = _profiles[userId];
    if (profile == null) {
      throw StateError('User profile not found: $userId');
    }

    return profile;
  }
}
