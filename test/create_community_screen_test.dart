import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heimdall/features/community/presentation/screens/create_community_screen.dart';

void main() {
  testWidgets('커뮤니티 생성 화면 배경을 누르면 키보드 포커스가 해제된다', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: CreateCommunityScreen())),
    );

    final topicField = find.byType(TextFormField).first;
    await tester.tap(topicField);
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    final dismissRegion = find.ancestor(
      of: find.byType(Form),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is GestureDetector &&
            widget.behavior == HitTestBehavior.opaque,
      ),
    );
    await tester.tapAt(tester.getTopLeft(dismissRegion) + const Offset(8, 8));
    await tester.pump();

    expect(tester.testTextInput.isVisible, isFalse);
  });
}
