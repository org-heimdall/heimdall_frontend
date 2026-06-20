import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../features/debate/presentation/providers/community_providers.dart';
import '../features/debate/presentation/screens/create_community_screen.dart';
import '../features/debate/presentation/screens/community_detail_screen.dart';
import '../features/debate/presentation/screens/community_list_screen.dart';
import '../features/debate/presentation/screens/debate_result_screen.dart';
import '../features/debate/presentation/screens/debate_session_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final repository = ref.watch(communityRepositoryProvider);

  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const CommunityListScreen(),
      ),
      GoRoute(
        path: '/communities/new',
        builder: (context, state) => const CreateCommunityScreen(),
      ),
      GoRoute(
        path: '/communities/:id',
        builder: (context, state) {
          final community = repository.getCommunityById(
            state.pathParameters['id'] ?? '',
          );
          return community == null
              ? const _RouteNotFoundScreen()
              : CommunityDetailScreen(community: community);
        },
      ),
      GoRoute(
        path: '/communities/:id/debate',
        builder: (context, state) {
          final community = repository.getCommunityById(
            state.pathParameters['id'] ?? '',
          );
          return community == null
              ? const _RouteNotFoundScreen()
              : DebateSessionScreen(community: community);
        },
      ),
      GoRoute(
        path: '/communities/:id/debate/result',
        builder: (context, state) {
          final community = repository.getCommunityById(
            state.pathParameters['id'] ?? '',
          );
          return community == null
              ? const _RouteNotFoundScreen()
              : DebateResultScreen(
                  community: community,
                  result: repository.getResult(community),
                );
        },
      ),
    ],
  );
});

class _RouteNotFoundScreen extends StatelessWidget {
  const _RouteNotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          '커뮤니티를 찾을 수 없습니다.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      ),
    );
  }
}
