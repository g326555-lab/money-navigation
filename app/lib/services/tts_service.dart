import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Reads Thai sentences aloud for the seller to hear.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  bool _thaiAvailable = false;

  /// Puts iOS audio back on the loudspeaker for speech. Recording a clip
  /// (record package) changes the audio session, so call this after one.
  Future<void> restoreSpeaker() async {
    if (Platform.isIOS) {
      // speech_to_text saves and restores the session category around each
      // listen. Setting playAndRecord + defaultToSpeaker first means the
      // restored category plays through the speaker, not the earpiece, and
      // ignores the Silent switch (flutter_tts#536).
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playAndRecord,
        [
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
        IosTextToSpeechAudioMode.defaultMode,
      );
    }
  }

  /// Sets up Thai speech. Returns false when no Thai voice is installed.
  Future<bool> prepare() async {
    if (_ready) return _thaiAvailable;
    _ready = true;
    await restoreSpeaker();
    final available = await _tts.isLanguageAvailable(thaiTtsLanguage);
    _thaiAvailable = available == true || available == 1;
    if (!_thaiAvailable) return false;
    await _tts.setLanguage(thaiTtsLanguage);
    await _pickThaiVoice();
    await _tts.setSpeechRate(thaiSpeechRate);
    await _tts.awaitSpeakCompletion(true);
    return true;
  }

  /// Chooses a Thai voice explicitly; on Android prefers an on-device one so
  /// it works without a network.
  Future<void> _pickThaiVoice() async {
    final voices = await _tts.getVoices;
    if (voices is! List) return;
    final thai = [
      for (final v in voices)
        if (v is Map &&
            '${v['locale']}'
                .toLowerCase()
                .replaceAll('_', '-')
                .startsWith('th'))
          {'name': '${v['name']}', 'locale': '${v['locale']}'},
    ];
    if (thai.isEmpty) return;
    final local = thai.where((v) => v['name']!.contains('local'));
    await _tts.setVoice(local.isNotEmpty ? local.first : thai.first);
  }

  /// Speaks [text] and completes when it has finished.
  Future<void> speak(String text) async {
    await _tts.stop();
    if (kDebugMode) debugPrint('[voice] phone speak');
    final result = await _tts.speak(text);
    if (kDebugMode) debugPrint('[voice] phone done result=$result');
  }

  Future<void> stop() => _tts.stop();
}

const thaiTtsLanguage = 'th-TH';

/// Slightly slower than normal (0.5 is normal on both platforms) so a
/// seller catches every number.
const thaiSpeechRate = 0.42;
