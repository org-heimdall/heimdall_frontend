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
}
