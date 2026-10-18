import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seker_bahcesi/candy_art.dart';
import 'package:seker_bahcesi/game_engine.dart';

void main() {
  testWidgets('V3 candy variants and specials render', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(children: [
          CandyPiece(type: 0, size: 56),
          CandyPiece(type: 3, size: 56),
          CandyPiece(type: 5, size: 56),
          CandyPiece(type: 2, size: 56, special: SpecialKind.horizontal),
          CandyPiece(type: 0, size: 56, special: SpecialKind.vertical),
          CandyPiece(type: 0, size: 56, special: SpecialKind.colorBomb),
        ]),
      ),
    ));
    expect(find.byType(CandyPiece), findsNWidgets(6));
    expect(tester.takeException(), isNull);
  });

  testWidgets('V3 explosions render without crashing at different progress values',
      (tester) async {
    for (final value in <double>[0, .12, .35, .8, 1]) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CustomPaint(
            size: const Size(260, 260),
            painter: SparklePainter(
              progress: value,
              centers: const [Offset(75, 75), Offset(145, 95), Offset(100, 170)],
              colors: const [Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('V3 painter accepts empty color list safely', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CustomPaint(
          size: const Size(100, 100),
          painter: SparklePainter(
            progress: .2,
            centers: const [Offset(35, 35)],
            colors: const [],
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
  });
}
