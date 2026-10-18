
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

enum CandySound {
  tap,
  swipe,
  pop,
  special,
  combo,
  win,
  lose,
}

class GameAudio {
  static AudioContext get musicContext => AudioContext(
        android: const AudioContextAndroid(
          audioFocus: AndroidAudioFocus.gain,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
      );

  static AudioContext get effectContext => AudioContext(
        android: const AudioContextAndroid(
          audioFocus: AndroidAudioFocus.none,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.game,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
      );

  final AudioPlayer _musicPlayer = AudioPlayer();

  final List<AudioPlayer> _effectPlayers =
      List.generate(5, (_) => AudioPlayer());

  final List<bool> _effectReady =
      List<bool>.filled(5, false);

  final List<Future<void>> _effectQueue =
      List.generate(5, (_) => Future<void>.value());

  bool _enabled = true;
  bool _initialized = false;
  bool _disposed = false;
  int _nextEffect = 0;

  bool get enabled => _enabled;

  Future<void> initialize({required bool enabled}) async {
    _enabled = enabled;
    if (_initialized || _disposed) return;

    try {
      await _musicPlayer.setAudioContext(musicContext);
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(0.32);
      _initialized = true;
    } catch (_) {}

    for (var i = 0; i < _effectPlayers.length && !_disposed; i++) {
      final player = _effectPlayers[i];

      try {
        await player.setAudioContext(effectContext);
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setVolume(0.78);
        _effectReady[i] = true;
      } catch (_) {
        _effectReady[i] = false;
      }
    }

    if (_enabled && !_disposed) {
      await resumeMusic();
    }
  }

  Future<void> resumeMusic() async {
    if (!_initialized || !_enabled || _disposed) return;

    try {
      final state = _musicPlayer.state;

      if (state == PlayerState.playing) return;

      if (state == PlayerState.paused) {
        await _musicPlayer.resume();
      } else {
        await _musicPlayer.play(
          AssetSource('audio/seker_bahcesi_muzik.wav'),
        );
      }
    } catch (_) {}
  }

  Future<void> pauseMusic() async {
    if (!_initialized || _disposed) return;

    try {
      await _musicPlayer.pause();
    } catch (_) {}
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    if (_disposed) return;

    if (enabled) {
      await resumeMusic();
      return;
    }

    await pauseMusic();

    for (final player in _effectPlayers) {
      try {
        await player.stop();
      } catch (_) {}
    }
  }

  void play(CandySound cue) {
    if (!_enabled || !_initialized || _disposed) return;

    final filename = switch (cue) {
      CandySound.tap => 'tik.wav',
      CandySound.swipe => 'kaydir.wav',
      CandySound.pop => 'patlama.wav',
      CandySound.special => 'ozel.wav',
      CandySound.combo => 'kombo.wav',
      CandySound.win => 'kazandin.wav',
      CandySound.lose => 'kaybettin.wav',
    };

    int? index;

    for (var offset = 0;
        offset < _effectPlayers.length;
        offset++) {
      final candidate =
          (_nextEffect + offset) % _effectPlayers.length;

      if (_effectReady[candidate]) {
        index = candidate;
        break;
      }
    }

    if (index == null) return;

    _nextEffect = (index + 1) % _effectPlayers.length;

    final currentIndex = index;

    _effectQueue[currentIndex] =
        _effectQueue[currentIndex]
            .catchError((Object _) {})
            .then(
              (_) => _playEffect(
                _effectPlayers[currentIndex],
                filename,
              ),
            );
  }

  Future<void> _playEffect(
    AudioPlayer player,
    String filename,
  ) async {
    if (!_enabled || _disposed) return;

    try {
      await player.stop();

      if (!_enabled || _disposed) return;

      await player.play(
        AssetSource('audio/$filename'),
      );
    } catch (_) {}
  }

  Future<void> dispose() async {
    if (_disposed) return;

    _disposed = true;

    try {
      await _musicPlayer.dispose();
    } catch (_) {}

    for (final player in _effectPlayers) {
      try {
        await player.dispose();
      } catch (_) {}
    }
  }
}
