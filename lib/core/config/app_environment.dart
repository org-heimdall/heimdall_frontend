abstract final class AppEnvironment {
  static const _apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _debateWebSocketBaseUrl = String.fromEnvironment(
    'DEBATE_WEBSOCKET_BASE_URL',
  );
  static const _communityWebSocketBaseUrl = String.fromEnvironment(
    'WEBSOCKET_BASE_URL',
  );

  static String get apiBaseUrl => _requireUrl('API_BASE_URL', _apiBaseUrl);

  static String get debateWebSocketBaseUrl =>
      _requireUrl('DEBATE_WEBSOCKET_BASE_URL', _debateWebSocketBaseUrl);

  static String get communityWebSocketBaseUrl =>
      _requireUrl('WEBSOCKET_BASE_URL', _communityWebSocketBaseUrl);

  static String _requireUrl(String name, String value) {
    if (value.trim().isEmpty) {
      throw StateError(
        '$name is required. Run Flutter with '
        '--dart-define-from-file=.env.',
      );
    }

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError('$name must be an absolute URL: $value');
    }

    return value;
  }
}
