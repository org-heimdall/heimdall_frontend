import '../../domain/entities/community_chat.dart';
import '../../domain/repositories/community_chat_repository.dart';
import '../realtime/community_chat_realtime_client.dart';

class WebSocketCommunityChatRepository implements CommunityChatRepository {
  const WebSocketCommunityChatRepository(this.client);

  final CommunityChatRealtimeClient client;

  @override
  Future<void> sendMessage(SendChatMessageRequest request) {
    return client.send(
      CommunityChatCommand(
        id: 'command-${request.clientMessageId}',
        communityId: request.communityId,
        type: CommunityChatCommandType.messageSend,
        clientMessageId: request.clientMessageId,
        sentAt: DateTime.now(),
        payload: {'text': request.text},
      ),
    );
  }

  @override
  Future<void> saveOpinion(SaveCommunityOpinionRequest request) {
    final commandId = 'opinion-${DateTime.now().microsecondsSinceEpoch}';
    return client.send(
      CommunityChatCommand(
        id: commandId,
        communityId: request.communityId,
        type: CommunityChatCommandType.opinionSubmit,
        sentAt: DateTime.now(),
        payload: {'claim': request.claim, 'reasons': request.reasons},
      ),
    );
  }
}
