import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seker_bahcesi/v5_fx.dart';

void main() {
  testWidgets('V5 score fly-up and celebration paint across frames',
      (tester) async {
    for (final progress in <double>[0, .18, .44, .74, 1]) {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: SizedBox(width: 350, height: 550, child: Stack(children: [
          Positioned.fill(child: CustomPaint(
            painter: V5ScorePainter(
              progress: progress,
              centers: const [Offset(50, 70), Offset(90, 70), Offset(130, 70)],
              points: 480,
              chain: 2,
            ),
          )),
          Positioned.fill(child: CustomPaint(
            painter: V5CelebrationPainter(progress: progress),
          )),
        ])),
      )));
      expect(tester.takeException(), isNull);
    }
  });
}
