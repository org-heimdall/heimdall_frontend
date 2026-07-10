import '../entities/community_chat.dart';

abstract interface class CommunityChatRealtimeRepository {
  Stream<CommunityChatEvent> watchEvents(String communityId);
}
