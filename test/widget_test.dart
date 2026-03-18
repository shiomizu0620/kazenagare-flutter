// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:kazenagare_flutter/main.dart';

void main() {
  testWidgets('タップでログインパネルが表示される', (WidgetTester tester) async {
    await tester.pumpWidget(const KazenagareApp());

    expect(find.text('風流'), findsOneWidget);
    expect(find.text('画面をタップ'), findsOneWidget);

    final gateLogin = find.text('GATE LOGIN');
    expect(gateLogin, findsOneWidget);

    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final initialTop = tester.getTopLeft(gateLogin).dy;
    expect(initialTop, greaterThan(screenHeight));

    await tester.tap(find.text('画面をタップ'));
    await tester.pumpAndSettle();

    final afterTapTop = tester.getTopLeft(gateLogin).dy;
    expect(afterTapTop, lessThan(screenHeight));
  });

  testWidgets('ゲスト体験押下でセットアップ画面へ遷移する', (WidgetTester tester) async {
    await tester.pumpWidget(const KazenagareApp());

    await tester.tap(find.text('画面をタップ'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ゲスト体験'));
    await tester.pumpAndSettle();

    expect(find.text('庭園の準備'), findsOneWidget);
    expect(find.text('季節の気配'), findsOneWidget);
  });
}
