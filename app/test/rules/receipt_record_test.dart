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

// Bangkok, Sukhumvit area. 0.00018 deg of latitude is about 20 m,
// 0.00045 deg about 50 m, 0.0027 deg about 300 m, 0.027 deg about 3 km.
const double _lat = 13.7400;
const double _lng = 100.5550;
const double _lat20m = _lat + 0.00018;
const double _lat50m = _lat + 0.00045;
const double _lat300m = _lat + 0.0027;
const double _lat3km = _lat + 0.027;

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
  double? serviceThb,
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
  serviceThb: serviceThb,
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
      // A new total makes the proven service amount stale.
      expect(c.serviceThb, isNull);
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

    final withVat = ReceiptRecord.fromCheck(
      const BillCheck(
        kind: BillKind.serviceCharge,
        total: 233.00,
        subtotal: 225.00,
        discount: 13.00,
        serviceCharge: 21.00,
        servicePercent: 10,
        vat: 15.24,
        vatPercent: 7,
        beforeVat: 217.76,
      ),
      id: 'c2',
      savedAt: DateTime(2026, 10, 14, 21),
    );

    test('a new total clears both proven service and VAT amounts', () {
      final c = withVat.corrected(totalThb: 240.00);
      expect(c.serviceThb, isNull);
      expect(c.vatThb, isNull);
      expect(c.subtotalThb, 225.00);
      expect(c.discountThb, 13.00);
      expect(c.servicePercent, 10);
    });

    test('a new service percent clears service only', () {
      final c = withVat.corrected(servicePercent: 0);
      expect(c.serviceThb, isNull);
      expect(c.vatThb, 15.24);
      expect(c.totalThb, 233.00);
    });

    test('a new service-included flag clears service only', () {
      final c = withVat.corrected(serviceIncluded: true);
      expect(c.serviceThb, isNull);
      expect(c.vatThb, 15.24);
      expect(c.serviceIncluded, isTrue);
    });

    test('a new VAT format clears VAT only', () {
      final c = withVat.corrected(vatOnTop: true);
      expect(c.vatThb, isNull);
      expect(c.serviceThb, 21.00);
      expect(c.vatOnTop, isTrue);
      expect(c.totalThb, 233.00);
    });

    test('a record cannot be both verified and user-corrected', () {
      expect(
        () => ReceiptRecord(
          id: 'bad',
          savedAt: DateTime(2026, 10, 14),
          totalThb: 100,
          verified: true,
          userCorrected: true,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('serviceCharged false clears every service figure', () {
      final c = original.corrected(serviceCharged: false);
      expect(c.servicePercent, isNull);
      expect(c.serviceThb, isNull);
      expect(c.serviceIncluded, isFalse);
      expect(c.totalThb, 330.00);
      expect(c.userCorrected, isTrue);
      expect(c.verified, isFalse);
    });

    test('serviceCharged false also clears a service-included record', () {
      final included = _rec(
        'inc',
        _daysAgo(1),
        300,
        merchant: 'Som Tam Nua',
        servicePercent: 10,
        serviceIncluded: true,
        serviceThb: 27.27,
      );
      final c = included.corrected(serviceCharged: false);
      expect(c.servicePercent, isNull);
      expect(c.serviceThb, isNull);
      expect(c.serviceIncluded, isFalse);
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
      final back = ReceiptRecord.fromJson(jsonDecode(jsonEncode(r.toJson())));
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

    test('stored verified with userCorrected loads as unverified', () {
      final json = {...valid(), 'verified': true, 'userCorrected': true};
      final r = ReceiptRecord.fromJson(json)!;
      expect(r.verified, isFalse);
      expect(r.userCorrected, isTrue);
    });

    test('verified loads only when stored as true', () {
      expect(ReceiptRecord.fromJson(valid())!.verified, isTrue);
      expect(
        ReceiptRecord.fromJson({...valid(), 'verified': 'true'})!.verified,
        isFalse,
      );
      final without = valid()..remove('verified');
      expect(ReceiptRecord.fromJson(without)!.verified, isFalse);
    });

    test('NaN and infinite totals return null', () {
      for (final bad in <Object>[
        'NaN',
        'Infinity',
        '-Infinity',
        double.nan,
        double.infinity,
      ]) {
        expect(
          ReceiptRecord.fromJson({...valid(), 'totalThb': bad}),
          isNull,
          reason: 'total $bad',
        );
      }
    });

    test('out-of-range coordinates are dropped, the record kept', () {
      final r = ReceiptRecord.fromJson({
        ...valid(),
        'lat': 91.0,
        'lng': -180.5,
      })!;
      expect(r.lat, isNull);
      expect(r.lng, isNull);
      expect(r.totalThb, 100);
      final edge = ReceiptRecord.fromJson({
        ...valid(),
        'lat': -90.0,
        'lng': 180.0,
      })!;
      expect(edge.lat, -90.0);
      expect(edge.lng, 180.0);
      final nan = ReceiptRecord.fromJson({...valid(), 'lat': 'NaN'})!;
      expect(nan.lat, isNull);
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
      expect(categorize(placeTypes: ['shopping_mall']), SpendCategory.shopping);
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
      expect(merchantFromRows(['ใบเสร็จรับเงิน', 'ร้านป้าแดง']), 'ร้านป้าแดง');
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
        merchantFromRows(['1', '2', '3', '4', '5', '6', 'Late Name']),
        isNull,
      );
    });

    test('null for empty or all-number rows', () {
      expect(merchantFromRows(const []), isNull);
      expect(merchantFromRows(['85.00', '12/10/2026 19:17']), isNull);
    });
  });

  group('merchantMemory (same shop only)', () {
    final current = _rec(
      'now',
      _now,
      120,
      merchant: '7-Eleven',
      lat: _lat,
      lng: _lng,
    );

    test('null with no history', () {
      expect(merchantMemory(current, const [], _now), isNull);
    });

    test('same name within 100 m matches, newest first', () {
      final history = [
        _rec('a', _daysAgo(3), 80, merchant: '7-ELEVEN', lat: _lat, lng: _lng),
        _rec(
          'b',
          _daysAgo(1),
          95,
          merchant: '7-eleven',
          lat: _lat50m,
          lng: _lng,
        ),
        // Same spot, other merchant: not this shop.
        _rec(
          'c',
          _daysAgo(2),
          300,
          merchant: 'Som Tam Nua',
          lat: _lat,
          lng: _lng,
        ),
      ];
      final m = merchantMemory(current, history, _now);
      expect(m, isNotNull);
      expect(m!.merchantKey, current.merchantKey);
      expect(m.visits, 2);
      expect(m.lastTotalThb, 95);
      expect(m.dates, [_daysAgo(1), _daysAgo(3)]);
      expect(m.correctedRecords, 0);
      expect(m.sampleRecords, 0);
      expect(m.lastVerified, isTrue);
    });

    test('same 7-Eleven within 50 m: one visit, no brand memory', () {
      final history = [
        _rec(
          'here',
          _daysAgo(2),
          70,
          merchant: '7-Eleven',
          lat: _lat50m,
          lng: _lng,
        ),
      ];
      final m = merchantMemory(current, history, _now);
      expect(m, isNotNull);
      expect(m!.visits, 1);
      expect(m.lastTotalThb, 70);
      expect(brandMemory(current, history, _now), isNull);
    });

    test('two 7-Eleven records 3 km apart are different shops', () {
      final history = [
        _rec(
          'other',
          _daysAgo(2),
          60,
          merchant: '7-Eleven',
          lat: _lat3km,
          lng: _lng,
        ),
      ];
      expect(merchantMemory(current, history, _now), isNull);
      final b = brandMemory(current, history, _now);
      expect(b, isNotNull);
      expect(b!.records, 1);
    });

    test('same name 300 m away is another branch, not this shop', () {
      final history = [
        _rec(
          'far',
          _daysAgo(1),
          500,
          merchant: '7-Eleven',
          lat: _lat300m,
          lng: _lng,
        ),
      ];
      expect(merchantMemory(current, history, _now), isNull);
      expect(brandMemory(current, history, _now)!.records, 1);
    });

    test('same name, earlier record without location: brand only', () {
      final history = [_rec('noloc', _daysAgo(1), 90, merchant: '7-Eleven')];
      expect(merchantMemory(current, history, _now), isNull);
      expect(brandMemory(current, history, _now)!.records, 1);
    });

    test('same name, current record without location: brand only', () {
      final noLoc = _rec('now', _now, 120, merchant: '7-Eleven');
      final history = [
        _rec(
          'here',
          _daysAgo(1),
          90,
          merchant: '7-Eleven',
          lat: _lat,
          lng: _lng,
        ),
      ];
      expect(merchantMemory(noLoc, history, _now), isNull);
      expect(brandMemory(noLoc, history, _now)!.records, 1);
    });

    test('different names 20 m apart are unrelated', () {
      final history = [
        _rec(
          'next-door',
          _daysAgo(1),
          90,
          merchant: 'FamilyMart',
          lat: _lat20m,
          lng: _lng,
        ),
      ];
      expect(merchantMemory(current, history, _now), isNull);
      expect(brandMemory(current, history, _now), isNull);
    });

    test('an unnamed record 50 m away is unrelated', () {
      final history = [_rec('anon', _daysAgo(1), 90, lat: _lat50m, lng: _lng)];
      expect(merchantMemory(current, history, _now), isNull);
      expect(brandMemory(current, history, _now), isNull);
    });

    test('current without a name gives null even at the same spot', () {
      final unnamed = _rec('now', _now, 50, lat: _lat, lng: _lng);
      final history = [_rec('x', _daysAgo(1), 50, lat: _lat, lng: _lng)];
      expect(merchantMemory(unnamed, history, _now), isNull);
    });

    test('counts sample records among the visits', () {
      final history = [
        ReceiptRecord(
          id: 's',
          savedAt: _daysAgo(2),
          totalThb: 75,
          verified: true,
          merchantName: '7-Eleven',
          lat: _lat,
          lng: _lng,
          isSample: true,
        ),
        _rec(
          'real',
          _daysAgo(1),
          90,
          merchant: '7-Eleven',
          lat: _lat,
          lng: _lng,
        ),
      ];
      final m = merchantMemory(current, history, _now)!;
      expect(m.visits, 2);
      expect(m.sampleRecords, 1);
    });

    test('future records and the current moment are ignored', () {
      final history = [
        _rec(
          'future',
          _now.add(const Duration(hours: 1)),
          999,
          merchant: '7-Eleven',
          lat: _lat,
          lng: _lng,
        ),
        _rec('same', _now, 888, merchant: '7-Eleven', lat: _lat, lng: _lng),
        _rec(
          'past',
          _daysAgo(4),
          60,
          merchant: '7-Eleven',
          lat: _lat,
          lng: _lng,
        ),
      ];
      final m = merchantMemory(current, history, _now)!;
      expect(m.visits, 1);
      expect(m.lastTotalThb, 60);
      expect(merchantMemory(current, [history[0]], _now), isNull);
    });

    test('carries the newest record format and counts corrections', () {
      final history = [
        _rec(
          'old',
          _daysAgo(5),
          330,
          merchant: '7-Eleven',
          lat: _lat,
          lng: _lng,
          servicePercent: 10,
        ),
        _rec(
          'new',
          _daysAgo(1),
          214,
          merchant: '7-Eleven',
          lat: _lat,
          lng: _lng,
          servicePercent: 0,
          serviceIncluded: true,
          vatOnTop: true,
          userCorrected: true,
          verified: false,
        ),
        // A newer record at another branch must not leak in.
        _rec(
          'branch',
          _daysAgo(0, hour: 9),
          40,
          merchant: '7-Eleven',
          lat: _lat3km,
          lng: _lng,
        ),
      ];
      final m = merchantMemory(current, history, _now)!;
      expect(m.visits, 2);
      expect(m.lastTotalThb, 214);
      expect(m.lastServicePercent, 0);
      expect(m.lastServiceIncluded, isTrue);
      expect(m.lastVatOnTop, isTrue);
      expect(m.correctedRecords, 1);
      expect(m.lastVerified, isFalse);
    });
  });

  group('brandMemory (other branches of the same name)', () {
    final current = _rec(
      'now',
      _now,
      120,
      merchant: '7-Eleven',
      lat: _lat,
      lng: _lng,
    );

    test('null with no history', () {
      expect(brandMemory(current, const [], _now), isNull);
    });

    test('null when the current record has no merchant name', () {
      final unnamed = _rec('now', _now, 50, lat: _lat, lng: _lng);
      final history = [_rec('b', _daysAgo(1), 50, merchant: '7-Eleven')];
      expect(brandMemory(unnamed, history, _now), isNull);
    });

    test('three branches: two without service, one with VAT on top', () {
      final history = [
        _rec(
          'b1',
          _daysAgo(1),
          60,
          merchant: '7-Eleven',
          lat: _lat3km,
          lng: _lng,
        ),
        _rec(
          'b2',
          _daysAgo(3),
          70,
          merchant: '7-ELEVEN',
          lat: _lat300m,
          lng: _lng,
        ),
        _rec('b3', _daysAgo(2), 80, merchant: '7-eleven', vatOnTop: true),
      ];
      final b = brandMemory(current, history, _now);
      expect(b, isNotNull);
      expect(b!.merchantKey, current.merchantKey);
      expect(b.records, 3);
      expect(b.serviceAddedRecords, 0);
      expect(b.serviceIncludedRecords, 0);
      expect(b.noServiceRecords, 3);
      expect(b.vatOnTopRecords, 1);
      expect(b.sampleRecords, 0);
      expect(b.dates, [_daysAgo(1), _daysAgo(2), _daysAgo(3)]);
    });

    test('splits records by service format and counts samples', () {
      final history = [
        // Service amount printed, no percent: added.
        _rec(
          'amount',
          _daysAgo(1),
          110,
          merchant: '7-Eleven',
          lat: _lat3km,
          lng: _lng,
          serviceThb: 10,
        ),
        // Service percent, not included: added.
        _rec(
          'percent',
          _daysAgo(2),
          110,
          merchant: '7-Eleven',
          lat: _lat3km,
          lng: _lng,
          servicePercent: 10,
        ),
        // Service included in prices.
        _rec(
          'included',
          _daysAgo(3),
          100,
          merchant: '7-Eleven',
          servicePercent: 10,
          serviceIncluded: true,
        ),
        // No service at all, VAT on top, demo sample.
        ReceiptRecord(
          id: 'sample',
          savedAt: _daysAgo(4),
          totalThb: 107,
          verified: true,
          merchantName: '7-Eleven',
          vatOnTop: true,
          isSample: true,
        ),
      ];
      final b = brandMemory(current, history, _now)!;
      expect(b.records, 4);
      expect(b.serviceAddedRecords, 2);
      expect(b.serviceIncludedRecords, 1);
      expect(b.noServiceRecords, 1);
      expect(b.vatOnTopRecords, 1);
      expect(b.sampleRecords, 1);
    });

    test('a branch corrected to no service counts as no service', () {
      final scanned = _rec(
        'scan',
        _daysAgo(1),
        110,
        merchant: '7-Eleven',
        lat: _lat3km,
        lng: _lng,
        servicePercent: 10,
        serviceThb: 10,
      );
      final b = brandMemory(current, [
        scanned.corrected(serviceCharged: false),
      ], _now)!;
      expect(b.records, 1);
      expect(b.serviceAddedRecords, 0);
      expect(b.serviceIncludedRecords, 0);
      expect(b.noServiceRecords, 1);
    });

    test('excludes same-shop records and other merchants', () {
      final history = [
        _rec(
          'shop',
          _daysAgo(1),
          90,
          merchant: '7-Eleven',
          lat: _lat50m,
          lng: _lng,
        ),
        _rec(
          'branch',
          _daysAgo(2),
          60,
          merchant: '7-Eleven',
          lat: _lat3km,
          lng: _lng,
        ),
        _rec(
          'other',
          _daysAgo(3),
          60,
          merchant: 'FamilyMart',
          lat: _lat3km,
          lng: _lng,
        ),
      ];
      final b = brandMemory(current, history, _now)!;
      expect(b.records, 1);
      expect(b.dates, [_daysAgo(2)]);
      expect(merchantMemory(current, history, _now)!.visits, 1);
    });

    test('future records and the current moment are ignored', () {
      final history = [
        _rec(
          'future',
          _now.add(const Duration(hours: 1)),
          999,
          merchant: '7-Eleven',
          lat: _lat3km,
          lng: _lng,
        ),
        _rec('same', _now, 888, merchant: '7-Eleven', lat: _lat3km, lng: _lng),
        _rec(
          'past',
          _daysAgo(4),
          60,
          merchant: '7-Eleven',
          lat: _lat3km,
          lng: _lng,
        ),
      ];
      final b = brandMemory(current, history, _now)!;
      expect(b.records, 1);
      expect(b.dates, [_daysAgo(4)]);
      expect(brandMemory(current, [history[0]], _now), isNull);
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
        _rec(
          'a',
          _daysAgo(2),
          330,
          merchant: 'Som Tam Nua',
          lat: _lat,
          lng: _lng,
          servicePercent: 10,
        ),
      ];
      expect(formatHint(current, history, _now), isNull);
    });

    test('uses only corrected records, newest correction wins', () {
      final history = [
        _rec(
          'c-old',
          _daysAgo(6),
          300,
          merchant: 'som tam  nua',
          lat: _lat,
          lng: _lng,
          servicePercent: 5,
          userCorrected: true,
          verified: false,
        ),
        _rec(
          'c-new',
          _daysAgo(3),
          321,
          merchant: 'Som Tam Nua',
          lat: _lat50m,
          lng: _lng,
          servicePercent: 0,
          serviceIncluded: true,
          vatOnTop: true,
          userCorrected: true,
          verified: false,
        ),
        // Newer but not corrected: must not override the user's fix.
        _rec(
          'plain',
          _daysAgo(1),
          330,
          merchant: 'Som Tam Nua',
          lat: _lat,
          lng: _lng,
          servicePercent: 10,
        ),
      ];
      final h = formatHint(current, history, _now);
      expect(h, isNotNull);
      expect(h!.servicePercent, 0);
      expect(h.serviceIncluded, isTrue);
      expect(h.vatOnTop, isTrue);
      expect(h.fromRecords, 2);
      expect(h.lastCorrectedAt, _daysAgo(3));
      expect(h.fromSample, isFalse);
      expect(h.sameShop, isTrue);
    });

    test('a correction at another branch 3 km away is not sameShop', () {
      final history = [
        _rec(
          'branch',
          _daysAgo(2),
          200,
          merchant: 'Som Tam Nua',
          lat: _lat3km,
          lng: _lng,
          servicePercent: 10,
          userCorrected: true,
          verified: false,
        ),
      ];
      final h = formatHint(current, history, _now)!;
      expect(h.servicePercent, 10);
      expect(h.fromRecords, 1);
      expect(h.sameShop, isFalse);
    });

    test('a correction without location is not sameShop', () {
      final history = [
        _rec(
          'noloc',
          _daysAgo(2),
          200,
          merchant: 'Som Tam Nua',
          servicePercent: 10,
          userCorrected: true,
          verified: false,
        ),
      ];
      expect(formatHint(current, history, _now)!.sameShop, isFalse);
    });

    test('sameShop follows the newest correction, shop or brand', () {
      final shopOld = _rec(
        'shop',
        _daysAgo(5),
        200,
        merchant: 'Som Tam Nua',
        lat: _lat,
        lng: _lng,
        servicePercent: 5,
        userCorrected: true,
        verified: false,
      );
      final brandNew = _rec(
        'brand',
        _daysAgo(1),
        200,
        merchant: 'Som Tam Nua',
        lat: _lat3km,
        lng: _lng,
        servicePercent: 10,
        userCorrected: true,
        verified: false,
      );
      final h1 = formatHint(current, [shopOld, brandNew], _now)!;
      expect(h1.servicePercent, 10);
      expect(h1.sameShop, isFalse);
      // Only other-branch corrections back a branch hint.
      expect(h1.fromRecords, 1);

      final shopNew = _rec(
        'shop2',
        _daysAgo(0, hour: 9),
        200,
        merchant: 'Som Tam Nua',
        lat: _lat50m,
        lng: _lng,
        servicePercent: 0,
        userCorrected: true,
        verified: false,
      );
      final h2 = formatHint(current, [shopOld, brandNew, shopNew], _now)!;
      expect(h2.servicePercent, 0);
      expect(h2.sameShop, isTrue);
      // Only same-shop corrections back a same-shop hint.
      expect(h2.fromRecords, 2);
    });

    test('fromRecords counts only the scope of the hint', () {
      final branchOld = _rec(
        'branch',
        _daysAgo(4),
        200,
        merchant: 'Som Tam Nua',
        lat: _lat3km,
        lng: _lng,
        servicePercent: 10,
        userCorrected: true,
        verified: false,
      );
      final shopNew = _rec(
        'shop',
        _daysAgo(1),
        200,
        merchant: 'Som Tam Nua',
        lat: _lat,
        lng: _lng,
        servicePercent: 5,
        userCorrected: true,
        verified: false,
      );
      final h = formatHint(current, [branchOld, shopNew], _now)!;
      expect(h.sameShop, isTrue);
      expect(h.servicePercent, 5);
      expect(h.fromRecords, 1);
      expect(h.lastCorrectedAt, _daysAgo(1));
    });

    test('a "no service" correction gives a null service percent', () {
      final scanned = _rec(
        'scan',
        _daysAgo(2),
        330,
        merchant: 'Som Tam Nua',
        lat: _lat,
        lng: _lng,
        servicePercent: 10,
      );
      final h = formatHint(current, [
        scanned.corrected(serviceCharged: false),
      ], _now)!;
      expect(h.servicePercent, isNull);
      expect(h.serviceIncluded, isFalse);
      expect(h.sameShop, isTrue);
      expect(h.fromRecords, 1);
    });

    test('fromSample is true when the last correction is a sample', () {
      final history = [
        ReceiptRecord(
          id: 'demo',
          savedAt: _daysAgo(1),
          totalThb: 233,
          verified: false,
          merchantName: 'Som Tam Nua',
          servicePercent: 10,
          userCorrected: true,
          isSample: true,
        ),
      ];
      final h = formatHint(current, history, _now)!;
      expect(h.fromSample, isTrue);
      expect(h.fromRecords, 1);
    });

    test('a nearby correction under another name or no name is ignored', () {
      final history = [
        _rec(
          'next-door',
          _daysAgo(2),
          200,
          merchant: 'Baan Khanitha',
          lat: _lat20m,
          lng: _lng,
          servicePercent: 10,
          userCorrected: true,
          verified: false,
        ),
        _rec(
          'anon',
          _daysAgo(1),
          200,
          lat: _lat50m,
          lng: _lng,
          servicePercent: 10,
          userCorrected: true,
          verified: false,
        ),
      ];
      expect(formatHint(current, history, _now), isNull);
    });

    test('future corrections are ignored', () {
      final history = [
        _rec(
          'future',
          _now.add(const Duration(minutes: 5)),
          200,
          merchant: 'Som Tam Nua',
          lat: _lat,
          lng: _lng,
          userCorrected: true,
          verified: false,
        ),
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
        _rec(
          's1',
          _daysAgo(6, hour: 0, minute: 1),
          85,
          category: SpendCategory.shopping,
        ),
        // Day 8: outside.
        _rec(
          'old',
          _daysAgo(7, hour: 23, minute: 59),
          5000,
          category: SpendCategory.shopping,
        ),
        // Later today: not yet happened.
        _rec(
          'future',
          _now.add(const Duration(hours: 2)),
          9000,
          category: SpendCategory.food,
        ),
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

    test('counts sample records per category', () {
      final history = [
        ReceiptRecord(
          id: 's1',
          savedAt: _daysAgo(1),
          totalThb: 233,
          verified: true,
          category: SpendCategory.food,
          isSample: true,
        ),
        _rec('f', _daysAgo(2), 100, category: SpendCategory.food),
        _rec('t', _daysAgo(2), 40, category: SpendCategory.transport),
      ];
      final out = spendByCategory(history, _now);
      expect(out[0].category, SpendCategory.food);
      expect(out[0].totalThb, 333);
      expect(out[0].records, 2);
      expect(out[0].sampleRecords, 1);
      expect(out[1].category, SpendCategory.transport);
      expect(out[1].sampleRecords, 0);
    });

    test('custom window of 1 day is today only', () {
      final history = [
        _rec('a', _daysAgo(0, hour: 8), 60, category: SpendCategory.food),
        _rec(
          'b',
          _daysAgo(1, hour: 23, minute: 59),
          999,
          category: SpendCategory.food,
        ),
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
      expect(d.sampleRecords, 0);
      expect(d.isEstimate, isTrue);
      expect(d.days.map((x) => DateTime(x.year, x.month, x.day)).toSet(), {
        DateTime(2026, 10, 14),
        DateTime(2026, 10, 13),
        DateTime(2026, 10, 11),
      });
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

    test('counts sample records on the days used, not today', () {
      ReceiptRecord sample(String id, DateTime at, double total) =>
          ReceiptRecord(
            id: id,
            savedAt: at,
            totalThb: total,
            verified: true,
            isSample: true,
          );
      final history = [
        sample('s1', _daysAgo(1, hour: 9), 200),
        sample('s2', _daysAgo(1, hour: 19), 100),
        _rec('r', _daysAgo(2), 300),
        sample('today', _daysAgo(0, hour: 8), 50),
      ];
      final d = dailySpend(history, _now)!;
      expect(d.daysUsed, 2);
      expect(d.medianThb, 300);
      expect(d.sampleRecords, 2);
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
