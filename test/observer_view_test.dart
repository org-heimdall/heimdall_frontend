import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heimdall/features/observer/presentation/widgets/observer_view.dart';

void main() {
  Widget app(ObserverView view) {
    return MaterialApp(
      home: Scaffold(body: SizedBox.expand(child: view)),
    );
  }

  testWidgets('관전 발언을 불러오는 동안 로딩 상태를 표시한다', (tester) async {
    await tester.pumpWidget(
      app(const ObserverView(items: [], isLoading: true)),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Username'), findsNothing);
  });

  testWidgets('관전 발언 로딩 실패 시 재시도할 수 있다', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      app(
        ObserverView(
          items: const [],
          errorMessage: '토론 발언을 불러오지 못했습니다.',
          onRetry: () => retried = true,
        ),
      ),
    );

    expect(find.text('토론 발언을 불러오지 못했습니다.'), findsOneWidget);
    await tester.tap(find.text('다시 시도'));
    expect(retried, isTrue);
  });

  testWidgets('새 확정 발언이 추가되면 마지막 내용까지 자동으로 따라간다', (tester) async {
    List<ObserverCommentItem> items(int count) => List.generate(
      count,
      (index) => ObserverCommentItem(
        turnId: 'turn-$index',
        userName: '참여자 $index',
        content: List.filled(4, '새로운 토론 발언 $index').join(' '),
        likes: 0,
        dislikes: 0,
      ),
    );

    await tester.pumpWidget(app(ObserverView(items: items(6))));
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.pixels, 0);

    await tester.pumpWidget(app(ObserverView(items: items(7))));
    await tester.pumpAndSettle();

    expect(scrollable.position.pixels, scrollable.position.maxScrollExtent);
    expect(scrollable.position.pixels, greaterThan(0));
  });
}
