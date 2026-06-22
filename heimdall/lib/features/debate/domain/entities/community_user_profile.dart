class CommunityUserProfile {
  const CommunityUserProfile({
    required this.userId,
    required this.userName,
    required this.score,
    required this.claim,
    required this.reasons,
  });

  final String userId;
  final String userName;
  final int score;
  final String claim;
  final List<String> reasons;
}
