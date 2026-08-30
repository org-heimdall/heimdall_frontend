import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:heimdall/app/app_router.dart';
import 'package:heimdall/app/heimdall_app.dart';
import 'package:heimdall/features/auth/data/stores/member_session_store.dart';
import 'package:heimdall/features/auth/data/stores/auth_token_store.dart';
import 'package:heimdall/features/auth/domain/auth_member.dart';
import 'package:heimdall/features/community/domain/entities/community.dart';
import 'package:heimdall/features/community/domain/repositories/community_repository.dart';
import 'package:heimdall/features/community/presentation/providers/community_providers.dart';
import 'package:heimdall/features/community/presentation/screens/community_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows login as unauthenticated entry screen', (tester) async {
    await _pumpHeimdall(tester);

    expect(find.text('HEIMDALL'), findsOneWidget);
    expect(find.text('로그인'), findsOneWidget);
    expect(find.text('처음이신가요? 회원가입'), findsOneWidget);
  });

  testWidgets('shows community list for restored member session', (
    tester,
  ) async {
    await _pumpHeimdall(tester, authenticated: true);
    await tester.pumpAndSettle();

    expect(find.byTooltip('검색'), findsOneWidget);
    expect(find.text('전체'), findsOneWidget);
    expect(find.text('총 5건'), findsOneWidget);
    expect(find.text('국밥 티어 순대국 VS 뼈해장국'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SvgPicture &&
            widget.bytesLoader.toString().contains('icon_timer.svg'),
      ),
      findsWidgets,
    );
  });

  testWidgets('switches community sorting between recommended and latest', (
    tester,
  ) async {
    await _pumpHeimdall(tester, authenticated: true);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HeimdallApp)),
      listen: false,
    );

    expect(
      container.read(communitiesProvider).requireValue.first.id,
      'test-room-1',
    );

    await tester.tap(find.text('추천순'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('최신순'));
    await tester.pumpAndSettle();

    expect(
      container.read(communityFilterProvider).sortOrder,
      CommunitySortOrder.latest,
    );
    expect(
      container.read(communitiesProvider).requireValue.first.id,
      'test-room-5',
    );
    expect(find.text('최신순'), findsOneWidget);
  });

  testWidgets('shows community creation form fields', (tester) async {
    await _pumpHeimdall(tester, authenticated: true);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('커뮤니티 생성'));
    await tester.pumpAndSettle();

    expect(find.text('토론 커뮤니티 생성'), findsOneWidget);
    expect(find.text('토론 테마 *', findRichText: true), findsOneWidget);
    expect(find.text('토론 주제 *', findRichText: true), findsOneWidget);
    expect(find.text('토론 설명'), findsOneWidget);
    expect(find.text('커뮤니티 생성하기'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('토론 라운드 개수 *', findRichText: true), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('나의 주장 *', findRichText: true), findsOneWidget);
    expect(find.text('근거'), findsOneWidget);
  });

  testWidgets('loads a community by id when opening a direct route', (
    tester,
  ) async {
    await _pumpHeimdall(tester, authenticated: true);
    await tester.pumpAndSettle();

    final context = tester.element(find.text('국밥 티어 순대국 VS 뼈해장국'));
    GoRouter.of(context).go('/communities/test-room-1');
    await tester.pumpAndSettle();

    expect(find.text('커뮤니티 상세'), findsOneWidget);
    expect(find.text('국밥 티어 순대국 VS 뼈해장국'), findsOneWidget);
  });

  testWidgets('community detail screen fits narrow mobile width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final community = Community(
      id: 'room-overflow-test',
      title: '매트릭스 빨간약을 먹을 것인가 파란약을 먹을 것인가',
      topic: '불편한 진실과 안정적인 환상 중 무엇을 택해야 하는가?',
      category: CommunityCategory.culture,
      status: CommunityStatus.live,
      host: const CommunityHost(name: '아주긴호스트이름', avatarColor: 0xFFC6F9FF),
      rounds: 3,
      observerCount: 8,
      isPublic: true,
      createdAt: DateTime(2026, 6, 17, 18, 40),
      hostClaim: '불편한 진실을 받아들이는 쪽이 장기적으로는 더 자율적인 선택을 가능하게 한다.',
      hostReasons: const [
        '진실을 알아야 이후의 선택을 스스로 책임질 수 있고, 환상 속 안정은 결국 타인이 설계한 선택지에 머무르게 만든다.',
        '현실을 이해하면 불편하더라도 문제를 바꿀 가능성이 생긴다.',
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: CommunityDetailScreen(community: community)),
    );

    expect(find.text('커뮤니티 상세'), findsOneWidget);
    expect(find.text('호스트 근거'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('restores an invited community route after authentication', (
    tester,
  ) async {
    await _pumpHeimdall(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HeimdallApp)),
      listen: false,
    );
    final router = container.read(appRouterProvider);
    const invitedRoute = '/communities/test-room-1?invite=share-1';

    router.go(invitedRoute);
    await tester.pumpAndSettle();

    var location = router.routerDelegate.currentConfiguration.uri;
    expect(location.path, '/login');
    expect(location.queryParameters['redirect'], invitedRoute);

    await tester.tap(find.text('처음이신가요? 회원가입'));
    await tester.pumpAndSettle();
    location = router.routerDelegate.currentConfiguration.uri;
    expect(location.path, '/signup');
    expect(location.queryParameters['redirect'], invitedRoute);

    await container
        .read(memberSessionStoreProvider)
        .save(
          const AuthMember(
            id: 'member-1',
            email: 'member@example.com',
            displayName: '초대회원',
            profileImageUrl: null,
            score: 0,
          ),
        );
    await container
        .read(authTokenStoreProvider)
        .save(const AuthTokens(accessToken: 'access', refreshToken: 'refresh'));
    container.read(authSessionEpochProvider.notifier).invalidate();
    await tester.pumpAndSettle();

    expect(container.read(appRouterProvider), same(router));
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      invitedRoute,
    );
    expect(find.text('커뮤니티 상세'), findsOneWidget);
  });

  testWidgets('rejects an external post-login redirect', (tester) async {
    await _pumpHeimdall(tester, authenticated: true);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HeimdallApp)),
      listen: false,
    );
    final router = container.read(appRouterProvider);

    router.go('/login?redirect=https%3A%2F%2Fevil.example%2Fsteal');
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path, '/');
    expect(find.byTooltip('검색'), findsOneWidget);
  });
}

Future<void> _pumpHeimdall(
  WidgetTester tester, {
  bool authenticated = false,
}) async {
  SharedPreferences.setMockInitialValues(
    authenticated
        ? {
            'auth.member.id': '00000000-0000-4000-8000-000000000001',
            'auth.member.email': 'member@example.com',
            'auth.member.displayName': '테스트회원',
          }
        : {},
  );
  final preferences = await SharedPreferences.getInstance();
  final tokenStore = MemoryAuthTokenStore(
    authenticated
        ? const AuthTokens(accessToken: 'access', refreshToken: 'refresh')
        : null,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        authTokenStoreProvider.overrideWithValue(tokenStore),
        communityRepositoryProvider.overrideWithValue(
          TestCommunityRepository(),
        ),
      ],
      child: const HeimdallApp(),
    ),
  );
  await tester.pumpAndSettle();
}

class TestCommunityRepository implements CommunityRepository {
  TestCommunityRepository()
    : _communities = List.generate(
        5,
        (index) => Community(
          id: 'test-room-${index + 1}',
          title: index == 0 ? '국밥 티어 순대국 VS 뼈해장국' : '테스트 커뮤니티 ${index + 1}',
          topic: '테스트 토론 주제',
          category: CommunityCategory.daily,
          status: CommunityStatus.waiting,
          host: const CommunityHost(name: '테스트 호스트', avatarColor: 0xFFC6F9FF),
          rounds: 1,
          observerCount: 5 - index,
          isPublic: true,
          createdAt: DateTime(2026, 8, 23 + index),
        ),
      );

  final List<Community> _communities;

  @override
  Future<List<Community>> fetchCommunities({
    CommunityCategory category = CommunityCategory.all,
    String query = '',
    CommunitySortOrder sortOrder = CommunitySortOrder.recommended,
  }) async {
    final filtered = _communities.where((community) {
      final matchesCategory =
          category == CommunityCategory.all || community.category == category;
      final normalizedQuery = query.trim().toLowerCase();
      return matchesCategory &&
          (normalizedQuery.isEmpty ||
              community.title.toLowerCase().contains(normalizedQuery));
    }).toList();
    filtered.sort(
      sortOrder == CommunitySortOrder.latest
          ? (left, right) => right.createdAt.compareTo(left.createdAt)
          : (left, right) {
              final memberCountOrder = right.observerCount.compareTo(
                left.observerCount,
              );
              return memberCountOrder != 0
                  ? memberCountOrder
                  : right.createdAt.compareTo(left.createdAt);
            },
    );
    return filtered;
  }

  @override
  Future<Community> fetchCommunityById(String id) async {
    for (final community in _communities) {
      if (community.id == id) return community;
    }
    throw StateError('Community not found: $id');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
