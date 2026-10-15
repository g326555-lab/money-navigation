import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/bill_check.dart';
import 'package:money_navigation/rules/receipt_record.dart';
import 'package:money_navigation/services/auth/receipt_record_mapper.dart';

final t0 = DateTime.utc(2026, 10, 15, 12, 5);

/// Verified service-charge receipt: 300.00 + 10 % = 30.00, total 330.00,
/// VAT 21.59 inside, 4 items, food, with a place.
final serviceReceipt = ReceiptRecord(
  id: 'rc-1',
  savedAt: t0,
  totalThb: 330.00,
  verified: true,
  merchantName: 'Baan Khanitha',
  placeName: 'Baan Khanitha Sukhumvit 23',
  lat: 13.7384,
  lng: 100.5631,
  kind: BillKind.serviceCharge,
  subtotalThb: 300.00,
  discountThb: 0,
  serviceThb: 30.00,
  servicePercent: 10,
  vatThb: 21.59,
  itemCount: 4,
  category: SpendCategory.food,
);

final itemsOnlyReceipt = ReceiptRecord(
  id: 'rc-2',
  savedAt: t0.add(const Duration(hours: 2)),
  totalThb: 85.00,
  verified: true,
  kind: BillKind.itemsOnly,
  itemCount: 2,
  category: SpendCategory.shopping,
);

const _columns = [
  'client_id',
  'saved_at',
  'total_thb',
  'verified',
  'merchant_name',
  'place_name',
  'place_lat',
  'place_lng',
  'kind',
  'subtotal_thb',
  'discount_thb',
  'service_thb',
  'service_percent',
  'service_included',
  'vat_thb',
  'vat_on_top',
  'item_count',
  'category',
  'user_corrected',
  'is_sample',
];

void expectSameReceipt(ReceiptRecord? actual, ReceiptRecord expected) {
  expect(actual, isNotNull);
  expect(actual!.savedAt.isAtSameMomentAs(expected.savedAt), isTrue);
  expect(actual.toJson(), expected.toJson());
}

void main() {
  group('receiptToRow', () {
    test('maps every field to its snake_case column', () {
      final row = receiptToRow(serviceReceipt);
      expect(row, {
        'client_id': 'rc-1',
        'saved_at': '2026-10-15T12:05:00.000Z',
        'total_thb': 330.0,
        'verified': true,
        'merchant_name': 'Baan Khanitha',
        'place_name': 'Baan Khanitha Sukhumvit 23',
        'place_lat': 13.7384,
        'place_lng': 100.5631,
        'kind': 'serviceCharge',
        'subtotal_thb': 300.0,
        'discount_thb': 0,
        'service_thb': 30.0,
        'service_percent': 10,
        'service_included': false,
        'vat_thb': 21.59,
        'vat_on_top': false,
        'item_count': 4,
        'category': 'food',
        'user_corrected': false,
        'is_sample': false,
      });
    });

    test('every column is present, absent values as null, no user_id', () {
      final row = receiptToRow(itemsOnlyReceipt);
      expect(row.keys.toSet(), _columns.toSet());
      expect(row.containsKey('user_id'), isFalse);
      expect(row.containsKey('id'), isFalse);
      for (final c in [
        'merchant_name',
        'place_name',
        'place_lat',
        'place_lng',
        'subtotal_thb',
        'discount_thb',
        'service_thb',
        'service_percent',
        'vat_thb',
      ]) {
        expect(row[c], isNull, reason: c);
      }
      expect(row['total_thb'], 85.0);
      expect(row['kind'], 'itemsOnly');
    });
  });

  group('round trip', () {
    test('verified service-charge receipt survives unchanged', () {
      expectSameReceipt(
        receiptFromRow(receiptToRow(serviceReceipt)),
        serviceReceipt,
      );
    });

    test('items-only 85.00 receipt survives unchanged', () {
      expectSameReceipt(
        receiptFromRow(receiptToRow(itemsOnlyReceipt)),
        itemsOnlyReceipt,
      );
    });

    test('a corrected copy survives, still not verified', () {
      final fixed = serviceReceipt.corrected(
        servicePercent: 0,
        serviceIncluded: true,
      );
      expect(fixed.userCorrected, isTrue);
      expect(fixed.verified, isFalse);
      final back = receiptFromRow(receiptToRow(fixed));
      expectSameReceipt(back, fixed);
      expect(back!.verified, isFalse);
      expect(back.userCorrected, isTrue);
    });
  });

  group('receiptFromRow', () {
    Map<String, Object?> row() => receiptToRow(serviceReceipt);

    test('accepts numeric columns as strings (PostgREST numeric)', () {
      final r = receiptFromRow(
        row()
          ..['total_thb'] = '330.00'
          ..['subtotal_thb'] = '300.00'
          ..['discount_thb'] = '0'
          ..['service_thb'] = '30.00'
          ..['service_percent'] = '10.00'
          ..['vat_thb'] = '21.59'
          ..['place_lat'] = '13.7384'
          ..['place_lng'] = '100.5631',
      )!;
      expect(r.totalThb, 330);
      expect(r.subtotalThb, 300);
      expect(r.discountThb, 0);
      expect(r.serviceThb, 30);
      expect(r.servicePercent, 10);
      expect(r.vatThb, 21.59);
      expect(r.lat, 13.7384);
      expect(r.lng, 100.5631);
    });

    test('accepts ints for numeric columns', () {
      final r = receiptFromRow(row()..['total_thb'] = 330)!;
      expect(r.totalThb, 330);
    });

    test('ignores database-only columns', () {
      final r = receiptFromRow(
        row()
          ..['id'] = 'uuid-1'
          ..['user_id'] = 'user-1'
          ..['created_at'] = '2026-10-15T12:06:00+00:00',
      )!;
      expect(r.id, 'rc-1');
    });

    test('reads a +00:00 timestamp', () {
      final r = receiptFromRow(
        row()..['saved_at'] = '2026-10-15T12:05:00+00:00',
      )!;
      expect(r.savedAt.isAtSameMomentAs(t0), isTrue);
    });

    test('missing client_id, saved_at or a total <= 0 gives null', () {
      expect(receiptFromRow(row()..remove('client_id')), isNull);
      expect(receiptFromRow(row()..['client_id'] = null), isNull);
      expect(receiptFromRow(row()..['client_id'] = ''), isNull);
      expect(receiptFromRow(row()..remove('saved_at')), isNull);
      expect(receiptFromRow(row()..['saved_at'] = 'noon'), isNull);
      expect(receiptFromRow(row()..['total_thb'] = 0), isNull);
      expect(receiptFromRow(row()..['total_thb'] = -5), isNull);
      expect(receiptFromRow(row()..['total_thb'] = '0.00'), isNull);
      expect(receiptFromRow(row()..['total_thb'] = 'abc'), isNull);
      expect(receiptFromRow(row()..remove('total_thb')), isNull);
    });

    test('non-map input gives null', () {
      expect(receiptFromRow(null), isNull);
      expect(receiptFromRow('row'), isNull);
      expect(receiptFromRow([row()]), isNull);
    });

    test('a stored corrected row is never read as verified', () {
      final r = receiptFromRow(
        row()
          ..['verified'] = true
          ..['user_corrected'] = true,
      )!;
      expect(r.verified, isFalse);
      expect(r.userCorrected, isTrue);
    });
  });

  group('receiptsFromRows', () {
    test('skips bad rows and sorts newest first', () {
      final rows = [
        receiptToRow(serviceReceipt),
        {'client_id': 'broken'},
        null,
        receiptToRow(itemsOnlyReceipt),
        receiptToRow(itemsOnlyReceipt)
          ..['client_id'] = 'rc-3'
          ..['total_thb'] = 0,
      ];
      expect(receiptsFromRows(rows).map((r) => r.id), ['rc-2', 'rc-1']);
    });

    test('non-list or empty input gives an empty list', () {
      expect(receiptsFromRows(null), isEmpty);
      expect(receiptsFromRows({'client_id': 'rc-1'}), isEmpty);
      expect(receiptsFromRows(const []), isEmpty);
    });
  });
}
