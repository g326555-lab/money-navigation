import 'dart:convert';

import '../../rules/haggle.dart';
import 'ai_trace.dart';
import 'cloud_functions.dart';

/// Last-resort item naming by Gemini (function `gemini`, task
/// `resolve_item`) when the on-device matcher found nothing. It gets every
/// transcript the recognizers produced (on-device and cloud) and may only
/// answer with one of our item keys; anything else is dropped. Optional:
/// null on any failure, after at most [timeout].
class GeminiItemResolver {
  GeminiItemResolver({CloudFunctions? functions})
    : _functions = functions ?? CloudFunctions();

  final CloudFunctions _functions;

  /// The function gives up at 4.5 s; this leaves room for the network.
  static const timeout = Duration(seconds: 5);

  /// Below this Gemini's own confidence the item stays unknown. On 5
  /// hand-written misheard transcripts (15 Oct, NOTES.md) the right picks
  /// came at 0.9 and a wrong one at 0.85. Even above it, the screen asks
  /// "Did they mean …?" rather than judging.
  static const minConfidence = 0.9;

  /// The item Gemini picked from [items] for [alternatives] (best first),
  /// its confidence and a measured trace; null when it is unsure, names
  /// something else, or contradicts the heard [unit].
  Future<(MarketItem, double, AiTrace)?> resolve(
    List<String> alternatives,
    List<MarketItem> items, {
    PriceUnit? unit,
  }) async {
    final transcripts = [
      for (final a in alternatives)
        if (a.trim().isNotEmpty) a.trim(),
    ];
    if (transcripts.isEmpty || items.isEmpty) return null;
    try {
      final (json, trace) = await AiTrace.measure(
        AiEngine.gemini,
        () => _functions.call('gemini', {
          'task': 'resolve_item',
          'input': {
            'alternatives': transcripts,
            'items': [
              for (final i in items)
                {'key': i.key, 'th': i.nameTh, 'unit': i.unit.name},
            ],
          },
        }, timeout: timeout),
      );
      final text = json['text'];
      if (text is! String) return null;
      final answer = jsonDecode(text);
      if (answer is! Map) return null;
      final key = answer['key'];
      final confidence = answer['confidence'];
      if (key is! String || confidence is! num) return null;
      if (confidence < minConfidence) return null;
      final item = items.where((i) => i.key == key).firstOrNull;
      if (item == null || (unit != null && item.unit != unit)) return null;
      return (item, confidence.toDouble(), trace);
    } on CloudFunctionError {
      return null;
    } on FormatException {
      return null;
    }
  }
}
