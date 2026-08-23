import '../../../../shared/chat/domain/chat_message.dart';
import '../../domain/repositories/community_chat_history_repository.dart';
import '../mappers/community_chat_response_mapper.dart';
import '../remote/community_chat_remote_data_source.dart';

class CommunityChatHistoryRepositoryImpl
    implements CommunityChatHistoryRepository {
  const CommunityChatHistoryRepositoryImpl(
    this._remoteDataSource,
    this._mapper,
  );

  final CommunityChatRemoteDataSource _remoteDataSource;
  final CommunityChatResponseMapper _mapper;

  @override
  Future<List<ChatMessage>> fetchMessages(String communityId) async {
    final response = await _remoteDataSource.fetchMessages(communityId);
    return _mapper.mapMessages(response);
  }

  @override
  Future<List<ChatMessage>> fetchOpinions(String communityId) async {
    final response = await _remoteDataSource.fetchOpinions(communityId);
    return _mapper.mapOpinions(response);
  }
}
