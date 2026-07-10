import '../domain/entities/community_chat.dart';
import '../domain/repositories/community_chat_repository.dart';

class MockCommunityChatRepository implements CommunityChatRepository {
  @override
  Future<void> sendMessage(SendCommunityChatMessageRequest request) async {}
}
