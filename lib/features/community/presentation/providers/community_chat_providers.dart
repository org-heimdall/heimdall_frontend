import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_environment.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/data/stores/auth_token_store.dart';
import '../../data/mappers/community_chat_response_mapper.dart';
import '../../data/realtime/community_chat_realtime_client.dart';
import '../../data/remote/community_chat_remote_data_source.dart';
import '../../data/repositories/community_chat_history_repository_impl.dart';
import '../../data/repositories/community_chat_realtime_repository_impl.dart';
import '../../data/repositories/websocket_community_chat_repository.dart';
import '../../domain/entities/community_chat.dart';
import '../../domain/repositories/community_chat_history_repository.dart';
import '../../domain/repositories/community_chat_repository.dart';
import '../../domain/repositories/community_chat_realtime_repository.dart';
import '../../../../shared/chat/domain/chat_message.dart';

final communityChatRepositoryProvider = Provider<CommunityChatRepository>((
  ref,
) {
  // 메시지 전송은 WebSocket command로 나가며, 화면은 pending 상태를 먼저 보여준다.
  final client = ref.watch(communityChatRealtimeClientProvider);
  return WebSocketCommunityChatRepository(client);
});

final communityChatRemoteDataSourceProvider =
    Provider<CommunityChatRemoteDataSource>((ref) {
      return CommunityChatRemoteDataSource(ref.watch(dioProvider));
    });

final communityChatResponseMapperProvider =
    Provider<CommunityChatResponseMapper>(
      (ref) => const CommunityChatResponseMapper(),
    );

final communityChatHistoryRepositoryProvider =
    Provider<CommunityChatHistoryRepository>((ref) {
      return CommunityChatHistoryRepositoryImpl(
        ref.watch(communityChatRemoteDataSourceProvider),
        ref.watch(communityChatResponseMapperProvider),
      );
    });

final communityChatRealtimeClientProvider =
    Provider<CommunityChatRealtimeClient>((ref) {
      final websocketBaseUrl = AppEnvironment.communityWebSocketBaseUrl;
      final tokenStore = ref.watch(authTokenStoreProvider);

      return WebSocketCommunityChatRealtimeClient(
        uriBuilder: (communityId) =>
            Uri.parse('$websocketBaseUrl/communities/$communityId/chat'),
        headersProvider: () async {
          final accessToken = (await tokenStore.read())?.accessToken;
          return {
            if (accessToken != null) 'Authorization': 'Bearer $accessToken',
          };
        },
      );
    });

final communityChatRealtimeRepositoryProvider =
    Provider<CommunityChatRealtimeRepository>((ref) {
      // raw WebSocket JSON을 domain event로 파싱하는 계층이다.
      final client = ref.watch(communityChatRealtimeClientProvider);
      return CommunityChatRealtimeRepositoryImpl(
        client,
        ref.watch(communityChatResponseMapperProvider),
      );
    });

final communityChatEventsProvider = StreamProvider.autoDispose
    .family<CommunityChatEvent, String>((ref, communityId) {
      // 커뮤니티 채팅방별 실시간 이벤트 스트림을 UI가 구독한다.
      final repository = ref.watch(communityChatRealtimeRepositoryProvider);
      return repository.watchEvents(communityId);
    });

final communityChatHistoryProvider = FutureProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, communityId) async {
      return ref
          .watch(communityChatHistoryRepositoryProvider)
          .fetchMessages(communityId);
    });

final communityOpinionHistoryProvider = FutureProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, communityId) async {
      return ref
          .watch(communityChatHistoryRepositoryProvider)
          .fetchOpinions(communityId);
    });

final sendChatMessageProvider =
    AsyncNotifierProvider.family<SendChatMessageNotifier, void, String>(
      (communityId) => SendChatMessageNotifier(communityId),
    );

final saveCommunityOpinionProvider =
    AsyncNotifierProvider.family<SaveCommunityOpinionNotifier, void, String>(
      (communityId) => SaveCommunityOpinionNotifier(communityId),
    );

class SendChatMessageNotifier extends AsyncNotifier<void> {
  SendChatMessageNotifier(this.communityId);

  final String communityId;

  @override
  Future<void> build() async {}

  // 입력창 전송 액션을 WebSocket message.send command로 변환한다.
  Future<void> send({
    required String authorId,
    required String text,
    required String clientMessageId,
  }) async {
    state = const AsyncLoading();

    final repository = ref.read(communityChatRepositoryProvider);
    await repository.sendMessage(
      SendChatMessageRequest(
        communityId: communityId,
        authorId: authorId,
        text: text,
        clientMessageId: clientMessageId,
      ),
    );

    state = const AsyncData(null);
  }
}

class SaveCommunityOpinionNotifier extends AsyncNotifier<void> {
  SaveCommunityOpinionNotifier(this.communityId);

  final String communityId;

  @override
  Future<void> build() async {}

  Future<void> save({
    required String claim,
    required List<String> reasons,
  }) async {
    state = const AsyncLoading();
    await ref
        .read(communityChatRepositoryProvider)
        .saveOpinion(
          SaveCommunityOpinionRequest(
            communityId: communityId,
            claim: claim,
            reasons: reasons,
          ),
        );
    state = const AsyncData(null);
  }
}
