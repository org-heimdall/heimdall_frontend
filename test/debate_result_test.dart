import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heimdall/features/debate/data/mappers/debate_response_mapper.dart';
import 'package:heimdall/core/theme/app_colors.dart';
import 'package:heimdall/features/community/domain/entities/community.dart';
import 'package:heimdall/features/debate/domain/entities/debate_chat_realtime.dart';
import 'package:heimdall/features/debate/domain/entities/debate_result.dart';
import 'package:heimdall/features/debate/presentation/screens/debate_result_screen.dart';
import 'package:heimdall/features/debate/presentation/providers/debate_chat_providers.dart';
import 'package:heimdall/features/debate/presentation/widgets/debate_result_popup.dart';
import 'package:heimdall/shared/domain/entities/debate_side.dart';

void main() {
  test('parses fact-check statement, status, reason, and sources', () {
    final results = const DebateResponseMapper().mapFactChecks([
      {
        'id': 'result-id',
        'componentId': 'component-id',
        'speakerId': 'speaker-id',
        'speakerSide': 'SIDE_A',
        'statement': '지구의 평균 기온은 지속해서 상승하고 있다.',
        'status': 'SUPPORTED',
        'reason': '장기 관측 자료가 해당 주장을 뒷받침한다.',
        'sources': [
          {
            'title': 'Climate report',
            'publisher': 'Example Institute',
            'url': 'https://example.com/climate-report',
          },
        ],
        'checkedAt': '2026-08-23T05:00:00.000Z',
      },
    ]);

    expect(results, hasLength(1));
    expect(results.single.status, FactCheckStatus.supported);
    expect(results.single.speakerId, 'speaker-id');
    expect(results.single.speakerSide, 'SIDE_A');
    expect(results.single.claim, '지구의 평균 기온은 지속해서 상승하고 있다.');
    expect(results.single.reason, '장기 관측 자료가 해당 주장을 뒷받침한다.');
    expect(results.single.sources.single.publisher, 'Example Institute');
  });

  testWidgets('shows fact-check details and sources in the result screen', (
    tester,
  ) async {
    final result = DebateResult(
      winner: DebateWinner.pro,
      scores: const [
        DebateScore(side: DebateSide.pro, score: 80, summary: '찬성 요약'),
        DebateScore(side: DebateSide.con, score: 70, summary: '반대 요약'),
      ],
      reason: '판정 근거',
      strengths: const [],
      weaknesses: const [],
      factChecks: [
        FactCheckResult(
          id: 'result-id',
          componentId: 'component-id',
          claim: '검증된 주장',
          status: FactCheckStatus.partiallySupported,
          reason: '일부 자료만 주장을 뒷받침합니다.',
          sources: const [
            FactCheckSource(
              title: '검증 보고서',
              publisher: '검증 기관',
              url: 'https://example.com/report',
            ),
          ],
          checkedAt: DateTime.utc(2026, 8, 23),
        ),
      ],
      feedback: '개선 피드백',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DebateResultScreen(community: _community, result: result),
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();

    expect(find.text('일부 근거 있음'), findsOneWidget);
    expect(find.text('검증된 주장'), findsOneWidget);
    expect(find.text('일부 자료만 주장을 뒷받침합니다.'), findsOneWidget);
    expect(find.text('검증 기관 · 검증 보고서'), findsOneWidget);
    expect(find.text('https://example.com/report'), findsOneWidget);
  });

  testWidgets('returns to the community chat after confirming the result', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/communities/community-id/debate/result',
      routes: [
        GoRoute(
          path: '/communities/:id/debate/result',
          builder: (context, state) =>
              DebateResultScreen(community: _community, result: _result),
        ),
        GoRoute(
          path: '/communities/:id/chat',
          builder: (context, state) => const Scaffold(body: Text('커뮤니티 채팅')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(find.text('커뮤니티 채팅'), findsOneWidget);
  });

  testWidgets('shows debate result and fact checks in a popup card', (
    tester,
  ) async {
    var closed = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          debateResultProvider(
            'popup-debate',
          ).overrideWith((ref) async => _popupResult),
          debateDetailProvider(
            'popup-debate',
          ).overrideWith((ref) async => _detail),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DebateResultPopup(
              debateId: 'popup-debate',
              onClose: () => closed = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('토론 결과'), findsOneWidget);
    expect(find.text('검증된 주장'), findsOneWidget);
    expect(find.text('근거 있음'), findsOneWidget);
    expect(find.text('VS'), findsOneWidget);
    expect(find.text('WINNER'), findsOneWidget);
    expect(find.text('찬성 참여자'), findsWidgets);
    expect(find.text('반대 참여자'), findsWidgets);
    expect(find.text('주 4일제를 도입해야 합니다.'), findsOneWidget);
    expect(find.text('주 4일제 도입에 신중해야 합니다.'), findsOneWidget);
    final bottomFade = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('debate-result-bottom-fade')),
    );
    final bottomFadeGradient =
        (bottomFade.decoration as BoxDecoration).gradient! as LinearGradient;
    expect(bottomFadeGradient.colors, const [
      Color(0x0022282D),
      AppColors.surface,
    ]);
    final winnerBadge = tester.getRect(
      find.byKey(const ValueKey('observer-result-winner-badge')),
    );
    final winnerProfile = tester.getRect(
      find.byKey(const ValueKey('observer-result-avatar-side-a')),
    );
    expect(winnerBadge.top, lessThan(winnerProfile.top));
    expect(winnerBadge.bottom, greaterThan(winnerProfile.top));
    expect(
      tester
          .getRect(
            find.descendant(
              of: find.byKey(
                const ValueKey('observer-result-left-participant'),
              ),
              matching: find.text('찬성 참여자'),
            ),
          )
          .bottom,
      lessThan(tester.getRect(find.text('82점')).top),
    );
    expect(
      find.byKey(const ValueKey('fact-check-speaker-fact-id')),
      findsOneWidget,
    );
    final factCheckAvatar = tester.widget<Container>(
      find.byKey(const ValueKey('fact-check-speaker-fact-id')),
    );
    final factCheckAvatarDecoration =
        factCheckAvatar.decoration! as BoxDecoration;
    expect(
      factCheckAvatarDecoration.border!.top.color,
      const Color(0xFFFFD54F),
    );
    expect(
      find.byKey(const ValueKey('fact-check-status-fact-id')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('observer-result-avatar-side-a')))
          .width,
      equals(
        tester
            .getSize(
              find.byKey(const ValueKey('observer-result-avatar-side-b')),
            )
            .width,
      ),
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('observer-result-right-participant')),
        matching: find.byType(ColorFiltered),
      ),
      findsOneWidget,
    );

    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('feedback-card-side-a')),
        matching: find.text('찬성 요약'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('feedback-card-side-b')),
        matching: find.text('반대 요약'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('닫기'));
    expect(closed, isTrue);
  });
}

final _popupResult = DebateResult(
  winner: DebateWinner.pro,
  scores: const [
    DebateScore(side: DebateSide.pro, score: 82, summary: '찬성 요약'),
    DebateScore(side: DebateSide.con, score: 71, summary: '반대 요약'),
  ],
  reason: '판정 근거',
  strengths: const [],
  weaknesses: const [],
  factChecks: [
    FactCheckResult(
      id: 'fact-id',
      componentId: 'component-id',
      speakerId: 'side-a',
      speakerSide: 'SIDE_A',
      claim: '검증된 주장',
      status: FactCheckStatus.supported,
      reason: '자료가 주장을 뒷받침합니다.',
      sources: const [],
      checkedAt: DateTime.utc(2026, 8, 23),
    ),
  ],
  feedback: '개선 피드백',
);

final _result = DebateResult(
  winner: DebateWinner.draw,
  scores: const [
    DebateScore(side: DebateSide.pro, score: 75, summary: '찬성 요약'),
    DebateScore(side: DebateSide.con, score: 75, summary: '반대 요약'),
  ],
  reason: '판정 근거',
  strengths: const [],
  weaknesses: const [],
  factChecks: const [],
  feedback: '개선 피드백',
);

const _detail = DebateDetail(
  id: 'popup-debate',
  communityId: 'community-id',
  status: 'COMPLETED',
  rebuttalQuestionRounds: 3,
  sideASpeaker: DebateSpeaker(
    id: 'side-a',
    displayName: '찬성 참여자',
    score: 120,
    claim: '주 4일제를 도입해야 합니다.',
  ),
  sideBSpeaker: DebateSpeaker(
    id: 'side-b',
    displayName: '반대 참여자',
    score: 95,
    claim: '주 4일제 도입에 신중해야 합니다.',
  ),
  viewerSide: null,
  startedAt: null,
  expiresAt: null,
  judgingStartedAt: null,
);

final _community = Community(
  id: 'community-id',
  title: '테스트 토론',
  topic: '테스트 주제',
  category: CommunityCategory.society,
  status: CommunityStatus.finished,
  host: const CommunityHost(name: '호스트', avatarColor: 0xFF000000),
  rounds: 1,
  observerCount: 0,
  isPublic: true,
  createdAt: DateTime(2026),
);
