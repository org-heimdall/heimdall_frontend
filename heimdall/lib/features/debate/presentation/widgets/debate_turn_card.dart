import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/debate_room.dart';
import '../../domain/entities/debate_turn.dart';
import 'heimdall_card.dart';

class DebateTurnCard extends StatelessWidget {
  const DebateTurnCard({
    required this.turn,
    this.compact = false,
    this.alignBySide = false,
    super.key,
  });

  final DebateTurn turn;
  final bool compact;
  final bool alignBySide;

  @override
  Widget build(BuildContext context) {
    final isPro = turn.side == DebateSide.pro;
    final card = HeimdallCard(
      margin: EdgeInsets.only(bottom: compact ? 12 : 10),
      padding: const EdgeInsets.all(14),
      color: alignBySide && isPro ? AppColors.primary : AppColors.surface,
      radius: compact ? 16 : 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            compact
                ? '${turn.stage.label} · ${turn.speaker}'
                : '${turn.stage.label} · ${turn.speaker} · ${turn.side.label}',
            style: TextStyle(
              color: alignBySide && isPro
                  ? AppColors.textPrimary
                  : AppColors.accent,
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            turn.content,
            style: TextStyle(
              color: alignBySide && isPro
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              height: compact ? 1.42 : 1.45,
            ),
          ),
        ],
      ),
    );

    if (!alignBySide) {
      return card;
    }

    return Align(
      alignment: isPro ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: card,
      ),
    );
  }
}

class DebateTimerPanel extends StatelessWidget {
  const DebateTimerPanel({
    required this.stage,
    required this.remainingSeconds,
    required this.isMyTurn,
    super.key,
  });

  final DebateStage stage;
  final int remainingSeconds;
  final bool isMyTurn;

  @override
  Widget build(BuildContext context) {
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');

    return HeimdallCard(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: AppColors.card,
      radius: 18,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.label,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isMyTurn ? '내 차례입니다. 1,000자 안에서 발언하세요.' : '상대 발언을 기다리는 중입니다.',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$minutes:$seconds',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
