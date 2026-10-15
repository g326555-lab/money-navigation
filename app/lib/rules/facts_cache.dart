// Facts the server re-checks once a day against their official pages
// (supabase/functions/facts-refresh). The phone keeps the last copy for a
// day, then asks again; offline it uses the last copy, then the bundled file.

import 'dart:convert';

import 'pay_facts.dart';

/// How long a fetched copy is used before asking the server again.
const factsMaxAge = Duration(hours: 24);

/// The Kasikorn Visa fee: the bundled Thai ATM fee for foreign cards.
const thAtmFeeKey = 'th.atm_fee.kasikorn.visa';

/// One row of the server's `facts` table.
class LiveFact {
  const LiveFact({
    required this.key,
    required this.value,
    required this.unit,
    required this.sourceUrl,
    required this.quote,
    required this.checkedAt,
    required this.fetchedAt,
    required this.status,
    required this.note,
  });

  final String key;
  final double value;
  final String unit;
  final String sourceUrl;

  /// The sentence on the source page the value was read from.
  final String? quote;

  /// When the server last looked at the source.
  final DateTime checkedAt;

  /// When the value was last read successfully.
  final DateTime? fetchedAt;

  /// 'updated', 'unchanged', 'kept' (check failed, old value kept) or 'new'.
  final String status;

  /// Why a check failed, for 'kept'.
  final String? note;

  /// Null when the row lacks a key, a number, a source or a check time.
  static LiveFact? fromRow(Map<String, Object?> row) {
    final key = row['key'];
    final source = row['source_url'];
    final raw = row['value'];
    final value = raw is num
        ? raw.toDouble()
        : raw is String
        ? double.tryParse(raw)
        : null;
    final checked = row['checked_at'] is String
        ? DateTime.tryParse(row['checked_at'] as String)
        : null;
    if (key is! String || key.isEmpty) return null;
    if (source is! String || source.trim().isEmpty) return null;
    if (value == null || !value.isFinite || checked == null) return null;
    final fetched = row['fetched_at'] is String
        ? DateTime.tryParse(row['fetched_at'] as String)
        : null;
    return LiveFact(
      key: key,
      value: value,
      unit: row['unit'] is String ? row['unit'] as String : '',
      sourceUrl: source,
      quote: row['quoted_text'] is String ? row['quoted_text'] as String : null,
      checkedAt: checked.toLocal(),
      fetchedAt: fetched?.toLocal(),
      status: row['status'] is String ? row['status'] as String : 'new',
      note: row['note'] is String ? row['note'] as String : null,
    );
  }

  Map<String, Object?> toJson() => {
    'key': key,
    'value': value,
    'unit': unit,
    'source_url': sourceUrl,
    'quoted_text': quote,
    'checked_at': checkedAt.toIso8601String(),
    'fetched_at': fetchedAt?.toIso8601String(),
    'status': status,
    'note': note,
  };
}

/// What one day's check did.
class FactsSummary {
  const FactsSummary({
    required this.checked,
    required this.updated,
    required this.unchanged,
    required this.kept,
  });

  final int checked;
  final int updated;
  final int unchanged;
  final int kept;
}

/// The copy of the facts kept on the phone.
class FactsSnapshot {
  const FactsSnapshot({required this.facts, required this.savedAt});

  final List<LiveFact> facts;
  final DateTime savedAt;

  bool isStale(DateTime now) => now.difference(savedAt) >= factsMaxAge;

  /// Facts checked on [day]'s local date.
  FactsSummary summary(DateTime day) {
    bool sameDay(DateTime t) =>
        t.year == day.year && t.month == day.month && t.day == day.day;
    final today = [
      for (final f in facts)
        if (sameDay(f.checkedAt)) f,
    ];
    int count(String status) => today.where((f) => f.status == status).length;
    return FactsSummary(
      checked: today.length,
      updated: count('updated'),
      unchanged: count('unchanged'),
      kept: count('kept'),
    );
  }

  String encode() => jsonEncode({
    'savedAt': savedAt.toIso8601String(),
    'facts': [for (final f in facts) f.toJson()],
  });

  static FactsSnapshot? decode(String json) {
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      return null;
    }
    if (decoded is! Map || decoded['facts'] is! List) return null;
    final saved = decoded['savedAt'] is String
        ? DateTime.tryParse(decoded['savedAt'] as String)
        : null;
    if (saved == null) return null;
    return FactsSnapshot(
      facts: [
        for (final f in decoded['facts'] as List)
          if (f is Map) ?LiveFact.fromRow(Map<String, Object?>.from(f)),
      ],
      savedAt: saved,
    );
  }
}

/// [bundled] with the server's checked values laid over it. A fact whose
/// check failed ('kept') keeps the date the bundle had; a checked one moves
/// it to the day of the check. Unknown keys and non-positive values are
/// ignored. [bundled] itself is not changed.
PayFacts applyLiveFacts(PayFacts bundled, List<LiveFact> live) {
  final visa = _last(live, thAtmFeeKey);
  final th = bundled.country('TH');
  final fee = th?.foreignCardAtmFee;
  if (visa == null || th == null || fee == null || visa.value <= 0) {
    return bundled;
  }
  final checked = visa.status == 'updated' || visa.status == 'unchanged';
  final newFee = SourcedFee(
    value: visa.value,
    currency: fee.currency,
    isPercent: fee.isPercent,
    source: fee.source,
    appliesTo: fee.appliesTo,
    checked: checked ? _isoDate(visa.checkedAt) : fee.checked,
  );
  return PayFacts({
    ...bundled.countries,
    'TH': CountryPayFacts(
      country: th.country,
      currency: th.currency,
      foreignCardAtmFee: newFee,
      atmOffersConversion: th.atmOffersConversion,
      atmConversionSource: th.atmConversionSource,
      atmConversionChecked: th.atmConversionChecked,
    ),
  });
}

LiveFact? _last(List<LiveFact> live, String key) {
  LiveFact? found;
  for (final f in live) {
    if (f.key == key) found = f;
  }
  return found;
}

String _isoDate(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-'
    '${t.month.toString().padLeft(2, '0')}-'
    '${t.day.toString().padLeft(2, '0')}';
