import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seker_bahcesi/game_audio.dart';

void main() {
  test('Uzun sureli muzik Android oyun ses odagini alir', () {
    final context = GameAudio.musicContext;
    expect(context.android.audioFocus, AndroidAudioFocus.gain);
    expect(context.android.contentType, AndroidContentType.music);
    expect(context.android.usageType, AndroidUsageType.game);
  });

  test('Kisa patlama sesleri muzikten audio focus CALMAZ', () {
    final music = GameAudio.musicContext;
    final effect = GameAudio.effectContext;
    expect(effect.android.audioFocus, AndroidAudioFocus.none);
    expect(effect.android.contentType, AndroidContentType.sonification);
    expect(effect.android.usageType, AndroidUsageType.game);
    expect(effect.android.audioFocus, isNot(music.android.audioFocus));
  });

  test('iOS oturumu muzigi ve efektleri birlikte calabilir', () {
    expect(GameAudio.musicContext.iOS.options,
        contains(AVAudioSessionOptions.mixWithOthers));
    expect(GameAudio.effectContext.iOS.options,
        contains(AVAudioSessionOptions.mixWithOthers));
  });
}
