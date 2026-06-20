import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:heimdall/app/heimdall_app.dart';

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
    expect(find.text('커뮤니티 테마 *', findRichText: true), findsOneWidget);
    expect(find.text('커뮤니티 주제 *', findRichText: true), findsOneWidget);
    expect(find.text('커뮤니티 설명'), findsOneWidget);
    expect(find.text('커뮤니티 생성하기'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('디베이트 라운드 개수 *', findRichText: true), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('호스트 주장 *', findRichText: true), findsOneWidget);
    expect(find.text('호스트 근거'), findsOneWidget);
  });
}
