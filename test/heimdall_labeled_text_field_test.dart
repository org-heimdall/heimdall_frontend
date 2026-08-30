import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heimdall/shared/presentation/widgets/heimdall_labeled_text_field.dart';

void main() {
  testWidgets('여러 줄 입력도 처음에는 한 줄 높이로 표시한다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HeimdallLabeledTextField(
            label: '토론 주제 *',
            hintText: '토론 주제',
            minLines: 1,
            maxLines: 3,
          ),
        ),
      ),
    );

    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.minLines, 1);
    expect(field.maxLines, 3);
  });
}
