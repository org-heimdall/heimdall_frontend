import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../domain/entities/community_chat.dart';

abstract interface class CommunityChatRealtimeClient {
  Stream<Map<String, Object?>> subscribe(String communityId);

  Future<Map<String, Object?>> send(CommunityChatCommand command);
}

typedef CommunityChatRealtimeUriBuilder = Uri Function(String communityId);
typedef CommunityChatRealtimeUrlBuilder = String Function(String communityId);

class WebSocketCommunityChatRealtimeClient
    implements CommunityChatRealtimeClient {
  WebSocketCommunityChatRealtimeClient({
    required this.uriBuilder,
    this.headersProvider,
    this.reconnectDelay = const Duration(seconds: 2),
    this.maxReconnectAttempts = 5,
    this.commandTimeout = const Duration(seconds: 10),
  });

  final CommunityChatRealtimeUriBuilder uriBuilder;
  final Future<Map<String, dynamic>> Function()? headersProvider;
  final Duration reconnectDelay;
  final int maxReconnectAttempts;
  final Duration commandTimeout;
  final Map<String, WebSocket> _sockets = {};
  final Map<String, Future<WebSocket>> _connectingSockets = {};
  final Map<String, _PendingCommunityCommand> _pendingCommands = {};

  @override
  Stream<Map<String, Object?>> subscribe(String communityId) async* {
    // 채팅방 WebSocket을 구독하고 서버 push를 raw JSON event로 흘려보낸다.
    var attempts = 0;

    while (true) {
      WebSocket? socket;
      try {
        socket = await _connect(communityId);
        attempts = 0;

        await for (final payload in socket) {
          // 서버 이벤트는 JSON string만 처리하고 binary frame은 무시한다.
          if (payload is! String) {
            continue;
          }

          final decoded = jsonDecode(payload);
          if (decoded is Map<String, Object?>) {
            _resolvePendingCommand(decoded);
            yield decoded;
          }
        }
      } on Object {
        // 일시적 네트워크 오류는 선형 backoff로 제한된 횟수만 재연결한다.
        attempts += 1;
        if (attempts > maxReconnectAttempts) {
          rethrow;
        }
        await Future<void>.delayed(reconnectDelay * attempts);
      } finally {
        _sockets.remove(communityId);
        _failPendingCommands(
          communityId,
          const CommunityChatConnectionException('채팅 연결이 종료되었습니다.'),
        );
        await socket?.close();
      }
    }
  }

  @override
  Future<Map<String, Object?>> send(CommunityChatCommand command) async {
    if (_pendingCommands.containsKey(command.id)) {
      throw StateError('이미 처리 중인 command입니다: ${command.id}');
    }

    final completer = Completer<Map<String, Object?>>();
    final pending = _PendingCommunityCommand(
      communityId: command.communityId,
      completer: completer,
    );
    _pendingCommands[command.id] = pending;

    try {
      final socket = await _connect(command.communityId);
      socket.add(jsonEncode(command.toJson()));
      return await completer.future.timeout(
        commandTimeout,
        onTimeout: () => throw TimeoutException(
          '커뮤니티 채팅 서버 응답 시간이 초과되었습니다.',
          commandTimeout,
        ),
      );
    } finally {
      if (identical(_pendingCommands[command.id], pending)) {
        _pendingCommands.remove(command.id);
      }
    }
  }

  Future<WebSocket> _connect(String communityId) async {
    // 구독과 전송이 같은 채팅방 연결을 공유하도록 열린 socket을 재사용한다.
    final cached = _sockets[communityId];
    if (cached != null && cached.readyState == WebSocket.open) {
      return cached;
    }

    final connecting = _connectingSockets[communityId];
    if (connecting != null) return connecting;

    final connection = WebSocket.connect(
      uriBuilder(communityId).toString(),
      headers: await headersProvider?.call(),
    );
    _connectingSockets[communityId] = connection;
    try {
      final socket = await connection;
      _sockets[communityId] = socket;
      return socket;
    } finally {
      _connectingSockets.remove(communityId);
    }
  }

  void _resolvePendingCommand(Map<String, Object?> event) {
    final commandId = event['commandId'];
    if (commandId is! String) return;
    final pending = _pendingCommands[commandId];
    if (pending == null || pending.completer.isCompleted) return;

    if (event['type'] == 'error') {
      final message = event['message'];
      pending.completer.completeError(
        CommunityChatCommandException(
          message is String && message.isNotEmpty
              ? message
              : '커뮤니티 채팅 요청을 처리하지 못했습니다.',
        ),
      );
      return;
    }

    if (event['type'] == 'community.message.ack' ||
        event['type'] == 'community.opinion.ack') {
      pending.completer.complete(event);
    }
  }

  void _failPendingCommands(String communityId, Object error) {
    for (final pending in _pendingCommands.values) {
      if (pending.communityId == communityId &&
          !pending.completer.isCompleted) {
        pending.completer.completeError(error);
      }
    }
  }
}

class _PendingCommunityCommand {
  const _PendingCommunityCommand({
    required this.communityId,
    required this.completer,
  });

  final String communityId;
  final Completer<Map<String, Object?>> completer;
}

class CommunityChatCommandException implements Exception {
  const CommunityChatCommandException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CommunityChatConnectionException implements Exception {
  const CommunityChatConnectionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SseCommunityChatRealtimeClient implements CommunityChatRealtimeClient {
  const SseCommunityChatRealtimeClient({
    required this.dio,
    required this.urlBuilder,
  });

  final Dio dio;
  final CommunityChatRealtimeUrlBuilder urlBuilder;

  @override
  Stream<Map<String, Object?>> subscribe(String communityId) async* {
    // SSE는 서버 -> 클라이언트 단방향 스트림을 line 단위로 파싱한다.
    final response = await dio.get<ResponseBody>(
      urlBuilder(communityId),
      options: Options(responseType: ResponseType.stream),
    );
    final body = response.data;
    if (body == null) {
      return;
    }

    final lines = body.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    final dataBuffer = StringBuffer();
    await for (final line in lines) {
      if (line.isEmpty) {
        final event = _decodeSseData(dataBuffer.toString());
        dataBuffer.clear();
        if (event != null) {
          yield event;
        }
        continue;
      }

      if (line.startsWith('data:')) {
        // SSE data 라인은 여러 줄일 수 있어 빈 줄 전까지 누적한다.
        dataBuffer.writeln(line.substring(5).trimLeft());
      }
    }
  }

  @override
  Future<Map<String, Object?>> send(CommunityChatCommand command) {
    // SSE는 송신 채널이 아니므로 WebSocket 전송으로 교체해야 한다.
    throw UnsupportedError('SSE client cannot send commands.');
  }

  Map<String, Object?>? _decodeSseData(String data) {
    // 빈 keep-alive 이벤트는 무시하고 JSON 객체만 domain parser로 넘긴다.
    final trimmed = data.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(trimmed);
    return decoded is Map<String, Object?> ? decoded : null;
  }
}
