import 'dart:convert';

import 'atm_conversion.dart';
import 'personal_context.dart';
import 'terminal_dcc.dart';

/// What kind of result a save came from.
enum SaveKind {
  atmConversion,
  haggle,

  /// Part B: paying in the local currency instead of the card terminal's
  /// home-currency offer.
  terminalDcc,
}

/// One result the traveler kept on this trip.
class TripSave {
  const TripSave({
    required this.id,
    required this.kind,
    required this.keptThb,
    required this.savedAt,
    this.itemKey,
    this.askedThb,
    this.paidThb,
    this.placeName,
    this.placeLat,
    this.placeLng,
    this.sellerPrices,
    this.ourOffers,
    this.isSample = false,
  });

  final String id;
  final SaveKind kind;

  /// Money kept, in baht. Never negative.
  final double keptThb;
  final DateTime savedAt;

  /// Haggle only: the market item's key, e.g. 'mango'.
  final String? itemKey;

  /// Haggle only: what the seller asked.
  final double? askedThb;

  /// Haggle only: what the traveler paid.
  final double? paidThb;

  /// Haggle only: the market it happened at, from Google Maps, when known.
  final String? placeName;

  /// Where it happened, when the phone knew (both or neither).
  final double? placeLat;
  final double? placeLng;

  /// Haggle only: every price the seller said, first ask first, and every
  /// price we offered, so a later verdict can learn from the exchange.
  final List<double>? sellerPrices;
  final List<double>? ourOffers;

  /// A sample record of the demo state (assets/data/demo_personas.json),
  /// never one the traveler made. Shown as a sample.
  final bool isSample;

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'keptThb': keptThb,
    'savedAt': savedAt.toUtc().toIso8601String(),
    if (itemKey != null) 'itemKey': itemKey,
    if (askedThb != null) 'askedThb': askedThb,
    if (paidThb != null) 'paidThb': paidThb,
    if (placeName != null) 'placeName': placeName,
    if (placeLat != null && placeLng != null) ...{
      'placeLat': placeLat,
      'placeLng': placeLng,
    },
    if (sellerPrices != null) 'sellerPrices': sellerPrices,
    if (ourOffers != null) 'ourOffers': ourOffers,
    if (isSample) 'isSample': true,
  };

  /// Null when [json] is not a well-formed save.
  static TripSave? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final kind = SaveKind.values.asNameMap()[json['kind']];
    final kept = _number(json['keptThb']);
    final savedAt = json['savedAt'] is String
        ? DateTime.tryParse(json['savedAt'] as String)
        : null;
    if (id is! String || id.isEmpty || kind == null) return null;
    if (kept == null || kept < 0 || savedAt == null) return null;
    final itemKey = json['itemKey'];
    final lat = _number(json['placeLat']);
    final lng = _number(json['placeLng']);
    return TripSave(
      id: id,
      kind: kind,
      keptThb: kept,
      savedAt: savedAt,
      itemKey: itemKey is String ? itemKey : null,
      askedThb: _number(json['askedThb']),
      paidThb: _number(json['paidThb']),
      placeName: json['placeName'] is String
          ? json['placeName'] as String
          : null,
      sellerPrices: _numbers(json['sellerPrices']),
      ourOffers: _numbers(json['ourOffers']),
      placeLat: lat != null && lng != null ? lat : null,
      placeLng: lat != null && lng != null ? lng : null,
      isSample: json['isSample'] == true,
    );
  }
}

double? _number(Object? value) {
  if (value is! num) return null;
  final v = value.toDouble();
  return v.isFinite ? v : null;
}

List<double>? _numbers(Object? value) {
  if (value is! List) return null;
  final out = [for (final v in value) ?_number(v)];
  return out.length == value.length ? out : null;
}

double keptTotalThb(Iterable<TripSave> saves) =>
    saves.fold(0, (sum, s) => sum + s.keptThb);

Map<SaveKind, double> keptByKind(Iterable<TripSave> saves) {
  final totals = <SaveKind, double>{};
  for (final s in saves) {
    totals[s.kind] = (totals[s.kind] ?? 0) + s.keptThb;
  }
  return totals;
}

/// The finished haggles among [saves], as the evidence the traveler's own
/// records give a verdict (lib/rules/personal_context.dart).
List<PastPurchase> pastPurchasesFromSaves(Iterable<TripSave> saves) => [
  for (final s in saves)
    if (s.kind == SaveKind.haggle &&
        s.itemKey != null &&
        s.paidThb != null &&
        s.paidThb! > 0)
      PastPurchase(
        itemKey: s.itemKey!,
        paidThb: s.paidThb!,
        askedThb: s.askedThb,
        placeName: s.placeName,
        // Day counts are calendar days where the traveler is.
        at: s.savedAt.toLocal(),
        isSample: s.isSample,
      ),
];

List<TripSave> newestFirst(Iterable<TripSave> saves) =>
    saves.toList()..sort((a, b) => b.savedAt.compareTo(a.savedAt));

double haggleKeptThb({required double askedThb, required double paidThb}) {
  final kept = askedThb - paidThb;
  return kept > 0 ? kept : 0;
}

/// The extra conversion cost the traveler avoided. Null when nothing was kept.
TripSave? saveFromAtm(
  AtmVerdict verdict, {
  required String id,
  required DateTime savedAt,
}) {
  if (verdict.extraCostThb <= 0) return null;
  return TripSave(
    id: id,
    kind: SaveKind.atmConversion,
    keptThb: verdict.extraCostThb,
    savedAt: savedAt,
  );
}

/// What paying in the local currency at a card terminal kept, in the
/// traveler's home currency (THB for Part B). Null when the home-currency
/// option was not the dearer one.
TripSave? saveFromDcc(
  DccVerdict verdict, {
  required String id,
  required DateTime savedAt,
}) {
  if (!verdict.payLocal || verdict.extraHome <= 0) return null;
  return TripSave(
    id: id,
    kind: SaveKind.terminalDcc,
    keptThb: verdict.extraHome,
    savedAt: savedAt,
  );
}

/// What haggling kept. Null when the paid price makes no sense.
TripSave? saveFromHaggle({
  required String id,
  required DateTime savedAt,
  required String itemKey,
  required double askedThb,
  required double paidThb,
  String? placeName,
  double? placeLat,
  double? placeLng,
  List<double>? sellerPrices,
  List<double>? ourOffers,
}) {
  if (paidThb <= 0 || paidThb > askedThb) return null;
  return TripSave(
    id: id,
    kind: SaveKind.haggle,
    keptThb: haggleKeptThb(askedThb: askedThb, paidThb: paidThb),
    savedAt: savedAt,
    itemKey: itemKey,
    askedThb: askedThb,
    paidThb: paidThb,
    placeName: placeName,
    placeLat: placeLat != null && placeLng != null ? placeLat : null,
    placeLng: placeLat != null && placeLng != null ? placeLng : null,
    sellerPrices: sellerPrices,
    ourOffers: ourOffers,
  );
}

String encodeSaves(List<TripSave> saves) =>
    jsonEncode([for (final s in saves) s.toJson()]);

/// Keeps every valid save; skips entries that cannot be read.
List<TripSave> decodeSaves(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    return const [];
  }
  if (decoded is! List) return const [];
  return [for (final entry in decoded) ?TripSave.fromJson(entry)];
}
