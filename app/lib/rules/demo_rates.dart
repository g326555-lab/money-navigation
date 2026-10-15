import 'dart:convert';

import 'exchange_rate.dart';

/// Fixed exchange rates for the demo state, read from
/// `assets/data/demo_rates.json`. That file is the only place they live;
/// normal use takes live Frankfurter rates instead.
class DemoRates {
  DemoRates._(this.source, this.date, this._quotes);

  /// What the rates are labelled with on screen, so a demo rate is never
  /// shown as if it came from the live source.
  final String source;

  /// The date the demo rates are shown with, 'YYYY-MM-DD'.
  final String date;
  final List<RateQuote> _quotes;

  List<RateQuote> get quotes => List.unmodifiable(_quotes);

  /// The demo rate from [base] to [quote], or null when the file has none.
  RateQuote? quoteFor(String base, String quote) {
    for (final q in _quotes) {
      if (q.base == base && q.quote == quote) return q;
    }
    return null;
  }
}

/// Parses the demo rates file. Returns null when anything is missing or not
/// a usable rate; it never fills in a value.
DemoRates? parseDemoRates(String json) {
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException {
    return null;
  }
  if (decoded is! Map) return null;
  final source = decoded['source'];
  final date = decoded['date'];
  final rates = decoded['rates'];
  if (source is! String || source.isEmpty) return null;
  if (date is! String || rates is! List || rates.isEmpty) return null;
  final day = DateTime.tryParse(date);
  if (day == null) return null;
  final quotes = <RateQuote>[];
  for (final entry in rates) {
    if (entry is! Map) return null;
    final base = entry['base'];
    final quote = entry['quote'];
    final rate = entry['rate'];
    if (base is! String || quote is! String) return null;
    if (rate is! num || !rate.isFinite || !(rate > 0)) return null;
    quotes.add(
      RateQuote(
        base: base,
        quote: quote,
        rate: rate.toDouble(),
        date: date,
        fetchedAt: day,
      ),
    );
  }
  return DemoRates._(source, date, quotes);
}
