import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seker_bahcesi/candy_art.dart';
import 'package:seker_bahcesi/game_audio.dart';

void main() {
  test('Ses kimliklerinin her biri ayri olmalidir', () {
    expect(CandySound.values.length, 7);
    expect(CandySound.values.toSet().length, 7);
  });

  testWidgets('Patlama parcaciklari tuvale cizilir', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: CustomPaint(
      size: const Size(320, 320),
      painter: SparklePainter(
        progress: .24,
        centers: const [Offset(80, 80), Offset(130, 200)],
        colors: const [Colors.pink, Colors.cyan],
      ),
    ))));
    expect(tester.takeException(), isNull);
  });

  test('Muzik ve ses dosyalari Flutter asset paketine dahil', () async {
    // Root bundle lists everything declared under flutter/assets.
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    const required = [
      'seker_bahcesi_muzik.wav', 'tik.wav', 'kaydir.wav',
      'patlama.wav', 'ozel.wav', 'kombo.wav', 'kazandin.wav', 'kaybettin.wav',
    ];
    for (final name in required) {
      expect(manifest.listAssets().contains('assets/audio/$name'), isTrue,
          reason: '$name must be bundled offline');
    }
  });
}
