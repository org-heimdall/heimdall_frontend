import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/debate_room.dart';
import '../providers/debate_providers.dart';
import '../widgets/debate_participant_tile.dart';
import '../widgets/debate_status_badge.dart';
import '../widgets/debate_turn_card.dart';
import '../widgets/heimdall_card.dart';
import '../widgets/heimdall_controls.dart';
import '../widgets/heimdall_logo.dart';
import '../widgets/participant_stack.dart';

class DebateDetailScreen extends ConsumerWidget {
  const DebateDetailScreen({required this.room, super.key});

  final DebateRoom room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(debateRepositoryProvider);
    final turns = repository.getTurns(room);

    return Scaffold(
      appBar: AppBar(
        leading: const HeimdallBackButton(),
        title: const Text('토론 상세'),
        actions: [
          IconButton(
            onPressed: () => context.push('/debates/${room.id}/result'),
            icon: const Icon(Icons.insights_rounded),
            tooltip: '판정 결과',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            HeimdallCard(
              padding: const EdgeInsets.all(18),
              color: AppColors.card,
              radius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DebateStatusBadge(status: room.status),
                      ParticipantStack(participants: room.participants),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    room.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    room.topic,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      HeimdallMetaChip(
                        icon: Icons.category_rounded,
                        text: room.category.label,
                      ),
                      HeimdallMetaChip(
                        icon: Icons.repeat_rounded,
                        text: '${room.rounds}라운드',
                      ),
                      HeimdallMetaChip(
                        icon: Icons.timer_rounded,
                        text: '${room.elapsedMinutes}분',
                      ),
                      HeimdallMetaChip(
                        icon: Icons.visibility_rounded,
                        text: room.isPublic ? '공개' : '비공개',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const HeimdallSectionTitle('참여자'),
            const SizedBox(height: 10),
            for (final participant in room.participants)
              DebateParticipantTile(participant: participant),
            const SizedBox(height: 18),
            const HeimdallSectionTitle('토론 기록'),
            const SizedBox(height: 10),
            for (final turn in turns) DebateTurnCard(turn: turn),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: HeimdallPrimaryButton(
          label: room.isJoinable ? '토론 참여하기' : '토론장 입장',
          onPressed: () => context.push('/debates/${room.id}/session'),
        ),
      ),
    );
  }
}
