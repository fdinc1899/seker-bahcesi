import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seker_bahcesi/candy_art.dart';
import 'package:seker_bahcesi/game_engine.dart';

void main() {
  testWidgets('V11 premium seker gorselleri bundle icinde bulunur',
      (tester) async {
    final paths = [
      for (var i = 0; i < 6; i++) 'assets/images/candy_$i.png',
      'assets/images/candy_bomb.png',
      'assets/images/v11_candy_valley.webp',
      'assets/images/v11_map_valley.webp',
    ];
    for (final path in paths) {
      final data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(100), reason: path);
    }
  });

  testWidgets('V11 sekerleri ve ozel sekerler cizilebilir', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Wrap(children: [
          CandyPiece(type: 0, size: 48),
          CandyPiece(type: 1, size: 48),
          CandyPiece(type: 2, size: 48),
          CandyPiece(type: 3, size: 48),
          CandyPiece(type: 4, size: 48),
          CandyPiece(type: 5, size: 48),
          CandyPiece(type: 0, size: 48, special: SpecialKind.horizontal),
          CandyPiece(type: 1, size: 48, special: SpecialKind.vertical),
          CandyPiece(type: 2, size: 48, special: SpecialKind.colorBomb),
        ]),
      ),
    ));
    await tester.pump();
    expect(find.byType(CandyPiece), findsNWidgets(9));
    expect(tester.takeException(), isNull);
  });
}
