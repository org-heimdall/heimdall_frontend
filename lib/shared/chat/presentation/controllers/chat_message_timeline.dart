import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/chat_message.dart';

/// 커뮤니티 채팅과 토론 채팅이 공유하는 메시지 상태 전이 컨트롤러다.
class ChatMessageTimeline extends ChangeNotifier {
  ChatMessageTimeline({
    Iterable<ChatMessage> initialMessages = const [],
    this.pendingTimeout = const Duration(seconds: 10),
  }) : _messages = [...initialMessages];

  final Duration pendingTimeout;
  final List<ChatMessage> _messages;
  final Map<String, Timer> _pendingTimers = {};

  bool get hasPendingMessages => _messages.any(
    (message) => message.deliveryStatus == ChatMessageDeliveryStatus.pending,
  );

  List<ChatMessage> get orderedMessages {
    return [..._messages]
      ..sort((left, right) => left.createdAt.compareTo(right.createdAt));
  }

  void addPending(ChatMessage message) {
    _messages.add(message);
    final clientMessageId = message.clientMessageId;
    if (clientMessageId != null) {
      _startPendingTimeout(clientMessageId);
    }
    notifyListeners();
  }

  void upsert(ChatMessage incoming) {
    final clientMessageId = incoming.clientMessageId;
    final byClientMessageId = clientMessageId == null
        ? -1
        : _messages.indexWhere(
            (message) => message.clientMessageId == clientMessageId,
          );
    final byServerId = _messages.indexWhere(
      (message) => message.id == incoming.id,
    );
    final index = byClientMessageId != -1 ? byClientMessageId : byServerId;

    if (clientMessageId != null) {
      _cancelPendingTimeout(clientMessageId);
    }

    if (index == -1) {
      _messages.add(incoming);
    } else {
      _messages[index] = incoming;
    }
    notifyListeners();
  }

  void markFailed(String clientMessageId) {
    _cancelPendingTimeout(clientMessageId);
    final index = _messages.indexWhere(
      (message) => message.clientMessageId == clientMessageId,
    );
    if (index == -1) {
      return;
    }

    _messages[index] = _messages[index].copyWith(
      deliveryStatus: ChatMessageDeliveryStatus.failed,
    );
    notifyListeners();
  }

  void removeById(String messageId) {
    final removedMessages = _messages.where(
      (message) => message.id == messageId,
    );
    for (final message in removedMessages) {
      final clientMessageId = message.clientMessageId;
      if (clientMessageId != null) {
        _cancelPendingTimeout(clientMessageId);
      }
    }

    final previousLength = _messages.length;
    _messages.removeWhere((message) => message.id == messageId);
    if (_messages.length != previousLength) {
      notifyListeners();
    }
  }

  void _startPendingTimeout(String clientMessageId) {
    _cancelPendingTimeout(clientMessageId);
    _pendingTimers[clientMessageId] = Timer(pendingTimeout, () {
      _pendingTimers.remove(clientMessageId);
      markFailed(clientMessageId);
    });
  }

  void _cancelPendingTimeout(String clientMessageId) {
    _pendingTimers.remove(clientMessageId)?.cancel();
  }

  @override
  void dispose() {
    for (final timer in _pendingTimers.values) {
      timer.cancel();
    }
    _pendingTimers.clear();
    super.dispose();
  }
}
