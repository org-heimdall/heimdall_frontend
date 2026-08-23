import '../entities/community.dart';

abstract interface class CommunityRepository {
  Future<List<Community>> fetchCommunities({
    CommunityCategory category = CommunityCategory.all,
    String query = '',
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

  Future<String> createAndStartDebate({
    required Community community,
    required String opponentMemberId,
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
