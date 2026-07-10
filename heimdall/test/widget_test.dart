import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:heimdall/app/heimdall_app.dart';
import 'package:heimdall/features/debate/domain/entities/community.dart';
import 'package:heimdall/features/debate/presentation/screens/community_detail_screen.dart';

void main() {
  testWidgets('shows community list entry screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HeimdallApp()));
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

  testWidgets('shows community creation form fields', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HeimdallApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('커뮤니티 생성'));
    await tester.pumpAndSettle();

    expect(find.text('커뮤니티 생성'), findsOneWidget);
    expect(find.text('토론 테마 *', findRichText: true), findsOneWidget);
    expect(find.text('토론 주제 *', findRichText: true), findsOneWidget);
    expect(find.text('토론 설명'), findsOneWidget);
    expect(find.text('커뮤니티 생성하기'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('토론 라운드 개수 *', findRichText: true), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('호스트 주장 *', findRichText: true), findsOneWidget);
    expect(find.text('호스트 근거'), findsOneWidget);
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
      activeDebaters: const [
        Debater(name: '아주긴호스트이름', side: DebateSide.pro, avatarColor: 0xFFC6F9FF),
        Debater(name: '상대토론자', side: DebateSide.con, avatarColor: 0xFFFF5D5D),
      ],
      rounds: 3,
      elapsedMinutes: 18,
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
}
