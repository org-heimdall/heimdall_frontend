import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/community_chat.dart';
import '../../domain/entities/community.dart';
import '../../domain/entities/community_user_profile.dart';
import '../providers/community_chat_providers.dart';
import '../providers/community_user_profile_providers.dart';
import '../widgets/community_host_member.dart';
import '../widgets/community_guest_member.dart';
import '../widgets/community_opinion.dart';
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
  static const _pendingMessageTimeout = Duration(seconds: 10);

  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final Map<String, Timer> _pendingTimers = {};
  final List<CommunityChatMessage> _messages = [
    CommunityChatMessage(
      id: 'message-1',
      communityId: 'room-2',
      authorId: 'user-1',
      authorName: 'Username',
      text: '토마토맛 토보다는 정치얘기나하자',
      createdAt: DateTime(2026, 6, 17, 20),
    ),
    CommunityChatMessage(
      id: 'message-2',
      communityId: 'room-2',
      authorId: 'user-1',
      authorName: 'Username',
      text: '토마토맛 토도 결국 토',
      createdAt: DateTime(2026, 6, 17, 20, 1),
    ),
    CommunityChatMessage(
      id: 'notice-1',
      communityId: 'room-2',
      authorId: 'system',
      authorName: 'System',
      text: 'Username3 님이 기조 발언을 작성했습니다.',
      relatedUserId: 'user-3',
      type: CommunityChatMessageType.openingStatementNotice,
      createdAt: DateTime(2026, 6, 17, 20, 2),
    ),
    CommunityChatMessage(
      id: 'message-3',
      communityId: 'room-2',
      authorId: 'user-1',
      authorName: 'Username',
      text: '난 그냥 토마토가 싫은데...',
      createdAt: DateTime(2026, 6, 17, 20, 2),
    ),
    CommunityChatMessage(
      id: 'message-4',
      communityId: 'room-2',
      authorId: 'user-2',
      authorName: 'Username2',
      text: '토마토맛 토를 누가 먹냐 우리 할머니도 안 드시겠다',
      createdAt: DateTime(2026, 6, 17, 20, 3),
      accentAvatar: true,
    ),
  ];

  @override
  void dispose() {
    for (final timer in _pendingTimers.values) {
      timer.cancel();
    }
    _pendingTimers.clear();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // WebSocket 이벤트를 화면 메시지 목록에 반영해 실시간 채팅 UX를 만든다.
    ref.listen<AsyncValue<CommunityChatEvent>>(
      communityChatEventsProvider(widget.community.id),
      (previous, next) {
        next.whenData(_mergeRealtimeEvent);
      },
    );

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
                  context.push('/communities/${widget.community.id}/debate'),
              onMore: _showCommunityMembers,
            ),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  for (final message in _orderedMessages)
                    if (message.type ==
                        CommunityChatMessageType.openingStatementNotice)
                      _DiscussionGuide(
                        message: message,
                        onStatementTap: () => _showUserProfileByUserId(
                          message.relatedUserId ?? message.authorId,
                        ),
                      )
                    else
                      _ChatMessageRow(
                        message: message,
                        onProfileTap: () =>
                            _showUserProfileByUserId(message.authorId),
                        onRetry: () => _retryMessage(message),
                      ),
                ],
              ),
            ),
            _WatchRoomInput(
              controller: _messageController,
              onSend: _send,
              onOpeningStatement:
                  widget.viewerRole == CommunityChatViewerRole.host
                  ? null
                  : _showOpeningStatementSheet,
            ),
          ],
        ),
      ),
    );
  }

  void _showCommunityMembers() {
    const currentUserName = 'Username';
    final memberNames = <String>[
      widget.community.host.name,
      ...widget.community.activeDebaters
          .map((debater) => debater.name)
          .where((name) => name != widget.community.host.name),
      'Username1',
      'Username2',
      'Username3',
      'Username5',
      'Username6',
    ];

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '커뮤니티 참여자 닫기',
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final isHost = widget.viewerRole == CommunityChatViewerRole.host;
        final guestMemberNames = <String>[
          currentUserName,
          widget.community.host.name,
          ...memberNames.where(
            (name) =>
                name != currentUserName && name != widget.community.host.name,
          ),
        ];

        return Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 329),
            child: SizedBox(
              width: MediaQuery.sizeOf(dialogContext).width - 74,
              height: double.infinity,
              child: isHost
                  ? CommunityMember(
                      hostName: widget.community.host.name,
                      memberNames: memberNames.take(7).toList(),
                      onClose: () => Navigator.pop(dialogContext),
                      showHostActions: true,
                      onDeleteCommunity: () =>
                          _showPanelActionFeedback('커뮤니티 삭제 기능은 준비 중입니다.'),
                      onReport: () =>
                          _showPanelActionFeedback('신고 기능은 준비 중입니다.'),
                    )
                  : CommunityGuestMember(
                      userName: currentUserName,
                      memberNames: guestMemberNames.take(7).toList(),
                      onClose: () => Navigator.pop(dialogContext),
                      onLeaveChat: () =>
                          _showPanelActionFeedback('채팅방 나가기 기능은 준비 중입니다.'),
                      onReport: () =>
                          _showPanelActionFeedback('신고 기능은 준비 중입니다.'),
                    ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        );
      },
    );
  }

  void _showPanelActionFeedback(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showOpeningStatementSheet() async {
    await showModalBottomSheet<CommunityOpinionDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (sheetContext) {
        return CommunityOpinionSheet(onSubmit: _submitOpeningStatement);
      },
    );
  }

  void _submitOpeningStatement(CommunityOpinionDraft draft) {
    setState(() {
      _messages.add(
        CommunityChatMessage(
          id: 'opening-${DateTime.now().microsecondsSinceEpoch}',
          communityId: widget.community.id,
          authorId: 'system',
          authorName: 'System',
          text: '나 님이 기조 발언을 작성했습니다.',
          relatedUserId: 'me',
          type: CommunityChatMessageType.openingStatementNotice,
          createdAt: DateTime.now(),
        ),
      );
    });
    _scrollToBottomAfterBuild();
  }

  // 시스템 알림과 일반 메시지를 서버 생성 시간 기준으로 섞어 보여준다.
  List<CommunityChatMessage> get _orderedMessages {
    return [..._messages]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  // 전송 즉시 내 말풍선을 pending으로 보여주고 WebSocket command를 보낸다.
  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    _messageController.clear();
    await _sendText(text);
  }

  Future<void> _sendText(String text) async {
    // 서버 push가 돌아오면 이 ID로 pending 말풍선과 서버 메시지를 병합한다.
    final clientMessageId = 'client-${DateTime.now().microsecondsSinceEpoch}';

    final pendingMessage = CommunityChatMessage(
      id: clientMessageId,
      communityId: widget.community.id,
      clientMessageId: clientMessageId,
      authorId: 'me',
      authorName: '나',
      text: text,
      createdAt: DateTime.now(),
      deliveryStatus: CommunityChatMessageDeliveryStatus.pending,
    );

    setState(() {
      _messages.add(pendingMessage);
    });
    _startPendingTimeout(clientMessageId);
    // 내가 보낸 메시지는 사용자의 현재 작업 결과이므로 항상 아래로 이동한다.
    _scrollToBottomAfterBuild();

    try {
      await ref
          .read(sendCommunityChatMessageProvider(widget.community.id).notifier)
          .send(
            authorId: pendingMessage.authorId,
            text: pendingMessage.text,
            clientMessageId: clientMessageId,
          );
    } on Object {
      _cancelPendingTimeout(clientMessageId);
      if (!mounted) {
        return;
      }

      setState(() {
        final index = _messages.indexWhere(
          (message) => message.clientMessageId == clientMessageId,
        );
        if (index == -1) {
          return;
        }
        _messages[index] = _messages[index].copyWith(
          deliveryStatus: CommunityChatMessageDeliveryStatus.failed,
        );
      });
      // 실패 라벨도 방금 보낸 메시지의 일부라 사용자가 바로 볼 수 있게 유지한다.
      _scrollToBottomAfterBuild();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('메시지를 보내지 못했습니다.')));
    }
  }

  Future<void> _retryMessage(CommunityChatMessage failedMessage) async {
    setState(() {
      _messages.removeWhere((message) => message.id == failedMessage.id);
    });

    await _sendText(failedMessage.text);
  }

  // 서버 이벤트 타입을 화면 상태 변경으로 변환한다.
  void _mergeRealtimeEvent(CommunityChatEvent event) {
    if (!mounted || event.communityId != widget.community.id) {
      return;
    }

    switch (event.type) {
      case CommunityChatEventType.messageCreated:
      case CommunityChatEventType.messageUpdated:
        final message = event.message;
        if (message == null) {
          return;
        }
        _upsertMessage(message);
        return;
      case CommunityChatEventType.messageDeleted:
        final message = event.message;
        if (message == null) {
          return;
        }
        // 과거 메시지를 보고 있는 사용자를 방해하지 않기 위해 삭제 전 위치를 기록한다.
        final wasNearBottom = _isNearBottom;
        setState(() {
          _messages.removeWhere((item) => item.id == message.id);
        });
        if (wasNearBottom) {
          _scrollToBottomAfterBuild();
        }
        return;
      case CommunityChatEventType.openingStatementCreated:
        final message = event.message;
        if (message == null) {
          return;
        }
        _upsertMessage(message);
        return;
      case CommunityChatEventType.connectionRestored:
        return;
    }
  }

  // 새 메시지, 서버 보정 메시지, optimistic 메시지를 중복 없이 합친다.
  void _upsertMessage(CommunityChatMessage incoming) {
    // 하단 근처에서 채팅을 보고 있던 경우에만 실시간 메시지를 따라 내려간다.
    final wasNearBottom = _isNearBottom;

    setState(() {
      // 내 pending 메시지는 clientMessageId로 서버 push와 같은 메시지인지 판단한다.
      final byClientMessageId = incoming.clientMessageId == null
          ? -1
          : _messages.indexWhere(
              (message) => message.clientMessageId == incoming.clientMessageId,
            );
      final byServerId = _messages.indexWhere(
        (message) => message.id == incoming.id,
      );
      final index = byClientMessageId != -1 ? byClientMessageId : byServerId;

      if (incoming.clientMessageId != null) {
        _cancelPendingTimeout(incoming.clientMessageId!);
      }

      if (index == -1) {
        _messages.add(incoming);
        return;
      }

      // 같은 메시지는 추가하지 않고 서버가 준 최신 값으로 교체한다.
      _messages[index] = incoming;
    });

    if (wasNearBottom) {
      _scrollToBottomAfterBuild();
    }
  }

  void _startPendingTimeout(String clientMessageId) {
    _cancelPendingTimeout(clientMessageId);
    _pendingTimers[clientMessageId] = Timer(_pendingMessageTimeout, () {
      if (!mounted) {
        return;
      }

      setState(() {
        final index = _messages.indexWhere(
          (message) =>
              message.clientMessageId == clientMessageId &&
              message.deliveryStatus ==
                  CommunityChatMessageDeliveryStatus.pending,
        );
        if (index == -1) {
          return;
        }
        _messages[index] = _messages[index].copyWith(
          deliveryStatus: CommunityChatMessageDeliveryStatus.failed,
        );
      });
      _pendingTimers.remove(clientMessageId);
    });
  }

  void _cancelPendingTimeout(String clientMessageId) {
    _pendingTimers.remove(clientMessageId)?.cancel();
  }

  // 하단에서 너무 멀리 올라가 있으면 사용자가 과거 메시지를 읽는 중으로 본다.
  bool get _isNearBottom {
    if (!_scrollController.hasClients) {
      return true;
    }

    final position = _scrollController.position;
    return position.maxScrollExtent - position.pixels <= 96;
  }

  // 새 레이아웃이 계산된 다음 실제 최하단 위치로 부드럽게 이동한다.
  void _scrollToBottomAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  // 메시지/알림의 userId로 프로필 상세를 불러와 동일한 팝업을 연다.
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

  // 채팅방 위에 프로필 팝업을 띄우고, 토론하기 액션을 실제 토론방으로 연결한다.
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
                context.push('/communities/${widget.community.id}/debate');
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
            padding: const EdgeInsets.fromLTRB(6, 10, 12, 6),
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
	                      fontSize: 21,
	                      height: 1.4,
	                      fontWeight: FontWeight.w600,
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
	              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
	                              fontSize: 15,
	                              height: 1.4,
	                              fontWeight: FontWeight.w600,
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
	        const SizedBox(height: 5),
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
  const _ChatMessageRow({
    required this.message,
    required this.onProfileTap,
    required this.onRetry,
  });

  final CommunityChatMessage message;
  final VoidCallback onProfileTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isMine = message.authorId == 'me';
    final maxMessageWidth = isMine
        ? MediaQuery.sizeOf(context).width - 16 * 2 - 72
        : MediaQuery.sizeOf(context).width - 16 * 2 - 36 - 8 - 4 - 28;
    final messageBody = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxMessageWidth),
      child: Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!isMine) ...[
            Text(
              message.authorName,
              style: const TextStyle(
                color: AppColors.textSecondary,
	                fontSize: 11,
	                height: 1.2,
              ),
            ),
	            const SizedBox(height: 6),
          ],
          Container(
	            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isMine ? AppColors.primary : AppColors.surfaceElevated,
	              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              message.text,
              style: const TextStyle(
                color: AppColors.textSecondary,
	                fontSize: 15,
	                height: 1.6,
              ),
            ),
          ),
          if (message.deliveryStatus ==
              CommunityChatMessageDeliveryStatus.failed) ...[
            const SizedBox(height: 4),
            InkWell(
              onTap: onRetry,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                child: Text(
                  '전송 실패 · 다시 보내기',
                  style: TextStyle(
                    color: AppColors.con,
                    fontSize: 11,
                    height: 1.35,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return Padding(
	      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMine)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ChatAvatar(accent: message.accentAvatar, onTap: onProfileTap),
                const SizedBox(width: 8),
                messageBody,
              ],
            )
          else
            messageBody,
          if (!isMine) ...[
            const SizedBox(width: 4),
            _NominateButton(onTap: () {}),
          ],
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
  const _DiscussionGuide({required this.message, required this.onStatementTap});

  final CommunityChatMessage message;
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
              message.text,
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
  const _WatchRoomInput({
    required this.controller,
    required this.onSend,
    this.onOpeningStatement,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onOpeningStatement;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
	      padding: EdgeInsets.fromLTRB(16, 8, 16, 10 + bottomPadding),
      color: AppColors.background,
      child: Row(
        children: [
          _CircleIconButton(
            icon: Icons.add_rounded,
            color: AppColors.accent,
            foreground: AppColors.background,
            onTap: onOpeningStatement,
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
	              height: 36,
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
	                        fontSize: 14,
	                        height: 1.45,
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
	                          fontSize: 14,
	                          height: 1.45,
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
	                      size: 22,
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
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
	      borderRadius: BorderRadius.circular(18),
	      child: Container(
	        width: 36,
	        height: 36,
        decoration: BoxDecoration(
          color: onTap == null ? AppColors.surfaceElevated : color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: onTap == null ? AppColors.textMuted : foreground,
	          size: 23,
        ),
      ),
    );
  }
}
