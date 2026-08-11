import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/community_chat.dart';
import '../../domain/entities/community.dart';
import '../../domain/entities/community_user_profile.dart';
import '../../domain/entities/debate_chat_realtime.dart';
import '../controllers/chat_message_timeline.dart';
import '../providers/community_chat_providers.dart';
import '../providers/community_providers.dart';
import '../providers/community_user_profile_providers.dart';
import '../providers/debate_chat_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../widgets/community_host_member.dart';
import '../widgets/community_opinion.dart';
import '../widgets/chat_composer.dart';
import '../widgets/chat_message_tile.dart';
import '../widgets/debate_popup_sheet.dart';
import '../widgets/debate_forfeit_dialog.dart';
import '../widgets/debate_start_dialog.dart';
import '../widgets/observer_view.dart';

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
      final debate = await ref
          .read(debateChatRepositoryProvider)
          .getActiveCommunityDebate(widget.community.id);
      if (!mounted || debate == null || debate.viewerSide == null) return;
      _navigatingToDebate = true;
      context.push(
        '/communities/${widget.community.id}/debate?debateId=${debate.id}',
      );
    } on Object {
      // 활성 토론 복구 실패는 채팅 입장을 막지 않는다.
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMember = ref.watch(currentMemberProvider);
    final messageHistoryAsync = ref.watch(
      communityChatHistoryProvider(widget.community.id),
    );
    final opinionHistoryAsync = ref.watch(
      communityOpinionHistoryProvider(widget.community.id),
    );
    final messageHistory = messageHistoryAsync.asData?.value;
    final opinionHistory = opinionHistoryAsync.asData?.value;
    final visibleMessages = _orderedMessagesWithHistory(
      messageHistory ?? const <CommunityChatMessage>[],
      opinionHistory ?? const <CommunityChatMessage>[],
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
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _WatchRoomHeader(
              community: widget.community,
              viewerRole: widget.viewerRole,
              onBack: _handleBack,
              onTitleTap: _showDebateInfo,
              onWatch: _showObserverView,
              onMore: () => _showCommunityMembers(),
            ),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  for (final message in visibleMessages)
                    if (message.type == CommunityChatMessageType.opinionNotice)
                      _DiscussionGuide(
                        message: message,
                        onStatementTap: () =>
                            _showUserProfileByUserId(message.authorId),
                      )
                    else
                      ChatMessageTile(
                        message: message,
                        isMine:
                            message.authorId == 'me' ||
                            message.authorId == currentMember?.id,
                        avatar: _ChatAvatar(
                          accent: message.accentAvatar,
                          onTap: () =>
                              _showUserProfileByUserId(message.authorId),
                        ),
                        trailing: _NominateButton(onTap: () {}),
                        onRetry: () => _retryMessage(message),
                      ),
                ],
              ),
            ),
            ChatComposer(
              controller: _messageController,
              enabled: hasMyOpinion,
              hintText: hasMyOpinion ? '관전방에서 대화하기' : '기조 발언 작성 후 채팅할 수 있습니다',
              onSend: _send,
              leading: [
                _CircleIconButton(
                  icon: Icons.add_rounded,
                  color: AppColors.accent,
                  foreground: AppColors.background,
                  onTap: widget.viewerRole == CommunityChatViewerRole.host
                      ? null
                      : _showOpinionSheet,
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

    CommunityMemberSummary? currentMembership;
    for (final membership in members) {
      if (membership.id == currentMember.id) {
        currentMembership = membership;
        break;
      }
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
              child: CommunityMember(
                userName: currentMember.displayName,
                currentMemberId: currentMember.id,
                profileImageUrl: currentMember.profileImageUrl,
                userScore: currentMember.score,
                members: members,
                initialWantsToDebate: currentMembership?.wantsToDebate ?? true,
                onDebateIntentChanged: (wantsToDebate) async {
                  await ref
                      .read(communityRepositoryProvider)
                      .updateCommunityDebateIntent(
                        communityId: widget.community.id,
                        wantsToDebate: wantsToDebate,
                      );
                  ref.invalidate(communityMembersProvider(widget.community.id));
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
                onLeaveCommunity: () => _confirmLeaveCommunity(dialogContext),
                onReport: () => _showHostActionFeedback('신고 기능은 준비 중입니다.'),
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

  Future<void> _confirmLeaveCommunity(BuildContext memberPanelContext) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (dialogContext) => DebateConfirmationDialog(
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

  Future<void> _showObserverView() async {
    final activeDebate = await ref
        .read(debateChatRepositoryProvider)
        .getActiveCommunityDebate(widget.community.id);
    if (!mounted) return;
    final debateId = activeDebate?.id;
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '관전하기 닫기',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Consumer(
          builder: (context, dialogRef, child) {
            final turns = debateId == null
                ? null
                : dialogRef.watch(finalizedDebateTurnsProvider(debateId));
            final items =
                turns?.when(
                  data: _observerItemsFromTurns,
                  loading: _mockObserverItems,
                  error: (error, stackTrace) => _mockObserverItems(),
                ) ??
                _mockObserverItems();
            return ObserverView(
              items: items,
              onClose: () => Navigator.pop(dialogContext),
              onVote: debateId == null
                  ? null
                  : (turnId, vote) => _voteOnTurn(
                      debateId: debateId,
                      turnId: turnId,
                      vote: vote,
                    ),
            );
          },
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
    );
  }

  List<ObserverCommentItem> _observerItemsFromTurns(
    List<DebateFinalizedTurn> turns,
  ) {
    final opponent = widget.community.activeDebaters.firstWhere(
      (debater) => debater.name != widget.community.host.name,
      orElse: () => const Debater(
        name: 'Username',
        side: DebateSide.con,
        avatarColor: 0xFFFF7B2F,
      ),
    );
    return turns.map((turn) {
      final isSideA = turn.speakerSide == 'SIDE_A';
      return ObserverCommentItem(
        turnId: turn.id,
        userName: isSideA ? widget.community.host.name : opponent.name,
        content: turn.content,
        likes: turn.likeCount,
        dislikes: turn.dislikeCount,
        isHost: isSideA,
        avatarAsset: isSideA ? AppAssets.avatarBlue : AppAssets.avatarRed,
      );
    }).toList();
  }

  Future<ObserverVoteResult> _voteOnTurn({
    required String debateId,
    required String turnId,
    required ObserverVoteType? vote,
  }) async {
    final repository = ref.read(debateChatRepositoryProvider);
    if (ref.read(currentMemberProvider) == null) {
      throw StateError('로그인이 필요합니다.');
    }
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

  List<ObserverCommentItem> _mockObserverItems() {
    final opponent = widget.community.activeDebaters.firstWhere(
      (debater) => debater.name != widget.community.host.name,
      orElse: () => const Debater(
        name: 'Username',
        side: DebateSide.con,
        avatarColor: 0xFFFF7B2F,
      ),
    );
    final hostContent = widget.community.hostClaim.isEmpty
        ? '음모론이 아니라니까 그러네.\n내 주변에는 범죄자도 없고, 범죄도 안일어나니 경찰은 필요 없다는 발상과 다르지 않다.\n어이없는건 민경욱 투표지에서 수백여장이 이상한 투표지로 법원에서 가려졌음에도 당락 결정에 영향을 줄만한 숫자가 아니라고 기각시킨 것임.'
        : [
            widget.community.hostClaim,
            ...widget.community.hostReasons,
          ].join('\n');

    return [
      const ObserverCommentItem(
        userName: 'Username',
        content:
            '궁금해서 그러는데 서버까면 뭐가 나옴?\n그냥 각 지역 검표 데이터 들어가 있는게 서버 아님? 여기서 부정선거 증거를 어떻게 찾음?\n윤어게인 말마따나 수백만표의 가짜 표를 CCTV 모르게, 참관인들 모르게, 중간에 내부 밀고자 한 명도 없는 세력이 고작 서버에 증거를 남긴다는',
        likes: 12,
        dislikes: 3,
        avatarAsset: AppAssets.avatarRed,
      ),
      ObserverCommentItem(
        userName: widget.community.host.name,
        content: hostContent,
        likes: widget.community.observerCount > 1 ? 2 : 1,
        dislikes: 0,
        isHost: true,
        avatarAsset: AppAssets.avatarBlue,
      ),
      ObserverCommentItem(
        userName: opponent.name,
        content: '상대 입장도 들어봐야 할 것 같아요. 지금 쟁점은 증거가 실제로 남는 구조인지부터 정리해야 합니다.',
        likes: 4,
        dislikes: 1,
        avatarAsset: AppAssets.avatarRed,
      ),
    ];
  }

  Future<void> _showOpinionSheet() async {
    await showModalBottomSheet<CommunityOpinionDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (sheetContext) {
        return CommunityOpinionSheet(onSubmit: _submitOpinion);
      },
    );
  }

  Future<void> _submitOpinion(CommunityOpinionDraft draft) async {
    try {
      await ref
          .read(saveCommunityOpinionProvider(widget.community.id).notifier)
          .save(claim: draft.claim, reasons: draft.reasons);
      final currentMember = ref.read(currentMemberProvider);
      if (currentMember != null) {
        ref.invalidate(
          communityUserProfileProvider((
            communityId: widget.community.id,
            userId: currentMember.id,
          )),
        );
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('기조 발언을 저장하지 못했습니다.')));
      }
      rethrow;
    }
  }

  // 시스템 알림과 일반 메시지를 서버 생성 시간 기준으로 섞어 보여준다.
  List<CommunityChatMessage> _orderedMessagesWithHistory(
    List<CommunityChatMessage> messageHistory,
    List<CommunityChatMessage> opinionHistory,
  ) {
    final messagesById = <String, CommunityChatMessage>{
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

  Future<void> _sendText(String text) async {
    // 서버 push가 돌아오면 이 ID로 pending 말풍선과 서버 메시지를 병합한다.
    final clientMessageId = 'client-${DateTime.now().microsecondsSinceEpoch}';

    final currentMember = ref.read(currentMemberProvider);
    final pendingMessage = CommunityChatMessage(
      id: clientMessageId,
      communityId: widget.community.id,
      clientMessageId: clientMessageId,
      authorId: currentMember?.id ?? 'me',
      authorName: currentMember?.displayName ?? '나',
      text: text,
      createdAt: DateTime.now(),
      deliveryStatus: CommunityChatMessageDeliveryStatus.pending,
    );

    _timeline.addPending(pendingMessage);
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

  Future<void> _retryMessage(CommunityChatMessage failedMessage) async {
    _timeline.removeById(failedMessage.id);

    await _sendText(failedMessage.text);
  }

  // 서버 이벤트 타입을 화면 상태 변경으로 변환한다.
  void _mergeRealtimeEvent(CommunityChatEvent event) {
    if (!mounted || event.communityId != widget.community.id) {
      return;
    }

    if (event.type == CommunityChatEventType.debateStarted) {
      final memberId = ref.read(currentMemberProvider)?.id;
      final isParticipant =
          memberId != null &&
          (memberId == event.sideASpeakerId ||
              memberId == event.sideBSpeakerId);
      if (isParticipant && !_startingDebate && !_navigatingToDebate) {
        final debateId = event.debateId;
        if (debateId != null) {
          _navigatingToDebate = true;
          context.push(
            '/communities/${widget.community.id}/debate?debateId=$debateId',
          );
        }
      }
      return;
    }

    if (event.type == CommunityChatEventType.messageCreated) {
      // 서버 저장이 완료된 이벤트를 받으면 재입장용 REST 이력도 최신화한다.
      ref.invalidate(communityChatHistoryProvider(widget.community.id));
    } else if (event.type == CommunityChatEventType.opinionSubmitted) {
      ref.invalidate(communityOpinionHistoryProvider(widget.community.id));
    }

    final wasNearBottom = _isNearBottom;
    _timeline.applyEvent(event);
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

    if (!mounted) {
      return;
    }

    _showUserProfile(profile, allowDebate: allowDebate);
  }

  // 채팅방 위에 프로필 팝업을 띄우고, 토론하기 액션을 실제 토론방으로 연결한다.
  void _showUserProfile(
    CommunityUserProfile profile, {
    bool allowDebate = true,
  }) {
    final canStartDebate = allowDebate && widget.community.isOwnedByCurrentUser;
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
              role: canStartDebate
                  ? DebatePopupRole.host
                  : DebatePopupRole.participant,
              onClose: () => Navigator.pop(dialogContext),
              onDebate: canStartDebate
                  ? () async {
                      Navigator.pop(dialogContext);
                      await _confirmAndStartDebate(profile.userId);
                    }
                  : null,
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmAndStartDebate(String opponentMemberId) async {
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
      final debateId = await ref
          .read(communityRepositoryProvider)
          .createAndStartDebate(
            community: widget.community,
            opponentMemberId: opponentMemberId,
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      context.push(
        '/communities/${widget.community.id}/debate?debateId=$debateId',
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
}

class _WatchRoomHeader extends StatefulWidget {
  const _WatchRoomHeader({
    required this.community,
    required this.viewerRole,
    required this.onBack,
    required this.onTitleTap,
    required this.onWatch,
    required this.onMore,
  });

  final Community community;
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
