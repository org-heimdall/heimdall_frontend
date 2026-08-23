import '../entities/community_chat.dart';

abstract interface class CommunityChatRepository {
  Future<void> sendMessage(SendChatMessageRequest request);

  Future<void> saveOpinion(SaveCommunityOpinionRequest request);
}
