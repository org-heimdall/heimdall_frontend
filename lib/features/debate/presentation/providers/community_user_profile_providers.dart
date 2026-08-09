import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/community_user_profile_repository.dart';
import '../../domain/entities/community_user_profile.dart';

final communityUserProfileRepositoryProvider =
    Provider<CommunityUserProfileRepository>((ref) {
      return CommunityUserProfileRepository(ref.watch(dioProvider));
    });

final communityUserProfileProvider =
    FutureProvider.family<
      CommunityUserProfile,
      ({String communityId, String userId})
    >((ref, input) {
      final repository = ref.watch(communityUserProfileRepositoryProvider);
      return repository.getUserProfile(
        communityId: input.communityId,
        userId: input.userId,
      );
    });
