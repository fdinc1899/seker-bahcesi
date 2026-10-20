import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seker_bahcesi/v15_5_visuals.dart';

void main() {
  testWidgets('current map level remains tappable when pulsing', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SizedBox(
      width: 62, height: 72,
      child: V155CurrentLevelPulse(child: GestureDetector(
        onTap: () => tapped++,
        child: const ColoredBox(color: Colors.pink),
      )),
    ))));
    await tester.tap(find.byType(GestureDetector));
    expect(tapped, 1);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('map shimmer is noninteractive', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: SizedBox(height: 150, width: 150, child: V155MapShimmer()),
    )));
    expect(find.byType(V155MapShimmer), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
