import 'dart:convert';

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

  TripSave toSave(String id, DateTime now) {
    final at = DateTime(now.year, now.month, now.day - daysAgo, hour, minute);
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
  return DemoPersona._(
    key: key,
    language: language,
    homeCurrency: home,
    localCurrency: local,
    samples: parsed,
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
  final common = (
    hour: int.parse(hm.group(1)!),
    minute: int.parse(hm.group(2)!),
    place: place as String?,
  );
  if (kind == SaveKind.haggle) {
    final item = entry['itemKey'];
    final asked = _number(entry['askedThb']);
    final paid = _number(entry['paidThb']);
    if (item is! String || item.isEmpty) return null;
    if (asked == null || paid == null || asked <= 0) return null;
    if (paid <= 0 || paid > asked) return null;
    return _Sample(
      kind: kind,
      daysAgo: daysAgo,
      hour: common.hour,
      minute: common.minute,
      itemKey: item,
      askedThb: asked,
      paidThb: paid,
      placeName: common.place,
    );
  }
  final kept = _number(entry['keptThb']);
  if (kept == null || kept < 0) return null;
  return _Sample(
    kind: kind,
    daysAgo: daysAgo,
    hour: common.hour,
    minute: common.minute,
    keptThb: kept,
    placeName: common.place,
  );
}

double? _number(Object? value) {
  if (value is! num) return null;
  final v = value.toDouble();
  return v.isFinite ? v : null;
}
