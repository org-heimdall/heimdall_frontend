import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heimdall/app/heimdall_app.dart';

void main() {
  testWidgets('shows debate list entry screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HeimdallApp()));
    await tester.pumpAndSettle();

    expect(find.byTooltip('검색'), findsOneWidget);
    expect(find.text('전체'), findsOneWidget);
    expect(find.text('총 5건'), findsOneWidget);
    expect(find.text('국밥 티어 순대국 VS 뼈해장국'), findsOneWidget);
  });
}
