import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_environment.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/data/auth_token_store.dart';
import '../../data/community_chat_realtime_client.dart';
import '../../data/mock_community_chat_realtime_repository.dart';
import '../../data/websocket_community_chat_repository.dart';
import '../../domain/entities/community_chat.dart';
import '../../domain/repositories/community_chat_repository.dart';
import '../../domain/repositories/community_chat_realtime_repository.dart';

final communityChatRepositoryProvider = Provider<CommunityChatRepository>((
  ref,
) {
  // 메시지 전송은 WebSocket command로 나가며, 화면은 pending 상태를 먼저 보여준다.
  final client = ref.watch(communityChatRealtimeClientProvider);
  return WebSocketCommunityChatRepository(client);
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
      return MockCommunityChatRealtimeRepository(client);
    });

final communityChatEventsProvider = StreamProvider.autoDispose
    .family<CommunityChatEvent, String>((ref, communityId) {
      // 커뮤니티 채팅방별 실시간 이벤트 스트림을 UI가 구독한다.
      final repository = ref.watch(communityChatRealtimeRepositoryProvider);
      return repository.watchEvents(communityId);
    });

final communityChatHistoryProvider = FutureProvider.autoDispose
    .family<List<CommunityChatMessage>, String>((ref, communityId) async {
      final response = await ref
          .watch(dioProvider)
          .get<List<dynamic>>('/communities/$communityId/messages');
      return (response.data ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(_communityMessageFromJson)
          .toList();
    });

final communityOpinionHistoryProvider = FutureProvider.autoDispose
    .family<List<CommunityChatMessage>, String>((ref, communityId) async {
      final response = await ref
          .watch(dioProvider)
          .get<List<dynamic>>('/communities/$communityId/opinions');
      return (response.data ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(_communityOpinionNoticeFromJson)
          .toList();
    });

final sendCommunityChatMessageProvider =
    AsyncNotifierProvider.family<
      SendCommunityChatMessageNotifier,
      void,
      String
    >((communityId) => SendCommunityChatMessageNotifier(communityId));

final saveCommunityOpinionProvider =
    AsyncNotifierProvider.family<SaveCommunityOpinionNotifier, void, String>(
      (communityId) => SaveCommunityOpinionNotifier(communityId),
    );

class SendCommunityChatMessageNotifier extends AsyncNotifier<void> {
  SendCommunityChatMessageNotifier(this.communityId);

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
      SendCommunityChatMessageRequest(
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

CommunityChatMessage _communityMessageFromJson(Map<String, dynamic> json) {
  return CommunityChatMessage(
    id: json['id'] as String,
    communityId: json['communityId'] as String,
    clientMessageId: json['clientMessageId'] as String?,
    authorId: json['authorId'] as String,
    authorName: json['authorName'] as String,
    text: json['text'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

CommunityChatMessage _communityOpinionNoticeFromJson(
  Map<String, dynamic> json,
) {
  return CommunityChatMessage(
    id: json['id'] as String,
    communityId: json['communityId'] as String,
    authorId: json['authorId'] as String,
    authorName: json['authorName'] as String,
    text: '${json['authorName']} 님이 기조 발언을 작성했습니다.',
    relatedUserId: json['authorId'] as String,
    opinionClaim: json['claim'] as String,
    opinionReasons:
        (json['reasons'] as List<dynamic>?)?.whereType<String>().toList() ??
        const [],
    type: CommunityChatMessageType.opinionNotice,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
