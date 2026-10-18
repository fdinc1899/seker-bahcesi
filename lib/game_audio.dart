import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// The tracks in assets/audio are original synthesized sounds included offline.
/// All audio requests are optional: a sound device error never stops gameplay.
enum CandySound { tap, swipe, pop, special, combo, win, lose }

class GameAudio {
  final AudioPlayer _music = AudioPlayer();
  final List<AudioPlayer> _effects = List.generate(4, (_) => AudioPlayer());
  bool _enabled = true;
  bool _initialized = false;
  bool _disposed = false;
  int _nextEffect = 0;

  bool get enabled => _enabled;

  Future<void> initialize({required bool enabled}) async {
    _enabled = enabled;
    try {
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.setVolume(.32);
      for (final effect in _effects) {
        await effect.setReleaseMode(ReleaseMode.stop);
        await effect.setVolume(.84);
      }
      _initialized = true;
      if (_enabled && !_disposed) await resumeMusic();
    } catch (_) {
      // Audio is noncritical; the game remains playable without sound.
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
    try { await _music.pause(); } catch (_) {}
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    if (!_initialized || _disposed) return;
    if (enabled) {
      await resumeMusic();
    } else {
      await pauseMusic();
      for (final effect in _effects) {
        try { await effect.stop(); } catch (_) {}
      }
    }
  }

  /// Rotating players allows an explosion and a combo sound to overlap.
  void play(CandySound cue) {
    if (!_enabled || !_initialized || _disposed) return;
    final sound = switch (cue) {
      CandySound.tap => 'tik.wav',
      CandySound.swipe => 'kaydir.wav',
      CandySound.pop => 'patlama.wav',
      CandySound.special => 'ozel.wav',
      CandySound.combo => 'kombo.wav',
      CandySound.win => 'kazandin.wav',
      CandySound.lose => 'kaybettin.wav',
    };
    final player = _effects[_nextEffect];
    _nextEffect = (_nextEffect + 1) % _effects.length;
    unawaited(_playSafe(player, sound));
  }

  Future<void> _playSafe(AudioPlayer player, String sound) async {
    if (!_enabled || _disposed) return;
    // A freshly constructed player may not have a source yet. Stopping such
    // a player can throw on certain Android media backends; never let that
    // prevent the first sound from playing.
    if (player.state != PlayerState.stopped) {
      try { await player.stop(); } catch (_) {}
    }
    if (!_enabled || _disposed) return;
    try { await player.play(AssetSource('audio/$sound')); } catch (_) {}
  }

  Future<void> dispose() async {
    _disposed = true;
    try { await _music.dispose(); } catch (_) {}
    for (final effect in _effects) {
      try { await effect.dispose(); } catch (_) {}
    }
  }
}
