import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../community/domain/entities/community.dart';
import '../../../../shared/chat/domain/chat_message.dart';
import '../../../../shared/domain/entities/debate_side.dart';
import '../../domain/entities/debate_chat_realtime.dart';
import '../../domain/entities/debate_turn.dart';
import '../../../../shared/chat/presentation/controllers/chat_message_timeline.dart';
import '../providers/debate_chat_providers.dart';
import '../../../../shared/chat/presentation/widgets/chat_composer.dart';
import '../../../../shared/chat/presentation/widgets/chat_message_tile.dart';
import '../../../../shared/presentation/widgets/confirmation_dialog.dart';
import 'debate_forfeit_dialog.dart';
import 'debate_progress_sheet.dart';
import 'debate_popup_sheet.dart';
import 'debate_user_profile.dart';
import 'discussion_guide.dart';

class DebateRoom extends ConsumerStatefulWidget {
  const DebateRoom({
    required this.community,
    required this.debateId,
    required this.initialDebateDetail,
    this.isHost = true,
    super.key,
  });

  final Community community;
  final String debateId;
  final DebateDetail initialDebateDetail;
  final bool isHost;

  @override
  ConsumerState<DebateRoom> createState() => _DebateRoomState();
}

class _DebateParticipant {
  const _DebateParticipant({required this.name, required this.side});

  final String name;
  final DebateSide side;
}

class _DebateRoomState extends ConsumerState<DebateRoom> {
  static const _fallbackMaxTurnCharacterCount = 1000;

  final _messageController = TextEditingController();
  final _messageFocusNode = FocusNode();
  final _scrollController = ScrollController();
  final Map<String, String> _messageCommandIds = {};
  final Map<String, int> _currentDraftCharacterCounts = {};
  Timer? _limitNoticeTimer;
  Timer? _turnPassedNoticeTimer;
  Timer? _finalizeTimeoutTimer;
  Timer? _turnClockTimer;
  Timer? _totalClockTimer;
  Timer? _resultPollTimer;
  bool _showLimitNotice = false;
  bool _showTurnPassedNotice = false;
  bool _isFinalizingTurn = false;
  bool _hasReceivedSnapshot = false;
  bool _isDebateFinalized = false;
  String? _pendingFinalizeCommandId;
  DebateChatCurrentTurn? _serverCurrentTurn;
  DebateDetail? _debateDetail;
  bool _isExpired = false;
  bool _endDialogShown = false;
  bool _isForfeiting = false;
  bool _forfeitDialogVisible = false;
  bool _isRetryingJudge = false;
  bool _judgeRetryDialogVisible = false;
  DateTime? _judgeRetryPromptDismissedUntil;
  ValueNotifier<int>? _progressStepNotifier;
  late final ChatMessageTimeline _timeline;

  @override
  void initState() {
    super.initState();
    _debateDetail = widget.initialDebateDetail;
    _timeline = ChatMessageTimeline()..addListener(_handleTimelineChanged);
    _messageController.addListener(_handleMessageChanged);
    _messageFocusNode.addListener(_handleInputFocusChanged);
    unawaited(_loadDebateDetail());
  }

  @override
  void dispose() {
    _timeline.removeListener(_handleTimelineChanged);
    _timeline.dispose();
    _messageController.removeListener(_handleMessageChanged);
    _messageFocusNode.removeListener(_handleInputFocusChanged);
    _limitNoticeTimer?.cancel();
    _turnPassedNoticeTimer?.cancel();
    _finalizeTimeoutTimer?.cancel();
    _turnClockTimer?.cancel();
    _totalClockTimer?.cancel();
    _resultPollTimer?.cancel();
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    _progressStepNotifier = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<DebateChatRealtimeEvent>>(
      debateChatEventsProvider(widget.debateId),
      (previous, next) => next.whenData(_handleRealtimeEvent),
    );

    final host = _hostDebater;
    final opponent = _opponentDebater;
    final currentTurn = _displayCurrentTurn(host, opponent);
    final canAct = _canActOnCurrentTurn;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _showForfeitDialog();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
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
                      hostScore: _debateDetail?.sideASpeaker.score ?? 0,
                      opponentScore: _debateDetail?.sideBSpeaker.score ?? 0,
                      hostAvatarUrl:
                          _debateDetail?.sideASpeaker.profileImageUrl,
                      opponentAvatarUrl:
                          _debateDetail?.sideBSpeaker.profileImageUrl,
                      remainingLabel: _totalRemainingLabel,
                      remainingProgress: _totalRemainingProgress,
                      onOpponentTap: _showOpponentOpeningStatement,
                      onBack: _showForfeitDialog,
                    ),
                    Expanded(
                      child: ListView(
                        controller: _scrollController,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.only(top: 12, bottom: 18),
                        children: [
                          if (_isPreparing)
                            DiscussionGuide(
                              lines: [
                                '토론자가 결정되었습니다.',
                                '$_preparationRemainingSeconds초 뒤, 비프로스트의 문이 열립니다.',
                                '기조 발언을 탐색하거나 상대방과 인사를 나누세요.',
                              ],
                            )
                          else
                            DiscussionGuide(
                              lines: [
                                '두 세계가 연결되었습니다. 예의를 갖추어 토론에 임하세요.',
                                '${host.name}님, 당신의 세계를 증명할 ‘입론’을 시작하세요.',
                              ],
                            ),
                          for (final message in _timeline.orderedMessages)
                            ChatMessageTile(
                              message: message,
                              isMine: message.authorId == 'me',
                              avatar: _messageAvatar(message),
                              onRetry: () => _retryMessage(message),
                            ),
                        ],
                      ),
                    ),
                    _DebateTurnControl(
                      turn: currentTurn,
                      enabled: canAct && !_timeline.hasPendingMessages,
                      isSubmitting: _isFinalizingTurn,
                      characterCount: _currentTurnCharacterCount,
                      maxCharacterCount: _maxTurnCharacterCount,
                      onInfoTap: _showDebateProgress,
                      onSkip: _confirmFinalizeCurrentTurn,
                    ),
                    ChatComposer(
                      controller: _messageController,
                      focusNode: _messageFocusNode,
                      enabled:
                          canAct &&
                          !_isFinalizingTurn &&
                          _remainingTurnCharacterCount > 0,
                      hintText: _isPreparing
                          ? '준비 시간이 끝나면 입론을 시작할 수 있습니다'
                          : '${currentTurn.stage.label} 입력',
                      maxLength: _remainingTurnCharacterCount > 0
                          ? _remainingTurnCharacterCount
                          : null,
                      onLimitReached: _showMessageLimitNotice,
                      onSend: _sendMessage,
                      leading: [
                        _InputIconButton(
                          icon: Icons.image_outlined,
                          onTap: canAct && !_isFinalizingTurn ? () {} : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _DebateToast(
                visible: _showLimitNotice,
                icon: Icons.error_rounded,
                message: '이번 턴에서는 더이상 메시지를 보낼 수 없습니다.',
              ),
              _DebateToast(
                visible: _showTurnPassedNotice,
                icon: Icons.check_circle_rounded,
                message: '상대방에게 턴을 넘겼습니다.',
              ),
            ],
          ),
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

  void _handleTimelineChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleInputFocusChanged() {
    if (!_messageFocusNode.hasFocus) {
      return;
    }

    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        _scrollToLatestMessage();
      }
    });
  }

  _DebateParticipant get _hostDebater {
    final detail = _debateDetail ?? widget.initialDebateDetail;
    return _DebateParticipant(
      name: detail.sideASpeaker.displayName,
      side: DebateSide.pro,
    );
  }

  _DebateParticipant get _opponentDebater {
    final detail = _debateDetail ?? widget.initialDebateDetail;
    return _DebateParticipant(
      name: detail.sideBSpeaker.displayName,
      side: DebateSide.con,
    );
  }

  String? get _localWireSide => _debateDetail?.viewerSide;

  Widget _messageAvatar(ChatMessage message) {
    final detail = _debateDetail;
    DebateSpeaker? speaker;
    if (detail != null) {
      if (message.authorId == 'me') {
        speaker = detail.viewerSide == 'SIDE_B'
            ? detail.sideBSpeaker
            : detail.sideASpeaker;
      } else if (message.authorId == detail.sideASpeaker.id) {
        speaker = detail.sideASpeaker;
      } else if (message.authorId == detail.sideBSpeaker.id) {
        speaker = detail.sideBSpeaker;
      }
    }
    return _DebateAvatar(
      name: speaker?.displayName ?? message.authorName,
      profileImageUrl: speaker?.profileImageUrl,
    );
  }

  bool get _canActOnCurrentTurn {
    if (_localWireSide == null ||
        _isPreparing ||
        _isExpired ||
        _isFinalizingTurn ||
        _isDebateFinalized) {
      return false;
    }
    if (!_hasReceivedSnapshot) {
      return false;
    }
    return _serverCurrentTurn?.turnSide == _localWireSide;
  }

  DateTime? get _scheduledDebateStartAt =>
      _serverCurrentTurn?.startedAt ??
      _debateDetail?.startedAt ??
      widget.initialDebateDetail.startedAt;

  int get _preparationRemainingSeconds {
    final currentTurn = _serverCurrentTurn;
    if (currentTurn != null) {
      return currentTurn.preparationSecondsRemainingAt(DateTime.now());
    }
    final startsAt = _scheduledDebateStartAt;
    if (startsAt == null) return 0;
    final remainingMilliseconds = startsAt
        .difference(DateTime.now())
        .inMilliseconds;
    if (remainingMilliseconds <= 0) return 0;
    return (remainingMilliseconds + 999) ~/ 1000;
  }

  bool get _isPreparing => _preparationRemainingSeconds > 0;

  int get _confirmedTurnCharacterCount =>
      _currentDraftCharacterCounts.values.fold(0, (sum, value) => sum + value);

  int get _maxTurnCharacterCount =>
      _serverCurrentTurn?.maxTotalCharacters ?? _fallbackMaxTurnCharacterCount;

  int get _currentTurnCharacterCount =>
      _confirmedTurnCharacterCount + _messageController.text.characters.length;

  int get _remainingTurnCharacterCount =>
      (_maxTurnCharacterCount - _confirmedTurnCharacterCount).clamp(
        0,
        _maxTurnCharacterCount,
      );

  DebateTurn _displayCurrentTurn(
    _DebateParticipant host,
    _DebateParticipant opponent,
  ) {
    final turn = _serverCurrentTurn;
    if (turn == null) {
      return DebateTurn(
        stage: DebateStage.opening,
        side: host.side,
        speaker: host.name,
        content: '',
        remainingSeconds: _hasReceivedSnapshot ? 0 : 90,
      );
    }

    final isSideA = turn.turnSide == 'SIDE_A';
    final speaker = isSideA ? host : opponent;
    final elapsedSeconds = DateTime.now().difference(turn.startedAt).inSeconds;
    return DebateTurn(
      stage: switch (turn.phase) {
        'OPENING' => DebateStage.opening,
        'REBUTTAL_QUESTION' => DebateStage.rebuttalQuestion,
        'CLOSING' => DebateStage.closing,
        _ => DebateStage.opening,
      },
      side: isSideA ? DebateSide.pro : DebateSide.con,
      speaker: speaker.name,
      content: '',
      remainingSeconds: (turn.maxDurationSeconds - elapsedSeconds).clamp(
        0,
        turn.maxDurationSeconds,
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (!_canActOnCurrentTurn) {
      return;
    }
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }
    if (_confirmedTurnCharacterCount + text.characters.length >
        _maxTurnCharacterCount) {
      _showMessageLimitNotice();
      return;
    }

    _messageController.clear();
    await _sendText(text);
  }

  Future<void> _sendText(String text) async {
    final clientMessageId = 'client-${DateTime.now().microsecondsSinceEpoch}';
    final commandId = 'message-${DateTime.now().microsecondsSinceEpoch}';
    final pendingMessage = ChatMessage(
      id: clientMessageId,
      scopeId: widget.debateId,
      clientMessageId: clientMessageId,
      authorId: 'me',
      authorName: '나',
      text: text,
      createdAt: DateTime.now(),
      deliveryStatus: ChatMessageDeliveryStatus.pending,
    );

    _timeline.addPending(pendingMessage);
    _currentDraftCharacterCounts[clientMessageId] = text.characters.length;
    _messageCommandIds[commandId] = clientMessageId;
    HapticFeedback.selectionClick();
    _messageFocusNode.requestFocus();
    _scrollToLatestMessage();

    try {
      await ref
          .read(debateChatCommandServiceProvider)
          .sendMessage(
            debateId: widget.debateId,
            commandId: commandId,
            text: pendingMessage.text,
            clientMessageId: clientMessageId,
          );
    } on Object {
      _messageCommandIds.remove(commandId);
      _currentDraftCharacterCounts.remove(clientMessageId);
      if (!mounted) {
        return;
      }
      _timeline.markFailed(clientMessageId);
      _scrollToLatestMessage();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('메시지를 보내지 못했습니다.')));
    }
  }

  Future<void> _retryMessage(ChatMessage failedMessage) async {
    if (failedMessage.deliveryStatus != ChatMessageDeliveryStatus.failed) {
      return;
    }
    _timeline.removeById(failedMessage.id);
    await _sendText(failedMessage.text);
  }

  Future<void> _confirmFinalizeCurrentTurn() async {
    if (!_canActOnCurrentTurn || _timeline.hasPendingMessages) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (dialogContext) => const _TurnFinalizeDialog(),
    );
    if (confirmed == true && mounted) {
      await _finalizeCurrentTurn();
    }
  }

  Future<void> _finalizeCurrentTurn() async {
    if (!_canActOnCurrentTurn || _timeline.hasPendingMessages) {
      return;
    }

    final commandId = 'finalize-${DateTime.now().microsecondsSinceEpoch}';

    setState(() {
      _isFinalizingTurn = true;
      _pendingFinalizeCommandId = commandId;
    });
    _messageFocusNode.unfocus();
    _startFinalizeTimeout(commandId);

    try {
      await ref
          .read(debateChatCommandServiceProvider)
          .finalizeTurn(debateId: widget.debateId, commandId: commandId);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      _clearFinalizePending();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_finalizeErrorMessage(error))));
    }
  }

  void _handleRealtimeEvent(DebateChatRealtimeEvent event) {
    if (!mounted || event.debateId != widget.debateId) {
      return;
    }

    switch (event.type) {
      case DebateChatRealtimeEventType.connectionRestored:
        _currentDraftCharacterCounts.clear();
        _applyCurrentTurn(event.currentTurn);
        for (final message in event.draftMessages) {
          _mergeDraftMessage(message);
        }
        return;
      case DebateChatRealtimeEventType.messageAcknowledged:
        if (event.commandId != null) {
          _messageCommandIds.remove(event.commandId);
        }
        if (event.message != null) {
          _mergeDraftMessage(event.message!);
        }
        return;
      case DebateChatRealtimeEventType.messageCreated:
        if (event.message != null) {
          _mergeDraftMessage(event.message!);
        }
        return;
      case DebateChatRealtimeEventType.turnFinalized:
        unawaited(_refreshTurnAfterFinalized());
        return;
      case DebateChatRealtimeEventType.debateEnded:
        _handleDebateEnded(event.endReason);
        return;
      case DebateChatRealtimeEventType.error:
        _handleRealtimeError(event);
        return;
    }
  }

  void _mergeDraftMessage(DebateChatDraftMessage draft) {
    _currentDraftCharacterCounts[draft.clientMessageId ?? draft.id] =
        draft.content.characters.length;
    final isMine = draft.speakerSide == _localWireSide;
    _timeline.upsert(
      ChatMessage(
        id: draft.id,
        scopeId: widget.debateId,
        clientMessageId: draft.clientMessageId,
        authorId: isMine ? 'me' : draft.speakerId,
        authorName: isMine ? '나' : _opponentDebater.name,
        text: draft.content,
        createdAt: draft.createdAt,
      ),
    );
    _scrollToLatestMessage();
  }

  Future<void> _loadDebateDetail() async {
    try {
      final detail = await ref
          .read(debateChatRepositoryProvider)
          .getDebateDetail(widget.debateId);
      if (!mounted) return;
      setState(() {
        _debateDetail = detail;
        _isExpired = detail.status == 'FAILED';
      });
      _checkJudgeRetryAvailability(detail);
      _totalClockTimer?.cancel();
      _totalClockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final expiresAt = _debateDetail?.expiresAt;
        if (expiresAt != null && !DateTime.now().isBefore(expiresAt)) {
          if (!_isExpired) {
            setState(() => _isExpired = true);
            unawaited(_confirmServerExpiration());
          }
          return;
        }
        setState(() {});
      });
      if (detail.status == 'FAILED') {
        _handleDebateEnded(null);
      } else if (detail.status == 'COMPLETED') {
        _openResult();
      } else if (detail.status == 'DEBATE_FINALIZED' ||
          detail.status == 'JUDGING') {
        _startResultPolling();
      }
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('토론 정보를 불러오지 못했습니다.')));
    }
  }

  String get _totalRemainingLabel {
    final expiresAt = _debateDetail?.expiresAt;
    if (expiresAt == null) return '27:00';
    final seconds = expiresAt
        .difference(DateTime.now())
        .inSeconds
        .clamp(0, 1620);
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  double get _totalRemainingProgress {
    final expiresAt = _debateDetail?.expiresAt;
    if (expiresAt == null) return 1;
    final remainingSeconds = expiresAt
        .difference(DateTime.now())
        .inSeconds
        .clamp(0, 1620);
    return remainingSeconds / 1620;
  }

  Future<void> _confirmServerExpiration() async {
    for (var attempt = 0; attempt < 4 && mounted; attempt++) {
      await Future<void>.delayed(const Duration(seconds: 1));
      final detail = await ref
          .read(debateChatRepositoryProvider)
          .getDebateDetail(widget.debateId);
      if (!mounted) return;
      _debateDetail = detail;
      if (detail.status == 'FAILED') {
        _handleDebateEnded('TOTAL_TIME_EXPIRED');
        return;
      }
    }
  }

  void _handleDebateEnded(String? reason) {
    if (_isForfeiting && reason == 'FORFEITED') return;
    if (!mounted || _endDialogShown) return;
    _endDialogShown = true;
    setState(() {
      _isExpired = true;
      _isDebateFinalized = true;
    });
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('토론 종료', style: TextStyle(color: Colors.white)),
        content: Text(switch (reason) {
          'TOTAL_TIME_EXPIRED' => '전체 토론 시간 27분이 지나 토론이 종료되었습니다.',
          'FORFEITED' => '상대방의 기권으로 토론이 종료되었습니다.',
          _ => '토론이 종료되었습니다.',
        }, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _returnToCommunityChat();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _handleRealtimeError(DebateChatRealtimeEvent event) {
    final commandId = event.commandId;
    final clientMessageId = commandId == null
        ? null
        : _messageCommandIds.remove(commandId);
    if (clientMessageId != null) {
      _timeline.markFailed(clientMessageId);
    }
    if (commandId != null && commandId == _pendingFinalizeCommandId) {
      _clearFinalizePending();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(event.errorMessage ?? '토론 요청을 처리하지 못했습니다.')),
    );
  }

  Future<void> _refreshTurnAfterFinalized() async {
    final wasMyFinalize = _pendingFinalizeCommandId != null;
    try {
      final currentTurn = await ref
          .read(debateChatRepositoryProvider)
          .getCurrentTurn(widget.debateId);
      if (!mounted) {
        return;
      }
      _clearFinalizePending();
      _applyCurrentTurn(currentTurn);
      if (wasMyFinalize) {
        _showTurnPassedToast();
      }
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      _clearFinalizePending();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_finalizeErrorMessage(error))));
    }
  }

  void _applyCurrentTurn(DebateChatCurrentTurn? turn) {
    _turnClockTimer?.cancel();
    final previousTurn = _serverCurrentTurn;
    final isNewTurn =
        previousTurn == null ||
        turn == null ||
        previousTurn.phase != turn.phase ||
        previousTurn.round != turn.round ||
        previousTurn.turnSide != turn.turnSide ||
        previousTurn.startedAt != turn.startedAt;
    if (isNewTurn) {
      _currentDraftCharacterCounts.clear();
      _messageController.clear();
    }
    if (mounted) {
      setState(() {
        _hasReceivedSnapshot = true;
        _serverCurrentTurn = turn;
        _isDebateFinalized = turn == null;
      });
      _syncProgressStep();
    }
    if (turn != null) {
      _turnClockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {});
        }
      });
    } else {
      _startResultPolling();
    }
  }

  void _startResultPolling() {
    if (_resultPollTimer != null || _isExpired) return;
    _resultPollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final detail = await ref
            .read(debateChatRepositoryProvider)
            .getDebateDetail(widget.debateId);
        if (!mounted) return;
        setState(() => _debateDetail = detail);
        _syncProgressStep();
        _checkJudgeRetryAvailability(detail);
        if (detail.status == 'COMPLETED') {
          _dismissJudgeRetryDialog();
          _resultPollTimer?.cancel();
          _resultPollTimer = null;
          _openResult();
        } else if (detail.status == 'FAILED') {
          _dismissJudgeRetryDialog();
          _resultPollTimer?.cancel();
          _resultPollTimer = null;
          _handleDebateEnded(null);
        }
      } on Object {
        // 일시적인 네트워크 오류는 다음 poll에서 복구한다.
      }
    });
  }

  void _openResult() {
    if (!mounted) return;
    context.go(
      '/communities/${widget.community.id}/debate/result?debateId=${widget.debateId}',
    );
  }

  void _checkJudgeRetryAvailability(DebateDetail detail) {
    if (!mounted ||
        _isRetryingJudge ||
        _judgeRetryDialogVisible ||
        !detail.canRetryJudgeAt(DateTime.now())) {
      return;
    }
    final dismissedUntil = _judgeRetryPromptDismissedUntil;
    if (dismissedUntil != null && DateTime.now().isBefore(dismissedUntil)) {
      return;
    }
    unawaited(_showJudgeRetryDialog());
  }

  void _dismissJudgeRetryDialog() {
    if (!_judgeRetryDialogVisible || !mounted) return;
    Navigator.of(context, rootNavigator: true).pop(false);
  }

  Future<void> _showJudgeRetryDialog() async {
    if (_judgeRetryDialogVisible || !mounted) return;
    _judgeRetryDialogVisible = true;
    final shouldRetry = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (dialogContext) => AppConfirmationDialog(
        icon: Icons.refresh_rounded,
        title: 'AI 판정이 지연되고 있습니다',
        description: '판정 작업이 5분 이상 완료되지 않았습니다. 지금 다시 시도하시겠습니까?',
        cancelLabel: '나중에',
        confirmLabel: '재시도',
        onCancel: () => Navigator.pop(dialogContext, false),
        onConfirm: () => Navigator.pop(dialogContext, true),
      ),
    );
    _judgeRetryDialogVisible = false;
    if (!mounted) return;
    if (shouldRetry == true) {
      await _retryJudge();
    } else {
      _judgeRetryPromptDismissedUntil = DateTime.now().add(
        const Duration(minutes: 1),
      );
    }
  }

  Future<void> _retryJudge() async {
    if (_isRetryingJudge || !mounted) return;
    setState(() => _isRetryingJudge = true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('AI 판정을 다시 요청하고 있습니다.')));
    try {
      await ref.read(debateChatRepositoryProvider).retryJudge(widget.debateId);
      if (!mounted) return;
      _resultPollTimer?.cancel();
      _resultPollTimer = null;
      _openResult();
    } on Object catch (error) {
      if (!mounted) return;
      _judgeRetryPromptDismissedUntil = DateTime.now().add(
        const Duration(seconds: 10),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_judgeRetryErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _isRetryingJudge = false);
    }
  }

  String _judgeRetryErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) return message;
      }
    }
    return 'AI 판정을 다시 요청하지 못했습니다. 잠시 후 다시 시도해 주세요.';
  }

  void _startFinalizeTimeout(String commandId) {
    _finalizeTimeoutTimer?.cancel();
    _finalizeTimeoutTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted || _pendingFinalizeCommandId != commandId) {
        return;
      }
      _clearFinalizePending();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('턴 확정 응답이 없습니다. 다시 시도해 주세요.')),
      );
    });
  }

  void _clearFinalizePending() {
    _finalizeTimeoutTimer?.cancel();
    _finalizeTimeoutTimer = null;
    if (mounted) {
      setState(() {
        _isFinalizingTurn = false;
        _pendingFinalizeCommandId = null;
      });
    }
  }

  String _finalizeErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
      }
    }
    return '턴을 확정하지 못했습니다. 잠시 후 다시 시도해 주세요.';
  }

  void _scrollToLatestMessage() {
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

  void _showMessageLimitNotice() {
    _limitNoticeTimer?.cancel();
    _turnPassedNoticeTimer?.cancel();
    setState(() {
      _showLimitNotice = true;
      _showTurnPassedNotice = false;
    });
    _limitNoticeTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _showLimitNotice = false;
      });
    });
  }

  void _showTurnPassedToast() {
    _turnPassedNoticeTimer?.cancel();
    _limitNoticeTimer?.cancel();
    setState(() {
      _showLimitNotice = false;
      _showTurnPassedNotice = true;
    });
    _turnPassedNoticeTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showTurnPassedNotice = false);
    });
  }

  Future<void> _showDebateProgress() async {
    final host = _hostDebater;
    final opponent = _opponentDebater;
    final notifier = ValueNotifier<int>(_currentProgressStepIndex);
    _progressStepNotifier?.dispose();
    _progressStepNotifier = notifier;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (dialogContext) {
        return ValueListenableBuilder<int>(
          valueListenable: notifier,
          builder: (context, currentStepIndex, child) {
            return DebateProgressSheet(
              currentStepIndex: currentStepIndex,
              steps: _buildProgressSteps(host, opponent),
              onClose: () => Navigator.pop(dialogContext),
            );
          },
        );
      },
    );
    if (_progressStepNotifier == notifier) {
      _progressStepNotifier = null;
    }
    notifier.dispose();
  }

  List<DebateProgressStep> _buildProgressSteps(
    _DebateParticipant host,
    _DebateParticipant opponent,
  ) {
    final rounds =
        _debateDetail?.rebuttalQuestionRounds ?? widget.community.rounds;
    final rebuttalDurationMinutes = rounds * 3;
    return [
      DebateProgressStep(label: '${host.name} 입론', durationLabel: '1분 30초'),
      DebateProgressStep(label: '${opponent.name} 입론', durationLabel: '1분 30초'),
      DebateProgressStep(
        label: '${host.name} 반론 및 질문',
        durationLabel: '$rebuttalDurationMinutes분',
      ),
      DebateProgressStep(
        label: '${opponent.name} 반론 및 질문',
        durationLabel: '$rebuttalDurationMinutes분',
      ),
      DebateProgressStep(label: '${host.name} 최종 발언', durationLabel: '1분 30초'),
      DebateProgressStep(
        label: '${opponent.name} 최종 발언',
        durationLabel: '1분 30초',
      ),
      const DebateProgressStep(label: '채팅 메시지 프로세싱', durationLabel: '1분'),
      const DebateProgressStep(label: '발언 내용 분석', durationLabel: '1분'),
      const DebateProgressStep(label: '판결', durationLabel: '1분'),
    ];
  }

  int get _currentProgressStepIndex {
    final turn = _serverCurrentTurn;
    const postDebateStartIndex = 6;

    if (turn == null) {
      return switch (_debateDetail?.status) {
        'DEBATE_FINALIZED' => postDebateStartIndex + 1,
        'JUDGING' || 'COMPLETED' => postDebateStartIndex + 2,
        _ => postDebateStartIndex,
      };
    }

    final sideOffset = turn.turnSide == 'SIDE_B' ? 1 : 0;
    return switch (turn.phase) {
      'OPENING' => sideOffset,
      'REBUTTAL_QUESTION' => 2 + sideOffset,
      'CLOSING' => 4 + sideOffset,
      _ => 0,
    };
  }

  void _syncProgressStep() {
    final notifier = _progressStepNotifier;
    if (notifier != null && notifier.value != _currentProgressStepIndex) {
      notifier.value = _currentProgressStepIndex;
    }
  }

  void _showForfeitDialog() {
    if (_forfeitDialogVisible || _isForfeiting || _isDebateFinalized) return;
    _forfeitDialogVisible = true;
    unawaited(
      showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.8),
        builder: (dialogContext) {
          return DebateForfeitDialog(
            onCancel: () => Navigator.pop(dialogContext),
            onForfeit: () {
              Navigator.pop(dialogContext);
              unawaited(_forfeitDebate());
            },
          );
        },
      ).whenComplete(() => _forfeitDialogVisible = false),
    );
  }

  Future<void> _forfeitDebate() async {
    if (_isForfeiting) return;
    setState(() => _isForfeiting = true);
    try {
      await ref
          .read(debateChatRepositoryProvider)
          .forfeitDebate(widget.debateId);
      if (mounted) {
        _returnToCommunityChat();
      }
    } on Object {
      if (!mounted) return;
      setState(() => _isForfeiting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('기권 처리에 실패했습니다.')));
    }
  }

  void _returnToCommunityChat() {
    if (!mounted) return;
    final roleQuery = widget.isHost ? '?role=host' : '';
    context.go('/communities/${widget.community.id}/chat$roleQuery');
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
              score: _debateDetail?.sideBSpeaker.score ?? 0,
              profileImageUrl: _debateDetail?.sideBSpeaker.profileImageUrl,
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
    required this.hostScore,
    required this.opponentScore,
    required this.hostAvatarUrl,
    required this.opponentAvatarUrl,
    required this.remainingLabel,
    required this.remainingProgress,
    required this.onOpponentTap,
    required this.onBack,
  });

  final String title;
  final String hostName;
  final String opponentName;
  final int hostScore;
  final int opponentScore;
  final String? hostAvatarUrl;
  final String? opponentAvatarUrl;
  final String remainingLabel;
  final double remainingProgress;
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
                          score: hostScore,
                          avatarUrl: hostAvatarUrl,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _TotalTimer(
                      label: remainingLabel,
                      progress: remainingProgress,
                    ),
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
                            score: opponentScore,
                            active: false,
                            avatarUrl: opponentAvatarUrl,
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
  const _TotalTimer({required this.label, required this.progress});

  final String label;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ClockwiseDrainRingPainter(
                progress: progress.clamp(0, 1),
              ),
            ),
          ),
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
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
          ),
        ],
      ),
    );
  }
}

class _ClockwiseDrainRingPainter extends CustomPainter {
  const _ClockwiseDrainRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 2.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(strokeWidth / 2);
    final trackPaint = Paint()
      ..color = AppColors.primarySoft.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final progressPaint = Paint()
      ..color = AppColors.primarySoft
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(arcRect, 0, math.pi * 2, false, trackPaint);
    if (progress <= 0) return;

    final elapsedSweep = (1 - progress) * math.pi * 2;
    canvas.drawArc(
      arcRect,
      -math.pi / 2 + elapsedSweep,
      progress * math.pi * 2,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ClockwiseDrainRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _DebateAvatar extends StatelessWidget {
  const _DebateAvatar({required this.name, required this.profileImageUrl});

  final String name;
  final String? profileImageUrl;

  @override
  Widget build(BuildContext context) {
    final imageUrl = profileImageUrl?.trim();
    return ClipOval(
      child: SizedBox(
        width: 36,
        height: 36,
        child: imageUrl == null || imageUrl.isEmpty
            ? _DebateAvatarFallback(name: name)
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _DebateAvatarFallback(name: name),
              ),
      ),
    );
  }
}

class _DebateAvatarFallback extends StatelessWidget {
  const _DebateAvatarFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final normalizedName = name.trim();
    return ColoredBox(
      color: AppColors.surfaceElevated,
      child: Center(
        child: Text(
          normalizedName.isEmpty ? '?' : normalizedName.characters.first,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
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
    required this.isSubmitting,
    required this.characterCount,
    required this.maxCharacterCount,
    required this.onInfoTap,
    required this.onSkip,
  });

  final DebateTurn turn;
  final bool enabled;
  final bool isSubmitting;
  final int characterCount;
  final int maxCharacterCount;
  final VoidCallback onInfoTap;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final progress = turn.remainingSeconds / turn.stage.limitSeconds;
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
            onTap: enabled && !isSubmitting ? onSkip : null,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    )
                  : Text(
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

class _TurnFinalizeDialog extends StatelessWidget {
  const _TurnFinalizeDialog();

  @override
  Widget build(BuildContext context) {
    return AppConfirmationDialog(
      icon: Icons.redo_rounded,
      title: '턴을 넘기시겠습니까?',
      description: '현재 발화가 종료되고 상대방에게 턴이 넘어갑니다.',
      cancelLabel: '아니오',
      confirmLabel: '턴 넘기기',
      onCancel: () => Navigator.pop(context, false),
      onConfirm: () => Navigator.pop(context, true),
    );
  }
}

class _DebateToast extends StatelessWidget {
  const _DebateToast({
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
            curve: Curves.easeOut,
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
