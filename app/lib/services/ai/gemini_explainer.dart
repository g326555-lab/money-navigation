import 'ai_trace.dart';
import 'cloud_functions.dart';

/// Optional one-sentence explanation from Gemini (function `gemini`, task
/// `explain`). The free key often answers 503, so this gives up after 3 s and
/// returns null; screens must look complete without it and show the
/// sentence only when it arrives.
class GeminiExplainer {
  GeminiExplainer({CloudFunctions? functions})
    : _functions = functions ?? CloudFunctions();

  final CloudFunctions _functions;

  static const timeout = Duration(seconds: 3);

  /// [facts] are the already verified numbers; Gemini may only reword them.
  Future<(String, AiTrace)?> explain(Map<String, Object?> facts) async {
    try {
      final (json, trace) = await AiTrace.measure(
        AiEngine.gemini,
        () => _functions.call(
          'gemini',
          {'task': 'explain', 'input': {'facts': facts}},
          timeout: timeout,
        ),
      );
      final raw = json['text'];
      final text = raw is String ? raw.trim() : '';
      if (text.isEmpty || !_onlyKnownNumbers(text, facts)) return null;
      return (text, trace);
    } on CloudFunctionError {
      return null;
    }
  }
}

/// True when every number in [text] is one of the verified [facts]. A
/// sentence with any other number is dropped, so Gemini can never show a
/// figure the app did not compute.
bool _onlyKnownNumbers(String text, Map<String, Object?> facts) {
  final known = <double>{
    for (final v in facts.values)
      if (v is num) v.toDouble(),
  };
  for (final m in RegExp(r'\d[\d,]*(?:\.\d+)?').allMatches(text)) {
    final value = double.tryParse(m.group(0)!.replaceAll(',', ''));
    if (value == null || !known.any((k) => (k - value).abs() < 0.005)) {
      return false;
    }
  }
  return true;
}
