import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      // 실행 환경별 WebSocket 서버 주소를 dart-define으로 바꿀 수 있게 한다.
      const websocketBaseUrl = String.fromEnvironment(
        'WEBSOCKET_BASE_URL',
        defaultValue: 'ws://localhost:8080',
      );

      return WebSocketCommunityChatRealtimeClient(
        uriBuilder: (communityId) =>
            Uri.parse('$websocketBaseUrl/communities/$communityId/chat'),
      );
    });

final communityChatRealtimeRepositoryProvider =
    Provider<CommunityChatRealtimeRepository>((ref) {
      // raw WebSocket JSON을 domain event로 파싱하는 계층이다.
      final client = ref.watch(communityChatRealtimeClientProvider);
      return MockCommunityChatRealtimeRepository(client);
    });

final communityChatEventsProvider =
    StreamProvider.family<CommunityChatEvent, String>((ref, communityId) {
      // 커뮤니티 채팅방별 실시간 이벤트 스트림을 UI가 구독한다.
      final repository = ref.watch(communityChatRealtimeRepositoryProvider);
      return repository.watchEvents(communityId);
    });

final sendCommunityChatMessageProvider =
    AsyncNotifierProvider.family<
      SendCommunityChatMessageNotifier,
      void,
      String
    >((communityId) => SendCommunityChatMessageNotifier(communityId));

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
