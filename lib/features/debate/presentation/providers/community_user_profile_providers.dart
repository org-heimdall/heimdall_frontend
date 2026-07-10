import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_community_user_profile_repository.dart';
import '../../domain/entities/community_user_profile.dart';

final communityUserProfileRepositoryProvider =
    Provider<MockCommunityUserProfileRepository>((ref) {
      return MockCommunityUserProfileRepository();
    });

final communityUserProfileProvider =
    FutureProvider.family<CommunityUserProfile, String>((ref, userId) {
      final repository = ref.watch(communityUserProfileRepositoryProvider);
      return repository.getUserProfile(userId);
    });
