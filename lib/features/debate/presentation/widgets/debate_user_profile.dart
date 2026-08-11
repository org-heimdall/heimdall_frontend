import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';

class DebateUserProfileChip extends StatelessWidget {
  const DebateUserProfileChip({
    required this.name,
    required this.score,
    this.active = true,
    this.avatarUrl,
    super.key,
  });

  final String name;
  final int score;
  final bool active;
  final String? avatarUrl;

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
          _MemberAvatar(name: name, imageUrl: avatarUrl),
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

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.name, required this.imageUrl});

  final String name;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = imageUrl?.trim();
    return ClipOval(
      child: SizedBox(
        width: 36,
        height: 36,
        child: normalizedUrl == null || normalizedUrl.isEmpty
            ? _AvatarFallback(name: name)
            : Image.network(
                normalizedUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _AvatarFallback(name: name),
              ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final normalizedName = name.trim();
    return ColoredBox(
      color: AppColors.surfaceElevated,
      child: Center(
        child: Text(
          normalizedName.isEmpty ? '?' : normalizedName.characters.first,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
