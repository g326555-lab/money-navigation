import 'ai_trace.dart';
import 'cloud_functions.dart';

/// One page a range rests on: the quote was found word for word on it.
class PriceQuote {
  const PriceQuote({
    required this.url,
    required this.quote,
    required this.date,
    required this.fetched,
  });

  final String url;
  final String quote;

  /// yyyy-MM-dd; [fetched] true means the day we read it, not published.
  final String date;
  final bool fetched;
}

/// A sourced Bangkok price range for an item missing from our data file.
class PriceReference {
  const PriceReference({
    required this.lowThb,
    required this.highThb,
    required this.sources,
    required this.cached,
    required this.trace,
  });

  final double lowThb;
  final double highThb;
  final List<PriceQuote> sources;
  final bool cached;
  final AiTrace trace;
}

/// Asks function `price-reference` (Tavily search, our own page fetch,
/// Gemini reading, verbatim-quote check, cached in `facts`). Null means no
/// sourced range: show "No usual price on record for this yet". A new
/// item takes 4-10 s the first time, about 0.3 s once cached (7 days); on
/// 10 everyday items plus vanilla latte it found a verified range for 5.
class PriceReferenceService {
  PriceReferenceService({CloudFunctions? functions})
    : _functions = functions ?? CloudFunctions();

  final CloudFunctions _functions;

  /// A first lookup takes 4-10 s; the screen shows its verdict meanwhile
  /// and fills the range in if it arrives in time.
  static const timeout = Duration(seconds: 10);

  Future<PriceReference?> lookup(String nameEn) async {
    try {
      final (json, trace) = await AiTrace.measure(
        AiEngine.webSearch,
        () => _functions.call('price-reference', {
          'nameEn': nameEn,
        }, timeout: timeout),
      );
      final low = json['low'], high = json['high'], sources = json['sources'];
      if (low is! num || high is! num || sources is! List) return null;
      final quotes = [
        for (final s in sources)
          if (s is Map &&
              s['url'] is String &&
              s['quote'] is String &&
              s['date'] is String)
            PriceQuote(
              url: s['url'] as String,
              quote: s['quote'] as String,
              date: s['date'] as String,
              fetched: s['dateKind'] != 'published',
            ),
      ];
      if (quotes.isEmpty) return null;
      return PriceReference(
        lowThb: low.toDouble(),
        highThb: high.toDouble(),
        sources: quotes,
        cached: json['cached'] == true,
        trace: trace,
      );
    } on CloudFunctionError {
      return null;
    }
  }
}
