/// Converts saved results between the app ([TripSave]) and rows of
/// `public.trip_records`. Pure Dart.
library;

import '../../rules/trip_ledger.dart';

/// The row to upsert for [save]. `user_id` is left to the database default
/// (`auth.uid()`), so a client can never write a row for someone else.
Map<String, Object?> tripSaveToRow(
  TripSave save, {
  Map<String, Object?> detail = const {},
  RecordContext? context,
}) => {
  if (save.placeName != null) 'place_name': save.placeName,
  ...?context?.toRow(),
  'client_id': save.id,
  'kind': save.kind.name,
  'kept_thb': save.keptThb,
  'saved_at': save.savedAt.toUtc().toIso8601String(),
  'item_key': save.itemKey,
  'asked_thb': save.askedThb,
  'paid_thb': save.paidThb,
  'detail': {
    ...detail,
    if (save.sellerPrices != null) 'sellerPrices': save.sellerPrices,
    if (save.ourOffers != null) 'ourOffers': save.ourOffers,
  },
};

/// Null when [row] cannot be read as a save.
TripSave? tripSaveFromRow(Object? row) {
  if (row is! Map) return null;
  final id = row['client_id'];
  final kind = SaveKind.values.asNameMap()[row['kind']];
  final kept = _number(row['kept_thb']);
  final savedAtRaw = row['saved_at'];
  final savedAt = savedAtRaw is String ? DateTime.tryParse(savedAtRaw) : null;
  if (id is! String || id.isEmpty || kind == null) return null;
  if (kept == null || kept < 0 || savedAt == null) return null;
  final itemKey = row['item_key'];
  final placeName = row['place_name'];
  final detail = row['detail'];
  return TripSave(
    id: id,
    kind: kind,
    keptThb: kept,
    savedAt: savedAt,
    itemKey: itemKey is String && itemKey.isNotEmpty ? itemKey : null,
    askedThb: _number(row['asked_thb']),
    paidThb: _number(row['paid_thb']),
    placeName: placeName is String && placeName.isNotEmpty ? placeName : null,
    sellerPrices: detail is Map ? _numbers(detail['sellerPrices']) : null,
    ourOffers: detail is Map ? _numbers(detail['ourOffers']) : null,
  );
}

/// A list of amounts, or null when [value] is not one.
List<double>? _numbers(Object? value) {
  if (value is! List) return null;
  final out = [for (final v in value) ?_number(v)];
  return out.length == value.length ? out : null;
}

/// Every readable save in [rows], newest first.
List<TripSave> tripSavesFromRows(Object? rows) {
  if (rows is! List) return const [];
  return newestFirst([for (final r in rows) ?tripSaveFromRow(r)]);
}

/// PostgREST returns `numeric` as a JSON number, or as a string when the
/// value does not fit a double exactly; accept both.
double? _number(Object? value) {
  final double? v = switch (value) {
    num n => n.toDouble(),
    String s => double.tryParse(s.trim()),
    _ => null,
  };
  return v != null && v.isFinite ? v : null;
}

/// Where and how a saved result happened, for the assistant's memory.
class RecordContext {
  const RecordContext({
    this.placeName,
    this.placeLat,
    this.placeLng,
    this.verdict,
    this.aiPath,
  }) : assert((placeLat == null) == (placeLng == null));

  final String? placeName;
  final double? placeLat;
  final double? placeLng;

  /// The verdict's own word, e.g. 'high', 'fair', 'payLocal'.
  final String? verdict;

  /// Which engines produced the result, e.g. 'mlkit_ocr'.
  final String? aiPath;

  Map<String, Object?> toRow() => {
    'place_name': placeName,
    'place_lat': placeLat,
    'place_lng': placeLng,
    'verdict': verdict,
    'ai_path': aiPath,
  };
}

enum HaggleOutcome {
  countered('countered'),
  accepted('accepted'),
  declined('declined'),
  walkedAway('walked_away');

  const HaggleOutcome(this.dbValue);

  final String dbValue;
}

/// One exchange in a haggle (`public.haggle_rounds`). Speech is kept as
/// recognised text only.
class HaggleRound {
  const HaggleRound({
    required this.haggleId,
    required this.roundNo,
    this.itemKey,
    this.sellerSaid,
    this.sellerPriceThb,
    this.ourOfferThb,
    this.ourSentence,
    this.outcome,
  });

  /// The app's id for the whole haggle; groups its rounds.
  final String haggleId;

  /// 1 for the first exchange.
  final int roundNo;
  final String? itemKey;
  final String? sellerSaid;
  final double? sellerPriceThb;
  final double? ourOfferThb;
  final String? ourSentence;
  final HaggleOutcome? outcome;

  Map<String, Object?> toRow({String? recordId}) => {
    'haggle_id': haggleId,
    'round_no': roundNo,
    'record_id': recordId,
    'item_key': itemKey,
    'seller_said': sellerSaid,
    'seller_price_thb': sellerPriceThb,
    'our_offer_thb': ourOfferThb,
    'our_sentence': ourSentence,
    'outcome': outcome?.dbValue,
  };
}
