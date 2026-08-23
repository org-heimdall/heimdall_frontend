import '../../domain/entities/debate_chat_realtime.dart';
import '../../domain/entities/debate_result.dart';
import '../../domain/repositories/debate_chat_repository.dart';
import '../mappers/debate_response_mapper.dart';
import '../remote/debate_remote_data_source.dart';

class DebateChatRepositoryImpl implements DebateChatRepository {
  const DebateChatRepositoryImpl(this._remoteDataSource, this._mapper);

  final DebateRemoteDataSource _remoteDataSource;
  final DebateResponseMapper _mapper;

  @override
  Future<DebateDetail> getDebateDetail(String debateId) async {
    final response = await _remoteDataSource.getDebate(debateId);
    return _mapper.mapDebateDetail(response);
  }

  @override
  Future<DebateDetail?> getActiveCommunityDebate(String communityId) async {
    final response = await _remoteDataSource.getActiveCommunityDebate(
      communityId,
    );
    return response == null ? null : _mapper.mapDebateDetail(response);
  }

  @override
  Future<void> forfeitDebate(String debateId) {
    return _remoteDataSource.forfeitDebate(debateId);
  }

  @override
  Future<void> retryJudge(String debateId) {
    return _remoteDataSource.retryJudge(debateId);
  }

  @override
  Future<DebateResult> getDebateResult(String debateId) async {
    final response = await _remoteDataSource.getDebateResult(debateId);
    return _mapper.mapDebateResult(response);
  }

  @override
  Future<DebateTurnCommandContext> getCurrentTurnContext(
    String debateId,
  ) async {
    final response = await _remoteDataSource.getDebate(debateId);
    return _mapper.mapTurnCommandContext(response);
  }

  @override
  Future<DebateChatCurrentTurn?> getCurrentTurn(String debateId) async {
    final response = await _remoteDataSource.getCurrentTurn(debateId);
    return response == null ? null : _mapper.mapCurrentTurn(response);
  }

  @override
  Future<List<DebateFinalizedTurn>> getFinalizedTurns(String debateId) async {
    final response = await _remoteDataSource.getFinalizedTurns(debateId);
    return _mapper.mapFinalizedTurns(response);
  }

  @override
  Future<DebateTurnVoteSummary> setTurnVote({
    required String debateId,
    required String turnId,
    required DebateTurnVoteType type,
  }) async {
    final response = await _remoteDataSource.setTurnVote(
      debateId: debateId,
      turnId: turnId,
      type: type,
    );
    return _mapper.mapVoteSummary(response);
  }

  @override
  Future<DebateTurnVoteSummary> removeTurnVote({
    required String debateId,
    required String turnId,
  }) async {
    final response = await _remoteDataSource.removeTurnVote(
      debateId: debateId,
      turnId: turnId,
    );
    return _mapper.mapVoteSummary(response);
  }
}
