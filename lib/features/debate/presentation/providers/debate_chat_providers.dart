import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_environment.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/data/auth_token_store.dart';
import '../../data/debate_chat_event_mapper.dart';
import '../../data/debate_chat_realtime_client.dart';
import '../../data/http_debate_chat_repository.dart';
import '../../domain/entities/debate_chat_realtime.dart';
import '../../domain/entities/debate_result.dart';
import '../../domain/repositories/debate_chat_repository.dart';

final debateChatRepositoryProvider = Provider<DebateChatRepository>((ref) {
  return HttpDebateChatRepository(ref.watch(dioProvider));
});

final finalizedDebateTurnsProvider =
    FutureProvider.family<List<DebateFinalizedTurn>, String>((ref, debateId) {
      return ref
          .watch(debateChatRepositoryProvider)
          .getFinalizedTurns(debateId);
    });

final debateDetailProvider = FutureProvider.family<DebateDetail, String>((
  ref,
  debateId,
) {
  return ref.watch(debateChatRepositoryProvider).getDebateDetail(debateId);
});

final debateResultProvider = FutureProvider.family<DebateResult, String>((
  ref,
  debateId,
) {
  return ref.watch(debateChatRepositoryProvider).getDebateResult(debateId);
});

final debateChatRealtimeClientProvider = Provider<DebateChatRealtimeClient>((
  ref,
) {
  final websocketBaseUrl = AppEnvironment.debateWebSocketBaseUrl;
  final tokenStore = ref.watch(authTokenStoreProvider);
  return WebSocketDebateChatRealtimeClient(
    uriBuilder: (debateId) =>
        Uri.parse('$websocketBaseUrl/debates/$debateId/chat'),
    accessTokenProvider: () async => (await tokenStore.read())?.accessToken,
  );
});

final debateChatEventsProvider =
    StreamProvider.family<DebateChatRealtimeEvent, String>((ref, debateId) {
      const mapper = DebateChatEventMapper();
      return ref
          .watch(debateChatRealtimeClientProvider)
          .subscribe(debateId)
          .map(mapper.fromJson);
    });

final debateChatCommandServiceProvider = Provider<DebateChatCommandService>((
  ref,
) {
  return DebateChatCommandService(
    repository: ref.watch(debateChatRepositoryProvider),
    realtimeClient: ref.watch(debateChatRealtimeClientProvider),
  );
});

class DebateChatCommandService {
  const DebateChatCommandService({
    required DebateChatRepository repository,
    required DebateChatRealtimeClient realtimeClient,
  }) : _repository = repository,
       _realtimeClient = realtimeClient;

  final DebateChatRepository _repository;
  final DebateChatRealtimeClient _realtimeClient;

  Future<void> sendMessage({
    required String debateId,
    required String commandId,
    required String clientMessageId,
    required String text,
  }) async {
    final context = await _repository.getCurrentTurnContext(debateId);
    await _realtimeClient.send(debateId, {
      'id': commandId,
      'type': 'debate.turn.message.send',
      'debateId': debateId,
      'clientMessageId': clientMessageId,
      'sentAt': DateTime.now().toUtc().toIso8601String(),
      'payload': _payload(context, content: text),
    });
  }

  Future<void> finalizeTurn({
    required String debateId,
    required String commandId,
  }) async {
    final context = await _repository.getCurrentTurnContext(debateId);
    await _realtimeClient.send(debateId, {
      'id': commandId,
      'type': 'debate.turn.finalize',
      'debateId': debateId,
      'payload': _payload(context),
    });
  }

  Map<String, Object?> _payload(
    DebateTurnCommandContext context, {
    String? content,
  }) {
    return {
      'speakerId': context.speakerId,
      'speakerSide': context.speakerSide,
      'phase': context.phase,
      'round': context.round,
      'content': ?content,
    };
  }
}
