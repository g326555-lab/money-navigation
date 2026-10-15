import 'dart:convert';

import '../../rules/haggle.dart';
import '../../rules/new_item.dart';
import 'ai_trace.dart';
import 'cloud_functions.dart';

/// What Gemini made of the seller's words: one of our items, or a new item
/// whose name is literally in the transcripts (no sourced price range).
class ItemGuess {
  const ItemGuess({
    this.known,
    this.newItem,
    required this.confidence,
    required this.trace,
  });

  final MarketItem? known;
  final NewItem? newItem;
  final double confidence;
  final AiTrace trace;
}

/// Last-resort item naming by Gemini (function `gemini`, task
/// `resolve_item`) when the on-device matcher found nothing. It gets every
/// transcript the recognizers produced (on-device and cloud). A known item
/// must be one of our keys; a new item must pass [acceptNewItem] (its Thai
/// name copied from a transcript). Optional: null on any failure, after at
/// most [timeout].
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

  /// Gemini's reading of [alternatives] (best first); null when it is
  /// unsure, names something not heard, or contradicts the heard [unit].
  Future<ItemGuess?> resolve(
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
      final score = confidence is num ? confidence.toDouble() : 0.0;
      if (key is String) {
        if (score < minConfidence) return null;
        final item = items.where((i) => i.key == key).firstOrNull;
        if (item == null || (unit != null && item.unit != unit)) return null;
        return ItemGuess(known: item, confidence: score, trace: trace);
      }
      final proposed = answer['newItem'];
      if (proposed is! Map) return null;
      final created = acceptNewItem(
        nameTh: '${proposed['nameTh'] ?? ''}',
        nameEn: '${proposed['nameEn'] ?? ''}',
        unit: '${proposed['unit'] ?? ''}',
        category: '${proposed['category'] ?? ''}',
        transcripts: transcripts,
        heardUnit: unit,
      );
      if (created == null) return null;
      return ItemGuess(newItem: created, confidence: score, trace: trace);
    } on CloudFunctionError {
      return null;
    } on FormatException {
      return null;
    }
  }
}
