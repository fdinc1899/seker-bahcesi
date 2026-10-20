import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// The same in-game announcements are spoken out loud in Turkish.
/// The device must have a Turkish text-to-speech voice installed.
String? celebrationPhraseForMatch(int matchedCount, {int chain = 1}) {
  if (matchedCount >= 5) return 'Muhteşem!';
  if (matchedCount == 4) return 'Mükemmel!';
  if (matchedCount == 3) return 'Harika!';
  if (chain > 1) return 'Süper kombo!';
  return null;
}

class MatchVoice {
  final FlutterTts _tts = FlutterTts();
  bool _enabled = true;
  bool _ready = false;
  bool _disposed = false;
  DateTime? _lastCallout;

  Future<void> initialize({required bool enabled}) async {
    _enabled = enabled;
    if (_disposed) return;
    try {
      // Prevent a large queue of announcements during chain reactions.
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _tts.setQueueMode(0); // Android QUEUE_FLUSH
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.ambient,
          [IosTextToSpeechAudioCategoryOptions.mixWithOthers],
        );
      }
      final languageResult = await _tts.setLanguage('tr-TR');
      if (languageResult == 0) return;
      await _tts.setSpeechRate(0.54);
      await _tts.setPitch(1.12);
      await _tts.setVolume(0.95);
      _ready = true;
    } catch (_) {
      // A missing speech engine must never prevent the game from starting.
      _ready = false;
    }
  }

  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (!enabled) stop();
  }

  void sayForMatch(int matchedCount, {required int chain}) {
    if (!_enabled || !_ready || _disposed) return;
    final phrase = celebrationPhraseForMatch(matchedCount, chain: chain);
    if (phrase == null) return;
    final now = DateTime.now();
    // Avoid stuttering from rapid back-to-back cascades.
    if (_lastCallout != null &&
        now.difference(_lastCallout!) < const Duration(milliseconds: 750)) {
      return;
    }
    _lastCallout = now;
    unawaited(_speak(phrase));
  }

  Future<void> _speak(String phrase) async {
    try {
      // In Android, do not request sound focus. Keep the game's music playing.
      await _tts.speak(phrase, focus: false);
    } catch (_) {
      // Speech is a bonus effect; normal gameplay continues if TTS fails.
    }
  }

  void stop() {
    if (_disposed || !_ready) return;
    unawaited(_stopSafely());
  }

  Future<void> _stopSafely() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  void dispose() {
    if (_disposed) return;
    // Start the stop call while the engine is still marked available.
    stop();
    _disposed = true;
  }
}
