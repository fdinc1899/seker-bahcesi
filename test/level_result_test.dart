import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seker_bahcesi/level_result.dart';

void main() {
  testWidgets('Kazanma ekrani tebrik, uc yildiz ve odulu gosterir',
      (tester) async {
    var nextPressed = false;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: LevelResultOverlay(
      won: true,
      level: 4,
      score: 3200,
      stars: 3,
      lastLevel: false,
      bonusShuffle: true,
      onPrimary: () => nextPressed = true,
      onMap: () {},
    ))));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('TEBRİKLER!'), findsOneWidget);
    expect(find.text('4. bölümü tamamladın!'), findsOneWidget);
    expect(find.byKey(const ValueKey('three-star-prize')), findsOneWidget);
    expect(find.byKey(const ValueKey('result-star-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('result-star-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('result-star-2')), findsOneWidget);
    await tester.tap(find.text('SONRAKİ BÖLÜM'));
    expect(nextPressed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Kaybetme ekrani basit yeniden dene akisini sunar',
      (tester) async {
    var retryPressed = false;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: LevelResultOverlay(
      won: false,
      level: 2,
      score: 200,
      stars: 0,
      lastLevel: false,
      bonusShuffle: false,
      onPrimary: () => retryPressed = true,
      onMap: () {},
    ))));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('TEKRAR DENE!'), findsOneWidget);
    expect(find.byKey(const ValueKey('three-star-prize')), findsNothing);
    await tester.tap(find.text('YENİDEN DENE'));
    expect(retryPressed, isTrue);
    expect(tester.takeException(), isNull);
  });
}
