import '../../domain/entities/community.dart';
import '../../domain/entities/community_chat.dart';
import '../../domain/repositories/community_repository.dart';
import '../mappers/community_response_mapper.dart';
import '../remote/community_remote_data_source.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  CommunityRepositoryImpl(this._remoteDataSource, this._mapper);

  final CommunityRemoteDataSource _remoteDataSource;
  final CommunityResponseMapper _mapper;
  final List<Community> _communities = [];

  @override
  Future<List<Community>> fetchCommunities({
    CommunityCategory category = CommunityCategory.all,
    String query = '',
    CommunitySortOrder sortOrder = CommunitySortOrder.recommended,
  }) async {
    final response = await _remoteDataSource.fetchCommunities();
    _communities
      ..clear()
      ..addAll(_mapper.mapCommunities(response));

    final normalizedQuery = query.trim().toLowerCase();
    final filtered = _communities.where((community) {
      final matchesCategory =
          category == CommunityCategory.all || community.category == category;
      final matchesQuery =
          normalizedQuery.isEmpty ||
          community.title.toLowerCase().contains(normalizedQuery) ||
          community.topic.toLowerCase().contains(normalizedQuery);
      return matchesCategory && matchesQuery;
    }).toList();
    filtered.sort(switch (sortOrder) {
      CommunitySortOrder.recommended => (left, right) {
        final memberCountOrder = right.observerCount.compareTo(
          left.observerCount,
        );
        return memberCountOrder != 0
            ? memberCountOrder
            : right.createdAt.compareTo(left.createdAt);
      },
      CommunitySortOrder.latest => (left, right) => right.createdAt.compareTo(
        left.createdAt,
      ),
    });
    return filtered;
  }

  @override
  Future<Community> fetchCommunityById(String id) async {
    final response = await _remoteDataSource.fetchCommunity(id);
    final community = _mapper.mapCommunity(response);
    _communities.removeWhere((item) => item.id == community.id);
    _communities.add(community);
    return community;
  }

  @override
  Future<Community> createCommunity({
    required String title,
    required String topic,
    required CommunityCategory category,
    required int rounds,
    required bool isPublic,
    required String hostClaim,
    required List<String> hostReasons,
  }) async {
    final response = await _remoteDataSource.createCommunity({
      'title': title,
      'topic': topic,
      'category': category.name.toUpperCase(),
      'rounds': rounds,
      'isPublic': isPublic,
      'hostClaim': hostClaim,
      'hostReasons': hostReasons,
    });
    final community = _mapper.mapCommunity(response);
    _communities.insert(0, community);
    return community;
  }

  @override
  Future<CommunityDebateInvitation> requestDebate({
    required Community community,
    required String opponentMemberId,
  }) async {
    final hostMemberId = community.host.id;
    if (hostMemberId == null || hostMemberId.isEmpty) {
      throw StateError('커뮤니티 방장 ID가 없습니다.');
    }
    if (hostMemberId == opponentMemberId) {
      throw StateError('방장 본인과는 토론을 시작할 수 없습니다.');
    }
    final response = await _remoteDataSource.startDebate(
      communityId: community.id,
      opponentMemberId: opponentMemberId,
    );
    return _mapper.mapDebateInvitation(response);
  }

  @override
  Future<String> acceptDebateInvitation({
    required String communityId,
    required String invitationId,
  }) async {
    final response = await _remoteDataSource.acceptDebateInvitation(
      communityId: communityId,
      invitationId: invitationId,
    );
    return _mapper.mapCreatedDebateId(response);
  }

  @override
  Future<void> rejectDebateInvitation({
    required String communityId,
    required String invitationId,
  }) {
    return _remoteDataSource.rejectDebateInvitation(
      communityId: communityId,
      invitationId: invitationId,
    );
  }

  @override
  Future<void> joinCommunity(String communityId) {
    return _remoteDataSource.joinCommunity(communityId);
  }

  @override
  Future<void> leaveCommunity(String communityId) {
    return _remoteDataSource.leaveCommunity(communityId);
  }

  @override
  Future<List<CommunityMemberSummary>> fetchCommunityMembers(
    String communityId,
  ) async {
    final response = await _remoteDataSource.fetchCommunityMembers(communityId);
    return _mapper.mapMembers(response);
  }

  @override
  Future<void> updateCommunityDebateIntent({
    required String communityId,
    required bool wantsToDebate,
  }) {
    return _remoteDataSource.updateDebateIntent(
      communityId: communityId,
      wantsToDebate: wantsToDebate,
    );
  }
}
