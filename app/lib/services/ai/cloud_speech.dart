import 'dart:convert';
import 'dart:typed_data';

import 'ai_trace.dart';
import 'cloud_functions.dart';

/// Cloud recognition of the seller's sentence (function `stt-thai`, Google
/// Cloud Speech-to-Text, th-TH, with our item words as hints). On 15 test
/// sentences it got item and price right 15/15 in quiet and 13/15 with
/// noise in about 1.1 s, against 9/15 and 1/15 on the phone, so it is the
/// second, better guess: the on-device result shows at once and stays the
/// fallback offline. The clip is not stored anywhere.
class CloudSpeech {
  CloudSpeech({CloudFunctions? functions})
    : _functions = functions ?? CloudFunctions();

  final CloudFunctions _functions;

  /// Generous for a slow upload; the trace shows the real wait.
  static const timeout = Duration(seconds: 10);

  /// About 15 s of 16 kHz 16-bit mono PCM.
  static const maxBytes = 500 * 1024;

  /// Transcripts of [audio] (best first) with a measured trace, or null on
  /// any failure. [encoding] is `LINEAR16` (raw PCM or a WAV file),
  /// `OGG_OPUS`, `WEBM_OPUS`, `AMR_WB` or `FLAC`. [phrases] are hint words,
  /// normally every item keyword and unit word from the market data.
  Future<(List<String>, AiTrace)?> recognize(
    Uint8List audio, {
    String encoding = 'LINEAR16',
    int sampleRateHertz = 16000,
    List<String> phrases = const [],
  }) async {
    if (audio.isEmpty || audio.length > maxBytes) return null;
    try {
      final (json, trace) = await AiTrace.measure(
        AiEngine.cloudSpeech,
        () => _functions.call('stt-thai', {
          'audioBase64': base64Encode(audio),
          'encoding': encoding,
          'sampleRateHertz': sampleRateHertz,
          'phrases': phrases,
        }, timeout: timeout),
      );
      final alternatives = json['alternatives'];
      if (alternatives is! List) return null;
      final texts = [
        for (final a in alternatives)
          if (a is Map &&
              a['text'] is String &&
              (a['text'] as String).isNotEmpty)
            a['text'] as String,
      ];
      return texts.isEmpty ? null : (texts, trace);
    } on CloudFunctionError {
      return null;
    }
  }
}
