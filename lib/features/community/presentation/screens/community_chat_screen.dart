import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/community_chat.dart';
import '../../domain/entities/community.dart';
import '../../domain/entities/community_user_profile.dart';
import '../../../debate/domain/entities/debate_chat_realtime.dart';
import '../../../../shared/chat/domain/chat_message.dart';
import '../../../../shared/chat/presentation/controllers/chat_message_timeline.dart';
import '../providers/community_chat_providers.dart';
import '../providers/community_providers.dart';
import '../providers/community_user_profile_providers.dart';
import '../../../debate/presentation/providers/debate_chat_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../widgets/community_host_member.dart';
import '../widgets/community_opinion.dart';
import '../../../../shared/chat/presentation/widgets/chat_composer.dart';
import '../../../../shared/chat/presentation/widgets/chat_message_tile.dart';
import '../../../debate/presentation/widgets/debate_popup_sheet.dart';
import '../../../../shared/presentation/widgets/confirmation_dialog.dart';
import '../../../debate/presentation/widgets/debate_start_dialog.dart';
import '../../../debate/presentation/widgets/debate_result_popup.dart';
import '../../../observer/presentation/widgets/observer_view.dart';

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
  final _scrollController = ScrollController();
  late final ChatMessageTimeline _timeline;
  bool _startingDebate = false;
  bool _navigatingToDebate = false;
  bool _didScrollToInitialHistory = false;
  bool _didCheckInitialOpinion = false;
  String? _visibleDebateInvitationId;
  String? _visibleOutgoingDebateInvitationId;
  Route<void>? _observerDialogRoute;
  Timer? _rejectedToastTimer;
  bool _showRejectedToast = false;
  String _rejectedToastMessage = '상대방이 토론 요청을 거부했어요.';

  @override
  void initState() {
    super.initState();
    _timeline = ChatMessageTimeline()..addListener(_handleTimelineChanged);
    unawaited(_resumeActiveDebate());
  }

  @override
  void dispose() {
    _timeline.removeListener(_handleTimelineChanged);
    _timeline.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _rejectedToastTimer?.cancel();
    super.dispose();
  }

  void _handleTimelineChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _resumeActiveDebate() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted || _startingDebate || _navigatingToDebate) return;
    try {
      final debate = await ref.read(
        activeCommunityDebateProvider(widget.community.id).future,
      );
      if (!mounted || debate == null || debate.viewerSide == null) return;
      await _openDebate(debate.id);
    } on Object {
      // 활성 토론 복구 실패는 채팅 입장을 막지 않는다.
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMember = ref.watch(currentMemberProvider);
    final activeDebate = ref
        .watch(activeCommunityDebateProvider(widget.community.id))
        .asData
        ?.value;
    final messageHistoryAsync = ref.watch(
      communityChatHistoryProvider(widget.community.id),
    );
    final opinionHistoryAsync = ref.watch(
      communityOpinionHistoryProvider(widget.community.id),
    );
    final communityMembers = ref
        .watch(communityMembersProvider(widget.community.id))
        .asData
        ?.value;
    final profileImageByMemberId = <String, String?>{
      for (final member in communityMembers ?? const <CommunityMemberSummary>[])
        member.id: member.profileImageUrl,
      if (currentMember != null)
        currentMember.id: currentMember.profileImageUrl,
    };
    final messageHistory = messageHistoryAsync.asData?.value;
    final opinionHistory = opinionHistoryAsync.asData?.value;
    final myOpinion = currentMember == null
        ? null
        : _findMemberOpinion(opinionHistory, currentMember.id);
    final visibleMessages = _orderedMessagesWithHistory(
      messageHistory ?? const <ChatMessage>[],
      opinionHistory ?? const <ChatMessage>[],
    );
    final hasMyOpinion =
        currentMember != null &&
        opinionHistory?.any(
              (message) => message.authorId == currentMember.id,
            ) ==
            true;
    if (!_didCheckInitialOpinion &&
        currentMember != null &&
        opinionHistory != null) {
      _didCheckInitialOpinion = true;
      if (!hasMyOpinion && widget.viewerRole != CommunityChatViewerRole.host) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            unawaited(_showOpinionSheet());
          }
        });
      }
    }
    if (!_didScrollToInitialHistory &&
        !messageHistoryAsync.isLoading &&
        !opinionHistoryAsync.isLoading) {
      _didScrollToInitialHistory = true;
      _scrollToBottomAfterBuild();
    }
    // WebSocket 이벤트를 화면 메시지 목록에 반영해 실시간 채팅 UX를 만든다.
    ref.listen<AsyncValue<CommunityChatEvent>>(
      communityChatEventsProvider(widget.community.id),
      (previous, next) {
        next.whenData(_mergeRealtimeEvent);
      },
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _WatchRoomHeader(
                  community: widget.community,
                  activeDebate: activeDebate,
                  viewerRole: widget.viewerRole,
                  onBack: _handleBack,
                  onTitleTap: _showDebateInfo,
                  onWatch: _showObserverView,
                  onMore: () => _showCommunityMembers(),
                ),
                Expanded(
                  child: ColoredBox(
                    color: AppColors.surface,
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      children: [
                        for (final message in visibleMessages)
                          if (message is CommunityOpinionMessage)
                            _DiscussionGuide(
                              message: message,
                              onStatementTap: () =>
                                  _showUserProfileByUserId(message.authorId),
                            )
                          else if (message is CommunityDebateStartedMessage)
                            _CommunitySystemNotice(message: message.text)
                          else if (message is CommunityDebateResultMessage)
                            _CommunitySystemNotice(
                              message: message.text,
                              actionLabel: '토론결과보기',
                              onAction: () =>
                                  _showDebateResultPopup(message.debateId),
                            )
                          else if (message is CommunityDebateForfeitMessage)
                            _CommunitySystemNotice(message: message.text)
                          else if (message is CommunityDebateTimeoutMessage)
                            _CommunitySystemNotice(message: message.text)
                          else
                            ChatMessageTile(
                              message: message,
                              isMine:
                                  message.authorId == 'me' ||
                                  message.authorId == currentMember?.id,
                              avatar: _ChatAvatar(
                                userName: message.authorName,
                                imageUrl:
                                    profileImageByMemberId[message.authorId],
                                onTap: () =>
                                    _showUserProfileByUserId(message.authorId),
                              ),
                              trailing:
                                  widget.viewerRole ==
                                          CommunityChatViewerRole.host &&
                                      currentMember != null &&
                                      message.authorId != currentMember.id
                                  ? _NominateButton(
                                      onTap: () => _confirmAndStartDebate(
                                        message.authorId,
                                        opponentName: message.authorName,
                                      ),
                                    )
                                  : null,
                              onRetry: () => _retryMessage(message),
                            ),
                      ],
                    ),
                  ),
                ),
                ChatComposer(
                  controller: _messageController,
                  enabled: hasMyOpinion,
                  hintText: hasMyOpinion
                      ? '관전방에서 대화하기'
                      : '기조 발언 작성 후 채팅할 수 있습니다',
                  maxLines: 5,
                  onSend: _send,
                  leading: [
                    _CircleIconButton(
                      icon: Icons.add_rounded,
                      color: AppColors.accent,
                      foreground: AppColors.background,
                      onTap: () => _showOpinionSheet(initialOpinion: myOpinion),
                    ),
                    _CircleIconButton(
                      icon: Icons.image_outlined,
                      color: AppColors.surfaceElevated,
                      foreground: AppColors.textSecondary,
                      onTap: hasMyOpinion ? () {} : null,
                    ),
                  ],
                ),
              ],
            ),
            _CommunityToast(
              visible: _showRejectedToast,
              icon: Icons.block_rounded,
              message: _rejectedToastMessage,
            ),
          ],
        ),
      ),
    );
  }

  void _handleBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }
    context.go('/');
  }

  void _showDebateInfo() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (_) => DebateStartDialog(
        community: widget.community,
        showActionButtons: false,
      ),
    );
  }

  void _showDebateResultPopup(String debateId) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (dialogContext) => DebateResultPopup(
        debateId: debateId,
        onClose: () => Navigator.pop(dialogContext),
      ),
    );
  }

  Future<void> _showCommunityMembers() async {
    final currentMember = ref.read(currentMemberProvider);
    if (currentMember == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('내 프로필을 불러오지 못했습니다.')));
      return;
    }

    final List<CommunityMemberSummary> members;
    try {
      members = await ref.read(
        communityMembersProvider(widget.community.id).future,
      );
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('커뮤니티 멤버를 불러오지 못했습니다.')));
      }
      return;
    }
    if (!mounted) {
      return;
    }

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '커뮤니티 참여자 닫기',
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 329),
            child: SizedBox(
              width: MediaQuery.sizeOf(dialogContext).width - 74,
              height: double.infinity,
              child: Consumer(
                builder: (context, dialogRef, child) {
                  final latestMembers = dialogRef
                      .watch(communityMembersProvider(widget.community.id))
                      .asData
                      ?.value;
                  final visibleMembers = latestMembers ?? members;
                  CommunityMemberSummary? currentMembership;
                  for (final membership in visibleMembers) {
                    if (membership.id == currentMember.id) {
                      currentMembership = membership;
                      break;
                    }
                  }
                  return CommunityMember(
                    userName: currentMember.displayName,
                    currentMemberId: currentMember.id,
                    profileImageUrl: currentMember.profileImageUrl,
                    userScore: currentMember.score,
                    members: visibleMembers,
                    initialWantsToDebate:
                        currentMembership?.wantsToDebate ?? true,
                    onDebateIntentChanged: (wantsToDebate) async {
                      await dialogRef
                          .read(communityRepositoryProvider)
                          .updateCommunityDebateIntent(
                            communityId: widget.community.id,
                            wantsToDebate: wantsToDebate,
                          );
                      dialogRef.invalidate(
                        communityMembersProvider(widget.community.id),
                      );
                    },
                    onProfileTap: () => _showUserProfileByUserId(
                      currentMember.id,
                      allowDebate: false,
                    ),
                    onMemberProfileTap: (memberId) => _showUserProfileByUserId(
                      memberId,
                      allowDebate: memberId != currentMember.id,
                    ),
                    onClose: () => Navigator.pop(dialogContext),
                    showHostActions:
                        widget.viewerRole == CommunityChatViewerRole.host,
                    onDeleteCommunity: () =>
                        _showHostActionFeedback('커뮤니티 삭제 기능은 준비 중입니다.'),
                    onLeaveCommunity: () =>
                        _confirmLeaveCommunity(dialogContext),
                    onReport: () => _showHostActionFeedback('신고 기능은 준비 중입니다.'),
                  );
                },
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

  void _showHostActionFeedback(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showDebateRequestRejectedToast([
    String message = '상대방이 토론 요청을 거부했어요.',
  ]) {
    _rejectedToastTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _rejectedToastMessage = message;
      _showRejectedToast = true;
    });
    _rejectedToastTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showRejectedToast = false);
    });
  }

  Future<void> _confirmLeaveCommunity(BuildContext memberPanelContext) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (dialogContext) => AppConfirmationDialog(
        icon: Icons.logout_rounded,
        title: '채팅방을 나가시겠습니까?',
        description: '참여 정보와 기조 발언이 삭제되며, 다시 입장하면 기조 발언을 새로 작성해야 합니다.',
        cancelLabel: '취소',
        confirmLabel: '나가기',
        onCancel: () => Navigator.pop(dialogContext, false),
        onConfirm: () => Navigator.pop(dialogContext, true),
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(communityRepositoryProvider)
          .leaveCommunity(widget.community.id);
      ref.read(enteredCommunityProvider.notifier).markLeft(widget.community.id);
      ref.invalidate(communitiesProvider);
      ref.invalidate(communityMembersProvider(widget.community.id));
      ref.invalidate(communityOpinionHistoryProvider(widget.community.id));
      if (!mounted) return;
      if (memberPanelContext.mounted) {
        Navigator.pop(memberPanelContext);
      }
      context.go('/');
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('채팅방에서 나가지 못했습니다.')));
    }
  }

  void _showObserverView() {
    if (_observerDialogRoute?.isActive == true) return;
    unawaited(
      showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: '관전하기 닫기',
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          _observerDialogRoute = ModalRoute.of(dialogContext);
          return _CommunityObserverDialog(
            communityId: widget.community.id,
            onClose: _closeObserverView,
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, -0.04),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
      ).whenComplete(() => _observerDialogRoute = null),
    );
  }

  void _closeObserverView() {
    final route = _observerDialogRoute;
    if (route != null && route.isActive && mounted) {
      Navigator.of(context, rootNavigator: true).removeRoute(route);
    }
  }

  Future<void> _showOpinionSheet({
    CommunityOpinionMessage? initialOpinion,
  }) async {
    await showModalBottomSheet<CommunityOpinionDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (sheetContext) {
        return CommunityOpinionSheet(
          initialDraft: initialOpinion == null
              ? null
              : CommunityOpinionDraft(
                  claim: initialOpinion.claim,
                  reasons: initialOpinion.reasons,
                ),
          onSubmit: _submitOpinion,
        );
      },
    );
  }

  CommunityOpinionMessage? _findMemberOpinion(
    List<ChatMessage>? opinions,
    String memberId,
  ) {
    if (opinions == null) return null;
    for (final opinion in opinions.whereType<CommunityOpinionMessage>()) {
      if (opinion.authorId == memberId) return opinion;
    }
    return null;
  }

  Future<void> _submitOpinion(CommunityOpinionDraft draft) async {
    try {
      await ref
          .read(saveCommunityOpinionProvider(widget.community.id).notifier)
          .save(claim: draft.claim, reasons: draft.reasons);
    } on Object {
      // 모바일 네트워크에서 DB 저장 직후 ACK만 유실될 수 있다. 같은 기조 발언이
      // REST 이력에 존재하면 저장 성공으로 복구해 사용자를 팝업에 가두지 않는다.
      if (await _isOpinionStored(draft)) {
        _refreshOpinionData();
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('기조 발언을 저장하지 못했습니다.')));
      }
      rethrow;
    }
    _refreshOpinionData();
  }

  Future<bool> _isOpinionStored(CommunityOpinionDraft draft) async {
    final currentMember = ref.read(currentMemberProvider);
    if (currentMember == null) return false;

    try {
      final opinions = await ref
          .read(communityChatHistoryRepositoryProvider)
          .fetchOpinions(widget.community.id);
      return opinions.whereType<CommunityOpinionMessage>().any(
        (opinion) =>
            opinion.authorId == currentMember.id &&
            opinion.claim == draft.claim &&
            listEquals(opinion.reasons, draft.reasons),
      );
    } on Object {
      return false;
    }
  }

  void _refreshOpinionData() {
    ref.invalidate(communityOpinionHistoryProvider(widget.community.id));
    final currentMember = ref.read(currentMemberProvider);
    if (currentMember != null) {
      ref.invalidate(
        communityUserProfileProvider((
          communityId: widget.community.id,
          userId: currentMember.id,
        )),
      );
    }
  }

  // 시스템 알림과 일반 메시지를 서버 생성 시간 기준으로 섞어 보여준다.
  List<ChatMessage> _orderedMessagesWithHistory(
    List<ChatMessage> messageHistory,
    List<ChatMessage> opinionHistory,
  ) {
    final messagesById = <String, ChatMessage>{
      for (final message in messageHistory) message.id: message,
      for (final message in opinionHistory) message.id: message,
      for (final message in _timeline.orderedMessages) message.id: message,
    };
    return messagesById.values.toList()
      ..sort((left, right) => left.createdAt.compareTo(right.createdAt));
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

  Future<void> _sendText(String text, {String? retryClientMessageId}) async {
    // 서버 push가 돌아오면 이 ID로 pending 말풍선과 서버 메시지를 병합한다.
    final clientMessageId =
        retryClientMessageId ??
        'client-${DateTime.now().microsecondsSinceEpoch}';

    final currentMember = ref.read(currentMemberProvider);
    final pendingMessage = ChatMessage(
      id: clientMessageId,
      scopeId: widget.community.id,
      clientMessageId: clientMessageId,
      authorId: currentMember?.id ?? 'me',
      authorName: currentMember?.displayName ?? '나',
      text: text,
      createdAt: DateTime.now(),
      deliveryStatus: ChatMessageDeliveryStatus.pending,
    );

    _timeline.addPending(pendingMessage);
    // 내가 보낸 메시지는 사용자의 현재 작업 결과이므로 항상 아래로 이동한다.
    _scrollToBottomAfterBuild();

    try {
      await ref
          .read(sendChatMessageProvider(widget.community.id).notifier)
          .send(
            authorId: pendingMessage.authorId,
            text: pendingMessage.text,
            clientMessageId: clientMessageId,
          );
    } on Object {
      if (!mounted) {
        return;
      }
      _timeline.markFailed(clientMessageId);
      // 실패 라벨도 방금 보낸 메시지의 일부라 사용자가 바로 볼 수 있게 유지한다.
      _scrollToBottomAfterBuild();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('메시지를 보내지 못했습니다.')));
    }
  }

  Future<void> _retryMessage(ChatMessage failedMessage) async {
    _timeline.removeById(failedMessage.id);

    await _sendText(
      failedMessage.text,
      retryClientMessageId: failedMessage.clientMessageId,
    );
  }

  // 서버 이벤트 타입을 화면 상태 변경으로 변환한다.
  void _mergeRealtimeEvent(CommunityChatEvent event) {
    if (!mounted || event.communityId != widget.community.id) {
      return;
    }

    if (event.type == CommunityChatEventType.debateStarted) {
      _closeDebateRequestWaiting();
      ref.invalidate(activeCommunityDebateProvider(widget.community.id));
      final memberId = ref.read(currentMemberProvider)?.id;
      final isParticipant =
          memberId != null &&
          (memberId == event.sideASpeakerId ||
              memberId == event.sideBSpeakerId);
      if (isParticipant && !_navigatingToDebate) {
        final debateId = event.debateId;
        if (debateId != null) {
          unawaited(_openDebate(debateId));
        }
      }
      return;
    }

    if (event.type == CommunityChatEventType.debateRequested) {
      final invitation = event.debateInvitation;
      if (invitation != null) {
        unawaited(_showDebateInvitation(invitation));
      }
      return;
    }

    if (event.type == CommunityChatEventType.debateRequestRejected) {
      _closeDebateRequestWaiting(event.invitationId);
      _showDebateRequestRejectedToast();
      return;
    }

    if (event.type == CommunityChatEventType.debateRequestExpired) {
      if (_visibleDebateInvitationId == event.invitationId) {
        _closeDebateInvitation(event.invitationId!);
      } else if (_visibleOutgoingDebateInvitationId == event.invitationId) {
        _closeDebateRequestWaiting(event.invitationId);
        _showDebateRequestRejectedToast('상대방이 응답하지 않아 토론 요청이 거부되었어요.');
      }
      return;
    }

    if (event.type == CommunityChatEventType.debateEnded) {
      _closeObserverView();
      ref.invalidate(activeCommunityDebateProvider(widget.community.id));
      return;
    }

    if (event.type == CommunityChatEventType.memberDebateIntentChanged) {
      ref.invalidate(communityMembersProvider(widget.community.id));
      return;
    }

    if (event.type == CommunityChatEventType.error) {
      if (event.commandId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(event.errorMessage ?? '채팅 연결 오류가 발생했습니다.')),
        );
      }
      return;
    }

    if (event.type == CommunityChatEventType.messageCreated ||
        event.type == CommunityChatEventType.messageAcknowledged) {
      // 서버 저장이 완료된 이벤트를 받으면 재입장용 REST 이력도 최신화한다.
      ref.invalidate(communityChatHistoryProvider(widget.community.id));
    } else if (event.type == CommunityChatEventType.opinionSubmitted ||
        event.type == CommunityChatEventType.opinionAcknowledged) {
      ref.invalidate(communityOpinionHistoryProvider(widget.community.id));
    }

    final wasNearBottom = _isNearBottom;
    final message = event.message;
    if (message != null) {
      _timeline.upsert(message);
    }
    if (wasNearBottom) {
      _scrollToBottomAfterBuild();
    }
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
  Future<void> _showUserProfileByUserId(
    String userId, {
    bool allowDebate = true,
  }) async {
    final CommunityUserProfile profile;
    var wantsToDebate = false;
    final provider = communityUserProfileProvider((
      communityId: widget.community.id,
      userId: userId,
    ));
    try {
      ref.invalidate(provider);
      profile = await ref.read(provider.future);
    } on Object {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('프로필을 불러오지 못했습니다.')));
      return;
    }

    try {
      final members = await ref.read(
        communityMembersProvider(widget.community.id).future,
      );
      for (final member in members) {
        if (member.id == userId) {
          wantsToDebate = member.wantsToDebate;
          break;
        }
      }
    } on Object {
      // 준비 상태를 확인할 수 없으면 토론 시작을 보수적으로 차단한다.
      wantsToDebate = false;
    }

    if (!mounted) {
      return;
    }

    _showUserProfile(
      profile,
      allowDebate: allowDebate,
      wantsToDebate: wantsToDebate,
    );
  }

  // 채팅방 위에 프로필 팝업을 띄우고, 토론하기 액션을 실제 토론방으로 연결한다.
  void _showUserProfile(
    CommunityUserProfile profile, {
    bool allowDebate = true,
    bool wantsToDebate = false,
  }) {
    final currentMemberId = ref.read(currentMemberProvider)?.id;
    final showDebateAction =
        allowDebate &&
        widget.community.isOwnedByCurrentUser &&
        profile.userId != currentMemberId;
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
              profileImageUrl: profile.profileImageUrl,
              claim: profile.claim,
              reasons: profile.reasons,
              role: showDebateAction
                  ? DebatePopupRole.host
                  : DebatePopupRole.participant,
              isDebateReady: wantsToDebate,
              onClose: () => Navigator.pop(dialogContext),
              onDebate: showDebateAction && wantsToDebate
                  ? () async {
                      Navigator.pop(dialogContext);
                      await _confirmAndStartDebate(
                        profile.userId,
                        opponentName: profile.userName,
                        opponentProfileImageUrl: profile.profileImageUrl,
                      );
                    }
                  : null,
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmAndStartDebate(
    String opponentMemberId, {
    required String opponentName,
    String? opponentProfileImageUrl,
  }) async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      return;
    }

    if (widget.community.host.id == opponentMemberId) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('본인과는 토론을 시작할 수 없습니다.')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (_) => DebateStartDialog(community: widget.community),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      _startingDebate = true;
      final invitation = await ref
          .read(communityRepositoryProvider)
          .requestDebate(
            community: widget.community,
            opponentMemberId: opponentMemberId,
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      unawaited(
        _showDebateRequestWaiting(
          invitation,
          opponentName: opponentName,
          opponentProfileImageUrl: opponentProfileImageUrl,
        ),
      );
    } on Object {
      if (!mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('토론을 시작하지 못했습니다.')));
    } finally {
      _startingDebate = false;
    }
  }

  Future<void> _showDebateRequestWaiting(
    CommunityDebateInvitation invitation, {
    required String opponentName,
    String? opponentProfileImageUrl,
  }) async {
    if (!mounted ||
        _visibleOutgoingDebateInvitationId != null ||
        invitation.expiresAt.isBefore(DateTime.now())) {
      return;
    }

    _visibleOutgoingDebateInvitationId = invitation.id;
    final remaining = invitation.expiresAt.difference(DateTime.now());
    late final Timer timeout;
    final dialogFuture = showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (_) => _DebateRequestWaitingDialog(
        opponentName: opponentName,
        opponentProfileImageUrl: opponentProfileImageUrl,
        expiresAt: invitation.expiresAt,
      ),
    );
    timeout = Timer(remaining, () {
      if (_visibleOutgoingDebateInvitationId != invitation.id) return;
      _closeDebateRequestWaiting(invitation.id);
      _showDebateRequestRejectedToast('상대방이 응답하지 않아 토론 요청이 거부되었어요.');
    });
    await dialogFuture;
    timeout.cancel();
    if (_visibleOutgoingDebateInvitationId == invitation.id) {
      _visibleOutgoingDebateInvitationId = null;
    }
  }

  void _closeDebateRequestWaiting([String? invitationId]) {
    final visibleId = _visibleOutgoingDebateInvitationId;
    if (!mounted ||
        visibleId == null ||
        (invitationId != null && invitationId != visibleId)) {
      return;
    }
    _visibleOutgoingDebateInvitationId = null;
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _showDebateInvitation(
    CommunityDebateInvitation invitation,
  ) async {
    if (!mounted || _visibleDebateInvitationId != null) return;
    final remaining = invitation.expiresAt.difference(DateTime.now());
    if (remaining <= Duration.zero) return;

    _visibleDebateInvitationId = invitation.id;
    Timer? timeout;
    final responseFuture = showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (dialogContext) => AppConfirmationDialog(
        header: _DebateInvitationCountdown(expiresAt: invitation.expiresAt),
        title: '${invitation.hostName}님으로부터 토론 요청이 왔습니다.',
        description: '토론방에 입장하시겠습니까?\n5초 안에 응답하지 않으면 자동으로 거부됩니다.',
        cancelLabel: '거부',
        confirmLabel: '확인',
        descriptionFontSize: 15,
        onCancel: () => _closeDebateInvitation(invitation.id, false),
        onConfirm: () => _closeDebateInvitation(invitation.id, true),
      ),
    );
    timeout = Timer(remaining, () {
      _closeDebateInvitation(invitation.id);
    });
    final accepted = await responseFuture;
    timeout.cancel();
    if (_visibleDebateInvitationId == invitation.id) {
      _visibleDebateInvitationId = null;
    }
    if (!mounted || accepted == null) return;

    try {
      final repository = ref.read(communityRepositoryProvider);
      if (!accepted) {
        await repository.rejectDebateInvitation(
          communityId: widget.community.id,
          invitationId: invitation.id,
        );
        return;
      }
      final debateId = await repository.acceptDebateInvitation(
        communityId: widget.community.id,
        invitationId: invitation.id,
      );
      if (mounted) await _openDebate(debateId);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('토론 요청 응답을 처리하지 못했습니다.')));
      }
    }
  }

  void _closeDebateInvitation(String invitationId, [bool? accepted]) {
    if (!mounted || _visibleDebateInvitationId != invitationId) return;
    _visibleDebateInvitationId = null;
    Navigator.of(context, rootNavigator: true).pop(accepted);
  }

  Future<void> _openDebate(String debateId) async {
    if (!mounted || _navigatingToDebate) return;
    _navigatingToDebate = true;
    try {
      await context.push(
        '/communities/${widget.community.id}/debate?debateId=$debateId',
      );
    } finally {
      _navigatingToDebate = false;
      if (mounted) {
        ref.invalidate(activeCommunityDebateProvider(widget.community.id));
      }
    }
  }
}

class _DebateInvitationCountdown extends StatefulWidget {
  const _DebateInvitationCountdown({required this.expiresAt});

  final DateTime expiresAt;

  @override
  State<_DebateInvitationCountdown> createState() =>
      _DebateInvitationCountdownState();
}

class _DebateRequestWaitingDialog extends StatelessWidget {
  const _DebateRequestWaitingDialog({
    required this.opponentName,
    required this.opponentProfileImageUrl,
    required this.expiresAt,
  });

  final String opponentName;
  final String? opponentProfileImageUrl;
  final DateTime expiresAt;

  @override
  Widget build(BuildContext context) {
    final imageUrl = opponentProfileImageUrl?.trim();
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 354),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DebateInvitationCountdown(expiresAt: expiresAt),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.surfaceElevated,
                backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                    ? NetworkImage(imageUrl)
                    : null,
                child: imageUrl == null || imageUrl.isEmpty
                    ? const Icon(
                        Icons.person_rounded,
                        color: AppColors.textMuted,
                        size: 32,
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                '$opponentName님의 응답을 기다리고 있어요',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 18,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '5초 안에 응답이 없으면\n요청이 자동으로 취소됩니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFA7B4BF),
                  fontSize: 15,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DebateInvitationCountdownState extends State<_DebateInvitationCountdown>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(seconds: 5);
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final remaining = widget.expiresAt.difference(DateTime.now());
    final remainingFraction =
        remaining.inMicroseconds.clamp(0, _duration.inMicroseconds) /
        _duration.inMicroseconds;
    _controller = AnimationController(vsync: this, duration: _duration)
      ..reverse(from: remainingFraction);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = _controller.value;
        final seconds = (progress * _duration.inSeconds).ceil();
        final color = seconds <= 2
            ? const Color(0xFFF26A4F)
            : AppColors.primary;

        return SizedBox.square(
          dimension: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox.square(
                dimension: 52,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  strokeCap: StrokeCap.round,
                  backgroundColor: AppColors.surfaceElevated,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text(
                '$seconds',
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CommunityObserverDialog extends ConsumerStatefulWidget {
  const _CommunityObserverDialog({
    required this.communityId,
    required this.onClose,
  });

  final String communityId;
  final VoidCallback onClose;

  @override
  ConsumerState<_CommunityObserverDialog> createState() =>
      _CommunityObserverDialogState();
}

class _CommunityObserverDialogState
    extends ConsumerState<_CommunityObserverDialog> {
  late Future<DebateDetail?> _activeDebate;
  ProviderSubscription<AsyncValue<DebateChatRealtimeEvent>>? _debateEventsSub;
  String? _subscribedDebateId;

  @override
  void initState() {
    super.initState();
    _activeDebate = _fetchActiveDebate();
  }

  Future<DebateDetail?> _fetchActiveDebate() {
    return ref
        .read(debateChatRepositoryProvider)
        .getActiveCommunityDebate(widget.communityId);
  }

  void _retryActiveDebate() {
    setState(() => _activeDebate = _fetchActiveDebate());
  }

  @override
  void dispose() {
    _debateEventsSub?.close();
    super.dispose();
  }

  void _listenToDebateEvents(String debateId) {
    if (_subscribedDebateId == debateId) {
      return;
    }

    _debateEventsSub?.close();
    _subscribedDebateId = debateId;
    _debateEventsSub = ref.listenManual<AsyncValue<DebateChatRealtimeEvent>>(
      debateChatEventsProvider(debateId),
      (previous, next) {
        final event = next.asData?.value;
        if (event?.type == DebateChatRealtimeEventType.turnFinalized) {
          ref.invalidate(finalizedDebateTurnsProvider(debateId));
        } else if (event?.type == DebateChatRealtimeEventType.debateEnded) {
          widget.onClose();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DebateDetail?>(
      future: _activeDebate,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ObserverView(
            items: const [],
            isLoading: true,
            onClose: widget.onClose,
          );
        }

        if (snapshot.hasError) {
          return ObserverView(
            items: const [],
            errorMessage: '진행 중인 토론을 불러오지 못했습니다.',
            onRetry: _retryActiveDebate,
            onClose: widget.onClose,
          );
        }

        final debate = snapshot.data;
        if (debate == null) {
          return ObserverView(
            items: const [],
            emptyMessage: '현재 진행 중인 토론이 없습니다.',
            onClose: widget.onClose,
          );
        }

        _listenToDebateEvents(debate.id);

        return ref
            .watch(finalizedDebateTurnsProvider(debate.id))
            .when(
              data: (turns) => ObserverView(
                items: _observerItemsFromTurns(turns, debate),
                onClose: widget.onClose,
                onVote: (turnId, vote) => _voteOnTurn(
                  debateId: debate.id,
                  turnId: turnId,
                  vote: vote,
                ),
              ),
              loading: () => ObserverView(
                items: const [],
                isLoading: true,
                onClose: widget.onClose,
              ),
              error: (error, stackTrace) => ObserverView(
                items: const [],
                errorMessage: '토론 발언을 불러오지 못했습니다.',
                onRetry: () =>
                    ref.invalidate(finalizedDebateTurnsProvider(debate.id)),
                onClose: widget.onClose,
              ),
            );
      },
    );
  }

  List<ObserverCommentItem> _observerItemsFromTurns(
    List<DebateFinalizedTurn> turns,
    DebateDetail debate,
  ) {
    return turns.map((turn) {
      final isSideA = turn.speakerSide == 'SIDE_A';
      final speaker = isSideA ? debate.sideASpeaker : debate.sideBSpeaker;
      return ObserverCommentItem(
        turnId: turn.id,
        userName: speaker.displayName,
        content: turn.content,
        likes: turn.likeCount,
        dislikes: turn.dislikeCount,
        isHost: isSideA,
        avatarUrl: speaker.profileImageUrl,
      );
    }).toList();
  }

  Future<ObserverVoteResult> _voteOnTurn({
    required String debateId,
    required String turnId,
    required ObserverVoteType? vote,
  }) async {
    if (ref.read(currentMemberProvider) == null) {
      throw StateError('로그인이 필요합니다.');
    }

    final repository = ref.read(debateChatRepositoryProvider);
    final summary = vote == null
        ? await repository.removeTurnVote(debateId: debateId, turnId: turnId)
        : await repository.setTurnVote(
            debateId: debateId,
            turnId: turnId,
            type: vote == ObserverVoteType.like
                ? DebateTurnVoteType.like
                : DebateTurnVoteType.dislike,
          );

    ref.invalidate(finalizedDebateTurnsProvider(debateId));
    return ObserverVoteResult(
      likes: summary.likeCount,
      dislikes: summary.dislikeCount,
      selectedVote: vote,
    );
  }
}

class _WatchRoomHeader extends StatefulWidget {
  const _WatchRoomHeader({
    required this.community,
    required this.activeDebate,
    required this.viewerRole,
    required this.onBack,
    required this.onTitleTap,
    required this.onWatch,
    required this.onMore,
  });

  final Community community;
  final DebateDetail? activeDebate;
  final CommunityChatViewerRole viewerRole;
  final VoidCallback onBack;
  final VoidCallback onTitleTap;
  final VoidCallback onWatch;
  final VoidCallback onMore;

  @override
  State<_WatchRoomHeader> createState() => _WatchRoomHeaderState();
}

class _WatchRoomHeaderState extends State<_WatchRoomHeader> {
  bool _isDebaterPreviewCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final activeDebate = widget.activeDebate;
    final hasOpponent = activeDebate != null;

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
                  child: InkWell(
                    onTap: widget.onTitleTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
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
                          name:
                              activeDebate?.sideASpeaker.displayName ??
                              widget.community.host.name,
                          profileImageUrl:
                              activeDebate?.sideASpeaker.profileImageUrl,
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
                          name: hasOpponent
                              ? activeDebate.sideBSpeaker.displayName
                              : '토론 상대 찾는 중...',
                          profileImageUrl: hasOpponent
                              ? activeDebate.sideBSpeaker.profileImageUrl
                              : null,
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
    this.profileImageUrl,
  });

  final String name;
  final bool active;
  final String? profileImageUrl;

  @override
  Widget build(BuildContext context) {
    final imageUrl = profileImageUrl?.trim();
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
          child: !active
              ? const SizedBox.shrink()
              : imageUrl == null || imageUrl.isEmpty
              ? _ChatAvatarFallback(userName: name)
              : Image.network(
                  imageUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (_, _, _) =>
                      _ChatAvatarFallback(userName: name),
                ),
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

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({
    required this.userName,
    required this.imageUrl,
    required this.onTap,
  });

  final String userName;
  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = imageUrl?.trim();
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipOval(
        child: SizedBox(
          width: 36,
          height: 36,
          child: normalizedUrl == null || normalizedUrl.isEmpty
              ? _ChatAvatarFallback(userName: userName)
              : Image.network(
                  normalizedUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      _ChatAvatarFallback(userName: userName),
                ),
        ),
      ),
    );
  }
}

class _ChatAvatarFallback extends StatelessWidget {
  const _ChatAvatarFallback({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    final normalizedName = userName.trim();
    return Container(
      alignment: Alignment.center,
      color: AppColors.primarySoft,
      child: Text(
        normalizedName.isEmpty ? '?' : normalizedName.characters.first,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
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
    return Tooltip(
      message: '토론 상대로 지목',
      child: InkWell(
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
      ),
    );
  }
}

class _DiscussionGuide extends StatelessWidget {
  const _DiscussionGuide({required this.message, required this.onStatementTap});

  final CommunityOpinionMessage message;
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

class _CommunitySystemNotice extends StatelessWidget {
  const _CommunitySystemNotice({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.textMuted.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 2),
              InkWell(
                onTap: onAction,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
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
          ],
        ),
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

class _CommunityToast extends StatelessWidget {
  const _CommunityToast({
    required this.visible,
    required this.icon,
    required this.message,
  });

  final bool visible;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final bottomOffset = 134 + MediaQuery.paddingOf(context).bottom;
    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomOffset,
      child: IgnorePointer(
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, 0.16),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: Center(
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.24),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      message,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
