import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/community.dart';
import '../../domain/entities/debate_turn.dart';
import 'debate_forfeit_dialog.dart';
import 'debate_progress_sheet.dart';
import 'debate_popup_sheet.dart';
import 'debate_user_profile.dart';
import 'discussion_guide.dart';

class DebateRoom extends StatefulWidget {
  const DebateRoom({required this.community, this.isHost = true, super.key});

  final Community community;
  final bool isHost;

  @override
  State<DebateRoom> createState() => _DebateRoomState();
}

class _DebateRoomState extends State<DebateRoom> {
  static const _maxPositionLength = 200;

  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showLimitNotice = false;
  final List<_DebateRoomMessage> _messages = [
    _DebateRoomMessage(authorName: '나', text: '토마토맛 토도 결국 토마토다.', isMine: true),
    _DebateRoomMessage(
      authorName: 'Username',
      text: '토마토맛 토는 토마토의 상큼한 향이 나기 때문에 먹을만하다.',
    ),
    _DebateRoomMessage(
      authorName: 'Username',
      text: '토마토맛 토는 토마토의 상큼한 향이 나기 때문에 먹을만하다.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_handleMessageChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleMessageChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final host = _hostDebater;
    final opponent = _opponentDebater;
    final currentTurn = DebateTurn(
      stage: DebateStage.opening,
      side: host.side,
      speaker: host.name,
      content: '',
      remainingSeconds: 168,
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              Color(0xFF171B24),
              Color(0xFF191C20),
            ],
            stops: [0, 0.66, 1],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: _DebateRoomGlow()),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _DebateRoomHeader(
                    title: widget.community.title,
                    hostName: host.name,
                    opponentName: opponent.name,
                    remainingLabel: '15:54',
                    onOpponentTap: _showOpponentOpeningStatement,
                    onBack: _showForfeitDialog,
                  ),
                  Expanded(
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(top: 12, bottom: 18),
                      children: [
                        const DiscussionGuide(),
                        for (final message in _messages)
                          _DebateRoomMessageRow(message: message),
                        DiscussionGuide(
                          lines: [
                            '두 세계가 연결되었습니다. 예의를 갖추어 토론에 임하세요.',
                            '${host.name}님, 당신의 세계를 증명할 ‘입론’을 시작하세요.',
                          ],
                        ),
                      ],
                    ),
                  ),
                  _DebateTurnControl(
                    turn: currentTurn,
                    enabled: widget.isHost,
                    characterCount: _messageController.text.characters.length,
                    maxCharacterCount: _maxPositionLength,
                    onInfoTap: _showDebateProgress,
                    onSkip: () {},
                  ),
                  _DebateRoomInput(
                    controller: _messageController,
                    enabled: widget.isHost,
                    hintText: '${currentTurn.stage.label} 입력',
                    maxLength: _maxPositionLength,
                    onLimitReached: _showMessageLimitNotice,
                    onSend: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMessageChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Debater get _hostDebater {
    return widget.community.activeDebaters.firstWhere(
      (debater) => debater.name == widget.community.host.name,
      orElse: () => Debater(
        name: widget.community.host.name,
        side: DebateSide.pro,
        avatarColor: widget.community.host.avatarColor,
      ),
    );
  }

  Debater get _opponentDebater {
    return widget.community.activeDebaters.firstWhere(
      (debater) => debater.name != widget.community.host.name,
      orElse: () => const Debater(
        name: 'User_name',
        side: DebateSide.con,
        avatarColor: 0xFFFF7B2F,
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }
    if (text.characters.length > _maxPositionLength) {
      _showMessageLimitNotice();
      return;
    }

    setState(() {
      _messages.add(
        _DebateRoomMessage(
          authorName: widget.community.host.name,
          text: text,
          isMine: true,
        ),
      );
    });
    _messageController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  void _showMessageLimitNotice() {
    if (_showLimitNotice) {
      return;
    }

    setState(() {
      _showLimitNotice = true;
    });
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _showLimitNotice = false;
      });
    });
  }

  void _showDebateProgress() {
    final host = _hostDebater;
    final opponent = _opponentDebater;

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (dialogContext) {
        return DebateProgressSheet(
          currentStepIndex: 1,
          steps: [
            DebateProgressStep(
              label: '${opponent.name} 입론',
              durationLabel: '1분 30초',
            ),
            DebateProgressStep(
              label: '${host.name} 입론',
              durationLabel: '1분 30초',
            ),
            DebateProgressStep(
              label: '${opponent.name} 반론 및 질문',
              durationLabel: '3분',
            ),
            DebateProgressStep(
              label: '${host.name} 반론 및 질문',
              durationLabel: '3분',
            ),
            DebateProgressStep(
              label: '${opponent.name} 최종 발언',
              durationLabel: '3분',
            ),
            DebateProgressStep(
              label: '${host.name} 최종 발언',
              durationLabel: '3분',
            ),
            const DebateProgressStep(label: '채팅 메시지 프로세싱', durationLabel: '1분'),
            const DebateProgressStep(label: '발언 내용 분석', durationLabel: '1분'),
            const DebateProgressStep(label: '판결', durationLabel: '1분'),
          ],
          onClose: () => Navigator.pop(dialogContext),
        );
      },
    );
  }

  void _showForfeitDialog() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (dialogContext) {
        return DebateForfeitDialog(
          onCancel: () => Navigator.pop(dialogContext),
          onForfeit: () {
            Navigator.pop(dialogContext);
            Navigator.maybePop(context);
          },
        );
      },
    );
  }

  void _showOpponentOpeningStatement() {
    final opponent = _opponentDebater;

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (dialogContext) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: DebatePopupSheet(
              userName: opponent.name,
              score: 32,
              claim: '토마토맛 토를 누가 먹냐 우리 할머니도 안 드시겠다',
              reasons: const [
                '토마토맛이라고 하더라도 토는 토다.',
                '누군가가 씹고 삼키고 소화하다가 뱉어낸 잔해물을 먹는 것보단 토 맛이 나는 토마토가 낫다.',
              ],
              role: DebatePopupRole.participant,
              onClose: () => Navigator.pop(dialogContext),
            ),
          ),
        );
      },
    );
  }
}

class _DebateRoomGlow extends StatelessWidget {
  const _DebateRoomGlow();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0),
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0),
          ],
          stops: const [0, 0.68, 1],
        ),
      ),
    );
  }
}

class _DebateRoomHeader extends StatelessWidget {
  const _DebateRoomHeader({
    required this.title,
    required this.hostName,
    required this.opponentName,
    required this.remainingLabel,
    required this.onOpponentTap,
    required this.onBack,
  });

  final String title;
  final String hostName;
  final String opponentName;
  final String remainingLabel;
  final VoidCallback onOpponentTap;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background.withValues(alpha: 0.9),
            AppColors.background.withValues(alpha: 0.81),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          children: [
            SizedBox(
              height: 52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      iconSize: 28,
                      color: AppColors.textMuted,
                      tooltip: '뒤로',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 56),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 20,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: DebateUserProfileChip(
                          name: hostName,
                          score: 16,
                          avatarAsset: AppAssets.avatarBlue,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _TotalTimer(label: remainingLabel),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: onOpponentTap,
                        borderRadius: BorderRadius.circular(50),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: DebateUserProfileChip(
                            name: opponentName,
                            score: 32,
                            active: false,
                            avatarAsset: AppAssets.avatarRed,
                          ),
                        ),
                      ),
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

class _TotalTimer extends StatelessWidget {
  const _TotalTimer({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primarySoft, width: 2),
        color: AppColors.surface.withValues(alpha: 0.34),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primarySoft,
          fontSize: 13,
          height: 1.4,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.28,
        ),
      ),
    );
  }
}

class _DebateRoomMessage {
  const _DebateRoomMessage({
    required this.authorName,
    required this.text,
    this.isMine = false,
  });

  final String authorName;
  final String text;
  final bool isMine;
}

class _DebateRoomMessageRow extends StatelessWidget {
  const _DebateRoomMessageRow({required this.message});

  final _DebateRoomMessage message;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width - 76;

    if (message.isMine) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: _MessageBubble(text: message.text, isMine: true),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DebateAvatar(),
          const SizedBox(width: 8),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.authorName,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MessageBubble(text: message.text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DebateAvatar extends StatelessWidget {
  const _DebateAvatar();

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        AppAssets.avatarRed,
        width: 36,
        height: 36,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.text, this.isMine = false});

  final String text;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isMine ? AppColors.primary : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _DebateTurnControl extends StatelessWidget {
  const _DebateTurnControl({
    required this.turn,
    required this.enabled,
    required this.characterCount,
    required this.maxCharacterCount,
    required this.onInfoTap,
    required this.onSkip,
  });

  final DebateTurn turn;
  final bool enabled;
  final int characterCount;
  final int maxCharacterCount;
  final VoidCallback onInfoTap;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final stageLimit = turn.remainingSeconds > turn.stage.limitSeconds
        ? 180
        : turn.stage.limitSeconds;
    final progress = turn.remainingSeconds / stageLimit;
    final minutes = (turn.remainingSeconds ~/ 60).toString();
    final seconds = (turn.remainingSeconds % 60).toString().padLeft(2, '0');
    final foreground = enabled ? AppColors.accent : AppColors.textMuted;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          InkWell(
            onTap: onInfoTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: foreground,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${turn.speaker} ${turn.stage.label}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$characterCount/$maxCharacterCount',
                      style: TextStyle(
                        color: characterCount >= maxCharacterCount
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
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0, 1),
                          minHeight: 5,
                          backgroundColor: AppColors.surfaceElevated,
                          valueColor: AlwaysStoppedAnimation<Color>(foreground),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$minutes:$seconds',
                      style: TextStyle(
                        color: foreground,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: 32,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: AppColors.border,
          ),
          InkWell(
            onTap: enabled ? onSkip : null,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Text(
                '턴 넘기기',
                style: TextStyle(
                  color: foreground,
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DebateRoomInput extends StatelessWidget {
  const _DebateRoomInput({
    required this.controller,
    required this.enabled,
    required this.hintText,
    required this.maxLength,
    required this.onLimitReached,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final String hintText;
  final int maxLength;
  final VoidCallback onLimitReached;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      color: AppColors.background,
      padding: EdgeInsets.fromLTRB(16, 8, 16, 10 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: _DebateLimitNotice(
              key: ValueKey<bool>(
                controller.text.characters.length >= maxLength,
              ),
              visible: controller.text.characters.length >= maxLength,
            ),
          ),
          Row(
            children: [
              _InputIconButton(
                icon: Icons.image_outlined,
                onTap: enabled ? () {} : null,
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
                          enabled: enabled,
                          maxLines: 1,
                          maxLength: maxLength,
                          maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(maxLength),
                          ],
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                            height: 1.5,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            counterText: '',
                            isCollapsed: true,
                            hintText: hintText,
                            hintStyle: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          onChanged: (value) {
                            if (value.characters.length >= maxLength) {
                              onLimitReached();
                            }
                          },
                          onSubmitted: (_) => onSend(),
                        ),
                      ),
                      InkWell(
                        onTap: enabled ? onSend : null,
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
        ],
      ),
    );
  }
}

class _DebateLimitNotice extends StatelessWidget {
  const _DebateLimitNotice({required this.visible, super.key});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_rounded, size: 18, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              '이번 턴에서는 더이상 메시지를 보낼 수 없습니다.',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                height: 1.45,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputIconButton extends StatelessWidget {
  const _InputIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.surfaceElevated,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 24),
      ),
    );
  }
}
