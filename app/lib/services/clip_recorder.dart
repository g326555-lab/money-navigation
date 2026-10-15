import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

/// How the last [ClipRecorder.record] ended.
enum ClipOutcome {
  /// Speech was heard; the clip holds it.
  speech,

  /// Nobody spoke within [ClipRecorder.waitForSpeech]: try again, the
  /// recorder works.
  silence,

  /// No permission or the recorder failed: use something else.
  failed,
}

/// Records what the seller says as one short clip (16 kHz mono 16-bit PCM,
/// the format Google Cloud Speech-to-Text takes as LINEAR16), for when the
/// phone is online. It waits for speech, then stops on its own after a
/// short silence. On Android only one app should capture the microphone at
/// a time, so this is used instead of on-device recognition, not beside it.
class ClipRecorder {
  ClipRecorder({AudioRecorder? recorder}) : _rec = recorder ?? AudioRecorder();

  static const sampleRate = 16000;

  /// Longest clip; a market sentence is a few seconds.
  static const maxDuration = Duration(seconds: 10);

  /// Silence after the first words that ends the clip.
  static const silenceAfterSpeech = Duration(milliseconds: 1200);

  /// How long to wait for the seller to start talking.
  static const waitForSpeech = Duration(seconds: 8);

  /// Loudness (dBFS) above which a chunk counts as speech.
  static const speechDbfs = -38.0;

  /// The level shown on the waveform runs from this dBFS (0) to 0 dBFS (1).
  static const floorDbfs = -60.0;

  final AudioRecorder _rec;
  Completer<Uint8List?>? _done;

  /// Why the last recording ended; a null clip is either silence (record
  /// again) or a failure (fall back).
  ClipOutcome get lastOutcome => _outcome;
  ClipOutcome _outcome = ClipOutcome.failed;

  Future<bool> hasPermission() => _rec.hasPermission();

  /// Records one sentence. [onLevel] gets 0..1 levels for the waveform,
  /// [onStarted] fires when the first audio arrives (the microphone is
  /// really open: say "Listening" only then, or the first word is lost),
  /// and [onSpeech] fires once when speech starts. Everything from the
  /// first audio on is kept, including the quiet lead-in. Returns the PCM bytes, or
  /// null when nobody spoke, permission is missing or recording failed.
  Future<Uint8List?> record({
    required void Function(double level) onLevel,
    void Function()? onSpeech,
    void Function()? onStarted,
  }) async {
    if (_done != null) return null;
    final done = _done = Completer<Uint8List?>();
    final bytes = BytesBuilder(copy: false);
    final started = DateTime.now();
    DateTime? speechAt;
    DateTime? quietSince;
    StreamSubscription<Uint8List>? sub;
    var broke = false;
    Timer? guard;

    Future<void> finish({required bool keep}) async {
      if (done.isCompleted) return;
      guard?.cancel();
      await sub?.cancel();
      try {
        await _rec.stop();
      } on Object {
        // Already stopped.
      }
      final clip = keep && speechAt != null ? bytes.takeBytes() : null;
      _outcome = clip != null
          ? ClipOutcome.speech
          : broke
          ? ClipOutcome.failed
          : ClipOutcome.silence;
      done.complete(clip);
    }

    try {
      if (!await _rec.hasPermission()) {
        _outcome = ClipOutcome.failed;
        _done = null;
        done.complete(null);
        return null;
      }
      final stream = await _rec.startStream(
        // Google's advice for Speech-to-Text: 16 kHz LINEAR16, no automatic
        // gain, no noise reduction (it hurts recognition). Android records
        // from the speech-recognition source.
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: 1,
          autoGain: false,
          echoCancel: false,
          noiseSuppress: false,
          androidConfig: AndroidRecordConfig(
            audioSource: AndroidAudioSource.voiceRecognition,
          ),
        ),
      );
      guard = Timer(maxDuration, () => finish(keep: true));
      var first = true;
      sub = stream.listen(
        (chunk) {
          if (first) {
            first = false;
            onStarted?.call();
          }
          bytes.add(chunk);
          final db = _dbfs(chunk);
          onLevel(((db - floorDbfs) / -floorDbfs).clamp(0.0, 1.0));
          final now = DateTime.now();
          if (db > speechDbfs) {
            quietSince = null;
            if (speechAt == null) {
              speechAt = now;
              onSpeech?.call();
            }
          } else if (speechAt != null) {
            quietSince ??= now;
            if (now.difference(quietSince!) >= silenceAfterSpeech) {
              finish(keep: true);
            }
          } else if (now.difference(started) >= waitForSpeech) {
            finish(keep: false);
          }
        },
        onError: (Object e) {
          broke = true;
          finish(keep: false);
        },
        onDone: () => finish(keep: true),
      );
    } on Object catch (e) {
      if (kDebugMode) debugPrint('[clip] failed: $e');
      _outcome = ClipOutcome.failed;
      if (!done.isCompleted) done.complete(null);
    }
    final result = await done.future;
    _done = null;
    return result;
  }

  /// Stops early and keeps what was heard (the traveler tapped "Done").
  Future<void> stop() async {
    if (_done == null) return;
    try {
      await _rec.stop();
    } on Object {
      // Already stopped.
    }
  }

  Future<void> dispose() => _rec.dispose();

  /// Loudness of a chunk of 16-bit little-endian PCM, in dBFS.
  static double _dbfs(Uint8List chunk) {
    final data = ByteData.sublistView(chunk);
    final n = chunk.length ~/ 2;
    if (n == 0) return floorDbfs;
    var sum = 0.0;
    for (var i = 0; i < n; i++) {
      final s = data.getInt16(i * 2, Endian.little) / 32768;
      sum += s * s;
    }
    final rms = math.sqrt(sum / n);
    return rms <= 0 ? floorDbfs : 20 * math.log(rms) / math.ln10;
  }
}
