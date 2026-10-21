import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seker_bahcesi/v15_6_super_fx.dart';

void main() {
  test('3, 4, 5 matching celebrations and cascade priority', () {
    expect(v156BurstTier(2, 1), 0);
    expect(v156BurstTier(3, 1), 1);
    expect(v156BurstTier(4, 1), 2);
    expect(v156BurstTier(5, 1), 3);
    expect(v156BurstTier(3, 2), 4);
    expect(v156Celebration(3, 1), 'HARİKA!');
    expect(v156Celebration(4, 1), 'MÜKEMMEL!');
    expect(v156Celebration(5, 1), 'MUHTEŞEM!');
    expect(v156Celebration(3, 3), 'SÜPER KOMBO x3!');
  });

  testWidgets('combo badge fits narrow phones', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Center(
      child: SizedBox(width: 245, child: V156ComboBanner(
        text: 'SÜPER KOMBO x12!', progress: .32, boardSize: 245, tier: 4,
      )),
    ))));
    expect(find.text('SÜPER KOMBO x12!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('burst overlay does not intercept taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SizedBox.square(
      dimension: 200, child: Stack(children: [
        Positioned.fill(child: GestureDetector(
          onTap: () => taps++, child: const ColoredBox(color: Colors.blue),
        )),
        Positioned.fill(child: IgnorePointer(child: CustomPaint(
          painter: const V156SuperBurstPainter(
            progress: .25, tier: 4, centers: [Offset(70, 70), Offset(90, 80)],
            colors: [Colors.red, Colors.amber],
          ),
        ))),
      ]),
    ))));
    await tester.tapAt(const Offset(100, 100));
    expect(taps, 1);
  });
}
