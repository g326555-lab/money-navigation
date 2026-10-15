import 'dart:convert';

/// A published exchange rate and when we fetched it.
class RateQuote {
  const RateQuote({
    required this.base,
    required this.quote,
    required this.rate,
    required this.date,
    required this.fetchedAt,
  });

  final String base;
  final String quote;

  /// Units of [quote] per one [base].
  final double rate;

  /// Publication date from the source, 'YYYY-MM-DD'.
  final String date;
  final DateTime fetchedAt;

  Map<String, Object?> toJson() => {
    'base': base,
    'quote': quote,
    'rate': rate,
    'date': date,
    'fetchedAt': fetchedAt.toUtc().toIso8601String(),
  };

  static RateQuote? fromJson(Object? json) {
    if (json is! Map) return null;
    final base = json['base'];
    final quote = json['quote'];
    final rate = json['rate'];
    final date = json['date'];
    final fetchedAt = json['fetchedAt'] is String
        ? DateTime.tryParse(json['fetchedAt'] as String)
        : null;
    if (base is! String || quote is! String || date is! String) return null;
    if (rate is! num || !(rate > 0) || !rate.isFinite || fetchedAt == null) {
      return null;
    }
    return RateQuote(
      base: base,
      quote: quote,
      rate: rate.toDouble(),
      date: date,
      fetchedAt: fetchedAt,
    );
  }
}

/// Parses `GET /v1/latest?base=THB&symbols=USD` from api.frankfurter.dev.
RateQuote? parseFrankfurterLatest(
  String body, {
  required String quote,
  required DateTime fetchedAt,
}) {
  final Object? json;
  try {
    json = jsonDecode(body);
  } on FormatException {
    return null;
  }
  if (json is! Map) return null;
  final base = json['base'];
  final date = json['date'];
  final rates = json['rates'];
  if (base is! String || date is! String || rates is! Map) return null;
  final rate = rates[quote];
  if (rate is! num || !(rate > 0) || !rate.isFinite) return null;
  return RateQuote(
    base: base,
    quote: quote,
    rate: rate.toDouble(),
    date: date,
    fetchedAt: fetchedAt,
  );
}

/// Rates are refreshed about once a day.
const rateMaxAge = Duration(hours: 24);

bool rateNeedsRefresh(RateQuote? cached, DateTime now) =>
    cached == null || now.difference(cached.fetchedAt) >= rateMaxAge;

double convertFromBase(double amount, RateQuote quote) => amount * quote.rate;

/// The same rate read the other way round: units of base per one quote.
double inverseRate(RateQuote quote) => 1 / quote.rate;
