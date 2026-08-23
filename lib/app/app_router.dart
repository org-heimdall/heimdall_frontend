import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../features/community/presentation/providers/community_providers.dart';
import '../features/community/domain/entities/community.dart';
import '../features/community/domain/entities/community_chat.dart';
import '../features/community/presentation/screens/create_community_screen.dart';
import '../features/community/presentation/screens/community_detail_screen.dart';
import '../features/community/presentation/screens/community_list_screen.dart';
import '../features/debate/presentation/screens/debate_session_screen.dart';
import '../features/debate/presentation/screens/debate_result_screen.dart';
import '../features/community/presentation/screens/community_chat_screen.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/screens/auth_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRouterRefreshNotifier();
  ref.listen(authControllerProvider, (previous, next) {
    refreshNotifier.refresh();
  });
  ref.onDispose(refreshNotifier.dispose);

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';
      final isSplashRoute = state.matchedLocation == '/splash';
      final savedRedirect = _safeAppRedirect(
        state.uri.queryParameters['redirect'],
      );

      if (auth.isLoading) {
        if (isAuthRoute) return null;
        if (isSplashRoute) return null;
        return _routeWithRedirect('/splash', state.uri.toString());
      }
      final isAuthenticated = auth.value != null;

      if (!isAuthenticated) {
        if (isAuthRoute) return null;
        final destination = isSplashRoute
            ? savedRedirect
            : _safeAppRedirect(state.uri.toString());
        return _routeWithRedirect('/login', destination);
      }

      if (isAuthRoute || isSplashRoute) {
        return savedRedirect ?? '/';
      }
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
        builder: (context, state) => AuthScreen.login(
          redirectLocation: _safeAppRedirect(
            state.uri.queryParameters['redirect'],
          ),
        ),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => AuthScreen.signUp(
          redirectLocation: _safeAppRedirect(
            state.uri.queryParameters['redirect'],
          ),
        ),
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
          final communityId = state.pathParameters['id'];
          if (communityId == null || communityId.isEmpty) {
            return const _RouteErrorScreen(message: '커뮤니티 ID가 없습니다.');
          }
          return _CommunityRouteScreen(
            communityId: communityId,
            builder: (community) => CommunityDetailScreen(community: community),
          );
        },
      ),
      GoRoute(
        path: '/communities/:id/chat',
        builder: (context, state) {
          final communityId = state.pathParameters['id'];
          if (communityId == null || communityId.isEmpty) {
            return const _RouteErrorScreen(message: '커뮤니티 ID가 없습니다.');
          }
          return _CommunityRouteScreen(
            communityId: communityId,
            builder: (community) => CommunityChatScreen(
              community: community,
              viewerRole: _chatViewerRoleFor(state, community),
            ),
          );
        },
      ),
      GoRoute(
        path: '/communities/:id/debate',
        builder: (context, state) {
          final communityId = state.pathParameters['id'];
          final debateId = state.uri.queryParameters['debateId'];
          if (communityId == null || communityId.isEmpty) {
            return const _RouteErrorScreen(message: '커뮤니티 ID가 없습니다.');
          }
          if (debateId == null || debateId.isEmpty) {
            return const _RouteErrorScreen(message: '토론 ID가 없습니다.');
          }
          return _CommunityRouteScreen(
            communityId: communityId,
            builder: (community) =>
                DebateSessionScreen(community: community, debateId: debateId),
          );
        },
      ),
      GoRoute(
        path: '/communities/:id/debate/result',
        builder: (context, state) {
          final communityId = state.pathParameters['id'];
          final debateId = state.uri.queryParameters['debateId'];
          if (communityId == null || communityId.isEmpty) {
            return const _RouteErrorScreen(message: '커뮤니티 ID가 없습니다.');
          }
          if (debateId == null || debateId.isEmpty) {
            return const _RouteErrorScreen(message: '토론 ID가 없습니다.');
          }
          return _CommunityRouteScreen(
            communityId: communityId,
            builder: (community) =>
                DebateResultApiScreen(community: community, debateId: debateId),
          );
        },
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class _AuthRouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

String _routeWithRedirect(String route, String? redirect) {
  final safeRedirect = _safeAppRedirect(redirect);
  return Uri(
    path: route,
    queryParameters: safeRedirect == null
        ? null
        : <String, String>{'redirect': safeRedirect},
  ).toString();
}

String? _safeAppRedirect(String? value) {
  if (value == null || value.isEmpty) return null;
  final uri = Uri.tryParse(value);
  if (uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      !uri.path.startsWith('/') ||
      uri.path.startsWith('//')) {
    return null;
  }
  if (uri.path == '/login' || uri.path == '/signup' || uri.path == '/splash') {
    return null;
  }
  return uri.toString();
}

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

class _CommunityRouteScreen extends ConsumerWidget {
  const _CommunityRouteScreen({
    required this.communityId,
    required this.builder,
  });

  final String communityId;
  final Widget Function(Community community) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(communityByIdProvider(communityId))
        .when(
          data: builder,
          loading: () => const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => _RouteErrorScreen(
            message: '커뮤니티를 불러오지 못했습니다.',
            onRetry: () => ref.invalidate(communityByIdProvider(communityId)),
          ),
        );
  }
}

class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: const TextStyle(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text('다시 시도')),
            ],
          ],
        ),
      ),
    );
  }
}
