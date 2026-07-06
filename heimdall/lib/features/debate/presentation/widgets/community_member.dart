import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';

class CommunityMember extends StatefulWidget {
  const CommunityMember({
    required this.hostName,
    required this.memberNames,
    required this.onClose,
    this.hostScore = 32,
    super.key,
  });

  final String hostName;
  final int hostScore;
  final List<String> memberNames;
  final VoidCallback onClose;

  @override
  State<CommunityMember> createState() => _CommunityMemberState();
}

class _CommunityMemberState extends State<CommunityMember> {
  bool _isFavorite = true;
  bool _wantsToDebate = true;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        left: false,
        child: Column(
          children: [
            _MemberPanelActions(
              isFavorite: _isFavorite,
              onClose: widget.onClose,
              onFavorite: () => setState(() => _isFavorite = !_isFavorite),
            ),
            const SizedBox(height: 4),
            const CircleAvatar(
              radius: 40,
              backgroundImage: AssetImage(AppAssets.communityHostAvatar),
            ),
            const SizedBox(height: 12),
            Text(
              widget.hostName,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 20,
                height: 1.4,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            _HostScore(score: widget.hostScore),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                children: [
                  const Text(
                    '토론 의사',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      height: 1.35,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DebateIntentButton(
                          label: '준비할래요',
                          icon: Icons.person_search_outlined,
                          selected: !_wantsToDebate,
                          onTap: () => setState(() => _wantsToDebate = false),
                        ),
                      ),
                      const SizedBox(width: 28),
                      Expanded(
                        child: _DebateIntentButton(
                          label: '토론할래요',
                          icon: Icons.search_rounded,
                          selected: _wantsToDebate,
                          onTap: () => setState(() => _wantsToDebate = true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                    ),
                    child: Column(
                      children: [
                        for (
                          var index = 0;
                          index < widget.memberNames.length;
                          index++
                        )
                          _MemberTile(
                            name: widget.memberNames[index],
                            isHost: index == 0,
                            showDivider: index < widget.memberNames.length - 1,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberPanelActions extends StatelessWidget {
  const _MemberPanelActions({
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

class _HostScore extends StatelessWidget {
  const _HostScore({required this.score});

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

class _DebateIntentButton extends StatelessWidget {
  const _DebateIntentButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        height: 83,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFA4A7FF) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              offset: Offset(0, 2),
              blurRadius: 2.5,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: AppColors.primary),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.name,
    required this.isHost,
    required this.showDivider,
  });

  final String name;
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
