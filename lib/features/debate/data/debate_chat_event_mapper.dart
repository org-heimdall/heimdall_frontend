import '../domain/entities/debate_chat_realtime.dart';

class DebateChatEventMapper {
  const DebateChatEventMapper();

  DebateChatRealtimeEvent fromJson(Map<String, Object?> json) {
    final type = _eventType(_string(json, 'type'));
    final currentTurnJson = json['currentTurn'];
    final messageJson = json['message'];
    final draftMessagesJson = json['draftMessages'];

    return DebateChatRealtimeEvent(
      id: _string(json, 'id'),
      debateId: _string(json, 'debateId'),
      type: type,
      commandId: _optionalString(json, 'commandId'),
      clientMessageId: _optionalString(json, 'clientMessageId'),
      currentTurn: currentTurnJson is Map<String, Object?>
          ? _currentTurn(currentTurnJson)
          : null,
      message: messageJson is Map<String, Object?>
          ? _message(messageJson)
          : null,
      draftMessages: draftMessagesJson is List
          ? draftMessagesJson
                .whereType<Map<String, Object?>>()
                .map(_message)
                .toList()
          : const [],
      errorMessage: _optionalString(json, 'message'),
      endReason: _optionalString(json, 'reason'),
      status: _optionalString(json, 'status'),
    );
  }

  DebateChatRealtimeEventType _eventType(String value) => switch (value) {
    'connection.restored' => DebateChatRealtimeEventType.connectionRestored,
    'debate.turn.message.ack' =>
      DebateChatRealtimeEventType.messageAcknowledged,
    'debate.turn.message.created' => DebateChatRealtimeEventType.messageCreated,
    'debate.turn.finalized' => DebateChatRealtimeEventType.turnFinalized,
    'debate.ended' => DebateChatRealtimeEventType.debateEnded,
    'error' => DebateChatRealtimeEventType.error,
    _ => throw FormatException('지원하지 않는 토론 이벤트입니다: $value'),
  };

  DebateChatCurrentTurn _currentTurn(Map<String, Object?> json) {
    return DebateChatCurrentTurn(
      phase: _string(json, 'phase'),
      round: _int(json, 'round'),
      turnSide: _string(json, 'turnSide'),
      startedAt: DateTime.parse(_string(json, 'startedAt')),
      maxDurationSeconds: _int(json, 'maxDurationSeconds'),
      maxTotalCharacters: _int(json, 'maxTotalCharacters'),
    );
  }

  DebateChatDraftMessage _message(Map<String, Object?> json) {
    return DebateChatDraftMessage(
      id: _string(json, 'id'),
      clientMessageId: _optionalString(json, 'clientMessageId'),
      speakerId: _string(json, 'speakerId'),
      speakerSide: _string(json, 'speakerSide'),
      content: _string(json, 'content'),
      createdAt: DateTime.parse(_string(json, 'createdAt')),
    );
  }

  String _string(Map<String, Object?> json, String field) {
    final value = json[field];
    if (value is! String || value.isEmpty) {
      throw FormatException('$field 값이 없거나 올바르지 않습니다.');
    }
    return value;
  }

  String? _optionalString(Map<String, Object?> json, String field) {
    final value = json[field];
    return value is String && value.isNotEmpty ? value : null;
  }

  int _int(Map<String, Object?> json, String field) {
    final value = json[field];
    if (value is! num || value.toInt() != value) {
      throw FormatException('$field 값이 없거나 올바르지 않습니다.');
    }
    return value.toInt();
  }
}
