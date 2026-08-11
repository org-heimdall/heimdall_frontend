import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/mock_community_repository.dart';
import '../../domain/entities/community.dart';

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

final communityRepositoryProvider = Provider<MockCommunityRepository>((ref) {
  return MockCommunityRepository(dioProvider: () => ref.read(dioProvider));
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
