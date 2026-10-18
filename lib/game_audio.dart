import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// Bundled, offline music and effects. Playback failures never block gameplay.
enum CandySound { tap, swipe, pop, special, combo, win, lose }

/// Background music and short game effects have *different* Android audio
/// focus policies. An effect must not take focus away from our music player.
///
/// With audioplayers the default for EACH player is AUDIOFOCUS_GAIN. Playing a
/// pop sound on a second player can therefore pause the already-playing music.
/// The music player owns focus; effects explicitly request NONE.
class GameAudio {
  static AudioContext get musicContext => AudioContext(
        android: const AudioContextAndroid(
          audioFocus: AndroidAudioFocus.gain,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
        ),
        iOS: const AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
      );

  static AudioContext get effectContext => AudioContext(
        android: const AudioContextAndroid(
          // Do NOT change focus when another candy pops.
          audioFocus: AndroidAudioFocus.none,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.game,
        ),
        iOS: const AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
      );

  final AudioPlayer _music = AudioPlayer();
  final List<AudioPlayer> _effects = List.generate(5, (_) => AudioPlayer());
  final List<bool> _effectReady = List.filled(5, false);
  final List<Future<void>> _effectTasks =
      List.generate(5, (_) => Future<void>.value());

  bool _enabled = true;
  bool _initialized = false;
  bool _disposed = false;
  int _nextEffect = 0;

  bool get enabled => _enabled;

  Future<void> initialize({required bool enabled}) async {
    _enabled = enabled;
    if (_initialized || _disposed) return;

    // Configure the looping track first. It remains independent of SFX.
    try {
      await _music.setAudioContext(musicContext);
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.setVolume(.32);
      _initialized = true;
      if (_enabled && !_disposed) await resumeMusic();
    } catch (_) {
      // Music is optional; errors must not interfere with the game.
    }

    for (var i = 0; i < _effects.length && !_disposed; i++) {
      try {
        final effect = _effects[i];
        // IMPORTANT: If context setup fails, don't start the effect with its
        // default gain focus; that would interrupt the background track.
        await effect.setAudioContext(effectContext);
        await effect.setPlayerMode(PlayerMode.lowLatency);
        await effect.setReleaseMode(ReleaseMode.stop);
        await effect.setVolume(.78);
        _effectReady[i] = true;
      } catch (_) {
        _effectReady[i] = false;
      }
    }
  }

  Future<void> resumeMusic() async {
    if (!_enabled || _disposed || !_initialized) return;
    try {
      if (_music.state == PlayerState.playing) return;
      if (_music.state == PlayerState.paused) {
        await _music.resume();
      } else {
        await _music.play(AssetSource('audio/seker_bahcesi_muzik.wav'));
      }
    } catch (_) {}
  }

  Future<void> pauseMusic() async {
    if (!_initialized || _disposed) return;
    try {
      await _music.pause();
    } catch (_) {}
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    if (_disposed) return;
    if (enabled) {
      await resumeMusic();
    } else {
      await pauseMusic();
      for (final effect in _effects) {
        try {
          await effect.stop();
        } catch (_) {}
      }
    }
  }

  /// Concurrent sounds use separate players without stealing Android focus.
  void play(CandySound cue) {
    if (!_enabled || _disposed || !_initialized) return;
    final sound = switch (cue) {
      CandySound.tap => 'tik.wav',
      CandySound.swipe => 'kaydir.wav',
      CandySound.pop => 'patlama.wav',
      CandySound.special => 'ozel.wav',
      CandySound.combo => 'kombo.wav',
      CandySound.win => 'kazandin.wav',
      CandySound.lose => 'kaybettin.wav',
    };

    // Skip players that failed the no-focus setup; never fall back to gain.
    final start = _nextEffect;
    int? selected;
    for (var n = 0; n < _effects.length; n++) {
      final i = (start + n) % _effects.length;
      if (_effectReady[i]) {
        selected = i;
        break;
      }
    }
    if (selected == null) return;
    _nextEffect = (selected + 1) % _effects.length;

    // Serialise operations for each native player so rapid matches can't
    // race stop()/play() on the same instance. Different players overlap.
    _effectTasks[selected] = _effectTasks[selected]
        .catchError((Object _) {})
        .then((_) => _playSafe(_effects[selected!], sound));
  }

  Future<void> _playSafe(AudioPlayer player, String sound) async {
    if (!_enabled || _disposed) return;
    try {
      if (player.state != PlayerState.stopped) await player.stop();
      if (!_enabled || _disposed) return;
      await player.play(AssetSource('audio/$sound'));
    } catch (_) {
      // Noncritical: leave the looped music untouched.
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await _music.dispose();
    } catch (_) {}
    for (final effect in _effects) {
      try {
        await effect.dispose();
      } catch (_) {}
    }
  }
}
