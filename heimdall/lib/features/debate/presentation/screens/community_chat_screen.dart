import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/community.dart';

class CommunityChatScreen extends StatefulWidget {
  const CommunityChatScreen({required this.community, super.key});

  final Community community;

  @override
  State<CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen> {
  final _messageController = TextEditingController();
  final List<_ChatMessage> _messages = const [
    _ChatMessage(userName: 'Username', text: '토마토맛 토보다는 정치얘기나하자'),
    _ChatMessage(userName: 'Username', text: '토마토맛 토도 결국 토'),
    _ChatMessage(userName: 'Username', text: '난 그냥 토마토가 싫은데...'),
    _ChatMessage(
      userName: 'Username2',
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
              onBack: () => Navigator.maybePop(context),
              onMore: () => context.go(
                '/communities/${widget.community.id}/debate/result',
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  for (final message in _messages)
                    _ChatMessageRow(message: message),
                  const _DiscussionGuide(),
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
      _messages.add(_ChatMessage(userName: '나', text: text));
      _messageController.clear();
    });
  }
}

class _WatchRoomHeader extends StatelessWidget {
  const _WatchRoomHeader({
    required this.community,
    required this.onBack,
    required this.onMore,
  });

  final Community community;
  final VoidCallback onBack;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
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
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: AppColors.textMuted,
                  tooltip: '뒤로',
                ),
                Expanded(
                  child: Text(
                    community.title,
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
                _ViewerPill(count: community.observerCount),
                IconButton(
                  onPressed: onMore,
                  icon: const Icon(Icons.more_vert_rounded),
                  color: AppColors.textMuted,
                  tooltip: '더보기',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _DebaterPreview(
                    name: community.host.name,
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
                const Expanded(
                  child: _DebaterPreview(name: '토론 상대 찾는 중...', active: false),
                ),
              ],
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

class _ChatMessage {
  const _ChatMessage({
    required this.userName,
    required this.text,
    this.accentAvatar = false,
  });

  final String userName;
  final String text;
  final bool accentAvatar;
}

class _ChatMessageRow extends StatelessWidget {
  const _ChatMessageRow({required this.message});

  final _ChatMessage message;

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
              _ChatAvatar(accent: message.accentAvatar),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxMessageWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.userName,
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
  const _ChatAvatar({required this.accent});

  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
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
  const _DiscussionGuide();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.textMuted.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Username3 님이 기조 발언을 작성했습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.35,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              '기조발언보기',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                height: 1.45,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.textMuted,
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
      padding: EdgeInsets.fromLTRB(16, 8, 16, 28 + bottomPadding),
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
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
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
