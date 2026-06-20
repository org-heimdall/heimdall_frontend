import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/community.dart';

class CommunityStatusLabel extends StatelessWidget {
  const CommunityStatusLabel({required this.stage, super.key});

  factory CommunityStatusLabel.fromStatus({
    required CommunityStatus status,
    Key? key,
  }) {
    return CommunityStatusLabel(
      key: key,
      stage: status == CommunityStatus.live
          ? CommunityStatusLabelStage.live
          : CommunityStatusLabelStage.upcoming,
    );
  }

  final CommunityStatusLabelStage stage;

  @override
  Widget build(BuildContext context) {
    final isLive = stage == CommunityStatusLabelStage.live;
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
            isLive ? '디베이트 중' : '모집 중',
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

class CommunityStatusBadge extends CommunityStatusLabel {
  const CommunityStatusBadge({required super.stage, super.key});
}

enum CommunityStatusLabelStage { live, upcoming }
