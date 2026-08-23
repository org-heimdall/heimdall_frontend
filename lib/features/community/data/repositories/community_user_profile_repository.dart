import 'package:dio/dio.dart';

import '../../domain/entities/community_user_profile.dart';

class CommunityUserProfileRepository {
  const CommunityUserProfileRepository(this.dio);

  final Dio dio;

  Future<CommunityUserProfile> getUserProfile({
    required String communityId,
    required String userId,
  }) async {
    final responses = await Future.wait([
      dio.get<Map<String, dynamic>>('/members/$userId'),
      dio.get<List<dynamic>>('/communities/$communityId/opinions'),
    ]);
    final member = responses[0].data as Map<String, dynamic>?;
    final opinions = responses[1].data as List<dynamic>? ?? const [];
    if (member == null) {
      throw StateError('Member response is empty: $userId');
    }

    Map<String, dynamic>? opinion;
    for (final item in opinions.whereType<Map<String, dynamic>>()) {
      if (item['authorId'] == userId) {
        opinion = item;
        break;
      }
    }

    return CommunityUserProfile(
      userId: member['id'] as String,
      userName: member['displayName'] as String,
      score: (member['score'] as num?)?.toInt() ?? 0,
      claim: opinion?['claim'] as String? ?? '등록된 기조 발언이 없습니다.',
      reasons:
          (opinion?['reasons'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
      profileImageUrl: member['profileImageUrl'] as String?,
    );
  }
}
