// Saved receipt results and what the traveler's own receipt history can
// say later. A record is "verified" only when the arithmetic proved it; a
// figure the user typed in is kept but marked as corrected, never as
// proven. Every statement drawn from history carries how many records it
// used. Pure Dart.
import 'dart:math' as math;

import 'bill_check.dart';

enum SpendCategory { food, transport, shopping, lodging, other }

/// One receipt the traveler kept.
class ReceiptRecord {
  const ReceiptRecord({
    required this.id,
    required this.savedAt,
    required this.totalThb,
    required this.verified,
    this.merchantName,
    this.placeName,
    this.lat,
    this.lng,
    this.kind,
    this.subtotalThb,
    this.discountThb,
    this.serviceThb,
    this.servicePercent,
    this.serviceIncluded = false,
    this.vatThb,
    this.vatOnTop = false,
    this.itemCount,
    this.category = SpendCategory.other,
    this.userCorrected = false,
    this.isSample = false,
  }) : assert(
         !(verified && userCorrected),
         'a corrected record is never verified',
       );

  /// A record of a receipt whose figures [check] proved.
  factory ReceiptRecord.fromCheck(
    BillCheck check, {
    required String id,
    required DateTime savedAt,
    String? merchantName,
    String? placeName,
    double? lat,
    double? lng,
    SpendCategory category = SpendCategory.other,
  }) => ReceiptRecord(
    id: id,
    savedAt: savedAt,
    totalThb: check.total,
    verified: true,
    merchantName: merchantName,
    placeName: placeName,
    lat: lat,
    lng: lng,
    kind: check.kind,
    subtotalThb: check.subtotal,
    discountThb: check.discount,
    serviceThb: check.serviceCharge,
    servicePercent: check.servicePercent,
    serviceIncluded: check.serviceIncluded,
    vatThb: check.vat,
    vatOnTop: check.vatOnTop,
    itemCount: check.itemCount,
    category: category,
  );

  final String id;
  final DateTime savedAt;
  final double totalThb;

  /// True only when built from a [BillCheck]: the arithmetic proved it.
  final bool verified;
  final String? merchantName;
  final String? placeName;
  final double? lat;
  final double? lng;
  final BillKind? kind;
  final double? subtotalThb;
  final double? discountThb;
  final double? serviceThb;
  final double? servicePercent;
  final bool serviceIncluded;
  final double? vatThb;
  final bool vatOnTop;
  final int? itemCount;
  final SpendCategory category;

  /// The traveler changed the verdict by hand.
  final bool userCorrected;
  final bool isSample;

  /// The traveler's fix. The new figures were not proven by arithmetic, so
  /// the copy is no longer [verified].
  ReceiptRecord corrected({
    double? totalThb,
    double? servicePercent,
    bool? serviceIncluded,
    bool? vatOnTop,
  }) => ReceiptRecord(
    id: id,
    savedAt: savedAt,
    totalThb: totalThb ?? this.totalThb,
    verified: false,
    merchantName: merchantName,
    placeName: placeName,
    lat: lat,
    lng: lng,
    kind: kind,
    subtotalThb: subtotalThb,
    discountThb: discountThb,
    // A changed format or total makes the proven amounts stale.
    serviceThb:
        servicePercent == null && serviceIncluded == null && totalThb == null
        ? serviceThb
        : null,
    servicePercent: servicePercent ?? this.servicePercent,
    serviceIncluded: serviceIncluded ?? this.serviceIncluded,
    vatThb: vatOnTop == null && totalThb == null ? vatThb : null,
    vatOnTop: vatOnTop ?? this.vatOnTop,
    itemCount: itemCount,
    category: category,
    userCorrected: true,
    isSample: isSample,
  );

  /// Lower-case letters and digits (Thai and Latin), single spaces.
  String? get merchantKey {
    final name = merchantName;
    if (name == null) return null;
    final key = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9฀-๿]+'), ' ')
        .trim();
    return key.isEmpty ? null : key;
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'savedAt': savedAt.toUtc().toIso8601String(),
    'totalThb': totalThb,
    'verified': verified,
    'merchantName': ?merchantName,
    'placeName': ?placeName,
    'lat': ?lat,
    'lng': ?lng,
    'kind': ?kind?.name,
    'subtotalThb': ?subtotalThb,
    'discountThb': ?discountThb,
    'serviceThb': ?serviceThb,
    'servicePercent': ?servicePercent,
    'serviceIncluded': serviceIncluded,
    'vatThb': ?vatThb,
    'vatOnTop': vatOnTop,
    'itemCount': ?itemCount,
    'category': category.name,
    'userCorrected': userCorrected,
    'isSample': isSample,
  };

  /// Null when [json] lacks an id, a time or a positive total.
  static ReceiptRecord? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final savedAt = json['savedAt'] is String
        ? DateTime.tryParse(json['savedAt'] as String)?.toLocal()
        : null;
    final total = _num(json['totalThb']);
    if (id is! String || id.isEmpty || savedAt == null) return null;
    if (total == null || total <= 0) return null;
    final count = json['itemCount'];
    return ReceiptRecord(
      id: id,
      savedAt: savedAt,
      totalThb: total,
      // A typed-in correction is never proven, whatever was stored.
      verified: json['verified'] == true && json['userCorrected'] != true,
      merchantName: _str(json['merchantName']),
      placeName: _str(json['placeName']),
      lat: _inRange(_num(json['lat']), 90),
      lng: _inRange(_num(json['lng']), 180),
      kind: BillKind.values.asNameMap()[json['kind']],
      subtotalThb: _num(json['subtotalThb']),
      discountThb: _num(json['discountThb']),
      serviceThb: _num(json['serviceThb']),
      servicePercent: _num(json['servicePercent']),
      serviceIncluded: json['serviceIncluded'] == true,
      vatThb: _num(json['vatThb']),
      vatOnTop: json['vatOnTop'] == true,
      itemCount: count is int ? count : null,
      category:
          SpendCategory.values.asNameMap()[json['category']] ??
          SpendCategory.other,
      userCorrected: json['userCorrected'] == true,
      isSample: json['isSample'] == true,
    );
  }
}

const _typeCategories = {
  SpendCategory.food: [
    'restaurant',
    'cafe',
    'bar',
    'bakery',
    'meal_takeaway',
    'food',
  ],
  SpendCategory.transport: [
    'transit_station',
    'train_station',
    'bus_station',
    'subway_station',
    'airport',
    'taxi_stand',
    'gas_station',
  ],
  SpendCategory.lodging: ['lodging', 'hotel'],
  SpendCategory.shopping: [
    'store',
    'shopping_mall',
    'supermarket',
    'convenience_store',
    'grocery_store',
    'department_store',
    'market',
    'pharmacy',
    'drugstore',
  ],
};

const _nameCategories = {
  SpendCategory.shopping: [
    '7-eleven',
    '7 eleven',
    'lotus',
    'big c',
    'makro',
    'tops',
    'family mart',
    'familymart',
    'boots',
    'watsons',
  ],
  SpendCategory.food: [
    'cafe',
    'coffee',
    'restaurant',
    'ร้านอาหาร',
    'กาแฟ',
    'bar',
  ],
  SpendCategory.transport: [
    'grab',
    'bolt',
    'taxi',
    'bts',
    'mrt',
    'airport rail',
  ],
  SpendCategory.lodging: ['hotel', 'hostel', 'guesthouse', 'resort', 'โรงแรม'],
};

/// Spending category from Google place types, else from the merchant name.
SpendCategory categorize({
  List<String> placeTypes = const [],
  String? merchantName,
}) {
  for (final entry in _typeCategories.entries) {
    if (placeTypes.any(entry.value.contains)) return entry.key;
  }
  final name = merchantName?.toLowerCase();
  if (name != null) {
    for (final entry in _nameCategories.entries) {
      if (entry.value.any((w) => _hasWord(name, w))) return entry.key;
    }
  }
  return SpendCategory.other;
}

bool _hasWord(String text, String word) {
  // Thai has no spaces; Latin words must stand alone ("bar" is not "barbecue").
  if (RegExp(r'[฀-๿]').hasMatch(word)) return text.contains(word);
  return RegExp('(?<![a-z])${RegExp.escape(word)}(?![a-z])').hasMatch(text);
}

/// Rows read before the merchant name is given up on.
const merchantSearchRows = 6;

final _documentTitle = RegExp(
  r'receipt|tax invoice|ใบเสร็จ|ใบกำกับ|vat included|\babb\b|cash ?sale|'
  r'customer|บิลเงินสด|ลูกค้า',
  caseSensitive: false,
);

/// The merchant name printed at the top of a receipt, or null.
String? merchantFromRows(List<String> rows) {
  for (final row in rows.take(merchantSearchRows)) {
    final text = row.trim();
    final letters = RegExp(r'[A-Za-z฀-๿]').allMatches(text).length;
    // A brand may carry a digit or two ("7-ELEVEN"); times, phone numbers
    // and IDs carry more.
    if (letters < 3 || RegExp(r'\d').allMatches(text).length > 2) continue;
    if (_documentTitle.hasMatch(text)) continue;
    return text;
  }
  return null;
}

/// What the traveler's earlier receipts at the same merchant say.
class MerchantMemory {
  const MerchantMemory({
    required this.merchantKey,
    required this.visits,
    required this.lastTotalThb,
    required this.lastServicePercent,
    required this.lastServiceIncluded,
    required this.lastVatOnTop,
    required this.correctedRecords,
    required this.sampleRecords,
    required this.lastVerified,
    required this.dates,
  });

  final String merchantKey;
  final int visits;
  final double lastTotalThb;
  final double? lastServicePercent;
  final bool lastServiceIncluded;
  final bool lastVatOnTop;

  /// Records among [visits] whose figures the traveler fixed by hand.
  final int correctedRecords;

  /// Demo sample records among [visits], to be labelled as such.
  final int sampleRecords;

  /// The last visit's figures were proven by arithmetic (not typed in).
  final bool lastVerified;
  final List<DateTime> dates;
}

/// Two receipts closer than this are the same place.
const samePlaceMeters = 100.0;

MerchantMemory? merchantMemory(
  ReceiptRecord current,
  List<ReceiptRecord> history,
  DateTime now,
) {
  final same = _sameMerchant(current, history, now);
  if (same.isEmpty) return null;
  final last = same.first;
  return MerchantMemory(
    merchantKey: current.merchantKey ?? last.merchantKey ?? '',
    visits: same.length,
    lastTotalThb: last.totalThb,
    lastServicePercent: last.servicePercent,
    lastServiceIncluded: last.serviceIncluded,
    lastVatOnTop: last.vatOnTop,
    correctedRecords: same.where((r) => r.userCorrected).length,
    sampleRecords: same.where((r) => r.isSample).length,
    lastVerified: last.verified,
    dates: [for (final r in same) r.savedAt],
  );
}

/// The receipt format the traveler set by hand at this merchant before.
class FormatHint {
  const FormatHint({
    required this.servicePercent,
    required this.serviceIncluded,
    required this.vatOnTop,
    required this.fromRecords,
    required this.lastCorrectedAt,
    required this.fromSample,
  });

  final double? servicePercent;
  final bool serviceIncluded;
  final bool vatOnTop;
  final int fromRecords;
  final DateTime lastCorrectedAt;

  /// The correction is on a demo sample record.
  final bool fromSample;
}

/// The traveler's last correction at this merchant, or null. It is shown
/// as their own note, never used to fill in a figure.
FormatHint? formatHint(
  ReceiptRecord current,
  List<ReceiptRecord> history,
  DateTime now,
) {
  final fixed = _sameMerchant(
    current,
    history,
    now,
  ).where((r) => r.userCorrected).toList();
  if (fixed.isEmpty) return null;
  final last = fixed.first;
  return FormatHint(
    servicePercent: last.servicePercent,
    serviceIncluded: last.serviceIncluded,
    vatOnTop: last.vatOnTop,
    fromRecords: fixed.length,
    lastCorrectedAt: last.savedAt,
    fromSample: last.isSample,
  );
}

class CategorySpend {
  const CategorySpend({
    required this.category,
    required this.totalThb,
    required this.records,
    required this.sampleRecords,
  });

  final SpendCategory category;
  final double totalThb;
  final int records;

  /// Demo sample receipts among [records].
  final int sampleRecords;
}

/// Receipt totals per category over the last [days] calendar days (today
/// is day 1), largest first.
List<CategorySpend> spendByCategory(
  List<ReceiptRecord> history,
  DateTime now, {
  int days = 7,
}) {
  final first = _dayOf(now).subtract(Duration(days: days - 1));
  final totals = <SpendCategory, double>{};
  final counts = <SpendCategory, int>{};
  final samples = <SpendCategory, int>{};
  for (final r in history) {
    if (!r.savedAt.isBefore(now) || _dayOf(r.savedAt).isBefore(first)) {
      continue;
    }
    totals[r.category] = (totals[r.category] ?? 0) + r.totalThb;
    counts[r.category] = (counts[r.category] ?? 0) + 1;
    if (r.isSample) samples[r.category] = (samples[r.category] ?? 0) + 1;
  }
  return [
    for (final c in totals.keys)
      CategorySpend(
        category: c,
        totalThb: (totals[c]! * 100).round() / 100,
        records: counts[c]!,
        sampleRecords: samples[c] ?? 0,
      ),
  ]..sort((a, b) => b.totalThb.compareTo(a.totalThb));
}

/// A day's receipt spending, estimated from the traveler's past days.
class DailySpend {
  const DailySpend({
    required this.medianThb,
    required this.daysUsed,
    required this.sampleRecords,
    required this.days,
  });

  final double medianThb;
  final int daysUsed;

  /// Demo sample receipts on the days used.
  final int sampleRecords;
  final List<DateTime> days;

  bool get isEstimate => true;
}

/// Days of receipts the daily estimate looks back over.
const dailySpendDays = 7;

/// Median per-day receipt total over the last [dailySpendDays] earlier
/// days with receipts, rounded up to 100 baht. Needs two such days.
DailySpend? dailySpend(List<ReceiptRecord> history, DateTime now) {
  final today = _dayOf(now);
  final byDay = <DateTime, double>{};
  final samplesByDay = <DateTime, int>{};
  for (final r in history) {
    final day = _dayOf(r.savedAt);
    if (!day.isBefore(today)) continue;
    byDay[day] = (byDay[day] ?? 0) + r.totalThb;
    if (r.isSample) samplesByDay[day] = (samplesByDay[day] ?? 0) + 1;
  }
  final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
  final recent = days.take(dailySpendDays).toList();
  if (recent.length < 2) return null;
  final values = [for (final d in recent) byDay[d]!]..sort();
  final mid = values.length ~/ 2;
  final median = values.length.isOdd
      ? values[mid]
      : (values[mid - 1] + values[mid]) / 2;
  return DailySpend(
    medianThb: (median / 100).ceil() * 100.0,
    daysUsed: recent.length,
    sampleRecords: recent.fold(0, (n, d) => n + (samplesByDay[d] ?? 0)),
    days: recent,
  );
}

/// Earlier receipts at the same merchant as [current] (same name key, or
/// within [samePlaceMeters]), newest first.
List<ReceiptRecord> _sameMerchant(
  ReceiptRecord current,
  List<ReceiptRecord> history,
  DateTime now,
) {
  final key = current.merchantKey;
  return [
    for (final r in history)
      if (r.id != current.id &&
          r.savedAt.isBefore(now) &&
          ((key != null && r.merchantKey == key) || _near(current, r)))
        r,
  ]..sort((a, b) => b.savedAt.compareTo(a.savedAt));
}

bool _near(ReceiptRecord a, ReceiptRecord b) {
  final (lat1, lng1, lat2, lng2) = (a.lat, a.lng, b.lat, b.lng);
  if (lat1 == null || lng1 == null || lat2 == null || lng2 == null) {
    return false;
  }
  const earth = 6371000.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * earth * math.asin(math.sqrt(h)) <= samePlaceMeters;
}

/// Calendar day as a UTC date, so day counts stay whole across DST.
DateTime _dayOf(DateTime t) => DateTime.utc(t.year, t.month, t.day);

double? _num(Object? v) {
  final d = switch (v) {
    final num n => n.toDouble(),
    final String s => double.tryParse(s),
    _ => null,
  };
  return d != null && d.isFinite ? d : null;
}

double? _inRange(double? v, double limit) =>
    v != null && v.abs() <= limit ? v : null;

String? _str(Object? v) => v is String && v.isNotEmpty ? v : null;
