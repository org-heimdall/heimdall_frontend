import '../../../../shared/chat/domain/chat_message.dart';

abstract interface class CommunityChatHistoryRepository {
  Future<List<ChatMessage>> fetchMessages(String communityId);

  Future<List<ChatMessage>> fetchOpinions(String communityId);
}
