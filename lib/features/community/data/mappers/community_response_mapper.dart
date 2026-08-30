import '../../domain/entities/community.dart';
import '../../domain/entities/community_chat.dart';

class CommunityResponseMapper {
  const CommunityResponseMapper();

  Community mapCommunity(Map<String, dynamic> json) {
    final hostJson = json['host'];
    final hostName = hostJson is Map<String, dynamic>
        ? hostJson['displayName'] as String? ?? '호스트'
        : '호스트';
    final participantPreviews =
        (json['participantPreviews'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(
              (item) => CommunityParticipantPreview(
                id: item['id'] as String? ?? '',
                displayName: item['displayName'] as String? ?? '멤버',
                profileImageUrl: item['profileImageUrl'] as String?,
              ),
            )
            .where((item) => item.id.isNotEmpty)
            .toList() ??
        const [];
    final hostId = hostJson is Map<String, dynamic>
        ? hostJson['id'] as String?
        : null;
    final hostProfileImageUrl =
        (hostJson is Map<String, dynamic>
            ? hostJson['profileImageUrl'] as String?
            : null) ??
        (participantPreviews.where((item) => item.id == hostId).isEmpty
            ? null
            : participantPreviews
                  .where((item) => item.id == hostId)
                  .first
                  .profileImageUrl);

    return Community(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
      category: _communityCategory(json['category']),
      status: _communityStatus(json['status']),
      host: CommunityHost(
        id: hostJson is Map<String, dynamic> ? hostJson['id'] as String? : null,
        name: hostName,
        avatarColor: 0xFFC9D6FF,
        profileImageUrl: hostProfileImageUrl,
      ),
      rounds: (json['rounds'] as num?)?.toInt() ?? 1,
      observerCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      isPublic: json['isPublic'] as bool? ?? true,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      participantPreviews: participantPreviews,
      hostClaim: json['hostClaim'] as String? ?? '',
      hostReasons:
          (json['hostReasons'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
      isOwnedByCurrentUser: json['isOwnedByCurrentUser'] as bool? ?? false,
      isJoined: json['isJoined'] as bool? ?? false,
    );
  }

  List<Community> mapCommunities(List<dynamic> response) {
    return response
        .whereType<Map<String, dynamic>>()
        .map(mapCommunity)
        .toList();
  }

  List<CommunityMemberSummary> mapMembers(List<dynamic> response) {
    return response
        .whereType<Map<String, dynamic>>()
        .map(
          (json) => CommunityMemberSummary(
            id: json['id'] as String,
            displayName: json['displayName'] as String? ?? '멤버',
            profileImageUrl: json['profileImageUrl'] as String?,
            role: json['role'] as String? ?? 'MEMBER',
            debateIntent: json['debateIntent'] as String? ?? 'OPEN_TO_DEBATE',
            joinedAt:
                DateTime.tryParse(json['joinedAt'] as String? ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0),
          ),
        )
        .toList();
  }

  String mapCreatedDebateId(Map<String, dynamic> response) {
    final debateId = response['id'] as String?;
    if (debateId == null || debateId.isEmpty) {
      throw const FormatException('생성된 토론 ID가 없습니다.');
    }
    return debateId;
  }

  CommunityDebateInvitation mapDebateInvitation(Map<String, dynamic> json) {
    return CommunityDebateInvitation(
      id: json['id'] as String,
      communityId: json['communityId'] as String,
      hostMemberId: json['hostMemberId'] as String,
      hostName: json['hostName'] as String,
      opponentMemberId: json['opponentMemberId'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  CommunityCategory _communityCategory(Object? value) {
    final normalized = value?.toString().toLowerCase();
    return CommunityCategory.values.firstWhere(
      (category) => category.name == normalized,
      orElse: () => CommunityCategory.etc,
    );
  }

  CommunityStatus _communityStatus(Object? raw) {
    return switch (raw) {
      'ACTIVE' => CommunityStatus.live,
      'CLOSED' => CommunityStatus.finished,
      _ => CommunityStatus.waiting,
    };
  }
}
