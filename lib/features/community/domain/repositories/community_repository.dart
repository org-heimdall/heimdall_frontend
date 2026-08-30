import '../entities/community.dart';
import '../entities/community_chat.dart';

abstract interface class CommunityRepository {
  Future<List<Community>> fetchCommunities({
    CommunityCategory category = CommunityCategory.all,
    String query = '',
    CommunitySortOrder sortOrder = CommunitySortOrder.recommended,
  });

  Future<Community> fetchCommunityById(String id);

  Future<Community> createCommunity({
    required String title,
    required String topic,
    required CommunityCategory category,
    required int rounds,
    required bool isPublic,
    required String hostClaim,
    required List<String> hostReasons,
  });

  Future<CommunityDebateInvitation> requestDebate({
    required Community community,
    required String opponentMemberId,
  });

  Future<String> acceptDebateInvitation({
    required String communityId,
    required String invitationId,
  });

  Future<void> rejectDebateInvitation({
    required String communityId,
    required String invitationId,
  });

  Future<void> joinCommunity(String communityId);

  Future<void> leaveCommunity(String communityId);

  Future<List<CommunityMemberSummary>> fetchCommunityMembers(
    String communityId,
  );

  Future<void> updateCommunityDebateIntent({
    required String communityId,
    required bool wantsToDebate,
  });
}
