import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seker_bahcesi/candy_art.dart';

void main() {
  testWidgets('V2 cam parlakligindaki seker gorunur', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: CandyPiece(type: 5, size: 72))),
    ));
    expect(find.byType(CandyPiece), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('V2 patlama boyayicisi render edilir', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: CustomPaint(
        size: const Size(200, 200),
        painter: SparklePainter(
          progress: 0.35,
          centers: const [Offset(75, 75), Offset(125, 95)],
          colors: const [Colors.pink, Colors.amber],
        ),
      )),
    ));
    expect(tester.takeException(), isNull);
  });
}
