import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/community_chat.dart';
import '../../domain/entities/community.dart';
import '../../domain/entities/community_user_profile.dart';
import '../providers/community_user_profile_providers.dart';
import '../widgets/debate_popup_sheet.dart';

class CommunityChatScreen extends ConsumerStatefulWidget {
  const CommunityChatScreen({
    required this.community,
    this.viewerRole = CommunityChatViewerRole.member,
    super.key,
  });

  final Community community;
  final CommunityChatViewerRole viewerRole;

  @override
  ConsumerState<CommunityChatScreen> createState() =>
      _CommunityChatScreenState();
}

class _CommunityChatScreenState extends ConsumerState<CommunityChatScreen> {
  final _messageController = TextEditingController();
  static const _openingStatementNotice = CommunityOpeningStatementNotice(
    authorId: 'user-3',
    authorName: 'Username3',
  );
  final List<CommunityChatMessage> _messages = const [
    CommunityChatMessage(
      id: 'message-1',
      authorId: 'user-1',
      authorName: 'Username',
      text: '토마토맛 토보다는 정치얘기나하자',
    ),
    CommunityChatMessage(
      id: 'message-2',
      authorId: 'user-1',
      authorName: 'Username',
      text: '토마토맛 토도 결국 토',
    ),
    CommunityChatMessage(
      id: 'message-3',
      authorId: 'user-1',
      authorName: 'Username',
      text: '난 그냥 토마토가 싫은데...',
    ),
    CommunityChatMessage(
      id: 'message-4',
      authorId: 'user-2',
      authorName: 'Username2',
      text: '토마토맛 토를 누가 먹냐 우리 할머니도 안 드시겠다',
      accentAvatar: true,
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _WatchRoomHeader(
              community: widget.community,
              viewerRole: widget.viewerRole,
              onBack: () => Navigator.maybePop(context),
              onWatch: () =>
                  context.go('/communities/${widget.community.id}/debate'),
              onMore: () => context.go(
                '/communities/${widget.community.id}/debate/result',
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  for (final message in _messages)
                    _ChatMessageRow(
                      message: message,
                      onProfileTap: () =>
                          _showUserProfileByUserId(message.authorId),
                    ),
                  _DiscussionGuide(
                    notice: _openingStatementNotice,
                    onStatementTap: () => _showUserProfileByUserId(
                      _openingStatementNotice.authorId,
                    ),
                  ),
                ],
              ),
            ),
            _WatchRoomInput(controller: _messageController, onSend: _send),
          ],
        ),
      ),
    );
  }

  void _send() {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() {
      _messages.add(
        CommunityChatMessage(
          id: 'local-message-${DateTime.now().microsecondsSinceEpoch}',
          authorId: 'me',
          authorName: '나',
          text: text,
        ),
      );
      _messageController.clear();
    });
  }

  Future<void> _showUserProfileByUserId(String userId) async {
    final CommunityUserProfile profile;
    try {
      profile = await ref.read(communityUserProfileProvider(userId).future);
    } on Object {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('프로필을 불러오지 못했습니다.')));
      return;
    }

    if (!mounted) {
      return;
    }

    _showUserProfile(profile);
  }

  void _showUserProfile(CommunityUserProfile profile) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (dialogContext) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: DebatePopupSheet(
              userName: profile.userName,
              score: profile.score,
              claim: profile.claim,
              reasons: profile.reasons,
              role: DebatePopupRole.host,
              onClose: () => Navigator.pop(dialogContext),
              onDebate: () {
                Navigator.pop(dialogContext);
                context.go('/communities/${widget.community.id}/debate');
              },
            ),
          ),
        );
      },
    );
  }
}

class _WatchRoomHeader extends StatefulWidget {
  const _WatchRoomHeader({
    required this.community,
    required this.viewerRole,
    required this.onBack,
    required this.onWatch,
    required this.onMore,
  });

  final Community community;
  final CommunityChatViewerRole viewerRole;
  final VoidCallback onBack;
  final VoidCallback onWatch;
  final VoidCallback onMore;

  @override
  State<_WatchRoomHeader> createState() => _WatchRoomHeaderState();
}

class _WatchRoomHeaderState extends State<_WatchRoomHeader> {
  bool _isDebaterPreviewCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final opponent = _findOpponent();
    final hasOpponent =
        opponent != null && widget.community.status == CommunityStatus.live;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.background,
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
            padding: const EdgeInsets.fromLTRB(6, 12, 12, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: AppColors.textMuted,
                  tooltip: '뒤로',
                ),
                Expanded(
                  child: Text(
                    widget.community.title,
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
                const SizedBox(width: 8),
                _ViewerPill(count: widget.community.observerCount),
                if (_isDebaterPreviewCollapsed) ...[
                  _HeaderFoldButton(
                    icon: Icons.keyboard_arrow_down_rounded,
                    tooltip: '펼치기',
                    onTap: _toggleDebaterPreview,
                  ),
                ],
                _HeaderActionButton(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textMuted,
                    size: 24,
                  ),
                  tooltip: '더보기',
                  onTap: widget.onMore,
                ),
              ],
            ),
          ),
          if (!_isDebaterPreviewCollapsed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Stack(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _DebaterPreview(
                          name: widget.community.host.name,
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
                        child: _DebaterPreview(
                          name: hasOpponent ? opponent.name : '토론 상대 찾는 중...',
                          avatarAsset: hasOpponent ? AppAssets.avatarRed : null,
                          active: hasOpponent,
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: _HeaderFoldButton(
                      icon: Icons.keyboard_arrow_up_rounded,
                      tooltip: '접기',
                      onTap: _toggleDebaterPreview,
                    ),
                  ),
                ],
              ),
            ),
          if (!_isDebaterPreviewCollapsed && widget.viewerRole.canWatchDebate)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _WatchDebateButton(
                enabled: hasOpponent,
                onTap: widget.onWatch,
              ),
            ),
        ],
      ),
    );
  }

  Debater? _findOpponent() {
    for (final debater in widget.community.activeDebaters) {
      if (debater.name != widget.community.host.name) {
        return debater;
      }
    }
    return null;
  }

  void _toggleDebaterPreview() {
    setState(() {
      _isDebaterPreviewCollapsed = !_isDebaterPreviewCollapsed;
    });
  }
}

class _HeaderFoldButton extends StatelessWidget {
  const _HeaderFoldButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _HeaderActionButton(
      icon: Icon(icon, color: AppColors.textMuted, size: 30),
      tooltip: tooltip,
      onTap: onTap,
      width: 24,
    );
  }
}

class _WatchDebateButton extends StatelessWidget {
  const _WatchDebateButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = enabled ? AppColors.accent : AppColors.textMuted;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: enabled ? AppColors.surfaceElevated : null,
          borderRadius: BorderRadius.circular(8),
          border: enabled ? null : Border.all(color: AppColors.surfaceElevated),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.visibility_rounded, size: 16, color: foreground),
            const SizedBox(width: 4),
            Text(
              '관전하기',
              style: TextStyle(
                color: foreground,
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

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.width = 28,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: width,
          height: 40,
          child: Center(child: icon),
        ),
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

class _DebaterPreview extends StatelessWidget {
  const _DebaterPreview({
    required this.name,
    required this.active,
    this.avatarAsset,
  });

  final String name;
  final bool active;
  final String? avatarAsset;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: active ? null : AppColors.surfaceElevated,
            shape: BoxShape.circle,
          ),
          clipBehavior: Clip.antiAlias,
          child: active && avatarAsset != null
              ? Image.asset(avatarAsset!, fit: BoxFit.cover)
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? AppColors.textSecondary : AppColors.textMuted,
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ChatMessageRow extends StatelessWidget {
  const _ChatMessageRow({required this.message, required this.onProfileTap});

  final CommunityChatMessage message;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final maxMessageWidth =
        MediaQuery.sizeOf(context).width - 16 * 2 - 36 - 8 - 4 - 28;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ChatAvatar(accent: message.accentAvatar, onTap: onProfileTap),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxMessageWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.authorName,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        message.text,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          _NominateButton(onTap: () {}),
        ],
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({required this.accent, required this.onTap});

  final bool accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFE6E7E8),
          gradient: accent
              ? const RadialGradient(
                  center: Alignment(0.2, 0.2),
                  radius: 0.9,
                  colors: [Color(0xFFFE7D34), Color(0xFFE6E7E8)],
                )
              : null,
        ),
      ),
    );
  }
}

class _NominateButton extends StatelessWidget {
  const _NominateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.textMuted.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.arrow_forward_rounded,
          color: AppColors.textMuted,
          size: 16,
        ),
      ),
    );
  }
}

class _DiscussionGuide extends StatelessWidget {
  const _DiscussionGuide({required this.notice, required this.onStatementTap});

  final CommunityOpeningStatementNotice notice;
  final VoidCallback onStatementTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.textMuted.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${notice.authorName} 님이 기조 발언을 작성했습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.28,
                letterSpacing: -0.5,
              ),
            ),
            InkWell(
              onTap: onStatementTap,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                child: Text(
                  '기조발언보기',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.textMuted,
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

class _WatchRoomInput extends StatelessWidget {
  const _WatchRoomInput({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomPadding),
      color: AppColors.background,
      child: Row(
        children: [
          _CircleIconButton(
            icon: Icons.add_rounded,
            color: AppColors.accent,
            foreground: AppColors.background,
            onTap: () {},
          ),
          const SizedBox(width: 8),
          _CircleIconButton(
            icon: Icons.image_outlined,
            color: AppColors.surfaceElevated,
            foreground: AppColors.textSecondary,
            onTap: () {},
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        height: 1.5,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: '관전방에서 대화하기',
                        hintStyle: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                  InkWell(
                    onTap: onSend,
                    borderRadius: BorderRadius.circular(12),
                    child: const Icon(
                      Icons.mic_rounded,
                      color: AppColors.textMuted,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.color,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: foreground, size: 24),
      ),
    );
  }
}
