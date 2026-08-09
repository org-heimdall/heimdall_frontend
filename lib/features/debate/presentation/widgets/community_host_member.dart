import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/community.dart';

class CommunityMember extends StatefulWidget {
  const CommunityMember({
    required this.userName,
    required this.currentMemberId,
    required this.members,
    required this.onClose,
    this.onProfileTap,
    this.profileImageUrl,
    this.userScore,
    this.initialWantsToDebate = true,
    this.onDebateIntentChanged,
    this.showHostActions = false,
    this.onDeleteCommunity,
    this.onLeaveCommunity,
    this.onReport,
    super.key,
  });

  final String userName;
  final String currentMemberId;
  final String? profileImageUrl;
  final int? userScore;
  final bool initialWantsToDebate;
  final Future<void> Function(bool wantsToDebate)? onDebateIntentChanged;
  final List<CommunityMemberSummary> members;
  final VoidCallback onClose;
  final VoidCallback? onProfileTap;
  final bool showHostActions;
  final VoidCallback? onDeleteCommunity;
  final VoidCallback? onLeaveCommunity;
  final VoidCallback? onReport;

  @override
  State<CommunityMember> createState() => _CommunityMemberState();
}

class _CommunityMemberState extends State<CommunityMember> {
  bool _isFavorite = true;
  late bool _wantsToDebate;

  @override
  void initState() {
    super.initState();
    _wantsToDebate = widget.initialWantsToDebate;
  }

  Future<void> _setDebateIntent(bool wantsToDebate) async {
    if (_wantsToDebate == wantsToDebate) {
      return;
    }
    final previous = _wantsToDebate;
    setState(() => _wantsToDebate = wantsToDebate);
    try {
      await widget.onDebateIntentChanged?.call(wantsToDebate);
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _wantsToDebate = previous);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('토론 의사 상태를 저장하지 못했습니다.')));
    }
  }

  List<CommunityMemberSummary> get _sortedMembers {
    final members = [...widget.members];
    members.sort((left, right) {
      final leftWantsToDebate = left.id == widget.currentMemberId
          ? _wantsToDebate
          : left.wantsToDebate;
      final rightWantsToDebate = right.id == widget.currentMemberId
          ? _wantsToDebate
          : right.wantsToDebate;
      final intentOrder = (rightWantsToDebate ? 1 : 0).compareTo(
        leftWantsToDebate ? 1 : 0,
      );
      if (intentOrder != 0) {
        return intentOrder;
      }
      final roleOrder = (left.isHost ? 0 : 1).compareTo(right.isHost ? 0 : 1);
      if (roleOrder != 0) {
        return roleOrder;
      }
      return left.joinedAt.compareTo(right.joinedAt);
    });
    return members;
  }

  @override
  Widget build(BuildContext context) {
    final members = _sortedMembers;
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        left: false,
        bottom: false,
        child: Column(
          children: [
            _MemberPanelActions(
              isFavorite: _isFavorite,
              onClose: widget.onClose,
              onFavorite: () => setState(() => _isFavorite = !_isFavorite),
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: widget.onProfileTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    _CurrentMemberAvatar(
                      userName: widget.userName,
                      profileImageUrl: widget.profileImageUrl,
                    ),
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
                    if (widget.userScore case final score?) ...[
                      const SizedBox(height: 8),
                      _HostScore(score: score),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                          iconAsset: AppAssets.debatePreparingIcon,
                          selected: !_wantsToDebate,
                          onTap: () => _setDebateIntent(false),
                        ),
                      ),
                      const SizedBox(width: 28),
                      Expanded(
                        child: _DebateIntentButton(
                          label: '토론할래요',
                          icon: Icons.search_rounded,
                          selected: _wantsToDebate,
                          onTap: () => _setDebateIntent(true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => CustomScrollView(
                  clipBehavior: Clip.hardEdge,
                  slivers: [
                    SliverToBoxAdapter(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text.rich(
                                      TextSpan(
                                        text: '현재 참여 중  ',
                                        children: [
                                          TextSpan(
                                            text: '${members.length}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
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
                                            index < members.length;
                                            index++
                                          )
                                            _MemberTile(
                                              name: members[index].displayName,
                                              isHost: members[index].isHost,
                                              showDivider:
                                                  index < members.length - 1,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              widget.showHostActions
                                  ? _HostCommunityActions(
                                      onDeleteCommunity:
                                          widget.onDeleteCommunity,
                                    )
                                  : _MemberCommunityActions(
                                      onLeaveCommunity: widget.onLeaveCommunity,
                                      onReport: widget.onReport,
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentMemberAvatar extends StatelessWidget {
  const _CurrentMemberAvatar({
    required this.userName,
    required this.profileImageUrl,
  });

  final String userName;
  final String? profileImageUrl;

  @override
  Widget build(BuildContext context) {
    final imageUrl = profileImageUrl?.trim();

    return ClipOval(
      child: SizedBox(
        width: 80,
        height: 80,
        child: imageUrl == null || imageUrl.isEmpty
            ? _AvatarFallback(userName: userName)
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _AvatarFallback(userName: userName),
              ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    final normalizedName = userName.trim();
    final initial = normalizedName.isEmpty
        ? '?'
        : normalizedName.characters.first;

    return ColoredBox(
      color: AppColors.primarySoft,
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 30,
            height: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MemberCommunityActions extends StatelessWidget {
  const _MemberCommunityActions({
    required this.onLeaveCommunity,
    required this.onReport,
  });

  final VoidCallback? onLeaveCommunity;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.surfaceElevated)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MemberCommunityActionButton(
              label: '채팅방 나가기',
              icon: Icons.logout_rounded,
              color: const Color(0xFFFF5410),
              onTap: onLeaveCommunity,
            ),
          ),
          const SizedBox(
            height: 28,
            child: VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppColors.surfaceElevated,
            ),
          ),
          Expanded(
            child: _MemberCommunityActionButton(
              label: '신고하기',
              icon: Icons.report_rounded,
              color: const Color(0xFFA7B4BF),
              onTap: onReport,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberCommunityActionButton extends StatelessWidget {
  const _MemberCommunityActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.iconSize = 20,
    this.fontSize = 14,
    this.contentSpacing = 8,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final double iconSize;
  final double fontSize;
  final double contentSpacing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 48,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize, color: color),
            SizedBox(width: contentSpacing),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: fontSize,
                height: 1.4,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HostCommunityActions extends StatelessWidget {
  const _HostCommunityActions({required this.onDeleteCommunity});

  final VoidCallback? onDeleteCommunity;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.surfaceElevated)),
      ),
      child: _MemberCommunityActionButton(
        label: '커뮤니티 삭제하기',
        icon: Icons.delete_rounded,
        color: const Color(0xFFFF5410),
        onTap: onDeleteCommunity,
        iconSize: 30,
        fontSize: 18,
        contentSpacing: 20,
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
    required this.selected,
    required this.onTap,
    this.icon,
    this.iconAsset,
  }) : assert(icon != null || iconAsset != null);

  final String label;
  final IconData? icon;
  final String? iconAsset;
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
            if (iconAsset case final asset?)
              SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: SvgPicture.asset(asset, width: 30, height: 27),
                ),
              )
            else
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
