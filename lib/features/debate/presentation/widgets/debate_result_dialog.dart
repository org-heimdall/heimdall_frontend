import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';

class DebateResultDialog extends StatelessWidget {
  const DebateResultDialog({
    required this.host,
    required this.user,
    required this.winner,
    required this.judgements,
    this.onClose,
    super.key,
  });

  final DebateResultPlayer host;
  final DebateResultPlayer user;
  final DebateResultSide winner;
  final List<String> judgements;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 402,
      height: 540,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '토론 결과',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textMuted,
                  tooltip: '닫기',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _ResultPlayerColumn(
                    player: host,
                    resultText: winner == DebateResultSide.host ? '승' : '패',
                    won: winner == DebateResultSide.host,
                  ),
                ),
                const SizedBox(
                  width: 44,
                  child: Text(
                    'VS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 20,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Expanded(
                  child: _ResultPlayerColumn(
                    player: user,
                    resultText: winner == DebateResultSide.user ? '승' : '패',
                    won: winner == DebateResultSide.user,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            const Text(
              '헤임달의 판정',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                height: 1.4,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: judgements.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _JudgementTile(
                    number: index + 1,
                    text: judgements[index],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DebateResultPlayer {
  const DebateResultPlayer({
    required this.name,
    required this.score,
    required this.avatarAsset,
  });

  final String name;
  final int score;
  final String avatarAsset;
}

enum DebateResultSide { host, user }

class _ResultPlayerColumn extends StatelessWidget {
  const _ResultPlayerColumn({
    required this.player,
    required this.resultText,
    required this.won,
  });

  final DebateResultPlayer player;
  final String resultText;
  final bool won;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          padding: EdgeInsets.all(won ? 4 : 0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: won ? const Color(0xFFFFCC00) : Colors.transparent,
          ),
          child: ClipOval(
            child: Image.asset(player.avatarAsset, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          player.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 20,
            height: 1.4,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.fromLTRB(4, 2, 6, 2),
          decoration: BoxDecoration(
            color: AppColors.primarySoft.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                AppAssets.trophyIcon,
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  AppColors.primary,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                '${player.score}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          resultText,
          style: TextStyle(
            color: won ? const Color(0xFFFFCC00) : AppColors.textSecondary,
            fontSize: 20,
            height: 1.4,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _JudgementTile extends StatelessWidget {
  const _JudgementTile({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
