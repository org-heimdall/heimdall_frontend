import 'package:flutter/material.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';

class ObserverView extends StatelessWidget {
  const ObserverView({required this.items, this.onClose, super.key});

  final List<ObserverCommentItem> items;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: 370,
        decoration: BoxDecoration(
          color: const Color(0xFF12161A),
          borderRadius: BorderRadius.circular(20),
          border: const Border(
            bottom: BorderSide(color: Color(0x33000000), width: 10),
          ),
        ),
        child: Stack(
          children: [
            ListView.separated(
              padding: const EdgeInsets.fromLTRB(11, 32, 23, 28),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 22),
              itemBuilder: (context, index) {
                return _ObserverCommentTile(item: items[index]);
              },
            ),
            Positioned(
              right: 16,
              top: 16,
              child: IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
                color: AppColors.accent,
                tooltip: '닫기',
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  width: 81,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ObserverCommentItem {
  const ObserverCommentItem({
    required this.userName,
    required this.content,
    required this.likes,
    required this.dislikes,
    this.isHost = false,
    this.avatarAsset,
  });

  final String userName;
  final String content;
  final int likes;
  final int dislikes;
  final bool isHost;
  final String? avatarAsset;
}

class _ObserverCommentTile extends StatelessWidget {
  const _ObserverCommentTile({required this.item});

  final ObserverCommentItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            ClipOval(
              child: Image.asset(
                item.avatarAsset ??
                    (item.isHost ? AppAssets.avatarBlue : AppAssets.avatarRed),
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            ),
            if (item.isHost)
              const Positioned(
                left: 16,
                bottom: -2,
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFFFFCC00),
                  size: 18,
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.userName,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.content,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text(
                    '자세히 보기',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  _VoteCount(
                    icon: Icons.thumb_up_alt_rounded,
                    count: item.likes,
                  ),
                  const SizedBox(width: 12),
                  _VoteCount(
                    icon: Icons.thumb_down_alt_rounded,
                    count: item.dislikes,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VoteCount extends StatelessWidget {
  const _VoteCount({required this.icon, required this.count});

  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(
          '$count',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.35,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
