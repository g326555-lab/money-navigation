import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';

import 'ai/ai_trace.dart';
import 'ai/cloud_functions.dart';

/// Natural Thai voice from Google Cloud Text-to-Speech (through the
/// `tts-thai` function). Each sentence is fetched once and kept as a file
/// for the session. When it is not configured, offline or slower than
/// [fetchTimeout], [speak] returns null and the caller uses the phone's own
/// voice.
class CloudVoice {
  CloudVoice({CloudFunctions? functions})
    : _functions = functions ?? CloudFunctions();

  static const fetchTimeout = Duration(milliseconds: 2500);

  /// Longest a spoken sentence may play before it is given up.
  static const playLimit = Duration(seconds: 15);

  final CloudFunctions _functions;
  final _player = AudioPlayer();
  final Map<String, File> _cache = {};

  /// Plays [text] and completes when playback ends. Returns the measured
  /// fetch step (zero-length when cached), or null when the cloud voice was
  /// not used.
  Future<AiTrace?> speak(String text) async {
    if (!CloudFunctions.configured) return null;
    AiTrace? trace;
    var file = _cache[text];
    if (file == null) {
      try {
        final (fetched, measured) = await AiTrace.measure(
          AiEngine.cloudTts,
          () => _fetch(text),
        );
        if (fetched == null) return null;
        file = fetched;
        trace = measured;
        _cache[text] = file;
      } on CloudFunctionError {
        return null;
      }
    }
    try {
      await _player.setAudioContext(_context);
      await _player.play(DeviceFileSource(file.path));
      await _player.onPlayerComplete.first.timeout(playLimit);
    } catch (_) {
      // Stopped, disposed or failed mid-play: the caller falls back.
      return null;
    }
    return trace ?? const AiTrace(AiEngine.cloudTts, Duration.zero);
  }

  Future<void> stop() => _player.stop();

  Future<void> dispose() => _player.dispose();

  Future<File?> _fetch(String text) async {
    final json = await _functions.call('tts-thai', {
      'text': text,
    }, timeout: fetchTimeout);
    final audio = json['audioBase64'];
    if (audio is! String || audio.isEmpty) return null;
    final dir = await Directory.systemTemp.createTemp('voice');
    final file = File('${dir.path}/say.mp3');
    await file.writeAsBytes(base64Decode(audio));
    return file;
  }

  /// Plays through the speaker and keeps the microphone session usable for
  /// the next listen (iOS playAndRecord, like the phone voice).
  static final _context = AudioContextConfig(
    route: AudioContextConfigRoute.speaker,
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();
}
