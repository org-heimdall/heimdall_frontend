import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heimdall/features/debate/presentation/widgets/debate_popup_sheet.dart';

void main() {
  testWidgets('disables debate action while the participant is preparing', (
    tester,
  ) async {
    var started = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DebatePopupSheet(
            userName: '참여자',
            score: 10,
            claim: '기조 발언',
            reasons: const ['근거'],
            role: DebatePopupRole.host,
            isDebateReady: false,
            onDebate: () => started = true,
          ),
        ),
      ),
    );

    expect(find.text('아직 토론 준비 중이에요'), findsOneWidget);
    expect(find.text('토론하기'), findsNothing);

    await tester.tap(find.text('아직 토론 준비 중이에요'));
    await tester.pump();
    expect(started, isFalse);
  });
}
