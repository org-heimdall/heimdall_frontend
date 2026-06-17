import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/debate_room.dart';

class DebateLabel extends StatelessWidget {
  const DebateLabel({required this.stage, super.key});

  factory DebateLabel.fromStatus({required DebateStatus status, Key? key}) {
    return DebateLabel(
      key: key,
      stage: status == DebateStatus.live
          ? DebateLabelStage.live
          : DebateLabelStage.upcoming,
    );
  }

  final DebateLabelStage stage;

  @override
  Widget build(BuildContext context) {
    final isLive = stage == DebateLabelStage.live;
    final foreground = isLive ? AppColors.accent : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            isLive ? AppAssets.debateLiveIcon : AppAssets.debateWaitingIcon,
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
          ),
          const SizedBox(width: 2),
          Text(
            isLive ? '토론 중' : '준비 중',
            style: TextStyle(
              color: foreground,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class DebateStatusBadge extends DebateLabel {
  const DebateStatusBadge({required super.stage, super.key});
}

enum DebateLabelStage { live, upcoming }
