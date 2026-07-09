import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';

class CommunityGuestMember extends StatefulWidget {
  const CommunityGuestMember({
    required this.userName,
    required this.memberNames,
    required this.onClose,
    this.userScore = 32,
    this.onLeaveChat,
    this.onReport,
    super.key,
  });

  final String userName;
  final int userScore;
  final List<String> memberNames;
  final VoidCallback onClose;
  final VoidCallback? onLeaveChat;
  final VoidCallback? onReport;

  @override
  State<CommunityGuestMember> createState() => _CommunityGuestMemberState();
}

class _CommunityGuestMemberState extends State<CommunityGuestMember> {
  bool _isFavorite = true;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        left: false,
        child: Column(
          children: [
            _GuestPanelActions(
              isFavorite: _isFavorite,
              onClose: widget.onClose,
              onFavorite: () => setState(() => _isFavorite = !_isFavorite),
            ),
            const SizedBox(height: 4),
            const _GuestAvatar(size: 80),
            const SizedBox(height: 12),
            Text(
              widget.userName,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 20,
                height: 1.4,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            _GuestScore(score: widget.userScore),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  Text.rich(
                    TextSpan(
                      text: '현재 참여 중  ',
                      children: [
                        TextSpan(
                          text: '${widget.memberNames.length}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      height: 1.35,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        for (
                          var index = 0;
                          index < widget.memberNames.length;
                          index++
                        )
                          _GuestMemberTile(
                            name: widget.memberNames[index],
                            isCurrentUser:
                                widget.memberNames[index] == widget.userName,
                            isHost: index == 1,
                            showDivider: index < widget.memberNames.length - 1,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _GuestCommunityActions(
              onLeaveChat: widget.onLeaveChat,
              onReport: widget.onReport,
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestPanelActions extends StatelessWidget {
  const _GuestPanelActions({
    required this.isFavorite,
    required this.onClose,
    required this.onFavorite,
  });

  final bool isFavorite;
  final VoidCallback onClose;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            color: AppColors.textMuted,
            tooltip: '닫기',
          ),
          const Spacer(),
          const IconButton(
            onPressed: null,
            icon: Icon(Icons.notifications_rounded),
            color: AppColors.primarySoft,
            disabledColor: AppColors.primarySoft,
          ),
          IconButton(
            onPressed: onFavorite,
            icon: Icon(
              isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
            ),
            color: AppColors.textMuted,
            tooltip: '즐겨찾기',
          ),
          const IconButton(
            onPressed: null,
            icon: Icon(Icons.share_rounded),
            color: AppColors.textMuted,
            disabledColor: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _GuestAvatar extends StatelessWidget {
  const _GuestAvatar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment(0.18, 0.12),
          radius: 0.72,
          colors: [Color(0xFFFF7B2F), Color(0xFFFFA533), Color(0xFFD7DEE8)],
          stops: [0, 0.36, 1],
        ),
      ),
    );
  }
}

class _GuestScore extends StatelessWidget {
  const _GuestScore({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primarySoft.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 2, 6, 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(AppAssets.trophyIcon, width: 20, height: 20),
            const SizedBox(width: 2),
            Text(
              '$score',
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
    );
  }
}

class _GuestMemberTile extends StatelessWidget {
  const _GuestMemberTile({
    required this.name,
    required this.isCurrentUser,
    required this.isHost,
    required this.showDivider,
  });

  final String name;
  final bool isCurrentUser;
  final bool isHost;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          SizedBox(
            height: 62,
            child: Row(
              children: [
                if (isCurrentUser)
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primarySoft,
                        width: 2,
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(1),
                      child: _GuestAvatar(size: 32),
                    ),
                  )
                else
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFE2E3E5),
                    backgroundImage: isHost
                        ? const AssetImage(AppAssets.communityHostAvatar)
                        : null,
                  ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showDivider)
            const Divider(height: 1, thickness: 1, color: AppColors.divider),
        ],
      ),
    );
  }
}

class _GuestCommunityActions extends StatelessWidget {
  const _GuestCommunityActions({
    required this.onLeaveChat,
    required this.onReport,
  });

  final VoidCallback? onLeaveChat;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.surfaceElevated)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GuestCommunityActionButton(
              label: '채팅방 나가기',
              icon: Icons.logout_rounded,
              color: const Color(0xFFFF5410),
              onTap: onLeaveChat,
            ),
            const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.surfaceElevated,
            ),
            _GuestCommunityActionButton(
              label: '신고하기',
              icon: Icons.report_rounded,
              color: Color(0xFFA7B4BF),
              onTap: onReport,
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestCommunityActionButton extends StatelessWidget {
  const _GuestCommunityActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(width: 28),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 18,
                height: 1.4,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
