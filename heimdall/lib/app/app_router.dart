import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../features/debate/presentation/providers/debate_providers.dart';
import '../features/debate/presentation/screens/create_debate_screen.dart';
import '../features/debate/presentation/screens/debate_detail_screen.dart';
import '../features/debate/presentation/screens/debate_list_screen.dart';
import '../features/debate/presentation/screens/debate_result_screen.dart';
import '../features/debate/presentation/screens/debate_session_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final repository = ref.watch(debateRepositoryProvider);

  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const DebateListScreen()),
      GoRoute(
        path: '/debates/new',
        builder: (context, state) => const CreateDebateScreen(),
      ),
      GoRoute(
        path: '/debates/:id',
        builder: (context, state) {
          final room = repository.getRoomById(state.pathParameters['id'] ?? '');
          return room == null
              ? const _RouteNotFoundScreen()
              : DebateDetailScreen(room: room);
        },
      ),
      GoRoute(
        path: '/debates/:id/session',
        builder: (context, state) {
          final room = repository.getRoomById(state.pathParameters['id'] ?? '');
          return room == null
              ? const _RouteNotFoundScreen()
              : DebateSessionScreen(room: room);
        },
      ),
      GoRoute(
        path: '/debates/:id/result',
        builder: (context, state) {
          final room = repository.getRoomById(state.pathParameters['id'] ?? '');
          return room == null
              ? const _RouteNotFoundScreen()
              : DebateResultScreen(
                  room: room,
                  result: repository.getResult(room),
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
          '토론방을 찾을 수 없습니다.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      ),
    );
  }
}
