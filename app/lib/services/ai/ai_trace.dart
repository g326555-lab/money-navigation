/// Which AI did a step. Names are product names, shown as they are in both
/// languages.
enum AiEngine {
  onDevice('On-device AI'),
  cloudVision('Google Cloud Vision'),
  googleMaps('Google Maps'),
  cloudTts('Google Cloud Text-to-Speech'),
  cloudSpeech('Google Cloud Speech-to-Text'),
  gemini('Gemini');

  const AiEngine(this.displayName);

  final String displayName;
}

/// Evidence of one AI step, measured on this phone while it ran: which
/// engine, how long the user waited for it, and an optional count it worked
/// over (reviews ranked, lines read). Never filled from a constant.
class AiTrace {
  const AiTrace(this.engine, this.elapsed, {this.count});

  final AiEngine engine;
  final Duration elapsed;
  final int? count;

  /// Wall-clock time of [run], measured with a [Stopwatch].
  static Future<(T, AiTrace)> measure<T>(
    AiEngine engine,
    Future<T> Function() run, {
    int? Function(T value)? count,
  }) async {
    final watch = Stopwatch()..start();
    final value = await run();
    watch.stop();
    return (value, AiTrace(engine, watch.elapsed, count: count?.call(value)));
  }

  /// Same as [measure] for synchronous on-device work.
  static (T, AiTrace) measureSync<T>(AiEngine engine, T Function() run) {
    final watch = Stopwatch()..start();
    final value = run();
    watch.stop();
    return (value, AiTrace(engine, watch.elapsed));
  }

  /// "0.2 ms", "38 ms", "0.8 s", "2.1 s": two significant figures at most.
  String get elapsedLabel {
    final us = elapsed.inMicroseconds;
    if (us < 10000) return '${(us / 1000).toStringAsFixed(1)} ms';
    if (us < 1000000) return '${(us / 1000).round()} ms';
    return '${(us / 1000000).toStringAsFixed(1)} s';
  }

  /// "Google Cloud Vision · 0.8 s".
  String get label => '${engine.displayName} · $elapsedLabel';
}
