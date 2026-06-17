import 'package:flutter/material.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';

class DebateRoomHeader extends StatelessWidget {
  const DebateRoomHeader({
    required this.title,
    required this.hostName,
    required this.viewerCount,
    this.opponentName,
    this.isActive = false,
    this.isHost = false,
    this.onBack,
    this.onWatch,
    this.onMore,
    super.key,
  });

  final String title;
  final String hostName;
  final int viewerCount;
  final String? opponentName;
  final bool isActive;
  final bool isHost;
  final VoidCallback? onBack;
  final VoidCallback? onWatch;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final hasOpponent = opponentName != null && opponentName!.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.7, 1],
          colors: [AppColors.background, Color(0xE6191C20)],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack ?? () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: AppColors.textMuted,
                  tooltip: '뒤로',
                ),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 22,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                _ViewerPill(count: viewerCount),
                if (isHost) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onMore,
                    icon: const Icon(Icons.more_vert_rounded),
                    color: AppColors.textMuted,
                    tooltip: '더보기',
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _DebaterSummary(
                    name: hostName,
                    avatarAsset: AppAssets.avatarBlue,
                    active: true,
                  ),
                ),
                const SizedBox(
                  width: 24,
                  child: Text(
                    'VS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 16,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Expanded(
                  child: _DebaterSummary(
                    name: hasOpponent ? opponentName! : '토론 상대 찾는 중...',
                    avatarAsset: hasOpponent
                        ? AppAssets.avatarRed
                        : AppAssets.avatarBlue,
                    active: hasOpponent,
                    muted: !hasOpponent,
                  ),
                ),
              ],
            ),
          ),
          if (!isHost)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: InkWell(
                onTap: onWatch,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.surfaceElevated : null,
                    borderRadius: BorderRadius.circular(8),
                    border: isActive
                        ? null
                        : Border.all(color: AppColors.surfaceElevated),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.visibility_rounded,
                        size: 16,
                        color: isActive
                            ? AppColors.accent
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '관전하기',
                        style: TextStyle(
                          color: isActive
                              ? AppColors.accent
                              : AppColors.textMuted,
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ViewerPill extends StatelessWidget {
  const _ViewerPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.group_rounded, size: 16, color: AppColors.textMuted),
          Text(
            '$count',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
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

class _DebaterSummary extends StatelessWidget {
  const _DebaterSummary({
    required this.name,
    required this.avatarAsset,
    required this.active,
    this.muted = false,
  });

  final String name;
  final String avatarAsset;
  final bool active;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: active
              ? Image.asset(
                  avatarAsset,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 40,
                  height: 40,
                  color: AppColors.surfaceElevated,
                ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: muted ? AppColors.textMuted : AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
