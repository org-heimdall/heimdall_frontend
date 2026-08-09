import '../entities/debate_chat_realtime.dart';
import '../entities/debate_result.dart';

abstract interface class DebateChatRepository {
  Future<DebateDetail> getDebateDetail(String debateId);

  Future<DebateDetail?> getActiveCommunityDebate(String communityId);

  Future<DebateResult> getDebateResult(String debateId);

  Future<DebateTurnCommandContext> getCurrentTurnContext(String debateId);

  Future<DebateChatCurrentTurn?> getCurrentTurn(String debateId);

  Future<List<DebateFinalizedTurn>> getFinalizedTurns(String debateId);

  Future<DebateTurnVoteSummary> setTurnVote({
    required String debateId,
    required String turnId,
    required DebateTurnVoteType type,
  });

  Future<DebateTurnVoteSummary> removeTurnVote({
    required String debateId,
    required String turnId,
  });
}
