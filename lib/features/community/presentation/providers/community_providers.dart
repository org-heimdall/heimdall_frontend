import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/mappers/community_response_mapper.dart';
import '../../data/remote/community_remote_data_source.dart';
import '../../data/repositories/community_repository_impl.dart';
import '../../domain/entities/community.dart';
import '../../domain/repositories/community_repository.dart';

class CommunityFilter {
  const CommunityFilter({
    this.category = CommunityCategory.all,
    this.query = '',
  });

  final CommunityCategory category;
  final String query;

  CommunityFilter copyWith({CommunityCategory? category, String? query}) {
    return CommunityFilter(
      category: category ?? this.category,
      query: query ?? this.query,
    );
  }
}

final communityRemoteDataSourceProvider = Provider<CommunityRemoteDataSource>((
  ref,
) {
  return CommunityRemoteDataSource(ref.watch(dioProvider));
});

final communityResponseMapperProvider = Provider<CommunityResponseMapper>((
  ref,
) {
  return const CommunityResponseMapper();
});

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepositoryImpl(
    ref.watch(communityRemoteDataSourceProvider),
    ref.watch(communityResponseMapperProvider),
  );
});

class CommunityFilterNotifier extends Notifier<CommunityFilter> {
  @override
  CommunityFilter build() {
    return const CommunityFilter();
  }

  void setCategory(CommunityCategory category) {
    state = state.copyWith(category: category);
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void reset() {
    state = const CommunityFilter();
  }
}

final communityFilterProvider =
    NotifierProvider<CommunityFilterNotifier, CommunityFilter>(
      CommunityFilterNotifier.new,
    );

final communitiesProvider = FutureProvider<List<Community>>((ref) {
  final repository = ref.watch(communityRepositoryProvider);
  final filter = ref.watch(communityFilterProvider);
  return repository.fetchCommunities(
    category: filter.category,
    query: filter.query,
  );
});

final communityByIdProvider = FutureProvider.autoDispose
    .family<Community, String>(
      (ref, communityId) => ref
          .watch(communityRepositoryProvider)
          .fetchCommunityById(communityId),
    );

final communityMembersProvider =
    FutureProvider.family<List<CommunityMemberSummary>, String>(
      (ref, communityId) => ref
          .watch(communityRepositoryProvider)
          .fetchCommunityMembers(communityId),
    );

class EnteredCommunityNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    return const {};
  }

  void markEntered(String communityId) {
    state = {...state, communityId};
  }

  void markLeft(String communityId) {
    state = {...state}..remove(communityId);
  }
}

final enteredCommunityProvider =
    NotifierProvider<EnteredCommunityNotifier, Set<String>>(
      EnteredCommunityNotifier.new,
    );
