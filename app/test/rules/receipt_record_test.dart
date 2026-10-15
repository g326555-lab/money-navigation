import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/bill_check.dart';
import 'package:money_navigation/rules/ocr_layout.dart';
import 'package:money_navigation/rules/receipt_record.dart';

/// One OCR line per printed line, stacked top to bottom.
List<OcrLine> _ocrLines(List<String> printed) => [
  for (var i = 0; i < printed.length; i++)
    OcrLine(
      text: printed[i],
      left: 0,
      top: i * 40.0,
      right: 20.0 * printed[i].length,
      bottom: i * 40.0 + 30,
    ),
];

// Bangkok, Sukhumvit area. 0.00045 deg of latitude is about 50 m,
// 0.0027 deg about 300 m.
const double _lat = 13.7400;
const double _lng = 100.5550;
const double _lat50m = _lat + 0.00045;
const double _lat300m = _lat + 0.0027;

final DateTime _now = DateTime(2026, 10, 15, 18, 0);

ReceiptRecord _rec(
  String id,
  DateTime savedAt,
  double total, {
  String? merchant,
  double? lat,
  double? lng,
  SpendCategory category = SpendCategory.other,
  bool verified = true,
  bool userCorrected = false,
  double? servicePercent,
  bool serviceIncluded = false,
  bool vatOnTop = false,
}) => ReceiptRecord(
  id: id,
  savedAt: savedAt,
  totalThb: total,
  verified: verified,
  merchantName: merchant,
  lat: lat,
  lng: lng,
  category: category,
  userCorrected: userCorrected,
  servicePercent: servicePercent,
  serviceIncluded: serviceIncluded,
  vatOnTop: vatOnTop,
);

DateTime _daysAgo(int days, {int hour = 12, int minute = 0}) =>
    DateTime(_now.year, _now.month, _now.day - days, hour, minute);

void main() {
  group('ReceiptRecord.fromCheck', () {
    test('items-only bill from checkBill is verified and copies figures', () {
      final check = checkBill(
        _ocrLines(['Pad thai 60.00', 'Iced tea 25.00', 'Total 85.00']),
      );
      expect(check, isNotNull);
      final saved = DateTime(2026, 10, 14, 12, 30);
      final r = ReceiptRecord.fromCheck(
        check!,
        id: 'r1',
        savedAt: saved,
        merchantName: 'Ta Kri Rest.',
        placeName: 'Ta Kri',
        lat: _lat,
        lng: _lng,
        category: SpendCategory.food,
      );
      expect(r.id, 'r1');
      expect(r.savedAt, saved);
      expect(r.verified, isTrue);
      expect(r.userCorrected, isFalse);
      expect(r.isSample, isFalse);
      expect(r.totalThb, 85.00);
      expect(r.kind, check.kind);
      expect(r.subtotalThb, check.subtotal);
      expect(r.itemCount, check.itemCount);
      expect(r.merchantName, 'Ta Kri Rest.');
      expect(r.placeName, 'Ta Kri');
      expect(r.lat, _lat);
      expect(r.lng, _lng);
      expect(r.category, SpendCategory.food);
    });

    test('service bill from checkBill carries service figures', () {
      final check = checkBill(
        _ocrLines([
          'Food 300.00',
          'Subtotal 300.00',
          'Service 10% 30.00',
          'Total 330.00',
        ]),
      );
      expect(check, isNotNull);
      final r = ReceiptRecord.fromCheck(
        check!,
        id: 'r2',
        savedAt: DateTime(2026, 10, 14, 20),
      );
      expect(r.verified, isTrue);
      expect(r.kind, BillKind.serviceCharge);
      expect(r.totalThb, 330.00);
      expect(r.subtotalThb, 300.00);
      expect(r.serviceThb, 30.00);
      expect(r.servicePercent, 10);
      expect(r.serviceIncluded, isFalse);
      expect(r.category, SpendCategory.other);
      expect(r.merchantName, isNull);
      expect(r.merchantKey, isNull);
    });

    test('copies every figure from a directly built BillCheck', () {
      const check = BillCheck(
        kind: BillKind.serviceCharge,
        total: 1083.50,
        subtotal: 1000.00,
        discount: 50.00,
        serviceCharge: 95.00,
        servicePercent: 10,
        vat: 70.88,
        vatPercent: 7,
        beforeVat: 1012.62,
        itemCount: 4,
        vatOnTop: true,
        serviceIncluded: true,
      );
      final r = ReceiptRecord.fromCheck(
        check,
        id: 'r3',
        savedAt: DateTime(2026, 10, 13, 19),
      );
      expect(r.verified, isTrue);
      expect(r.kind, BillKind.serviceCharge);
      expect(r.totalThb, 1083.50);
      expect(r.subtotalThb, 1000.00);
      expect(r.discountThb, 50.00);
      expect(r.serviceThb, 95.00);
      expect(r.servicePercent, 10);
      expect(r.vatThb, 70.88);
      expect(r.itemCount, 4);
      expect(r.vatOnTop, isTrue);
      expect(r.serviceIncluded, isTrue);
    });
  });

  group('ReceiptRecord.corrected', () {
    final original = ReceiptRecord.fromCheck(
      const BillCheck(
        kind: BillKind.serviceCharge,
        total: 330.00,
        subtotal: 300.00,
        serviceCharge: 30.00,
        servicePercent: 10,
        itemCount: 1,
      ),
      id: 'c1',
      savedAt: DateTime(2026, 10, 14, 20),
      merchantName: 'Som Tam Nua',
      placeName: 'Som Tam Nua Siam',
      lat: _lat,
      lng: _lng,
      category: SpendCategory.food,
    );

    test('new total marks user-corrected and unverified', () {
      final c = original.corrected(totalThb: 350.00);
      expect(c.totalThb, 350.00);
      expect(c.userCorrected, isTrue);
      expect(c.verified, isFalse);
    });

    test('keeps every other field', () {
      final c = original.corrected(totalThb: 350.00);
      expect(c.id, original.id);
      expect(c.savedAt, original.savedAt);
      expect(c.merchantName, 'Som Tam Nua');
      expect(c.placeName, 'Som Tam Nua Siam');
      expect(c.lat, _lat);
      expect(c.lng, _lng);
      expect(c.kind, BillKind.serviceCharge);
      expect(c.subtotalThb, 300.00);
      expect(c.serviceThb, 30.00);
      expect(c.servicePercent, 10);
      expect(c.itemCount, 1);
      expect(c.category, SpendCategory.food);
      expect(c.isSample, isFalse);
      expect(c.merchantKey, original.merchantKey);
    });

    test('format-only correction keeps the total', () {
      final c = original.corrected(
        servicePercent: 0,
        serviceIncluded: true,
        vatOnTop: true,
      );
      expect(c.totalThb, 330.00);
      expect(c.servicePercent, 0);
      expect(c.serviceIncluded, isTrue);
      expect(c.vatOnTop, isTrue);
      expect(c.userCorrected, isTrue);
      expect(c.verified, isFalse);
    });

    test('does not change the original', () {
      original.corrected(totalThb: 999);
      expect(original.totalThb, 330.00);
      expect(original.verified, isTrue);
      expect(original.userCorrected, isFalse);
    });
  });

  group('JSON', () {
    test('round-trips every field through jsonEncode', () {
      final r = ReceiptRecord(
        id: 'j1',
        savedAt: DateTime(2026, 10, 12, 9, 41, 7),
        totalThb: 1083.50,
        verified: false,
        merchantName: 'Baan Khanitha',
        placeName: 'Baan Khanitha Sukhumvit 23',
        lat: _lat,
        lng: _lng,
        kind: BillKind.vatOnTop,
        subtotalThb: 1000.00,
        discountThb: 50.00,
        serviceThb: 95.00,
        servicePercent: 10,
        serviceIncluded: true,
        vatThb: 70.88,
        vatOnTop: true,
        itemCount: 4,
        category: SpendCategory.food,
        userCorrected: true,
        isSample: true,
      );
      final back = ReceiptRecord.fromJson(
        jsonDecode(jsonEncode(r.toJson())),
      );
      expect(back, isNotNull);
      final b = back!;
      expect(b.id, 'j1');
      expect(
        b.savedAt.millisecondsSinceEpoch,
        r.savedAt.millisecondsSinceEpoch,
      );
      expect(b.totalThb, 1083.50);
      expect(b.verified, isFalse);
      expect(b.merchantName, 'Baan Khanitha');
      expect(b.placeName, 'Baan Khanitha Sukhumvit 23');
      expect(b.lat, _lat);
      expect(b.lng, _lng);
      expect(b.kind, BillKind.vatOnTop);
      expect(b.subtotalThb, 1000.00);
      expect(b.discountThb, 50.00);
      expect(b.serviceThb, 95.00);
      expect(b.servicePercent, 10);
      expect(b.serviceIncluded, isTrue);
      expect(b.vatThb, 70.88);
      expect(b.vatOnTop, isTrue);
      expect(b.itemCount, 4);
      expect(b.category, SpendCategory.food);
      expect(b.userCorrected, isTrue);
      expect(b.isSample, isTrue);
    });

    test('round-trips a minimal record with nulls and defaults', () {
      final r = ReceiptRecord(
        id: 'j2',
        savedAt: DateTime(2026, 10, 11, 8),
        totalThb: 45,
        verified: true,
      );
      final b = ReceiptRecord.fromJson(jsonDecode(jsonEncode(r.toJson())))!;
      expect(b.id, 'j2');
      expect(b.totalThb, 45);
      expect(b.verified, isTrue);
      expect(b.merchantName, isNull);
      expect(b.placeName, isNull);
      expect(b.lat, isNull);
      expect(b.lng, isNull);
      expect(b.kind, isNull);
      expect(b.subtotalThb, isNull);
      expect(b.discountThb, isNull);
      expect(b.serviceThb, isNull);
      expect(b.servicePercent, isNull);
      expect(b.vatThb, isNull);
      expect(b.itemCount, isNull);
      expect(b.serviceIncluded, isFalse);
      expect(b.vatOnTop, isFalse);
      expect(b.category, SpendCategory.other);
      expect(b.userCorrected, isFalse);
      expect(b.isSample, isFalse);
    });

    test('every BillKind and SpendCategory survives a round trip', () {
      for (final kind in BillKind.values) {
        for (final cat in SpendCategory.values) {
          final r = ReceiptRecord(
            id: '${kind.name}-${cat.name}',
            savedAt: DateTime(2026, 10, 10),
            totalThb: 100,
            verified: true,
            kind: kind,
            category: cat,
          );
          final b = ReceiptRecord.fromJson(r.toJson())!;
          expect(b.kind, kind);
          expect(b.category, cat);
        }
      }
    });

    Map<String, Object?> valid() => ReceiptRecord(
      id: 'm1',
      savedAt: DateTime(2026, 10, 10),
      totalThb: 100,
      verified: true,
    ).toJson();

    test('malformed input returns null', () {
      expect(ReceiptRecord.fromJson(null), isNull);
      expect(ReceiptRecord.fromJson('receipt'), isNull);
      expect(ReceiptRecord.fromJson(42), isNull);
      expect(ReceiptRecord.fromJson(const <Object?>[]), isNull);
      expect(ReceiptRecord.fromJson(const <String, Object?>{}), isNull);
      expect(ReceiptRecord.fromJson(valid()), isNotNull);
    });

    test('missing id, savedAt or total returns null', () {
      for (final key in valid().keys.where(
        (k) => k == 'id' || k == 'savedAt' || k == 'totalThb',
      )) {
        final json = valid()..remove(key);
        expect(ReceiptRecord.fromJson(json), isNull, reason: 'without $key');
      }
      // Whatever the key names are, dropping all three must fail.
      expect(ReceiptRecord.fromJson({'verified': true}), isNull);
    });

    test('total of zero or below returns null', () {
      final base = ReceiptRecord(
        id: 'm2',
        savedAt: DateTime(2026, 10, 10),
        totalThb: 100,
        verified: true,
      ).toJson();
      final totalKey = base.entries
          .firstWhere((e) => e.value == 100 || e.value == 100.0)
          .key;
      expect(ReceiptRecord.fromJson({...base, totalKey: 0}), isNull);
      expect(ReceiptRecord.fromJson({...base, totalKey: -5.0}), isNull);
      expect(ReceiptRecord.fromJson({...base, totalKey: 'abc'}), isNull);
    });
  });

  group('merchantKey', () {
    ReceiptRecord named(String? name) => ReceiptRecord(
      id: 'k',
      savedAt: DateTime(2026, 10, 10),
      totalThb: 10,
      verified: true,
      merchantName: name,
    );

    test('case, punctuation and repeated spaces do not matter', () {
      final a = named('7-ELEVEN  Sukhumvit 11').merchantKey;
      final b = named('7-eleven sukhumvit 11').merchantKey;
      expect(a, isNotNull);
      expect(a, b);
      expect(a, a!.toLowerCase());
      expect(a.contains('  '), isFalse);
      expect(a, isNot(contains('-')));
      expect(a, contains('sukhumvit'));
      expect(a, contains('11'));
    });

    test('Thai names normalise and keep Thai letters', () {
      final a = named('ร้านป้าแดง  สาขา 2!').merchantKey;
      final b = named('ร้านป้าแดง สาขา 2').merchantKey;
      expect(a, b);
      expect(a, contains('สาขา'));
    });

    test('different merchants have different keys', () {
      expect(
        named('7-Eleven Sukhumvit 11').merchantKey,
        isNot(named('7-Eleven Sukhumvit 13').merchantKey),
      );
    });

    test('null when no merchant name', () {
      expect(named(null).merchantKey, isNull);
    });
  });

  group('categorize', () {
    test('place types map to categories', () {
      expect(categorize(placeTypes: ['restaurant']), SpendCategory.food);
      expect(categorize(placeTypes: ['cafe']), SpendCategory.food);
      expect(categorize(placeTypes: ['bakery']), SpendCategory.food);
      expect(categorize(placeTypes: ['meal_takeaway']), SpendCategory.food);
      expect(
        categorize(placeTypes: ['subway_station']),
        SpendCategory.transport,
      );
      expect(categorize(placeTypes: ['airport']), SpendCategory.transport);
      expect(categorize(placeTypes: ['gas_station']), SpendCategory.transport);
      expect(categorize(placeTypes: ['lodging']), SpendCategory.lodging);
      expect(
        categorize(placeTypes: ['convenience_store']),
        SpendCategory.shopping,
      );
      expect(
        categorize(placeTypes: ['shopping_mall']),
        SpendCategory.shopping,
      );
      expect(categorize(placeTypes: ['pharmacy']), SpendCategory.shopping);
    });

    test('a known type is found among generic Google types', () {
      expect(
        categorize(
          placeTypes: ['point_of_interest', 'establishment', 'restaurant'],
        ),
        SpendCategory.food,
      );
    });

    test('place types beat the merchant name', () {
      expect(
        categorize(placeTypes: ['lodging'], merchantName: '7-Eleven'),
        SpendCategory.lodging,
      );
      expect(
        categorize(placeTypes: ['restaurant'], merchantName: 'Grab'),
        SpendCategory.food,
      );
    });

    test('falls back to merchant name words', () {
      expect(categorize(merchantName: '7-ELEVEN'), SpendCategory.shopping);
      expect(categorize(merchantName: 'Big C Extra'), SpendCategory.shopping);
      expect(categorize(merchantName: 'Boots Siam'), SpendCategory.shopping);
      expect(
        categorize(merchantName: 'Lotus\'s Rama 4'),
        SpendCategory.shopping,
      );
      expect(
        categorize(merchantName: 'Roast Coffee & Eatery'),
        SpendCategory.food,
      );
      expect(categorize(merchantName: 'ร้านอาหารป้าแดง'), SpendCategory.food);
      expect(categorize(merchantName: 'GRAB'), SpendCategory.transport);
      expect(categorize(merchantName: 'BTS Skytrain'), SpendCategory.transport);
      expect(
        categorize(merchantName: 'Lub d Hostel Silom'),
        SpendCategory.lodging,
      );
      expect(categorize(merchantName: 'โรงแรมสยาม'), SpendCategory.lodging);
    });

    test('unknown types fall back to the name', () {
      expect(
        categorize(
          placeTypes: ['point_of_interest', 'establishment'],
          merchantName: 'Family Mart',
        ),
        SpendCategory.shopping,
      );
    });

    test('other when nothing matches', () {
      expect(categorize(), SpendCategory.other);
      expect(categorize(merchantName: 'Zyxw Co.'), SpendCategory.other);
      expect(
        categorize(placeTypes: ['point_of_interest'], merchantName: null),
        SpendCategory.other,
      );
    });
  });

  group('merchantFromRows', () {
    test('skips a status-bar row and returns the shop name', () {
      // A row may carry up to two digits (7-ELEVEN); the status bar has more.
      expect(
        merchantFromRows(['19:17 lll 5G 53', '7-ELEVEN', 'CP ALL PCL']),
        '7-ELEVEN',
      );
    });

    test('skips a document title row', () {
      expect(
        merchantFromRows(['RECEIPT/TAX INVOICE (ABB.)', 'Ta Kri Rest.']),
        'Ta Kri Rest.',
      );
      expect(
        merchantFromRows(['ใบเสร็จรับเงิน', 'ร้านป้าแดง']),
        'ร้านป้าแดง',
      );
      expect(
        merchantFromRows(['ใบกำกับภาษีอย่างย่อ', 'VAT Included', 'Somboon']),
        'Somboon',
      );
    });

    test('skips rows with more than two digits or under three letters', () {
      expect(
        merchantFromRows(['TAX# 0105536', 'No. 12', 'ab', 'Baan Suan']),
        'Baan Suan',
      );
      expect(merchantFromRows(['Soi 123', 'Lane 12 Cafe']), 'Lane 12 Cafe');
    });

    test('skips cash-sale and customer title rows', () {
      expect(
        merchantFromRows(['CASH SALE', 'Customer copy', 'Jay Fai']),
        'Jay Fai',
      );
      expect(
        merchantFromRows(['บิลเงินสด', 'สำหรับลูกค้า', 'ร้านป้าแดง']),
        'ร้านป้าแดง',
      );
    });

    test('only the first six rows are looked at', () {
      expect(
        merchantFromRows([
          '1',
          '2',
          '3',
          '4',
          '5',
          '6',
          'Late Name',
        ]),
        isNull,
      );
    });

    test('null for empty or all-number rows', () {
      expect(merchantFromRows(const []), isNull);
      expect(merchantFromRows(['85.00', '12/10/2026 19:17']), isNull);
    });
  });

  group('merchantMemory', () {
    final current = _rec(
      'now',
      _now,
      120,
      merchant: '7-Eleven Sukhumvit 11',
      lat: _lat,
      lng: _lng,
    );

    test('null with no history', () {
      expect(merchantMemory(current, const [], _now), isNull);
    });

    test('matches by merchant name, newest first', () {
      final history = [
        _rec('a', _daysAgo(3), 80, merchant: '7-ELEVEN  sukhumvit 11'),
        _rec('b', _daysAgo(1), 95, merchant: '7-eleven Sukhumvit 11'),
        _rec('c', _daysAgo(2), 300, merchant: 'Som Tam Nua'),
      ];
      final m = merchantMemory(current, history, _now);
      expect(m, isNotNull);
      expect(m!.merchantKey, current.merchantKey);
      expect(m.visits, 2);
      expect(m.lastTotalThb, 95);
      expect(m.dates, [_daysAgo(1), _daysAgo(3)]);
      expect(m.correctedRecords, 0);
    });

    test('matches an unnamed record within 100 m, not one 300 m away', () {
      final history = [
        _rec('near', _daysAgo(2), 70, lat: _lat50m, lng: _lng),
        _rec('far', _daysAgo(1), 500, lat: _lat300m, lng: _lng),
      ];
      final m = merchantMemory(current, history, _now);
      expect(m, isNotNull);
      expect(m!.visits, 1);
      expect(m.lastTotalThb, 70);
      expect(m.dates, [_daysAgo(2)]);
    });

    test('only 300 m away gives null', () {
      final history = [_rec('far', _daysAgo(1), 500, lat: _lat300m, lng: _lng)];
      expect(merchantMemory(current, history, _now), isNull);
    });

    test('future records and the current moment are ignored', () {
      final history = [
        _rec('future', _now.add(const Duration(hours: 1)), 999,
            merchant: '7-Eleven Sukhumvit 11'),
        _rec('same', _now, 888, merchant: '7-Eleven Sukhumvit 11'),
        _rec('past', _daysAgo(4), 60, merchant: '7-Eleven Sukhumvit 11'),
      ];
      final m = merchantMemory(current, history, _now)!;
      expect(m.visits, 1);
      expect(m.lastTotalThb, 60);
      expect(merchantMemory(current, [history[0]], _now), isNull);
    });

    test('carries the newest record format and counts corrections', () {
      final history = [
        _rec('old', _daysAgo(5), 330,
            merchant: '7-Eleven Sukhumvit 11', servicePercent: 10),
        _rec('new', _daysAgo(1), 214,
            merchant: '7-Eleven Sukhumvit 11',
            servicePercent: 0,
            serviceIncluded: true,
            vatOnTop: true,
            userCorrected: true,
            verified: false),
      ];
      final m = merchantMemory(current, history, _now)!;
      expect(m.visits, 2);
      expect(m.lastTotalThb, 214);
      expect(m.lastServicePercent, 0);
      expect(m.lastServiceIncluded, isTrue);
      expect(m.lastVatOnTop, isTrue);
      expect(m.correctedRecords, 1);
    });

    test('no name and no location gives null', () {
      final bare = _rec('bare', _now, 50);
      final history = [_rec('x', _daysAgo(1), 50)];
      expect(merchantMemory(bare, history, _now), isNull);
    });
  });

  group('formatHint', () {
    final current = _rec(
      'now',
      _now,
      400,
      merchant: 'Som Tam Nua',
      lat: _lat,
      lng: _lng,
    );

    test('null when the merchant was never corrected', () {
      final history = [
        _rec('a', _daysAgo(2), 330,
            merchant: 'Som Tam Nua', servicePercent: 10),
      ];
      expect(formatHint(current, history, _now), isNull);
    });

    test('uses only corrected records, newest correction wins', () {
      final history = [
        _rec('c-old', _daysAgo(6), 300,
            merchant: 'som tam  nua',
            servicePercent: 5,
            userCorrected: true,
            verified: false),
        _rec('c-new', _daysAgo(3), 321,
            merchant: 'Som Tam Nua',
            servicePercent: 0,
            serviceIncluded: true,
            vatOnTop: true,
            userCorrected: true,
            verified: false),
        // Newer but not corrected: must not override the user's fix.
        _rec('plain', _daysAgo(1), 330,
            merchant: 'Som Tam Nua', servicePercent: 10),
      ];
      final h = formatHint(current, history, _now);
      expect(h, isNotNull);
      expect(h!.servicePercent, 0);
      expect(h.serviceIncluded, isTrue);
      expect(h.vatOnTop, isTrue);
      expect(h.fromRecords, 2);
      expect(h.lastCorrectedAt, _daysAgo(3));
    });

    test('a correction 50 m away counts, 300 m away does not', () {
      final near = [
        _rec('n', _daysAgo(2), 200,
            lat: _lat50m, lng: _lng, servicePercent: 10,
            userCorrected: true, verified: false),
      ];
      final far = [
        _rec('f', _daysAgo(2), 200,
            lat: _lat300m, lng: _lng, servicePercent: 10,
            userCorrected: true, verified: false),
      ];
      final h = formatHint(current, near, _now);
      expect(h, isNotNull);
      expect(h!.servicePercent, 10);
      expect(h.fromRecords, 1);
      expect(formatHint(current, far, _now), isNull);
    });

    test('future corrections and other merchants are ignored', () {
      final history = [
        _rec('future', _now.add(const Duration(minutes: 5)), 200,
            merchant: 'Som Tam Nua', userCorrected: true, verified: false),
        _rec('other', _daysAgo(1), 200,
            merchant: 'Baan Khanitha', userCorrected: true, verified: false),
      ];
      expect(formatHint(current, history, _now), isNull);
    });
  });

  group('spendByCategory', () {
    test('empty history gives an empty list', () {
      expect(spendByCategory(const [], _now), isEmpty);
    });

    test('sums the last 7 calendar days, sorted by total', () {
      final history = [
        _rec('f1', _daysAgo(0, hour: 9), 120, category: SpendCategory.food),
        _rec('f2', _daysAgo(2), 330, category: SpendCategory.food),
        _rec('t1', _daysAgo(1), 45, category: SpendCategory.transport),
        _rec('l1', _daysAgo(3), 1200, category: SpendCategory.lodging),
        // Day 7 (today is day 1): first minute is inside the window.
        _rec('s1', _daysAgo(6, hour: 0, minute: 1), 85,
            category: SpendCategory.shopping),
        // Day 8: outside.
        _rec('old', _daysAgo(7, hour: 23, minute: 59), 5000,
            category: SpendCategory.shopping),
        // Later today: not yet happened.
        _rec('future', _now.add(const Duration(hours: 2)), 9000,
            category: SpendCategory.food),
      ];
      final out = spendByCategory(history, _now);
      expect(out.map((c) => c.category).toList(), [
        SpendCategory.lodging,
        SpendCategory.food,
        SpendCategory.shopping,
        SpendCategory.transport,
      ]);
      expect(out[0].totalThb, 1200);
      expect(out[0].records, 1);
      expect(out[1].totalThb, 450);
      expect(out[1].records, 2);
      expect(out[2].totalThb, 85);
      expect(out[2].records, 1);
      expect(out[3].totalThb, 45);
      expect(out[3].records, 1);
    });

    test('custom window of 1 day is today only', () {
      final history = [
        _rec('a', _daysAgo(0, hour: 8), 60, category: SpendCategory.food),
        _rec('b', _daysAgo(1, hour: 23, minute: 59), 999,
            category: SpendCategory.food),
      ];
      final out = spendByCategory(history, _now, days: 1);
      expect(out.length, 1);
      expect(out.single.category, SpendCategory.food);
      expect(out.single.totalThb, 60);
      expect(out.single.records, 1);
    });

    test('nothing inside the window gives an empty list', () {
      final history = [_rec('old', _daysAgo(10), 100)];
      expect(spendByCategory(history, _now), isEmpty);
    });
  });

  group('dailySpend', () {
    test('median of three days, rounded up to the next 100', () {
      final history = [
        _rec('a1', _daysAgo(1, hour: 9), 300),
        _rec('a2', _daysAgo(1, hour: 19), 150), // day total 450
        _rec('b', _daysAgo(2), 820),
        _rec('c', _daysAgo(4), 1200),
      ];
      final d = dailySpend(history, _now);
      expect(d, isNotNull);
      expect(d!.medianThb, 900);
      expect(d.daysUsed, 3);
      expect(d.isEstimate, isTrue);
      expect(
        d.days.map((x) => DateTime(x.year, x.month, x.day)).toSet(),
        {
          DateTime(2026, 10, 14),
          DateTime(2026, 10, 13),
          DateTime(2026, 10, 11),
        },
      );
    });

    test('even count uses the mean of the middle two, then rounds up', () {
      final history = [
        _rec('a', _daysAgo(1), 300),
        _rec('b', _daysAgo(3), 510),
      ];
      final d = dailySpend(history, _now)!;
      expect(d.medianThb, 500); // (300 + 510) / 2 = 405 -> 500
      expect(d.daysUsed, 2);
    });

    test('an exact hundred is not rounded further', () {
      final history = [
        _rec('a', _daysAgo(1), 400),
        _rec('b', _daysAgo(2), 400),
      ];
      expect(dailySpend(history, _now)!.medianThb, 400);
    });

    test('today is excluded', () {
      final history = [
        _rec('today', _daysAgo(0, hour: 8), 5000),
        _rec('a', _daysAgo(1), 300),
        _rec('b', _daysAgo(2), 300),
      ];
      final d = dailySpend(history, _now)!;
      expect(d.medianThb, 300);
      expect(d.daysUsed, 2);
    });

    test('fewer than two earlier days gives null', () {
      expect(dailySpend(const [], _now), isNull);
      expect(dailySpend([_rec('a', _daysAgo(1), 300)], _now), isNull);
      expect(
        dailySpend([
          _rec('a1', _daysAgo(1, hour: 9), 300),
          _rec('a2', _daysAgo(1, hour: 20), 200),
          _rec('today', _daysAgo(0, hour: 9), 100),
        ], _now),
        isNull,
      );
    });
  });
}
