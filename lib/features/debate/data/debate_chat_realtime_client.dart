import 'dart:async';
import 'dart:convert';
import 'dart:io';

abstract interface class DebateChatRealtimeClient {
  Stream<Map<String, Object?>> subscribe(String debateId);

  Future<void> send(String debateId, Map<String, Object?> command);
}

class WebSocketDebateChatRealtimeClient implements DebateChatRealtimeClient {
  const WebSocketDebateChatRealtimeClient({
    required this.uriBuilder,
    required this.accessTokenProvider,
    this.reconnectDelay = const Duration(seconds: 2),
    this.maxReconnectAttempts = 5,
  });

  final Uri Function(String debateId) uriBuilder;
  final Future<String?> Function() accessTokenProvider;
  final Duration reconnectDelay;
  final int maxReconnectAttempts;
  static final Map<String, WebSocket> _sockets = {};
  static final Map<String, Future<WebSocket>> _connectingSockets = {};

  @override
  Stream<Map<String, Object?>> subscribe(String debateId) async* {
    var attempts = 0;

    while (true) {
      WebSocket? socket;
      try {
        socket = await _connect(debateId);
        attempts = 0;

        await for (final payload in socket) {
          if (payload is! String) {
            continue;
          }
          final decoded = jsonDecode(payload);
          if (decoded is Map<String, Object?>) {
            yield decoded;
          }
        }
      } on Object {
        attempts += 1;
        if (attempts > maxReconnectAttempts) {
          rethrow;
        }
        await Future<void>.delayed(reconnectDelay * attempts);
      } finally {
        _sockets.remove(debateId);
        await socket?.close();
      }
    }
  }

  @override
  Future<void> send(String debateId, Map<String, Object?> command) async {
    final socket = await _connect(debateId);
    socket.add(jsonEncode(command));
  }

  Future<WebSocket> _connect(String debateId) async {
    final cached = _sockets[debateId];
    if (cached != null && cached.readyState == WebSocket.open) {
      return cached;
    }

    final connecting = _connectingSockets[debateId];
    if (connecting != null) {
      return connecting;
    }

    final accessToken = await accessTokenProvider();
    final connection = WebSocket.connect(
      uriBuilder(debateId).toString(),
      headers: {
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      },
    );
    _connectingSockets[debateId] = connection;
    try {
      final socket = await connection;
      _sockets[debateId] = socket;
      return socket;
    } finally {
      _connectingSockets.remove(debateId);
    }
  }
}
