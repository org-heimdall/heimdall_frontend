import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../features/debate/presentation/providers/community_providers.dart';
import '../features/debate/domain/entities/community.dart';
import '../features/debate/domain/entities/community_chat.dart';
import '../features/debate/presentation/screens/create_community_screen.dart';
import '../features/debate/presentation/screens/community_detail_screen.dart';
import '../features/debate/presentation/screens/community_list_screen.dart';
import '../features/debate/presentation/screens/debate_session_screen.dart';
import '../features/debate/presentation/screens/debate_result_screen.dart';
import '../features/debate/presentation/screens/community_chat_screen.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/screens/auth_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final repository = ref.watch(communityRepositoryProvider);
  final auth = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';
      if (auth.isLoading) {
        if (isAuthRoute) return null;
        return state.matchedLocation == '/splash' ? null : '/splash';
      }
      final isAuthenticated = auth.value != null;

      if (!isAuthenticated && !isAuthRoute) return '/login';
      if (isAuthenticated && isAuthRoute) return '/';
      if (isAuthenticated && state.matchedLocation == '/splash') return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const AuthScreen.login(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const AuthScreen.signUp(),
      ),
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
        path: '/communities/:id/chat',
        builder: (context, state) {
          final community = repository.getCommunityById(
            state.pathParameters['id'] ?? '',
          );
          return community == null
              ? const _RouteNotFoundScreen()
              : CommunityChatScreen(
                  community: community,
                  viewerRole: _chatViewerRoleFor(state, community),
                );
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
              : DebateSessionScreen(
                  community: community,
                  debateId:
                      state.uri.queryParameters['debateId'] ?? community.id,
                );
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
              : DebateResultApiScreen(
                  community: community,
                  debateId:
                      state.uri.queryParameters['debateId'] ?? community.id,
                );
        },
      ),
    ],
  );
});

CommunityChatViewerRole _chatViewerRoleFor(
  GoRouterState state,
  Community community,
) {
  final role = state.uri.queryParameters['role'];
  if (role == 'host') {
    return CommunityChatViewerRole.host;
  }
  if (role == 'debater') {
    return CommunityChatViewerRole.debater;
  }
  return community.isOwnedByCurrentUser
      ? CommunityChatViewerRole.host
      : CommunityChatViewerRole.member;
}

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
