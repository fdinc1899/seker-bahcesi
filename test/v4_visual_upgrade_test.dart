import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seker_bahcesi/candy_art.dart';

void main() {
  testWidgets('V4 seviye sekeri widget agacina eklenir', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: CandyPiece(type: 3, size: 72))),
    ));
    expect(find.byType(CandyPiece), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('V4 patlama katmanlari farkli karelerde cizilebilir',
      (tester) async {
    for (final progress in <double>[0, .12, .28, .55, .9, 1]) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: SizedBox.square(
          dimension: 320,
          child: CustomPaint(
            painter: SparklePainter(
              progress: progress,
              centers: const [Offset(70, 70), Offset(150, 150),
                  Offset(225, 190), Offset(150, 230)],
              colors: const [Colors.pink, Colors.amber, Colors.cyan],
            ),
          ),
        )),
      ));
      expect(tester.takeException(), isNull);
    }
  });
}
