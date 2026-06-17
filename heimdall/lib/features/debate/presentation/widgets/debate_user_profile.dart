import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';

class DebateUserProfileChip extends StatelessWidget {
  const DebateUserProfileChip({
    required this.name,
    required this.score,
    this.active = true,
    this.avatarAsset = AppAssets.avatarBlue,
    super.key,
  });

  final String name;
  final int score;
  final bool active;
  final String avatarAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
      decoration: BoxDecoration(
        color: active ? AppColors.primary.withValues(alpha: 0.2) : null,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: active ? const Color(0xFF001D88) : AppColors.surfaceElevated,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: Image.asset(
              avatarAsset,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 76,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.fromLTRB(3, 2, 4, 2),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        AppAssets.trophyIcon,
                        width: 16,
                        height: 16,
                        colorFilter: ColorFilter.mode(
                          active ? AppColors.primarySoft : AppColors.textMuted,
                          BlendMode.srcIn,
                        ),
                      ),
                      Text(
                        '$score',
                        style: TextStyle(
                          color: active
                              ? AppColors.primarySoft
                              : AppColors.textMuted,
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
