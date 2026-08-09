import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../domain/entities/community_chat.dart';

abstract interface class CommunityChatRealtimeClient {
  Stream<Map<String, Object?>> subscribe(String communityId);

  Future<void> send(CommunityChatCommand command);
}

typedef CommunityChatRealtimeUriBuilder = Uri Function(String communityId);
typedef CommunityChatRealtimeUrlBuilder = String Function(String communityId);

class WebSocketCommunityChatRealtimeClient
    implements CommunityChatRealtimeClient {
  const WebSocketCommunityChatRealtimeClient({
    required this.uriBuilder,
    this.headersProvider,
    this.reconnectDelay = const Duration(seconds: 2),
    this.maxReconnectAttempts = 5,
  });

  final CommunityChatRealtimeUriBuilder uriBuilder;
  final Future<Map<String, dynamic>> Function()? headersProvider;
  final Duration reconnectDelay;
  final int maxReconnectAttempts;
  static final Map<String, WebSocket> _sockets = {};

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
        await socket?.close();
      }
    }
  }

  @override
  Future<void> send(CommunityChatCommand command) async {
    // 프론트 액션을 WebSocket command JSON으로 서버에 보낸다.
    final socket = await _connect(command.communityId);
    socket.add(jsonEncode(command.toJson()));
  }

  Future<WebSocket> _connect(String communityId) async {
    // 구독과 전송이 같은 채팅방 연결을 공유하도록 열린 socket을 재사용한다.
    final cached = _sockets[communityId];
    if (cached != null && cached.readyState == WebSocket.open) {
      return cached;
    }

    final socket = await WebSocket.connect(
      uriBuilder(communityId).toString(),
      headers: await headersProvider?.call(),
    );
    _sockets[communityId] = socket;
    return socket;
  }
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
  Future<void> send(CommunityChatCommand command) {
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
