import '../entities/community_chat.dart';

abstract interface class CommunityChatRepository {
  Future<void> sendMessage(SendCommunityChatMessageRequest request);
}
