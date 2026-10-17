import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seker_bahcesi/candy_art.dart';
import 'package:seker_bahcesi/game_engine.dart';

void main() {
  testWidgets('Dortlu ve besli eslesme sembolleri cizilebilir', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Row(children: [
          CandyPiece(type: 0, size: 72, special: SpecialKind.horizontal),
          CandyPiece(type: 1, size: 72, special: SpecialKind.vertical),
          CandyPiece(type: 3, size: 72, special: SpecialKind.colorBomb),
        ]),
      ),
    ));
    expect(find.byType(CandyPiece), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}
