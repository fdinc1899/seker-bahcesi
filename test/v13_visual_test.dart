import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seker_bahcesi/v12_map_path.dart';

void main() {
  testWidgets('V13 manzara dosyalari apk iceriginde bulunur', (tester) async {
    for (final path in [
      'assets/images/v13_home_scene.webp',
      'assets/images/v13_map_scene.webp',
    ]) {
      final bytes = await rootBundle.load(path);
      expect(bytes.lengthInBytes, greaterThan(30000));
    }
  });
  testWidgets('V13 yol cizimi calisir', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: CustomPaint(size: Size(320, 1125), painter: V12RoadPainter()),
    )));
    expect(tester.takeException(), isNull);
  });
}
