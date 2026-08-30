import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heimdall/features/community/presentation/widgets/community_opinion.dart';

void main() {
  testWidgets('기존 기조 발언을 초기값으로 보여주고 수정해 저장한다', (tester) async {
    CommunityOpinionDraft? submittedDraft;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CommunityOpinionSheet(
            initialDraft: const CommunityOpinionDraft(
              claim: '기존 주장',
              reasons: ['기존 근거 1', '기존 근거 2'],
            ),
            onSubmit: (draft) => submittedDraft = draft,
          ),
        ),
      ),
    );

    expect(find.text('기조 발언 수정하기'), findsOneWidget);
    expect(find.text('기존 주장'), findsOneWidget);
    expect(find.text('기존 근거 1'), findsOneWidget);
    expect(find.text('기존 근거 2'), findsOneWidget);
    expect(find.text('수정 완료'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '수정된 주장');
    await tester.enterText(fields.at(1), '수정된 근거 1');
    await tester.enterText(fields.at(2), '수정된 근거 2');
    await tester.tap(find.text('수정 완료'));
    await tester.pump();

    expect(submittedDraft?.claim, '수정된 주장');
    expect(submittedDraft?.reasons, ['수정된 근거 1', '수정된 근거 2']);
  });

  testWidgets('나의 주장은 줄바꿈되고 배경을 누르면 키보드 포커스가 해제된다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CommunityOpinionSheet())),
    );

    final claimField = find.byType(TextField).first;
    await tester.tap(claimField);
    await tester.enterText(claimField, '첫 번째 줄\n두 번째 줄');
    await tester.pump();

    final textField = tester.widget<TextField>(claimField);
    expect(textField.maxLines, 3);
    expect(textField.controller?.text, contains('\n'));
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.text('기조 발언 작성하기'));
    await tester.pump();

    expect(tester.testTextInput.isVisible, isFalse);
  });
}
