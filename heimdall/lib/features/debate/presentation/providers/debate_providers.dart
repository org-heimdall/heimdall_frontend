import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_debate_repository.dart';
import '../../domain/entities/debate_room.dart';

class DebateFilter {
  const DebateFilter({this.category = DebateCategory.all, this.query = ''});

  final DebateCategory category;
  final String query;

  DebateFilter copyWith({DebateCategory? category, String? query}) {
    return DebateFilter(
      category: category ?? this.category,
      query: query ?? this.query,
    );
  }
}

final debateRepositoryProvider = Provider<MockDebateRepository>((ref) {
  return MockDebateRepository();
});

class DebateFilterNotifier extends Notifier<DebateFilter> {
  @override
  DebateFilter build() {
    return const DebateFilter();
  }

  void setCategory(DebateCategory category) {
    state = state.copyWith(category: category);
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void reset() {
    state = const DebateFilter();
  }
}

final debateFilterProvider =
    NotifierProvider<DebateFilterNotifier, DebateFilter>(
      DebateFilterNotifier.new,
    );

final debateRoomsProvider = Provider<List<DebateRoom>>((ref) {
  final repository = ref.watch(debateRepositoryProvider);
  final filter = ref.watch(debateFilterProvider);
  return repository.getRooms(category: filter.category, query: filter.query);
});
