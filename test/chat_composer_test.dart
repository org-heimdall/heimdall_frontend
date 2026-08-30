import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heimdall/core/theme/app_colors.dart';
import 'package:heimdall/shared/chat/presentation/widgets/chat_composer.dart';

void main() {
  testWidgets('multiline composer grows with debate input', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const Spacer(),
              ChatComposer(
                controller: controller,
                hintText: '발언 입력',
                maxLines: 5,
                onSend: () {},
              ),
            ],
          ),
        ),
      ),
    );
    final initialHeight = tester.getSize(find.byType(ChatComposer)).height;
    expect(initialHeight, 58);

    await tester.enterText(find.byType(TextField), '첫 줄\n둘째 줄\n셋째 줄');
    await tester.pump();

    expect(
      tester.getSize(find.byType(ChatComposer)).height,
      greaterThan(initialHeight),
    );
  });

  testWidgets('tapping outside the composer dismisses keyboard focus', (
    tester,
  ) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const Expanded(child: ColoredBox(color: Colors.black)),
              ChatComposer(
                controller: controller,
                focusNode: focusNode,
                hintText: '메시지 입력',
                onSend: () {},
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.tapAt(const Offset(20, 20));
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);
  });

  testWidgets('composer background continues through the bottom safe area', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatComposer(
            controller: controller,
            hintText: '메시지 입력',
            onSend: () {},
          ),
        ),
      ),
    );

    final safeAreaBackground = tester.widget<ColoredBox>(
      find.byWidgetPredicate(
        (widget) =>
            widget is ColoredBox &&
            widget.color == AppColors.background &&
            widget.child is SafeArea,
      ),
    );
    final composerBackground = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(SafeArea),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Container && widget.color == AppColors.background,
            ),
          )
          .first,
    );

    expect(safeAreaBackground.color, AppColors.background);
    expect(composerBackground.color, safeAreaBackground.color);
  });
}
