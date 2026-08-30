import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heimdall/features/debate/presentation/widgets/debate_processing_dialog.dart';

void main() {
  Widget app({required String status, required bool canRetry}) {
    return MaterialApp(
      home: Scaffold(
        body: DebateProcessingDialog(
          status: status,
          canRetry: canRetry,
          retrying: false,
          onRetry: () {},
        ),
      ),
    );
  }

  testWidgets('분석과 팩트체크 중에는 정리 중 로딩만 표시한다', (tester) async {
    await tester.pumpWidget(app(status: 'DEBATE_FINALIZED', canRetry: false));

    expect(find.text('토론 내용 정리 중'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('재시도'), findsNothing);
  });

  testWidgets('판정 지연 시 같은 팝업에 재시도 버튼을 표시한다', (tester) async {
    await tester.pumpWidget(app(status: 'JUDGING', canRetry: true));

    expect(find.text('AI 판정 중'), findsOneWidget);
    expect(
      find.text('양측의 토론 내용을 바탕으로\n최종 판정 결과를 생성하고 있어요.\n잠시만 기다려 주세요.'),
      findsOneWidget,
    );
    expect(find.text('재시도'), findsOneWidget);
  });
}
