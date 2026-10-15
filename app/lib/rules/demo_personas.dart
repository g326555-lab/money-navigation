import 'dart:convert';

import 'atm_conversion.dart';
import 'bill_check.dart' show BillKind;
import 'cash_wallet.dart';
import 'haggle.dart' show marketCurrency;
import 'receipt_record.dart';
import 'trip_ledger.dart';

/// The demo file: the two prepared states of the demo switch and their
/// sample records. The only place sample records live.
const demoPersonasAsset = 'assets/data/demo_personas.json';

/// One prepared demo state: who the traveler is, the language the app
/// speaks, the currencies, and the sample records that come with it.
class DemoPersona {
  const DemoPersona._({
    required this.key,
    required this.language,
    required this.homeCurrency,
    required this.localCurrency,
    required this._samples,
    required this._receipts,
    required this._cashMovements,
  });

  /// 'visitorBangkok' or 'thaiTokyo'; also names the persona in l10n.
  final String key;

  /// App language code, 'en' or 'th'.
  final String language;

  /// The currency the traveler thinks in.
  final String homeCurrency;

  /// The currency of the country being visited.
  final String localCurrency;
  final List<_Sample> _samples;
  final List<_Receipt> _receipts;
  final List<_CashMovement> _cashMovements;

  /// The sample cash ledger, computed from the sample records the same way
  /// the app links a traveler's own: an ATM sample adds the amount its
  /// screen says was taken out, a haggle or receipt paid in cash subtracts
  /// what was paid, a card payment leaves cash alone. Cash activity with no
  /// record of its own (an exchange counter) comes from the file as is.
  /// Kept apart from the traveler's real wallet.
  List<CashMovement> cashMovementsAt(DateTime now) => [
    for (final (i, s) in _samples.indexed) ?s.toCash('demo-$key-$i', now),
    for (final (i, r) in _receipts.indexed)
      ?r.toCash('demo-$key-receipt-$i', now),
    for (final (i, m) in _cashMovements.indexed)
      m.toMovement('demo-$key-cash-$i', now),
  ]..sort((a, b) => b.at.compareTo(a.at));

  /// The sample receipts dated relative to [now], newest first, each marked
  /// [ReceiptRecord.isSample]. Their figures were checked when the file was
  /// read.
  List<ReceiptRecord> receiptsAt(DateTime now) {
    final out = [
      for (final (i, r) in _receipts.indexed)
        r.toRecord('demo-$key-receipt-$i', now),
    ]..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return out;
  }

  /// The sample records dated relative to [now], newest first, each marked
  /// [TripSave.isSample].
  List<TripSave> samplesAt(DateTime now) => newestFirst([
    for (final (i, s) in _samples.indexed) s.toSave('demo-$key-$i', now),
  ]);
}

/// Both prepared states.
class DemoPersonas {
  const DemoPersonas._(this.personas);

  final List<DemoPersona> personas;

  DemoPersona? byKey(String key) {
    for (final p in personas) {
      if (p.key == key) return p;
    }
    return null;
  }

  /// The persona the switch swaps [persona] for.
  DemoPersona other(DemoPersona persona) {
    final i = personas.indexWhere((p) => p.key == persona.key);
    return personas[(i + 1) % personas.length];
  }
}

class _Sample {
  const _Sample({
    required this.kind,
    required this.daysAgo,
    required this.hour,
    required this.minute,
    this.keptThb,
    this.itemKey,
    this.askedThb,
    this.paidThb,
    this.placeName,
    this.placeLat,
    this.placeLng,
    this.screen,
    this.paidCash = false,
  });

  final SaveKind kind;
  final int daysAgo;
  final int hour;
  final int minute;
  final double? keptThb;
  final String? itemKey;
  final double? askedThb;
  final double? paidThb;
  final String? placeName;
  final double? placeLat;
  final double? placeLng;

  /// What an ATM sample's screen showed, as a live scan would keep it.
  final Map<String, Object>? screen;

  /// A haggle paid in cash ('paidWith': 'cash').
  final bool paidCash;

  DateTime _at(DateTime now) =>
      DateTime(now.year, now.month, now.day - daysAgo, hour, minute);

  /// This sample's effect on cash: an ATM withdrawal adds what was taken
  /// out, a haggle paid in cash takes away what was paid.
  CashMovement? toCash(String id, DateTime now) {
    final withdrawal = screen?[AtmFigures.withdrawalThb];
    if (kind == SaveKind.atmConversion && withdrawal is double) {
      return CashMovement(
        id: 'cash-$id',
        kind: CashMovementKind.withdrawal,
        amount: withdrawal,
        currency: atmLocalCurrency,
        at: _at(now),
        description: placeName,
        sourceId: id,
      );
    }
    if (kind == SaveKind.haggle && paidCash) {
      return CashMovement(
        id: 'cash-spend-$id',
        kind: CashMovementKind.cashSpend,
        amount: paidThb!,
        currency: marketCurrency,
        at: _at(now),
        description: placeName,
        sourceId: id,
      );
    }
    return null;
  }

  TripSave toSave(String id, DateTime now) {
    final at = _at(now);
    final haggle = kind == SaveKind.haggle;
    return TripSave(
      id: id,
      kind: kind,
      keptThb: haggle
          ? haggleKeptThb(askedThb: askedThb!, paidThb: paidThb!)
          : keptThb!,
      savedAt: at,
      itemKey: itemKey,
      askedThb: askedThb,
      paidThb: paidThb,
      placeName: placeName,
      placeLat: placeLat,
      placeLng: placeLng,
      screen: screen,
      isSample: true,
    );
  }
}

/// Parses the demo file. Null when anything is missing or malformed; it
/// never fills in a value.
DemoPersonas? parseDemoPersonas(String json) {
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException {
    return null;
  }
  if (decoded is! Map || decoded['personas'] is! List) return null;
  final personas = <DemoPersona>[];
  for (final entry in decoded['personas'] as List) {
    final persona = _persona(entry);
    if (persona == null) return null;
    if (personas.any((p) => p.key == persona.key)) return null;
    personas.add(persona);
  }
  if (personas.length < 2) return null;
  return DemoPersonas._(List.unmodifiable(personas));
}

final _currency = RegExp(r'^[A-Z]{3}$');
final _time = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');

DemoPersona? _persona(Object? entry) {
  if (entry is! Map) return null;
  final key = entry['key'];
  final language = entry['language'];
  final home = entry['homeCurrency'];
  final local = entry['localCurrency'];
  final samples = entry['samples'];
  if (key is! String || key.isEmpty) return null;
  if (language is! String || !const {'en', 'th'}.contains(language)) {
    return null;
  }
  if (home is! String || !_currency.hasMatch(home)) return null;
  if (local is! String || !_currency.hasMatch(local)) return null;
  if (samples is! List) return null;
  final parsed = <_Sample>[];
  for (final s in samples) {
    final sample = _sample(s);
    if (sample == null) return null;
    parsed.add(sample);
  }
  final receipts = entry['receipts'] ?? const [];
  if (receipts is! List) return null;
  final parsedReceipts = <_Receipt>[];
  for (final r in receipts) {
    final receipt = _receipt(r);
    if (receipt == null) return null;
    parsedReceipts.add(receipt);
  }
  final rawCashMovements = entry['cashMovements'] ?? const [];
  if (rawCashMovements is! List) return null;
  final cashMovements = <_CashMovement>[];
  for (final movement in rawCashMovements) {
    final parsedMovement = _cashMovement(movement);
    if (parsedMovement == null) return null;
    cashMovements.add(parsedMovement);
  }
  return DemoPersona._(
    key: key,
    language: language,
    homeCurrency: home,
    localCurrency: local,
    samples: parsed,
    receipts: parsedReceipts,
    cashMovements: cashMovements,
  );
}

class _CashMovement {
  const _CashMovement({
    required this.kind,
    required this.amount,
    required this.currency,
    required this.daysAgo,
    required this.hour,
    required this.minute,
    required this.description,
    this.sourceId,
  });

  final CashMovementKind kind;
  final double amount;
  final String currency;
  final int daysAgo;
  final int hour;
  final int minute;
  final String description;
  final String? sourceId;

  CashMovement toMovement(String id, DateTime now) => CashMovement(
    id: id,
    kind: kind,
    amount: amount,
    currency: currency,
    at: DateTime(now.year, now.month, now.day - daysAgo, hour, minute),
    description: description,
    sourceId: sourceId,
  );
}

_CashMovement? _cashMovement(Object? value) {
  if (value is! Map) return null;
  final kind = CashMovementKind.values.asNameMap()[value['kind']];
  final amount = _number(value['amount']);
  final currency = value['currency'];
  final daysAgo = value['daysAgo'];
  final time = value['time'];
  final hm = time is String ? _time.firstMatch(time) : null;
  final description = value['description'];
  final sourceId = value['sourceId'];
  if (kind == null ||
      amount == null ||
      amount <= 0 ||
      currency is! String ||
      !_currency.hasMatch(currency) ||
      daysAgo is! int ||
      daysAgo < 0 ||
      hm == null ||
      description is! String ||
      description.isEmpty ||
      (sourceId != null && sourceId is! String)) {
    return null;
  }
  return _CashMovement(
    kind: kind,
    amount: amount,
    currency: currency,
    daysAgo: daysAgo,
    hour: int.parse(hm.group(1)!),
    minute: int.parse(hm.group(2)!),
    description: description,
    sourceId: sourceId as String?,
  );
}

_Sample? _sample(Object? entry) {
  if (entry is! Map) return null;
  final kind = SaveKind.values.asNameMap()[entry['kind']];
  final daysAgo = entry['daysAgo'];
  final time = entry['time'];
  if (kind == null || daysAgo is! int || daysAgo < 0) return null;
  final hm = time is String ? _time.firstMatch(time) : null;
  if (hm == null) return null;
  final place = entry['placeName'];
  if (place != null && (place is! String || place.isEmpty)) return null;
  // A map position is optional but comes as a pair, in range.
  final lat = entry['placeLat'];
  final lng = entry['placeLng'];
  if ((lat == null) != (lng == null)) return null;
  if (lat != null && (lat is! num || lat < -90 || lat > 90)) return null;
  if (lng != null && (lng is! num || lng < -180 || lng > 180)) return null;
  final common = (
    hour: int.parse(hm.group(1)!),
    minute: int.parse(hm.group(2)!),
    place: place as String?,
    lat: (lat as num?)?.toDouble(),
    lng: (lng as num?)?.toDouble(),
  );
  if (kind == SaveKind.haggle) {
    final item = entry['itemKey'];
    final asked = _number(entry['askedThb']);
    final paid = _number(entry['paidThb']);
    if (item is! String || item.isEmpty) return null;
    if (asked == null || paid == null || asked <= 0) return null;
    if (paid <= 0 || paid > asked) return null;
    final paidWith = _paidWith(entry['paidWith']);
    if (paidWith == null) return null;
    return _Sample(
      kind: kind,
      daysAgo: daysAgo,
      hour: common.hour,
      minute: common.minute,
      itemKey: item,
      askedThb: asked,
      paidThb: paid,
      placeName: common.place,
      placeLat: common.lat,
      placeLng: common.lng,
      paidCash: paidWith == _PaidWith.cash,
    );
  }
  // An ATM sample states what its screen showed; what declining the
  // conversion kept comes from the same rule as a live ATM scan.
  final double? kept;
  Map<String, Object>? screen;
  if (kind == SaveKind.atmConversion && entry['atm'] != null) {
    final atm = _atmSample(entry['atm']);
    kept = atm == null ? null : (atm.verdict.extraCostThb * 100).round() / 100;
    screen = atm == null ? null : atmFigures(atm.reading, atm.verdict);
  } else {
    kept = _number(entry['keptThb']);
  }
  if (kept == null || kept < 0) return null;
  return _Sample(
    kind: kind,
    daysAgo: daysAgo,
    hour: common.hour,
    minute: common.minute,
    keptThb: kept,
    screen: screen,
    placeName: common.place,
    placeLat: common.lat,
    placeLng: common.lng,
  );
}

({AtmScreenReading reading, AtmVerdict verdict})? _atmSample(Object? atm) {
  if (atm is! Map) return null;
  final withdrawal = _number(atm['withdrawalThb']);
  final fee = _number(atm['accessFeeThb']);
  final rate = _number(atm['thbPerUsd']);
  final charged = _number(atm['chargedThb']);
  final usd = _number(atm['chargedUsd']);
  if ([withdrawal, fee, rate, charged, usd].contains(null)) return null;
  if (rate! <= 0 || (withdrawal! + fee! - charged!).abs() > 0.005) return null;
  final reading = AtmScreenReading(
    withdrawalThb: withdrawal,
    accessFeeThb: fee,
    thbPerUsd: rate,
    markupPercent: _number(atm['markupPercent']),
    chargedThb: charged,
    chargedUsd: usd!,
  );
  final verdict = evaluateAtm(reading);
  if (verdict.recommended != AtmChoice.declineConversion) return null;
  return (reading: reading, verdict: verdict);
}

enum _PaidWith { cash, card }

_PaidWith? _paidWith(Object? value) =>
    value is String ? _PaidWith.values.asNameMap()[value] : null;

/// A sample receipt: only figures that add up the way a checked receipt
/// does are accepted.
class _Receipt {
  const _Receipt(
    this.daysAgo,
    this.hour,
    this.minute,
    this.fields, {
    required this.paidCash,
  });

  final int daysAgo;
  final int hour;
  final int minute;
  final Map<String, Object?> fields;

  /// Paid in cash ('paidWith': 'cash'); a card payment leaves cash alone.
  final bool paidCash;

  CashMovement? toCash(String id, DateTime now) => !paidCash
      ? null
      : CashMovement(
          id: 'cash-spend-$id',
          kind: CashMovementKind.cashSpend,
          amount: (fields['totalThb']! as num).toDouble(),
          currency: marketCurrency,
          at: DateTime(now.year, now.month, now.day - daysAgo, hour, minute),
          description: fields['merchantName'] as String?,
          sourceId: id,
        );

  ReceiptRecord toRecord(String id, DateTime now) => ReceiptRecord.fromJson({
    ...fields,
    'id': id,
    'savedAt': DateTime(
      now.year,
      now.month,
      now.day - daysAgo,
      hour,
      minute,
    ).toIso8601String(),
    'verified': true,
    'userCorrected': false,
    'isSample': true,
  })!;
}

/// VAT inside a total: total * 7 / 107, to the satang.
const _vatRate = 7.0;

_Receipt? _receipt(Object? entry) {
  if (entry is! Map) return null;
  final daysAgo = entry['daysAgo'];
  final time = entry['time'];
  if (daysAgo is! int || daysAgo < 0) return null;
  final hm = time is String ? _time.firstMatch(time) : null;
  if (hm == null) return null;
  final merchant = entry['merchantName'];
  final place = entry['placeName'];
  if (merchant is! String || merchant.isEmpty) return null;
  if (place is! String || place.isEmpty) return null;
  final lat = _number(entry['lat']);
  final lng = _number(entry['lng']);
  if (lat == null || lng == null || lat.abs() > 90 || lng.abs() > 180) {
    return null;
  }
  final kind = BillKind.values.asNameMap()[entry['kind']];
  final total = _number(entry['totalThb']);
  final subtotal = _number(entry['subtotalThb']);
  if (kind == null || total == null || subtotal == null || total <= 0) {
    return null;
  }
  if (SpendCategory.values.asNameMap()[entry['category']] == null) {
    return null;
  }
  final discount = _number(entry['discountThb']) ?? 0;
  final service = _number(entry['serviceThb']);
  final percent = _number(entry['servicePercent']);
  final vat = _number(entry['vatThb']);
  bool near(double a, double b) => (a - b).abs() < 0.005;
  final net = subtotal - discount;
  final adds = switch (kind) {
    BillKind.itemsOnly => near(net, total) && service == null && vat == null,
    BillKind.serviceCharge =>
      service != null &&
          percent != null &&
          near((net * percent).round() / 100, service) &&
          near(net + service, total) &&
          (vat == null ||
              near(
                (total * _vatRate / (100 + _vatRate) * 100).round() / 100,
                vat,
              )),
    BillKind.vatOnTop =>
      vat != null &&
          near((net * _vatRate).round() / 100, vat) &&
          near(net + vat, total),
    BillKind.vatIncluded =>
      vat != null &&
          near(net, total) &&
          near((total * _vatRate / (100 + _vatRate) * 100).round() / 100, vat),
  };
  if (!adds) return null;
  final paidWith = _paidWith(entry['paidWith']);
  if (paidWith == null) return null;
  return _Receipt(daysAgo, int.parse(hm.group(1)!), int.parse(hm.group(2)!), {
    for (final k in const [
      'merchantName',
      'placeName',
      'lat',
      'lng',
      'kind',
      'subtotalThb',
      'discountThb',
      'serviceThb',
      'servicePercent',
      'vatThb',
      'totalThb',
      'itemCount',
      'category',
    ])
      if (entry[k] != null) k: entry[k],
    'vatOnTop': kind == BillKind.vatOnTop,
  }, paidCash: paidWith == _PaidWith.cash);
}

double? _number(Object? value) {
  if (value is! num) return null;
  final v = value.toDouble();
  return v.isFinite ? v : null;
}
