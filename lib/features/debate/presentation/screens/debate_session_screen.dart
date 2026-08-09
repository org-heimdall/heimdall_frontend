import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/community.dart';
import '../providers/debate_chat_providers.dart';
import '../widgets/debate_room.dart';

class DebateSessionScreen extends ConsumerWidget {
  const DebateSessionScreen({
    required this.community,
    required this.debateId,
    super.key,
  });

  final Community community;
  final String debateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(debateDetailProvider(debateId))
        .when(
          data: (detail) => DebateRoom(
            community: community,
            debateId: debateId,
            initialDebateDetail: detail,
            isHost: community.isOwnedByCurrentUser,
          ),
          loading: () => const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (error, stackTrace) => Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: TextButton(
                onPressed: () => ref.invalidate(debateDetailProvider(debateId)),
                child: const Text('토론 참여자 정보를 다시 불러오기'),
              ),
            ),
          ),
        );
  }
}
