import 'package:flutter_test/flutter_test.dart';
import 'package:heimdall/features/community/data/mappers/community_chat_response_mapper.dart';
import 'package:heimdall/features/community/data/mappers/community_response_mapper.dart';
import 'package:heimdall/features/community/domain/entities/community.dart';
import 'package:heimdall/features/community/domain/entities/community_chat.dart';

void main() {
  test('maps a community response without HTTP concerns', () {
    final community = const CommunityResponseMapper().mapCommunity({
      'id': 'community-1',
      'title': '테스트 커뮤니티',
      'topic': '테스트 주제',
      'category': 'SOCIETY',
      'status': 'ACTIVE',
      'host': {'id': 'host-1', 'displayName': '방장'},
      'rounds': 2,
      'memberCount': 3,
      'isPublic': true,
      'createdAt': '2026-08-23T08:00:00.000Z',
      'hostClaim': '주장',
      'hostReasons': ['근거'],
      'isOwnedByCurrentUser': true,
      'isJoined': true,
    });

    expect(community.category, CommunityCategory.society);
    expect(community.status, CommunityStatus.live);
    expect(community.host.name, '방장');
    expect(community.isOwnedByCurrentUser, isTrue);
    expect(community.debateDurationMinutes, 16);
  });

  test('keeps forfeit notifications out of the shared message model', () {
    final message = const CommunityChatResponseMapper().mapMessage({
      'id': 'forfeit-message',
      'communityId': 'community-1',
      'clientMessageId': 'forfeit-client',
      'authorId': 'system',
      'authorName': '헤임달',
      'text': '윤호님이 기권하여 토론이 종료되었습니다.',
      'messageType': 'DEBATE_FORFEIT',
      'debateId': 'debate-1',
      'createdAt': '2026-08-23T08:00:00.000Z',
    });

    expect(message, isA<CommunityDebateForfeitMessage>());
  });
}
